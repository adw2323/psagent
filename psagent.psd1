@{
    RootModule = 'psagent.psm1'
    ModuleVersion = '0.3.0'
    GUID = 'c6162bb8-d5c1-48a5-80d3-fe69530bb89d'
    Author = 'Nexum Router by Dialagram'
    CompanyName = 'Dialagram'
    Copyright = '(c) 2026 Dialagram. All rights reserved.'
    Description = 'Structured data provider for AI agents — PowerShell functions returning JSON instead of human-formatted text.'
    
    # Minimum version of the PowerShell engine required
    PowerShellVersion = '5.1'
    
    # Modules to import as nested modules
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # File inspection
        'Get-AgentChildItem',
        'Get-AgentFile',
        'Find-AgentPattern',
        
        # System
        'Get-AgentProcess',
        'Get-AgentService',
        'Get-AgentDisk',
        'Get-AgentNetwork',
        'Get-AgentPort',
        'Get-AgentEnvironment',
        'Get-AgentToolVersion',
        'Get-AgentSystemInfo',
        'Get-AgentUser',
        'Get-AgentStartup',
        
        # Search
        'Find-AgentRipgrep',
        'Compare-AgentDiff',
        'Measure-AgentWordCount',
        
        # Git
        'Get-AgentGitStatus',
        'Get-AgentGitLog',
        'Get-AgentGitDiff',
        
        # Security
        'Get-AgentSecurityAudit',
        'Get-AgentScheduledTask',
        'Get-AgentEventLog',
        'Get-AgentFirewall',
        'Get-AgentDefender',
        'Get-AgentHotfix',
        
        # Network
        'Get-AgentDns',
        
        # Output
        'ConvertTo-AgentJson'
    )
    
    # Aliases to export from this module
    AliasesToExport = @(
        'al',      # Get-AgentChildItem
        'af',      # Get-AgentFile
        'ag',      # Find-AgentPattern
        'arg',     # Find-AgentRipgrep
        'ap',      # Get-AgentProcess
        'as',      # Get-AgentService
        'ad',      # Get-AgentDisk
        'an',      # Get-AgentNetwork
        'apo',     # Get-AgentPort
        'aenv',    # Get-AgentEnvironment
        'atv',     # Get-AgentToolVersion
        'asi',     # Get-AgentSystemInfo
        'ausr',    # Get-AgentUser
        'asu',     # Get-AgentStartup
        'adiff',   # Compare-AgentDiff
        'awc',     # Measure-AgentWordCount
        'ags',     # Get-AgentGitStatus
        'agl',     # Get-AgentGitLog
        'agd',     # Get-AgentGitDiff
        'asa',     # Get-AgentSecurityAudit
        'ast',     # Get-AgentScheduledTask
        'ael',     # Get-AgentEventLog
        'afw',     # Get-AgentFirewall
        'adf',     # Get-AgentDefender
        'ahf',     # Get-AgentHotfix
        'adns',    # Get-AgentDns
        'agentjson' # ConvertTo-AgentJson
    )
    
    # Private functions to import
    ScriptsToProcess = @(
        'Public/ConvertTo-AgentJson.ps1',
        'Private/Format-FileSize.ps1',
        'Private/Get-Language.ps1',
        'Private/Get-MIMEType.ps1'
    )
    
    # Module private data
    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Agent', 'Structured', 'JSON', 'System', 'DevOps')
            LicenseUri = 'https://github.com/adw2323/psagent/blob/main/LICENSE'
            ProjectUri = 'https://github.com/adw2323/psagent'
            IconUri = ''
            ReleaseNotes = 'v0.3.0 - Added SystemInfo, User, Startup, Hotfix, Dns functions'
        }
    }
}
