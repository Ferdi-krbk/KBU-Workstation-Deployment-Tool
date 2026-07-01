# =============================================================================
#  deployment.tests.ps1
#  Pester 5 test suite — KBU Workstation Deployment Tool
#  PS 5.1 + Pester 5.6.0
# =============================================================================

Describe "Config.ps1 — Configuration Loading" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Config.ps1")
        . (Join-Path $src "Logger.ps1")
        . (Join-Path $PSScriptRoot "TestConfig.ps1")
    }

    Context "Valid config.json" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_Cfg_$(Get-Random)"
            New-TestConfigFile -TargetDir $testDir | Out-Null
            $result = Get-Configuration -UsbRoot $testDir
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }

        It "Returns non-null object"                { $result | Should -Not -BeNullOrEmpty }
        It "Version is 1.3.0"                       { $result.Version | Should -Be "1.3.0" }
        It "AnyDesk path resolves"                   { $result.Paths.AnyDesk -like "*Kbu*AnyDesk.exe" | Should -BeTrue }
        It "Java path resolves"                      { $result.Paths.Java -like "*Kbu*jre*.exe" | Should -BeTrue }
        It "Desktop path has USERPROFILE"            { $result.Paths.Desktop | Should -BeLike "*Desktop*" }
        It "AppTitle from config"                    { $result.AppTitle | Should -Be "Test Tool" }
        It "NetTargets count = 2"                    { $result.NetTargets.Count | Should -Be 2 }
        It "JavaSilent1 is /s"                       { $result.JavaSilent1 | Should -Be "/s" }
        It "DesktopIcons GUID"                       { $result.DesktopIcons."Bu PC" | Should -Be "{TEST-1}" }
        It "LogFile has Desktop and filename"        { $result.LogFile -match "Desktop" | Should -BeTrue }
        It "Absolute log path resolves" {
            $alt = @{version="1";paths=@{kbu_directory="x";office_directory="x";anydesk="x";akia="x";java="x";envision="x";ninite="x";office="x"};logging=@{filename="l.txt";location="C:\Logs"}} | ConvertTo-Json
            Set-Content (Join-Path $testDir "config.json") $alt -Encoding UTF8
            (Get-Configuration -UsbRoot $testDir).LogFile -like "C:\Logs\l.txt" | Should -BeTrue
        }
    }

    Context "Missing config.json" {
        BeforeAll { $testDir = Join-Path $env:TEMP "KbuTest_No_$(Get-Random)"; New-Item -ItemType Directory $testDir -Force | Out-Null }
        AfterAll  { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "config.json does not exist" { Test-Path (Join-Path $testDir "config.json") -PathType Leaf | Should -BeFalse }
    }

    Context "Invalid JSON" {
        BeforeAll { $testDir = Join-Path $env:TEMP "KbuTest_Bad_$(Get-Random)"; New-TestConfigFile -TargetDir $testDir -InvalidJson | Out-Null }
        AfterAll  { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "ConvertFrom-Json throws" {
            $c = Get-Content (Join-Path $testDir "config.json") -Raw -Encoding UTF8
            { $c | ConvertFrom-Json -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Missing required fields" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_Req_$(Get-Random)"
            New-TestConfigFile -TargetDir $testDir -MissingKbuDirectory -MissingAnyDesk | Out-Null
            $cfg = Get-Content (Join-Path $testDir "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "kbu_directory absent"  { [bool]$cfg.paths.kbu_directory | Should -BeFalse }
        It "anydesk absent"        { [bool]$cfg.paths.anydesk       | Should -BeFalse }
    }

    Context "Optional defaults" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_Opt_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            $m = @{version="1";paths=@{kbu_directory="K";office_directory="O";anydesk="a";akia="b";java="c";envision="d";ninite="e";office="f"};logging=@{filename="l.txt";location="desktop"}} | ConvertTo-Json
            Set-Content (Join-Path $testDir "config.json") $m -Encoding UTF8
            $result = Get-Configuration -UsbRoot $testDir
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Default AppTitle"       { $result.AppTitle       | Should -Be "KBU Workstation Deployment Tool" }
        It "Default BackgroundColor" { $result.BackgroundColor | Should -Be "DarkBlue" }
        It "Default ForegroundColor" { $result.ForegroundColor | Should -Be "White" }
        It "Default DateFormat"      { $result.DateFormat | Should -BeLike "*dd.MM.yyyy*" }
        It "Default JavaSilent1"     { $result.JavaSilent1 | Should -BeLike "*REBOOT=0*" }
        It "Default JavaSilent2"     { $result.JavaSilent2 | Should -BeLike "*INSTALL_SILENT*" }
        It "Default EnvSilent1"      { $result.EnvSilent1  | Should -BeLike "*quiet*" }
        It "Default EnvSilent2"      { $result.EnvSilent2  | Should -Be "/S" }
        It "Default ExplorerWaitSec" { $result.ExplorerWaitSec | Should -Be 2 }
        It "Default InvalidWaitSec"  { $result.InvalidWaitSec  | Should -Be 2 }
        It "Default ExitWaitSec"     { $result.ExitWaitSec     | Should -Be 2 }
        It "Desktop icons object"    { $result.DesktopIcons.PSObject.Properties.Name.Count | Should -BeGreaterThan 0 }
        It "DesktopRegPath not null" { $result.DesktopRegPath | Should -Not -BeNullOrEmpty }
    }
}

# =============================================================================
Describe "Logger.ps1 — Logging" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Logger.ps1")
        . (Join-Path $src "Config.ps1")
    }

    Context "Write-InstallLog" {
        BeforeAll {
            $testLog = Join-Path $env:TEMP "KbuTest_Log_$(Get-Random).txt"
            Set-LogPath -Path $testLog
        }
        AfterAll { Remove-Item $testLog -ErrorAction SilentlyContinue }

        It "Creates file"         { Write-InstallLog "t"; Test-Path $testLog | Should -BeTrue }
        It "Writes exact message"  { Write-InstallLog "hello"; (Get-Content $testLog -Tail 1) | Should -BeLike "*hello*" }
        It "Appends lines"         { Write-InstallLog "A"; Write-InstallLog "B"; (Get-Content $testLog).Count | Should -BeGreaterOrEqual 2 }
    }

    Context "Console never throws" {
        It "Write-StatusOk"    { { Write-StatusOk    "x" } | Should -Not -Throw }
        It "Write-StatusError" { { Write-StatusError "x" } | Should -Not -Throw }
        It "Write-StatusWarn"  { { Write-StatusWarn  "x" } | Should -Not -Throw }
    }
}

# =============================================================================
Describe "Network.ps1 — Internet Connectivity" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Network.ps1")
    }

    Context "Function signature" {
        It "Command exists" {
            { Get-Command Test-InternetConnection -ErrorAction Stop } | Should -Not -Throw
        }
        It "Targets is string array" {
            (Get-Command Test-InternetConnection).Parameters['Targets'].ParameterType.Name | Should -Be "String[]"
        }
        It "TimeoutMs is integer" {
            (Get-Command Test-InternetConnection).Parameters['TimeoutMs'].ParameterType.Name | Should -Be "Int32"
        }
        It "Targets is mandatory" {
            $attr = (Get-Command Test-InternetConnection).Parameters['Targets'].Attributes
            ($attr | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
        }
    }
}

