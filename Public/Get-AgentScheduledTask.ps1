# Get-AgentScheduledTask.ps1 - Returns Windows scheduled tasks as structured JSON

function Get-AgentScheduledTask {
    <#
    .SYNOPSIS
    Returns Windows scheduled tasks as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns scheduled task information including:
    - Task name and path
    - Task status (Ready, Running, Disabled)
    - Last run time and result
    - Next run time
    - Triggers (time-based, event-based, etc.)
    - Actions (commands executed)
    - Principals (user account)
    
    .PARAMETER TaskName
    Filter by task name (supports wildcards).
    
    .PARAMETER Status
    Filter by status: Ready, Running, Disabled, Unknown.
    
    .PARAMETER TaskPath
    Filter by task path (e.g., \Microsoft\Windows\).
    
    .PARAMETER Raw
    Output as raw PowerShell hashtable instead of JSON.
    
    .EXAMPLE
    Get-AgentScheduledTask
    
    .EXAMPLE
    Get-AgentScheduledTask -Status Running
    
    .EXAMPLE
    Get-AgentScheduledTask -TaskName "\Microsoft\Windows\*"
    #>
    [CmdletBinding()]
    param(
        [string]$TaskName,
        
        [ValidateSet('Ready', 'Running', 'Disabled', 'Unknown')]
        [string]$Status,
        
        [string]$TaskPath,
        
        [switch]$Raw
    )
    
    try {
        # Build Get-ScheduledTask parameters
        $params = @{}
        
        if ($TaskName) {
            $params['TaskName'] = $TaskName
        }
        
        if ($TaskPath) {
            $params['TaskPath'] = $TaskPath
        }
        
        # Get scheduled tasks
        $tasks = Get-ScheduledTask @params -ErrorAction Stop
        
        # Filter by status if specified
        if ($Status) {
            $tasks = $tasks | Where-Object { $_.State -eq $Status }
        }
        
        $results = @()
        
        foreach ($task in $tasks) {
            # Get task info for detailed information
            $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
            
            # Extract triggers
            $triggers = @()
            if ($task.Triggers) {
                foreach ($trigger in $task.Triggers) {
                    $triggerInfo = @{
                        type = $trigger.CimClass.CimClassName -replace 'MSFT_', '' -replace 'Trigger', ''
                        enabled = $trigger.Enabled
                    }
                    
                    # Add trigger-specific properties
                    if ($trigger.PSObject.Properties['StartBoundary']) {
                        $triggerInfo.start_boundary = $trigger.StartBoundary
                    }
                    if ($trigger.PSObject.Properties['EndBoundary']) {
                        $triggerInfo.end_boundary = $trigger.EndBoundary
                    }
                    if ($trigger.PSObject.Properties['Interval']) {
                        $triggerInfo.interval = $trigger.Interval
                    }
                    if ($trigger.PSObject.Properties['Repetition']) {
                        $triggerInfo.repetition = $trigger.Repetition.Interval
                    }
                    
                    $triggers += $triggerInfo
                }
            }
            
            # Extract actions
            $actions = @()
            if ($task.Actions) {
                foreach ($action in $task.Actions) {
                    $actionInfo = @{
                        type = $action.CimClass.CimClassName -replace 'MSFT_', '' -replace 'Action', ''
                    }
                    
                    if ($action.PSObject.Properties['Execute']) {
                        $actionInfo.execute = $action.Execute
                    }
                    if ($action.PSObject.Properties['Arguments']) {
                        $actionInfo.arguments = $action.Arguments
                    }
                    if ($action.PSObject.Properties['WorkingDirectory']) {
                        $actionInfo.working_directory = $action.WorkingDirectory
                    }
                    
                    $actions += $actionInfo
                }
            }
            
            # Extract principal
            $principal = @{}
            if ($task.Principal) {
                $principal = @{
                    user_id = $task.Principal.UserId
                    logon_type = $task.Principal.LogonType
                    run_level = $task.Principal.RunLevel
                }
            }
            
            # Build task result
            $taskResult = @{
                task_name = $task.TaskName
                task_path = $task.TaskPath
                status = $task.State.ToString()
                last_run_time = if ($taskInfo.LastRunTime -and $taskInfo.LastRunTime -ne [datetime]::MinValue) {
                    $taskInfo.LastRunTime.ToString("yyyy-MM-ddTHH:mm:ss")
                } else { $null }
                last_run_result = if ($taskInfo.LastTaskResult -ne 0) {
                    $taskInfo.LastTaskResult
                } else { $null }
                next_run_time = if ($taskInfo.NextRunTime -and $taskInfo.NextRunTime -ne [datetime]::MinValue) {
                    $taskInfo.NextRunTime.ToString("yyyy-MM-ddTHH:mm:ss")
                } else { $null }
                number_of_missed_runs = $taskInfo.NumberOfMissedRuns
                triggers = @($triggers)
                actions = @($actions)
                principal = $principal
            }
            
            $results += $taskResult
        }
        
        $output = @{
            type = 'scheduled_tasks'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            total_tasks = $results.Count
            tasks = @($results)
        }
        
        if ($Raw) {
            return $output
        } else {
            return $output | ConvertTo-Json -Depth 10
        }
        
    } catch {
        $errorOutput = @{
            type = 'scheduled_tasks'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            error = $_.Exception.Message
            tasks = @()
            total_tasks = 0
        }
        
        if ($Raw) {
            return $errorOutput
        } else {
            return $errorOutput | ConvertTo-Json -Depth 10
        }
    }
}

Set-Alias -Name ast -Value Get-AgentScheduledTask
