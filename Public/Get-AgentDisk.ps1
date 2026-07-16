# Get-AgentDisk.ps1 - Returns disk information as structured JSON

function Get-AgentDisk {
    <#
    .SYNOPSIS
    Returns disk information as structured JSON for AI agents.
    
    .EXAMPLE
    Get-AgentDisk -SortBy FreeSpace -Descending
    #>
    [CmdletBinding()]
    param(
        [switch]$Json
    )
    
    $results = @()
    
    Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
        $used = if ($_.Used) { $_.Used } else { 0 }
        $free = if ($_.Free) { $_.Free } else { 0 }
        $total = $used + $free
        
        $results += @{
            name = $_.Name
            root = $_.Root
            used_bytes = $used
            used_human = Format-FileSize -Bytes $used
            free_bytes = $free
            free_human = Format-FileSize -Bytes $free
            total_bytes = $total
            total_human = Format-FileSize -Bytes $total
            used_percent = if ($total -gt 0) { [math]::Round(($used / $total) * 100, 1) } else { 0 }
            free_percent = if ($total -gt 0) { [math]::Round(($free / $total) * 100, 1) } else { 0 }
        }
    }
    
    $output = @{
        type = 'disk_info'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_drives = $results.Count
        drives = $results
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name ad -Value Get-AgentDisk
