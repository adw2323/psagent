<#
.SYNOPSIS
    Returns comprehensive system information as structured JSON for AI agents.

.DESCRIPTION
    Gathers OS, hardware, network identity, and uptime in a single call.
    Designed for AI agents that need a fast system overview.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentSystemInfo

.EXAMPLE
    Get-AgentSystemInfo -Raw
#>
function Get-AgentSystemInfo {
    [CmdletBinding()]
    param(
        [switch]$Raw
    )

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1

    $uptime = (Get-Date) - $os.LastBootUpTime

    $result = @{
        type        = 'system_info'
        timestamp   = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        hostname    = $cs.Name
        domain      = $cs.Domain
        domain_role = $cs.DomainRole
        manufacturer = $cs.Manufacturer
        model       = $cs.Model
        total_physical_memory_gb = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        available_physical_memory_gb = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        os = @{
            caption     = $os.Caption
            version     = $os.Version
            build_number = $os.BuildNumber
            architecture = $os.OSArchitecture
            install_date = $os.InstallDate.ToString('yyyy-MM-ddTHH:mm:ss')
        }
        cpu = @{
            name           = $cpu.Name
            cores          = $cpu.NumberOfCores
            logical_processors = $cpu.NumberOfLogicalProcessors
            max_clock_speed_mhz = $cpu.MaxClockSpeed
        }
        bios = @{
            manufacturer = $bios.Manufacturer
            version      = $bios.SMBIOSBIOSVersion
            release_date = $bios.ReleaseDate
        }
        uptime = @{
            days    = $uptime.Days
            hours   = $uptime.Hours
            minutes = $uptime.Minutes
            total_hours = [math]::Round($uptime.TotalHours, 2)
            boot_time = $os.LastBootUpTime.ToString('yyyy-MM-ddTHH:mm:ss')
        }
        timezone = (Get-TimeZone).Id
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name asi -Value Get-AgentSystemInfo
