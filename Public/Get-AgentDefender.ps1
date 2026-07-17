# Get-AgentDefender.ps1 - Returns Windows Defender status as structured JSON

function Get-AgentDefender {
    <#
    .SYNOPSIS
    Returns Windows Defender status as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns Windows Defender information including:
    - Real-time protection status
    - Signature versions and dates
    - Scan history
    - Threat detection history
    - Exclusions
    
    .PARAMETER IncludeThreats
    Include recent threat detection history.
    
    .PARAMETER IncludeExclusions
    Include exclusion lists.
    
    .PARAMETER Raw
    Output as raw PowerShell hashtable instead of JSON.
    
    .EXAMPLE
    Get-AgentDefender
    
    .EXAMPLE
    Get-AgentDefender -IncludeThreats -IncludeExclusions
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeThreats,
        
        [switch]$IncludeExclusions,
        
        [switch]$Raw
    )
    
    try {
        # Get Defender status
        $status = Get-MpComputerStatus -ErrorAction Stop
        
        $defenderStatus = @{
            real_time_protection = $status.RealTimeProtectionEnabled
            behavior_monitor = $status.BehaviorMonitorEnabled
            ioav_protection = $status.IoavProtectionEnabled
            on_access_protection = $status.OnAccessProtectionEnabled
            antimalware_enabled = $status.AntimalwareEnabled
            antivirus_enabled = $status.AntivirusEnabled
            antispyware_enabled = $status.AntispywareEnabled
            antivirus_signature_last_updated = if ($status.AntivirusSignatureLastUpdated) {
                $status.AntivirusSignatureLastUpdated.ToString("yyyy-MM-ddTHH:mm:ss")
            } else { $null }
            antivirus_signature_version = $status.AntivirusSignatureVersion
            antispyware_signature_last_updated = if ($status.AntispywareSignatureLastUpdated) {
                $status.AntispywareSignatureLastUpdated.ToString("yyyy-MM-ddTHH:mm:ss")
            } else { $null }
            antispyware_signature_version = $status.AntispywareSignatureVersion
            quick_scan_end_time = if ($status.QuickScanEndTime) {
                $status.QuickScanEndTime.ToString("yyyy-MM-ddTHH:mm:ss")
            } else { $null }
            quick_scan_results = $status.QuickScanEndTime -ne $null
            full_scan_end_time = if ($status.FullScanEndTime) {
                $status.FullScanEndTime.ToString("yyyy-MM-ddTHH:mm:ss")
            } else { $null }
            full_scan_results = $status.FullScanEndTime -ne $null
            product_version = $status.AMProductVersion
            enabled = $status.AMServiceEnabled
        }
        
        # Get threat history if requested
        $threatHistory = @()
        if ($IncludeThreats) {
            try {
                $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue | Select-Object -First 50
                foreach ($threat in $threats) {
                    $threatInfo = @{
                        threat_id = $threat.ThreatID
                        domain_user = $threat.DomainUser
                        process_name = $threat.ProcessName
                        initial_detection_time = if ($threat.InitialDetectionTime) {
                            $threat.InitialDetectionTime.ToString("yyyy-MM-ddTHH:mm:ss")
                        } else { $null }
                        last_threat_status_time = if ($threat.LastThreatStatusTime) {
                            $threat.LastThreatStatusTime.ToString("yyyy-MM-ddTHH:mm:ss")
                        } else { $null }
                        additional_fields_bit_mask = $threat.AdditionalFieldsBitMask
                        domain = $threat.Domain
                        machine = $threat.Machine
                    }
                    $threatHistory += $threatInfo
                }
            } catch {
                $threatHistory = @(@{ error = "Failed to get threat history" })
            }
        }
        
        # Get exclusions if requested
        $exclusions = @{}
        if ($IncludeExclusions) {
            try {
                $prefs = Get-MpPreference -ErrorAction SilentlyContinue
                if ($prefs) {
                    $exclusions = @{
                        process_exclusions = @($prefs.ExclusionProcess)
                        path_exclusions = @($prefs.ExclusionPath)
                        extension_exclusions = @($prefs.ExclusionExtension)
                        ip_exclusions = @($prefs.ExclusionIpAddress)
                    }
                }
            } catch {
                $exclusions = @{ error = "Failed to get exclusions" }
            }
        }
        
        $output = @{
            type = 'defender_status'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            status = $defenderStatus
        }
        
        if ($IncludeThreats) {
            $output.threat_history = @($threatHistory)
            $output.total_threats = $threatHistory.Count
        }
        
        if ($IncludeExclusions) {
            $output.exclusions = $exclusions
        }
        
        if ($Raw) {
            return $output
        } else {
            return $output | ConvertTo-Json -Depth 10
        }
        
    } catch {
        $errorOutput = @{
            type = 'defender_status'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            error = $_.Exception.Message
            status = @{}
        }
        
        if ($Raw) {
            return $errorOutput
        } else {
            return $errorOutput | ConvertTo-Json -Depth 10
        }
    }
}

Set-Alias -Name adf -Value Get-AgentDefender
