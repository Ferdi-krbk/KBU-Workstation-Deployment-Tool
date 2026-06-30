# Manual Test Plan — KBU Workstation Deployment Tool

**Document Version:** 1.0
**Date:** 2026-06-30
**Author:** KBU IT Department
**Application Version:** v1.3.0

---

## Purpose

This document defines the manual testing strategy for the KBU Workstation Deployment Tool. It covers every user-facing feature and failure mode to ensure the application behaves correctly before production deployment on university workstations.

## Environment

| Property | Value |
|----------|-------|
| Operating System | Windows 10 22H2 (64-bit), clean install |
| Architecture | x64 |
| RAM | 8 GB minimum |
| Disk | 256 GB SSD |
| User Account | Local Administrator |
| PowerShell | 5.1 (bundled with Windows 10) |
| USB Drive | 16 GB, FAT32, labeled `KBU_DEPLOY` |
| Test USB Path | `D:\` (varies) |

## Prerequisites

Before executing any test case, ensure:

1. A USB drive is prepared with the full project structure (see `README.md` → Folder Structure)
2. All installer packages are present in `Kbu\` and `Office Cevrimdisi\`
3. `config.json` is present at the USB root and contains valid values
4. The test workstation is a **clean** Windows 10 installation (or a VM snapshot that can be reverted)
5. The tester is logged in with **Administrator privileges**

## Acceptance Criteria

A test case is marked **PASS** when:

- The application displays the expected output message (success, warning, or error)
- The log file (`%USERPROFILE%\Desktop\kurulum_log.txt`) contains the expected entry
- No unexpected crashes, blank screens, or PowerShell exceptions occur
- For install tests: the application actually installs and can be launched
- For Dry Run tests: **zero** files are modified on the system
- For error cases: the application exits gracefully with code 1

---

## Manual Test Cases

---

### TC-01 — Configuration File Missing

| Field | Details |
|-------|---------|
| **Test ID** | TC-01 |
| **Category** | Configuration Validation |
| **Priority** | Critical |
| **Description** | Verify the application handles a missing `config.json` gracefully. |
| **Preconditions** | Rename or delete `config.json` from the USB root. |
| **Steps** | 1. Double-click `deploy.bat` as Administrator<br>2. Observe console output |
| **Expected Result** | A red error message: `[X] config.json bulunamadi!`. The expected path is displayed. A USB folder structure diagram is shown. The application waits for a keypress and then exits. Fallback log `[HATA] config.json bulunamadi: <path>` is written. |
| **Acceptance Criteria** | Error message shown, log entry written, exit code 1, no crash. |

---

### TC-02 — Invalid JSON Syntax

| Field | Details |
|-------|---------|
| **Test ID** | TC-02 |
| **Category** | Configuration Validation |
| **Priority** | Critical |
| **Description** | Verify the application reports invalid JSON (e.g., a trailing comma). |
| **Preconditions** | Edit `config.json` to contain invalid JSON — add a trailing comma after the last property, or remove a closing brace. |
| **Steps** | 1. Double-click `deploy.bat` as Administrator<br>2. Observe console output |
| **Expected Result** | A red error message: `[X] config.json gecersiz!` with the PowerShell parse error message. Fallback log is written. Application exits gracefully. |
| **Acceptance Criteria** | Error message shown with parse details, log entry written, exit code 1. |

---

### TC-03 — Missing Required Config Fields

| Field | Details |
|-------|---------|
| **Test ID** | TC-03 |
| **Category** | Configuration Validation |
| **Priority** | Critical |
| **Description** | Verify application reports every missing required field. |
| **Preconditions** | Remove `paths.kbu_directory`, `paths.anydesk`, and `logging.filename` from `config.json`. |
| **Steps** | 1. Double-click `deploy.bat` as Administrator<br>2. Observe console output |
| **Expected Result** | A red error message listing all three missing fields: `paths.kbu_directory is required`, `paths.anydesk is required`, `logging.filename is required`. Fallback log is written. |
| **Acceptance Criteria** | All missing fields listed individually, log entry written, exit code 1. |

---

### TC-04 — Missing Optional Config Fields (Default Fallback)

| Field | Details |
|-------|---------|
| **Test ID** | TC-04 |
| **Category** | Configuration Validation |
| **Priority** | Medium |
| **Description** | Verify that missing optional fields (e.g., `app`, `desktop`, `timing`) do not cause errors — built-in defaults are applied. |
| **Preconditions** | Remove the entire `app`, `desktop`, `timing`, and `installers` sections from `config.json`. |
| **Steps** | 1. Double-click `deploy.bat` as Administrator<br>2. Observe menu appearance<br>3. Check log file |
| **Expected Result** | Menu displays with default application name "KBU Workstation Deployment Tool" and version. Colours are white-on-blue. No error messages. |
| **Acceptance Criteria** | Menu renders correctly with defaults, no errors, log entries normal. |

---

### TC-05 — Dry Run — All Files Present

| Field | Details |
|-------|---------|
| **Test ID** | TC-05 |
| **Category** | Test Mode |
| **Priority** | High |
| **Description** | Run Dry Run with a fully populated USB drive. All 9 checks should pass. |
| **Preconditions** | All installer files and folders are present on USB. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[0]` for Test Mode<br>3. Observe all 9 checks |
| **Expected Result** | All 9 items show `[√] ... bulundu.` in green. Summary shows `Basarili: 9/9`, `Basarisiz: 0/9`. Message: `Tum kontroller basarili! Kuruluma hazir.` |
| **Acceptance Criteria** | 9/9 passed, no system changes, log records all checks. |

