# Get-AgentFirewall.ps1 - Returns Windows Firewall rules as structured JSON

function Get-AgentFirewall {
    <#
    .SYNOPSIS
    Returns Windows Firewall rules as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns firewall information including:
    - Firewall profile status (Domain, Private, Public)
    - Inbound rules
    - Outbound rules
    - Rule properties (name, direction, action, protocol, ports)
    
    .PARAMETER Direction
    Filter by direction: Inbound or Outbound.
    
    .PARAMETER Action
    Filter by action: Allow or Block.
    
    .PARAMETER Enabled
    Filter by enabled status: true or false.
    
    .PARAMETER Profile
    Filter by profile: Domain, Private, Public, or Any.
    
    .PARAMETER MaxRules
    Maximum number of rules to return (default: 100).
    
    .PARAMETER Raw
    Output as raw PowerShell hashtable instead of JSON.
    
    .EXAMPLE
    Get-AgentFirewall
    
    .EXAMPLE
    Get-AgentFirewall -Direction Inbound -Action Allow
    
    .EXAMPLE
    Get-AgentFirewall -Profile Domain -Enabled $true
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Inbound', 'Outbound')]
        [string]$Direction,
        
        [ValidateSet('Allow', 'Block')]
        [string]$Action,
        
        [bool]$Enabled,
        
        [ValidateSet('Domain', 'Private', 'Public', 'Any')]
        [string]$Profile,
        
        [int]$MaxRules = 100,
        
        [switch]$Raw
    )
    
    try {
        # Get firewall profiles
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
        
        $profileStatus = @()
        foreach ($p in $profiles) {
            $profileStatus += @{
                name = $p.Name
                enabled = $p.Enabled
                default_inbound_action = $p.DefaultInboundAction.ToString()
                default_outbound_action = $p.DefaultOutboundAction.ToString()
            }
        }
        
        # Build filter parameters for rules
        $params = @{}
        
        if ($Direction) {
            $params['Direction'] = $Direction
        }
        
        if ($Action) {
            $params['Action'] = $Action
        }
        
        if ($PSBoundParameters.ContainsKey('Enabled')) {
            $params['Enabled'] = if ($Enabled) { 'True' } else { 'False' }
        }
        
        if ($Profile -and $Profile -ne 'Any') {
            $params['Profile'] = $Profile
        }
        
        # Get firewall rules
        $rules = Get-NetFirewallRule @params -ErrorAction Stop | Select-Object -First $MaxRules
        
        $inboundRules = @()
        $outboundRules = @()
        
        foreach ($rule in $rules) {
            $ruleInfo = @{
                name = $rule.Name
                display_name = $rule.DisplayName
                description = if ($rule.Description.Length -gt 200) {
                    $rule.Description.Substring(0, 200) + "..."
                } else {
                    $rule.Description
                }
                direction = $rule.Direction.ToString()
                action = $rule.Action.ToString()
                enabled = $rule.Enabled
                profile = $rule.Profile.ToString()
                group = $rule.Group
                program = $rule.Program
                service = $rule.Service
            }
            
            # Get port filter if available
            try {
                $portFilter = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
                if ($portFilter) {
                    $ruleInfo.protocol = $portFilter.Protocol
                    $ruleInfo.local_port = $portFilter.LocalPort
                    $ruleInfo.remote_port = $portFilter.RemotePort
                }
            } catch {
                # Port filter not available
            }
            
            # Get address filter if available
            try {
                $addressFilter = $rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
                if ($addressFilter) {
                    $ruleInfo.local_address = $addressFilter.LocalAddress
                    $ruleInfo.remote_address = $addressFilter.RemoteAddress
                }
            } catch {
                # Address filter not available
            }
            
            if ($rule.Direction -eq 'Inbound') {
                $inboundRules += $ruleInfo
            } else {
                $outboundRules += $ruleInfo
            }
        }
        
        $output = @{
            type = 'firewall_rules'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            profiles = @($profileStatus)
            total_rules = $rules.Count
            inbound_rules = @($inboundRules)
            outbound_rules = @($outboundRules)
        }
        
        if ($Raw) {
            return $output
        } else {
            return $output | ConvertTo-Json -Depth 10
        }
        
    } catch {
        $errorOutput = @{
            type = 'firewall_rules'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            error = $_.Exception.Message
            profiles = @()
            inbound_rules = @()
            outbound_rules = @()
            total_rules = 0
        }
        
        if ($Raw) {
            return $errorOutput
        } else {
            return $errorOutput | ConvertTo-Json -Depth 10
        }
    }
}

Set-Alias -Name afw -Value Get-AgentFirewall
