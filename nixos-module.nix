{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.hardware.lenovo.wwan;

  # USB ID mapping for supported manufacturers
  manufacturerUsbIds = {
    MediaTek = "14c3:4d75";
    Intel = "8086:7560";
    Quectel = "2c7c:6008";
  };

  # Upstream Lenovo repository
  lenovoWwanUnlock = pkgs.fetchFromGitHub {
    owner = "lenovo";
    repo = "lenovo-wwan-unlock";
    rev = "6bc2138677cad43cd67fb23ec73869efd8beda46";
    hash = "sha256-ibclz63Nw+ivBx7jdHgAhpTesbHiYn21XpCfQTf4bnI=";
  };

  # FCC unlock scripts package
  fccUnlockScripts = pkgs.stdenv.mkDerivation {
    pname = "lenovo-fcc-unlock-scripts";
    version = "unstable";
    src = lenovoWwanUnlock;

    buildPhase = ''
      runHook preBuild
      
      mkdir -p $out/share/ModemManager/fcc-unlock.available.d
      tar -zxf fcc-unlock.d.tar.gz
      cp -r fcc-unlock.d/* $out/share/ModemManager/fcc-unlock.available.d/
      chmod +x $out/share/ModemManager/fcc-unlock.available.d/*
      
      runHook postBuild
    '';

    dontInstall = true;
  };

  # SAR configuration package
  sarConfigPackage = pkgs.stdenv.mkDerivation {
    pname = "lenovo-sar-config";
    version = "unstable";
    src = lenovoWwanUnlock;

    nativeBuildInputs = with pkgs; [ zlib openssl ];

    buildPhase = ''
      runHook preBuild
      
      mkdir -p $out/{bin,lib,share}
      tar -zxf sar_config_files.tar.gz -C $out/share/
      cp *.so $out/lib/
      cp DPR_Fcc_unlock_service configservice_lenovo $out/bin/
      chmod +x $out/bin/*
      
      runHook postBuild
    '';

    dontInstall = true;
  };

  # Current USB ID for the configured manufacturer
  usbId = manufacturerUsbIds.${cfg.modemManufacturer};

  # FCC unlock script configuration
  fccUnlockScript = {
    id = usbId;
    path = "${fccUnlockScripts}/share/ModemManager/fcc-unlock.available.d/${usbId}";
  };

in
{
  options.hardware.lenovo.wwan = {
    enable = mkEnableOption "Lenovo WWAN FCC unlock support";

    modemManufacturer = mkOption {
      type = types.enum (builtins.attrNames manufacturerUsbIds);
      example = "Quectel";
      description = ''
        Modem manufacturer. Run `mmcli -m 0` to identify your modem manufacturer.
      '';
    };

    enableSarConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable SAR configuration service.";
    };

    sarConfigBinary = mkOption {
      type = types.package;
      default = sarConfigPackage;
      internal = true;
      description = "Package containing SAR configuration binaries.";
    };
  };

  config = mkIf cfg.enable {
    # Enable ModemManager service
    services.modemmanager.enable = true;

    # Configure FCC unlock scripts for ModemManager
    networking = 
      if lib.versionOlder lib.version "25.05pre" then
        { networkmanager.fccUnlockScripts = [ fccUnlockScript ]; }
      else
        { modemmanager.fccUnlockScripts = [ fccUnlockScript ]; };

    # SAR configuration service
    systemd.services.lenovo-sar-config = mkIf cfg.enableSarConfig {
      description = "Lenovo SAR Configuration Service";
      after = [ "ModemManager.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${cfg.sarConfigBinary}/bin/configservice_lenovo";
        Restart = "on-failure";
        RestartSec = 20;
      };
    };

    # Provide mmcli for modem manufacturer discovery
    environment.systemPackages = [ pkgs.modemmanager ];
  };
}