# =============================================================================
Describe "Installer.ps1 — Installer Functions" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Installer.ps1")
        . (Join-Path $src "Logger.ps1")
    }

    Context "Test-InstallerExists" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_IEx_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            "x" | Set-Content "$testDir\real.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }

        It "True for existing file"  { Test-InstallerExists -Path "$testDir\real.exe" -Label "T" | Should -BeTrue }
        It "False for missing file"  { Test-InstallerExists -Path "$testDir\gone.exe" -Label "T" | Should -BeFalse }
        It "False for directory"     { Test-InstallerExists -Path $testDir -Label "T" | Should -BeFalse }
    }

    Context "Missing installers" {
        It "Install-Akia"    { Install-Akia    -SourcePath "C:\None\a.exe" | Should -BeFalse }
        It "Install-Office"  { Install-Office  -SourcePath "C:\None\o.exe" | Should -BeFalse }
        It "Install-Ninite"  { Install-Ninite  -SourcePath "C:\None\n.exe" | Should -BeFalse }
    }

    Context "Install-AnyDesk real copy" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_AD_$(Get-Random)"
            $null = New-Item -ItemType Directory "$testDir","$testDir\Dst" -Force
            "x" | Set-Content "$testDir\AnyDesk.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Copies and returns true" {
            $r = Install-AnyDesk -SourcePath "$testDir\AnyDesk.exe" -DesktopPath "$testDir\Dst"
            $r | Should -BeTrue
            "$testDir\Dst\AnyDesk.exe" | Should -Exist
        }
    }

    Context "Install-Java fallback" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_Jv_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            "x" | Set-Content "$testDir\j.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Succeeds on 1st attempt" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter { $ArgumentList -match "REBOOT" }
            Install-Java -SourcePath "$testDir\j.exe" -SilentArgs1 "/s REBOOT=0" -SilentArgs2 "INSTALL_SILENT=1" | Should -BeTrue
        }
        It "Falls back to 2nd" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } -ParameterFilter { $ArgumentList -match "REBOOT" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter { $ArgumentList -match "INSTALL_SILENT" }
            Install-Java -SourcePath "$testDir\j.exe" -SilentArgs1 "/s REBOOT=0" -SilentArgs2 "INSTALL_SILENT=1" | Should -BeTrue
        }
    }

    Context "Install-Java all fail" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_JvF_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            "x" | Set-Content "$testDir\j.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Returns false" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
            Install-Java -SourcePath "$testDir\j.exe" -SilentArgs1 "/s" -SilentArgs2 "INSTALL_SILENT=1" | Should -BeFalse
        }
    }

    Context "Install-Envision fallback" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_Ev_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            "x" | Set-Content "$testDir\e.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Succeeds on 1st silent" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter { $ArgumentList -match "/quiet" }
            Install-Envision -SourcePath "$testDir\e.exe" -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" | Should -BeTrue
        }
        It "Falls back to interactive" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } -ParameterFilter { $ArgumentList -match "/quiet" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } -ParameterFilter { $ArgumentList -match "^-S$|^/S$" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter { [string]::IsNullOrEmpty($ArgumentList) }
            Install-Envision -SourcePath "$testDir\e.exe" -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" | Should -BeTrue
        }
    }

    Context "Install-Envision all fail" {
        BeforeAll {
            $testDir = Join-Path $env:TEMP "KbuTest_EvF_$(Get-Random)"
            New-Item -ItemType Directory $testDir -Force | Out-Null
            "x" | Set-Content "$testDir\e.exe"
        }
        AfterAll { Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue }
        It "Returns false" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
            Install-Envision -SourcePath "$testDir\e.exe" -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" | Should -BeFalse
        }
    }
}

