# psagent.Tests.ps1 - Pester tests for psagent module

BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot/../psagent.psd1" -Force
}

Describe 'Get-AgentChildItem' {
    It 'Returns directory listing for C:\Windows' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Depth 0
        $result.type | Should -Be 'directory_listing'
        $result.total_entries | Should -BeGreaterThan 0
        $result.items | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured metadata' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Depth 0
        $item = $result.items[0]
        $item.name | Should -Not -BeNullOrEmpty
        $item.absolute | Should -Match '^[A-Z]:\\'
        $item.language | Should -Not -BeNullOrEmpty
        $item.mime | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by extension' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Filter '*.dll' -Depth 0
        $result.items | Should -Not -BeNullOrEmpty
        $result.items[0].extension | Should -Be '.dll'
    }
}

Describe 'Get-AgentProcess' {
    It 'Returns process list' {
        $result = Get-AgentProcess -Top 5
        $result.type | Should -Be 'process_list'
        $result.processes | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured process data' {
        $result = Get-AgentProcess -Top 1
        $proc = $result.processes[0]
        $proc.name | Should -Not -BeNullOrEmpty
        $proc.id | Should -BeGreaterThan 0
        $proc.cpu | Should -BeGreaterOrEqual 0
    }
    
    It 'Filters by name' {
        $result = Get-AgentProcess -Name 'python'
        $result.processes | Should -Not -BeNullOrEmpty
        $result.processes[0].name | Should -Match 'python'
    }
}

Describe 'Get-AgentService' {
    It 'Returns service list' {
        $result = Get-AgentService
        $result.type | Should -Be 'service_list'
        $result.services | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured service data' {
        $result = Get-AgentService -Status Running
        $result.services | Should -Not -BeNullOrEmpty
        $svc = $result.services[0]
        $svc.name | Should -Not -BeNullOrEmpty
        $svc.status | Should -Be 'Running'
    }
}

Describe 'Get-AgentDisk' {
    It 'Returns disk info' {
        $result = Get-AgentDisk
        $result.type | Should -Be 'disk_info'
        $result.drives | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured disk data' {
        $result = Get-AgentDisk
        $drive = $result.drives[0]
        $drive.name | Should -Not -BeNullOrEmpty
        $drive.total_bytes | Should -BeGreaterThan 0
    }
}

Describe 'ConvertTo-AgentJson' {
    It 'Converts object to JSON' {
        $obj = @{name = 'test'; value = 42}
        $result = $obj | ConvertTo-AgentJson
        $result | Should -Match '"type": "result"'
        $result | Should -Match '"timestamp":'
        $result | Should -Match '"count": 1'
    }
}
