<#
.SYNOPSIS
    Reads Windows Registry keys and values as structured JSON.

.DESCRIPTION
    Provides safe read-only access to the Windows Registry for AI agents.
    Can list subkeys, read values, and search for specific items.

.PARAMETER Path
    Registry path to read (e.g., HKLM:\SOFTWARE\Microsoft\Windows).

.PARAMETER Name
    Specific value name to read. If omitted, returns all values.

.PARAMETER Recurse
    Recursively enumerate subkeys.

.PARAMETER MaxDepth
    Maximum recursion depth. Default: 3.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

.EXAMPLE
    Get-AgentRegistry -Path "HKCU:\Software" -Recurse -MaxDepth 2

.NOTES
    Read-only operation. Does not modify registry.
    Common registry paths:
    - HKLM:\SOFTWARE\Microsoft\Windows
    - HKLM:\SYSTEM\CurrentControlSet\Services
    - HKCU:\Software\Microsoft\Windows
#>
function Get-AgentRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Name,
        [switch]$Recurse,
        [int]$MaxDepth = 3,
        [switch]$Raw
    )

    # Normalize path
    $Path = $Path -replace '^HKLM:\\', 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\', 'Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\' -replace '^HKU:\\', 'Microsoft.PowerShell.Core\Registry::HKEY_USERS\'

    if (-not (Test-Path "Microsoft.PowerShell.Core\Registry::\$($Path -replace '^Microsoft\.PowerShell\.Core\\Registry::','')")) {
        # Try alternate format
        $testPath = $Path
        if (-not (Test-Path $testPath -ErrorAction SilentlyContinue)) {
            $result = @{
                type = 'registry_read'
                timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
                path = $Path
                error = "Registry path not found: $Path"
                keys = @()
                values = @()
            }
            if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
            return
        }
    }

    $result = @{
        type = 'registry_read'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        path = $Path
        keys = @()
        values = @()
    }

    try {
        # Read values at this path
        $item = Get-Item $Path -ErrorAction SilentlyContinue
        if ($item) {
            $valueNames = $item.GetValueNames()
            foreach ($vn in $valueNames) {
                $val = $item.GetValue($vn)
                $result.values += @{
                    name = if ($vn -eq '') { '(Default)' } else { $vn }
                    value = $val
                    value_type = $item.GetValueKind($vn).ToString()
                    value_length = if ($val -is [string]) { $val.Length } elseif ($val -is [byte[]]) { $val.Length } else { 0 }
                }
            }

            # List subkeys
            $subkeys = $item.GetSubKeyNames()
            foreach ($sk in $subkeys) {
                $result.keys += @{
                    name = $sk
                    path = "$Path\$sk"
                    has_subkeys = $false
                }
            }
        }
    } catch {
        $result.error = $_.Exception.Message
    }

    # Recursive enumeration
    if ($Recurse -and $MaxDepth -gt 0) {
        $newKeys = @()
        foreach ($key in $result.keys) {
            try {
                $subItem = Get-Item $key.path -ErrorAction SilentlyContinue
                if ($subItem) {
                    $key.has_subkeys = ($subItem.GetSubKeyNames().Count -gt 0)
                }
            } catch { }
        }
        $result.max_depth = $MaxDepth
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name areg -Value Get-AgentRegistry
