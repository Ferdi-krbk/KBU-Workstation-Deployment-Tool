# KBU Workstation Deployment Tool

Karabuk Universitesi - Bilgi Islem Daire Baskanligi

Automated workstation deployment tool for Windows 10. Installs and configures a full software stack from a USB drive in offline or online mode.

---

## Project Overview

When deploying new workstations at the university, IT staff must manually install multiple applications (Office, Java, Akia, AnyDesk, enVision, browsers). This tool automates the entire process:

1. **Plug USB** into the new computer
2. **Run as Administrator** (one double-click)
3. **Choose mode** from interactive menu
4. **Walk away** — everything installs automatically

All operations are logged. A Dry Run mode validates USB contents before committing to installation.

---

## Features

### Core Capabilities
- **Offline Installation** — AnyDesk, Akia, Java JRE (silent), Microsoft Office, desktop icons
- **Online Installation** — enVision.Client.Service (silent), Ninite package bundle (Chrome, Firefox, Foxit, GOM)
- **Dry Run / Test Mode** — 9-point validation of USB contents and internet connectivity; zero changes to the system
- **Desktop Customization** — Registry-based toggle for This PC, Control Panel, Network, and Recycle Bin icons

### Engineering Quality
- **Hybrid Batch + PowerShell Architecture** — `kurulum.bat` / `deploy.bat` are thin launchers; all logic lives in modular `src/` PowerShell scripts
- **External Configuration** — Every path, installer argument, icon GUID, colour, and timing value lives in `config.json`
- **Graceful Error Handling** — File existence checks before every operation, multiple silent-install fallbacks, missing config exits cleanly
- **Comprehensive Logging** — Step-by-step log written to Desktop (`kurulum_log.txt`), configurable via `config.json`
- **Coloured Console Output** — Green (success), red (error), yellow (warning), cyan (online), magenta (test)
- **UTF-8 Support** — Full Turkish character support

---

## Hybrid Batch + PowerShell Architecture

The project uses a **thin-launcher pattern**:

```
kurulum.bat         →  2 %  of logic   (admin check, launch PowerShell)
deploy.bat          →  2 %  of logic   (alternative launcher)
src/Deploy.ps1      →  60 % of logic   (menu orchestrator, workflow controller)
src/Config.ps1      →  15 % of logic   (config.json loading and validation)
src/Installer.ps1   →  10 % of logic   (6 installer functions)
src/Desktop.ps1     →   5 % of logic   (registry icons, explorer refresh)
src/Logger.ps1      →   4 % of logic   (file logging, coloured console)
src/Network.ps1     →   4 % of logic   (multi-target ping verification)
```

### Why Hybrid?

| Layer | Technology | Role |
|-------|-----------|------|
| `kurulum.bat` | Windows Batch | Admin privilege check, code page setup, PowerShell bootstrap — primary entry point for IT staff |
| `deploy.bat` | Windows Batch | Alternative launcher with identical behaviour — also calls `src/Deploy.ps1` |
| `src/*.ps1` | PowerShell 5.1+ | All deployment logic, config validation, installer orchestration, logging |

**Benefits over pure Batch:**
- Native JSON parsing — no fragile `for /f` hacks
- Structured error handling (`try/catch`)
- Named parameters on every function
- Registry operations via `Set-ItemProperty` instead of `reg add`
- `Test-Connection` cmdlet instead of `ping` parsing
- Proper `Copy-Item`, `Start-Process` with exit code inspection

---

## Architecture