---

### TC-06 — Dry Run — Missing Files

| Field | Details |
|-------|---------|
| **Test ID** | TC-06 |
| **Category** | Test Mode |
| **Priority** | High |
| **Description** | Run Dry Run with intentionally missing installer files. Verify failures are reported. |
| **Preconditions** | Delete `Kbu\AnyDesk.exe` and `Kbu\Ninite ... Installer.exe` from USB. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[0]` for Test Mode<br>3. Observe checks 3 and 8 |
| **Expected Result** | AnyDesk and Ninite show `[X] ... BULUNAMADI!` in red. Summary shows `Basarisiz: 2/9`. Message: `Eksik dosya/klasor var! Eksikleri tamamlayin.` |
| **Acceptance Criteria** | Failures correctly reported, pass/fail counts accurate, no false positives/negatives. |

---

### TC-07 — Dry Run — Missing Folders

| Field | Details |
|-------|---------|
| **Test ID** | TC-07 |
| **Category** | Test Mode |
| **Priority** | Medium |
| **Description** | Run Dry Run with missing Kbu and Office folders. |
| **Preconditions** | Rename `Kbu` to `Kbu_OLD` and `Office Cevrimdisi` to `Office_OLD`. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[0]` for Test Mode<br>3. Observe checks 1 and 2 |
| **Expected Result** | Both folders show `[X] ... BULUNAMADI!` with "Lutfen USB'de bu klasorun varligini kontrol edin." messages. All file checks (3-8) also fail since paths depend on these folders. |
| **Acceptance Criteria** | Folder and dependent file checks fail correctly. Restore folders after test. |

---

### TC-08 — Offline Deployment — Full Workflow

