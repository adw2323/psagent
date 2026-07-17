<#
.SYNOPSIS
    Returns detailed network adapter configuration as structured JSON.

.DESCRIPTION
    Provides comprehensive network configuration including IP addresses,
    DNS servers, gateways, DHCP status, and adapter properties.
    More detailed than Get-AgentNetwork (connections) and Get-AgentDns (DNS only).

.PARAMETER AdapterName
    Filter by specific adapter name.

.PARAMETER IncludeIPv6
    Include IPv6 addresses. Default: false.

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentNetworkConfig

.EXAMPLE
    Get-AgentNetworkConfig -AdapterName "Ethernet"

.NOTES
    Equivalent to ipconfig /all but in structured JSON.
#>
function Get-AgentNetworkConfig {
    [CmdletBinding()]
    param(
        [string]$AdapterName,
        [switch]$IncludeIPv6,
        [switch]$Raw
    )

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' }

    if ($AdapterName) {
        $adapters = $adapters | Where-Object { $_.Name -like "*$AdapterName*" }
    }

    $adapterList = @()

    foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        $ipAddresses = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue

        $addresses = @()
        foreach ($ip in $ipAddresses) {
            if (-not $IncludeIPv6 -and $ip.AddressFamily -eq 'IPv6') { continue }
            $addresses += @{
                address = $ip.IPAddress
                prefix_length = $ip.PrefixLength
                address_family = $ip.AddressFamily.ToString()
            }
        }

        # Get DNS servers
        $dnsServers = @()
        try {
            $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            foreach ($d in $dns) {
                if (-not $IncludeIPv6 -and $d.AddressFamily -eq 'IPv6') { continue }
                $dnsServers += $d.ServerAddresses
            }
        } catch { }

        # Get gateway
        $gateway = $null
        if ($ipConfig) {
            $gateway = $ipConfig.IPv4DefaultGateway.NextHop
        }

        $adapterInfo = @{
            name = $adapter.Name
            interface_description = $adapter.InterfaceDescription
            mac_address = $adapter.MacAddress
            link_speed = $adapter.LinkSpeed
            status = $adapter.Status
            if_index = $adapter.InterfaceIndex
            addresses = @($addresses)
            dns_servers = @($dnsServers)
            gateway = $gateway
            dhcp_enabled = $adapter.DhcpEnabled
            driver_version = $adapter.DriverVersion
            driver_date = if ($adapter.DriverDate) { try { $adapter.DriverDate.ToString('yyyy-MM-dd') } catch { $null } } else { $null }
        }

        $adapterList += $adapterInfo
    }

    # Also get adapter properties from ipconfig-style output
    $ipconfig = Get-NetIPConfiguration -ErrorAction SilentlyContinue
    $allAdapters = @()
    foreach ($ic in $ipconfig) {
        if ($ic.NetIPv4Interface.IPAddress) {
            $allAdapters += @{
                name = $ic.InterfaceAlias
                status = $ic.NetIPv4Interface.ConnectionState.ToString()
                ipv4_address = @($ic.NetIPv4Interface.IPAddress | Where-Object { $_ -notmatch ':' })
                subnet = $ic.NetIPv4Interface.PrefixLength
                gateway = $ic.IPv4DefaultGateway.NextHop
                dns = @($ic.DNSServer.ServerAddresses | Where-Object { $_ -notmatch ':' })
            }
        }
    }

    $result = @{
        type = 'network_config'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        active_adapters = @($adapterList)
        all_interfaces = @($allAdapters)
        total_active = $adapterList.Count
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name ancfg -Value Get-AgentNetworkConfig
