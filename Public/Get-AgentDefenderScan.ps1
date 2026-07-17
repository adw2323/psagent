<#
.SYNOPSIS
    Manages Windows Defender scans as structured JSON.

.DESCRIPTION
    Starts, stops, or monitors Windows Defender scans.
    Returns structured JSON for AI agents to parse.

.PARAMETER Action
    Action to perform: StartQuickScan, StartFullScan, GetStatus, GetHistory.

.PARAMETER ScanType
    Type of scan: Quick, Full, Custom.

.PARAMETER MaxResults
    Maximum number of history items to return.

.EXAMPLE
    Get-AgentDefenderScan -Action GetStatus

.EXAMPLE
    Get-AgentDefenderScan -Action StartQuickScan

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.6.0
#>
function Get-AgentDefenderScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('StartQuickScan', 'StartFullScan', 'GetStatus', 'GetHistory')]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Quick', 'Full', 'Custom')]
        [string]$ScanType = 'Quick',
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 20
    )

    try {
        $result = @{
            Type        = 'DefenderScan'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            Action      = $Action
            Status      = 'Success'
            Data        = @{}
        }

        switch ($Action) {
            'GetStatus' {
                $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
                $result.Data = @{
                    AntivirusEnabled         = $defenderStatus.AntivirusEnabled
                    RealTimeProtectionEnabled = $defenderStatus.RealTimeProtectionEnabled
                    AntivirusSignatureAge    = $defenderStatus.AntivirusSignatureAge
                    QuickScanAge             = $defenderStatus.QuickScanAge
                    FullScanAge              = $defenderStatus.FullScanAge
                    AntivirusSignatureLastUpdated = if ($defenderStatus.AntivirusSignatureLastUpdated) { 
                        $defenderStatus.AntivirusSignatureLastUpdated.ToString('yyyy-MM-ddTHH:mm:ss') 
                    } else { $null }
                    QuickScanEndTime         = if ($defenderStatus.QuickScanEndTime) { 
                        $defenderStatus.QuickScanEndTime.ToString('yyyy-MM-ddTHH:mm:ss') 
                    } else { $null }
                    FullScanEndTime          = if ($defenderStatus.FullScanEndTime) { 
                        $defenderStatus.FullScanEndTime.ToString('yyyy-MM-ddTHH:mm:ss') 
                    } else { $null }
                    IsTamperProtected        = $defenderStatus.IsTamperProtected
                    AntivirusSignatureVersion = $defenderStatus.AntivirusSignatureVersion
                }
            }
            
            'StartQuickScan' {
                $scanResult = Start-MpScan -ScanType QuickScan -ErrorAction Stop
                $result.Data = @{
                    ScanType     = 'Quick'
                    StartTime    = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                    Status       = 'Completed'
                    ThreatsFound = $scanResult.ThreatsFound
                    ThreatsCleaned = $scanResult.ThreatsCleaned
                    ThreatsQuarantined = $scanResult.ThreatsQuarantined
                    ThreatsRemoved = $scanResult.ThreatsRemoved
                }
            }
            
            'StartFullScan' {
                $scanResult = Start-MpScan -ScanType FullScan -ErrorAction Stop
                $result.Data = @{
                    ScanType     = 'Full'
                    StartTime    = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
                    Status       = 'Completed'
                    ThreatsFound = $scanResult.ThreatsFound
                    ThreatsCleaned = $scanResult.ThreatsCleaned
                    ThreatsQuarantined = $scanResult.ThreatsQuarantined
                    ThreatsRemoved = $scanResult.ThreatsRemoved
                }
            }
            
            'GetHistory' {
                $history = Get-MpThreatDetection -ErrorAction SilentlyContinue |
                    Sort-Object InitialDetectionTime -Descending |
                    Select-Object -First $MaxResults
                
                $historyList = @()
                foreach ($item in $history) {
                    $historyList += @{
                        ThreatID            = $item.ThreatID
                        Domain              = $item.Domain
                        UserName            = $item.UserName
                        ProcessName         = $item.ProcessName
                        InitialDetectionTime = if ($item.InitialDetectionTime) { 
                            $item.InitialDetectionTime.ToString('yyyy-MM-ddTHH:mm:ss') 
                        } else { $null }
                        LastThreatStatusTime = if ($item.LastThreatStatusTime) { 
                            $item.LastThreatStatusTime.ToString('yyyy-MM-ddTHH:mm:ss') 
                        } else { $null }
                        AdditionalFieldsBitMask = $item.AdditionalFieldsBitMask
                    }
                }
                $result.Data = @{
                    History = $historyList
                    Count   = $historyList.Count
                }
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'DefenderScan'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
            Action      = $Action
            Status      = 'Failed'
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
