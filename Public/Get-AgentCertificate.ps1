<#
.SYNOPSIS
    Returns certificates from the Windows certificate store as structured JSON.

.DESCRIPTION
    Lists certificates with details useful for security auditing.
    Can filter by store, expiration status, and issuer.

.PARAMETER Store
    Certificate store to query. Default: LocalMachine\My.
    Common stores: LocalMachine\My, LocalMachine\Root, CurrentUser\My

.PARAMETER ExpiredOnly
    Show only expired certificates.

.PARAMETER ExpiringSoonDays
    Show certificates expiring within N days.

.PARAMETER FilterIssuer
    Filter by issuer name (partial match).

.PARAMETER Raw
    Output the raw PowerShell hashtable instead of JSON.

.EXAMPLE
    Get-AgentCertificate

.EXAMPLE
    Get-AgentCertificate -ExpiringSoonDays 30

.EXAMPLE
    Get-AgentCertificate -Store "LocalMachine\Root" -FilterIssuer "Microsoft"
#>
function Get-AgentCertificate {
    [CmdletBinding()]
    param(
        [string]$Store = 'LocalMachine\My',
        [switch]$ExpiredOnly,
        [int]$ExpiringSoonDays,
        [string]$FilterIssuer,
        [switch]$Raw
    )

    $certs = @()

    try {
        $certCollection = Get-ChildItem -Path "Cert:\$Store" -ErrorAction Stop

        foreach ($cert in $certCollection) {
            $certInfo = @{
                subject = $cert.Subject
                issuer = $cert.Issuer
                thumbprint = $cert.Thumbprint
                serial_number = $cert.SerialNumber
                not_before = $cert.NotBefore.ToString('yyyy-MM-ddTHH:mm:ss')
                not_after = $cert.NotAfter.ToString('yyyy-MM-ddTHH:mm:ss')
                has_private_key = $cert.HasPrivateKey
                is_valid = $cert.Verify()
                version = $cert.Version
                signature_algorithm = $cert.SignatureAlgorithm.FriendlyName
                friendly_name = $cert.FriendlyName
                store = $Store
                days_until_expiry = ([math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays))
            }

            # Extract SAN if available
            try {
                $san = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' }
                if ($san) {
                    $certInfo.subject_alt_names = $san.Format($false)
                }
            } catch { }

            $certs += $certInfo
        }
    } catch {
        $result = @{
            type = 'certificate_store'
            timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            store = $Store
            error = $_.Exception.Message
            certificates = @()
            total_certs = 0
        }
        if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
        return
    }

    # Apply filters
    if ($ExpiredOnly) {
        $certs = $certs | Where-Object { -not $_.is_valid }
    }

    if ($ExpiringSoonDays -gt 0) {
        $cutoff = (Get-Date).AddDays($ExpiringSoonDays)
        $certs = $certs | Where-Object { $_.not_after -le $cutoff.ToString('yyyy-MM-ddTHH:mm:ss') }
    }

    if ($FilterIssuer) {
        $certs = $certs | Where-Object { $_.issuer -like "*$FilterIssuer*" }
    }

    $result = @{
        type = 'certificate_store'
        timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        store = $Store
        total_certs = $certs.Count
        certificates = @($certs)
    }

    if ($Raw) { $result } else { $result | ConvertTo-Json -Depth 10 }
}

Set-Alias -Name acert -Value Get-AgentCertificate
