# KBU Workstation Deployment Tool

Windows Batch-based deployment automation tool developed during my internship at Karabuk University IT Department.

## Features

- **Offline Installation Workflow** — AnyDesk, Akia, Java JRE, Microsoft Office deployment without internet
- **Online Installation Workflow** — enVision.Client.Service + Ninite package manager with internet connectivity check
- **Dry Run / Test Mode** — Validates all files, folders and internet connection without installing or modifying anything
- **Internet Connectivity Check** — Multi-target ping verification with configurable endpoints
- **Desktop Shortcut Configuration** — Registry-based toggling of This PC, Control Panel, Network, Recycle Bin icons
- **Silent Java Installation** — Multiple fallback strategies for unattended JRE deployment
- **AnyDesk Deployment** — Copies AnyDesk directly to user's Desktop
- **Installation Logging** — Step-by-step log written to Desktop (`kurulum_log.txt`)
- **Comprehensive Error Handling** — File existence checks before every operation, graceful fallbacks
- **Colored Console Output** — Green/red/yellow status messages for readability
- **Turkish Language Support** — Full UTF-8 support via `chcp 65001`
- **External Configuration** — All paths, names and settings loaded from `config.json`

## Requirements

- Windows 10 (64-bit)
- Administrator privileges
- PowerShell 5.1+ (included with Windows 10)
- USB flash drive with the following structure:

```
USB_ROOT
├── kurulum.bat
├── config.json
├── Kbu
│   ├── AnyDesk.exe
│   ├── Akia_windows-x64_6_7_6.exe
│   ├── jre-8u411-windows-x64.exe
│   ├── enVision.Client.Service.exe
│   └── Ninite Chrome Firefox Foxit Reader GOM Installer.exe
└── Office Cevrimdisi
    └── Setup.exe
```

## Usage

1. Plug the USB drive into a fresh Windows 10 computer
2. Right-click `kurulum.bat` → **Run as Administrator**
3. Choose **[0]** Test Mode first to verify USB contents
4. Select **[1]** Offline or **[2]** Online installation based on your needs
5. Wait for completion — a log file will be saved to Desktop

## Configuration

All settings are defined in `config.json` at the USB root. This separates configuration from application logic, enabling:

- **Maintainability** — Change paths or names without editing source code
- **Scalability** — Add or remove installer entries by updating the config
- **Flexibility** — Customize logging location, application branding, and internet check targets
- **Portability** — The same script works with different USB folder layouts by swapping config files

### Configuration Example

```json
{
    "version": "1.2.0",

    "paths": {
        "kbu_directory": "Kbu",
        "office_directory": "Office Cevrimdisi",
        "anydesk": "Kbu\\AnyDesk.exe",
        "akia": "Kbu\\Akia_windows-x64_6_7_6.exe",
        "java": "Kbu\\jre-8u411-windows-x64.exe",
        "envision": "Kbu\\enVision.Client.Service.exe",
        "ninite": "Kbu\\Ninite Chrome Firefox Foxit Reader GOM Installer.exe",
        "office": "Office Cevrimdisi\\Setup.exe"
    },

    "logging": {
        "filename": "kurulum_log.txt",
        "location": "desktop"
    },

    "internet_check": {
        "targets": ["8.8.8.8", "google.com", "1.1.1.1"],
        "timeout_ms": 3000
    },

    "app": {
        "title": "KBU Workstation Deployment Tool",
        "name": "KBU Workstation Deployment Tool",
        "institution": "Karabuk Universitesi - Bilgi Islem Daire Baskanligi"
    }
}
```

| Field | Description |
|-------|-------------|
| `version` | Application version displayed in menus and logs |
| `paths.*` | Relative paths from USB root to installers |
| `logging.filename` | Log file name |
| `logging.location` | `"desktop"` or a custom path (absolute or relative to USB root) |
| `internet_check.targets` | Hostnames/IPs to ping for connectivity check |
| `internet_check.timeout_ms` | Ping timeout in milliseconds |
| `app.*` | Application branding (title bar, menu header, institution name) |

