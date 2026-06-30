@echo off
setlocal enabledelayedexpansion

:: =============================================================================
::  KBU Workstation Deployment Tool
::  Karabuk Universitesi - Bilgi Islem Daire Baskanligi
::  Yeni is istasyonu otomasyon kurulum betigi
:: =============================================================================
::
::  KULLANIM:
::    1. USB bellegi yeni Windows 10 bilgisayara takin
::    2. USB bellekteki kurulum.bat dosyasina cift tiklayin (Yonetici olarak)
::    3. Once [0] Test Modu ile USB icerigini dogrulayin
::    4. Menuden secim yapip kurulumu baslatin
::
::  USB KLASOR YAPISI:
::    USB_ROOT
::    ├── kurulum.bat
::    ├── config.json
::    ├── Kbü
::    │   ├── AnyDesk.exe
::    │   ├── Akia_windows-x64_6_7_6.exe
::    │   ├── jre-8u411-windows-x64.exe
::    │   ├── enVision.Client.Service.exe
::    │   └── Ninite Chrome Firefox Foxit Reader GOM Installer.exe
::    └── Office Çevrimdışı
::        └── Setup.exe
::
:: =============================================================================

:: ---------- UTF-8 kod sayfasi (Turkce karakter destegi) ----------
chcp 65001 >nul 2>&1

:: ---------- USB kok dizini (betigin calistigi konum) ----------
:: Eger KBU_USB_ROOT ortam degiskeni ayarlanmissa onu kullan (EXE modu),
:: yoksa betigin kendi konumunu kullan (normal .bat calistirma)
if defined KBU_USB_ROOT (
    set "USB_ROOT=%KBU_USB_ROOT%"
) else (
    set "USB_ROOT=%~dp0"
)
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

:: ---------- Fallback log yolu (config yuklenene kadar) ----------
set "LOG_FILE=%USERPROFILE%\Desktop\kurulum_log.txt"

:: =============================================================================
::  KONFIGURASYON DOSYASI YUKLEME VE DOGRULAMA
:: =============================================================================
:load_config
set "CONFIG_FILE=%USB_ROOT%\config.json"

if not exist "%CONFIG_FILE%" (
    echo.
    echo   [X] config.json bulunamadi!
    echo.
    echo       Beklenen konum: %CONFIG_FILE%
    echo       Lutfen USB bellekte config.json dosyasinin oldugundan emin olun.
    echo.
    echo       USB Klasor Yapisi:
    echo         USB_ROOT
    echo         ├── kurulum.bat
    echo         ├── config.json
    echo         ├── Kbu
    echo         └── Office Cevrimdisi
    echo.
    echo %DATE% %TIME% [HATA] config.json bulunamadi: %CONFIG_FILE%>>"%LOG_FILE%"
    pause
    exit /b 1
)

