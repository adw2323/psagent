<#
.SYNOPSIS
    Gets Secure Boot status as structured JSON.

.DESCRIPTION
    Retrieves Secure Boot configuration and status.
    Returns structured JSON for AI agents to parse.

.EXAMPLE
    Get-AgentSecureBoot

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.5.0
#>
function Get-AgentSecureBoot {
    [CmdletBinding()]
    param()

    try {
        # Get Secure Boot status
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue

        # Get UEFI certificate information
        $dbInfo = $null
        $kekInfo = $null
        
        try {
            $dbBytes = (Get-SecureBootUEFI -Name db -ErrorAction Stop).Bytes
            $dbInfo = [System.Text.Encoding]::ASCII.GetString($dbBytes)
        }
        catch {
            $dbInfo = 'Unable to read db store'
        }

        try {
            $kekBytes = (Get-SecureBootUEFI -Name KEK -ErrorAction Stop).Bytes
            $kekInfo = [System.Text.Encoding]::ASCII.GetString($kekBytes)
        }
        catch {
            $kekInfo = 'Unable to read KEK store'
        }

        # Check for Windows UEFI CA 2023
        $hasWindowsUEFICA2023 = $dbInfo -match 'Windows UEFI CA 2023'
        $hasKEK2KCA2023 = $kekInfo -match 'KEK 2K CA 2023'

        # Get last boot time
        $lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime

        # Build the result
        $result = @{
            Type        = 'SecureBoot'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            Status      = @{
                SecureBootEnabled    = $secureBoot
                IsUEFI               = $true
                LastBootTime         = if ($lastBoot) { $lastBoot.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            }
            Certificates = @{
                HasWindowsUEFICA2023 = $hasWindowsUEFICA2023
                HasKEK2KCA2023       = $hasKEK2KCA2023
                DBStoreReadable      = $dbInfo -ne 'Unable to read db store'
                KEKStoreReadable     = $kekInfo -ne 'Unable to read KEK store'
            }
            Summary     = @{
                IsSecure           = $secureBoot -eq $true
                HasRequiredCerts   = $hasWindowsUEFICA2023 -and $hasKEK2KCA2023
                SecurityLevel      = if ($secureBoot -and $hasWindowsUEFICA2023 -and $hasKEK2KCA2023) {
                    'Enhanced'
                } elseif ($secureBoot) {
                    'Standard'
                } else {
                    'None'
                }
            }
        }

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'SecureBoot'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
            Status      = @{
                SecureBootEnabled = $false
                IsUEFI            = $false
            }
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
