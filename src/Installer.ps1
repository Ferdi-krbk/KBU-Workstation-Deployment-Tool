# =============================================================================
#  Installer.ps1
#  Software installation module.
#  Each function receives source paths from the central config object.
#  Silent-install arguments are also config-driven (config.json).
#  Every installer checks file existence via Test-InstallerExists helper,
#  runs the installer with appropriate arguments, handles fallbacks,
#  inspects exit codes, and logs results.
# =============================================================================

<#
.SYNOPSIS
    Validates that an installer file exists at the given path.
.DESCRIPTION
    Checks whether the file at $Path exists. If not, logs a warning
    and returns $false so the caller can skip installation gracefully.
.PARAMETER Path
    Full path to the installer executable.
.PARAMETER Label
    Human-readable name for log and console messages.
.EXAMPLE
    if (-not (Test-InstallerExists -Path "D:\Kbu\AnyDesk.exe" -Label "AnyDesk")) { return }
#>
function Test-InstallerExists {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label
    )
    if (Test-Path $Path -PathType Leaf) {
        return $true
    }
    Write-StatusWarn "$Label bulunamadi! Atlaniyor..."
    Write-InstallLog "[UYARI] $Label bulunamadi: $Path"
    return $false
}

<#
.SYNOPSIS
    Copies AnyDesk executable to the user Desktop.
.DESCRIPTION
    Verifies the source file exists, then copies it to the Desktop directory.
    Logs success or failure. Uses try/catch for copy errors.
.PARAMETER SourcePath
    Full path to AnyDesk.exe on the USB drive.
.PARAMETER DesktopPath
    Destination directory (usually the user Desktop folder).
.EXAMPLE
    Install-AnyDesk -SourcePath "D:\Kbu\AnyDesk.exe" -DesktopPath "C:\Users\Admin\Desktop"
#>
function Install-AnyDesk {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DesktopPath
    )

    Write-Host "  [1/6] AnyDesk masaustune kopyalaniyor..."

    if (-not (Test-InstallerExists -Path $SourcePath -Label "AnyDesk.exe")) {
        return $false
    }

    Write-Host "         Kaynak: $SourcePath"
    try {
        Copy-Item -Path $SourcePath -Destination "$DesktopPath\AnyDesk.exe" -Force -ErrorAction Stop
        Write-StatusOk "AnyDesk basariyla masaustune kopyalandi."
        Write-InstallLog "[OK] AnyDesk kopyalandi: $DesktopPath\AnyDesk.exe"
        return $true
    }
    catch {
        Write-StatusError "AnyDesk kopyalanirken hata olustu! (Yetki sorunu olabilir)"
        Write-InstallLog "[HATA] AnyDesk kopyalanamadi: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Installs Akia interactively.
.DESCRIPTION
    Verifies the installer exists, then runs it and waits for completion.
    Inspects the exit code and logs the result.
.PARAMETER SourcePath
    Full path to the Akia installer executable.
.PARAMETER RelPath
    Human-readable relative path for warning messages.
.EXAMPLE
    Install-Akia -SourcePath "D:\Kbu\Akia_windows-x64_6_7_6.exe" -RelPath "Kbu\Akia_windows-x64_6_7_6.exe"
#>
function Install-Akia {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [2/6] Akia kuruluyor..."

    $label = if ($RelPath) { $RelPath } else { "Akia installer" }
    if (-not (Test-InstallerExists -Path $SourcePath -Label $label)) {
        return $false
    }

    Write-Host "         Dosya: $SourcePath"
    Write-Host "         Kurulum baslatiliyor, lutfen ekrandaki adimlari takip edin..."
    $process = Start-Process -FilePath $SourcePath -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-StatusOk "Akia kurulumu tamamlandi."
        Write-InstallLog "[OK] Akia kuruldu."
        return $true
    }
    else {
        Write-StatusWarn "Akia kurulumu tamamlandi (kullanici iptal etmis olabilir)."
        Write-InstallLog "[UYARI] Akia kurulumu $($process.ExitCode) koduyla sonlandi."
        return $false
    }
}

<#
.SYNOPSIS
    Installs Java JRE with silent and fallback strategies.
