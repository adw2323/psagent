<#
.SYNOPSIS
    Returns local user accounts and groups as structured JSON for AI agents.

.DESCRIPTION
    Lists local user accounts, their properties, and group memberships.
    Useful for access auditing and user management tasks.

.PARAMETER IncludeGroups
    Include local group information. Default: true.

.PARAMETER IncludeMembers
    Include group membership details. Default: true.

.PARAMETER UserName
    Filter to a specific user account.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentUser

.EXAMPLE
    Get-AgentUser -UserName Administrator
#>
function Get-AgentUser {
    [CmdletBinding()]
    param(
        [switch]$IncludeGroups = $true,
        [switch]$IncludeMembers = $true,
        [string]$UserName,
        [switch]$Raw
    )

    # Get local users
    $params = @{}
    if ($UserName) { $params['Name'] = $UserName }

    $users = Get-LocalUser @params -ErrorAction SilentlyContinue

    $userList = foreach ($u in $users) {
        $groups = @()
        if ($IncludeMembers) {
            try {
                $groups = @((Get-LocalGroup -MemberOf $u -ErrorAction SilentlyContinue).Name)
            } catch { }
        }
        @{
            name         = $u.Name
            enabled      = $u.Enabled
            last_logon   = if ($u.LastLogon) { $u.LastLogon.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            password_set = $u.PasswordSet
            password_expires = if ($u.PasswordExpires) { $u.PasswordExpires.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            last_password_change = if ($u.PasswordLastSet) { $u.PasswordLastSet.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
            description  = $u.Description
            sid          = $u.SID.Value
            may_change_password = $u.MayChangePassword
            is_system_account = $u.SystemAccount
            profile_path = $u.PrincipalSource.ToString()
            member_of    = $groups
        }
    }

    # Get local groups
    $groupList = @()
    if ($IncludeGroups) {
        $groups = Get-LocalGroup -ErrorAction Stop
        $groupList = foreach ($g in $groups) {
            $members = @()
            if ($IncludeMembers) {
                try {
                    $members = @((Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue).Name)
                } catch { }
            }
            @{
                name        = $g.Name
                description = $g.Description
                sid         = $g.SID.Value
                members     = $members
            }
        }
    }

    $output = @{
        type       = 'user_info'
        timestamp  = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        total_users = $userList.Count
        total_groups = $groupList.Count
        users      = @($userList)
        groups     = @($groupList)
    }

    if ($Raw) { $output } else { $output | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name ausr -Value Get-AgentUser
