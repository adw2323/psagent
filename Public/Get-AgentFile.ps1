# Get-AgentFile.ps1 - Returns file metadata as structured JSON

function Get-AgentFile {
    <#
    .SYNOPSIS
    Returns file metadata as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns file info with:
    - Absolute path
    - Size (bytes + human-readable)
    - Language detection
    - MIME type
    - Timestamps
    
    .EXAMPLE
    Get-AgentFile -Path C:\src\main.py
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [switch]$Json
    )
    
    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        return @{ error = "File not found: $Path" } | ConvertTo-Json
    }
    
    $file = Get-Item -Path $resolvedPath.Path -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) {
        return @{ error = "Not a file: $Path" } | ConvertTo-Json
    }
    
    $ext = $file.Extension
    $lang = Get-Language -Extension $ext
    $mime = Get-MIMEType -Extension $ext
    
    # Count lines if text file
    $lineCount = 0
    $wordCount = 0
    try {
        $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
        $lineCount = $content.Count
        $wordCount = ($content -join "`n" -split '\s+').Count
    } catch {
        # Binary file, skip
    }
    
    $output = @{
        type = 'file_info'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        name = $file.Name
        path = $file.FullName
        absolute = $file.FullName
        directory = $file.DirectoryName
        extension = $ext
        language = $lang
        mime = $mime
        size_bytes = $file.Length
        size_human = Format-FileSize -Bytes $file.Length
        lines = $lineCount
        words = $wordCount
        created = $file.CreationTime.ToString('yyyy-MM-ddTHH:mm:ss')
        modified = $file.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
        accessed = $file.LastAccessTime.ToString('yyyy-MM-ddTHH:mm:ss')
        modified_ago_s = [math]::Floor(([DateTimeOffset]::Now - $file.LastWriteTime).TotalSeconds)
        is_read_only = $file.IsReadOnly
    }
    
    if ($Json) {
        $output | ConvertTo-Json -Depth 10
    } else {
        $output
    }
}

Set-Alias -Name af -Value Get-AgentFile
