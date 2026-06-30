# =============================================================================
#  Deploy.ps1
#  KBU Workstation Deployment Tool   Main Entry Point
#  Karabuk Universitesi - Bilgi Islem Daire Baskanligi
#
#  Orchestrates the main menu and delegates to domain modules.
#  All behavior is driven by the central $Config object loaded from config.json.
#  Modules (Config, Logger, Network, Installer, Desktop) receive config
#  values as parameters, never hardcoded strings.
# =============================================================================

# ----- UTF-8 encoding -----
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = [Text.Encoding]::UTF8

# ----- Dot-source all modules -----
. "$PSScriptRoot\Config.ps1"
. "$PSScriptRoot\Logger.ps1"
. "$PSScriptRoot\Network.ps1"
. "$PSScriptRoot\Installer.ps1"
. "$PSScriptRoot\Desktop.ps1"

# ----- Detect USB root -----
if ($env:KBU_USB_ROOT) {
    $UsbRoot = $env:KBU_USB_ROOT.TrimEnd('\')
}
else {
    $UsbRoot = Split-Path $PSScriptRoot -Parent
}

# ----- Load central configuration (validates, exits on failure) -----
$Cfg = Get-Configuration -UsbRoot $UsbRoot

# ----- Set window title and console colours from config -----
$host.UI.RawUI.WindowTitle = $Cfg.AppTitle
[Console]::BackgroundColor = $Cfg.BackgroundColor
[Console]::ForegroundColor = $Cfg.ForegroundColor
Clear-Host

# ----- Set up logging -----
Set-LogPath -Path $Cfg.LogFile

# ----- Initial log entries -----
Write-InstallLog "=============================================="
Write-InstallLog "  $($Cfg.AppName) v$($Cfg.Version)"
Write-InstallLog "  Baslangic: $(Get-Date -Format $Cfg.DateFormat)"
Write-InstallLog "  USB Konum: $UsbRoot"
Write-InstallLog "=============================================="

# =============================================================================
#  HELPER FUNCTIONS
# =============================================================================

function Test-CheckItem {
    param([string]$Path, [string]$Label, [string]$Type)
    if (Test-Path $Path) {
        Write-StatusOk "$Label bulundu."
        Write-InstallLog "[OK] $Label mevcut: $Path"
        return $true
    }
    else {
        Write-StatusError "$Label BULUNAMADI!"
        Write-InstallLog "[HATA] $Label eksik: $Path"
        Write-Host "         Beklenen konum: $Path"
        if ($Type -eq "klasor") {
            Write-Host "         Lutfen USB'de bu klasorun varligini kontrol edin."
        }
        return $false
    }
}

# =============================================================================
#  MAIN MENU
# =============================================================================
function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2554).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2557).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host $Cfg.AppName -NoNewline -ForegroundColor Yellow
    Write-Host "  " -NoNewline
    Write-Host ("v" + $Cfg.Version).PadRight(49 - $Cfg.AppName.Length) -NoNewline -ForegroundColor Red
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host $Cfg.Institution.PadRight(55) -NoNewline -ForegroundColor Cyan
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2560).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2563).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                                                          " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "[0]" -NoNewline -ForegroundColor Magenta
    Write-Host "  " -NoNewline
    Write-Host "TEST MODU (Dry Run)" -NoNewline -ForegroundColor Magenta
    Write-Host "                                  " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "        USB icerigini kontrol eder, kurulum YAPMAZ        " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                                                          " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "[1]" -NoNewline -ForegroundColor Green
    Write-Host "  " -NoNewline
    Write-Host "Cevrimdisi Kurulum" -NoNewline -ForegroundColor Green
    Write-Host "                                    " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "        AnyDesk, Akia, Java, Office + Masaustu Ogeleri    " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                                                          " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "[2]" -NoNewline -ForegroundColor Cyan
    Write-Host "  " -NoNewline
    Write-Host "Cevrimici Kurulum" -NoNewline -ForegroundColor Cyan
    Write-Host "                                     " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "        enVision.Client.Service + Ninite Paketleri        " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                                                          " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "[3]" -NoNewline -ForegroundColor Red
    Write-Host "  " -NoNewline
    Write-Host "Cikis" -NoNewline -ForegroundColor Red
    Write-Host "                                               " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                                                          " -NoNewline
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline
    Write-Host ([char]0x255A).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x255D).ToString() -ForegroundColor White
    Write-Host ""
}

