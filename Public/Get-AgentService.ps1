# Get-AgentService.ps1 - Returns service information as structured JSON

function Get-AgentService {
    <#
    .SYNOPSIS
    Returns Windows service information as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns service data with:
    - Service name, display name, status
    - Start type, start name
    - Process ID, service type
    
    .EXAMPLE
    Get-AgentService -Status Running -SortBy Name
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        
        [string]$Status,
        
        [string]$SortBy = 'Name',
        
        [switch]$Descending,
        
        [switch]$Raw,
                [switch]$Json
    )
    
    $services = Get-Service -ErrorAction SilentlyContinue
    
    if ($Name) {
        $services = $services | Where-Object { $_.Name -like "*$Name*" -or $_.DisplayName -like "*$Name*" }
    }
    
    if ($Status) {
        $services = $services | Where-Object { $_.Status -eq $Status }
    }
    
    $results = @()
    
    # Batch WMI query for all service details (much faster than per-service)
    $wmiData = @{}
    Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | ForEach-Object {
        $wmiData[$_.Name] = $_
    }
    
    $services | ForEach-Object {
        $wmi = $wmiData[$_.Name]
        
        $results += @{
            name = $_.Name
            display_name = $_.DisplayName
            status = $_.Status.ToString()
            start_type = if ($wmi) { $wmi.StartMode } else { 'unknown' }
            start_name = if ($wmi) { $wmi.StartName } else { 'unknown' }
            process_id = if ($wmi) { $wmi.ProcessId } else { 0 }
            service_type = if ($wmi) { $wmi.ServiceType } else { 'unknown' }
            path = if ($wmi) { $wmi.PathName } else { '' }
            description = if ($wmi) { $wmi.Description } else { '' }
        }
    }
    
    # Sort
    $results = $results | Sort-Object -Property $SortBy -Descending:$Descending
    
    $output = @{
        type = 'service_list'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_services = $results.Count
        services = @($results)
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name as -Value Get-AgentService
