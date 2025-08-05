{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.hardware.lenovo.wwan;
  
  # Extract FCC unlock scripts from the provided archive
  fccUnlockScripts = pkgs.stdenv.mkDerivation {
    name = "lenovo-fcc-unlock-scripts";
    src = ./.;
    
    buildPhase = ''
      mkdir -p $out/share/ModemManager/fcc-unlock.available.d
      tar -zxf fcc-unlock.d.tar.gz
      cp -r fcc-unlock.d/* $out/share/ModemManager/fcc-unlock.available.d/
      chmod +x $out/share/ModemManager/fcc-unlock.available.d/*
    '';
    
    installPhase = ''
      # Already done in buildPhase
    '';
  };

  # Create systemd service for SAR configuration
  sarConfigService = pkgs.writeShellScriptBin "lenovo-sar-config" ''
    ${cfg.sarConfigBinary}/bin/configservice_lenovo
  '';

  # Package the SAR configuration files and binaries
  sarConfigPackage = pkgs.stdenv.mkDerivation {
    name = "lenovo-sar-config";
    src = ./.;
    
    buildInputs = with pkgs; [ zlib openssl ];
    
    buildPhase = ''
      mkdir -p $out/{bin,lib,share}
      
      # Extract SAR config files
      tar -zxf sar_config_files.tar.gz -C $out/share/
      
      # Copy libraries
      cp libmodemauth.so libconfigserviceR+.so libconfigservice350.so libmbimtools.so $out/lib/
      
      # Copy binaries
      cp DPR_Fcc_unlock_service configservice_lenovo $out/bin/
      chmod +x $out/bin/*
    '';
    
    installPhase = ''
      # Already done in buildPhase
    '';
  };

in {
  options.hardware.lenovo.wwan = {
    enable = mkEnableOption "Lenovo WWAN FCC unlock support";
    
    modemId = mkOption {
      type = types.enum [ "mediatek" "intel" "quectel" ];
      description = "Modem manufacturer";
      example = "quectel";
    };
    
    enableSarConfig = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SAR configuration service";
    };
    
    sarConfigBinary = mkOption {
      type = types.package;
      default = sarConfigPackage;
      description = "Package containing SAR configuration binaries";
    };
  };

  config = mkIf cfg.enable {
    # Configure FCC unlock scripts for ModemManager
    networking = 
      let
        # Map manufacturer names to USB IDs
        usbIds = {
          mediatek = "14c3:4d75";
          intel = "8086:7560";
          quectel = "2c7c:6008";
        };
        usbId = usbIds.${cfg.modemId};
        fcc_unlock_script = {
          id = usbId;
          path = "${fccUnlockScripts}/share/ModemManager/fcc-unlock.available.d/${usbId}";
        };
      in
      if lib.versionOlder lib.version "25.05pre" then
        { networkmanager.fccUnlockScripts = [ fcc_unlock_script ]; }
      else
        { modemmanager.fccUnlockScripts = [ fcc_unlock_script ]; };

    # Enable ModemManager service
    services.modemmanager.enable = true;

    # Configure SAR service if enabled
    systemd.services.lenovo-sar-config = mkIf cfg.enableSarConfig {
      description = "Lenovo SAR Configuration Service";
      after = [ "ModemManager.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${sarConfigService}/bin/lenovo-sar-config";
        Restart = "on-failure";
        RestartSec = 20;
      };
    };

    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      modemmanager
      libmbim 
      pciutils
      usbutils
    ];
  };
}