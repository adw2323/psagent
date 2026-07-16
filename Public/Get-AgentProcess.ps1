# Get-AgentProcess.ps1 - Returns process information as structured JSON

function Get-AgentProcess {
    <#
    .SYNOPSIS
    Returns process information as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns process data with:
    - Process name, ID, CPU usage
    - Memory usage (working set, private bytes)
    - Start time, runtime
    - Command line (if available)
    
    .EXAMPLE
    Get-AgentProcess -MinCPU 10 -SortBy CPU -Descending
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        
        [int]$MinCPU,
        
        [long]$MinMemory,
        
        [string]$SortBy = 'CPU',
        
        [switch]$Descending,
        
        [int]$Top = 50,
        
        [switch]$Json
    )
    
    $processes = Get-Process -ErrorAction SilentlyContinue
    
    if ($Name) {
        $processes = $processes | Where-Object { $_.Name -like "*$Name*" }
    }
    
    if ($MinCPU) {
        $processes = $processes | Where-Object { $_.CPU -ge $MinCPU }
    }
    
    if ($MinMemory) {
        $processes = $processes | Where-Object { $_.WorkingSet64 -ge $MinMemory }
    }
    
    $results = @()
    
    $processes | ForEach-Object {
        $results += @{
            name = $_.Name
            id = $_.Id
            cpu = [math]::Round($_.CPU, 2)
            memory_working_set = $_.WorkingSet64
            memory_working_set_human = Format-FileSize -Bytes $_.WorkingSet64
            memory_private = $_.PrivateMemorySize64
            memory_private_human = Format-FileSize -Bytes $_.PrivateMemorySize64
            threads = $_.Threads.Count
            handles = $_.HandleCount
            start_time = if ($_.StartTime) { $_.StartTime.ToString('yyyy-MM-ddTHH:mm:ss') } else { 'unknown' }
            runtime_seconds = if ($_.StartTime) { [math]::Round(([DateTime]::Now - $_.StartTime).TotalSeconds, 1) } else { 0 }
            path = $_.Path
        }
    }
    
    # Batch WMI query for command lines (much faster than per-process)
    $processIds = $results | ForEach-Object { $_.id }
    $wmiData = @{}
    if ($processIds.Count -gt 0) {
        $idFilter = ($processIds | ForEach-Object { "ProcessId=$_" }) -join ' OR '
        Get-CimInstance Win32_Process -Filter $idFilter -ErrorAction SilentlyContinue | ForEach-Object {
            $wmiData[$_.ProcessId] = $_.CommandLine
        }
    }
    
    # Add command lines to results
    foreach ($r in $results) {
        $r.command_line = if ($wmiData.ContainsKey($r.id)) { $wmiData[$r.id] } else { '' }
    }
    
    # Sort
    $results = $results | Sort-Object -Property $SortBy -Descending:$Descending
    
    # Top N
    if ($Top -gt 0) {
        $results = $results | Select-Object -First $Top
    }
    
    $output = @{
        type = 'process_list'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_processes = $results.Count
        processes = @($results)
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name ap -Value Get-AgentProcess
