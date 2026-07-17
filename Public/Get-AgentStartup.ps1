<#
.SYNOPSIS
    Returns startup/autorun items as structured JSON for AI agents.

.DESCRIPTION
    Lists programs configured to run at startup from registry Run keys,
    Startup folder, and scheduled tasks with startup triggers.
    Useful for security auditing and troubleshooting slow boot times.

.PARAMETER IncludeRegistry
    Include registry Run/RunOnce entries. Default: true.

.PARAMETER IncludeStartupFolder
    Include Startup folder contents. Default: true.

.PARAMETER IncludeScheduledTasks
    Include tasks with boot/logon triggers. Default: true.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentStartup

.EXAMPLE
    Get-AgentStartup -IncludeScheduledTasks:$false
#>
function Get-AgentStartup {
    [CmdletBinding()]
    param(
        [switch]$IncludeRegistry = $true,
        [switch]$IncludeStartupFolder = $true,
        [switch]$IncludeScheduledTasks = $true,
        [switch]$Raw
    )

    $results = @{
        type      = 'startup_items'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        registry_entries    = @()
        startup_folder      = @()
        scheduled_task_starts = @()
    }

    # Registry Run/RunOnce keys
    if ($IncludeRegistry) {
        $regPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        )

        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                if ($props) {
                    $props.PSObject.Properties | Where-Object {
                        $_.Name -notmatch '^PS' -and $_.Name -ne '(default)'
                    } | ForEach-Object {
                        $results.registry_entries += @{
                            hive    = if ($path -match '^HKCU') { 'HKCU' } else { 'HKLM' }
                            key     = $path
                            name    = $_.Name
                            command = $_.Value
                        }
                    }
                }
            }
        }
    }

    # Startup folder contents
    if ($IncludeStartupFolder) {
        $startupPaths = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )

        foreach ($sp in $startupPaths) {
            if (Test-Path $sp) {
                Get-ChildItem -Path $sp -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $results.startup_folder += @{
                        name = $_.Name
                        path = $_.FullName
                        target = if ($_.Target) { $_.Target } else { $null }
                        size_bytes = $_.Length
                        modified = $_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
                    }
                }
            }
        }
    }

    # Scheduled tasks with startup triggers
    if ($IncludeScheduledTasks) {
        try {
            $tasks = Get-ScheduledTask -ErrorAction Stop |
                Where-Object {
                    $_.State -ne 'Disabled' -and
                    $_.Triggers | Where-Object {
                        $_.CimClass.CimClassName -match 'Boot|Logon'
                    }
                }

            foreach ($task in $tasks) {
                foreach ($trigger in $task.Triggers) {
                    if ($trigger.CimClass.CimClassName -match 'Boot|Logon') {
                        $results.scheduled_task_starts += @{
                            task_name  = $task.TaskName
                            task_path  = $task.TaskPath
                            trigger    = $trigger.CimClass.CimClassName -replace 'MSFT_', '' -replace 'Trigger', ''
                            enabled    = $trigger.Enabled
                            user       = $task.Principal.UserId
                        }
                    }
                }
            }
        } catch {
            # Silently continue - tasks may not be accessible
        }
    }

    $output = @{
        type      = $results.type
        timestamp = $results.timestamp
        total_items = $results.registry_entries.Count + $results.startup_folder.Count + $results.scheduled_task_starts.Count
        registry_entries     = @($results.registry_entries)
        startup_folder       = @($results.startup_folder)
        scheduled_task_starts = @($results.scheduled_task_starts)
    }

    if ($Raw) { $output } else { $output | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name asu -Value Get-AgentStartup