| Field | Details |
|-------|---------|
| **Test ID** | TC-08 |
| **Category** | Offline Installation |
| **Priority** | Critical |
| **Description** | Execute the complete offline installation workflow on a clean system. |
| **Preconditions** | Clean Windows 10 VM snapshot. All installers present on USB. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` for Offline Install<br>3. Wait for all 6 steps to complete<br>4. Verify each installed application |
| **Expected Result** | All 6 steps show green `[√]` messages. AnyDesk.exe on Desktop. Akia, Java, Office installed. Desktop icons visible. Explorer refreshed. Log file contains [OK] entries for all steps. |
| **Acceptance Criteria** | All 6 steps pass, applications launchable, desktop icons present, log complete. |

---

### TC-09 — Offline Deployment — AnyDesk Copy to Desktop

| Field | Details |
|-------|---------|
| **Test ID** | TC-09 |
| **Category** | Offline Installation |
| **Priority** | High |
| **Description** | Verify AnyDesk.exe is copied to the Desktop directory. |
| **Preconditions** | AnyDesk.exe present at `Kbu\AnyDesk.exe`. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [1/6]<br>3. Check `%USERPROFILE%\Desktop\AnyDesk.exe` |
| **Expected Result** | `AnyDesk.exe` exists on Desktop with correct file size. Console: `[√] AnyDesk basariyla masaustune kopyalandi.` |
| **Acceptance Criteria** | File present on Desktop, log entry: `[OK] AnyDesk kopyalandi: <path>`. |

---

### TC-10 — Offline Deployment — Java JRE Silent Install

| Field | Details |
|-------|---------|
| **Test ID** | TC-10 |
| **Category** | Offline Installation |
| **Priority** | High |
| **Description** | Verify Java JRE installs silently with configuration-driven arguments. |
| **Preconditions** | Java JRE installer present. No prior Java installation. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [3/6]<br>3. After completion, check `C:\Program Files\Java\` |
| **Expected Result** | Java installed without interactive prompts. Log: `[OK] Java JRE sessiz kuruldu.` Directory `jre1.8.0_411` exists. |
| **Acceptance Criteria** | Silent install, Java directory present, `java -version` works. |

---

### TC-11 — Offline Deployment — Java Silent Install Fallback

| Field | Details |
|-------|---------|
| **Test ID** | TC-11 |
| **Category** | Offline Installation |
| **Priority** | Medium |
| **Description** | Verify the fallback mechanism when the first silent install method fails. This is tested by temporarily using invalid silent arguments in config.json, then restoring. |
| **Preconditions** | Edit `config.json` → `installers.java.silent_args_1` to `"/invalid_flag"`. Second args remain valid. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [3/6]<br>3. After completion, restore `config.json` |
| **Expected Result** | First attempt fails silently. Console: `Alternatif sessiz yontem deneniyor...`. Second attempt succeeds: `[√] Java JRE sessiz olarak basariyla kuruldu. (alternatif yontem)`. |
| **Acceptance Criteria** | Fallback triggered, Java installed, log records alternative method used. |

---

### TC-12 — Online Deployment — enVision Installation

| Field | Details |
|-------|---------|
| **Test ID** | TC-12 |
| **Category** | Online Installation |
| **Priority** | High |
| **Description** | Verify enVision.Client.Service installs silently. |
| **Preconditions** | Active internet connection. enVision installer present on USB. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[2]` for Online Install<br>3. Observe step [1/2] |
| **Expected Result** | Internet check passes. enVision installs silently: `[√] enVision.Client.Service basariyla kuruldu.` |
| **Acceptance Criteria** | Internet check passes, enVision service installed, log entry written. |

---

### TC-13 — Online Deployment — No Internet Connection

| Field | Details |
|-------|---------|
| **Test ID** | TC-13 |
| **Category** | Online Installation |
| **Priority** | High |
| **Description** | Verify the application blocks online installation when no internet is available. |
| **Preconditions** | Disconnect the Ethernet cable or disable the Wi-Fi adapter. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[2]` for Online Install<br>3. Observe internet check |
| **Expected Result** | `[X] Internet baglantisi bulunamadi!` displayed. Message: "Alternatif olarak Cevrimdisi Kurulumu kullanabilirsiniz." User is returned to the main menu. No installers are launched. |
| **Acceptance Criteria** | No installers run, error message shown, log entry: `[HATA] Internet baglantisi yok!`, return to menu. |

---

### TC-14 — Log File Generation

| Field | Details |
|-------|---------|
| **Test ID** | TC-14 |
| **Category** | Logging |
| **Priority** | High |
| **Description** | Verify `kurulum_log.txt` is created on the Desktop with correct content. |
| **Preconditions** | Delete any existing `kurulum_log.txt` from Desktop. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Run a full Offline installation<br>3. Open `%USERPROFILE%\Desktop\kurulum_log.txt` |
| **Expected Result** | File exists. Contains header (`=====...=====`, app name, version, timestamp, USB path), step-by-step `[OK]` entries, and a completion footer. All entries are in UTF-8. |
| **Acceptance Criteria** | Log file created, complete entries, UTF-8 encoding, no corruption. |

---

### TC-15 — Desktop Icons Configuration

| Field | Details |
|-------|---------|
| **Test ID** | TC-15 |
| **Category** | Desktop Customization |
| **Priority** | Medium |
| **Description** | Verify This PC, Control Panel, Network, and Recycle Bin icons appear on the Desktop after offline installation. |
| **Preconditions** | All four icons are hidden before the test (default on clean Windows). |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [5/6]<br>3. After completion, check Desktop |
| **Expected Result** | All four icons visible on Desktop. Console: `[√] Masaustu simgeleri eklendi.` Log: `[OK] Masaustu simgeleri (Bu PC, Denetim Masasi, Ag, Geri Donusum Kutusu) eklendi.` |
| **Acceptance Criteria** | Four icons visible, registry values set to 0, log entry recorded. |

---

### TC-16 — Windows Explorer Refresh

| Field | Details |
|-------|---------|
| **Test ID** | TC-16 |
| **Category** | Desktop Customization |
| **Priority** | Medium |
| **Description** | Verify Explorer restarts after desktop icon changes (step 6/6). |
| **Preconditions** | Open a File Explorer window before running the test. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [6/6]<br>3. Note if Explorer windows close and reopen |
| **Expected Result** | Explorer windows close briefly and restart. Console: `[√] Windows Gezgini yenilendi.` Log: `[OK] Windows Gezgini yenilendi.` |
| **Acceptance Criteria** | Explorer process is killed and restarted within 2 seconds, taskbar reappears, log entry recorded. |

---

### TC-17 — Administrator Privileges Required

| Field | Details |
|-------|---------|
| **Test ID** | TC-17 |
| **Category** | Security |
| **Priority** | High |
| **Description** | Verify the launcher blocks execution when not run as Administrator. |
| **Preconditions** | Log in as a standard user (non-admin). |
| **Steps** | 1. Double-click `deploy.bat` (do NOT use "Run as Administrator")<br>2. Observe console output |
| **Expected Result** | `[X] Administrator privileges required!` displayed. Instructions to right-click and Run as Administrator. Script exits with error code 1. PowerShell is never launched. |
| **Acceptance Criteria** | Error message, no PowerShell process started, exit code 1. |

---

### TC-18 — Invalid Menu Choice Handling

| Field | Details |
|-------|---------|
| **Test ID** | TC-18 |
| **Category** | UI |
| **Priority** | Low |
| **Description** | Verify the menu rejects invalid input and returns to the menu. |
| **Preconditions** | Application running at the main menu. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Type `5` and press Enter<br>3. Type `abc` and press Enter<br>4. Observe behaviour |
| **Expected Result** | Console: `[!] Gecersiz secim! Lutfen 0, 1, 2 veya 3 girin.` displayed for 2 seconds, then menu redraws. |
| **Acceptance Criteria** | Invalid inputs rejected, menu redrawn, no crash. |

---

### TC-19 — Office Offline Installation

| Field | Details |
|-------|---------|
| **Test ID** | TC-19 |
| **Category** | Offline Installation |
| **Priority** | High |
| **Description** | Verify Microsoft Office installs from the `Office Cevrimdisi` folder. |
| **Preconditions** | `Office Cevrimdisi\Setup.exe` present on USB. No Office currently installed. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[1]` → Observe step [4/6]<br>3. Follow Office setup prompts<br>4. After completion, launch Word |
| **Expected Result** | Office installer launches interactively. After completion, Word, Excel, PowerPoint are available. Console: `[√] Office kurulumu tamamlandi.` |
| **Acceptance Criteria** | Office installs successfully, applications launch, log entry recorded. |

