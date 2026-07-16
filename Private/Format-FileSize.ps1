# Format-FileSize.ps1 - Helper function to format file sizes

function Format-FileSize {
    <#
    .SYNOPSIS
    Formats a file size in bytes to human-readable format.
    
    .DESCRIPTION
    Converts bytes to KB, MB, or GB as appropriate.
    
    .EXAMPLE
    Format-FileSize -Bytes 1024
    # Returns: 1.0KB
    #>
    param([long]$Bytes)
    
    if ($Bytes -ge 1GB) { return "{0:N1}GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1}MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1}KB" -f ($Bytes / 1KB) }
    return "${Bytes}B"
}
