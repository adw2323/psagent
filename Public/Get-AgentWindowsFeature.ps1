<#
.SYNOPSIS
    Returns Windows features and roles as structured JSON.

.DESCRIPTION
    Lists installed Windows features, roles, and capabilities.
    Useful for system capability assessment and compliance checks.

.PARAMETER Filter
    Filter features by name (case-insensitive partial match).

.PARAMETER OnlyInstalled
    Show only installed features.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentWindowsFeature

.EXAMPLE
    Get-AgentWindowsFeature -OnlyInstalled

.NOTES
    Uses Get-WindowsCapability for modern Windows 10/11 systems.
    Falls back to DISM for older systems.
#>
function Get-AgentWindowsFeature {
    [CmdletBinding()]
    param(
        [string]$Filter,
        [switch]$OnlyInstalled,
        [switch]$Raw
    )

    $features = @()

    # Try Get-WindowsCapability first (modern)
    try {
        $caps = Get-WindowsCapability -Online -ErrorAction Stop

        foreach ($cap in $caps) {
            $features += @{
                name = $cap.Name
                display_name = $cap.DisplayName
                state = $cap.State.ToString()
                install_time = if ($cap.InstallTime) { $cap.InstallTime.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
                size_bytes = if ($cap.Size) { $cap.Size } else { $null }
                description = if ($cap.Description.Length -gt 200) { $cap.Description.Substring(0, 200) + '...' } else { $cap.Description }
                type = 'capability'
            }
        }
    } catch {
        # Fallback to DISM
        try {
            $dismOutput = dism /online /get-features /format:table 2>&1
            foreach ($line in $dismOutput) {
                if ($line -match '^\|?\s*(\S+)\s+\|\s*(\S+)\s+\|') {
                    $features += @{
                        name = $Matches[1]
                        display_name = $Matches[1]
                        state = $Matches[2]
                        type = 'feature'
                    }
                }
            }
        } catch { }
    }

    # Apply filters
    if ($Filter) {
        $features = $features | Where-Object { $_.name -like "*$Filter*" -or $_.display_name -like "*$Filter*" }
    }

    if ($OnlyInstalled) {
        $features = $features | Where-Object { $_.state -eq 'Installed' }
    }

    $result = @{
        type = 'windows_features'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_features = $features.Count
        filter = $Filter
        features = @($features)
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name awf -Value Get-AgentWindowsFeature
