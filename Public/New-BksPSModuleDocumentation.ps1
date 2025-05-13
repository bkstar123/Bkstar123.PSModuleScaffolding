function New-BksPSModuleDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Check if PlatyPS is installed
        if (-not (Get-Module -ListAvailable -Name PlatyPS)) {
            Write-Host "PlatyPS module not found. Installing..." -ForegroundColor Yellow
            Install-Module -Name PlatyPS -Force -Scope CurrentUser
        }
        
        Import-Module PlatyPS
        
        if (-not $OutputPath) {
            $OutputPath = Join-Path $ModulePath 'docs'
        }
    }
    
    process {
        try {
            # Create docs directory if it doesn't exist
            if (-not (Test-Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Import the module to document
            $moduleName = Split-Path $ModulePath -Leaf
            Import-Module $ModulePath -Force
            
            # Generate markdown help
            $null = New-MarkdownHelp -Module $moduleName -OutputFolder $OutputPath -Force:$Force
            
            # Generate module page
            $moduleInfo = Get-Module $moduleName
            $modulePage = @"
# $($moduleInfo.Name)

## Description
$($moduleInfo.Description)

## Installation
```powershell
Install-Module -Name $($moduleInfo.Name) -Scope CurrentUser
```

## Functions
$(Get-Command -Module $moduleName | ForEach-Object { "* [$($_.Name)]($($_.Name).md)" })

## Requirements
PowerShell Version: $($moduleInfo.PowerShellVersion)
"@
            Set-Content -Path (Join-Path $OutputPath "README.md") -Value $modulePage
            
            # Generate external help
            New-ExternalHelp -Path $OutputPath -OutputPath (Join-Path $ModulePath "en-US") -Force:$Force
            
            Write-Host "Documentation generated successfully at $OutputPath" -ForegroundColor Green
            Write-Host "MAML help generated at $(Join-Path $ModulePath 'en-US')" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to generate documentation: $_"
        }
        finally {
            # Remove the module from the current session
            Remove-Module $moduleName -ErrorAction SilentlyContinue
        }
    }
} 