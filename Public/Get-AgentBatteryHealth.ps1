<#
.SYNOPSIS
    Gets battery health information as structured JSON.

.DESCRIPTION
    Retrieves battery status, health, and charge information.
    Returns structured JSON for AI agents to parse.

.PARAMETER IncludeDetails
    Include detailed battery information.

.EXAMPLE
    Get-AgentBatteryHealth

.EXAMPLE
    Get-AgentBatteryHealth -IncludeDetails

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.5.0
#>
function Get-AgentBatteryHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails
    )

    try {
        # Get battery status
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        $batteryStatus = Get-CimInstance -ClassName BatteryStatus -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue

        # Build the result
        $result = @{
            Type        = 'BatteryHealth'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            HasBattery  = $null -ne $battery
            Status      = @{}
            Health      = @{}
            Details     = @{}
        }

        if ($battery) {
            $result.Status = @{
                Name             = $battery.Name
                DeviceID         = $battery.DeviceID
                Status           = $battery.Status
                Caption          = $battery.Caption
                Description      = $battery.Description
                BatteryStatus    = $battery.BatteryStatus
                EstimatedChargeRemaining = $battery.EstimatedChargeRemaining
                EstimatedRunTime = $battery.EstimatedRunTime
                PowerOnline      = $battery.PowerOnline
                Chemistry        = $battery.Chemistry
            }

            # Get detailed battery information
            if ($IncludeDetails) {
                $batteryStatic = Get-CimInstance -ClassName BatteryStaticData -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue
                $batteryCharges = Get-CimInstance -ClassName BatteryFullChargedCapacity -Namespace "ROOT\WMI" -ErrorAction SilentlyContinue

                if ($batteryStatic -and $batteryCharges) {
                    $designedCapacity = $batteryStatic.DesignedCapacity
                    $fullChargeCapacity = $batteryCharges.FullChargedCapacity

                    if ($designedCapacity -and $fullChargeCapacity) {
                        $healthPercent = [Math]::Round(($fullChargeCapacity / $designedCapacity) * 100, 2)
                        $result.Health = @{
                            DesignedCapacity = $designedCapacity
                            FullChargeCapacity = $fullChargeCapacity
                            HealthPercent    = $healthPercent
                            CycleCount       = $battery.CycleCount
                        }
                    }
                }

                # Add battery static data
                if ($batteryStatic) {
                    $result.Details = @{
                        DeviceName       = $batteryStatic.DeviceName
                        Chemistry        = $batteryStatic.Chemistry
                        DesignVoltage    = $batteryStatic.DesignVoltage
                        SerialNumber     = $batteryStatic.SerialNumber
                        ManufactureDate  = $batteryStatic.ManufactureDate
                        Manufacturer     = $batteryStatic.Manufacturer
                    }
                }
            }

            # Determine overall health status
            if ($result.Health.HealthPercent) {
                if ($result.Health.HealthPercent -gt 80) {
                    $result.Health.Status = 'Good'
                }
                elseif ($result.Health.HealthPercent -gt 50) {
                    $result.Health.Status = 'Fair'
                }
                else {
                    $result.Health.Status = 'Poor'
                }
            }
        }
        else {
            $result.Status = @{
                HasBattery = $false
                Message    = 'No battery detected on this system'
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'BatteryHealth'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
