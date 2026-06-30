# Manual Test Results — KBU Workstation Deployment Tool

**Application Version:** v1.3.0
**Test Date:** 2026-06-30
**Tester:** IT Department — Deployment Team
**Environment:** Windows 10 22H2 (VM), x64, 8 GB RAM, Local Admin

---

## Results Table

| Test ID | Test Case | Expected Result | Actual Result | Status |
|---------|-----------|-----------------|---------------|--------|
| TC-01 | Config Missing | Red error `[X] config.json bulunamadi!`, path displayed, log written, exit code 1 | Error displayed correctly in red. USB folder diagram shown. Fallback log written to Desktop. Process exited with code 1. | ✅ PASS |
| TC-02 | Invalid JSON | Red error `[X] config.json gecersiz!`, parse message displayed, log written, exit code 1 | Parse error `Unexpected token '}'` shown. Fallback log written. Application exited gracefully. | ✅ PASS |
| TC-03 | Missing Required Fields | All three missing fields listed: `paths.kbu_directory`, `paths.anydesk`, `logging.filename` | Three errors displayed with `-` bullet prefix. Fallback log written with semicolon-separated list. Exit code 1. | ✅ PASS |
| TC-04 | Optional Field Defaults | Menu renders with default branding, no errors | Menu displayed "KBU Workstation Deployment Tool v1.3.0" in yellow. Background dark blue, foreground white. No errors. | ✅ PASS |
| TC-05 | Dry Run — All Present | 9/9 passed, green summary, "Kuruluma hazir" | All 9 items passed with green `[√]`. Summary: `Basarili: 9/9`, `Basarisiz: 0/9`. Log recorded all checks. Zero system changes confirmed via registry snapshot comparison. | ✅ PASS |
| TC-06 | Dry Run — Missing Files | AnyDesk + Ninite show `[X]`, 2/9 failed | Items 3 and 8 showed `[X] BULUNAMADI!` with expected paths. Summary: `Basarili: 7/9`, `Basarisiz: 2/9`. "Eksik dosya/klasor var!" warning displayed. | ✅ PASS |
| TC-07 | Dry Run — Missing Folders | Folders + all dependent files fail | KBU folder (check 1) and Office folder (check 2) both `[X]`. Subsequent file checks 3-8 also failed since paths depend on those folders. Total: `Basarili: 1/9` (only internet check passed). | ✅ PASS |
| TC-08 | Full Offline Deploy | All 6 steps green, apps launchable, icons visible | Steps 1-6 all completed with green `[√]`. AnyDesk on Desktop, Akia launchable, Java `1.8.0_411` in Programs, Office 2016 launched Word successfully, 4 desktop icons visible, Explorer refreshed. | ✅ PASS |
| TC-09 | AnyDesk Desktop Copy | File on Desktop, log entry | `AnyDesk.exe` (3.8 MB) present at `%USERPROFILE%\Desktop\`. Console: `[√] AnyDesk basariyla masaustune kopyalandi.` Log confirmed full path. | ✅ PASS |
| TC-10 | Java Silent Install | Silent install, `jre1.8.0_411` exists | Java installed without any GUI windows appearing. Directory `C:\Program Files\Java\jre1.8.0_411` created. `java -version` returned `1.8.0_411`. | ✅ PASS |
| TC-11 | Java Fallback | First attempt fails silently, second succeeds | After setting `silent_args_1` to `/invalid_flag`, first attempt exited non-zero. "Alternatif sessiz yontem deneniyor..." displayed. Second attempt with `INSTALL_SILENT=1` succeeded. Log recorded `(alternatif yontem)`. | ✅ PASS |
| TC-12 | enVision Online Install | Internet check passes, enVision installs silently | Internet check: `[√] Internet baglantisi mevcut.` enVision installed via `/quiet /norestart`. `enVision.Client.Service` appeared in Services. | ✅ PASS |
| TC-13 | No Internet | Blocked with error, returned to menu | After disabling NIC, internet check failed after trying all 3 targets. `[X] Internet baglantisi bulunamadi!` displayed. "Alternatif olarak Cevrimdisi Kurulumu kullanabilirsiniz." shown. Returned to main menu. No installers executed. | ✅ PASS |
| TC-14 | Log Generation | File created, UTF-8, all entries present | `kurulum_log.txt` created on Desktop (16 KB). Header: app name, version `v1.3.0`, timestamp `30.06.2026 - 16:15:37`, USB path `D:\`. Six `[OK]` entries for offline deployment. Footer with end timestamp. UTF-8 verified (Turkish characters intact). | ✅ PASS |
| TC-15 | Desktop Icons | All 4 icons visible, registry values = 0 | After step 5/6, refreshed Desktop showed This PC, Control Panel, Network, Recycle Bin. Registry confirmed all 4 CLSID values set to `0x00000000`. Log recorded all 4 icons. | ✅ PASS |
| TC-16 | Explorer Refresh | Explorer killed, restarted within 2s | Explorer windows closed for ~2 seconds, then taskbar and windows reappeared. Console: `[√] Windows Gezgini yenilendi.` No data loss in open folders. | ✅ PASS |
| TC-17 | Admin Required | Blocked with message, exit code 1 | Under standard user account, `net session` failed. `[X] Administrator privileges required!` displayed with Run as Administrator instructions. `deploy.bat` exited with code 1. PowerShell never spawned (confirmed via Task Manager). | ✅ PASS |
| TC-18 | Invalid Menu Input | Rejected, menu redrawn | Typing `5`: `[!] Gecersiz secim! Lutfen 0, 1, 2 veya 3 girin.` displayed for 2 seconds, then menu redrew. Typing `abc`: same behaviour. Application stable after 10 repeated invalid inputs. | ✅ PASS |
| TC-19 | Office Install | Office installs, apps launch | Office Setup.exe launched interactively. User clicked through prompts (standard Office install). After completion, Word, Excel, and PowerPoint launched successfully from Start Menu. Console: `[√] Office kurulumu tamamlandi.` | ✅ PASS |
| TC-20 | Ninite Install | Chrome, Firefox, Foxit, GOM installed | Ninite window appeared and progressed. All 4 apps installed. Chrome and Firefox launched. Foxit Reader opened a test PDF. GOM Player launched. Console and log confirmed success. | ✅ PASS |

---

## Test Summary

| Metric | Value |
|--------|-------|
| **Total Test Cases** | 20 |
| **Passed** | 20 |
| **Failed** | 0 |
| **Skipped** | 0 |
| **Success Rate** | **100%** |

### By Category

| Category | Total | Pass | Fail | Rate |
|----------|-------|------|------|------|
| Configuration Validation | 4 | 4 | 0 | 100% |
| Test Mode (Dry Run) | 3 | 3 | 0 | 100% |
| Offline Installation | 5 | 5 | 0 | 100% |
| Online Installation | 3 | 3 | 0 | 100% |
| Logging | 1 | 1 | 0 | 100% |
| Desktop Customization | 2 | 2 | 0 | 100% |
| Security | 1 | 1 | 0 | 100% |
| UI | 1 | 1 | 0 | 100% |

### By Priority

| Priority | Total | Pass | Fail |
|----------|-------|------|------|
| Critical | 4 | 4 | 0 |
| High | 10 | 10 | 0 |
| Medium | 5 | 5 | 0 |
| Low | 1 | 1 | 0 |

---

## Observations

1. **Configuration validation is robust** — all three error modes (missing, invalid JSON, missing fields) were caught with clear, actionable error messages. Fallback logging worked in every case.

2. **Silent install fallback for Java** (TC-11) worked correctly. The second method `INSTALL_SILENT=1` succeeded after the first failed. This confirms the resilience mechanism.

3. **Dry Run is truly non-destructive** — verified by taking registry snapshots before and after Test Mode. Zero keys were modified.

4. **Offline deployment** completed end-to-end in approximately 12 minutes on the test VM (SSD). The interactive Office install was the longest step.

5. **Explorer refresh** (TC-16) is briefly disruptive but necessary. The 2-second wait from `config.json` (`desktop.explorer_wait_seconds`) was sufficient.

6. **No regressions detected** — all features that existed in v1.2.0 continue to work identically in v1.3.0.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tester | IT Deployment Team | 2026-06-30 | ✓ |
| Reviewer | IT Manager | 2026-06-30 | ✓ |

**Status: APPROVED FOR PRODUCTION**
