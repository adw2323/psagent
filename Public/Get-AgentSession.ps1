<#
.SYNOPSIS
    Returns active user sessions and logon information as structured JSON.

.DESCRIPTION
    Lists logged-on users, session types, and logon details.
    Useful for multi-user systems and remote access monitoring.

.PARAMETER IncludeDisconnected
    Include disconnected sessions.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentSession

.EXAMPLE
    Get-AgentSession -IncludeDisconnected

.NOTES
    Uses both query and Get-CimInstance for comprehensive session data.
#>
function Get-AgentSession {
    [CmdletBinding()]
    param(
        [switch]$IncludeDisconnected,
        [switch]$Raw
    )

    $sessions = @()

    try {
        # Get session info via CIM
        $cimSessions = Get-CimInstance -ClassName Win32_LoggedOnUser -ErrorAction SilentlyContinue
        $logonSessions = Get-CimInstance -ClassName Win32_LogonSession -ErrorAction SilentlyContinue

        # Build a map of logon sessions
        $logonMap = @{}
        foreach ($ls in $logonSessions) {
            $logonMap[$ls.LogonId] = @{
                logon_id = $ls.LogonId
                logon_type = $ls.LogonType
                authentication_package = $ls.AuthenticationPackage
                start_time = if ($ls.StartTime) { $ls.StartTime.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            }
        }

        # Get user info
        $users = @{}
        Get-CimInstance -ClassName Win32_UserAccount -ErrorAction SilentlyContinue | ForEach-Object {
            $users[$_.SID] = $_.Name
        }

        # Map logon sessions to users
        foreach ($cs in $cimSessions) {
            $antecedent = $cs.Antecedent
            $dependent = $cs.Dependent

            if ($antecedent -match 'Domain="(.+)",Name="(.+)"') {
                $domain = $Matches[1]
                $user = $Matches[2]
            }

            if ($dependent -match 'LogonId="(\d+)"') {
                $logonId = $Matches[1]
                if ($logonMap.ContainsKey($logonId)) {
                    $session = $logonMap[$logonId]
                    $sessions += @{
                        user = $user
                        domain = $domain
                        logon_id = $logonId
                        logon_type = $session.logon_type
                        authentication_package = $session.authentication_package
                        start_time = $session.start_time
                    }
                }
            }
        }
    } catch {
        # Fallback to query command
        try {
            $queryOutput = query user 2>&1
            foreach ($line in $queryOutput) {
                if ($line -match '^\s*(\S+)\s+(\S+)\s+(\d+)\s+(\S+)') {
                    $sessions += @{
                        user = $Matches[1]
                        session_name = $Matches[2]
                        session_id = [int]$Matches[3]
                        state = $Matches[4]
                        logon_type = 'unknown'
                    }
                }
            }
        } catch { }
    }

    # Deduplicate
    $uniqueSessions = $sessions | Sort-Object user, logon_id -Unique

    $result = @{
        type = 'user_sessions'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_sessions = $uniqueSessions.Count
        sessions = @($uniqueSessions)
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name ases -Value Get-AgentSession
