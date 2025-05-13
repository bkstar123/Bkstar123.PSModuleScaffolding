function Publish-BksPSModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter(Mandatory = $true)]
        [string]$NuGetApiKey,
        
        [Parameter()]
        [switch]$WhatIf,
        
        [Parameter()]
        [switch]$SkipVersionCheck,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Validate module path
        if (-not (Test-Path $ModulePath)) {
            throw "Module path not found: $ModulePath"
        }
        
        # Get module manifest
        $manifestPath = Get-ChildItem -Path $ModulePath -Filter "*.psd1" |
            Where-Object { $_.BaseName -eq (Split-Path $ModulePath -Leaf) } |
            Select-Object -First 1 -ExpandProperty FullName
            
        if (-not $manifestPath) {
            throw "Module manifest not found in $ModulePath"
        }
    }
    
    process {
        try {
            # Import module manifest
            $manifest = Import-PowerShellDataFile -Path $manifestPath
            $moduleName = $manifest.RootModule.Replace('.psm1', '')
            $moduleVersion = $manifest.ModuleVersion
            
            # Check if module version already exists in PSGallery
            if (-not $SkipVersionCheck) {
                try {
                    $existingModule = Find-Module -Name $moduleName -RequiredVersion $moduleVersion -ErrorAction Stop
                    if ($existingModule -and -not $Force) {
                        throw "Module version $moduleVersion already exists in PowerShell Gallery. Use -Force to override or update the module version."
                    }
                }
                catch [Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage.ModuleNotFoundInRepository] {
                    # Module/version not found, which is what we want
                }
            }
            
            # Validate module before publishing
            Write-Host "Validating module..." -ForegroundColor Yellow
            $testResults = Test-ModuleManifest -Path $manifestPath
            if (-not $testResults) {
                throw "Module manifest validation failed"
            }
            
            # Check for required metadata
            $requiredFields = @('Description', 'Author', 'PowerShellVersion')
            foreach ($field in $requiredFields) {
                if (-not $manifest.$field) {
                    throw "Required field '$field' is missing in the module manifest"
                }
            }
            
            # Prepare publishing parameters
            $publishParams = @{
                Path = $ModulePath
                NuGetApiKey = $NuGetApiKey
                Repository = 'PSGallery'
                Force = $Force
                WhatIf = $WhatIf
            }
            
            # Publish module
            Write-Host "Publishing module $moduleName version $moduleVersion to PowerShell Gallery..." -ForegroundColor Yellow
            Publish-Module @publishParams
            
            if (-not $WhatIf) {
                Write-Host "Module published successfully!" -ForegroundColor Green
                
                # Create GitHub release if in git repository
                $gitPath = Join-Path $ModulePath '.git'
                if (Test-Path $gitPath) {
                    try {
                        # Create release tag if it doesn't exist
                        $null = git -C $ModulePath tag -a "v$moduleVersion" -m "Release v$moduleVersion" 2>$null
                        $null = git -C $ModulePath push origin "v$moduleVersion"
                        Write-Host "Created git tag and pushed to origin: v$moduleVersion" -ForegroundColor Green
                    }
                    catch {
                        Write-Warning "Failed to create git release: $_"
                    }
                }
                
                # Return publishing info
                return [PSCustomObject]@{
                    ModuleName = $moduleName
                    Version = $moduleVersion
                    PublishDate = Get-Date
                    Repository = 'PSGallery'
                    GalleryUrl = "https://www.powershellgallery.com/packages/$moduleName/$moduleVersion"
                }
            }
        }
        catch {
            Write-Error "Failed to publish module: $_"
        }
    }
} 