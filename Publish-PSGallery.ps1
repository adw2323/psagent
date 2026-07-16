#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publish psagent module to PSGallery.

.DESCRIPTION
    Publishes the psagent PowerShell module to the PowerShell Gallery.
    Requires a PSGallery API key (set via -ApiKey or $env:PSGALLERY_API_KEY).

.PARAMETER ApiKey
    PSGallery API key. If not provided, uses $env:PSGALLERY_API_KEY.

.PARAMETER WhatIf
    Shows what would be published without actually publishing.

.EXAMPLE
    ./Publish-PSGallery.ps1 -ApiKey "your-api-key"
    ./Publish-PSGallery.ps1 -WhatIf
#>
param(
    [string]$ApiKey,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Get API key
if (-not $ApiKey) {
    $ApiKey = $env:PSGALLERY_API_KEY
}
if (-not $ApiKey) {
    Write-Error "No API key provided. Set -ApiKey parameter or $env:PSGALLERY_API_KEY."
    exit 1
}

# Verify module loads
Write-Host "Verifying module loads..." -ForegroundColor Cyan
try {
    Import-Module "./psagent.psd1" -Force
    $commands = Get-Command -Module psagent
    Write-Host "  Module loaded: $($commands.Count) functions exported" -ForegroundColor Green
} catch {
    Write-Error "Failed to load module: $_"
    exit 1
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Cyan
$testResult = Invoke-Pester "./Tests/psagent.Tests.ps1" -PassThru
if ($testResult.FailedCount -gt 0) {
    Write-Error "Tests failed: $($testResult.FailedCount) failures"
    exit 1
}
Write-Host "  Tests passed: $($testResult.PassedCount)/$($testResult.TotalCount)" -ForegroundColor Green

# Check version
$manifest = Import-PowerShellDataFile "./psagent.psd1"
Write-Host "Publishing version $($manifest.ModuleVersion)..." -ForegroundColor Cyan

# Publish
$publishParams = @{
    Path = "./psagent.psd1"
    NuGetApiKey = $ApiKey
    Repository = "PSGallery"
    Force = $true
    Confirm = $false
}

if ($WhatIf) {
    $publishParams.WhatIf = $true
    Write-Host "  WhatIf mode - no changes will be made" -ForegroundColor Yellow
}

try {
    Publish-Module @publishParams
    Write-Host "  Published successfully!" -ForegroundColor Green
} catch {
    Write-Error "Publish failed: $_"
    exit 1
}

Write-Host "`nModule published to PSGallery: https://www.powershellgallery.com/packages/psagent" -ForegroundColor Green
