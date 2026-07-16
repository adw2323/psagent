# Get-AgentChildItem.ps1 - Lists directory contents with metadata

function Get-AgentChildItem {
    <#
    .SYNOPSIS
    Lists directory contents with structured metadata for AI agents.
    
    .DESCRIPTION
    Returns directory contents as structured JSON with:
    - Absolute paths
    - File sizes (bytes + human-readable)
    - Language detection
    - MIME types
    - Timestamps (Unix epoch + human-readable)
    
    .EXAMPLE
    Get-AgentChildItem -Path C:\src -Filter *.py -Depth 2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',
        
        [string]$Filter = '*',
        
        [int]$Depth = 1,
        
        [switch]$IncludeHidden,
        
        [switch]$Recurse,
        
        [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "Path not found: $Path" } | ConvertTo-Json
    }
    
    $items = @()
    
    $childParams = @{
        Path = $resolvedPath.Path
        Filter = $Filter
        ErrorAction = 'SilentlyContinue'
    }
    
    if ($Depth -gt 0) {
        $childParams.Depth = $Depth
    }
    
    if ($IncludeHidden) {
        $childParams.Force = $true
    }
    
    Get-ChildItem @childParams | ForEach-Object {
        $ext = if ($_.PSIsContainer) { '' } else { $_.Extension }
        $lang = if ($ext) { Get-Language -Extension $ext } else { 'directory' }
        $mime = if ($ext) { Get-MIMEType -Extension $ext } else { 'inode/directory' }
        
        $items += @{
            name = $_.Name
            path = $_.FullName
            absolute = $_.FullName
            is_dir = $_.PSIsContainer
            size_bytes = if ($_.PSIsContainer) { 0 } else { $_.Length }
            size_human = if ($_.PSIsContainer) { '0' } else { Format-FileSize -Bytes $_.Length }
            language = $lang
            mime = $mime
            extension = $ext
            modified = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            modified_ago_s = [math]::Floor(([DateTimeOffset]::Now - $_.LastWriteTime).TotalSeconds)
            readable = -not $_.IsReadOnly
        }
    }
    
    $output = @{
        type = 'directory_listing'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        path = $resolvedPath.Path
        total_entries = $items.Count
        files = ($items | Where-Object { -not $_.is_dir })
        directories = ($items | Where-Object { $_.is_dir })
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

function Format-FileSize {
    param([long]$Bytes)
    
    if ($Bytes -ge 1GB) { return "{0:N1}GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1}MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1}KB" -f ($Bytes / 1KB) }
    return "${Bytes}B"
}

Set-Alias -Name al -Value Get-AgentChildItem