:: PowerShell ile config.json dogrula ve degiskenleri yukle
for /f "usebackq tokens=1,* delims==" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { ^
  $cfg = Get-Content '%CONFIG_FILE%' -Raw -Encoding UTF8 ^| ConvertFrom-Json -ErrorAction Stop; ^
  if (-not $cfg.version) { throw 'config.json: version is required' }; ^
  if (-not $cfg.paths) { throw 'config.json: paths is required' }; ^
  if (-not $cfg.logging) { throw 'config.json: logging is required' }; ^
  if (-not $cfg.paths.kbu_directory) { throw 'paths.kbu_directory is required' }; ^
  if (-not $cfg.paths.office_directory) { throw 'paths.office_directory is required' }; ^
  if (-not $cfg.paths.anydesk) { throw 'paths.anydesk is required' }; ^
  if (-not $cfg.paths.akia) { throw 'paths.akia is required' }; ^
  if (-not $cfg.paths.java) { throw 'paths.java is required' }; ^
  if (-not $cfg.paths.envision) { throw 'paths.envision is required' }; ^
  if (-not $cfg.paths.ninite) { throw 'paths.ninite is required' }; ^
  if (-not $cfg.paths.office) { throw 'paths.office is required' }; ^
  if (-not $cfg.logging.filename) { throw 'logging.filename is required' }; ^
  if (-not $cfg.logging.location) { throw 'logging.location is required' }; ^
  if (-not $cfg.app) { $cfg.app = @{} }; ^
  if (-not $cfg.app.title) { $cfg.app.title = 'KBU Workstation Deployment Tool' }; ^
  if (-not $cfg.app.name) { $cfg.app.name = 'KBU Workstation Deployment Tool' }; ^
  if (-not $cfg.app.institution) { $cfg.app.institution = 'Karabuk Universitesi - Bilgi Islem Daire Baskanligi' }; ^
  if (-not $cfg.internet_check) { $cfg.internet_check = @{} }; ^
  if (-not $cfg.internet_check.targets) { $cfg.internet_check.targets = @('8.8.8.8','google.com','1.1.1.1') }; ^
  if (-not $cfg.internet_check.timeout_ms) { $cfg.internet_check.timeout_ms = 3000 }; ^
  Write-Output ('APP_VERSION=' + $cfg.version); ^
  Write-Output ('KBU_DIR_NAME=' + $cfg.paths.kbu_directory); ^
  Write-Output ('OFFICE_DIR_NAME=' + $cfg.paths.office_directory); ^
  Write-Output ('ANYDESK_REL=' + $cfg.paths.anydesk); ^
  Write-Output ('AKIA_REL=' + $cfg.paths.akia); ^
  Write-Output ('JAVA_REL=' + $cfg.paths.java); ^
  Write-Output ('ENVISION_REL=' + $cfg.paths.envision); ^
  Write-Output ('NINITE_REL=' + $cfg.paths.ninite); ^
  Write-Output ('OFFICE_REL=' + $cfg.paths.office); ^
  Write-Output ('LOG_FILENAME=' + $cfg.logging.filename); ^
  Write-Output ('LOG_LOCATION=' + $cfg.logging.location); ^
  Write-Output ('APP_TITLE=' + $cfg.app.title); ^
  Write-Output ('APP_NAME=' + $cfg.app.name); ^
  Write-Output ('APP_INSTITUTION=' + $cfg.app.institution); ^
  $targets = $cfg.internet_check.targets -join ','; ^
  Write-Output ('INET_TARGETS=' + $targets); ^
  Write-Output ('INET_TIMEOUT=' + $cfg.internet_check.timeout_ms.ToString()) ^
} catch { ^
  Write-Output ('CONFIG_ERROR=' + $_.Exception.Message) ^
}"`) do (
    set "%%a=%%b"
)

:: Hata kontrolu
if defined CONFIG_ERROR (
    echo.
    echo   [X] config.json gecersiz!
    echo.
    echo       Hata: !CONFIG_ERROR!
    echo       Lutfen config.json dosyasini kontrol edin.
    echo.
    echo %DATE% %TIME% [HATA] config.json gecersiz: !CONFIG_ERROR!>>"%LOG_FILE%"
    pause
    exit /b 1
)

if not defined APP_VERSION (
    echo.
    echo   [X] config.json yuklenemedi!
    echo.
    echo       Gerekli alanlar eksik veya dosya bozuk.
    echo       Lutfen config.json dosyasini kontrol edin.
    echo.
    echo %DATE% %TIME% [HATA] config.json yuklenemedi - gerekli alanlar eksik>>"%LOG_FILE%"
    pause
    exit /b 1
)

:: ---------- Config'den tam dosya yollari olustur ----------
set "KBU_DIR=%USB_ROOT%\%KBU_DIR_NAME%"
set "OFFICE_DIR=%USB_ROOT%\%OFFICE_DIR_NAME%"
set "ANYDESK=%USB_ROOT%\%ANYDESK_REL%"
set "AKIA=%USB_ROOT%\%AKIA_REL%"
set "JAVA=%USB_ROOT%\%JAVA_REL%"
set "ENVISION=%USB_ROOT%\%ENVISION_REL%"
set "NINITE=%USB_ROOT%\%NINITE_REL%"
set "OFFICE_SETUP=%USB_ROOT%\%OFFICE_REL%"

