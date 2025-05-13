function Test-BksPSModuleQuality {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter()]
        [switch]$FixProblems,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string[]]$Severity = @('Error', 'Warning')
    )
    
    begin {
        # Check if PSScriptAnalyzer is installed
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Write-Host "PSScriptAnalyzer module not found. Installing..." -ForegroundColor Yellow
            Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
        }
        
        Import-Module PSScriptAnalyzer
        
        if (-not $OutputPath) {
            $OutputPath = Join-Path $ModulePath 'analysis'
        }
        
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
    }
    
    process {
        try {
            # Create custom PSScriptAnalyzer settings
            $settingsPath = Join-Path $OutputPath 'PSScriptAnalyzerSettings.psd1'
            $settingsContent = @'
@{
    Severity = @('Error', 'Warning', 'Information')
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters',
        'PSUseApprovedVerbs',
        'PSAvoidUsingPlainTextForPassword',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars',
        'PSAvoidUsingInvokeExpression',
        'PSUseSingularNouns',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingEmptyCatchBlock'
    )
    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }
    }
}
'@
            Set-Content -Path $settingsPath -Value $settingsContent
            
            # Analyze module
            $results = @()
            $files = Get-ChildItem -Path $ModulePath -Include "*.ps1", "*.psm1", "*.psd1" -Recurse
            
            foreach ($file in $files) {
                $analysis = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settingsPath |
                    Where-Object { $_.Severity -in $Severity }
                
                if ($analysis) {
                    $results += $analysis
                    
                    if ($FixProblems) {
                        Write-Host "Attempting to fix issues in $($file.Name)..." -ForegroundColor Yellow
                        $null = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settingsPath -Fix
                    }
                }
            }
            
            # Generate report
            $reportPath = Join-Path $OutputPath "QualityReport.html"
            $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerShell Module Quality Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .error { color: red; }
        .warning { color: orange; }
        .information { color: blue; }
    </style>
</head>
<body>
    <h1>PowerShell Module Quality Report</h1>
    <h2>Module: $(Split-Path $ModulePath -Leaf)</h2>
    <h3>Analysis Date: $(Get-Date)</h3>
    
    <table>
        <tr>
            <th>Severity</th>
            <th>Rule Name</th>
            <th>File</th>
            <th>Line</th>
            <th>Message</th>
        </tr>
        $(foreach ($result in $results) {
            "<tr class='$($result.Severity.ToLower())'>"
            "<td>$($result.Severity)</td>"
            "<td>$($result.RuleName)</td>"
            "<td>$($result.ScriptName)</td>"
            "<td>$($result.Line)</td>"
            "<td>$($result.Message)</td>"
            "</tr>"
        })
    </table>
</body>
</html>
"@
            Set-Content -Path $reportPath -Value $reportContent
            
            # Output summary
            $summary = $results | Group-Object Severity | Select-Object @{N='Severity';E={$_.Name}}, @{N='Count';E={$_.Count}}
            Write-Host "`nAnalysis Summary:" -ForegroundColor Cyan
            $summary | Format-Table -AutoSize
            
            Write-Host "`nDetailed report generated at: $reportPath" -ForegroundColor Green
            
            if ($results.Count -gt 0) {
                Write-Host "`nFound $($results.Count) issue(s) in total." -ForegroundColor Yellow
                if (-not $FixProblems) {
                    Write-Host "Run with -FixProblems switch to attempt automatic fixes." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "`nNo issues found!" -ForegroundColor Green
            }
            
            # Return results object for pipeline use
            return [PSCustomObject]@{
                TotalIssues = $results.Count
                Summary = $summary
                Details = $results
                ReportPath = $reportPath
            }
        }
        catch {
            Write-Error "Failed to analyze module: $_"
        }
    }
} 