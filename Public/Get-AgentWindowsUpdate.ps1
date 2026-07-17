<#
.SYNOPSIS
    Gets Windows Update history and status as structured JSON.

.DESCRIPTION
    Retrieves installed updates, available updates, and update status.
    Returns structured JSON for AI agents to parse.

.PARAMETER MaxResults
    Maximum number of updates to return.

.PARAMETER Status
    Filter by update status: Installed, Available, Failed.

.PARAMETER IncludeDrivers
    Include driver updates.

.EXAMPLE
    Get-AgentWindowsUpdate

.EXAMPLE
    Get-AgentWindowsUpdate -Status Installed -MaxResults 10

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.4.0
#>
function Get-AgentWindowsUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 50,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Installed', 'Available', 'Failed', 'Pending')]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDrivers
    )

    try {
        # Get installed updates
        $installedUpdates = Get-HotFix -ErrorAction SilentlyContinue | 
            Sort-Object InstalledOn -Descending |
            Select-Object -First $MaxResults

        # Get pending updates (if PSWindowsUpdate module is available)
        $pendingUpdates = @()
        if (Get-Module -ListAvailable -Name PSWindowsUpdate -ErrorAction SilentlyContinue) {
            Import-Module PSWindowsUpdate -Force
            $pendingUpdates = Get-WindowsUpdate -ErrorAction SilentlyContinue |
                Select-Object -First $MaxResults
        }

        # Build the result
        $result = @{
            Type            = 'WindowsUpdate'
            Timestamp       = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName    = $env:COMPUTERNAME
            InstalledUpdates = @()
            PendingUpdates  = @()
            Summary         = @{
                TotalInstalled = $installedUpdates.Count
                TotalPending   = $pendingUpdates.Count
            }
        }

        # Process installed updates
        foreach ($update in $installedUpdates) {
            $updateInfo = @{
                HotFixID       = $update.HotFixID
                Description    = $update.Description
                InstalledOn    = if ($update.InstalledOn) { $update.InstalledOn.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
                InstalledBy    = $update.InstalledBy
                ServicePack    = $update.ServicePackInEffect
                Status         = 'Installed'
            }

            # Filter by status if specified
            if ($Status -eq 'Installed' -or -not $Status) {
                $result.InstalledUpdates += $updateInfo
            }
        }

        # Process pending updates
        foreach ($update in $pendingUpdates) {
            $updateInfo = @{
                Title          = $update.Title
                Description    = $update.Description
                KB             = $update.KB
                Size           = $update.Size
                Status         = $update.Status
                Downloaded     = $update.IsDownloaded
                Hidden         = $update.IsHidden
            }

            # Filter by status if specified
            if ($Status -eq 'Available' -or $Status -eq 'Pending' -or -not $Status) {
                $result.PendingUpdates += $updateInfo
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'WindowsUpdate'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
