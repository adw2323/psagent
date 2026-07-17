<#
.SYNOPSIS
    Gets or sets the Windows clipboard content as structured JSON.

.DESCRIPTION
    Provides clipboard read/write access for AI agents.
    Can read text, HTML, images, and file lists from clipboard.
    Can set text content to clipboard.

.PARAMETER Set
    Text content to set to the clipboard.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentClipboard

.EXAMPLE
    Get-AgentClipboard -Set "Hello from AI agent"

.NOTES
    Uses Windows Forms clipboard API for reliable access.
#>
function Get-AgentClipboard {
    [CmdletBinding()]
    param(
        [string]$Set,
        [switch]$Raw
    )

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

    if ($Set) {
        [System.Windows.Forms.Clipboard]::SetText($Set)
        $result = @{
            type = 'clipboard_set'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            status = 'success'
            length = $Set.Length
            preview = if ($Set.Length -gt 100) { $Set.Substring(0, 100) + '...' } else { $Set }
        }
        if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
        return
    }

    $hasText = [System.Windows.Forms.Clipboard]::ContainsText()
    $hasImage = [System.Windows.Forms.Clipboard]::ContainsImage()
    $hasFiles = [System.Windows.Forms.Clipboard]::ContainsFileDropList()

    $result = @{
        type = 'clipboard_content'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        has_text = $hasText
        has_image = $hasImage
        has_files = $hasFiles
        text = $null
        text_length = 0
        image_size = $null
        files = @()
    }

    if ($hasText) {
        $text = [System.Windows.Forms.Clipboard]::GetText()
        $result.text = if ($text.Length -gt 5000) { $text.Substring(0, 5000) + '...' } else { $text }
        $result.text_length = $text.Length
    }

    if ($hasImage) {
        $img = [System.Windows.Forms.Clipboard]::GetImage()
        if ($img) {
            $result.image_size = @{
                width = $img.Width
                height = $img.Height
            }
        }
    }

    if ($hasFiles) {
        $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
        $result.files = @($files | ForEach-Object {
            $info = Get-Item $_ -ErrorAction SilentlyContinue
            if ($info) {
                @{
                    path = $_
                    name = $info.Name
                    is_directory = $info.PSIsContainer
                    size_bytes = if (-not $info.PSIsContainer) { $info.Length } else { 0 }
                }
            } else {
                @{ path = $_; name = (Split-Path $_ -Leaf); is_directory = $false; size_bytes = 0 }
            }
        })
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name aclip -Value Get-AgentClipboard