### Configuration Validation

If `config.json` is missing, contains invalid JSON, or lacks required fields, the application:

1. Displays a clear error message on screen
2. Writes the error to the fallback log file
3. Exits gracefully without crashing

## Project Structure

```
USB_ROOT/
├── kurulum.bat          # Main deployment script (entry point)
├── config.json          # External configuration file
├── LICENSE              # MIT License
├── README.md            # Project documentation
├── CHANGELOG.md          # Release history
├── .gitignore           # Git ignore rules
├── screenshots/         # UI screenshots
│   ├── anamenu.png
│   └── testmod.png
├── Kbu/                 # Installer packages directory
│   ├── AnyDesk.exe
│   ├── Akia_windows-x64_6_7_6.exe
│   ├── jre-8u411-windows-x64.exe
│   ├── enVision.Client.Service.exe
│   └── Ninite Chrome Firefox Foxit Reader GOM Installer.exe
└── Office Cevrimdisi/   # Office offline installer directory
    └── Setup.exe
```

## Architecture

```
kurulum.bat
├── Config Loading (config.json parsing via PowerShell)
│   ├── File existence check
│   ├── JSON validation
│   ├── Required field validation
│   └── Environment variable initialization
│
├── Main Menu
│   ├── [0] Test Mode (Dry Run)
│   ├── [1] Offline Installation
│   ├── [2] Online Installation
│   └── [3] Exit
│
├── Offline Installation Workflow
│   ├── 1. AnyDesk → Desktop copy
│   ├── 2. Akia → Interactive install
│   ├── 3. Java JRE → Silent install (2 fallback methods)
│   ├── 4. Office → Interactive install
│   ├── 5. Desktop icons → Registry modifications
│   └── 6. Explorer refresh
│
├── Online Installation Workflow
│   ├── Internet connectivity check (multi-target ping)
│   ├── 1. enVision.Client.Service → Silent install (2 fallback methods)
│   └── 2. Ninite → Interactive install
│
├── Test Mode (Dry Run)
│   ├── USB folder validation (9 checks)
│   ├── File existence verification
│   └── Internet connectivity check
│
└── Helper Functions
    ├── :check_internet  — Multi-target ping with configurable timeout
    ├── :add_desktop_icons — Registry-based desktop icon toggle
    ├── :refresh_explorer — Windows Explorer restart
    ├── :log — Timestamped logging to file
    ├── :show_ok / :show_err / :show_warn — Colored console output
    └── :check_item — Single file/folder validation for Test Mode
```

## Deployment Workflow

```
User plugs in USB drive
        │
        ▼
Run kurulum.bat as Administrator
        │
        ▼
config.json loaded and validated
        │
        ├── Missing/Invalid → Error message, log, graceful exit
        │
        ▼
Main Menu displayed
        │
        ├── [0] Test Mode        → Validate USB contents (9 checks)
        │                          → Report pass/fail counts
        │                          → Return to menu
        │
        ├── [1] Offline Install  → Check each file exists
        │                          → Install sequentially
        │                          → Add desktop icons
        │                          → Refresh Explorer
        │                          → Return to menu
        │
        ├── [2] Online Install   → Check internet connectivity
        │                          → Install enVision
        │                          → Install Ninite packages
        │                          → Return to menu
        │
        └── [3] Exit             → Write final log entry
                                   → Close application
```

## Screenshots

### Main Menu

![Main Menu](screenshots/anamenu.png)

### Test Mode

![Test Mode](screenshots/testmod.png)

## Notes

- Test Mode performs **zero installations and zero system modifications** — it only checks file/folder existence
- Offline installation refreshes Windows Explorer after adding desktop icons
- Online installation requires an active internet connection — if unavailable, the script will prompt you to use offline mode instead
- All operations are logged to `%USERPROFILE%\Desktop\kurulum_log.txt` (configurable via `config.json`)
- Configuration is loaded at startup via PowerShell — `config.json` must be valid JSON with all required fields

## License

MIT License — see [LICENSE](LICENSE) for details.
