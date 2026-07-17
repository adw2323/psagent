# Get-AgentSecurityAudit.ps1 - Returns Windows security audit information as structured JSON

function Get-AgentSecurityAudit {
    <#
    .SYNOPSIS
    Returns Windows security audit information as structured JSON for AI agents.
    
    .DESCRIPTION
    Returns security information including:
    - Firewall status
    - Windows Defender status
    - User account control settings
    - Password policy
    - Audit policy
    - Recent security events
    
    .EXAMPLE
    Get-AgentSecurityAudit
    #>
    [CmdletBinding()]
    param(
        [switch]$Raw
    )
    
    $results = @{
        firewall = @{}
        defender = @{}
        uac = @{}
        password_policy = @{}
        audit_policy = @{}
        recent_events = @()
    }
    
    # Firewall status
    try {
        $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        $results.firewall = @{
            profiles = @()
            enabled = $false
        }
        
        foreach ($profile in $firewallProfiles) {
            $results.firewall.profiles += @{
                name = $profile.Name
                enabled = $profile.Enabled
                default_inbound_action = $profile.DefaultInboundAction
                default_outbound_action = $profile.DefaultOutboundAction
            }
            if ($profile.Enabled) { $results.firewall.enabled = $true }
        }
    } catch {
        $results.firewall = @{ error = "Failed to get firewall status" }
    }
    
    # Windows Defender status
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            $results.defender = @{
                real_time_protection = $defenderStatus.RealTimeProtectionEnabled
                behavior_monitor = $defenderStatus.BehaviorMonitorEnabled
                ioav_protection = $defenderStatus.IoavProtectionEnabled
                on_access_protection = $defenderStatus.OnAccessProtectionEnabled
                antimalware_enabled = $defenderStatus.AntimalwareEnabled
                antivirus_enabled = $defenderStatus.AntivirusEnabled
                antivirus_signature_last_updated = $defenderStatus.AntivirusSignatureLastUpdated
                quick_scan_end_time = $defenderStatus.QuickScanEndTime
                full_scan_end_time = $defenderStatus.FullScanEndTime
            }
        }
    } catch {
        $results.defender = @{ error = "Failed to get Defender status" }
    }
    
    # User Account Control
    try {
        $uacKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue
        if ($uacKey) {
            $results.uac = @{
                enable_lua = [bool]$uacKey.EnableLUA
                consent_prompt_behavior_admin = $uacKey.ConsentPromptBehaviorAdmin
                prompt_on_secure_desktop = $uacKey.PromptOnSecureDesktop
                enable_secure_uac = $uacKey.EnableSecureUIAPaths
            }
        }
    } catch {
        $results.uac = @{ error = "Failed to get UAC settings" }
    }
    
    # Password policy
    try {
        $netAccounts = & net accounts 2>&1
        $results.password_policy = @{
            min_password_length = 0
            max_password_age_days = 0
            min_password_age_days = 0
            password_history_count = 0
            lockout_threshold = 0
            lockout_duration_minutes = 0
        }
        
        foreach ($line in $netAccounts) {
            if ($line -match "Minimum password length:\s+(\d+)") {
                $results.password_policy.min_password_length = [int]$Matches[1]
            }
            elseif ($line -match "Maximum password age \(days\):\s+(\d+)") {
                $results.password_policy.max_password_age_days = [int]$Matches[1]
            }
            elseif ($line -match "Minimum password age \(days\):\s+(\d+)") {
                $results.password_policy.min_password_age_days = [int]$Matches[1]
            }
            elseif ($line -match "Password history count:\s+(\d+)") {
                $results.password_policy.password_history_count = [int]$Matches[1]
            }
            elseif ($line -match "Lockout threshold:\s+(\d+)") {
                $results.password_policy.lockout_threshold = [int]$Matches[1]
            }
            elseif ($line -match "Lockout duration \(minutes\):\s+(\d+)") {
                $results.password_policy.lockout_duration_minutes = [int]$Matches[1]
            }
        }
    } catch {
        $results.password_policy = @{ error = "Failed to get password policy" }
    }
    
    # Recent security events (last 24 hours)
    try {
        $startTime = (Get-Date).AddHours(-24)
        $securityEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            StartTime = $startTime
        } -MaxEvents 50 -ErrorAction SilentlyContinue
        
        foreach ($event in $securityEvents) {
            $results.recent_events += @{
                id = $event.Id
                level = $event.LevelDisplayName
                time_created = $event.TimeCreated.ToString("yyyy-MM-ddTHH:mm:ss")
                provider_name = $event.ProviderName
                message = if ($event.Message.Length -gt 200) { 
                    $event.Message.Substring(0, 200) + "..." 
                } else { 
                    $event.Message 
                }
            }
        }
    } catch {
        $results.recent_events = @(@{ error = "Failed to get security events" })
    }
    
    # Calculate security score
    $score = 0
    $maxScore = 100
    
    # Firewall enabled (+25)
    if ($results.firewall.enabled) { $score += 25 }
    
    # Defender enabled (+25)
    if ($results.defender.real_time_protection) { $score += 25 }
    
    # UAC enabled (+15)
    if ($results.uac.enable_lua) { $score += 15 }
    
    # Password length >= 8 (+15)
    if ($results.password_policy.min_password_length -ge 8) { $score += 15 }
    
    # Lockout threshold > 0 (+10)
    if ($results.password_policy.lockout_threshold -gt 0) { $score += 10 }
    
    # No critical security events (+10)
    $criticalEvents = $results.recent_events | Where-Object { $_.level -eq "Critical" -or $_.level -eq "Error" }
    if (-not $criticalEvents) { $score += 10 }
    
    $output = @{
        type = 'security_audit'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        security_score = $score
        max_score = $maxScore
        security_score_percent = [math]::Round(($score / $maxScore) * 100)
        results = $results
    }
    
    if ($Raw) {
        $output
    } else {
        $output | ConvertTo-Json -Depth 10
    }
}

Set-Alias -Name asa -Value Get-AgentSecurityAudit
