# =============================================================================
#  Network.ps1
#  Internet connectivity check module.
#  Pings a list of targets (hostnames or IPs) provided by the caller.
#  Returns $true as soon as any target responds; $false if none do.
#  All targets and timeout values come from the central config object.
# =============================================================================

function Test-InternetConnection {
    param(
        [string[]]$Targets,
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