:: ---------- Config'den log yolu olustur ----------
if /i "%LOG_LOCATION%"=="desktop" (
    set "LOG_FILE=%USERPROFILE%\Desktop\%LOG_FILENAME%"
) else (
    if "%LOG_LOCATION:~1,1%"==":" (
        set "LOG_FILE=%LOG_LOCATION%\%LOG_FILENAME%"
    ) else (
        set "LOG_FILE=%USB_ROOT%\%LOG_LOCATION%\%LOG_FILENAME%"
    )
)

:: ---------- Internet kontrol hedeflerini diziye ayir ----------
set "INET_IDX=0"
for %%i in (%INET_TARGETS%) do (
    set "INET_TARGET_!INET_IDX!=%%i"
    set /a "INET_IDX+=1"
)
set "INET_COUNT=!INET_IDX!"

:: ---------- Pencere basligi ve renk ----------
title %APP_TITLE%
color 1F

:: ---------- Masaustu yolu ----------
set "DESKTOP=%USERPROFILE%\Desktop"

:: ---------- Baslangic log kaydi ----------
call :log "=============================================="
call :log "  %APP_NAME% v%APP_VERSION%"
call :log "  Baslangic: %DATE% - %TIME%"
call :log "  USB Konum: %USB_ROOT%"
call :log "=============================================="

