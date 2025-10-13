# Driven Repairs Installer

This directory contains the installer configuration for the Driven Repairs Windows application.

## Requirements

To build the installer, you need:

1. **Inno Setup** - Download from https://jrsoftware.org/isinfo.php
2. **Completed Flutter build** - Run `flutter build windows --release` first

## Building the Installer

1. **Install Inno Setup** from the official website
2. **Build your Flutter app** (if not already done):
   ```powershell
   flutter build windows --release
   ```
3. **Open Inno Setup Compiler**
4. **Load the script**: Open `driven_repairs_setup.iss`
5. **Compile**: Press F9 or go to Build → Compile

## Output

The installer will be created as:
```
build/installer/DrivenRepairs_Setup_v1.0.0.exe
```

## Customization

### Update Version
Edit the version in both:
- `pubspec.yaml` (line 20)
- `driven_repairs_setup.iss` (line 6)

### Change App Details
In `driven_repairs_setup.iss`, modify:
- `MyAppName` - Application name
- `MyAppPublisher` - Your company name
- `MyAppURL` - Your website
- App GUID (generate new one for different apps)

### Add App Icon
Place your app icon at:
```
windows/runner/resources/app_icon.ico
```

## Features Included

✅ **Professional Installation Wizard**
✅ **Desktop & Start Menu shortcuts**
✅ **Automatic uninstaller**
✅ **Registry entries for file associations**
✅ **Custom welcome message**
✅ **Data location information**
✅ **Modern wizard style**
✅ **64-bit Windows support**
✅ **Minimum Windows 10 requirement**

## Distribution

The generated installer:
- Is a single `.exe` file
- Contains all required files
- Handles installation/uninstallation
- Creates proper shortcuts
- Shows installation progress
- Can be digitally signed (recommended for distribution)

## Digital Signing (Optional)

For professional distribution:
1. Get a code signing certificate
2. Add signing commands to the Inno Setup script
3. This prevents Windows security warnings

## Troubleshooting

**"File not found" errors:**
- Ensure `flutter build windows --release` completed successfully
- Check that all paths in the script are correct

**"Permission denied":**
- Run Inno Setup as Administrator
- Check antivirus software isn't blocking the build