# Changelog

All notable changes to the KBU Workstation Deployment Tool are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.3.0] — 2026-06-30

### Added

- **Hybrid Batch + PowerShell architecture** — `deploy.bat` is a thin launcher; all logic in `src/` PowerShell modules
- **Modular PowerShell engine** — six domain modules (`Config.ps1`, `Logger.ps1`, `Network.ps1`, `Installer.ps1`, `Desktop.ps1`, `Deploy.ps1`)
- **Comprehensive `config.json`** — `installers`, `desktop`, `timing`, and `app` sections added
- Configurable Java and enVision silent-install arguments
- Configurable desktop icon GUIDs and registry path
- Configurable console colours (`background_color`, `foreground_color`)
- Configurable timestamp format (`date_format`)
- Configurable wait durations (`invalid_choice_wait_seconds`, `exit_wait_seconds`, `explorer_wait_seconds`)
- Admin privilege check in `deploy.bat` before launching PowerShell
- Guard clause on main loop — `Deploy.ps1` is safe to dot-source without running

### Changed

- All PowerShell modules receive configuration as parameters (no hardcoded values)
- `Network.ps1` parameter defaults removed — caller provides targets and timeout
- `Desktop.ps1` accepts icon objects and registry path as parameters
- `Installer.ps1` functions accept `-SilentArgs1` / `-SilentArgs2` parameters
- `Config.ps1` builds default objects as variables before `Add-Member` (resolves parser ambiguity)
- `Deploy.ps1` consolidated repetitive box-drawing into `Write-BoxHeader` and `Write-TestSummary` helpers
- Test Mode loop replaced with declarative `$checks` array (DRY)

### Documentation

- Rewritten README with Hybrid Architecture explanation, architecture diagram, config reference table
- Added Future Improvements section
- Updated KEEP A CHANGELOG format

---

## [1.2.0] — 2026-06-30

### Added

- External configuration via `config.json`
- Configuration validation with graceful error handling (missing file, invalid JSON, missing fields)
- Configurable installer paths, directory names, and application branding from `config.json`
- Configurable log file name and location
- Configurable internet check targets (`internet_check.targets`) and timeout (`internet_check.timeout_ms`)
- Dynamic internet connectivity check — iterates over targets from config
- CHANGELOG.md in Keep a Changelog format

### Changed

- All installer paths moved from hardcoded values to `config.json`
- Application version, title, and institution loaded from configuration
- Log file path built dynamically from config `logging.location` (supports `"desktop"`, absolute, and relative)
- Test Mode displays directory names from config instead of hardcoded labels

### Documentation

- README updated with Configuration, Architecture, Project Structure, and Deployment Workflow sections

---

## [1.1.0] — 2026

### Added

- **Test Mode (Dry Run)** — 9-point USB content validation with zero installations and zero system changes
- Multi-target internet connectivity check (Google DNS `8.8.8.8`, `google.com`, Cloudflare `1.1.1.1`)
- Pass/fail counter with colour-coded summary in Test Mode
- Step counter labels (`[1/6]` through `[6/6]`) for offline installation
- Warning banner "HICBIR KURULUM VEYA DEGISIKLIK YAPILMAZ" in Test Mode

### Changed

- Internet connectivity check now tries multiple endpoints sequentially before failing
- Improved error messages — expected file paths displayed on failure
- Code structure cleaned up

---

## [1.0.0] — 2026

### Added

- **Offline Install Workflow**: AnyDesk (desktop copy), Akia, Java JRE (silent with 2 fallback methods), Microsoft Office
- **Online Install Workflow**: enVision.Client.Service (silent with 2 fallback methods), Ninite package bundle
- **Interactive Console Menu** with Unicode box-drawing characters and colour-coded output (green/red/yellow/cyan/magenta)
- **Desktop Icon Configuration** via Registry (`HideDesktopIcons\NewStartPanel`) — This PC, Control Panel, Network, Recycle Bin
- **Windows Explorer Refresh** after desktop icon changes
- **Step-by-step Installation Logging** to `%USERPROFILE%\Desktop\kurulum_log.txt`
- **UTF-8 Support** via `chcp 65001` for Turkish character display
- **Graceful Error Handling** — file existence checks before every operation, fallbacks when installers are missing or fail
- USB root auto-detection (`KBU_USB_ROOT` environment variable or script location)