---

### TC-20 — Ninite Package Installation

| Field | Details |
|-------|---------|
| **Test ID** | TC-20 |
| **Category** | Online Installation |
| **Priority** | Medium |
| **Description** | Verify Ninite installer runs and installs Chrome, Firefox, Foxit Reader, and GOM Player. |
| **Preconditions** | Active internet. Ninite installer present. No prior installation of these apps. |
| **Steps** | 1. Launch `deploy.bat` as Administrator<br>2. Press `[2]` → Observe step [2/2]<br>3. Wait for Ninite to complete |
| **Expected Result** | All four apps installed. Console: `[√] Ninite paketleri basariyla kuruldu.` Log: `[OK] Ninite paketleri (Chrome, Firefox, Foxit, GOM) kuruldu.` |
| **Acceptance Criteria** | Browsers and apps present, launchable, log entry recorded. |

---

## Test Case Summary

| ID | Test Case | Priority |
|----|-----------|----------|
| TC-01 | Config Missing | Critical |
| TC-02 | Invalid JSON | Critical |
| TC-03 | Missing Required Fields | Critical |
| TC-04 | Optional Field Defaults | Medium |
| TC-05 | Dry Run — All Pass | High |
| TC-06 | Dry Run — Missing Files | High |
| TC-07 | Dry Run — Missing Folders | Medium |
| TC-08 | Full Offline Deployment | Critical |
| TC-09 | AnyDesk Desktop Copy | High |
| TC-10 | Java Silent Install | High |
| TC-11 | Java Install Fallback | Medium |
| TC-12 | enVision Online Install | High |
| TC-13 | No Internet | High |
| TC-14 | Log Generation | High |
| TC-15 | Desktop Icons | Medium |
| TC-16 | Explorer Refresh | Medium |
| TC-17 | Admin Privileges | High |
| TC-18 | Invalid Menu Input | Low |
| TC-19 | Office Install | High |
| TC-20 | Ninite Install | Medium |

**Total: 20 test cases**