# =============================================================================
#  OFFLINE INSTALLATION WORKFLOW
# =============================================================================
function Invoke-OfflineInstall {
    Clear-Host
    Write-BoxHeader "CEVRIMDISI KURULUM BASLATILIYOR..." Green
    Write-InstallLog "--- Cevrimdisi Kurulum Basladi ---"

    Install-AnyDesk -SourcePath $Cfg.Paths.AnyDesk -DesktopPath $Cfg.Paths.Desktop
    Install-Akia     -SourcePath $Cfg.Paths.Akia    -RelPath $Cfg.RawPaths.AkiaRel
    Install-Java     -SourcePath $Cfg.Paths.Java    -SilentArgs1 $Cfg.JavaSilent1 -SilentArgs2 $Cfg.JavaSilent2 -RelPath $Cfg.RawPaths.JavaRel
    Install-Office   -SourcePath $Cfg.Paths.OfficeSetup

    Write-Host ""
    Write-Host "  [5/6] Masaustu simgeleri ekleniyor..."
    Add-DesktopIcons -Icons $Cfg.DesktopIcons -RegistryPath $Cfg.DesktopRegPath
    Write-StatusOk "Masaustu simgeleri eklendi."
    Write-InstallLog "[OK] Masaustu simgeleri (Bu PC, Denetim Masasi, Ag, Geri Donusum Kutusu) eklendi."

    Write-Host ""
    Write-Host "  [6/6] Windows Gezgini yenileniyor..."
    Refresh-Explorer -WaitSeconds $Cfg.ExplorerWaitSec
    Write-StatusOk "Windows Gezgini yenilendi."
    Write-InstallLog "[OK] Windows Gezgini yenilendi."

    Write-BoxHeader "CEVRIMDISI KURULUM TAMAMLANDI!" Green
    Write-Host "         Log dosyasi: $($Cfg.LogFile)"
    Write-Host ""
    Write-InstallLog "--- Cevrimdisi Kurulum Tamamlandi ---"
    Write-InstallLog ""
    Read-Host "Devam etmek icin bir tusa basin"
}

# =============================================================================
#  ONLINE INSTALLATION WORKFLOW
# =============================================================================
function Invoke-OnlineInstall {
    Clear-Host
    Write-BoxHeader "CEVRIMICI KURULUM BASLATILIYOR..." Cyan
    Write-InstallLog "--- Cevrimici Kurulum Basladi ---"

    Write-Host "  Internet baglantisi kontrol ediliyor..."
    $online = Test-InternetConnection -Targets $Cfg.NetTargets -TimeoutMs $Cfg.NetTimeoutMs
    if (-not $online) {
        Write-Host ""
        Write-StatusError "Internet baglantisi bulunamadi!"
        Write-Host ""
        Write-Host "  Lutfen ag baglantinizi kontrol edip tekrar deneyin."
        Write-Host "  Alternatif olarak Cevrimdisi Kurulumu kullanabilirsiniz."
        Write-Host ""
        Write-InstallLog "[HATA] Internet baglantisi yok! Cevrimici kurulum iptal edildi."
        Read-Host "Devam etmek icin bir tusa basin"
        return
    }
    Write-StatusOk "Internet baglantisi mevcut."
    Write-InstallLog "[OK] Internet baglantisi dogrulandi."

    Install-Envision -SourcePath $Cfg.Paths.Envision -SilentArgs1 $Cfg.EnvSilent1 -SilentArgs2 $Cfg.EnvSilent2 -RelPath $Cfg.RawPaths.EnvisionRel
    Install-Ninite   -SourcePath $Cfg.Paths.Ninite

    Write-BoxHeader "CEVRIMICI KURULUM TAMAMLANDI!" Cyan
    Write-Host "         Log dosyasi: $($Cfg.LogFile)"
    Write-Host ""
    Write-InstallLog "--- Cevrimici Kurulum Tamamlandi ---"
    Write-InstallLog ""
    Read-Host "Devam etmek icin bir tusa basin"
}

