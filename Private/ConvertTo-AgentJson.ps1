# ConvertTo-AgentJson.ps1 - Converts objects to agent-friendly JSON

function ConvertTo-AgentJson {
    <#
    .SYNOPSIS
    Converts objects to structured JSON for AI agents.
    
    .DESCRIPTION
    Wraps ConvertTo-Json with agent-friendly formatting:
    - Always uses depth 10
    - Formats for readability
    - Adds metadata wrapper
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject,
        
        [string]$Type = "result",
        
        [int]$Depth = 10
    )
    
    process {
        $items = @($InputObject)
        
        $output = @{
            type = $Type
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            count = $items.Count
            items = $items
        }
        
        $output | ConvertTo-Json -Depth $Depth -Compress:$false
    }
}

Set-Alias -Name agentjson -Value ConvertTo-AgentJson
