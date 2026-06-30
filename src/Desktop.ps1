# =============================================================================
#  Desktop.ps1
#  Desktop customization module.
#  Registry-based desktop icon toggling and Windows Explorer refresh.
#  All icon GUIDs, registry paths, and timing are config-driven
#  via config.json.
# =============================================================================

<#
.SYNOPSIS
    Shows or hides common desktop icons via registry.
.DESCRIPTION
    Writes DWORD value 0 (visible) to HideDesktopIcons registry keys
    for This PC, Control Panel, Network, and Recycle Bin.
    Icon GUIDs and registry path come from config.json.
    Failures are logged; individual icon failures do not abort the entire set.
.PARAMETER Icons
    PSCustomObject mapping icon names to CLSID GUIDs (from config.json desktop.icons).
.PARAMETER RegistryPath
    Full registry provider path (e.g., HKCU:\Software\...\NewStartPanel).
.EXAMPLE
    Add-DesktopIcons -Icons $Cfg.DesktopIcons -RegistryPath $Cfg.DesktopRegPath
#>
function Add-DesktopIcons {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Icons,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath
    )

    try {
        if (-not (Test-Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }
    }
    catch {
        Write-InstallLog "[HATA] Registry path olusturulamadi: $RegistryPath - $($_.Exception.Message)"
        Write-StatusError "Masaustu simgeleri icin registry yolu olusturulamadi!"
        return
    }

    foreach ($iconName in $Icons.PSObject.Properties.Name) {
        $guid = $Icons.$iconName
        try {
            Set-ItemProperty -Path $RegistryPath -Name $guid -Value 0 -Type DWord -Force -ErrorAction Stop
        }
        catch {
            Write-InstallLog "[UYARI] Registry yazma basarisiz - $iconName ($guid): $($_.Exception.Message)"
            Write-StatusWarn "$iconName simgesi eklenemedi!"
        }
    }
}

<#
.SYNOPSIS
    Restarts Windows Explorer to apply desktop changes.
.DESCRIPTION
    Stops the explorer.exe process, waits a configurable number of
    seconds, then starts it again. Errors are logged but not fatal.
.PARAMETER WaitSeconds
    Seconds to wait between stopping and starting explorer. Default 2.
.EXAMPLE
    Update-ExplorerShell -WaitSeconds 2
#>
function Update-ExplorerShell {
    param(
        [int]$WaitSeconds = 2
    )

    try {
        Stop-Process -Name explorer -Force -ErrorAction Stop
    }
    catch {
        Write-InstallLog "[UYARI] Explorer durdurulamadi: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $WaitSeconds

    try {
        Start-Process explorer -ErrorAction Stop
    }
    catch {
        Write-InstallLog "[HATA] Explorer yeniden baslatilamadi: $($_.Exception.Message)"
    }
}