# =============================================================================
#  TEST MODE (DRY RUN)
# =============================================================================
function Invoke-TestMode {
    Clear-Host
    Write-Host ""
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2554).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2557).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "              " -NoNewline
    Write-Host "TEST MODU (DRY RUN) BASLATILIYOR" -NoNewline -ForegroundColor Magenta
    Write-Host "                  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "         " -NoNewline
    Write-Host "HICBIR KURULUM VEYA DEGISIKLIK YAPILMAZ" -NoNewline -ForegroundColor Yellow
    Write-Host "              " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x255A).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x255D).ToString() -ForegroundColor White
    Write-Host ""
    Write-InstallLog "--- TEST MODU (DRY RUN) Basladi ---"
    Write-InstallLog "  UYARI: Bu mod hicbir kurulum yapmaz, sadece kontrol eder."

    $testPass = 0
    $testFail = 0

    $checks = @(
        @{ Step="[1/9]"; Path=$Cfg.Paths.KbuDir;      Label="$($Cfg.RawPaths.KbuDirName) klasoru";       Type="klasor" }
        @{ Step="[2/9]"; Path=$Cfg.Paths.OfficeDir;   Label="$($Cfg.RawPaths.OfficeDirName) klasoru";    Type="klasor" }
        @{ Step="[3/9]"; Path=$Cfg.Paths.AnyDesk;     Label="AnyDesk.exe";                                Type="dosya" }
        @{ Step="[4/9]"; Path=$Cfg.Paths.Akia;        Label="Akia installer";                             Type="dosya" }
        @{ Step="[5/9]"; Path=$Cfg.Paths.Java;        Label="Java JRE installer";                         Type="dosya" }
        @{ Step="[6/9]"; Path=$Cfg.Paths.OfficeSetup; Label="Office Setup.exe";                           Type="dosya" }
        @{ Step="[7/9]"; Path=$Cfg.Paths.Envision;    Label="enVision.Client.Service.exe";                Type="dosya" }
        @{ Step="[8/9]"; Path=$Cfg.Paths.Ninite;      Label="Ninite Installer";                           Type="dosya" }
    )

    foreach ($chk in $checks) {
        Write-Host "  $($chk.Step) $($chk.Label) kontrol ediliyor..."
        $ok = Test-CheckItem -Path $chk.Path -Label $chk.Label -Type $chk.Type
        if ($ok) { $testPass++ } else { $testFail++ }
        Write-Host ""
    }

    Write-Host "  [9/9] Internet baglantisi kontrol ediliyor..."
    $online = Test-InternetConnection -Targets $Cfg.NetTargets -TimeoutMs $Cfg.NetTimeoutMs
    if ($online) {
        Write-StatusOk "Internet baglantisi mevcut."
        Write-InstallLog "[OK] Internet baglantisi: MEVCUT"
        $testPass++
    }
    else {
        Write-StatusWarn "Internet baglantisi bulunamadi. (Cevrimici kurulum calismaz!)"
        Write-InstallLog "[UYARI] Internet baglantisi: YOK"
        $testFail++
    }
    Write-Host ""

    Write-TestSummary $testPass $testFail
    Write-Host "         Log dosyasi: $($Cfg.LogFile)"
    Write-Host ""
    Write-InstallLog "--- TEST MODU Tamamlandi (Gecen: $testPass, Kalan: $testFail) ---"
    Write-InstallLog ""
    Read-Host "Devam etmek icin bir tusa basin"
}

# =============================================================================
#  UI HELPERS (driven by $Cfg)
# =============================================================================
function Write-BoxHeader {
    param([string]$Text, [ConsoleColor]$Color)
    Write-Host ""
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2554).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2557).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "         " -NoNewline
    Write-Host $Text -NoNewline -ForegroundColor $Color
    Write-Host (" " * (56 - $Text.Length)) -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x255A).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x255D).ToString() -ForegroundColor White
    Write-Host ""
}

