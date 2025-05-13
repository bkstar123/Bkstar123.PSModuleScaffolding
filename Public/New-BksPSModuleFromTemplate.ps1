function New-BksPSModuleFromTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Azure', 'AWS', 'SystemAdmin')]
        [string]$TemplateType,
        
        [Parameter()]
        [string]$OutputPath = (Get-Location),
        
        [Parameter()]
        [hashtable]$CustomParameters = @{}
    )
    
    begin {
        $templatePath = Join-Path $PSScriptRoot "..\Templates\$TemplateType\template.json"
        if (-not (Test-Path $templatePath)) {
            throw "Template not found: $templatePath"
        }
        
        $template = Get-Content $templatePath | ConvertFrom-Json
    }
    
    process {
        try {
            # Create module directory
            $modulePath = Join-Path $OutputPath $ModuleName
            New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
            
            # Create standard folders
            foreach ($folder in @('Public', 'Private', 'Classes', 'Tests')) {
                New-Item -Path (Join-Path $modulePath $folder) -ItemType Directory -Force | Out-Null
            }
            
            # Process template files
            foreach ($section in $template.files.PSObject.Properties) {
                $sectionPath = Join-Path $modulePath $section.Name
                foreach ($file in $section.Value) {
                    $filePath = Join-Path $sectionPath $file.name
                    $content = $file.content
                    
                    # Replace placeholders with custom parameters
                    foreach ($param in $CustomParameters.GetEnumerator()) {
                        $content = $content.Replace("{{$($param.Key)}}", $param.Value)
                    }
                    
                    Set-Content -Path $filePath -Value $content
                }
            }
            
            # Create module manifest
            $manifestPath = Join-Path $modulePath "$ModuleName.psd1"
            $manifestParams = @{
                Path = $manifestPath
                RootModule = "$ModuleName.psm1"
                ModuleVersion = '0.1.0'
                Author = $env:USERNAME
                Description = "PowerShell module created from $TemplateType template"
                PowerShellVersion = '5.1'
                RequiredModules = $template.dependencies
            }
            New-ModuleManifest @manifestParams
            
            # Create module file
            $moduleContent = @'
# Dot source public and private functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue)

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
            
            Write-Host "Successfully created $ModuleName module from $TemplateType template at $modulePath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create module: $_"
        }
    }
} 