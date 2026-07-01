# =============================================================================
#  TestConfig.ps1
#  Pester test helper — generates valid and invalid config.json payloads.
#  Used by deployment.tests.ps1 to create real config files in temp folders.
# =============================================================================

function New-TestConfig {
    param(
        [switch]$Minimal,
        [switch]$MissingVersion,
        [switch]$MissingPaths,
        [switch]$MissingLogging,
        [switch]$MissingKbuDirectory,
        [switch]$MissingAnyDesk
    )

    $cfg = @{
        version = "1.3.0"
        paths   = @{
            kbu_directory    = "Kbu"
            office_directory = "Office Cevrimdisi"
            anydesk          = "Kbu\\AnyDesk.exe"
            akia             = "Kbu\\Akia_windows-x64_6_7_6.exe"
            java             = "Kbu\\jre-8u411-windows-x64.exe"
            envision         = "Kbu\\enVision.Client.Service.exe"
            ninite           = "Kbu\\Ninite Chrome Firefox Foxit Reader GOM Installer.exe"
            office           = "Office Cevrimdisi\\Setup.exe"
        }
        logging = @{
            filename = "kurulum_log.txt"
            location = "desktop"
        }
        internet_check = @{ targets = @("8.8.8.8", "google.com"); timeout_ms = 3000 }
        app      = @{ title = "Test Tool"; name = "Test"; institution = "Test Uni";
                      date_format = "yyyy-MM-dd"; background_color = "Black"; foreground_color = "Green" }
        installers = @{
            java     = @{ silent_args_1 = "/s"; silent_args_2 = "INSTALL_SILENT=1" }
            envision = @{ silent_args_1 = "/quiet"; silent_args_2 = "/S" }
        }
        desktop = @{
            icons                = @{ "Bu PC" = "{TEST-1}"; "Denetim Masasi" = "{TEST-2}" }
            registry_path        = "HKCU:\\Software\\Test\\HideDesktopIcons\\NewStartPanel"
            explorer_wait_seconds = 1
        }
        timing  = @{ invalid_choice_wait_seconds = 1; exit_wait_seconds = 1 }
    }

    if ($MissingVersion)      { $cfg.Remove("version") }
    if ($MissingPaths)        { $cfg.Remove("paths") }
    if ($MissingLogging)      { $cfg.Remove("logging") }
    if ($MissingKbuDirectory) { $cfg.paths.Remove("kbu_directory") }
    if ($MissingAnyDesk)      { $cfg.paths.Remove("anydesk") }

    return $cfg | ConvertTo-Json -Depth 5
}

function New-TestConfigFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDir,

        [switch]$MissingVersion,
        [switch]$MissingPaths,
        [switch]$MissingLogging,
        [switch]$MissingKbuDirectory,
        [switch]$MissingAnyDesk,
        [switch]$InvalidJson
    )

    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
    $configPath = Join-Path $TargetDir "config.json"

    if ($InvalidJson) {
        Set-Content -Path $configPath -Value '{broken json: true,,}' -Encoding UTF8
    }
    else {
        $json = New-TestConfig -MissingVersion:$MissingVersion -MissingPaths:$MissingPaths `
            -MissingLogging:$MissingLogging -MissingKbuDirectory:$MissingKbuDirectory `
            -MissingAnyDesk:$MissingAnyDesk
        Set-Content -Path $configPath -Value $json -Encoding UTF8
    }
    return $configPath
}