```
                               ┌──────────────────────┐
                               │   kurulum.bat /       │
                               │   deploy.bat          │
                               │  (Thin Launchers)     │
                               └──────────┬───────────┘
                                          │ powershell -File
                                          ▼
                               ┌──────────────────────┐
                               │    src/Deploy.ps1     │
                               │  (Entry Point / Menu) │
                               └──────────┬───────────┘
                                          │ dot-source
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
                    ▼                     ▼                     ▼
          ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
          │   Config.ps1    │   │   Logger.ps1    │   │  Network.ps1    │
          │  ┌───────────┐  │   │  ┌───────────┐  │   │  ┌───────────┐  │
          │  │ Validate  │  │   │  │ Log Path  │  │   │  │ Ping      │  │
          │  │ JSON      │  │   │  │ Setup     │  │   │  │ Targets   │  │
          │  │ Defaults  │  │   │  │ Write Log │  │   │  │ Return OK │  │
          │  │ Resolve   │  │   │  │ Status    │  │   │  └───────────┘  │
          │  │ Paths     │  │   │  │ Output    │  │   └─────────────────┘
          │  └───────────┘  │   │  └───────────┘  │
          └─────────────────┘   └─────────────────┘
                    │
                    │
          ┌─────────────────┐   ┌─────────────────┐
          │  Installer.ps1  │   │  Desktop.ps1    │
          │  ┌───────────┐  │   │  ┌───────────┐  │
          │  │ AnyDesk   │  │   │  │ Icons     │  │
          │  │ Akia      │  │   │  │ Registry  │  │
          │  │ Java (3)  │  │   │  │ Explorer  │  │
          │  │ Office    │  │   │  │ Refresh   │  │
          │  │ enVision  │  │   │  └───────────┘  │
          │  │ Ninite    │  │   └─────────────────┘
          │  └───────────┘  │
          └─────────────────┘

                          ┌──────────────────────┐
                          │     config.json       │
                          │  ┌──────────────────┐ │
                          │  │ paths            │ │
                          │  │ logging          │ │
                          │  │ internet_check   │ │
                          │  │ app              │ │
                          │  │ installers       │ │
                          │  │ desktop          │ │
                          │  │ timing           │ │
                          │  └──────────────────┘ │
                          └──────────────────────┘
```

### Data Flow

```
config.json ──► Config.ps1 ──► $Cfg object ──► All other modules
                                       │
                     ┌─────────────────┼──────────────────┐
                     ▼                 ▼                  ▼
              Installer.ps1     Desktop.ps1          Network.ps1
              (paths, args)   (icons, reg path)   (targets, timeout)
```

---

## Configuration

All settings live in `config.json` at the project root. No values are hardcoded in the PowerShell modules.

### Configuration Example

```json
{
    "version": "1.3.0",

    "paths": {
        "kbu_directory": "Kbü",
        "office_directory": "Office Cevrimdisi",
        "anydesk": "Kbü\\AnyDesk.exe",
        "akia": "Kbü\\Akia_windows-x64_6_7_6.exe",
        "java": "Kbü\\jre-8u411-windows-x64.exe",
        "envision": "Kbü\\enVision.Client.Service.exe",
        "ninite": "Kbü\\Ninite Chrome Firefox Foxit Reader GOM Installer.exe",
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
        "institution": "Karabuk Universitesi - Bilgi Islem Daire Baskanligi",
        "date_format": "dd.MM.yyyy - HH:mm:ss",
        "background_color": "DarkBlue",
        "foreground_color": "White"
    },

    "installers": {
        "java": {
            "silent_args_1": "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H",
            "silent_args_2": "INSTALL_SILENT=1 REBOOT=Suppress"
        },
        "envision": {
            "silent_args_1": "/quiet /norestart",
            "silent_args_2": "/S"
        }
    },

    "desktop": {
        "icons": {
            "Bu PC": "{20D04FE0-3AEA-1069-A2D8-08002B30309D}",
            "Denetim Masasi": "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}",
            "Ag": "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}",
            "Geri Donusum Kutusu": "{645FF040-5081-101B-9F08-00AA002F954E}"
        },
        "registry_path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\HideDesktopIcons\\NewStartPanel",
        "explorer_wait_seconds": 2
    },

    "timing": {
        "invalid_choice_wait_seconds": 2,
        "exit_wait_seconds": 2
    }
}
```

### Configuration Reference

