# Lenovo WWAN FCC Unlock for NixOS

NixOS module for Lenovo WWAN FCC unlock functionality.

## Usage

```nix
{
  imports = [
    ./path/to/lenovo-wwan-unlock/nixos-module.nix
  ];

  hardware.lenovo.wwan = {
    enable = true;
    # Choose your modem manufacturer:
    # "MediaTek" for MediaTek modems
    # "Intel" for Intel modems  
    # "Quectel" for Quectel modems (EM160R-GL, RM520N-GL, etc.)
    modemManufacturer = "Quectel";
  };
}
```

Then rebuild your system:
```bash
sudo nixos-rebuild switch
```

## Finding your modem manufacturer

To identify your modem manufacturer:

```bash
# List modems
mmcli -L

# Get modem details  
mmcli -m 0

# Look for manufacturer in the output:
# Quectel -> use "Quectel"
# Intel -> use "Intel" 
# MediaTek -> use "MediaTek"
```

The module automatically fetches unlock scripts from Lenovo's official repository.