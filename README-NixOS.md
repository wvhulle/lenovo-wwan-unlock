# Lenovo WWAN FCC Unlock for NixOS

This module provides NixOS support for Lenovo WWAN FCC unlock functionality.

## Available unlock scripts

The following USB vendor:product IDs have unlock scripts available:

- `14c3:4d75` - MediaTek modem
- `1eac:100d` - Unknown vendor modem  
- `1eac:1007` - Unknown vendor modem
- `8086:7560` - Intel modem
- `2c7c:6008` - Quectel modem

## Usage

1. Import the module in your NixOS configuration:

```nix
{ pkgs, ... }:

{
  imports = [
    ./path/to/lenovo-wwan-unlock/nixos-module.nix
  ];

  hardware.lenovo.wwan = {
    enable = true;
    modemId = "2c7c:6008";  # Replace with your modem's USB ID
    enableSarConfig = true;
  };
}
```

2. Rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Finding your modem ID

To find your modem's USB vendor:product ID, you can use:

```bash
# List USB devices
lsusb | grep -i quectel

# Or check ModemManager info
mmcli -L
mmcli -m [modem-number]
```

## Features

- **FCC unlock scripts**: Automatically configures ModemManager with the appropriate unlock script for your modem
- **SAR configuration**: Runs the Lenovo SAR configuration service 
- **Systemd integration**: Proper service management with automatic restart on failure
- **Version compatibility**: Works with both older and newer NixOS versions

## Module options

- `hardware.lenovo.wwan.enable`: Enable the WWAN unlock support
- `hardware.lenovo.wwan.modemId`: USB vendor:product ID of your modem  
- `hardware.lenovo.wwan.enableSarConfig`: Enable SAR configuration service (default: true)
- `hardware.lenovo.wwan.sarConfigBinary`: Override the SAR configuration package

## Troubleshooting

1. Check if ModemManager detects your modem:
   ```bash
   mmcli -L
   ```

2. Check service status:
   ```bash
   systemctl status ModemManager
   systemctl status lenovo-sar-config
   ```

3. Check system logs:
   ```bash
   journalctl -u ModemManager
   journalctl -u lenovo-sar-config
   ```