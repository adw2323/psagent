<#
.SYNOPSIS
    Returns installed hotfixes and updates as structured JSON for AI agents.

.DESCRIPTION
    Lists installed Windows updates, patches, and hotfixes.
    Useful for vulnerability assessment and patch compliance checks.

.PARAMETER MaxResults
    Maximum number of hotfixes to return. Default 50.

.PARAMETER HotfixId
    Filter by specific KB article (e.g. KB5034441).

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentHotfix

.EXAMPLE
    Get-AgentHotfix -MaxResults 10
#>
function Get-AgentHotfix {
    [CmdletBinding()]
    param(
        [int]$MaxResults = 50,
        [string]$HotfixId,
        [switch]$Raw
    )

    $params = @{
        ClassName = 'Win32_QuickFixEngineering'
        ErrorAction = 'Stop'
    }

    if ($HotfixId) {
        $params['Filter'] = "HotFixID='$HotfixId'"
    }

    $hotfixes = Get-CimInstance @params |
        Sort-Object InstalledOn -Descending |
        Select-Object -First $MaxResults

    $results = foreach ($hf in $hotfixes) {
        @{
            hotfix_id   = $hf.HotFixID
            description = $hf.Description
            installed_on = if ($hf.InstalledOn) { $hf.InstalledOn.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            installed_by = $hf.InstalledBy
            service_pack = $hf.ServicePackInEffect
        }
    }

    $output = @{
        type          = 'hotfix_list'
        timestamp     = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_hotfixes = $results.Count
        hotfixes      = @($results)
    }

    if ($Raw) { $output } else { $output | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name ahf -Value Get-AgentHotfix
