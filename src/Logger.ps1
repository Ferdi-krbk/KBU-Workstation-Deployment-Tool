# =============================================================================
#  Logger.ps1
#  Logging and status output module.
#  Provides file logging and coloured console status messages.
# =============================================================================

$script:LogFilePath = $null

function Set-LogPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $script:LogFilePath = $Path
}

function Write-InstallLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    if ($script:LogFilePath) {
        $Message | Out-File -FilePath $script:LogFilePath -Append -Encoding UTF8
    }
}

function Write-StatusOk {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [√] $Message" -ForegroundColor Green
}

function Write-StatusError {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [X] $Message" -ForegroundColor Red
}

function Write-StatusWarn {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}
