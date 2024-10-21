# Universal Android Screen Resolution Manager

A powerful and user-friendly bash script for managing screen resolution and density settings on any Android device. This tool provides an interactive dialog-based interface with comprehensive preset management and device-specific configurations.

![License](https://img.shields.io/badge/License-Custom-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android-blue.svg)
![Version](https://img.shields.io/badge/Version-2.1-orange.svg)

## 🌟 Features

- 📱 Works with any Android device
- 🧙‍♂️ First-time setup wizard
- 📊 Automatic DPI calculation based on screen size
- 💾 Save and manage custom resolution presets
- 🔄 Backup and restore functionality
- 🛡️ Safety checks and confirmation dialogs
- 🎯 Device-specific configuration storage
- 🖥️ Interactive dialog-based interface

## 📋 Prerequisites

- Android device with USB debugging enabled
- ADB (Android Debug Bridge) installed on your computer
- `dialog` package installed on your system
- Root access (may be required on some devices)

## 🚀 Installation

1. Clone the repository or download the script:
```bash
git clone https://github.com/yourusername/android-screen-manager.git
```

2. Make the script executable:
```bash
chmod +x screen-res.sh
```

## 📱 Device Setup

1. Enable USB debugging on your Android device:
   - Go to Settings > About Phone
   - Tap Build Number 7 times to enable Developer Options
   - Go to Settings > Developer Options
   - Enable USB Debugging

2. Connect your device and verify ADB connection:
```bash
adb devices
```

## 💻 Usage

1. Connect to your Android device via ADB shell:
```bash
adb shell
```

2. Navigate to the script location:
```bash
cd /path/to/script
```

3. Run the script:
```bash
./screen-res.sh
```

### First Time Setup
On first run, the setup wizard will guide you through:
- Device name configuration
- Screen size specification
- Default resolution settings
- Default DPI settings

### Main Functions

1. **View Current Settings**
   - Shows current resolution and density
   - Displays device-specific configuration

2. **Custom Resolution**
   - Set custom width and height
   - Automatic DPI calculation
   - Safety checks for valid ranges

3. **Preset Management**
   - Save custom resolutions as presets
   - Apply saved presets
   - Delete unwanted presets
   - View preset details before applying

4. **Backup and Restore**
   - Backup current settings
   - Restore previous configurations
   - Safe restore with confirmation

5. **Default Settings**
   - Revert to default resolution
   - Revert to default DPI
   - Safe revert with confirmation

## 📁 Configuration Files

The script stores all configurations in `~/.config/android-screen-manager/`:

- `config.conf`: Device-specific settings
  ```bash
  DEVICE_NAME="Your Device"
  SCREEN_DIAGONAL=6.1
  DEFAULT_WIDTH=1080
  DEFAULT_HEIGHT=2400
  DEFAULT_DENSITY=440
  ```

- `screen_presets.txt`: Custom resolution presets
- `screen_backup.txt`: Backup settings

## 🛡️ Safety Features

- Resolution range validation
- DPI calculation verification
- Confirmation dialogs for changes
- Input validation
- Error handling
- Safe file operations

## ⚠️ Troubleshooting

1. **Script won't run**
   - Verify script permissions
   - Ensure dialog package is installed
   - Check ADB connection

2. **Resolution change failed**
   - Check root access
   - Verify input values
   - Check device compatibility

3. **Presets not showing**
   - Check preset file permissions
   - Verify preset file format
   - Add new presets if empty

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📝 License

© anlaki - 2024

## 🙏 Acknowledgments

- Special thanks to all contributors
- Android Debug Bridge (ADB) team
- Dialog package maintainers

## 📞 Support

If you encounter any issues or have suggestions:
1. Check the troubleshooting guide
2. Open an issue on GitHub
3. Contribute a fix via pull request

---
Made with ❤️ by anlaki
