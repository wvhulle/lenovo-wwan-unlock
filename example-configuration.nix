# Minimal NixOS configuration for Lenovo WWAN FCC unlock
{ ... }:

{
  imports = [
    ./nixos-module.nix
  ];

  hardware.lenovo.wwan = {
    enable = true;
    # Choose your modem manufacturer:
    # "mediatek" for MediaTek modems
    # "intel" for Intel modems  
    # "quectel" for Quectel modems (EM160R-GL, RM520N-GL, etc.)
    modemId = "quectel";
  };
}