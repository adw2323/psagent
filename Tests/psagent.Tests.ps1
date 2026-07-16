# psagent.Tests.ps1 - Pester tests for psagent module

BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot/../psagent.psd1" -Force
}

Describe 'Get-AgentChildItem' {
    It 'Returns directory listing for C:\Windows' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Depth 0 -Raw
        $result.type | Should -Be 'directory_listing'
        $result.total_entries | Should -BeGreaterThan 0
        $result.files | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured metadata' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Depth 0 -Raw
        $item = $result.files[0]
        $item.name | Should -Not -BeNullOrEmpty
        $item.absolute | Should -Match '^[A-Z]:\\'
        $item.language | Should -Not -BeNullOrEmpty
        $item.mime | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by extension' {
        $result = Get-AgentChildItem -Path 'C:\Windows' -Filter '*.dll' -Depth 0 -Raw
        $result.files | Should -Not -BeNullOrEmpty
        $result.files[0].extension | Should -Be '.dll'
    }
}

Describe 'Get-AgentProcess' {
    It 'Returns process list' {
        $result = Get-AgentProcess -Top 5
        $result.type | Should -Be 'process_list'
        $result.processes | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured process data' {
        $result = Get-AgentProcess -Top 5
        $proc = $result.processes | Where-Object { $_.id -gt 0 } | Select-Object -First 1
        $proc | Should -Not -BeNullOrEmpty
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

Describe 'Get-AgentEnvironment' {
    It 'Returns environment variables' {
        $result = Get-AgentEnvironment
        $result.type | Should -Be 'environment'
        $result.vars | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured env data' {
        $result = Get-AgentEnvironment
        $var = $result.vars[0]
        $var.name | Should -Not -BeNullOrEmpty
        $var.value | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by name' {
        $result = Get-AgentEnvironment -Filter 'PATH'
        $result.vars | Should -Not -BeNullOrEmpty
        $result.vars[0].name | Should -Match 'PATH'
    }
}

Describe 'Get-AgentFile' {
    It 'Returns file info' {
        $result = Get-AgentFile -Path './psagent.psd1'
        $result.type | Should -Be 'file_info'
        $result.name | Should -Be 'psagent.psd1'
    }
    
    It 'Returns structured file data' {
        $result = Get-AgentFile -Path './psagent.psd1'
        $result.size_bytes | Should -BeGreaterThan 0
        $result.extension | Should -Be '.psd1'
        $result.language | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentNetwork' {
    It 'Returns network connections' {
        $result = Get-AgentNetwork
        $result.type | Should -Be 'network_connections'
        $result.connections | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured connection data' {
        $result = Get-AgentNetwork
        $conn = $result.connections[0]
        $conn.local_address | Should -Not -BeNullOrEmpty
        $conn.local_port | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentPort' {
    It 'Returns listening ports' {
        $result = Get-AgentPort
        $result.type | Should -Be 'port_usage'
        $result.connections | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured port data' {
        $result = Get-AgentPort
        $port = $result.connections[0]
        $port.local_port | Should -BeGreaterThan 0
        $port.local_address | Should -Not -BeNullOrEmpty
    }
}

Describe 'Find-AgentPattern' {
    It 'Finds pattern in files' {
        $result = Find-AgentPattern -Pattern 'function' -Path './Public'
        $result.type | Should -Be 'search_results'
        $result.matches | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured match data' {
        $result = Find-AgentPattern -Pattern 'function' -Path './Public'
        $match = $result.matches[0]
        $match.file | Should -Not -BeNullOrEmpty
        $match.line_number | Should -BeGreaterThan 0
        $match.line | Should -Not -BeNullOrEmpty
    }
}

Describe 'Find-AgentRipgrep' {
    It 'Finds pattern with ripgrep' {
        $result = Find-AgentRipgrep -Pattern 'function' -Path './Public'
        $result.type | Should -Be 'ripgrep_results'
        $result.matches | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured ripgrep data' {
        $result = Find-AgentRipgrep -Pattern 'function' -Path './Public'
        $match = $result.matches[0]
        $match.file | Should -Not -BeNullOrEmpty
        $match.line_number | Should -BeGreaterThan 0
    }
}

Describe 'Compare-AgentDiff' {
    It 'Compares two files' {
        $result = Compare-AgentDiff -Reference './psagent.psd1' -Difference './psagent.psm1'
        $result.type | Should -Be 'diff'
    }
}

Describe 'Measure-AgentWordCount' {
    It 'Counts words in file' {
        $result = Measure-AgentWordCount -Path './README.md'
        $result.type | Should -Be 'word_count'
        $result.total_words | Should -BeGreaterThan 0
    }
    
    It 'Returns structured word count data' {
        $result = Measure-AgentWordCount -Path './README.md'
        $result.total_lines | Should -BeGreaterThan 0
        $result.total_characters | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentGitStatus' {
    It 'Returns git status' {
        $result = Get-AgentGitStatus -Path '.'
        $result.type | Should -Be 'git_status'
    }
    
    It 'Returns structured git data' {
        $result = Get-AgentGitStatus -Path '.'
        $result.branch | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentGitLog' {
    It 'Returns git log' {
        $result = Get-AgentGitLog -Path '.' -Count 5
        $result.type | Should -Be 'git_log'
        $result.commits | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured commit data' {
        $result = Get-AgentGitLog -Path '.' -Count 1
        $commit = $result.commits[0]
        $commit.hash | Should -Not -BeNullOrEmpty
        $commit.message | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentGitDiff' {
    It 'Returns git diff' {
        $result = Get-AgentGitDiff -Path '.'
        $result.type | Should -Be 'git_diff'
    }
}

Describe 'Get-AgentToolVersion' {
    It 'Returns tool versions' {
        $result = Get-AgentToolVersion -Tools @('git', 'node')
        $result.type | Should -Be 'tool_versions'
        $result.tools | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured version data' {
        $result = Get-AgentToolVersion -Tools @('git')
        $tool = $result.tools[0]
        $tool.name | Should -Be 'git'
        $tool.installed | Should -Be $true
    }
}

# Edge case tests
Describe 'Edge Cases' {
    It 'Get-AgentChildItem returns error for invalid path' {
        $result = Get-AgentChildItem -Path 'C:\NonExistentPath12345' -Depth 0 -Raw
        $result | Should -Match 'error'
    }
    
    It 'Get-AgentFile returns error for missing file' {
        $result = Get-AgentFile -Path 'C:\NonExistent12345.txt'
        $result | Should -Match 'error'
    }
    
    It 'Find-AgentPattern returns empty for non-matching pattern' {
        $result = Find-AgentPattern -Pattern 'ZZZZZNOTFOUND12345' -Path './Public'
        $result.type | Should -Be 'search_results'
        $result.matches | Should -BeNullOrEmpty
    }
    
    It 'Get-AgentProcess handles Top 0' {
        $result = Get-AgentProcess -Top 0
        $result.type | Should -Be 'process_list'
    }
    
    It 'ConvertTo-AgentJson wraps single object' {
        $obj = @{name = 'test'; value = 42}
        $result = $obj | ConvertTo-AgentJson
        $result | Should -Match '"type": "result"'
        $result | Should -Match '"count": 1'
    }
    
    It 'Get-AgentEnvironment filters are case-insensitive' {
        $result = Get-AgentEnvironment -Filter 'path'
        $result.vars | Should -Not -BeNullOrEmpty
    }
    
    It 'Find-AgentRipgrep handles no matches' {
        $result = Find-AgentRipgrep -Pattern 'ZZZZZNOTFOUND12345' -Path './Public'
        $result.type | Should -Be 'ripgrep_results'
    }
    
    It 'Get-AgentDisk returns usage percentage' {
        $result = Get-AgentDisk
        $drive = $result.drives | Where-Object { $_.total_bytes -gt 0 } | Select-Object -First 1
        $drive.used_percent | Should -BeGreaterOrEqual 0
        $drive.used_percent | Should -BeLessOrEqual 100
    }
}
