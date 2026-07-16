@{
    RootModule = 'psagent.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c6162bb8-d5c1-48a5-80d3-fe69530bb89d'
    Author = 'Nexum Router by Dialagram'
    Description = 'Structured data provider for AI agents on Windows'
    PowerShellVersion = '5.1'
    
    # Exported cmdlets
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
        
        # Search
        'Find-AgentRipgrep',
        'Compare-AgentDiff',
        'Measure-AgentWordCount',
        
        # Git
        'Get-AgentGitStatus',
        'Get-AgentGitLog',
        'Get-AgentGitDiff',
        
        # Output
        'ConvertTo-AgentJson'
    )
    
    # Aliases
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
        'adiff',   # Compare-AgentDiff
        'awc',     # Measure-AgentWordCount
        'ags',     # Get-AgentGitStatus
        'agl',     # Get-AgentGitLog
        'agd'      # Get-AgentGitDiff
    )
    
    # Private functions
    ScriptsToProcess = @(
        'Private/ConvertTo-AgentJson.ps1',
        'Private/Get-Language.ps1',
        'Private/Get-MIMEType.ps1'
    )
}
