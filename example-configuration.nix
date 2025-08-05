# Example NixOS configuration for Lenovo ThinkPad with WWAN modem
{ config, pkgs, lib, ... }:

{
  # Import the Lenovo WWAN unlock module
  imports = [
    ./nixos-module.nix
  ];

  # Configure Lenovo WWAN FCC unlock
  hardware.lenovo.wwan = {
    enable = true;
    # Common Quectel modem USB IDs - replace with your specific modem ID
    modemId = "2c7c:6008";  # Example: Quectel EM160R-GL or similar
    enableSarConfig = true;
  };

  # Enable NetworkManager for mobile broadband management
  networking.networkmanager = {
    enable = true;
    # Ensure mobile broadband is enabled
    enableStrongSwan = false; # Set to true if you need IPSec VPN
  };

  # Additional networking configuration
  networking = {
    # Enable wireless support if needed
    wireless.enable = false; # Use NetworkManager instead
    
    # Configure firewall if needed
    firewall = {
      enable = true;
      # Allow mobile broadband connections
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Essential services for modem functionality
  services = {
    # ModemManager is automatically enabled by the WWAN module
    # but you can add additional configuration here if needed
    
    # Enable D-Bus (required for NetworkManager/ModemManager)
    dbus.enable = true;
    
    # Optional: Enable location services if your modem supports GPS
    # geoclue2.enable = true;
  };

  # System packages useful for modem management
  environment.systemPackages = with pkgs; [
    # Command-line tools for modem management
    modemmanager  # mmcli command
    networkmanager  # nmcli command
    
    # USB/PCI utilities for hardware identification
    usbutils  # lsusb
    pciutils  # lspci
    
    # Optional: GUI tools
    networkmanagerapplet  # nm-applet for desktop environments
  ];

  # Optional: Configure suspend fixes if needed
  # (based on the suspend-fix directory in the original package)
  powerManagement = {
    enable = true;
    # You may need to add custom suspend/resume scripts here
    # if you experience issues with the WWAN module during suspend
  };

  # Example user configuration with NetworkManager access
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel" 
      "networkmanager"  # Required for NetworkManager access
    ];
  };
}