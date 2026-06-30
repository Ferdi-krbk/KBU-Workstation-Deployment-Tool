# Changelog

All notable changes to the KBU Workstation Deployment Tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.2.0] - 2026-06-30

### Added

- External configuration via `config.json`
- Configuration validation with graceful error handling
- Configurable installer paths, directory names, and application branding
- Configurable log file name and location
- Configurable internet check targets and timeout
- Dynamic internet connectivity check (reads targets from config)
- Configuration section in README
- Architecture section in README
- Project structure documentation in README
- Deployment workflow diagram in README
- CHANGELOG.md

### Changed

- All installer paths moved from hardcoded values to `config.json`
- Application version, title, and institution loaded from configuration
- Internet check now iterates over configurable target list
- Log file path built dynamically from configuration settings
- Test Mode displays dynamic directory names from config

### Documentation

- Updated README with Configuration and Architecture sections
- Added configuration example table
- Added project structure diagram
- Added architecture and workflow documentation

---

## [1.1.0] - 2026

### Added

- Test Mode (Dry Run) with 9-point USB content validation
- Multi-target internet connectivity verification (Google DNS, google.com, Cloudflare)
- Pass/fail counter with summary in Test Mode
- Colored console output for Test Mode results
- Step counter for offline installation (1/6 to 6/6)

### Changed

- Refactored internet check to try multiple endpoints sequentially
- Improved error messages with expected paths displayed on failure
- Test Mode displays "HICBIR KURULUM VEYA DEGISIKLIK YAPILMAZ" warning banner
- Code cleanup and structure improvements

---

## [1.0.0] - 2026

### Initial Release

- Windows workstation deployment automation
- Offline installation workflow (AnyDesk, Akia, Java JRE, Microsoft Office)
- Online installation workflow (enVision.Client.Service, Ninite packages)
- Registry-based desktop icon configuration (This PC, Control Panel, Network, Recycle Bin)
- Windows Explorer refresh after desktop modifications
- Silent Java JRE installation with fallback strategies
- Step-by-step installation logging to Desktop
- UTF-8 Turkish character support
- Interactive console menu with color-coded output
- Comprehensive error handling with file existence checks
- Graceful fallbacks when installers are missing or fail
