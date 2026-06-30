# =============================================================================
#  Installer.ps1
#  Software installation module.
#  Each function receives source paths from the central config object.
#  Silent-install arguments are also config-driven (config.json).
#  Every installer checks file existence, runs the installer with
#  appropriate arguments, handles fallbacks, and logs results.
# =============================================================================

function Install-AnyDesk {
    param(
        [string]$SourcePath,
        [string]$DesktopPath
    )

    Write-Host "  [1/6] AnyDesk masaustune kopyalaniyor..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        Write-StatusWarn "AnyDesk.exe bulunamadi! Atlaniyor..."
        Write-InstallLog "[UYARI] AnyDesk.exe bulunamadi: $SourcePath"
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

function Install-Akia {
    param(
        [string]$SourcePath,
        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [2/6] Akia kuruluyor..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        if ($RelPath) { Write-StatusWarn "$RelPath bulunamadi! Atlaniyor..." }
        else          { Write-StatusWarn "Akia installer bulunamadi! Atlaniyor..." }
        Write-InstallLog "[UYARI] Akia dosyasi bulunamadi: $SourcePath"
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

function Install-Java {
    param(
        [string]$SourcePath,
        [string]$SilentArgs1,
        [string]$SilentArgs2,
        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [3/6] Java JRE sessiz kuruluyor..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        if ($RelPath) { Write-StatusWarn "$RelPath bulunamadi! Atlaniyor..." }
        else          { Write-StatusWarn "Java JRE installer bulunamadi! Atlaniyor..." }
        Write-InstallLog "[UYARI] Java JRE dosyasi bulunamadi: $SourcePath"
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
    Start-Process -FilePath $SourcePath -Wait
    Write-InstallLog "[BILGI] Java etkilesimli kurulum tamamlandi."
    return $true
}

function Install-Office {
    param(
        [string]$SourcePath
    )

    Write-Host ""
    Write-Host "  [4/6] Microsoft Office kuruluyor..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        Write-StatusWarn "Office\Setup.exe bulunamadi! Yol: $SourcePath"
        Write-StatusWarn "Office Cevrimdisi klasoru ve Setup.exe'nin varligini kontrol edin."
        Write-InstallLog "[UYARI] Office Setup.exe bulunamadi: $SourcePath"
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

function Install-Envision {
    param(
        [string]$SourcePath,
        [string]$SilentArgs1,
        [string]$SilentArgs2,
        [string]$RelPath = ""
    )

    Write-Host ""
    Write-Host "  [1/2] enVision.Client.Service kuruluyor..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        if ($RelPath) { Write-StatusWarn "$RelPath bulunamadi! Atlaniyor..." }
        else          { Write-StatusWarn "enVision.Client.Service.exe bulunamadi! Atlaniyor..." }
        Write-InstallLog "[UYARI] enVision dosyasi bulunamadi: $SourcePath"
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
    Start-Process -FilePath $SourcePath -Wait
    Write-StatusWarn "enVision.Client.Service etkilesimli olarak calistirildi."
    Write-InstallLog "[UYARI] enVision sessiz kurulamadi, etkilesimli calistirildi."
    return $true
}

function Install-Ninite {
    param(
        [string]$SourcePath
    )

    Write-Host ""
    Write-Host "  [2/2] Ninite paketleri kuruluyor (Chrome, Firefox, Foxit Reader, GOM)..."

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        Write-StatusWarn "Ninite Installer bulunamadi! Atlaniyor..."
        Write-InstallLog "[UYARI] Ninite dosyasi bulunamadi: $SourcePath"
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
