# =============================================================================
#  Network.ps1
#  Internet connectivity check module.
#  Pings a list of targets (hostnames or IPs) provided by the caller.
#  Returns $true as soon as any target responds; $false if none do.
#  All targets and timeout values come from the central config object.
# =============================================================================

<#
.SYNOPSIS
    Tests internet connectivity by pinging a list of targets.
.DESCRIPTION
    Sends one ICMP echo request to each target in order.
    Returns $true on the first successful response.
    Returns $false only after every target has failed.
.PARAMETER Targets
    Array of hostnames or IP addresses to ping (from config.json internet_check.targets).
.PARAMETER TimeoutMs
    Per-target timeout in milliseconds (from config.json internet_check.timeout_ms).
.EXAMPLE
    $online = Test-InternetConnection -Targets @("8.8.8.8","google.com") -TimeoutMs 3000
.EXAMPLE
    if (-not (Test-InternetConnection -Targets $Cfg.NetTargets -TimeoutMs $Cfg.NetTimeoutMs)) {
        Write-StatusError "Internet yok!"
    }
#>
function Test-InternetConnection {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]$Targets,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 60000)]
        [int]$TimeoutMs
    )

    foreach ($target in $Targets) {
        $pingResult = Test-Connection -ComputerName $target -Count 1 -TimeoutMilliseconds $TimeoutMs -Quiet -ErrorAction SilentlyContinue
        if ($pingResult) {
            return $true
        }
    }
    return $false
}
