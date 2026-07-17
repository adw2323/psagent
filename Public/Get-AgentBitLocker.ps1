<#
.SYNOPSIS
    Gets BitLocker status as structured JSON.

.DESCRIPTION
    Retrieves BitLocker volume encryption status.
    Returns structured JSON for AI agents to parse.

.PARAMETER Volume
    Specific volume to check (e.g., C:, D:).

.EXAMPLE
    Get-AgentBitLocker

.EXAMPLE
    Get-AgentBitLocker -Volume C:

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.4.0
#>
function Get-AgentBitLocker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Volume
    )

    try {
        # Get BitLocker volumes
        $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
        
        if ($Volume) {
            $volumes = $volumes | Where-Object { $_.MountPoint -eq $Volume -or $_.MountPoint -eq "$Volume\" }
        }

        # Build the result
        $result = @{
            Type        = 'BitLocker'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            Volumes     = @()
            Summary     = @{
                TotalVolumes    = 0
                ProtectedVolumes = 0
                UnprotectedVolumes = 0
            }
        }

        foreach ($vol in $volumes) {
            $volumeInfo = @{
                MountPoint         = $vol.MountPoint
                CapacityGB         = [Math]::Round($vol.CapacityGB, 2)
                FreeSpaceGB        = [Math]::Round($vol.FreeSpaceGB, 2)
                VolumeStatus       = $vol.VolumeStatus.ToString()
                ProtectionStatus   = $vol.ProtectionStatus.ToString()
                EncryptionMethod   = $vol.EncryptionMethod.ToString()
                IsBdeKeyProtectorAvailable = $vol.IsBdeKeyProtectorAvailable
                IsVolumeInitializedForAutoUnlock = $vol.IsVolumeInitializedForAutoUnlock
                KeyProtectors      = @()
            }

            # Get key protectors
            if ($vol.KeyProtector) {
                foreach ($key in $vol.KeyProtector) {
                    $volumeInfo.KeyProtectors += @{
                        KeyProtectorId = $key.KeyProtectorId
                        KeyProtectorType = $key.KeyProtectorType.ToString()
                        Thumbprint     = $key.Thumbprint
                    }
                }
            }

            $result.Volumes += $volumeInfo
            $result.Summary.TotalVolumes++

            if ($vol.ProtectionStatus.ToString() -eq 'On') {
                $result.Summary.ProtectedVolumes++
            }
            else {
                $result.Summary.UnprotectedVolumes++
            }
        }

        # Add overall status
        $result.OverallStatus = @{
            AllVolumesProtected = $result.Summary.UnprotectedVolumes -eq 0
            ProtectionPercentage = if ($result.Summary.TotalVolumes -gt 0) {
                [Math]::Round(($result.Summary.ProtectedVolumes / $result.Summary.TotalVolumes) * 100, 2)
            } else {
                0
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'BitLocker'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