.DESCRIPTION
    Attempts two silent install strategies from config.json.
    If both fail, falls back to interactive installation.
    Exit codes are inspected at every stage.
.PARAMETER SourcePath
    Full path to the Java JRE installer.
.PARAMETER SilentArgs1
    First silent install argument string (from config.json).
.PARAMETER SilentArgs2
    Second silent install argument string (from config.json, alternative method).
.PARAMETER RelPath
    Human-readable relative path for warning messages.
.EXAMPLE
    Install-Java -SourcePath "D:\Kbu\jre-8u411-windows-x64.exe" -SilentArgs1 "/s REBOOT=0..." -SilentArgs2 "INSTALL_SILENT=1..."
#>
function Install-Java {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SilentArgs1,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SilentArgs2,

        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [3/6] Java JRE sessiz kuruluyor..."

    $label = if ($RelPath) { $RelPath } else { "Java JRE installer" }
    if (-not (Test-InstallerExists -Path $SourcePath -Label $label)) {
        return $false
    }

    Write-Host "         Dosya: $SourcePath"
    Write-Host "         Sessiz kurulum calistiriliyor, lutfen bekleyin..."

    $proc1 = Start-Process -FilePath $SourcePath -ArgumentList $SilentArgs1 -Wait -NoNewWindow -PassThru
    if ($proc1.ExitCode -eq 0) {
        Write-StatusOk "Java JRE sessiz olarak basariyla kuruldu."
        Write-InstallLog "[OK] Java JRE sessiz kuruldu."
        return $true
    }

    Write-Host "         Alternatif sessiz yontem deneniyor..."
    $proc2 = Start-Process -FilePath $SourcePath -ArgumentList $SilentArgs2 -Wait -NoNewWindow -PassThru
    if ($proc2.ExitCode -eq 0) {
        Write-StatusOk "Java JRE sessiz olarak basariyla kuruldu. (alternatif yontem)"
        Write-InstallLog "[OK] Java JRE sessiz kuruldu (alternatif yontem)."
        return $true
    }

    Write-StatusWarn "Java JRE sessiz kurulumu basarisiz! Etkilesimli deneniyor..."
    Write-InstallLog "[UYARI] Java sessiz kurulum basarisiz, etkilesimli deneniyor."
    $proc3 = Start-Process -FilePath $SourcePath -Wait -PassThru
    if ($proc3.ExitCode -eq 0) {
        Write-StatusOk "Java JRE etkilesimli olarak kuruldu."
        Write-InstallLog "[OK] Java JRE etkilesimli kuruldu."
        return $true
    }
    else {
        Write-StatusError "Java JRE kurulumu basarisiz oldu! (exit code: $($proc3.ExitCode))"
        Write-InstallLog "[HATA] Java JRE kurulumu $($proc3.ExitCode) koduyla basarisiz oldu."
        return $false
    }
}

<#
.SYNOPSIS
    Installs Microsoft Office from the offline installer.
.DESCRIPTION
    Verifies the Office Setup.exe exists, then runs it interactively.
    Inspects the exit code and logs the result.
.PARAMETER SourcePath
    Full path to Office Setup.exe.
.EXAMPLE
    Install-Office -SourcePath "D:\Office Cevrimdisi\Setup.exe"
#>
function Install-Office {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath
    )

    Write-Host ""
    Write-Host "  [4/6] Microsoft Office kuruluyor..."

    if (-not (Test-InstallerExists -Path $SourcePath -Label "Office Setup.exe")) {
        Write-StatusWarn "Office Cevrimdisi klasoru ve Setup.exe'nin varligini kontrol edin."
        return $false
    }

    Write-Host "         Dosya: $SourcePath"
    Write-Host "         Office kurulumu baslatiliyor, lutfen ekrandaki adimlari takip edin..."
    Write-Host "         (Bu islem birkac dakika surebilir)"
    $process = Start-Process -FilePath $SourcePath -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-StatusOk "Office kurulumu tamamlandi."
        Write-InstallLog "[OK] Microsoft Office kuruldu."
        return $true
    }
    else {
        Write-StatusWarn "Office kurulumu tamamlandi (hata kodu: $($process.ExitCode))."
        Write-InstallLog "[UYARI] Office kurulumu $($process.ExitCode) koduyla sonlandi."
        return $false
    }
}

