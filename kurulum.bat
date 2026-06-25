@echo off
setlocal enabledelayedexpansion

:: =============================================================================
::  KBU Workstation Deployment Tool  v1.1
::  Karabük Üniversitesi - Bilgi İşlem Daire Başkanlığı
::  Yeni iş istasyonu otomasyon kurulum betiği
:: =============================================================================
::
::  KULLANIM:
::    1. USB belleği yeni Windows 10 bilgisayara takın
::    2. USB bellekteki kurulum.bat dosyasına çift tıklayın (Yönetici olarak)
::    3. Önce [0] Test Modu ile USB içeriğini doğrulayın
::    4. Menüden seçim yapıp kurulumu başlatın
::
::  USB KLASÖR YAPISI:
::    USB_ROOT
::    ├── kurulum.bat
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

:: ---------- UTF-8 kod sayfası (Türkçe karakter desteği) ----------
chcp 65001 >nul 2>&1

:: ---------- Pencere başlığı ve renk ----------
title KBU Workstation Deployment Tool
color 1F

:: ---------- USB kök dizini (betiğin çalıştığı konum) ----------
:: Eğer KBU_USB_ROOT ortam değişkeni ayarlanmışsa onu kullan (EXE modu),
:: yoksa betiğin kendi konumunu kullan (normal .bat çalıştırma)
if defined KBU_USB_ROOT (
    set "USB_ROOT=%KBU_USB_ROOT%"
) else (
    set "USB_ROOT=%~dp0"
)
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

:: ---------- Sabit dizin yolları ----------
set "KBU_DIR=%USB_ROOT%\Kbü"
set "OFFICE_DIR=%USB_ROOT%\Office Çevrimdışı"
set "DESKTOP=%USERPROFILE%\Desktop"
set "LOG_FILE=%DESKTOP%\kurulum_log.txt"

:: ---------- Kurulum dosyaları ----------
set "ANYDESK=%KBU_DIR%\AnyDesk.exe"
set "AKIA=%KBU_DIR%\Akia_windows-x64_6_7_6.exe"
set "JAVA=%KBU_DIR%\jre-8u411-windows-x64.exe"
set "ENVISION=%KBU_DIR%\enVision.Client.Service.exe"
set "NINITE=%KBU_DIR%\Ninite Chrome Firefox Foxit Reader GOM Installer.exe"
set "OFFICE_SETUP=%OFFICE_DIR%\Setup.exe"

:: ---------- Başlangıç log kaydı ----------
call :log "=============================================="
call :log "  KBU Workstation Deployment Tool v1.1"
call :log "  Başlangıç: %DATE% - %TIME%"
call :log "  USB Konum: %USB_ROOT%"
call :log "=============================================="