| Section | Field | Type | Required | Default | Description |
|---------|-------|------|----------|---------|-------------|
| | `version` | string | Yes | — | App version displayed in UI |
| `paths` | `kbu_directory` | string | Yes | — | KBU installer folder name |
| `paths` | `office_directory` | string | Yes | — | Office folder name |
| `paths` | `anydesk` | string | Yes | — | AnyDesk installer relative path |
| `paths` | `akia` | string | Yes | — | Akia installer relative path |
| `paths` | `java` | string | Yes | — | Java JRE installer relative path |
| `paths` | `envision` | string | Yes | — | enVision installer relative path |
| `paths` | `ninite` | string | Yes | — | Ninite installer relative path |
| `paths` | `office` | string | Yes | — | Office Setup.exe relative path |
| `logging` | `filename` | string | Yes | — | Log file name |
| `logging` | `location` | string | Yes | — | `"desktop"`, absolute path, or relative to USB root |
| `internet_check` | `targets` | string[] | No | `["8.8.8.8","google.com","1.1.1.1"]` | Ping targets for connectivity |
| `internet_check` | `timeout_ms` | int | No | `3000` | Ping timeout per target |
| `app` | `title` | string | No | `"KBU..."` | Window title bar text |
| `app` | `name` | string | No | `"KBU..."` | Application display name |
| `app` | `institution` | string | No | `"Karabuk..."` | Institution name in header |
| `app` | `date_format` | string | No | `"dd.MM.yyyy - HH:mm:ss"` | Timestamp format in logs |
| `app` | `background_color` | string | No | `"DarkBlue"` | Console background colour |
| `app` | `foreground_color` | string | No | `"White"` | Console foreground colour |
| `installers.java` | `silent_args_1` | string | No | `"/s REBOOT=0..."` | First silent install attempt |
| `installers.java` | `silent_args_2` | string | No | `"INSTALL_SILENT=1..."` | Second silent install attempt |
| `installers.envision` | `silent_args_1` | string | No | `"/quiet /norestart"` | First silent install attempt |
| `installers.envision` | `silent_args_2` | string | No | `"/S"` | Second silent install attempt |
| `desktop` | `icons` | object | No | 4 GUIDs | Desktop icon CLSID registry values |
| `desktop` | `registry_path` | string | No | `"HKCU:\\..."` | HideDesktopIcons registry path |
| `desktop` | `explorer_wait_seconds` | int | No | `2` | Wait time after killing explorer.exe |
| `timing` | `invalid_choice_wait_seconds` | int | No | `2` | Pause after invalid menu choice |
| `timing` | `exit_wait_seconds` | int | No | `2` | Pause before closing on exit |

### Configuration Validation

`Config.ps1` validates at three levels:

| Failure | Behaviour |
|---------|-----------|
| `config.json` missing | Red error, USB folder diagram, log to fallback file, graceful exit |
| Invalid JSON syntax | Red error with PowerShell parse message, log, graceful exit |
| Missing required field | Red error listing every missing field, log, graceful exit |
| Missing optional field | Applies sensible built-in default — no error |

**The application never crashes on configuration problems.**

---

## Folder Structure

### Repository (Git)

```
KBU-Workstation-Deployment-Tool/
│
├── kurulum.bat              ← Primary launcher (thin Batch script)
├── deploy.bat               ← Alternative launcher
├── config.json              ← External configuration (paths, settings, args)
├── CHANGELOG.md             ← Release history (Keep a Changelog)
├── README.md                ← Project documentation
├── LICENSE                  ← MIT License
├── .gitignore               ← Excludes installer binaries and logs
│
├── src/                     ← PowerShell deployment engine
│   ├── Deploy.ps1           ← Entry point, main menu, workflow orchestrator
│   ├── Config.ps1           ← config.json loader, validator, path resolver
│   ├── Logger.ps1           ← File logging and coloured console output
│   ├── Network.ps1          ← Multi-target internet connectivity check
│   ├── Installer.ps1        ← AnyDesk, Akia, Java, Office, enVision, Ninite
│   └── Desktop.ps1          ← Registry icon toggle, Explorer restart
│
├── legacy/                  ← Historical Batch implementation
│   └── kurulum_legacy.bat   ← Full Batch script preserved (v1.2.0)
│
├── tests/                   ← Testing documentation
│   ├── manual-test-plan.md  ← 20 manual test cases
│   ├── manual-test-results.md ← Completed results (100% pass)
│   └── TESTING.md           ← Testing strategy + Pester examples
│
└── screenshots/             ← UI screenshots
    ├── anamenu.png
    └── testmod.png
```

### USB Deployment Layout

The repository is deployed onto a USB drive with the following layout (installer binaries are excluded from Git via `.gitignore`):

```
USB_ROOT/
│
├── kurulum.bat
├── deploy.bat
├── config.json
├── src/
│   └── (all .ps1 modules)
│
├── Kbu/                     ← Installer packages (gitignored)
│   ├── AnyDesk.exe
│   ├── Akia_windows-x64_6_7_6.exe
│   ├── jre-8u411-windows-x64.exe
│   ├── enVision.Client.Service.exe
│   └── Ninite Chrome Firefox Foxit Reader GOM Installer.exe
│
└── Office Cevrimdisi/       ← Office offline installer (gitignored)
    └── Setup.exe
```

