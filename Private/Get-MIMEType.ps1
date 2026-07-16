# Get-MIMEType.ps1 - Detects MIME type from file extension

function Get-MIMEType {
    <#
    .SYNOPSIS
    Detects MIME type from file extension.
    
    .DESCRIPTION
    Maps file extensions to MIME types for agent consumption.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Extension
    )
    
    $mimeMap = @{
        '.py' = 'text/x-python'
        '.js' = 'application/javascript'
        '.ts' = 'application/typescript'
        '.go' = 'text/x-go'
        '.rs' = 'text/x-rust'
        '.java' = 'text/x-java'
        '.c' = 'text/x-c'
        '.cpp' = 'text/x-c++'
        '.cs' = 'text/x-csharp'
        '.rb' = 'text/x-ruby'
        '.php' = 'text/x-php'
        '.sh' = 'application/x-shellscript'
        '.ps1' = 'application/x-powershell'
        '.html' = 'text/html'
        '.css' = 'text/css'
        '.json' = 'application/json'
        '.yaml' = 'application/x-yaml'
        '.yml' = 'application/x-yaml'
        '.xml' = 'application/xml'
        '.md' = 'text/markdown'
        '.txt' = 'text/plain'
        '.csv' = 'text/csv'
        '.sql' = 'application/sql'
        '.png' = 'image/png'
        '.jpg' = 'image/jpeg'
        '.jpeg' = 'image/jpeg'
        '.gif' = 'image/gif'
        '.svg' = 'image/svg+xml'
        '.webp' = 'image/webp'
        '.pdf' = 'application/pdf'
        '.zip' = 'application/zip'
        '.tar' = 'application/x-tar'
        '.gz' = 'application/gzip'
    }
    
    $ext = $Extension.ToLower()
    if ($mimeMap.ContainsKey($ext)) {
        return $mimeMap[$ext]
    }
    
    return 'application/octet-stream'
}

Set-Alias -Name getmime -Value Get-MIMEType
