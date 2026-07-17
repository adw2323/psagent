# Get-AgentEventLog.ps1 - Returns Windows event logs as structured JSON

function Get-AgentEventLog {
    <#
    .SYNOPSIS
    Returns Windows event logs as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns event log information including:
    - Event ID and level
    - Time created
    - Provider name
    - Message content
    - Machine name
    - User identity
    
    .PARAMETER LogName
    Log name: Application, Security, System, or custom log.
    
    .PARAMETER Level
    Event level: Critical, Error, Warning, Information, Verbose.
    
    .PARAMETER MaxEvents
    Maximum number of events to return (default: 50).
    
    .PARAMETER StartTime
    Start time for event search.
    
    .PARAMETER EndTime
    End time for event search.
    
    .PARAMETER ProviderName
    Filter by provider name.
    
    .PARAMETER Raw
    Output as raw PowerShell hashtable instead of JSON.
    
    .EXAMPLE
    Get-AgentEventLog -LogName System -MaxEvents 10
    
    .EXAMPLE
    Get-AgentEventLog -LogName Security -Level Error
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Application', 'Security', 'System')]
        [string]$LogName = 'System',
        
        [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
        [string]$Level,
        
        [int]$MaxEvents = 50,
        
        [datetime]$StartTime,
        
        [datetime]$EndTime,
        
        [string]$ProviderName,
        
        [switch]$Raw
    )
    
    try {
        # Build filter hashtable
        $filter = @{
            LogName = $LogName
        }
        
        if ($Level) {
            $filter['Level'] = switch ($Level) {
                'Critical' { 1 }
                'Error' { 2 }
                'Warning' { 3 }
                'Information' { 4 }
                'Verbose' { 5 }
            }
        }
        
        if ($StartTime) {
            $filter['StartTime'] = $StartTime
        }
        
        if ($EndTime) {
            $filter['EndTime'] = $EndTime
        }
        
        if ($ProviderName) {
            $filter['ProviderName'] = $ProviderName
        }
        
        # Get events
        $events = Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop
        
        $results = @()
        
        foreach ($event in $events) {
            $eventResult = @{
                event_id = $event.Id
                level = $event.LevelDisplayName
                time_created = $event.TimeCreated.ToString("yyyy-MM-ddTHH:mm:ss.fff")
                provider_name = $event.ProviderName
                machine_name = $event.MachineName
                message = if ($event.Message.Length -gt 500) {
                    $event.Message.Substring(0, 500) + "..."
                } else {
                    $event.Message
                }
                record_id = $event.RecordId
                process_id = $event.ProcessId
                thread_id = $event.ThreadId
                keywords = @($event.Keywords)
            }
            
            # Add user identity if available
            if ($event.UserId) {
                $eventResult.user_sid = $event.UserId.Value
            }
            
            $results += $eventResult
        }
        
        $output = @{
            type = 'event_log'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            log_name = $LogName
            total_events = $results.Count
            events = @($results)
        }
        
        if ($Raw) {
            return $output
        } else {
            return $output | ConvertTo-Json -Depth 10
        }
        
    } catch {
        $errorOutput = @{
            type = 'event_log'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            log_name = $LogName
            error = $_.Exception.Message
            events = @()
            total_events = 0
        }
        
        if ($Raw) {
            return $errorOutput
        } else {
            return $errorOutput | ConvertTo-Json -Depth 10
        }
    }
}

Set-Alias -Name ael -Value Get-AgentEventLog
