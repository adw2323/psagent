<#
.SYNOPSIS
    Returns DNS resolution results and hosts file as structured JSON for AI agents.

.DESCRIPTION
    Resolves hostnames to IPs, IPs to hostnames, and reads the local hosts file.
    Useful for network troubleshooting and DNS verification.

.PARAMETER Hostname
    Hostname(s) to resolve to IP addresses.

.PARAMETER IPAddress
    IP address(es) to resolve to hostnames (reverse lookup).

.PARAMETER ShowHostsFile
    Include the contents of the local hosts file.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentDns -Hostname google.com

.EXAMPLE
    Get-AgentDns -IPAddress 8.8.8.8

.EXAMPLE
    Get-AgentDns -ShowHostsFile
#>
function Get-AgentDns {
    [CmdletBinding()]
    param(
        [string[]]$Hostname,
        [string[]]$IPAddress,
        [switch]$ShowHostsFile,
        [switch]$Raw
    )

    $results = @{
        type      = 'dns_info'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        forward_lookups = @()
        reverse_lookups = @()
    }

    # Forward DNS lookups
    if ($Hostname) {
        foreach ($name in $Hostname) {
            try {
                $entries = Resolve-DnsName -Name $name -ErrorAction Stop
                $resolved = foreach ($entry in $entries) {
                    @{
                        name    = $entry.Name
                        type    = $entry.Type.ToString()
                        address = $entry.IPAddress
                        ttl     = $entry.TTL
                    }
                }
                $results.forward_lookups += @{
                    hostname   = $name
                    status     = 'success'
                    records    = @($resolved)
                }
            } catch {
                $results.forward_lookups += @{
                    hostname = $name
                    status   = 'error'
                    error    = $_.Exception.Message
                    records  = @()
                }
            }
        }
    }

    # Reverse DNS lookups
    if ($IPAddress) {
        foreach ($ip in $IPAddress) {
            try {
                $entry = Resolve-DnsName -Name $ip -ErrorAction Stop | Select-Object -First 1
                $results.reverse_lookups += @{
                    ip_address = $ip
                    status     = 'success'
                    hostname   = $entry.NameHost
                }
            } catch {
                $results.reverse_lookups += @{
                    ip_address = $ip
                    status     = 'error'
                    error      = $_.Exception.Message
                }
            }
        }
    }

    # Hosts file
    if ($ShowHostsFile) {
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        try {
            $lines = Get-Content -Path $hostsPath -ErrorAction Stop |
                Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' }

            $entries = foreach ($line in $lines) {
                $parts = $line -split '\s+'
                if ($parts.Count -ge 2) {
                    @{
                        address  = $parts[0]
                        hostname = $parts[1]
                        aliases  = @($parts[2..($parts.Count - 1)])
                    }
                }
            }
            $results.hosts_file = @{
                status  = 'success'
                path    = $hostsPath
                entries = @($entries)
            }
        } catch {
            $results.hosts_file = @{
                status = 'error'
                error  = $_.Exception.Message
                path   = $hostsPath
            }
        }
    }

    if ($Raw) { $results } else { $results | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name adns -Value Get-AgentDns