:: =============================================================================
::  ANA MENU
:: =============================================================================
:main_menu
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║   [1;33m%APP_NAME%  [1;31mv%APP_VERSION%[1;37m                   ║
echo  ║   [1;36m%APP_INSTITUTION%[1;37m    ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║                                                          ║
echo  ║   [[1;35m0[1;37m]  [1;35mTEST MODU (Dry Run)[1;37m                                  ║
echo  ║        USB icerigini kontrol eder, kurulum YAPMAZ        ║
echo  ║                                                          ║
echo  ║   [[1;32m1[1;37m]  [1;32mCevrimdisi Kurulum[1;37m                                    ║
echo  ║        AnyDesk, Akia, Java, Office + Masaustu Ogeleri    ║
echo  ║                                                          ║
echo  ║   [[1;36m2[1;37m]  [1;36mCevrimici Kurulum[1;37m                                     ║
echo  ║        enVision.Client.Service + Ninite Paketleri        ║
echo  ║                                                          ║
echo  ║   [[1;31m3[1;37m]  [1;31mCikis[1;37m                                               ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
set "menu_choice="
set /p menu_choice="   Seciminizi yapin (0-3): "

if "%menu_choice%"=="0" goto test_mode
if "%menu_choice%"=="1" goto offline_install
if "%menu_choice%"=="2" goto online_install
if "%menu_choice%"=="3" goto exit_script

:: Gecersiz secim
echo.
echo   [1;31m[!] Gecersiz secim! Lutfen 0, 1, 2 veya 3 girin.[0m
timeout /t 2 /nobreak >nul
goto main_menu


:: =============================================================================
::  CEVRIMDISI KURULUM
:: =============================================================================
:offline_install
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║         [1;32mCEVRIMDISI KURULUM BASLATILIYOR...[1;37m                  ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- Cevrimdisi Kurulum Basladi ---"

:: ---------------------------------------------------
:: 1. AnyDesk masaustune kopyalama
:: ---------------------------------------------------
echo   [1/6] AnyDesk masaustune kopyalaniyor...
if exist "%ANYDESK%" (
    echo          Kaynak: %ANYDESK%
    copy /Y "%ANYDESK%" "%DESKTOP%\AnyDesk.exe" >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "AnyDesk basariyla masaustune kopyalandi."
        call :log "[OK] AnyDesk kopyalandi: %DESKTOP%\AnyDesk.exe"
    ) else (
        call :show_err "AnyDesk kopyalanirken hata olustu! (Yetki sorunu olabilir)"
        call :log "[HATA] AnyDesk kopyalanamadi (errorlevel: !errorlevel!)"
    )
) else (
    call :show_warn "AnyDesk.exe bulunamadi! Atlaniyor..."
    call :log "[UYARI] AnyDesk.exe bulunamadi: %ANYDESK%"
)

:: ---------------------------------------------------
:: 2. Akia kurulumu
:: ---------------------------------------------------
echo.
echo   [2/6] Akia kuruluyor...
if exist "%AKIA%" (
    echo          Dosya: %AKIA%
    echo          Kurulum baslatiliyor, lutfen ekrandaki adimlari takip edin...
    start "" /wait "%AKIA%"
    if !errorlevel! equ 0 (
        call :show_ok "Akia kurulumu tamamlandi."
        call :log "[OK] Akia kuruldu."
    ) else (
        call :show_warn "Akia kurulumu tamamlandi (kullanici iptal etmis olabilir)."
        call :log "[UYARI] Akia kurulumu !errorlevel! koduyla sonlandi."
    )
) else (
    call :show_warn "%AKIA_REL% bulunamadi! Atlaniyor..."
    call :log "[UYARI] Akia dosyasi bulunamadi: %AKIA%"
)

:: ---------------------------------------------------
:: 3. Java JRE sessiz kurulum
:: ---------------------------------------------------
echo.
echo   [3/6] Java JRE sessiz kuruluyor...
if exist "%JAVA%" (
    echo          Dosya: %JAVA%
    echo          Sessiz kurulum calistiriliyor, lutfen bekleyin...
    "%JAVA%" /s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "Java JRE sessiz olarak basariyla kuruldu."
        call :log "[OK] Java JRE sessiz kuruldu."
    ) else (
        :: Alternatif sessiz parametrelerle dene
        "%JAVA%" INSTALL_SILENT=1 REBOOT=Suppress >nul 2>&1
        if !errorlevel! equ 0 (
            call :show_ok "Java JRE sessiz olarak basariyla kuruldu. (alternatif yontem)"
            call :log "[OK] Java JRE sessiz kuruldu (alternatif yontem)."
        ) else (
            call :show_warn "Java JRE sessiz kurulumu basarisiz! Etkilesimli deneniyor..."
            call :log "[UYARI] Java sessiz kurulum basarisiz, etkilesimli deneniyor."
            start "" /wait "%JAVA%"
            call :log "[BILGI] Java etkilesimli kurulum tamamlandi."
        )
    )
) else (
    call :show_warn "%JAVA_REL% bulunamadi! Atlaniyor..."
    call :log "[UYARI] Java JRE dosyasi bulunamadi: %JAVA%"
)

:: ---------------------------------------------------
:: 4. Office cevrimdisi kurulum
:: ---------------------------------------------------
echo.
echo   [4/6] Microsoft Office kuruluyor...
if exist "%OFFICE_SETUP%" (
    echo          Dosya: %OFFICE_SETUP%
    echo          Office kurulumu baslatiliyor, lutfen ekrandaki adimlari takip edin...
    echo          (Bu islem birkac dakika surebilir)
    start "" /wait "%OFFICE_SETUP%"
    if !errorlevel! equ 0 (
        call :show_ok "Office kurulumu tamamlandi."
        call :log "[OK] Microsoft Office kuruldu."
    ) else (
        call :show_warn "Office kurulumu tamamlandi (hata kodu: !errorlevel!)."
        call :log "[UYARI] Office kurulumu !errorlevel! koduyla sonlandi."
    )
) else (
    call :show_warn "Office\Setup.exe bulunamadi! Yol: %OFFICE_SETUP%"
    call :show_warn "Office Cevrimdisi klasoru ve Setup.exe'nin varligini kontrol edin."
    call :log "[UYARI] Office Setup.exe bulunamadi: %OFFICE_SETUP%"
)

:: ---------------------------------------------------
:: 5. Masaustu simgelerini ekleme
:: ---------------------------------------------------
echo.
echo   [5/6] Masaustu simgeleri ekleniyor...
call :add_desktop_icons
call :show_ok "Masaustu simgeleri eklendi."
call :log "[OK] Masaustu simgeleri (Bu PC, Denetim Masasi, Ag, Geri Donusum Kutusu) eklendi."

:: ---------------------------------------------------
:: 6. Windows Gezgini'ni yenileme
:: ---------------------------------------------------
echo.
echo   [6/6] Windows Gezgini yenileniyor...
call :refresh_explorer
call :show_ok "Windows Gezgini yenilendi."
call :log "[OK] Windows Gezgini yenilendi."

:: ---------------------------------------------------
:: Ozet
:: ---------------------------------------------------
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║          [1;32mCEVRIMDISI KURULUM TAMAMLANDI![1;37m                     ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyasi: %LOG_FILE%
echo.
call :log "--- Cevrimdisi Kurulum Tamamlandi ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  CEVRIMICI KURULUM
:: =============================================================================
:online_install
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║         [1;36mCEVRIMICI KURULUM BASLATILIYOR...[1;37m                    ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- Cevrimici Kurulum Basladi ---"

:: ---------------------------------------------------
:: Internet baglantisi kontrolu
:: ---------------------------------------------------
echo   Internet baglantisi kontrol ediliyor...
call :check_internet
if !internet_ok! equ 0 (
    echo.
    call :show_err "Internet baglantisi bulunamadi!"
    echo.
    echo   Lutfen ag baglantinizi kontrol edip tekrar deneyin.
    echo   Alternatif olarak Cevrimdisi Kurulumu kullanabilirsiniz.
    echo.
    call :log "[HATA] Internet baglantisi yok! Cevrimici kurulum iptal edildi."
    pause
    goto main_menu
)
call :show_ok "Internet baglantisi mevcut."
call :log "[OK] Internet baglantisi dogrulandi."

:: ---------------------------------------------------
:: 1. enVision.Client.Service kurulumu
:: ---------------------------------------------------
echo.
echo   [1/2] enVision.Client.Service kuruluyor...
if exist "%ENVISION%" (
    echo          Dosya: %ENVISION%
    echo          Kurulum calistiriliyor, lutfen bekleyin...
    "%ENVISION%" /quiet /norestart >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "enVision.Client.Service basariyla kuruldu."
        call :log "[OK] enVision.Client.Service kuruldu."
    ) else (
        :: Sessiz basarisiz olursa etkilesimli dene
        "%ENVISION%" /S >nul 2>&1
        if !errorlevel! equ 0 (
            call :show_ok "enVision.Client.Service basariyla kuruldu."
            call :log "[OK] enVision.Client.Service kuruldu."
        ) else (
            echo          Sessiz kurulum basarisiz, etkilesimli deneniyor...
            start "" /wait "%ENVISION%"
            call :show_warn "enVision.Client.Service etkilesimli olarak calistirildi."
            call :log "[UYARI] enVision sessiz kurulamadi, etkilesimli calistirildi."
        )
    )
) else (
    call :show_warn "%ENVISION_REL% bulunamadi! Atlaniyor..."
    call :log "[UYARI] enVision dosyasi bulunamadi: %ENVISION%"
)

:: ---------------------------------------------------
:: 2. Ninite paket kurulumu
:: ---------------------------------------------------
echo.
echo   [2/2] Ninite paketleri kuruluyor (Chrome, Firefox, Foxit Reader, GOM)...
if exist "%NINITE%" (
    echo          Dosya: %NINITE%
    echo          Ninite calistiriliyor, lutfen bekleyin...
    start "" /wait "%NINITE%"
    if !errorlevel! equ 0 (
        call :show_ok "Ninite paketleri basariyla kuruldu."
        call :log "[OK] Ninite paketleri (Chrome, Firefox, Foxit, GOM) kuruldu."
    ) else (
        call :show_warn "Ninite kurulumu tamamlandi (hata kodu: !errorlevel!)."
        call :log "[UYARI] Ninite !errorlevel! koduyla sonlandi."
    )
) else (
    call :show_warn "Ninite Installer bulunamadi! Atlaniyor..."
    call :log "[UYARI] Ninite dosyasi bulunamadi: %NINITE%"
)

:: ---------------------------------------------------
:: Ozet
:: ---------------------------------------------------
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║          [1;36mCEVRIMICI KURULUM TAMAMLANDI![1;37m                       ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyasi: %LOG_FILE%
echo.
call :log "--- Cevrimici Kurulum Tamamlandi ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  TEST MODU (DRY RUN)
::  Hicbir kurulum yapmaz, sadece USB icerigini ve interneti kontrol eder.
::  Tum sonuclar log dosyasina ve ekrana yazilir.
:: =============================================================================
:test_mode
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║              [1;35mTEST MODU (DRY RUN) BASLATILIYOR[1;37m                  ║
echo  ║         [1;33mHICBIR KURULUM VEYA DEGISIKLIK YAPILMAZ[1;37m              ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- TEST MODU (DRY RUN) Basladi ---"
call :log "  UYARI: Bu mod hicbir kurulum yapmaz, sadece kontrol eder."

:: Karsilama sayaci
set "test_pass=0"
set "test_fail=0"

:: ---------------------------------------------------
:: 1. Kbu klasoru kontrolu
:: ---------------------------------------------------
echo   [1/9] %KBU_DIR_NAME% klasoru kontrol ediliyor...
call :check_item "%KBU_DIR%" "%KBU_DIR_NAME% klasoru" "klasor"
echo.

:: ---------------------------------------------------
:: 2. Office Cevrimdisi klasoru kontrolu
:: ---------------------------------------------------
echo   [2/9] %OFFICE_DIR_NAME% klasoru kontrol ediliyor...
call :check_item "%OFFICE_DIR%" "%OFFICE_DIR_NAME% klasoru" "klasor"
echo.

:: ---------------------------------------------------
:: 3. AnyDesk.exe kontrolu
:: ---------------------------------------------------
echo   [3/9] AnyDesk.exe kontrol ediliyor...
call :check_item "%ANYDESK%" "AnyDesk.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 4. Akia installer kontrolu
:: ---------------------------------------------------
echo   [4/9] %AKIA_REL% kontrol ediliyor...
call :check_item "%AKIA%" "Akia installer" "dosya"
echo.

:: ---------------------------------------------------
:: 5. Java JRE installer kontrolu
:: ---------------------------------------------------
echo   [5/9] %JAVA_REL% kontrol ediliyor...
call :check_item "%JAVA%" "Java JRE installer" "dosya"
echo.

:: ---------------------------------------------------
:: 6. Office Setup.exe kontrolu
:: ---------------------------------------------------
echo   [6/9] Office Setup.exe kontrol ediliyor...
call :check_item "%OFFICE_SETUP%" "Office Setup.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 7. enVision.Client.Service.exe kontrolu
:: ---------------------------------------------------
echo   [7/9] %ENVISION_REL% kontrol ediliyor...
call :check_item "%ENVISION%" "enVision.Client.Service.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 8. Ninite installer kontrolu
:: ---------------------------------------------------
echo   [8/9] Ninite installer kontrol ediliyor...
call :check_item "%NINITE%" "Ninite Installer" "dosya"
echo.

:: ---------------------------------------------------
:: 9. Internet baglantisi kontrolu
:: ---------------------------------------------------
echo   [9/9] Internet baglantisi kontrol ediliyor...
call :check_internet
if !internet_ok! equ 1 (
    call :show_ok "Internet baglantisi mevcut."
    call :log "[OK] Internet baglantisi: MEVCUT"
    set /a "test_pass+=1"
) else (
    call :show_warn "Internet baglantisi bulunamadi. (Cevrimici kurulum calismaz!)"
    call :log "[UYARI] Internet baglantisi: YOK"
    set /a "test_fail+=1"
)
echo.

:: ---------------------------------------------------
:: Test Ozeti
:: ---------------------------------------------------
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║                   [1;35mTEST SONUCLARI[1;37m                              ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║   [1;32mBasarili: !test_pass!/9[1;37m                                     ║
echo  ║   [1;31mBasarisiz: !test_fail!/9[1;37m                                   ║
echo  ╠══════════════════════════════════════════════════════════╣

if !test_fail! equ 0 (
    echo  ║   [1;32mTum kontroller basarili! Kuruluma hazir.[1;37m              ║
    call :log "[OZET] Tum kontroller basarili (!test_pass!/9). USB kuruluma hazir."
) else (
    echo  ║   [1;31mEksik dosya/klasor var! Eksikleri tamamlayin.[1;37m        ║
    call :log "[OZET] !test_fail! kontrol basarisiz. USB tamamlanmali."
)

echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyasi: %LOG_FILE%
echo.
call :log "--- TEST MODU Tamamlandi (Gecen: !test_pass!, Kalan: !test_fail!) ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  CIKIS
:: =============================================================================
:exit_script
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║         %APP_NAME%                  ║
echo  ║         [1;33mKapatiliyor... Gule gule![1;37m                            ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyasi: %LOG_FILE%
echo.
call :log "=============================================="
call :log "  %APP_NAME% - Sonlandi"
call :log "  Bitis: %DATE% - %TIME%"
call :log "=============================================="
timeout /t 2 /nobreak >nul
exit /b 0


:: =============================================================================
::  FONKSIYON: Internet baglantisi kontrolu
::  Sonuc: !internet_ok! degiskenine 1 (var) veya 0 (yok) atar
::  Hedefler config.json'daki internet_check.targets dizisinden okunur
:: =============================================================================
:check_internet
set "internet_ok=0"
set /a "inet_last=INET_COUNT - 1"

for /l %%x in (0,1,!inet_last!) do (
    ping -n 1 -w !INET_TIMEOUT! !INET_TARGET_%%x! >nul 2>&1
    if !errorlevel! equ 0 (
        set "internet_ok=1"
        goto :eof
    )
)
goto :eof


:: =============================================================================
::  FONKSIYON: Masaustu simgelerini ekle
::  Registry uzerinden Bu PC, Denetim Masasi, Ag ve Geri Donusum Kutusu
:: =============================================================================
:add_desktop_icons

:: Registry anahtari yolu
set "REG_HIDE=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons"
set "REG_CLASSIC=%REG_HIDE%\ClassicStartMenu"
set "REG_NEW=%REG_HIDE%\NewStartPanel"

:: Her iki start menu modu icin de simgeleri goster (0 = gorunur, 1 = gizli)

:: Bu PC (Computer) - {20D04FE0-3AEA-1069-A2D8-08002B30309D}
reg add "%REG_NEW%" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Denetim Masasi (Control Panel) - {5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}
reg add "%REG_NEW%" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Ag (Network) - {F02C1A0D-BE21-4350-88B0-7367FC96EF3C}
reg add "%REG_NEW%" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Geri Donusum Kutusu (Recycle Bin) - {645FF040-5081-101B-9F08-00AA002F954E}
reg add "%REG_NEW%" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0 /f >nul 2>&1

goto :eof


:: =============================================================================
::  FONKSIYON: Windows Gezgini'ni yenile
:: =============================================================================
:refresh_explorer
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
goto :eof


:: =============================================================================
::  FONKSIYON: Log yazma
::  Parametre: %1 = log mesaji
:: =============================================================================
:log
set "log_message=%~1"
echo %log_message%>>"%LOG_FILE%"
goto :eof


:: =============================================================================
::  FONKSIYON: Basarili mesaji goster  (Yesil)
:: =============================================================================
:show_ok
echo   [1;32m[√] %~1[0m
goto :eof


:: =============================================================================
::  FONKSIYON: Hata mesaji goster  (Kirmizi)
:: =============================================================================
:show_err
echo   [1;31m[X] %~1[0m
goto :eof


:: =============================================================================
::  FONKSIYON: Uyari mesaji goster  (Sari)
:: =============================================================================
:show_warn
echo   [1;33m[!] %~1[0m
goto :eof


:: =============================================================================
::  FONKSIYON: Tek bir ogeyi kontrol et (Test Modu icin)
::  Parametreler: %1 = tam yol, %2 = gorunen ad, %3 = tur (dosya/klasor)
::  Sonuc: test_pass veya test_fail sayacini artirir
:: =============================================================================
:check_item
set "item_path=%~1"
set "item_name=%~2"
set "item_type=%~3"

if exist "%item_path%" (
    call :show_ok "%item_name% bulundu."
    call :log "[OK] %item_name% mevcut: %item_path%"
    set /a "test_pass+=1"
) else (
    call :show_err "%item_name% BULUNAMADI!"
    call :log "[HATA] %item_name% eksik: %item_path%"
    if /i "%item_type%"=="klasor" (
        echo          Beklenen konum: %item_path%
        echo          Lutfen USB'de bu klasorun varligini kontrol edin.
    ) else (
        echo          Beklenen konum: %item_path%
    )
    set /a "test_fail+=1"
)
goto :eof
