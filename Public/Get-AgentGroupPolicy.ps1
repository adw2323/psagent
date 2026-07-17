<#
.SYNOPSIS
    Gets Windows Group Policy information as structured JSON.

.DESCRIPTION
    Retrieves applied Group Policy objects and settings.
    Returns structured JSON for AI agents to parse.

.PARAMETER MaxResults
    Maximum number of policies to return.

.PARAMETER Detailed
    Include detailed policy settings.

.EXAMPLE
    Get-AgentGroupPolicy

.EXAMPLE
    Get-AgentGroupPolicy -Detailed -MaxResults 5

.NOTES
    Author: Nexum Router by Dialagram
    Version: 0.6.0
#>
function Get-AgentGroupPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    try {
        # Get applied GPOs
        $gpResult = gpresult /Scope Computer -v 2>&1
        $gpResultUser = gpresult /Scope User -v 2>&1

        # Parse the output
        $result = @{
            Type        = 'GroupPolicy'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            ComputerName = $env:COMPUTERNAME
            ComputerPolicies = @()
            UserPolicies     = @()
            AppliedGPOs      = @()
            Summary          = @{
                TotalComputerPolicies = 0
                TotalUserPolicies     = 0
            }
        }

        # Parse computer policies
        $inComputerSection = $false
        $currentPolicy = $null

        foreach ($line in $gpResult) {
            if ($line -match 'Applied Group Policy Objects') {
                $inComputerSection = $true
                continue
            }
            if ($inComputerSection -and $line -match '^\s+Local Group Policy') {
                $currentPolicy = @{
                    Name = 'Local Group Policy'
                    Path = 'Local'
                    Links = @()
                }
                $result.ComputerPolicies += $currentPolicy
            }
            if ($inComputerSection -and $line -match '^\s+([\w\s\-]+Policy)') {
                $currentPolicy = @{
                    Name = $Matches[1].Trim()
                    Path = 'Active Directory'
                    Links = @()
                }
                $result.ComputerPolicies += $currentPolicy
            }
        }

        # Parse user policies
        $inUserSection = $false
        foreach ($line in $gpResultUser) {
            if ($line -match 'Applied Group Policy Objects') {
                $inUserSection = $true
                continue
            }
            if ($inUserSection -and $line -match '^\s+([\w\s\-]+Policy)') {
                $result.UserPolicies += @{
                    Name = $Matches[1].Trim()
                    Path = 'Active Directory'
                }
            }
        }

        # If detailed, get more specific information
        if ($Detailed) {
            # Get registry-based policy settings
            $registryPolicies = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -ErrorAction SilentlyContinue
            if ($registryPolicies) {
                $result.RegistryPolicies = @{}
                foreach ($prop in $registryPolicies.PSObject.Properties) {
                    if ($prop.Name -notmatch '^PS') {
                        $result.RegistryPolicies[$prop.Name] = $prop.Value
                    }
                }
            }

            # Get security settings
            $securitySettings = secedit /export /cfg "$env:TEMP\secpolicy.cfg" /areas SECURITYPOLICY 2>&1
            if ($securitySettings -match 'Successfully') {
                $securityContent = Get-Content "$env:TEMP\secpolicy.cfg" -ErrorAction SilentlyContinue
                $result.SecuritySettings = @{}
                foreach ($line in $securityContent) {
                    if ($line -match '^\s*(\w[\w\s]+)=\s*(.+)') {
                        $result.SecuritySettings[$Matches[1].Trim()] = $Matches[2].Trim()
                    }
                }
                Remove-Item "$env:TEMP\secpolicy.cfg" -Force -ErrorAction SilentlyContinue
            }
        }

        # Update summary
        $result.Summary.TotalComputerPolicies = $result.ComputerPolicies.Count
        $result.Summary.TotalUserPolicies = $result.UserPolicies.Count

        return $result | ConvertTo-Json -Depth 10
    }
    catch {
        $errorResult = @{
            Type        = 'GroupPolicy'
            Timestamp   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            Error       = $_.Exception.Message
            ErrorCode   = $_.Exception.ErrorCode
        }
        return $errorResult | ConvertTo-Json -Depth 10
    }
}
