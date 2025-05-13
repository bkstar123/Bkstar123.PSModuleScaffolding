function Update-BksPSModuleVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter()]
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$VersionType = 'Patch',
        
        [Parameter()]
        [switch]$GenerateChangelog
    )
    
    begin {
        function Update-Version {
            param (
                [Version]$Version,
                [string]$Type
            )
            
            $major = $Version.Major
            $minor = $Version.Minor
            $build = $Version.Build
            
            switch ($Type) {
                'Major' {
                    $major++
                    $minor = 0
                    $build = 0
                }
                'Minor' {
                    $minor++
                    $build = 0
                }
                'Patch' {
                    $build++
                }
            }
            
            return [Version]::new($major, $minor, $build)
        }
    }
    
    process {
        try {
            # Get module manifest path
            $manifestPath = Get-ChildItem -Path $ModulePath -Filter "*.psd1" |
                Where-Object { $_.BaseName -eq (Split-Path $ModulePath -Leaf) } |
                Select-Object -First 1 -ExpandProperty FullName
            
            if (-not $manifestPath) {
                throw "Module manifest not found in $ModulePath"
            }
            
            # Import current manifest
            $manifest = Import-PowerShellDataFile -Path $manifestPath
            $currentVersion = [Version]$manifest.ModuleVersion
            $newVersion = Update-Version -Version $currentVersion -Type $VersionType
            
            # Update manifest version
            Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion
            
            if ($GenerateChangelog) {
                $changelogPath = Join-Path $ModulePath 'CHANGELOG.md'
                $date = Get-Date -Format "yyyy-MM-dd"
                
                if (-not (Test-Path $changelogPath)) {
                    $changelogHeader = @"
# Changelog
All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

"@
                    Set-Content -Path $changelogPath -Value $changelogHeader
                }
                
                $existingContent = Get-Content -Path $changelogPath
                $versionHeader = @"

## [$newVersion] - $date
### Changed
- Version updated from $currentVersion to $newVersion

"@
                $newContent = @()
                $newContent += $existingContent[0..3]  # Keep the header
                $newContent += $versionHeader
                $newContent += $existingContent[4..$existingContent.Count]
                Set-Content -Path $changelogPath -Value $newContent
                
                Write-Host "Updated CHANGELOG.md" -ForegroundColor Green
            }
            
            # Create git tag if in git repository
            $gitPath = Join-Path $ModulePath '.git'
            if (Test-Path $gitPath) {
                try {
                    $null = git -C $ModulePath tag -a "v$newVersion" -m "Version $newVersion"
                    Write-Host "Created git tag v$newVersion" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to create git tag: $_"
                }
            }
            
            Write-Host "Module version updated from $currentVersion to $newVersion" -ForegroundColor Green
            
            # Return version info
            return [PSCustomObject]@{
                PreviousVersion = $currentVersion
                NewVersion = $newVersion
                ManifestPath = $manifestPath
                ChangelogPath = if ($GenerateChangelog) { $changelogPath } else { $null }
            }
        }
        catch {
            Write-Error "Failed to update module version: $_"
        }
    }
} 