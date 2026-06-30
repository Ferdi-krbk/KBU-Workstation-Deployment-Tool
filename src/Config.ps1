# =============================================================================
#  Config.ps1
#  Configuration loading and validation module.
#  Reads config.json from USB root, validates required fields,
#  resolves full paths, applies defaults, and returns a
#  structured config object consumed by all other modules.
# =============================================================================

function Get-Configuration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UsbRoot
    )

    $configPath = Join-Path $UsbRoot "config.json"
    $fallbackLog = Join-Path $env:USERPROFILE "Desktop\kurulum_log.txt"

    # ----- 1. File existence -----
    if (-not (Test-Path $configPath -PathType Leaf)) {
        Write-Host ""
        Write-Host "  [X] config.json bulunamadi!" -ForegroundColor Red
        Write-Host ""
        Write-Host "      Beklenen konum: $configPath"
        Write-Host "      Lutfen USB bellekte config.json dosyasinin oldugundan emin olun."
        Write-Host ""
        Write-Host "      USB Klasor Yapisi:"
        Write-Host "        USB_ROOT"
        Write-Host "        +-- deploy.bat"
        Write-Host "        +-- config.json"
        Write-Host "        +-- Kbu"
        Write-Host "        +-- Office Cevrimdisi"
        Write-Host ""
        "[HATA] config.json bulunamadi: $configPath" | Out-File -FilePath $fallbackLog -Append -Encoding UTF8
        Read-Host "Devam etmek icin bir tusa basin"
        exit 1
    }

    # ----- 2. Parse JSON -----
    try {
        $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "  [X] config.json gecersiz!" -ForegroundColor Red
        Write-Host ""
        Write-Host "      Hata: $($_.Exception.Message)"
        Write-Host "      Lutfen config.json dosyasini kontrol edin."
        Write-Host ""
        "[HATA] config.json gecersiz: $($_.Exception.Message)" | Out-File -FilePath $fallbackLog -Append -Encoding UTF8
        Read-Host "Devam etmek icin bir tusa basin"
        exit 1
    }

    # ----- 3. Validate required top-level sections -----
    $errors = @()
    if (-not $cfg.version) { $errors += "version is required" }
    if (-not $cfg.paths)   { $errors += "paths is required" }
    if (-not $cfg.logging) { $errors += "logging is required" }

    if ($cfg.paths) {
        if (-not $cfg.paths.kbu_directory)    { $errors += "paths.kbu_directory is required" }
        if (-not $cfg.paths.office_directory) { $errors += "paths.office_directory is required" }
        if (-not $cfg.paths.anydesk)          { $errors += "paths.anydesk is required" }
        if (-not $cfg.paths.akia)             { $errors += "paths.akia is required" }
        if (-not $cfg.paths.java)             { $errors += "paths.java is required" }
        if (-not $cfg.paths.envision)         { $errors += "paths.envision is required" }
        if (-not $cfg.paths.ninite)           { $errors += "paths.ninite is required" }
        if (-not $cfg.paths.office)           { $errors += "paths.office is required" }
    }

    if ($cfg.logging) {
        if (-not $cfg.logging.filename) { $errors += "logging.filename is required" }
        if (-not $cfg.logging.location) { $errors += "logging.location is required" }
    }

    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "  [X] config.json yuklenemedi! Gerekli alanlar eksik:" -ForegroundColor Red
        Write-Host ""
        foreach ($err in $errors) {
            Write-Host "      - $err"
        }
        Write-Host ""
        Write-Host "      Lutfen config.json dosyasini kontrol edin."
        Write-Host ""
        "[HATA] config.json yuklenemedi - gerekli alanlar eksik: $($errors -join '; ')" | Out-File -FilePath $fallbackLog -Append -Encoding UTF8
        Read-Host "Devam etmek icin bir tusa basin"
        exit 1
    }

    # =========================================================================
    #  4. Apply defaults for optional sections
    #  Default objects are built as variables first to avoid PowerShell parser
    #  issues with inline [PSCustomObject]@{...} inside function calls.
    # =========================================================================

    # --- app ---
    if (-not $cfg.app) {
        $appDef = [PSCustomObject]@{
            title            = 'KBU Workstation Deployment Tool'
            name             = 'KBU Workstation Deployment Tool'
            institution      = 'Karabuk Universitesi - Bilgi Islem Daire Baskanligi'
            date_format      = 'dd.MM.yyyy - HH:mm:ss'
            background_color = 'DarkBlue'
            foreground_color = 'White'
        }
        $cfg | Add-Member -MemberType NoteProperty -Name 'app' -Value $appDef -Force
    }
    else {
        $appProps = @{
            title            = 'KBU Workstation Deployment Tool'
            name             = 'KBU Workstation Deployment Tool'
            institution      = 'Karabuk Universitesi - Bilgi Islem Daire Baskanligi'
            date_format      = 'dd.MM.yyyy - HH:mm:ss'
            background_color = 'DarkBlue'
            foreground_color = 'White'
        }
        foreach ($prop in $appProps.GetEnumerator()) {
            if (-not (Get-Member -InputObject $cfg.app -Name $prop.Key -MemberType NoteProperty)) {
                $cfg.app | Add-Member -MemberType NoteProperty -Name $prop.Key -Value $prop.Value -Force
            }
        }
    }

    # --- internet_check ---
    if (-not $cfg.internet_check) {
        $inetDef = [PSCustomObject]@{ targets = @('8.8.8.8', 'google.com', '1.1.1.1'); timeout_ms = 3000 }
        $cfg | Add-Member -MemberType NoteProperty -Name 'internet_check' -Value $inetDef -Force
    }
    else {
        if (-not (Get-Member -InputObject $cfg.internet_check -Name 'targets' -MemberType NoteProperty))    { $cfg.internet_check | Add-Member -MemberType NoteProperty -Name 'targets'    -Value @('8.8.8.8', 'google.com', '1.1.1.1') -Force }
        if (-not (Get-Member -InputObject $cfg.internet_check -Name 'timeout_ms' -MemberType NoteProperty)) { $cfg.internet_check | Add-Member -MemberType NoteProperty -Name 'timeout_ms' -Value 3000 -Force }
    }

    # --- installers ---
    $javaArgs1 = '/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H'
    $javaArgs2 = 'INSTALL_SILENT=1 REBOOT=Suppress'
    $envArgs1  = '/quiet /norestart'
    $envArgs2  = '/S'

    if (-not $cfg.installers) {
        $javaDef = [PSCustomObject]@{ silent_args_1 = $javaArgs1; silent_args_2 = $javaArgs2 }
        $envDef  = [PSCustomObject]@{ silent_args_1 = $envArgs1;  silent_args_2 = $envArgs2 }
        $instDef = [PSCustomObject]@{ java = $javaDef; envision = $envDef }
        $cfg | Add-Member -MemberType NoteProperty -Name 'installers' -Value $instDef -Force
    }
    else {
        if (-not (Get-Member -InputObject $cfg.installers -Name 'java' -MemberType NoteProperty)) {
            $javaDef = [PSCustomObject]@{ silent_args_1 = $javaArgs1; silent_args_2 = $javaArgs2 }
            $cfg.installers | Add-Member -MemberType NoteProperty -Name 'java' -Value $javaDef -Force
        }
        else {
            if (-not (Get-Member -InputObject $cfg.installers.java -Name 'silent_args_1' -MemberType NoteProperty)) { $cfg.installers.java | Add-Member -MemberType NoteProperty -Name 'silent_args_1' -Value $javaArgs1 -Force }
            if (-not (Get-Member -InputObject $cfg.installers.java -Name 'silent_args_2' -MemberType NoteProperty)) { $cfg.installers.java | Add-Member -MemberType NoteProperty -Name 'silent_args_2' -Value $javaArgs2 -Force }
        }
        if (-not (Get-Member -InputObject $cfg.installers -Name 'envision' -MemberType NoteProperty)) {
            $envDef = [PSCustomObject]@{ silent_args_1 = $envArgs1; silent_args_2 = $envArgs2 }
            $cfg.installers | Add-Member -MemberType NoteProperty -Name 'envision' -Value $envDef -Force
        }
        else {
            if (-not (Get-Member -InputObject $cfg.installers.envision -Name 'silent_args_1' -MemberType NoteProperty)) { $cfg.installers.envision | Add-Member -MemberType NoteProperty -Name 'silent_args_1' -Value $envArgs1 -Force }
            if (-not (Get-Member -InputObject $cfg.installers.envision -Name 'silent_args_2' -MemberType NoteProperty)) { $cfg.installers.envision | Add-Member -MemberType NoteProperty -Name 'silent_args_2' -Value $envArgs2 -Force }
        }
    }

    # --- desktop ---
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
    $iconGuidPC      = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    $iconGuidControl = '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}'
    $iconGuidNetwork = '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'
    $iconGuidRecycle = '{645FF040-5081-101B-9F08-00AA002F954E}'

    if (-not $cfg.desktop) {
        $iconsDef = [PSCustomObject]@{
            'Bu PC'               = $iconGuidPC
            'Denetim Masasi'      = $iconGuidControl
            'Ag'                  = $iconGuidNetwork
            'Geri Donusum Kutusu' = $iconGuidRecycle
        }
        $desktopDef = [PSCustomObject]@{ icons = $iconsDef; registry_path = $regPath; explorer_wait_seconds = 2 }
        $cfg | Add-Member -MemberType NoteProperty -Name 'desktop' -Value $desktopDef -Force
    }
    else {
        if (-not (Get-Member -InputObject $cfg.desktop -Name 'icons' -MemberType NoteProperty)) {
            $iconsDef = [PSCustomObject]@{
                'Bu PC'               = $iconGuidPC
                'Denetim Masasi'      = $iconGuidControl
                'Ag'                  = $iconGuidNetwork
                'Geri Donusum Kutusu' = $iconGuidRecycle
            }
            $cfg.desktop | Add-Member -MemberType NoteProperty -Name 'icons' -Value $iconsDef -Force
        }
        if (-not (Get-Member -InputObject $cfg.desktop -Name 'registry_path' -MemberType NoteProperty))        { $cfg.desktop | Add-Member -MemberType NoteProperty -Name 'registry_path'        -Value $regPath -Force }
        if (-not (Get-Member -InputObject $cfg.desktop -Name 'explorer_wait_seconds' -MemberType NoteProperty)) { $cfg.desktop | Add-Member -MemberType NoteProperty -Name 'explorer_wait_seconds' -Value 2 -Force }
    }

    # --- timing ---
    if (-not $cfg.timing) {
        $timingDef = [PSCustomObject]@{ invalid_choice_wait_seconds = 2; exit_wait_seconds = 2 }
        $cfg | Add-Member -MemberType NoteProperty -Name 'timing' -Value $timingDef -Force
    }
    else {
        if (-not (Get-Member -InputObject $cfg.timing -Name 'invalid_choice_wait_seconds' -MemberType NoteProperty)) { $cfg.timing | Add-Member -MemberType NoteProperty -Name 'invalid_choice_wait_seconds' -Value 2 -Force }
        if (-not (Get-Member -InputObject $cfg.timing -Name 'exit_wait_seconds' -MemberType NoteProperty))           { $cfg.timing | Add-Member -MemberType NoteProperty -Name 'exit_wait_seconds'           -Value 2 -Force }
    }

    # ----- 5. Build resolved full paths -----
    $paths = [PSCustomObject]@{
        UsbRoot     = $UsbRoot
        KbuDir      = Join-Path $UsbRoot $cfg.paths.kbu_directory
        OfficeDir   = Join-Path $UsbRoot $cfg.paths.office_directory
        AnyDesk     = Join-Path $UsbRoot $cfg.paths.anydesk
        Akia        = Join-Path $UsbRoot $cfg.paths.akia
        Java        = Join-Path $UsbRoot $cfg.paths.java
        Envision    = Join-Path $UsbRoot $cfg.paths.envision
        Ninite      = Join-Path $UsbRoot $cfg.paths.ninite
        OfficeSetup = Join-Path $UsbRoot $cfg.paths.office
        Desktop     = Join-Path $env:USERPROFILE "Desktop"
    }

    # ----- 6. Resolve log path -----
    if ($cfg.logging.location -eq "desktop") {
        $logSubDir = Join-Path $env:USERPROFILE "Desktop"
        $logPath   = Join-Path $logSubDir $cfg.logging.filename
    }
    elseif ($cfg.logging.location -match '^[A-Za-z]:\\') {
        $logPath = Join-Path $cfg.logging.location $cfg.logging.filename
    }
    else {
        $logSubDir = Join-Path $UsbRoot $cfg.logging.location
        $logPath   = Join-Path $logSubDir $cfg.logging.filename
    }

    # ----- 7. Return structured config object -----
    return [PSCustomObject]@{
        Version         = $cfg.version
        Paths           = $paths
        LogFile         = $logPath
        AppTitle        = $cfg.app.title
        AppName         = $cfg.app.name
        Institution     = $cfg.app.institution
        DateFormat      = $cfg.app.date_format
        BackgroundColor = $cfg.app.background_color
        ForegroundColor = $cfg.app.foreground_color
        NetTargets      = $cfg.internet_check.targets
        NetTimeoutMs    = $cfg.internet_check.timeout_ms
        JavaSilent1     = $cfg.installers.java.silent_args_1
        JavaSilent2     = $cfg.installers.java.silent_args_2
        EnvSilent1      = $cfg.installers.envision.silent_args_1
        EnvSilent2      = $cfg.installers.envision.silent_args_2
        DesktopIcons    = $cfg.desktop.icons
        DesktopRegPath  = $cfg.desktop.registry_path
        ExplorerWaitSec = $cfg.desktop.explorer_wait_seconds
        InvalidWaitSec  = $cfg.timing.invalid_choice_wait_seconds
        ExitWaitSec     = $cfg.timing.exit_wait_seconds
        RawPaths        = [PSCustomObject]@{
            KbuDirName    = $cfg.paths.kbu_directory
            OfficeDirName = $cfg.paths.office_directory
            AnyDeskRel    = $cfg.paths.anydesk
            AkiaRel       = $cfg.paths.akia
            JavaRel       = $cfg.paths.java
            EnvisionRel   = $cfg.paths.envision
            NiniteRel     = $cfg.paths.ninite
            OfficeRel     = $cfg.paths.office
            LogFilename   = $cfg.logging.filename
            LogLocation   = $cfg.logging.location
        }
    }
}