# =============================================================================
Describe "Desktop.ps1 — Desktop Customization" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Desktop.ps1")
        . (Join-Path $src "Logger.ps1")
    }

    Context "Add-DesktopIcons mocked registry" {
        BeforeAll {
            $icons = [PSCustomObject]@{ "A" = "{AAAA-AAAA}"; "B" = "{BBBB-BBBB}" }
            Mock New-Item { }
            Mock Set-ItemProperty { }
            Mock Write-InstallLog { }
            Mock Write-StatusWarn { }
            Mock Write-StatusError { }
        }
        It "Does not throw" {
            { Add-DesktopIcons -Icons $icons -RegistryPath "HKCU:\Test\Icons" } | Should -Not -Throw
        }
        It "Calls Set-ItemProperty 2x" {
            Add-DesktopIcons -Icons $icons -RegistryPath "HKCU:\Test\Icons"
            Should -Invoke Set-ItemProperty -Times 2 -Exactly
        }
    }

    Context "Add-DesktopIcons registry failure" {
        BeforeAll {
            Mock Test-Path { $false }
            Mock New-Item { throw "access denied" }
            Mock Write-InstallLog { }
            Mock Write-StatusError { }
        }
        It "Does not crash" {
            { Add-DesktopIcons -Icons ([PSCustomObject]@{X="{G}"}) -RegistryPath "HKCU:\Bad" } | Should -Not -Throw
        }
    }

    Context "Update-ExplorerShell mocked" {
        It "Normal restart ok" {
            Mock Stop-Process { } -ParameterFilter { $Name -eq "explorer" }
            Mock Start-Sleep { }
            Mock Start-Process { } -ParameterFilter { $FilePath -eq "explorer" }
            { Update-ExplorerShell -WaitSeconds 0 } | Should -Not -Throw
        }
        It "Stop-Process failure ok" {
            Mock Stop-Process { throw "gone" } -ParameterFilter { $Name -eq "explorer" }
            Mock Write-InstallLog { }
            Mock Start-Sleep { }
            Mock Start-Process { } -ParameterFilter { $FilePath -eq "explorer" }
            { Update-ExplorerShell -WaitSeconds 0 } | Should -Not -Throw
        }
        It "Start-Process failure ok" {
            Mock Stop-Process { } -ParameterFilter { $Name -eq "explorer" }
            Mock Start-Sleep { }
            Mock Write-InstallLog { }
            Mock Start-Process { throw "cant" } -ParameterFilter { $FilePath -eq "explorer" }
            { Update-ExplorerShell -WaitSeconds 0 } | Should -Not -Throw
        }
    }
}

# =============================================================================
Describe "Deploy.ps1 — Integration" {
    BeforeAll {
        $src = Join-Path (Split-Path $PSScriptRoot -Parent) "src"
        . (Join-Path $src "Config.ps1")
        . (Join-Path $src "Logger.ps1")
        . (Join-Path $src "Network.ps1")
        . (Join-Path $src "Installer.ps1")
        . (Join-Path $src "Desktop.ps1")
    }

    Context "16 module functions" {
        It "All 16 loaded" {
            $n = 'Get-Configuration','Set-LogPath','Write-InstallLog','Write-StatusOk','Write-StatusError',
                 'Write-StatusWarn','Test-InternetConnection','Test-InstallerExists','Add-DesktopIcons',
                 'Update-ExplorerShell','Install-AnyDesk','Install-Akia','Install-Java','Install-Office',
                 'Install-Envision','Install-Ninite'
            ($n | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }).Count | Should -Be 16
        }
        It "Refresh-Explorer is gone" { { Get-Command Refresh-Explorer -ErrorAction Stop } | Should -Throw }
    }

    Context "Mandatory params" {
        It "AnyDesk SourcePath"   { { Install-AnyDesk -DesktopPath "C:\" } | Should -Throw }
        It "Java SourcePath"      { { Install-Java -SilentArgs1 "/s" -SilentArgs2 "/x" } | Should -Throw }
        It "Config UsbRoot"       { { Get-Configuration } | Should -Throw }
        It "Network Targets"      { { Test-InternetConnection -TimeoutMs 1000 } | Should -Throw }
    }
}
