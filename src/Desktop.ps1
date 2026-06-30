# =============================================================================
#  Desktop.ps1
#  Desktop customization module.
#  Registry-based desktop icon toggling and Windows Explorer refresh.
#  All icon GUIDs, registry paths, and timing are config-driven
#  via config.json.
# =============================================================================

function Add-DesktopIcons {
    param(
        [PSCustomObject]$Icons,
        [string]$RegistryPath
    )

    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    foreach ($iconName in $Icons.PSObject.Properties.Name) {
        $guid = $Icons.$iconName
        Set-ItemProperty -Path $RegistryPath -Name $guid -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

function Refresh-Explorer {
    param(
        [int]$WaitSeconds = 2
    )

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $WaitSeconds
    Start-Process explorer
}
