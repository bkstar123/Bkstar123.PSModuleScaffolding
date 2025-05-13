function New-BksPSModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter()]
        [string]$OutputPath = (Get-Location)
    )
    
    process {
        try {
            # Create module directory
            $modulePath = Join-Path $OutputPath $ModuleName
            New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
            
            # Create all required directories
            $directories = @(
                'Public',      # Public functions
                'Private',     # Private functions
                'Class',       # Class definitions
                'Tests',       # Pester tests
                'docs',        # Documentation
                'en-US',      # Localized help files
                '.github\workflows', # GitHub Actions
                'analysis'     # Code analysis reports
            )
            
            foreach ($dir in $directories) {
                $path = Join-Path $modulePath $dir
                New-Item -Path $path -ItemType Directory -Force | Out-Null
            }
            
            # Create module manifest
            $manifestPath = Join-Path $modulePath "$ModuleName.psd1"
            $manifestParams = @{
                Path = $manifestPath
                RootModule = "$ModuleName.psm1"
                ModuleVersion = '0.1.0'
                Author = $env:USERNAME
                Description = "PowerShell module created with Bkstar123.PSModuleScaffolding"
                PowerShellVersion = '5.1'
                FunctionsToExport = @()
                CompatiblePSEditions = @('Desktop', 'Core')
            }
            New-ModuleManifest @manifestParams
            
            # Create module file
            $moduleContent = @'
# Dot source public and private functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Class\*.ps1 -ErrorAction SilentlyContinue)

# Dot source classes first
foreach ($class in $Classes) {
    try {
        . $class.FullName
    }
    catch {
        Write-Error "Failed to import class $($class.FullName): $_"
    }
}

# Dot source private functions
foreach ($function in $Private) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Failed to import function $($function.FullName): $_"
    }
}

# Dot source public functions
foreach ($function in $Public) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Failed to import function $($function.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
'@
            Set-Content -Path (Join-Path $modulePath "$ModuleName.psm1") -Value $moduleContent
            
            # Create initial CHANGELOG.md
            $changelogContent = @'
# Changelog
All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - $(Get-Date -Format "yyyy-MM-dd")
### Added
- Initial release
'@
            Set-Content -Path (Join-Path $modulePath "CHANGELOG.md") -Value $changelogContent
            
            # Create initial GitHub workflow
            $workflowPath = Join-Path $modulePath ".github\workflows\test.yml"
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
        Install-Module Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
        
    - name: Run Tests
      shell: pwsh
      run: |
        Import-Module Pester -MinimumVersion 5.0.0
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
            New-Item -Path $workflowPath -ItemType File -Force
            Set-Content -Path $workflowPath -Value $workflowContent
            
            Write-Host "Successfully created module scaffold at $modulePath" -ForegroundColor Green
            Write-Host "Next steps:" -ForegroundColor Yellow
            Write-Host "1. Add your functions to the Public and Private folders" -ForegroundColor Yellow
            Write-Host "2. Update the module manifest (FunctionsToExport, etc.)" -ForegroundColor Yellow
            Write-Host "3. Add tests to the Tests folder" -ForegroundColor Yellow
            Write-Host "4. Update documentation in the docs folder" -ForegroundColor Yellow
        }
        catch {
            Write-Error "Failed to create module scaffold: $_"
        }
    }
}
