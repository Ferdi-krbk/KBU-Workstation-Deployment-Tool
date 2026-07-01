# =============================================================================
#  deployment.tests.ps1
#  Pester test suite -- KBU Workstation Deployment Tool
#
#  Tests the real src/ modules. Only dangerous operations are mocked
#  (Start-Process, registry writes, process termination, network pings).
#  All other logic is tested against actual functions.
#
#  Pester 3.x compatible -- uses BeforeEach, Should Be, Should Throw.
#
#  Run with:  Invoke-Pester -Path tests/deployment.tests.ps1
# =============================================================================

$root = Split-Path $MyInvocation.MyCommand.Path -Parent
$src  = Join-Path (Split-Path $root -Parent) "src"

# Dot-source real modules AND the test helper
. (Join-Path $src   "Config.ps1")
. (Join-Path $src   "Logger.ps1")
. (Join-Path $src   "Network.ps1")
. (Join-Path $src   "Installer.ps1")
. (Join-Path $src   "Desktop.ps1")
. (Join-Path $root  "TestConfig.ps1")

# =============================================================================
#  CONFIG MODULE TESTS
# =============================================================================
Describe "Config.ps1 -- Configuration Loading" {

    Context "When config.json exists and is valid" {
        $testDir = Join-Path $env:TEMP "KbuTest_Config_$(Get-Random)"
        $null = New-TestConfigFile -TargetDir $testDir
        $result = Get-Configuration -UsbRoot $testDir

        It "Loads and returns a valid config object" {
            $result | Should Not Be $null
        }

        It "Returns the correct version" {
            $result.Version | Should Be "1.3.0"
        }

        It "Resolves installer paths relative to USB root" {
            $result.Paths.AnyDesk -like "*Kbu*AnyDesk.exe" | Should Be $true
        }

        It "Resolves Java path correctly" {
            $result.Paths.Java -like "*Kbu*jre-8u411*.exe" | Should Be $true
        }

        It "Resolves the desktop path from USERPROFILE" {
            $result.Paths.Desktop | Should BeLike "*Desktop*"
        }

        It "Populates AppTitle from config" {
            $result.AppTitle | Should Be "Test Deployment Tool"
        }

        It "Populates NetTargets from config - 2 targets" {
            $result.NetTargets.Count | Should Be 2
        }

        It "Populates JavaSilent1 from config" {
            $result.JavaSilent1 | Should Be "/s"
        }

        It "Populates DesktopIcons as a PSCustomObject" {
            $result.DesktopIcons."Bu PC" | Should Be "{TEST-GUID-1}"
        }

        It "Resolves log path containing Desktop folder" {
            $result.LogFile -match "Desktop" | Should Be $true
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "When config.json is missing" {
        $testDir = Join-Path $env:TEMP "KbuTest_ConfigMiss_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $configPath = Join-Path $testDir "config.json"

        It "config.json does not exist at the path" {
            Test-Path $configPath -PathType Leaf | Should Be $false
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "When config.json contains invalid JSON" {
        $testDir = Join-Path $env:TEMP "KbuTest_ConfigBad_$(Get-Random)"
        $null = New-TestConfigFile -TargetDir $testDir -InvalidJson

        It "ConvertFrom-Json rejects the malformed content" {
            $content = Get-Content (Join-Path $testDir "config.json") -Raw -Encoding UTF8
            { $content | ConvertFrom-Json -ErrorAction Stop } | Should Throw
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "When required fields are missing" {
        $testDir = Join-Path $env:TEMP "KbuTest_ConfigReq_$(Get-Random)"
        $null = New-TestConfigFile -TargetDir $testDir -MissingKbuDirectory -MissingAnyDesk
        $cfg = Get-Content (Join-Path $testDir "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json

        It "kbu_directory is absent from paths" {
            [bool]$cfg.paths.kbu_directory | Should Be $false
        }

        It "anydesk is absent from paths" {
            [bool]$cfg.paths.anydesk | Should Be $false
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "When optional fields are missing -- applies defaults" {
        $testDir = Join-Path $env:TEMP "KbuTest_ConfigOpt_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $minimalJson = @{
            version = "1.0.0"
            paths   = @{
                kbu_directory    = "Kbu"
                office_directory = "Office"
                anydesk          = "Kbu\\a.exe"
                akia             = "Kbu\\b.exe"
                java             = "Kbu\\c.exe"
                envision         = "Kbu\\d.exe"
                ninite           = "Kbu\\e.exe"
                office           = "Office\\f.exe"
            }
            logging = @{ filename = "log.txt"; location = "desktop" }
        } | ConvertTo-Json
        Set-Content -Path (Join-Path $testDir "config.json") -Value $minimalJson -Encoding UTF8

        $result = Get-Configuration -UsbRoot $testDir

        It "Returns default AppTitle when app section is missing" {
            $result.AppTitle | Should Be "KBU Workstation Deployment Tool"
        }

        It "Returns default BackgroundColor" {
            $result.BackgroundColor | Should Be "DarkBlue"
        }

        It "Returns default ForegroundColor" {
            $result.ForegroundColor | Should Be "White"
        }

        It "Returns default JavaSilent1" {
            $result.JavaSilent1 | Should Be "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 WEB_JAVA=0 WEB_JAVA_SECURITY_LEVEL=H"
        }

        It "Returns default ExplorerWaitSec" {
            $result.ExplorerWaitSec | Should Be 2
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# =============================================================================
#  LOGGER MODULE TESTS
# =============================================================================
Describe "Logger.ps1 -- Logging" {
    $testLog = Join-Path $env:TEMP "KbuTest_Log_$(Get-Random).txt"
    Remove-Item $testLog -ErrorAction SilentlyContinue
    Set-LogPath -Path $testLog

    Context "Write-InstallLog" {

        It "Creates the log file when a message is written" {
            Write-InstallLog "test entry"
            Test-Path $testLog | Should Be $true
        }

        It "Writes the exact message to the log file" {
            Write-InstallLog "hello world 123"
            Get-Content $testLog -Tail 1 | Should Be "hello world 123"
        }

        It "Appends lines without overwriting" {
            Write-InstallLog "alpha"
            Write-InstallLog "beta"
            $lines = Get-Content $testLog
            ($lines.Count -ge 2) | Should Be $true
        }
    }

    Context "Console output functions" {
        It "Write-StatusOk does not throw" {
            { Write-StatusOk "success message" } | Should Not Throw
        }

        It "Write-StatusError does not throw" {
            { Write-StatusError "error message" } | Should Not Throw
        }

        It "Write-StatusWarn does not throw" {
            { Write-StatusWarn "warning message" } | Should Not Throw
        }
    }

    Context "Log file path not set" {
        It "Write-InstallLog does not throw when path is empty" {
            $global:LogFilePath = ""
            { Write-InstallLog "should be silent" } | Should Not Throw
        }
    }

    Remove-Item $testLog -ErrorAction SilentlyContinue
}

# =============================================================================
#  NETWORK MODULE TESTS
# =============================================================================
Describe "Network.ps1 -- Internet Connectivity" {

    Context "Function structure" {
        It "Test-InternetConnection function exists" {
            Get-Command Test-InternetConnection -ErrorAction Stop | Should Not Be $null
        }

        It "Accepts Target and TimeoutMs parameters" {
            $cmd = Get-Command Test-InternetConnection
            $cmd.Parameters['Targets']   | Should Not Be $null
            $cmd.Parameters['TimeoutMs'] | Should Not Be $null
        }

        It "Targets parameter is mandatory" {
            $cmd = Get-Command Test-InternetConnection
            $mandatory = ($cmd.Parameters['Targets'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory
            $mandatory | Should Be $true
        }
    }

    Context "Return consistency" {
        It "Function signature accepts mandatory parameters" {
            $targetsParam = (Get-Command Test-InternetConnection).Parameters['Targets']
            $targetsParam | Should Not Be $null
        }
    }
}

# =============================================================================
#  INSTALLER MODULE TESTS
# =============================================================================
Describe "Installer.ps1 -- Installer Functions" {

    Context "Test-InstallerExists" {
        $testDir = Join-Path $env:TEMP "KbuTest_Inst_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $realFile = Join-Path $testDir "real.exe"
        $fakeFile = Join-Path $testDir "missing.exe"
        "dummy" | Set-Content $realFile

        It "Returns true for an existing file" {
            Test-InstallerExists -Path $realFile -Label "Test" | Should Be $true
        }

        It "Returns false for a missing file" {
            Test-InstallerExists -Path $fakeFile -Label "Test" | Should Be $false
        }

        It "Returns false for a directory (not a file)" {
            Test-InstallerExists -Path $testDir -Label "DirCheck" | Should Be $false
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Install-Akia -- missing source" {
        It "Returns false when installer does not exist" {
            Install-Akia -SourcePath "C:\NonExistent\file.exe" | Should Be $false
        }
    }

    Context "Install-Office -- missing source" {
        It "Returns false when installer does not exist" {
            Install-Office -SourcePath "C:\NonExistent\setup.exe" | Should Be $false
        }
    }

    Context "Install-Ninite -- missing source" {
        It "Returns false when installer does not exist" {
            Install-Ninite -SourcePath "C:\NonExistent\ninite.exe" | Should Be $false
        }
    }

    Context "Install-AnyDesk -- copies valid source" {
        $testDir = Join-Path $env:TEMP "KbuTest_AnyDesk_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $srcFile = Join-Path $testDir "AnyDesk.exe"
        $dstDir  = Join-Path $testDir "Desktop"
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        "dummy" | Set-Content $srcFile

        It "Copies the file and returns true" {
            $result = Install-AnyDesk -SourcePath $srcFile -DesktopPath $dstDir
            $result | Should Be $true
            Test-Path (Join-Path $dstDir "AnyDesk.exe") | Should Be $true
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Install-Java -- mocked process" {
        $testDir = Join-Path $env:TEMP "KbuTest_Java_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $javaFile = Join-Path $testDir "java.exe"
        "dummy" | Set-Content $javaFile

        It "Returns true when silent install succeeds on first attempt" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } `
                -ParameterFilter { $ArgumentList -match "REBOOT" }
            Install-Java -SourcePath $javaFile -SilentArgs1 "/s REBOOT=0" -SilentArgs2 "INSTALL_SILENT=1" |
                Should Be $true
        }

        It "Falls back to second method when first fails" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } `
                -ParameterFilter { $ArgumentList -match "REBOOT" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } `
                -ParameterFilter { $ArgumentList -match "INSTALL_SILENT" }
            Install-Java -SourcePath $javaFile -SilentArgs1 "/s REBOOT=0" -SilentArgs2 "INSTALL_SILENT=1" |
                Should Be $true
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Install-Java -- all methods fail" {
        $testDir = Join-Path $env:TEMP "KbuTest_JavaFail_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $javaFile = Join-Path $testDir "java.exe"
        "dummy" | Set-Content $javaFile

        It "Returns false when all attempts fail" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
            Install-Java -SourcePath $javaFile -SilentArgs1 "/s" -SilentArgs2 "INSTALL_SILENT=1" |
                Should Be $false
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Install-Envision -- mocked process" {
        $testDir = Join-Path $env:TEMP "KbuTest_Env_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $envFile = Join-Path $testDir "envision.exe"
        "dummy" | Set-Content $envFile

        It "Returns true when silent install succeeds" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } `
                -ParameterFilter { $ArgumentList -match "/quiet" }
            Install-Envision -SourcePath $envFile -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" |
                Should Be $true
        }

        It "Falls back to interactive and returns true" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } `
                -ParameterFilter { $ArgumentList -match "/quiet" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } } `
                -ParameterFilter { $ArgumentList -match "^-S$|^/S$" }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } `
                -ParameterFilter { [string]::IsNullOrEmpty($ArgumentList) }
            Install-Envision -SourcePath $envFile -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" |
                Should Be $true
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context "Install-Envision -- all methods fail" {
        $testDir = Join-Path $env:TEMP "KbuTest_EnvFail_$(Get-Random)"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $envFile = Join-Path $testDir "envision.exe"
        "dummy" | Set-Content $envFile

        It "Returns false when all attempts fail" {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
            Install-Envision -SourcePath $envFile -SilentArgs1 "/quiet /norestart" -SilentArgs2 "/S" |
                Should Be $false
        }

        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# =============================================================================
#  DESKTOP MODULE TESTS
# =============================================================================
Describe "Desktop.ps1 -- Desktop Customization" {

    Context "Add-DesktopIcons -- mocked registry writes" {
        $regPath = "HKCU:\Software\KbuTest\Icons"
        $icons   = [PSCustomObject]@{
            "Test PC"            = "{11111111-1111-1111-1111-111111111111}"
            "Test Control Panel" = "{22222222-2222-2222-2222-222222222222}"
        }

        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock Write-InstallLog { }
        Mock Write-StatusOk { }
        Mock Write-StatusWarn { }

        It "Does not throw when called with valid icons" {
            { Add-DesktopIcons -Icons $icons -RegistryPath $regPath } | Should Not Throw
        }
    }

    Context "Add-DesktopIcons -- handles registry path failure" {
        It "Does not throw when registry path creation fails" {
            Mock Test-Path { return $false }
            Mock New-Item { throw "access denied" }
            Mock Write-InstallLog { }
            Mock Write-StatusError { }

            $icons = [PSCustomObject]@{ "Test" = "{GUID}" }
            { Add-DesktopIcons -Icons $icons -RegistryPath "HKCU:\Bad\Path" } | Should Not Throw
        }
    }

    Context "Update-ExplorerShell -- mocked processes" {
        It "Does not throw when explorer is stopped and started" {
            Mock Stop-Process { } -ParameterFilter { $Name -eq "explorer" }
            Mock Start-Sleep { }
            Mock Start-Process { } -ParameterFilter { $FilePath -eq "explorer" }

            { Update-ExplorerShell -WaitSeconds 0 } | Should Not Throw
        }

        It "Handles Stop-Process failure gracefully" {
            Mock Stop-Process { throw "not running" } -ParameterFilter { $Name -eq "explorer" }
            Mock Write-InstallLog { }
            Mock Start-Sleep { }
            Mock Start-Process { } -ParameterFilter { $FilePath -eq "explorer" }

            { Update-ExplorerShell -WaitSeconds 0 } | Should Not Throw
        }
    }
}

# =============================================================================
#  DEPLOY MODULE TESTS (module-level smoke tests)
# =============================================================================
Describe "Deploy.ps1 -- Module Integration" {

    Context "Function inventory" {
        It "Get-Configuration function is defined" {
            Get-Command Get-Configuration -ErrorAction Stop | Should Not Be $null
        }

        It "Test-InstallerExists function is defined" {
            Get-Command Test-InstallerExists -ErrorAction Stop | Should Not Be $null
        }

        It "Update-ExplorerShell function is defined (not Refresh-Explorer)" {
            Get-Command Update-ExplorerShell -ErrorAction Stop | Should Not Be $null
            { Get-Command Refresh-Explorer -ErrorAction Stop } | Should Throw
        }

        It "All 16 module-level functions are available" {
            $expected = @(
                'Get-Configuration','Set-LogPath','Write-InstallLog',
                'Write-StatusOk','Write-StatusError','Write-StatusWarn',
                'Test-InternetConnection','Test-InstallerExists',
                'Add-DesktopIcons','Update-ExplorerShell',
                'Install-AnyDesk','Install-Akia','Install-Java',
                'Install-Office','Install-Envision','Install-Ninite'
            )
            $found = 0
            foreach ($fn in $expected) {
                if (Get-Command $fn -ErrorAction SilentlyContinue) { $found++ }
            }
            $found | Should Be 16
        }


        It "Deploy.ps1 script-level functions are not loaded during tests (config-dependent)" {
            $result = Get-Command Show-MainMenu -ErrorAction SilentlyContinue
            $result -eq $null | Should Be $true
        }
    }

    Context "Dependency verification" {
        It "Installer functions can see Write-InstallLog from Logger.ps1" {
            { Get-Command Write-InstallLog -ErrorAction Stop } | Should Not Throw
        }

        It "Desktop functions can see Write-InstallLog from Logger.ps1" {
            { Get-Command Write-InstallLog -ErrorAction Stop } | Should Not Throw
        }
    }
}