:: =============================================================================
::  ANA MENÜ
:: =============================================================================
:main_menu
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║   [1;33mKBU WORKSTATION DEPLOYMENT TOOL  [1;31mv1.1[1;37m                   ║
echo  ║   [1;36mKarabük Üniversitesi - Bilgi İşlem Daire Başkanlığı[1;37m    ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║                                                          ║
echo  ║   [[1;35m0[1;37m]  [1;35mTEST MODU (Dry Run)[1;37m                                  ║
echo  ║        USB içeriğini kontrol eder, kurulum YAPMAZ        ║
echo  ║                                                          ║
echo  ║   [[1;32m1[1;37m]  [1;32mÇevrimdışı Kurulum[1;37m                                    ║
echo  ║        AnyDesk, Akia, Java, Office + Masaüstü Öğeleri    ║
echo  ║                                                          ║
echo  ║   [[1;36m2[1;37m]  [1;36mÇevrimiçi Kurulum[1;37m                                     ║
echo  ║        enVision.Client.Service + Ninite Paketleri        ║
echo  ║                                                          ║
echo  ║   [[1;31m3[1;37m]  [1;31mÇıkış[1;37m                                               ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
set "menu_choice="
set /p menu_choice="   Seçiminizi yapın (0-3): "

if "%menu_choice%"=="0" goto test_mode
if "%menu_choice%"=="1" goto offline_install
if "%menu_choice%"=="2" goto online_install
if "%menu_choice%"=="3" goto exit_script

:: Geçersiz seçim
echo.
echo   [1;31m[!] Geçersiz seçim! Lütfen 0, 1, 2 veya 3 girin.[0m
timeout /t 2 /nobreak >nul
goto main_menu


:: =============================================================================
::  ÇEVRİMDIŞI KURULUM
:: =============================================================================
:offline_install
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║         [1;32mÇEVRİMDIŞI KURULUM BAŞLATILIYOR...[1;37m                  ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- Çevrimdışı Kurulum Başladı ---"

:: ---------------------------------------------------
:: 1. AnyDesk masaüstüne kopyalama
:: ---------------------------------------------------
echo   [1/6] AnyDesk masaüstüne kopyalanıyor...
if exist "%ANYDESK%" (
    echo          Kaynak: %ANYDESK%
    copy /Y "%ANYDESK%" "%DESKTOP%\AnyDesk.exe" >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "AnyDesk başarıyla masaüstüne kopyalandı."
        call :log "[OK] AnyDesk kopyalandı: %DESKTOP%\AnyDesk.exe"
    ) else (
        call :show_err "AnyDesk kopyalanırken hata oluştu! (Yetki sorunu olabilir)"
        call :log "[HATA] AnyDesk kopyalanamadı (errorlevel: !errorlevel!)"
    )
) else (
    call :show_warn "AnyDesk.exe bulunamadı! Atlanıyor..."
    call :log "[UYARI] AnyDesk.exe bulunamadı: %ANYDESK%"
)

:: ---------------------------------------------------
:: 2. Akia kurulumu
:: ---------------------------------------------------
echo.
echo   [2/6] Akia kuruluyor...
if exist "%AKIA%" (
    echo          Dosya: %AKIA%
    echo          Kurulum başlatılıyor, lütfen ekrandaki adımları takip edin...
    start "" /wait "%AKIA%"
    if !errorlevel! equ 0 (
        call :show_ok "Akia kurulumu tamamlandı."
        call :log "[OK] Akia kuruldu."
    ) else (
        call :show_warn "Akia kurulumu tamamlandı (kullanıcı iptal etmiş olabilir)."
        call :log "[UYARI] Akia kurulumu !errorlevel! koduyla sonlandı."
    )
) else (
    call :show_warn "Akia_windows-x64_6_7_6.exe bulunamadı! Atlanıyor..."
    call :log "[UYARI] Akia dosyası bulunamadı: %AKIA%"
)

:: ---------------------------------------------------
:: 3. Java JRE sessiz kurulum
:: ---------------------------------------------------
echo.
echo   [3/6] Java JRE sessiz kuruluyor...
if exist "%JAVA%" (
    echo          Dosya: %JAVA%
    echo          Sessiz kurulum çalıştırılıyor, lütfen bekleyin...
    "%JAVA%" /s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "Java JRE sessiz olarak başarıyla kuruldu."
        call :log "[OK] Java JRE 8u411 sessiz kuruldu."
    ) else (
        :: Alternatif sessiz parametrelerle dene
        "%JAVA%" INSTALL_SILENT=1 REBOOT=Suppress >nul 2>&1
        if !errorlevel! equ 0 (
            call :show_ok "Java JRE sessiz olarak başarıyla kuruldu. (alternatif yöntem)"
            call :log "[OK] Java JRE 8u411 sessiz kuruldu (alternatif yöntem)."
        ) else (
            call :show_warn "Java JRE sessiz kurulumu başarısız! Etkileşimli deneniyor..."
            call :log "[UYARI] Java sessiz kurulum başarısız, etkileşimli deneniyor."
            start "" /wait "%JAVA%"
            call :log "[BİLGİ] Java etkileşimli kurulum tamamlandı."
        )
    )
) else (
    call :show_warn "jre-8u411-windows-x64.exe bulunamadı! Atlanıyor..."
    call :log "[UYARI] Java JRE dosyası bulunamadı: %JAVA%"
)

:: ---------------------------------------------------
:: 4. Office çevrimdışı kurulum
:: ---------------------------------------------------
echo.
echo   [4/6] Microsoft Office kuruluyor...
if exist "%OFFICE_SETUP%" (
    echo          Dosya: %OFFICE_SETUP%
    echo          Office kurulumu başlatılıyor, lütfen ekrandaki adımları takip edin...
    echo          (Bu işlem birkaç dakika sürebilir)
    start "" /wait "%OFFICE_SETUP%"
    if !errorlevel! equ 0 (
        call :show_ok "Office kurulumu tamamlandı."
        call :log "[OK] Microsoft Office kuruldu."
    ) else (
        call :show_warn "Office kurulumu tamamlandı (hata kodu: !errorlevel!)."
        call :log "[UYARI] Office kurulumu !errorlevel! koduyla sonlandı."
    )
) else (
    call :show_warn "Office\Setup.exe bulunamadı! Yol: %OFFICE_SETUP%"
    call :show_warn "Office Çevrimdışı klasörü ve Setup.exe'nin varlığını kontrol edin."
    call :log "[UYARI] Office Setup.exe bulunamadı: %OFFICE_SETUP%"
)

:: ---------------------------------------------------
:: 5. Masaüstü simgelerini ekleme
:: ---------------------------------------------------
echo.
echo   [5/6] Masaüstü simgeleri ekleniyor...
call :add_desktop_icons
call :show_ok "Masaüstü simgeleri eklendi."
call :log "[OK] Masaüstü simgeleri (Bu PC, Denetim Masası, Ağ, Geri Dönüşüm Kutusu) eklendi."

:: ---------------------------------------------------
:: 6. Windows Gezgini'ni yenileme
:: ---------------------------------------------------
echo.
echo   [6/6] Windows Gezgini yenileniyor...
call :refresh_explorer
call :show_ok "Windows Gezgini yenilendi."
call :log "[OK] Windows Gezgini yenilendi."

:: ---------------------------------------------------
:: Özet
:: ---------------------------------------------------
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║          [1;32mÇEVRİMDIŞI KURULUM TAMAMLANDI![1;37m                     ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyası: %LOG_FILE%
echo.
call :log "--- Çevrimdışı Kurulum Tamamlandı ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  ÇEVRİMİÇİ KURULUM
:: =============================================================================
:online_install
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║         [1;36mÇEVRİMİÇİ KURULUM BAŞLATILIYOR...[1;37m                    ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- Çevrimiçi Kurulum Başladı ---"

:: ---------------------------------------------------
:: İnternet bağlantısı kontrolü
:: ---------------------------------------------------
echo   İnternet bağlantısı kontrol ediliyor...
call :check_internet
if !internet_ok! equ 0 (
    echo.
    call :show_err "İnternet bağlantısı bulunamadı!"
    echo.
    echo   Lütfen ağ bağlantınızı kontrol edip tekrar deneyin.
    echo   Alternatif olarak Çevrimdışı Kurulumu kullanabilirsiniz.
    echo.
    call :log "[HATA] İnternet bağlantısı yok! Çevrimiçi kurulum iptal edildi."
    pause
    goto main_menu
)
call :show_ok "İnternet bağlantısı mevcut."
call :log "[OK] İnternet bağlantısı doğrulandı."

:: ---------------------------------------------------
:: 1. enVision.Client.Service kurulumu
:: ---------------------------------------------------
echo.
echo   [1/2] enVision.Client.Service kuruluyor...
if exist "%ENVISION%" (
    echo          Dosya: %ENVISION%
    echo          Kurulum çalıştırılıyor, lütfen bekleyin...
    "%ENVISION%" /quiet /norestart >nul 2>&1
    if !errorlevel! equ 0 (
        call :show_ok "enVision.Client.Service başarıyla kuruldu."
        call :log "[OK] enVision.Client.Service kuruldu."
    ) else (
        :: Sessiz başarısız olursa etkileşimli dene
        "%ENVISION%" /S >nul 2>&1
        if !errorlevel! equ 0 (
            call :show_ok "enVision.Client.Service başarıyla kuruldu."
            call :log "[OK] enVision.Client.Service kuruldu."
        ) else (
            echo          Sessiz kurulum başarısız, etkileşimli deneniyor...
            start "" /wait "%ENVISION%"
            call :show_warn "enVision.Client.Service etkileşimli olarak çalıştırıldı."
            call :log "[UYARI] enVision sessiz kurulamadı, etkileşimli çalıştırıldı."
        )
    )
) else (
    call :show_warn "enVision.Client.Service.exe bulunamadı! Atlanıyor..."
    call :log "[UYARI] enVision dosyası bulunamadı: %ENVISION%"
)

:: ---------------------------------------------------
:: 2. Ninite paket kurulumu
:: ---------------------------------------------------
echo.
echo   [2/2] Ninite paketleri kuruluyor (Chrome, Firefox, Foxit Reader, GOM)...
if exist "%NINITE%" (
    echo          Dosya: %NINITE%
    echo          Ninite çalıştırılıyor, lütfen bekleyin...
    start "" /wait "%NINITE%"
    if !errorlevel! equ 0 (
        call :show_ok "Ninite paketleri başarıyla kuruldu."
        call :log "[OK] Ninite paketleri (Chrome, Firefox, Foxit, GOM) kuruldu."
    ) else (
        call :show_warn "Ninite kurulumu tamamlandı (hata kodu: !errorlevel!)."
        call :log "[UYARI] Ninite !errorlevel! koduyla sonlandı."
    )
) else (
    call :show_warn "Ninite Installer bulunamadı! Atlanıyor..."
    call :log "[UYARI] Ninite dosyası bulunamadı: %NINITE%"
)

:: ---------------------------------------------------
:: Özet
:: ---------------------------------------------------
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║          [1;36mÇEVRİMİÇİ KURULUM TAMAMLANDI![1;37m                       ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyası: %LOG_FILE%
echo.
call :log "--- Çevrimiçi Kurulum Tamamlandı ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  TEST MODU (DRY RUN)
::  Hiçbir kurulum yapmaz, sadece USB içeriğini ve interneti kontrol eder.
::  Tüm sonuçlar log dosyasına ve ekrana yazılır.
:: =============================================================================
:test_mode
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║              [1;35mTEST MODU (DRY RUN) BAŞLATILIYOR[1;37m                  ║
echo  ║         [1;33mHİÇBİR KURULUM VEYA DEĞİŞİKLİK YAPILMAZ[1;37m              ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
call :log "--- TEST MODU (DRY RUN) Başladı ---"
call :log "  UYARI: Bu mod hiçbir kurulum yapmaz, sadece kontrol eder."

:: Karşılama sayacı
set "test_pass=0"
set "test_fail=0"

:: ---------------------------------------------------
:: 1. Kbü klasörü kontrolü
:: ---------------------------------------------------
echo   [1/9] Kbü klasörü kontrol ediliyor...
call :check_item "%KBU_DIR%" "Kbü klasörü" "klasör"
echo.

:: ---------------------------------------------------
:: 2. Office Çevrimdışı klasörü kontrolü
:: ---------------------------------------------------
echo   [2/9] Office Çevrimdışı klasörü kontrol ediliyor...
call :check_item "%OFFICE_DIR%" "Office Çevrimdışı klasörü" "klasör"
echo.

:: ---------------------------------------------------
:: 3. AnyDesk.exe kontrolü
:: ---------------------------------------------------
echo   [3/9] AnyDesk.exe kontrol ediliyor...
call :check_item "%ANYDESK%" "AnyDesk.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 4. Akia installer kontrolü
:: ---------------------------------------------------
echo   [4/9] Akia_windows-x64_6_7_6.exe kontrol ediliyor...
call :check_item "%AKIA%" "Akia installer" "dosya"
echo.

:: ---------------------------------------------------
:: 5. Java JRE installer kontrolü
:: ---------------------------------------------------
echo   [5/9] jre-8u411-windows-x64.exe kontrol ediliyor...
call :check_item "%JAVA%" "Java JRE installer" "dosya"
echo.

:: ---------------------------------------------------
:: 6. Office Setup.exe kontrolü
:: ---------------------------------------------------
echo   [6/9] Office Setup.exe kontrol ediliyor...
call :check_item "%OFFICE_SETUP%" "Office Setup.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 7. enVision.Client.Service.exe kontrolü
:: ---------------------------------------------------
echo   [7/9] enVision.Client.Service.exe kontrol ediliyor...
call :check_item "%ENVISION%" "enVision.Client.Service.exe" "dosya"
echo.

:: ---------------------------------------------------
:: 8. Ninite installer kontrolü
:: ---------------------------------------------------
echo   [8/9] Ninite installer kontrol ediliyor...
call :check_item "%NINITE%" "Ninite Installer" "dosya"
echo.

:: ---------------------------------------------------
:: 9. İnternet bağlantısı kontrolü
:: ---------------------------------------------------
echo   [9/9] İnternet bağlantısı kontrol ediliyor...
call :check_internet
if !internet_ok! equ 1 (
    call :show_ok "İnternet bağlantısı mevcut."
    call :log "[OK] İnternet bağlantısı: MEVCUT"
    set /a "test_pass+=1"
) else (
    call :show_warn "İnternet bağlantısı bulunamadı. (Çevrimiçi kurulum çalışmaz!)"
    call :log "[UYARI] İnternet bağlantısı: YOK"
    set /a "test_fail+=1"
)
echo.

:: ---------------------------------------------------
:: Test Özeti
:: ---------------------------------------------------
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║                   [1;35mTEST SONUÇLARI[1;37m                              ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║   [1;32mBaşarılı: !test_pass!/9[1;37m                                     ║
echo  ║   [1;31mBaşarısız: !test_fail!/9[1;37m                                   ║
echo  ╠══════════════════════════════════════════════════════════╣

if !test_fail! equ 0 (
    echo  ║   [1;32mTüm kontroller başarılı! Kuruluma hazır.[1;37m              ║
    call :log "[ÖZET] Tüm kontroller başarılı (!test_pass!/9). USB kuruluma hazır."
) else (
    echo  ║   [1;31mEksik dosya/klasör var! Eksikleri tamamlayın.[1;37m        ║
    call :log "[ÖZET] !test_fail! kontrol başarısız. USB tamamlanmalı."
)

echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyası: %LOG_FILE%
echo.
call :log "--- TEST MODU Tamamlandı (Geçen: !test_pass!, Kalan: !test_fail!) ---"
call :log ""
pause
goto main_menu


:: =============================================================================
::  ÇIKIŞ
:: =============================================================================
:exit_script
cls
echo.
echo  [1;37m╔══════════════════════════════════════════════════════════╗
echo  ║                                                          ║
echo  ║         KBU Workstation Deployment Tool                  ║
echo  ║         [1;33mKapatılıyor... Güle güle![1;37m                            ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝[0m
echo.
echo          Log dosyası: %LOG_FILE%
echo.
call :log "=============================================="
call :log "  KBU Workstation Deployment Tool - Sonlandı"
call :log "  Bitiş: %DATE% - %TIME%"
call :log "=============================================="
timeout /t 2 /nobreak >nul
exit /b 0


:: =============================================================================
::  FONKSİYON: İnternet bağlantısı kontrolü
::  Sonuç: !internet_ok! değişkenine 1 (var) veya 0 (yok) atar
:: =============================================================================
:check_internet
set "internet_ok=0"

:: DNS sunucusuna ping at (8.8.8.8 = Google DNS)
ping -n 1 -w 3000 8.8.8.8 >nul 2>&1
if !errorlevel! equ 0 (
    set "internet_ok=1"
    goto :eof
)

:: Alternatif: google.com'a ping at
ping -n 1 -w 3000 google.com >nul 2>&1
if !errorlevel! equ 0 (
    set "internet_ok=1"
    goto :eof
)

:: Alternatif: cloudflare DNS
ping -n 1 -w 3000 1.1.1.1 >nul 2>&1
if !errorlevel! equ 0 (
    set "internet_ok=1"
    goto :eof
)
goto :eof


:: =============================================================================
::  FONKSİYON: Masaüstü simgelerini ekle
::  Registry üzerinden Bu PC, Denetim Masası, Ağ ve Geri Dönüşüm Kutusu
:: =============================================================================
:add_desktop_icons

:: Registry anahtarı yolu
set "REG_HIDE=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons"
set "REG_CLASSIC=%REG_HIDE%\ClassicStartMenu"
set "REG_NEW=%REG_HIDE%\NewStartPanel"

:: Her iki start menü modu için de simgeleri göster (0 = görünür, 1 = gizli)

:: Bu PC (Computer) - {20D04FE0-3AEA-1069-A2D8-08002B30309D}
reg add "%REG_NEW%" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Denetim Masası (Control Panel) - {5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}
reg add "%REG_NEW%" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Ağ (Network) - {F02C1A0D-BE21-4350-88B0-7367FC96EF3C}
reg add "%REG_NEW%" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f >nul 2>&1

:: Geri Dönüşüm Kutusu (Recycle Bin) - {645FF040-5081-101B-9F08-00AA002F954E}
reg add "%REG_NEW%" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0 /f >nul 2>&1

goto :eof


:: =============================================================================
::  FONKSİYON: Windows Gezgini'ni yenile
:: =============================================================================
:refresh_explorer
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
goto :eof


:: =============================================================================
::  FONKSİYON: Log yazma
::  Parametre: %1 = log mesajı
::  Hem dosyaya hem ekrana yazar
:: =============================================================================
:log
set "log_message=%~1"
echo %log_message%>>"%LOG_FILE%"
goto :eof


:: =============================================================================
::  FONKSİYON: Başarılı mesajı göster  (Yeşil)
:: =============================================================================
:show_ok
echo   [1;32m[√] %~1[0m
goto :eof


:: =============================================================================
::  FONKSİYON: Hata mesajı göster  (Kırmızı)
:: =============================================================================
:show_err
echo   [1;31m[X] %~1[0m
goto :eof


:: =============================================================================
::  FONKSİYON: Uyarı mesajı göster  (Sarı)
:: =============================================================================
:show_warn
echo   [1;33m[!] %~1[0m
goto :eof


:: =============================================================================
::  FONKSİYON: Tek bir öğeyi kontrol et (Test Modu için)
::  Parametreler: %1 = tam yol, %2 = görünen ad, %3 = tür (dosya/klasör)
::  Sonuç: test_pass veya test_fail sayacını artırır
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
    if /i "%item_type%"=="klasör" (
        echo          Beklenen konum: %item_path%
        echo          Lütfen USB'de bu klasörün varlığını kontrol edin.
    ) else (
        echo          Beklenen konum: %item_path%
    )
    set /a "test_fail+=1"
)
goto :eof
