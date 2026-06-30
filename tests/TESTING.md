# Testing Strategy — KBU Workstation Deployment Tool

---

## Overview

The KBU Workstation Deployment Tool is a system-administration utility that installs software, modifies the Windows Registry, copies files, and restarts system processes. **It cannot be safely unit-tested in isolation** because its primary function is to interact with the live operating system.

This document explains the testing approach — why manual testing is the right choice today, and how automated testing can be layered on in the future.

---

## Why Manual Testing Is Appropriate

### 1. The Tool's Domain Is System State Mutation

| Operation | Why It Cannot Be Mocked Easily |
|-----------|-------------------------------|
| `Copy-Item` to `%USERPROFILE%\Desktop` | Requires a real user profile directory |
| `Start-Process -Wait -FilePath Setup.exe` | Requires the actual 200 MB+ installer binary |
| `Set-ItemProperty -Path HKCU:\...` | Requires live registry access with correct permissions |
| `Stop-Process -Name explorer` | Kills the shell — cannot run inside a CI container |
| `Test-Connection` to internet hosts | Requires real network access |

These operations span the file system, registry, process tree, and network stack. Mocking them would produce a parallel test framework that tests mocks, not the actual tool.

### 2. The Cost of a Bad Deployment Is High

A false-positive test pass could mean:
- A workstation deployed without Java → Akia won't launch
- A missing desktop icon → help-desk call
- A failed silent install that fell back to interactive → IT staff must click through prompts manually

Manual testing on a real (or VM) Windows installation gives the highest confidence.

### 3. The Tool's Surface Area Is Well-Defined

With only 6 PowerShell modules and 19 exported functions, the entire codebase can be manually verified in under 30 minutes. The 20 test cases in `manual-test-plan.md` cover every user-facing feature and every known failure mode.

---

## Current Testing Approach

```
┌─────────────────────────────────────────────────────┐
│                   MANUAL TESTING                     │
│                                                      │
│  manual-test-plan.md     20 test cases defined       │
│         │                                            │
│         ▼                                            │
│  Human tester on Windows 10 VM                       │
│         │                                            │
│         ▼                                            │
│  manual-test-results.md   Results recorded           │
│                                                      │
│  Frequency: Before every release                     │
│  Duration:  ~30 minutes                              │
└─────────────────────────────────────────────────────┘
```

### What We Test Manually

| Layer | What | How |
|-------|------|-----|
| **Configuration** | Missing, invalid, and partial `config.json` | Delete/rename/edit the file; verify graceful exit |
| **Menu / UI** | Display, colours, input validation | Visual inspection + invalid input |
| **Dry Run** | File/folder existence checks | Populated USB + intentionally broken USB |
| **Offline Install** | All 6 steps end-to-end | Clean VM snapshot, run full workflow, verify each app |
| **Online Install** | Internet check + enVision + Ninite | Live connection + disconnected NIC |
| **Logging** | Log file creation and content | Inspect `kurulum_log.txt` after each run |
| **Desktop** | Registry icons + Explorer refresh | Visual confirmation + registry query |
| **Security** | Admin privilege gate | Standard user account |

### Regression Baseline

Before each release, the full test plan is executed against a VM snapshot. Results are compared against the previous release's `manual-test-results.md`. Any deviation is investigated before the release is approved.

---

## Future: Automated Testing with Pester

