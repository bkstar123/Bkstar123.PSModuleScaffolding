function New-BksPSModuleTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter()]
        [switch]$RunTests,
        
        [Parameter()]
        [switch]$GenerateCodeCoverage
    )
    
    begin {
        try {
            # Unload existing Pester module if any
            if (Get-Module -Name Pester) {
                Remove-Module -Name Pester -Force -ErrorAction SilentlyContinue
            }

            # Try to find latest Pester version
            $pester = Get-Module -ListAvailable -Name Pester | 
                Where-Object { $_.Version.Major -ge 5 } | 
                Sort-Object Version -Descending | 
                Select-Object -First 1

            if (-not $pester) {
                Write-Host "Installing Pester 5.0.0 or later..." -ForegroundColor Yellow
                $null = Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck -AllowClobber -Scope CurrentUser
                $pester = Get-Module -ListAvailable -Name Pester | 
                    Where-Object { $_.Version.Major -ge 5 } | 
                    Sort-Object Version -Descending | 
                    Select-Object -First 1
            }

            # Import Pester using full path to avoid antivirus issues
            $pesterPath = Join-Path $pester.ModuleBase "Pester.psd1"
            if (Test-Path $pesterPath) {
                Import-Module $pesterPath -Force -ErrorAction Stop
            } else {
                throw "Could not find Pester module at $pesterPath"
            }

            Write-Host "Using Pester version $($pester.Version)" -ForegroundColor Green
        }
        catch {
            throw "Failed to initialize Pester: $_"
        }

        $moduleName = Split-Path $ModulePath -Leaf
        $testsPath = Join-Path $ModulePath 'Tests'
    }
    
    process {
        try {
            # Create Tests directory if it doesn't exist
            if (-not (Test-Path $testsPath)) {
                New-Item -Path $testsPath -ItemType Directory -Force | Out-Null
            }
            
            # Create test configuration file
            $testConfig = @'
BeforeAll {
    $ModulePath = Split-Path -Parent $PSScriptRoot
    $ModuleName = Split-Path $ModulePath -Leaf
    
    # Import module
    Import-Module $ModulePath -Force
}

AfterAll {
    # Remove module from session
    Remove-Module $ModuleName -ErrorAction SilentlyContinue
}

Describe "$ModuleName Module Tests" {
    Context "Module Loading" {
        It "Should import successfully" {
            Get-Module $ModuleName | Should -Not -BeNullOrEmpty
        }
    }
}
'@
            Set-Content -Path (Join-Path $testsPath "Module.Tests.ps1") -Value $testConfig -Force
            
            # Create test files for each public function
            $publicFunctions = Get-ChildItem -Path (Join-Path $ModulePath 'Public') -Filter "*.ps1"
            foreach ($function in $publicFunctions) {
                $functionName = $function.BaseName
                $testContent = @"
BeforeAll {
    `$ModulePath = Split-Path -Parent `$PSScriptRoot
    `$ModuleName = Split-Path `$ModulePath -Leaf
    Import-Module `$ModulePath -Force
}

Describe "$functionName Tests" {
    Context "Function Validation" {
        It "Has a valid help section" {
            Get-Help $functionName | Should -Not -BeNullOrEmpty
        }
        
        It "Is an advanced function" {
            `$command = Get-Command $functionName
            `$command.CmdletBinding | Should -Be `$true
        }
    }
    
    Context "Parameter Validation" {
        # Add parameter validation tests here
    }
    
    Context "Function Behavior" {
        # Add function behavior tests here
    }
}
"@
                Set-Content -Path (Join-Path $testsPath "$functionName.Tests.ps1") -Value $testContent -Force
            }
            
            # Create GitHub Actions workflow for tests
            $workflowsPath = Join-Path $ModulePath '.github\workflows'
            if (-not (Test-Path $workflowsPath)) {
                New-Item -Path $workflowsPath -ItemType Directory -Force | Out-Null
            }
            
            $workflowContent = @'
name: Test PowerShell Module

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]
        
    steps:
    - uses: actions/checkout@v2
    
    - name: Install Pester
      shell: pwsh
      run: |
        Install-Module Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck -Scope CurrentUser
        
    - name: Run Tests
      shell: pwsh
      run: |
        $pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version.Major -ge 5 } | Sort-Object Version -Descending | Select-Object -First 1
        Import-Module $pester.ModuleBase\Pester.psd1 -Force
        $config = @{
            Run = @{
                Path = "./Tests"
            }
            Output = @{
                Verbosity = "Detailed"
            }
        }
        Invoke-Pester -Configuration $config
'@
            Set-Content -Path (Join-Path $workflowsPath "test.yml") -Value $workflowContent -Force
            
            if ($RunTests) {
                Write-Host "Running tests..." -ForegroundColor Yellow
                
                try {
                    # Create configuration using hashtable instead of New-PesterConfiguration
                    $config = @{
                        Run = @{
                            Path = $testsPath
                        }
                        Output = @{
                            Verbosity = "Detailed"
                        }
                    }
                    
                    if ($GenerateCodeCoverage) {
                        $config.CodeCoverage = @{
                            Enabled = $true
                            Path = Join-Path $ModulePath "Public\*.ps1"
                            OutputPath = Join-Path $testsPath "coverage.xml"
                        }
                    }
                    
                    # Run tests using the configuration hashtable
                    Invoke-Pester -Configuration $config
                }
                catch {
                    Write-Warning "Error running tests with Pester 5 configuration. Error: $_"
                }
            }
            
            Write-Host "Test files generated successfully at $testsPath" -ForegroundColor Green
            Write-Host "GitHub Actions workflow created at $workflowsPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to generate tests: $_"
        }
    }
} 