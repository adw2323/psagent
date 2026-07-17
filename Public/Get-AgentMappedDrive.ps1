<#
.SYNOPSIS
    Gets mapped network drives as structured JSON.

.DESCRIPTION
    Retrieves mapped network drives and their properties.
    Returns structured JSON for AI agents to parse.

.PARAMETER MaxResults
    Maximum number of drives to return.

.PARAMETER IncludeDisconnected
    Include disconnected drives.

.EXAMPLE
    Get-AgentMappedDrive

.EXAMPLE
    Get-AgentMappedDrive -IncludeDisconnected

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.4.0
#>
function Get-AgentMappedDrive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDisconnected
    )

    try {
        # Get mapped drives
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayRoot -or $_.Provider -like '*FileSystem*' }

        # Filter to network drives
        $networkDrives = @()
        foreach ($drive in $drives) {
            if ($drive.DisplayRoot -and $drive.DisplayRoot.StartsWith('\\')) {
                $networkDrives += $drive
            }
        }

        # Get WMI network drive information
        $wmiDrives = Get-CimInstance -ClassName Win32_MappedLogicalDisk -ErrorAction SilentlyContinue

        # Build the result
        $result = @{
            Type        = 'MappedDrive'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            Drives      = @()
            Summary     = @{
                TotalDrives     = 0
                ConnectedDrives = 0
                DisconnectedDrives = 0
            }
        }

        # Process network drives
        foreach ($drive in $networkDrives | Select-Object -First $MaxResults) {
            $driveInfo = @{
                Name        = $drive.Name
                DisplayRoot = $drive.DisplayRoot
                ProviderURI = $drive.ProviderURI
                Root        = $drive.Root
                Used        = $drive.Used
                Free        = $drive.Free
                Description = $drive.Description
                Credential  = $drive.Credential.UserName
            }

            # Check if drive is connected
            $isConnected = Test-Path -Path "$($drive.Name):\" -ErrorAction SilentlyContinue
            $driveInfo.IsConnected = $isConnected

            if ($isConnected -or $IncludeDisconnected) {
                $result.Drives += $driveInfo
                $result.Summary.TotalDrives++

                if ($isConnected) {
                    $result.Summary.ConnectedDrives++
                }
                else {
                    $result.Summary.DisconnectedDrives++
                }
            }
        }

        # Add WMI information if available
        if ($wmiDrives) {
            $result.WMIDrives = @()
            foreach ($wmiDrive in $wmiDrives) {
                $result.WMIDrives += @{
                    Name       = $wmiDrive.Name
                    ProviderName = $wmiDrive.ProviderName
                    VolumeName = $wmiDrive.VolumeName
                    Size       = $wmiDrive.Size
                    FreeSpace  = $wmiDrive.FreeSpace
                    FileSystem = $wmiDrive.FileSystem
                }
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'MappedDrive'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