<#
.SYNOPSIS
    Installs enVision.Client.Service with silent and fallback strategies.
.DESCRIPTION
    Attempts two silent install strategies from config.json.
    If both fail, falls back to interactive installation.
    Exit codes are inspected at every stage.
.PARAMETER SourcePath
    Full path to the enVision installer.
.PARAMETER SilentArgs1
    First silent install argument string (e.g., "/quiet /norestart").
.PARAMETER SilentArgs2
    Second silent install argument string (e.g., "/S").
.PARAMETER RelPath
    Human-readable relative path for warning messages.
.EXAMPLE
    Install-Envision -SourcePath "D:\Kbu\enVision.Client.Service.exe" -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S"
#>
function Install-Envision {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SilentArgs1,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SilentArgs2,

        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [1/2] enVision.Client.Service kuruluyor..."

    $label = if ($RelPath) { $RelPath } else { "enVision.Client.Service.exe" }
    if (-not (Test-InstallerExists -Path $SourcePath -Label $label)) {
        return $false
    }

    Write-Host "         Dosya: $SourcePath"
    Write-Host "         Kurulum calistiriliyor, lutfen bekleyin..."

    $proc1 = Start-Process -FilePath $SourcePath -ArgumentList $SilentArgs1 -Wait -NoNewWindow -PassThru
    if ($proc1.ExitCode -eq 0) {
        Write-StatusOk "enVision.Client.Service basariyla kuruldu."
        Write-InstallLog "[OK] enVision.Client.Service kuruldu."
        return $true
    }

    $proc2 = Start-Process -FilePath $SourcePath -ArgumentList $SilentArgs2 -Wait -NoNewWindow -PassThru
    if ($proc2.ExitCode -eq 0) {
        Write-StatusOk "enVision.Client.Service basariyla kuruldu."
        Write-InstallLog "[OK] enVision.Client.Service kuruldu."
        return $true
    }

    Write-Host "         Sessiz kurulum basarisiz, etkilesimli deneniyor..."
    $proc3 = Start-Process -FilePath $SourcePath -Wait -PassThru
    if ($proc3.ExitCode -eq 0) {
        Write-StatusOk "enVision.Client.Service etkilesimli olarak kuruldu."
        Write-InstallLog "[OK] enVision.Client.Service etkilesimli kuruldu."
        return $true
    }
    else {
        Write-StatusError "enVision.Client.Service kurulumu basarisiz oldu! (exit code: $($proc3.ExitCode))"
        Write-InstallLog "[HATA] enVision kurulumu $($proc3.ExitCode) koduyla basarisiz oldu."
        return $false
    }
}

<#
.SYNOPSIS
    Installs Ninite package bundle (Chrome, Firefox, Foxit, GOM Player).
.DESCRIPTION
    Verifies the Ninite installer exists, then runs it interactively.
    Inspects the exit code and logs the result.
.PARAMETER SourcePath
    Full path to the Ninite installer executable.
.EXAMPLE
    Install-Ninite -SourcePath "D:\Kbu\Ninite Chrome Firefox Foxit Reader GOM Installer.exe"
#>
function Install-Ninite {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath
    )

    Write-Host ""
    Write-Host "  [2/2] Ninite paketleri kuruluyor (Chrome, Firefox, Foxit Reader, GOM)..."

    if (-not (Test-InstallerExists -Path $SourcePath -Label "Ninite Installer")) {
        return $false
    }

    Write-Host "         Dosya: $SourcePath"
    Write-Host "         Ninite calistiriliyor, lutfen bekleyin..."
    $process = Start-Process -FilePath $SourcePath -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-StatusOk "Ninite paketleri basariyla kuruldu."
        Write-InstallLog "[OK] Ninite paketleri (Chrome, Firefox, Foxit, GOM) kuruldu."
        return $true
    }
    else {
        Write-StatusWarn "Ninite kurulumu tamamlandi (hata kodu: $($process.ExitCode))."
        Write-InstallLog "[UYARI] Ninite $($process.ExitCode) koduyla sonlandi."
        return $false
    }
}