---

## Usage

### Quick Start

1. **Prepare USB** — Copy all files and installer packages to a USB drive
2. **Plug USB** into the new Windows 10 computer
3. **Right-click** `kurulum.bat` → **Run as Administrator**
4. **Verify** — Press `[0]` for Test Mode to check all files are present
5. **Deploy** — Press `[1]` for offline install or `[2]` for online install
6. **Done** — Log file saved to Desktop

### Menu Options

| Key | Mode | Description |
|-----|------|-------------|
| `0` | **Test Mode (Dry Run)** | Validates USB contents (9 checks). Zero installations, zero system changes. |
| `1` | **Offline Installation** | Installs AnyDesk, Akia, Java JRE, Office. Adds desktop icons. Refreshes Explorer. |
| `2` | **Online Installation** | Checks internet, then installs enVision.Client.Service and Ninite packages. |
| `3` | **Exit** | Writes final log entries, closes. |

### Administrator Privileges

`kurulum.bat` checks for admin rights before launching PowerShell. If missing, it displays an error and exits.

---

## Deployment Workflow

```
User double-clicks kurulum.bat
           │
           ▼
   [Admin privilege check]
           │
    ┌──────┴──────┐
    │ No          │ Yes
    ▼             ▼
  Error +     PowerShell launches
  Exit          src/Deploy.ps1
                    │
                    ▼
            config.json loaded
            and validated
                    │
            ┌───────┴────────┐
            │ Invalid/Missing │
            ▼                 ▼
       Error + Log        Main Menu
       Graceful Exit      Displayed
                               │
               ┌───────────────┼───────────────┐
               │               │               │
          [0] Test        [1] Offline      [2] Online
               │               │               │
               ▼               ▼               ▼
         9 USB checks    ┌─ 1. AnyDesk    ┌─ Internet check
         + internet      │  2. Akia       ├─ enVision (silent)
         check           │  3. Java       └─ Ninite packages
               │         │  4. Office         │
               ▼         │  5. Icons          ▼
         Pass/Fail       │  6. Explorer   Summary + Log
         Summary         └─ Summary + Log  Return to Menu
         Return to Menu  Return to Menu
```

---

## Screenshots

### Main Menu

![Main Menu](screenshots/anamenu.png)

### Test Mode Results

![Test Mode](screenshots/testmod.png)

---

## Future Improvements

- [ ] **Automatic config.json schema migration** — detect older config versions and upgrade fields automatically
- [ ] **Unattended Office installation** — configure Office Setup with an XML answer file for fully silent deployment
- [ ] **Progress bars** — `Write-Progress` integration for long-running installers
- [ ] **Network share deployment** — support running from a UNC path instead of requiring a USB drive
- [ ] **Post-install validation** — verify installed applications actually launch after deployment
- [ ] **Parallel Ninite-like architecture** — queue multiple installs and run them concurrently where possible
- [ ] **CI/CD pipeline** — GitHub Actions to validate `config.json` schema and PowerShell syntax on every push
- [ ] **Installer hash verification** — SHA-256 checks of installer files before execution

---

## Testing

The project includes a **Pester testing suite** with 54 automated tests covering all 6 modules.

### Running Tests

```powershell
Import-Module Pester -Force
Invoke-Pester -Path tests/deployment.tests.ps1
```

**Requirements:** Pester 3.x or later, PowerShell 5.1+

### Coverage

| Module | Tests | Approach |
|--------|-------|----------|
| Config.ps1 | 19 | Creates real config.json in `%TEMP%` — no mocks |
| Logger.ps1 | 7 | Writes to `%TEMP%` log files — no mocks |
| Network.ps1 | 4 | Validates function structure and parameters |
| Installer.ps1 | 15 | `Start-Process` mocked to simulate success/failure |
| Desktop.ps1 | 4 | Registry and process management mocked |
| Deploy.ps1 | 7 | Module integration and dependency verification |

Destructive operations are always mocked. Pure logic is tested against real functions.
See `tests/TESTING.md` for the full testing strategy.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
