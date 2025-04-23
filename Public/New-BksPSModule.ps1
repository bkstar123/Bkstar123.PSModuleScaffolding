function New-BksPSModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    $Author = Read-Host "Enter the author of the module (required)"
    $Description = Read-Host "Enter a description for the module (required)"
    $Version = Read-Host "Enter the version of the module (required)"

    $basePath = Join-Path -Path (Get-Location) -ChildPath $ModuleName
    $folders = @("Public", "Private", "Classes", "Tests")
    
    # Create module folder structure
    if (-not (Test-Path $basePath)) {
        New-Item -ItemType Directory -Path $basePath | Out-Null
        foreach ($folder in $folders) {
            New-Item -ItemType Directory -Path (Join-Path $basePath $folder) | Out-Null
        }
    }

    # Create Private function to get functions from file
    $privateFunc = @'
function Get-FunctionsFromFile {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        # Write-Warning "File not found: $Path"
        return @()
    }

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

    return $ast.FindAll({
        param ($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false) | ForEach-Object {
        $_.Name
    }
}
'@
    Set-Content -Path (Join-Path $basePath (Join-Path "Private" "Get-FunctionsFromFile.ps1")) -Value $privateFunc

    # Create file .psm1
    $psm1 = @'
# Dot-source all scripts in Classes, Private, and Public folders
$ClassPath = Join-Path -Path $PSScriptRoot -ChildPath 'Classes'
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'

if (Test-Path $ClassPath) {
    Get-ChildItem -Path (Join-Path $ClassPath "*.ps1") -Recurse -File | ForEach-Object { . $_.FullName }
}

if (Test-Path $PrivatePath) {
    Get-ChildItem -Path (Join-Path $PrivatePath "*.ps1") -Recurse -File | ForEach-Object { . $_.FullName }
}

$publicFunctions = @()
if (Test-Path $PublicPath) {
    Get-ChildItem -Path (Join-Path $PublicPath "*.ps1") -Recurse -File | ForEach-Object { 
        . $_.FullName 
        $publicFunctions += Get-FunctionsFromFile -Path $_.FullName
    }
} 
# Export only functions from Public
Export-ModuleMember -Function $publicFunctions
'@
    Set-Content -Path (Join-Path $basePath "$ModuleName.psm1") -Value $psm1
    
    # Create File manifest .psd1
    New-ModuleManifest -Path (Join-Path $basePath "$ModuleName.psd1") `
        -RootModule "$ModuleName.psm1" `
        -Author "$Author" `
        -Description "$Description" `
        -ModuleVersion "$Version" `
        -FunctionsToExport '*' `
    
    # Create Example public function
    $func = @'
function DoSomething {
    [CmdletBinding()]
    param (
        [string]$message = "example action"
    )
    return "Do $message"
}
'@
    Set-Content -Path (Join-Path $basePath (Join-Path "Public" "DoSomething.ps1")) -Value $func
    
    # Create Test with Pester
    $test = @"
Describe "$ModuleName - DoSomething" {
    It "Should display properly" {
        . (Join-Path (Join-Path `$PSScriptRoot "..") $ModuleName.psm1)
        (DoSomething) | Should -Be "Do example action"
    }
}
"@
    Set-Content -Path (Join-Path $basePath (Join-Path "Tests" "DoSomething.Test.ps1")) -Value $test
    
    # Create README.md
    $readme = @"
# $ModuleName
    
A reusable PowerShell module.
    
## Usage
    
```powershell
Import-Module .\$ModuleName\$ModuleName.psd1
DoSomething
"@
    Set-Content -Path (Join-Path $basePath "README.md") -Value $readme

    # Create .gitignore (Simplified for PS module)
    $gitignore = @"
*.ps1xml
*.user
*.suo
*.log
*.nupkg
.vscode/
.idea/
"@
    Set-Content -Path (Join-Path $basePath ".gitignore") -Value $gitignore 
    
    # Create License file
    $license = @" 
MIT License
Copyright (c) $(Get-Date -Format yyyy)
Permission is hereby granted, free of charge, to any person obtaining a copy... 
"@ 
    Set-Content -Path (Join-Path $basePath "LICENSE") -Value $license   
}
