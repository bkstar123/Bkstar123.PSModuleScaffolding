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
