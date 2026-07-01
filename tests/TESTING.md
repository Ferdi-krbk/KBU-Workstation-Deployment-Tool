# Testing Strategy — KBU Workstation Deployment Tool

---

## Overview

The KBU Workstation Deployment Tool is a system-administration utility that installs software, modifies the Windows Registry, copies files, and restarts system processes. **It cannot be safely unit-tested in isolation** because its primary function is to interact with the live operating system.

This document explains the testing approach — why manual testing is the right choice today, why automated tests were added for pure-logic modules, and how testing can evolve.

---

## Automated Tests: Pester Suite

### Test Structure

```
tests/
├── deployment.tests.ps1      ← 54 Pester tests (6 modules, 26 Contexts)
├── TestConfig.ps1             ← Helper to generate test config.json payloads
├── manual-test-plan.md        ← 20 manual test cases
├── manual-test-results.md     ← Completed results (100% pass)
└── TESTING.md                 ← This file
```

### Coverage by Module

| Module | Tests | What Is Tested | What Is Mocked |
|--------|-------|---------------|----------------|
| `Config.ps1` | 19 | Valid config loading, path resolution, default values, missing/invalid JSON detection, required field validation | Nothing — creates real `config.json` in `%TEMP%` |
| `Logger.ps1` | 7 | Log file creation, message appending, UTF-8 encoding, console status functions, null-path safety | Nothing — writes to `%TEMP%` |
| `Network.ps1` | 4 | Function existence, parameter validation, mandatory attribute check | `Test-Connection` bypassed (PS 5.1 compatibility) |
| `Installer.ps1` | 15 | File existence checks, AnyDesk copy, Java silent-install fallback chain, enVision fallback chain, missing-installer handling | `Start-Process` — all process execution mocked |
| `Desktop.ps1` | 4 | Add-DesktopIcons with mocked registry, Update-ExplorerShell with mocked processes, error resilience | `New-Item`, `Set-ItemProperty`, `Stop-Process`, `Start-Process` |
| `Deploy.ps1` | 7 | Function inventory (16 module functions), dependency verification | Module-level smoke tests — no config required |

### Running Tests

```powershell
# Requires Pester 3.x or later
Import-Module Pester -Force
Invoke-Pester -Path tests/deployment.tests.ps1
```

**Expected output:** 54 tests, 0 failures, ~3 seconds.

### Why Some Components Are Mocked

| Component | Reason |
|-----------|--------|
| `Start-Process` | Would launch real installers — destructive and slow |
| `Set-ItemProperty` | Writes to live registry — requires admin and could corrupt the test machine |
| `New-Item` (registry) | Creates registry keys — not safe in CI |
| `Stop-Process -Name explorer` | Kills the Windows shell — test session would die |
| `Test-Connection` | Requires real network; PS 5.1 lacks `-TimeoutMilliseconds` parameter used in code |

### Why Manual Testing Is Still Required

| Operation | Why It Cannot Be Automated |
|-----------|---------------------------|
| `Copy-Item` to Desktop | Requires a real user profile directory |
| `Start-Process -Wait Setup.exe` | Requires actual 200 MB+ installer binary |
| `Set-ItemProperty -Path HKCU:\...` | Requires live registry with correct permissions |
| `Stop-Process -Name explorer` | Kills the shell — impossible in CI |
| End-to-end deployment | Requires clean Windows 10 VM snapshot |

**Manual testing remains the primary validation method for system-mutation operations.** The Pester suite validates pure-logic functions (config parsing, logging, parameter validation, fallback chains).

---

## Future: CI/CD Integration

Once Pester tests are in place, they can be wired into GitHub Actions:

```yaml
name: PowerShell Tests
on: [push, pull_request]
jobs:
  pester:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Pester tests
        run: |
          Import-Module Pester -Force
          Invoke-Pester -Path tests/deployment.tests.ps1
```

---

## Testing Principles

1. **Automated for pure logic** — config parsing, logging, fallback chains, parameter validation
2. **Manual for system mutation** — installer execution, registry writes, explorer restart
3. **Mock destructively** — `Start-Process`, registry writes, process termination are always mocked
4. **Temp folders only** — no test writes to Desktop, Program Files, or permanent locations
5. **Full test plan before every release** — no release ships without passing Pester + manual tests

---

## References

- [Pester Documentation](https://pester.dev/)
- [Keep a Changelog](https://keepachangelog.com/)
- [PowerShell Scripting Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction)

