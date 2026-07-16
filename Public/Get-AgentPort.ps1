# Get-AgentPort.ps1 - Returns port usage as structured JSON

function Get-AgentPort {
    <#
    .SYNOPSIS
    Returns port usage information as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns port info with:
    - Local/remote addresses
    - Process name and ID
    - Connection state
    
    .EXAMPLE
    Get-AgentPort -LocalPort 8080
    #>
    [CmdletBinding()]
    param(
        [int]$LocalPort,
        
        [int]$RemotePort,
        
        [string]$ProcessName,
        
        [string]$State,
        
        [switch]$Raw,
                [switch]$Json
    )
    
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    
    if ($LocalPort) {
        $connections = $connections | Where-Object { $_.LocalPort -eq $LocalPort }
    }
    
    if ($RemotePort) {
        $connections = $connections | Where-Object { $_.RemotePort -eq $RemotePort }
    }
    
    if ($State) {
        $connections = $connections | Where-Object { $_.State -eq $State }
    }
    
    $results = @()
    
    $connections | ForEach-Object {
        $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $processName = if ($process) { $process.Name } else { 'unknown' }
        
        if ($ProcessName -and $processName -notlike "*$ProcessName*") {
            return
        }
        
        $results += @{
            local_address = $_.LocalAddress
            local_port = $_.LocalPort
            remote_address = $_.RemoteAddress
            remote_port = $_.RemotePort
            state = $_.State.ToString()
            process_name = $processName
            process_id = $_.OwningProcess
        }
    }
    
    $output = @{
        type = 'port_usage'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_connections = $results.Count
        connections = $results
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name apo -Value Get-AgentPort
