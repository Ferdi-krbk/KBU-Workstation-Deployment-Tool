# Changelog

All notable changes to the KBU Workstation Deployment Tool are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.4.0] — 2026-07-01

### Added

- **Pester 5 testing suite** — 63 automated tests, zero failures, PS 5.1 compatible
- **Config module tests** (19) — valid/invalid JSON, missing fields, default values, path resolution
- **Logger module tests** (7) — file creation, message appending, console output safety
- **Network module tests** (4) — function structure, parameter validation, mandatory attributes
- **Installer module tests** (15) — file existence, AnyDesk copy, Java/enVision fallback chains
- **Desktop module tests** (4) — mocked registry writes, explorer restart resilience
- **Deploy module tests** (7) — function inventory (16 functions), dependency verification
- Test helper `tests/TestConfig.ps1` for generating config.json payloads in temp directories
- Testing section in README with coverage table and run instructions

### Documentation

- **TESTING.md rewritten** — automated test structure, mock rationale, Pester run instructions, CI/CD template
- **README.md** updated with Testing section (coverage by module, how to run)
- **CHANGELOG.md** updated with v1.4.0 entry

---

## [1.3.0] — 2026-06-30

### Added

- **Hybrid Batch + PowerShell architecture** — thin launchers (`kurulum.bat`, `deploy.bat`) delegate to PowerShell engine
- **Modular PowerShell deployment engine** — six domain modules in `src/` (`Config.ps1`, `Logger.ps1`, `Network.ps1`, `Installer.ps1`, `Desktop.ps1`, `Deploy.ps1`)
- **Comprehensive manual testing documentation** — `tests/manual-test-plan.md` (20 cases), `tests/manual-test-results.md` (100% pass), `tests/TESTING.md` (strategy + Pester examples)
- **Extended `config.json`** — `installers`, `desktop`, `timing`, and `app` sections with 24 configurable fields
- Configurable Java and enVision silent-install arguments, desktop icon GUIDs, registry path, console colours, date format, timing values
- Admin privilege check in launchers before PowerShell launch
- Guard clause on Deploy.ps1 main loop — safe to dot-source without running
- Mandatory parameter validation on all 6 installer functions
- try/catch error handling on main loop, installer fallback paths, and registry operations

### Changed

- **`kurulum.bat` converted into a thin launcher** — original 722-line Batch logic preserved in `legacy/kurulum_legacy.bat`
- **Deployment logic moved into modular PowerShell scripts** — each module has a single responsibility
- All PowerShell modules receive configuration as parameters (zero hardcoded values)
- `Network.ps1`, `Desktop.ps1`, `Installer.ps1` functions accept config-driven parameters
- `Config.ps1` builds default objects as variables before `Add-Member` (resolves parser ambiguity)
- `Deploy.ps1` consolidated repetitive box-drawing into `Write-BoxHeader` and `Write-TestSummary` helpers
- Test Mode loop replaced with declarative `$checks` array (DRY)
- `Refresh-Explorer` renamed to `Update-ExplorerShell` (approved PowerShell verb)
- `Test-InstallerExists` helper extracted to eliminate 6 identical file-existence guards
- Improved `.gitignore` with binary and installer folder exclusions

### Documentation

- **README rewritten** for hybrid architecture — architecture diagram, config reference table, repo and USB folder structures, deployment workflow
- **CHANGELOG maintained in Keep a Changelog format** across all versions
- **Manual testing suite added** — test plan, completed results, and testing strategy
- Added Future Improvements roadmap

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
