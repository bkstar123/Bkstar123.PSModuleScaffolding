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
