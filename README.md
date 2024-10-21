# Universal Android Screen Resolution Manager

A simple script to manage screen resolution and density settings on Android devices through Termux.

## Requirements

1. Install Termux from F-Droid (recommended) or Play Store
2. Required packages:

Install all needed packages with one command:
```bash
pkg update && pkg install -y dialog tsu
```

Or install them individually:
- `pkg install dialog` - for the user interface
- `pkg install tsu` - for root access

## Installation

1. Create a directory for the script:
```bash
mkdir -p ~/phone_settings
```

2. Download the script and make it executable:
```bash
cd ~/phone_settings
curl -O https://raw.githubusercontent.com/anlaki-py/screen-res/main/screen-res.sh
chmod +x screen-res.sh
```

## Usage

Run the script with:
```bash
sudo bash ~/phone_settings/screen-res.sh
```

On first run:
0. Select 
1. Enter your device name
2. Enter your screen size (in inches)
3. Default resolution and DPI will be automatically detected

## Features

- Change screen resolution
- Save and load resolution presets
- Backup and restore settings
- Automatic DPI calculation
- Revert to default settings

## Troubleshooting

If the script doesn't work:
1. Make sure you installed all required packages
2. Check if you have root access (`sudo su`)
3. Verify the script has execute permissions

## License

© anlaki - 2024
