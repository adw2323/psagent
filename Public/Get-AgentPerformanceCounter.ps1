<#
.SYNOPSIS
    Gets performance counter data as structured JSON.

.DESCRIPTION
    Retrieves system performance counters for CPU, memory, disk, and network.
    Returns structured JSON for AI agents to parse.

.PARAMETER Counter
    Specific counter to monitor (e.g., \Processor(_Total)\% Processor Time).

.PARAMETER Duration
    Duration in seconds to monitor the counter.

.PARAMETER SampleInterval
    Interval in seconds between samples.

.EXAMPLE
    Get-AgentPerformanceCounter

.EXAMPLE
    Get-AgentPerformanceCounter -Counter "\Processor(_Total)\% Processor Time" -Duration 10

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.4.0
#>
function Get-AgentPerformanceCounter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Counter,
        
        [Parameter(Mandatory = $false)]
        [int]$Duration = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1
    )

    try {
        # Default counters if none specified
        if (-not $Counter) {
            $counters = @(
                '\Processor(_Total)\% Processor Time',
                '\Memory\Available MBytes',
                '\Memory\% Committed Bytes In Use',
                '\LogicalDisk(C:)\% Free Space',
                '\LogicalDisk(C:)\Disk Read Bytes/sec',
                '\LogicalDisk(C:)\Disk Write Bytes/sec',
                '\Network Interface(*)\Bytes Total/sec'
            )
        }
        else {
            $counters = @($Counter)
        }

        # Get counter data
        $counterData = Get-Counter -Counter $counters -ErrorAction SilentlyContinue

        # Build the result
        $result = @{
            Type        = 'PerformanceCounter'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            Counters    = @()
            Summary     = @{
                CPUUsage      = $null
                AvailableMemoryMB = $null
                MemoryUsagePercent = $null
                DiskFreePercent = $null
            }
        }

        foreach ($sample in $counterData.CounterSamples) {
            $counterInfo = @{
                Path        = $sample.Path
                Instance    = $sample.InstanceName
                Value       = [Math]::Round($sample.CookedValue, 2)
                Timestamp   = $sample.Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.fff')
                SecondValue = $sample.SecondValue
                Status      = $sample.Status
            }

            $result.Counters += $counterInfo

            # Update summary based on counter type
            switch -Wildcard ($sample.Path) {
                '*Processor*Processor Time*' {
                    $result.Summary.CPUUsage = [Math]::Round($sample.CookedValue, 2)
                }
                '*Memory*Available MBytes*' {
                    $result.Summary.AvailableMemoryMB = [Math]::Round($sample.CookedValue, 0)
                }
                '*Memory*% Committed Bytes*' {
                    $result.Summary.MemoryUsagePercent = [Math]::Round($sample.CookedValue, 2)
                }
                '*LogicalDisk*% Free Space*' {
                    $result.Summary.DiskFreePercent = [Math]::Round($sample.CookedValue, 2)
                }
            }
        }

        # Add additional system metrics
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $result.SystemMetrics = @{
                TotalPhysicalMemoryGB = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                FreePhysicalMemoryGB  = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
                TotalVirtualMemoryGB = [Math]::Round($os.TotalVirtualMemorySize / 1MB, 2)
                FreeVirtualMemoryGB  = [Math]::Round($os.FreeVirtualMemory / 1MB, 2)
                UptimeHours          = [Math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 2)
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'PerformanceCounter'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