[Pester](https://github.com/pester/Pester) is the de-facto testing framework for PowerShell. As the codebase matures, we can incrementally add automated tests for the parts that **can** be tested without a live system.

### Proposed Pester Test Structure

```
tests/
├── manual-test-plan.md
├── manual-test-results.md
├── TESTING.md                    ← this file
└── pester/                       ← future automated tests
    ├── Config.Tests.ps1
    ├── Logger.Tests.ps1
    ├── Network.Tests.ps1
    └── Deploy.Tests.ps1
```

### What Can Be Automated Today

#### Config.Tests.ps1 — Configuration Validation

```powershell
Describe "Get-Configuration" {
    Context "When config.json is missing" {
        It "Throws a terminating error" {
            # Mock Test-Path to return $false
            Mock Test-Path { return $false }
            { Get-Configuration -UsbRoot "C:\Fake" } | Should -Throw
        }
    }

    Context "When config.json has invalid JSON" {
        It "Throws with a parse error message" {
            Mock Get-Content { return '{invalid json' }
            { Get-Configuration -UsbRoot "C:\Fake" } | Should -Throw
        }
    }

    Context "When required fields are missing" {
        It "Lists every missing field" {
            $partialJson = '{"version":"1.0","paths":{},"logging":{}}'
            Mock Get-Content { return $partialJson }
            Mock Test-Path { return $true }
            { Get-Configuration -UsbRoot "C:\Fake" } | Should -Throw
        }
    }

    Context "When optional fields are missing" {
        It "Applies defaults without error" {
            $validJson = @'
{
    "version":"1.2.0",
    "paths":{"kbu_directory":"Kbu","office_directory":"Office","anydesk":"x","akia":"x","java":"x","envision":"x","ninite":"x","office":"x"},
    "logging":{"filename":"log.txt","location":"desktop"}
}
'@
            Mock Get-Content { return $validJson }
            Mock Test-Path { return $true }
            $result = Get-Configuration -UsbRoot "C:\Fake"
            $result.AppTitle | Should -Be "KBU Workstation Deployment Tool"
            $result.BackgroundColor | Should -Be "DarkBlue"
            $result.JavaSilent1 | Should -Be "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H"
        }
    }
}
```

#### Network.Tests.ps1 — Internet Connectivity

```powershell
Describe "Test-InternetConnection" {
    Context "When a target responds" {
        It "Returns true on first successful ping" {
            Mock Test-Connection { return $true } -ParameterFilter { $ComputerName -eq "8.8.8.8" }
            Test-InternetConnection -Targets @("8.8.8.8") -TimeoutMs 1000 | Should -BeTrue
        }
    }

    Context "When no targets respond" {
        It "Returns false after trying all targets" {
            Mock Test-Connection { return $false }
            Test-InternetConnection -Targets @("8.8.8.8","1.1.1.1") -TimeoutMs 1000 | Should -BeFalse
        }
    }
}
```

#### Logger.Tests.ps1 — Logging

```powershell
Describe "Logger functions" {
    BeforeEach {
        $testLog = Join-Path $env:TEMP "test_kbu_log.txt"
        Remove-Item $testLog -ErrorAction SilentlyContinue
        Set-LogPath -Path $testLog
    }

    It "Write-InstallLog appends a line to the log file" {
        Write-InstallLog "test message"
        Get-Content $testLog | Should -Contain "test message"
    }

    It "Write-StatusOk outputs green text without throwing" {
        { Write-StatusOk "success" } | Should -Not -Throw
    }
}
```

### What Cannot Be Automated (Stays Manual)

| Module | Function | Reason |
|--------|----------|--------|
| `Installer.ps1` | All 6 installers | Require real installer binaries and system modification |
| `Desktop.ps1` | `Add-DesktopIcons` | Writes to live registry — mock would not validate actual behaviour |
| `Desktop.ps1` | `Update-ExplorerShell` | Kills the shell process — not viable in CI |
| `Deploy.ps1` | `Invoke-OfflineInstall` | Orchestrates system-mutating installer functions |
| `Deploy.ps1` | `Invoke-OnlineInstall` | Requires real internet and installers |

### CI/CD Integration

Once Pester tests are in place, they can be wired into GitHub Actions:

```yaml
# .github/workflows/test.yml
name: PowerShell Tests
on: [push, pull_request]
jobs:
  pester:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Pester tests
        run: |
          Install-Module Pester -Force -SkipPublisherCheck
          Invoke-Pester -Path tests/pester/ -OutputFormat NUnitXml -OutputFile test-results.xml
      - name: Publish results
        uses: dorny/test-reporter@v1
        with:
          name: Pester Tests
          path: test-results.xml
          reporter: java-junit
```

---

## Testing Principles

1. **Manual for system mutation** — anything that writes to disk, registry, or process tree must be verified by a human on real hardware.
2. **Automated for pure logic** — config parsing, logging, network checks, and input validation can be Pester-tested.
3. **Full test plan before every release** — no release ships without a completed `manual-test-results.md`.
4. **VM snapshots as reset mechanism** — every test run starts from a clean Windows 10 state.
5. **Logs are truth** — if the log file says it happened, the test considers it verified (supplemented by visual confirmation).

---

## References

- [Pester Documentation](https://pester.dev/)
- [Keep a Changelog](https://keepachangelog.com/)
- [PowerShell Scripting Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction)
