@{
    RootModule        = 'psagent.psm1'
    ModuleVersion     = '0.6.0'
    GUID              = 'c6162bb8-d5c1-48a5-80d3-fe69530bb89d'
    Author            = 'Nexum Router by Dialagram'
    CompanyName       = 'Dialagram'
    Copyright         = '(c) 2026 Dialagram. All rights reserved.'
    Description       = 'Structured data provider for AI agents — PowerShell functions returning JSON instead of human-formatted text.'

    PowerShellVersion = '5.1'
    NestedModules     = @()

    FunctionsToExport = @(
        # File inspection
        'Get-AgentChildItem'
        'Get-AgentFile'
        'Find-AgentPattern'

        # System
        'Get-AgentProcess'
        'Get-AgentService'
        'Get-AgentDisk'
        'Get-AgentNetwork'
        'Get-AgentPort'
        'Get-AgentEnvironment'
        'Get-AgentToolVersion'
        'Get-AgentSystemInfo'
        'Get-AgentUser'
        'Get-AgentStartup'
        'Get-AgentSession'
        'Get-AgentNetworkConfig'

        # Search
        'Find-AgentRipgrep'
        'Compare-AgentDiff'
        'Measure-AgentWordCount'

        # Git
        'Get-AgentGitStatus'
        'Get-AgentGitLog'
        'Get-AgentGitDiff'

        # Security
        'Get-AgentSecurityAudit'
        'Get-AgentScheduledTask'
        'Get-AgentEventLog'
        'Get-AgentFirewall'
        'Get-AgentDefender'
        'Get-AgentHotfix'
        'Get-AgentDefenderScan'

        # Network
        'Get-AgentDns'

        # Software & Configuration
        'Get-AgentInstalledSoftware'
        'Get-AgentWindowsFeature'
        'Get-AgentCertificate'
        'Get-AgentRegistry'

        # Clipboard
        'Get-AgentClipboard'

        # New functions
        'Get-AgentWindowsUpdate'
        'Get-AgentGroupPolicy'
        'Get-AgentMappedDrive'
        'Get-AgentBatteryHealth'
        'Get-AgentSecureBoot'
        'Get-AgentBitLocker'
        'Get-AgentPerformanceCounter'

        # Output
        'ConvertTo-AgentJson'
    )

    AliasesToExport = @(
        'al'        # Get-AgentChildItem
        'af'        # Get-AgentFile
        'ag'        # Find-AgentPattern
        'arg'       # Find-AgentRipgrep
        'ap'        # Get-AgentProcess
        'as'        # Get-AgentService
        'ad'        # Get-AgentDisk
        'an'        # Get-AgentNetwork
        'apo'       # Get-AgentPort
        'aenv'      # Get-AgentEnvironment
        'atv'       # Get-AgentToolVersion
        'asi'       # Get-AgentSystemInfo
        'ausr'      # Get-AgentUser
        'asu'       # Get-AgentStartup
        'ases'      # Get-AgentSession
        'ancfg'     # Get-AgentNetworkConfig
        'adiff'     # Compare-AgentDiff
        'awc'       # Measure-AgentWordCount
        'ags'       # Get-AgentGitStatus
        'agl'       # Get-AgentGitLog
        'agd'       # Get-AgentGitDiff
        'asa'       # Get-AgentSecurityAudit
        'ast'       # Get-AgentScheduledTask
        'ael'       # Get-AgentEventLog
        'afw'       # Get-AgentFirewall
        'adf'       # Get-AgentDefender
        'ahf'       # Get-AgentHotfix
        'adns'      # Get-AgentDns
        'asw'       # Get-AgentInstalledSoftware
        'awf'       # Get-AgentWindowsFeature
        'acert'     # Get-AgentCertificate
        'areg'      # Get-AgentRegistry
        'aclip'     # Get-AgentClipboard
        'awup'      # Get-AgentWindowsUpdate
        'agpol'     # Get-AgentGroupPolicy
        'amap'      # Get-AgentMappedDrive
        'abat'      # Get-AgentBatteryHealth
        'asboot'    # Get-AgentSecureBoot
        'ablock'    # Get-AgentBitLocker
        'aperf'     # Get-AgentPerformanceCounter
        'adscan'    # Get-AgentDefenderScan
        'agentjson' # ConvertTo-AgentJson
    )

    ScriptsToProcess = @(
        'Public/ConvertTo-AgentJson.ps1'
        'Private/Format-FileSize.ps1'
        'Private/Get-Language.ps1'
        'Private/Get-MIMEType.ps1'
    )

    PrivateData      = @{
        PSData = @{
            Tags       = @('AI', 'Agent', 'Structured', 'JSON', 'System', 'DevOps')
            LicenseUri = 'https://github.com/adw2323/psagent/blob/main/LICENSE'
            ProjectUri = 'https://github.com/adw2323/psagent'
            IconUri    = ''
            ReleaseNotes = 'v0.6.0 - Added WindowsUpdate, DefenderScan, GroupPolicy, MappedDrive, BatteryHealth, SecureBoot, BitLocker, PerformanceCounter'
        }
    }
}
