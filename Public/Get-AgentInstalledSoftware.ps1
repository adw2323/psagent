<#
.SYNOPSIS
    Lists installed software as structured JSON.

.DESCRIPTION
    Enumerates installed applications from registry and program directories.
    Provides clean data about what software is installed on the system.

.PARAMETER Filter
    Filter software by name (case-insensitive partial match).

.PARAMETER MaxResults
    Maximum number of results to return. Default: 100.

.PARAMETER IncludeUpdates
    Include Windows updates in the list.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentInstalledSoftware

.EXAMPLE
    Get-AgentInstalledSoftware -Filter "Visual Studio"

.NOTES
    Reads from multiple registry locations for comprehensive coverage:
    - HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
    - HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
    - HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
#>
function Get-AgentInstalledSoftware {
    [CmdletBinding()]
    param(
        [string]$Filter,
        [int]$MaxResults = 100,
        [switch]$IncludeUpdates,
        [switch]$Raw
    )

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $software = @()

    foreach ($path in $registryPaths) {
        try {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and ($IncludeUpdates -or -not $_.SystemComponent) } |
                Where-Object { -not $_.ParentKeyName }

            foreach ($item in $items) {
                $sw = @{
                    name = $item.DisplayName
                    version = $item.DisplayVersion
                    publisher = $item.Publisher
                    install_date = $item.InstallDate
                    install_location = $item.InstallLocation
                    uninstall_string = $item.UninstallString
                    estimated_size_mb = if ($item.EstimatedSize) { [math]::Round($item.EstimatedSize / 1024, 2) } else { $null }
                    system_component = [bool]$item.SystemComponent
                    quiet_uninstall = $item.QuietUninstallString
                }
                $software += $sw
            }
        } catch { }
    }

    # Apply filter
    if ($Filter) {
        $software = $software | Where-Object { $_.name -like "*$Filter*" }
    }

    # Deduplicate by name+version
    $unique = $software | Sort-Object name, version -Unique | Select-Object -First $MaxResults

    $result = @{
        type = 'installed_software'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_count = $unique.Count
        filter = $Filter
        software = @($unique)
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name asw -Value Get-AgentInstalledSoftware
