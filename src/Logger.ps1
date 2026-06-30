# =============================================================================
#  Logger.ps1
#  Logging and status output module.
#  Provides file logging and coloured console status messages.
# =============================================================================

$script:LogFilePath = $null

<#
.SYNOPSIS
    Sets the global log file path for this session.
.DESCRIPTION
    Stores the log file path in a script-scoped variable.
    All subsequent Write-InstallLog calls write to this file.
.PARAMETER Path
    Full path to the log file (e.g., C:\Users\...\Desktop\kurulum_log.txt).
.EXAMPLE
    Set-LogPath -Path "C:\Users\Admin\Desktop\kurulum_log.txt"
#>
function Set-LogPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $script:LogFilePath = $Path
}

<#
.SYNOPSIS
    Appends a message to the installation log file.
.DESCRIPTION
    Writes a line of text to the log file configured by Set-LogPath.
    Uses UTF-8 encoding. Silently skips if no log path is set.
.PARAMETER Message
    The text to append.
.EXAMPLE
    Write-InstallLog "[OK] AnyDesk kopyalandi."
#>
function Write-InstallLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    if ($script:LogFilePath) {
        $Message | Out-File -FilePath $script:LogFilePath -Append -Encoding UTF8
    }
}

<#
.SYNOPSIS
    Writes a green success message to the console.
.PARAMETER Message
    The success text to display.
.EXAMPLE
    Write-StatusOk "Java JRE kuruldu."
#>
function Write-StatusOk {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [√] $Message" -ForegroundColor Green
}

<#
.SYNOPSIS
    Writes a red error message to the console.
.PARAMETER Message
    The error text to display.
.EXAMPLE
    Write-StatusError "config.json bulunamadi!"
#>
function Write-StatusError {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [X] $Message" -ForegroundColor Red
}

<#
.SYNOPSIS
    Writes a yellow warning message to the console.
.PARAMETER Message
    The warning text to display.
.EXAMPLE
    Write-StatusWarn "Java sessiz kurulum basarisiz."
#>
function Write-StatusWarn {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}
