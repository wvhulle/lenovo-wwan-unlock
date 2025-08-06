{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.lenovo.wwan;

  # USB ID mapping for supported manufacturers
  manufacturerUsbIds = {
    MediaTek = "14c3:4d75";
    Intel = "8086:7560";
    Quectel = "2c7c:6008";
  };

  # Upstream Lenovo repository
  src = pkgs.fetchFromGitHub {
    owner = "lenovo";
    repo = "lenovo-wwan-unlock";
    rev = "6bc2138677cad43cd67fb23ec73869efd8beda46";
    hash = "sha256-ibclz63Nw+ivBx7jdHgAhpTesbHiYn21XpCfQTf4bnI=";
  };

  # FCC unlock scripts package
  fccUnlockScripts = pkgs.stdenv.mkDerivation {
    pname = "lenovo-fcc-unlock-scripts";
    version = "unstable-2024-01-01";
    inherit src;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/ModemManager/fcc-unlock.available.d
      tar -xzf fcc-unlock.d.tar.gz
      cp -r fcc-unlock.d/* $out/share/ModemManager/fcc-unlock.available.d/
      chmod +x $out/share/ModemManager/fcc-unlock.available.d/*
      runHook postInstall
    '';
  };

  # SAR configuration package
  sarConfigPackage = pkgs.stdenv.mkDerivation {
    pname = "lenovo-sar-config";
    version = "unstable-2024-01-01";
    inherit src;

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      openssl
      glib
      libmbim
      modemmanager
      pciutils
      zlib
      stdenv.cc.cc.lib  # for libstdc++
    ];

    installPhase = ''
      runHook preInstall
      
      # Extract and install files
      mkdir -p $out/{bin,lib,share}
      tar -xzf sar_config_files.tar.gz -C $out/share/
      install -m755 *.so $out/lib/
      install -m755 DPR_Fcc_unlock_service configservice_lenovo $out/bin/
      
      runHook postInstall
    '';

    # Wrap binaries with required PATH
    postFixup = ''
      wrapProgram $out/bin/configservice_lenovo \
        --prefix PATH : ${makeBinPath [ pkgs.pciutils pkgs.usbutils pkgs.coreutils ]}
    '';
  };

  # Helper to get the current USB ID
  currentUsbId = manufacturerUsbIds.${cfg.modemManufacturer};

in
{
  options.hardware.lenovo.wwan = {
    enable = mkEnableOption "Lenovo WWAN FCC unlock support";

    modemManufacturer = mkOption {
      type = types.enum (attrNames manufacturerUsbIds);
      example = "Quectel";
      description = "Modem manufacturer. Run `mmcli -m 0` to identify your modem manufacturer.";
    };

    enableSarConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable SAR configuration service.";
    };
  };

  config = mkIf cfg.enable {
    # Configure FCC unlock scripts based on NixOS version
    networking = if versionOlder version "25.05pre" then {
      networkmanager.fccUnlockScripts = [{
        id = currentUsbId;
        path = "${fccUnlockScripts}/share/ModemManager/fcc-unlock.available.d/${currentUsbId}";
      }];
    } else {
      modemmanager.fccUnlockScripts = [{
        id = currentUsbId;
        path = "${fccUnlockScripts}/share/ModemManager/fcc-unlock.available.d/${currentUsbId}";
      }];
    };

    # SAR configuration service
    systemd.services.lenovo-sar-config = mkIf cfg.enableSarConfig {
      description = "Lenovo SAR Configuration Service";
      after = [ "ModemManager.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ 
        pciutils 
        usbutils 
        procps 
        modemmanager 
        coreutils
        bash
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        
        # Create symlinks for hardcoded paths
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /usr/bin"
          "${pkgs.bash}/bin/bash -c '[ ! -e /usr/bin/lspci ] && ln -sf ${pkgs.pciutils}/bin/lspci /usr/bin/lspci || true'"
          "${pkgs.bash}/bin/bash -c '[ ! -e /usr/bin/lsusb ] && ln -sf ${pkgs.usbutils}/bin/lsusb /usr/bin/lsusb || true'"
        ];
        
        ExecStart = "${sarConfigPackage}/bin/configservice_lenovo";
        Restart = "on-failure";
        RestartSec = 20;
      };
    };

    # Provide mmcli for modem manufacturer discovery
    environment.systemPackages = [ pkgs.modemmanager ];
  };
}