function Write-TestSummary {
    param([int]$Pass, [int]$Fail)

    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2554).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2557).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "                   " -NoNewline
    Write-Host "TEST SONUCLARI" -NoNewline -ForegroundColor Magenta
    Write-Host "                              " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2560).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2563).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "Basarili: $Pass/9" -NoNewline -ForegroundColor Green
    Write-Host (" " * (47 - "Basarili: $Pass/9".Length)) -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "Basarisiz: $Fail/9" -NoNewline -ForegroundColor Red
    Write-Host (" " * (47 - "Basarisiz: $Fail/9".Length)) -NoNewline -ForegroundColor White
    Write-Host ([char]0x2551).ToString() -ForegroundColor White
    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x2560).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x2563).ToString() -ForegroundColor White

    if ($Fail -eq 0) {
        Write-Host "  " -NoNewline -ForegroundColor White
        Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
        Write-Host "   " -NoNewline
        Write-Host "Tum kontroller basarili! Kuruluma hazir." -NoNewline -ForegroundColor Green
        Write-Host "              " -NoNewline -ForegroundColor White
        Write-Host ([char]0x2551).ToString() -ForegroundColor White
        Write-InstallLog "[OZET] Tum kontroller basarili ($Pass/9). USB kuruluma hazir."
    }
    else {
        Write-Host "  " -NoNewline -ForegroundColor White
        Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
        Write-Host "   " -NoNewline
        Write-Host "Eksik dosya/klasor var! Eksikleri tamamlayin." -NoNewline -ForegroundColor Red
        Write-Host "        " -NoNewline -ForegroundColor White
        Write-Host ([char]0x2551).ToString() -ForegroundColor White
        Write-InstallLog "[OZET] $Fail kontrol basarisiz. USB tamamlanmali."
    }

    Write-Host "  " -NoNewline -ForegroundColor White
    Write-Host ([char]0x255A).ToString() -NoNewline -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
    Write-Host ([char]0x255D).ToString() -ForegroundColor White
}

# =============================================================================
#  MAIN LOOP (only runs when script is invoked directly, not dot-sourced)
# =============================================================================
if ($MyInvocation.InvocationName -ne '.') {
do {
    Show-MainMenu
    $choice = Read-Host "   Seciminizi yapin (0-3)"

    switch ($choice) {
        "0" { Invoke-TestMode }
        "1" { Invoke-OfflineInstall }
        "2" { Invoke-OnlineInstall }
        "3" {
            Clear-Host
            Write-Host ""
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2554).ToString() -NoNewline -ForegroundColor White
            Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
            Write-Host ([char]0x2557).ToString() -ForegroundColor White
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
            Write-Host "                                                          " -NoNewline
            Write-Host ([char]0x2551).ToString() -ForegroundColor White
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
            Write-Host "         $($Cfg.AppName)" -NoNewline -ForegroundColor White
            Write-Host (" " * (56 - $Cfg.AppName.Length)) -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -ForegroundColor White
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
            Write-Host "         " -NoNewline
            Write-Host "Kapatiliyor... Gule gule!" -NoNewline -ForegroundColor Yellow
            Write-Host "                            " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -ForegroundColor White
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x2551).ToString() -NoNewline -ForegroundColor White
            Write-Host "                                                          " -NoNewline
            Write-Host ([char]0x2551).ToString() -ForegroundColor White
            Write-Host "  " -NoNewline -ForegroundColor White
            Write-Host ([char]0x255A).ToString() -NoNewline -ForegroundColor White
            Write-Host "══════════════════════════════════════════════════════════" -NoNewline -ForegroundColor White
            Write-Host ([char]0x255D).ToString() -ForegroundColor White
            Write-Host ""
            Write-Host "         Log dosyasi: $($Cfg.LogFile)"
            Write-Host ""

            Write-InstallLog "=============================================="
            Write-InstallLog "  $($Cfg.AppName) - Sonlandi"
            Write-InstallLog "  Bitis: $(Get-Date -Format $Cfg.DateFormat)"
            Write-InstallLog "=============================================="

            Start-Sleep -Seconds $Cfg.ExitWaitSec
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "  [!] Gecersiz secim! Lutfen 0, 1, 2 veya 3 girin." -ForegroundColor Red
            Start-Sleep -Seconds $Cfg.InvalidWaitSec
        }
    }
} while ($true)
}
