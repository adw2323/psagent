# psagent.Tests.ps1 - Pester tests for psagent module

BeforeAll {
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
        $result = Get-AgentProcess -Top 5 -Raw
        $result.type | Should -Be 'process_list'
        $result.processes | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured process data' {
        $result = Get-AgentProcess -Top 5 -Raw
        $proc = $result.processes | Where-Object { $_.id -gt 0 } | Select-Object -First 1
        $proc | Should -Not -BeNullOrEmpty
        $proc.name | Should -Not -BeNullOrEmpty
        $proc.id | Should -BeGreaterThan 0
        $proc.cpu | Should -BeGreaterOrEqual 0
    }
    
    It 'Filters by name' {
        $result = Get-AgentProcess -Name 'python' -Raw
        $result.processes | Should -Not -BeNullOrEmpty
        $result.processes[0].name | Should -Match 'python'
    }
}

Describe 'Get-AgentService' {
    It 'Returns service list' {
        $result = Get-AgentService -Raw
        $result.type | Should -Be 'service_list'
        $result.services | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured service data' {
        $result = Get-AgentService -Status Running -Raw
        $result.services | Should -Not -BeNullOrEmpty
        $svc = $result.services[0]
        $svc.name | Should -Not -BeNullOrEmpty
        $svc.status | Should -Be 'Running'
    }
}

Describe 'Get-AgentDisk' {
    It 'Returns disk info' {
        $result = Get-AgentDisk -Raw
        $result.type | Should -Be 'disk_info'
        $result.drives | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured disk data' {
        $result = Get-AgentDisk -Raw
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
        $result = Get-AgentEnvironment -Raw
        $result.type | Should -Be 'environment'
        $result.vars | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured env data' {
        $result = Get-AgentEnvironment -Raw
        $var = $result.vars[0]
        $var.name | Should -Not -BeNullOrEmpty
        $var.value | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by name' {
        $result = Get-AgentEnvironment -Filter 'PATH' -Raw
        $result.vars | Should -Not -BeNullOrEmpty
        $result.vars[0].name | Should -Match 'PATH'
    }
}

Describe 'Get-AgentFile' {
    It 'Returns file info' {
        $result = Get-AgentFile -Path './psagent.psd1' -Raw
        $result.type | Should -Be 'file_info'
        $result.name | Should -Be 'psagent.psd1'
    }
    
    It 'Returns structured file data' {
        $result = Get-AgentFile -Path './psagent.psd1' -Raw
        $result.size_bytes | Should -BeGreaterThan 0
        $result.extension | Should -Be '.psd1'
        $result.language | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentNetwork' {
    It 'Returns network connections' {
        $result = Get-AgentNetwork -Raw
        $result.type | Should -Be 'network_connections'
        $result.connections | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured connection data' {
        $result = Get-AgentNetwork -Raw
        $conn = $result.connections[0]
        $conn.local_address | Should -Not -BeNullOrEmpty
        $conn.local_port | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentPort' {
    It 'Returns listening ports' {
        $result = Get-AgentPort -Raw
        $result.type | Should -Be 'port_usage'
        $result.connections | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured port data' {
        $result = Get-AgentPort -Raw
        $port = $result.connections[0]
        $port.local_port | Should -BeGreaterThan 0
        $port.local_address | Should -Not -BeNullOrEmpty
    }
}

Describe 'Find-AgentPattern' {
    It 'Finds pattern in files' {
        $result = Find-AgentPattern -Pattern 'function' -Path './Public' -Raw
        $result.type | Should -Be 'search_results'
        $result.matches | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured match data' {
        $result = Find-AgentPattern -Pattern 'function' -Path './Public' -Raw
        $match = $result.matches[0]
        $match.file | Should -Not -BeNullOrEmpty
        $match.line_number | Should -BeGreaterThan 0
        $match.line | Should -Not -BeNullOrEmpty
    }
}

Describe 'Find-AgentRipgrep' {
    It 'Finds pattern with ripgrep' {
        $result = Find-AgentRipgrep -Pattern 'function' -Path './Public' -Raw
        $result.type | Should -Be 'ripgrep_results'
        $result.matches | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured ripgrep data' {
        $result = Find-AgentRipgrep -Pattern 'function' -Path './Public' -Raw
        $match = $result.matches[0]
        $match.file | Should -Not -BeNullOrEmpty
        $match.line_number | Should -BeGreaterThan 0
    }
}

Describe 'Compare-AgentDiff' {
    It 'Compares two files' {
        $result = Compare-AgentDiff -Reference './psagent.psd1' -Difference './psagent.psm1' -Raw
        $result.type | Should -Be 'diff'
    }
}

Describe 'Measure-AgentWordCount' {
    It 'Counts words in file' {
        $result = Measure-AgentWordCount -Path './README.md' -Raw
        $result.type | Should -Be 'word_count'
        $result.total_words | Should -BeGreaterThan 0
    }
    
    It 'Returns structured word count data' {
        $result = Measure-AgentWordCount -Path './README.md' -Raw
        $result.total_lines | Should -BeGreaterThan 0
        $result.total_characters | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentGitStatus' {
    It 'Returns git status' {
        $result = Get-AgentGitStatus -Path '.' -Raw
        $result.type | Should -Be 'git_status'
    }
    
    It 'Returns structured git data' {
        $result = Get-AgentGitStatus -Path '.' -Raw
        $result.branch | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentGitLog' {
    It 'Returns git log' {
        $result = Get-AgentGitLog -Path '.' -Count 5 -Raw
        $result.type | Should -Be 'git_log'
        $result.commits | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured commit data' {
        $result = Get-AgentGitLog -Path '.' -Count 1 -Raw
        $commit = $result.commits[0]
        $commit.hash | Should -Not -BeNullOrEmpty
        $commit.message | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentGitDiff' {
    It 'Returns git diff' {
        $result = Get-AgentGitDiff -Path '.' -Raw
        $result.type | Should -Be 'git_diff'
    }
}

Describe 'Get-AgentToolVersion' {
    It 'Returns tool versions' {
        $result = Get-AgentToolVersion -Tools @('git', 'node') -Raw
        $result.type | Should -Be 'tool_versions'
        $result.tools | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured version data' {
        $result = Get-AgentToolVersion -Tools @('git') -Raw
        $tool = $result.tools[0]
        $tool.name | Should -Be 'git'
        $tool.installed | Should -Be $true
    }
}

Describe 'Get-AgentSecurityAudit' {
    It 'Returns security audit data' {
        $result = Get-AgentSecurityAudit -Raw
        $result.type | Should -Be 'security_audit'
    }
    
    It 'Returns firewall and defender status' {
        $result = Get-AgentSecurityAudit -Raw
        $result.results.firewall | Should -Not -BeNullOrEmpty
        $result.results.defender | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentScheduledTask' {
    It 'Returns scheduled tasks' {
        $result = Get-AgentScheduledTask -Raw
        $result.type | Should -Be 'scheduled_tasks'
        $result.total_tasks | Should -BeGreaterThan 0
    }
    
    It 'Returns structured task data' {
        $result = Get-AgentScheduledTask -Raw
        $task = $result.tasks[0]
        $task.task_name | Should -Not -BeNullOrEmpty
        $task.status | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentEventLog' {
    It 'Returns event log entries' {
        $result = Get-AgentEventLog -LogName System -MaxEvents 5 -Raw
        $result.type | Should -Be 'event_log'
        $result.events | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured event data' {
        $result = Get-AgentEventLog -LogName System -MaxEvents 1 -Raw
        $event = $result.events[0]
        $event.event_id | Should -BeGreaterThan 0
        $event.message | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentFirewall' {
    It 'Returns firewall rules' {
        $result = Get-AgentFirewall -Raw
        $result.type | Should -Be 'firewall_rules'
        $result.profiles | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns profile status' {
        $result = Get-AgentFirewall -Raw
        $profile = $result.profiles[0]
        $profile.name | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentDefender' {
    It 'Returns Defender status' {
        $result = Get-AgentDefender -Raw
        $result.type | Should -Be 'defender_status'
        $result.status | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns protection status' {
        $result = Get-AgentDefender -Raw
        $result.status.real_time_protection | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentSystemInfo' {
    It 'Returns system info' {
        $result = Get-AgentSystemInfo -Raw
        $result.type | Should -Be 'system_info'
        $result.hostname | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns OS and CPU details' {
        $result = Get-AgentSystemInfo -Raw
        $result.os | Should -Not -BeNullOrEmpty
        $result.os.caption | Should -Not -BeNullOrEmpty
        $result.cpu | Should -Not -BeNullOrEmpty
        $result.cpu.cores | Should -BeGreaterThan 0
    }
    
    It 'Returns uptime' {
        $result = Get-AgentSystemInfo -Raw
        $result.uptime | Should -Not -BeNullOrEmpty
        $result.uptime.total_hours | Should -BeGreaterOrEqual 0
        $result.uptime.boot_time | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns memory info' {
        $result = Get-AgentSystemInfo -Raw
        $result.total_physical_memory_gb | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentHotfix' {
    It 'Returns hotfix list' {
        $result = Get-AgentHotfix -Raw
        $result.type | Should -Be 'hotfix_list'
        $result.hotfixes | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns structured hotfix data' {
        $result = Get-AgentHotfix -MaxResults 1 -Raw
        $hf = $result.hotfixes[0]
        $hf.hotfix_id | Should -Not -BeNullOrEmpty
        $hf.description | Should -Not -BeNullOrEmpty
    }
    
    It 'Limits results' {
        $result = Get-AgentHotfix -MaxResults 3 -Raw
        $result.hotfixes.Count | Should -BeLessOrEqual 3
    }
}

Describe 'Get-AgentDns' {
    It 'Resolves hostname' {
        $result = Get-AgentDns -Hostname 'localhost' -Raw
        $result.type | Should -Be 'dns_info'
        $result.forward_lookups | Should -Not -BeNullOrEmpty
    }
    
    It 'Resolves IP address' {
        $result = Get-AgentDns -IPAddress '127.0.0.1' -Raw
        $result.reverse_lookups | Should -Not -BeNullOrEmpty
        $result.reverse_lookups[0].status | Should -Be 'success'
    }
    
    It 'Reads hosts file' {
        $result = Get-AgentDns -ShowHostsFile -Raw
        $result.hosts_file | Should -Not -BeNullOrEmpty
        $result.hosts_file.path | Should -Match 'hosts'
    }
    
    It 'Handles multiple hostnames' {
        $result = Get-AgentDns -Hostname @('localhost', '127.0.0.1') -Raw
        $result.forward_lookups.Count | Should -Be 2
    }
}

Describe 'Get-AgentStartup' {
    It 'Returns startup items' {
        $result = Get-AgentStartup -Raw
        $result.type | Should -Be 'startup_items'
        $result.total_items | Should -BeGreaterThan 0
    }
    
    It 'Returns registry entries' {
        $result = Get-AgentStartup -Raw
        $result.registry_entries | Should -Not -BeNullOrEmpty
        $entry = $result.registry_entries[0]
        $entry.name | Should -Not -BeNullOrEmpty
        $entry.command | Should -Not -BeNullOrEmpty
    }
    
    It 'Includes scheduled task starts' {
        $result = Get-AgentStartup -Raw
        # scheduled_task_starts may be empty if no tasks have boot/logon triggers
        $result.ContainsKey('scheduled_task_starts') | Should -Be $true
    }
}

Describe 'Get-AgentUser' {
    It 'Returns user list' {
        $result = Get-AgentUser -Raw
        $result.type | Should -Be 'user_info'
        $result.total_users | Should -BeGreaterThan 0
    }
    
    It 'Returns structured user data' {
        $result = Get-AgentUser -Raw
        $user = $result.users[0]
        $user.name | Should -Not -BeNullOrEmpty
        $user.sid | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns groups' {
        $result = Get-AgentUser -Raw
        $result.total_groups | Should -BeGreaterThan 0
        $group = $result.groups[0]
        $group.name | Should -Not -BeNullOrEmpty
        $group.sid | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns group memberships' {
        $result = Get-AgentUser -Raw
        # Check that the member_of property exists on user objects
        $result.users[0].ContainsKey('member_of') | Should -Be $true
    }
    
    It 'Filters by username' {
        $result = Get-AgentUser -UserName 'Guest' -Raw
        # Guest may or may not exist, so check for empty or matching
        if ($result.users.Count -gt 0) {
            $result.users[0].name | Should -Be 'Guest'
        }
    }
}

Describe 'Edge Cases' {
    It 'Get-AgentChildItem returns error for invalid path' {
        $result = Get-AgentChildItem -Path 'C:\NonExistentPath12345' -Depth 0
        $result | Should -Match 'error'
    }
    
    It 'Get-AgentFile returns error for missing file' {
        $result = Get-AgentFile -Path 'C:\NonExistent12345.txt'
        $result | Should -Match 'error'
    }
    
    It 'Find-AgentPattern returns empty for non-matching pattern' {
        $result = Find-AgentPattern -Pattern 'ZZZZZNOTFOUND12345' -Path './Public' -Raw
        $result.type | Should -Be 'search_results'
        $result.matches | Should -BeNullOrEmpty
    }
    
    It 'Get-AgentProcess handles Top 0' {
        $result = Get-AgentProcess -Top 0 -Raw
        $result.type | Should -Be 'process_list'
    }
    
    It 'ConvertTo-AgentJson wraps single object' {
        $obj = @{name = 'test'; value = 42}
        $result = $obj | ConvertTo-AgentJson
        $result | Should -Match '"type": "result"'
        $result | Should -Match '"count": 1'
    }
    
    It 'Get-AgentEnvironment filters are case-insensitive' {
        $result = Get-AgentEnvironment -Filter 'path' -Raw
        $result.vars | Should -Not -BeNullOrEmpty
    }
    
    It 'Find-AgentRipgrep handles no matches' {
        $result = Find-AgentRipgrep -Pattern 'ZZZZZNOTFOUND12345' -Path './Public' -Raw
        $result.type | Should -Be 'ripgrep_results'
    }
    
    It 'Get-AgentDisk returns usage percentage' {
        $result = Get-AgentDisk -Raw
        $drive = $result.drives | Where-Object { $_.total_bytes -gt 0 } | Select-Object -First 1
        $drive.used_percent | Should -BeGreaterOrEqual 0
        $drive.used_percent | Should -BeLessOrEqual 100
    }
    
    It 'Get-AgentSystemInfo returns timezone' {
        $result = Get-AgentSystemInfo -Raw
        $result.timezone | Should -Not -BeNullOrEmpty
    }
    
    It 'Get-AgentHotfix filters by hotfix ID' {
        $result = Get-AgentHotfix -HotfixId 'KB9999999' -Raw
        $result.hotfixes | Should -BeNullOrEmpty
    }
    
    It 'Get-AgentUser handles non-existent user' {
        $result = Get-AgentUser -UserName 'NonExistentUserXYZ123' -Raw
        $result.users | Should -BeNullOrEmpty
    }
}

Describe 'Get-AgentClipboard' {
    It 'Returns clipboard content type' {
        $result = Get-AgentClipboard -Raw
        $result.type | Should -Be 'clipboard_content'
        $result.ContainsKey('has_text') | Should -Be $true
        $result.ContainsKey('has_image') | Should -Be $true
        $result.ContainsKey('has_files') | Should -Be $true
    }
    
    It 'Can set and read clipboard' {
        $testText = "psagent test $(Get-Random)"
        Set-Clipboard -Value $testText
        Start-Sleep -Milliseconds 200
        $result = Get-AgentClipboard -Raw
        $result.has_text | Should -Be $true
        $result.text | Should -Be $testText
    }
    
    It 'Reports text length' {
        $testText = "Hello psagent $(Get-Random)"
        Set-Clipboard -Value $testText
        Start-Sleep -Milliseconds 200
        $result = Get-AgentClipboard -Raw
        $result.text_length | Should -Be $testText.Length
    }
}

Describe 'Get-AgentRegistry' {
    It 'Reads Windows version from registry' {
        $result = Get-AgentRegistry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Raw
        $result.type | Should -Be 'registry_read'
        $result.values | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns value metadata' {
        $result = Get-AgentRegistry -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Raw
        $val = $result.values | Where-Object { $_.name -eq 'ProductName' } | Select-Object -First 1
        $val | Should -Not -BeNullOrEmpty
        $val.value_type | Should -Not -BeNullOrEmpty
    }
    
    It 'Lists subkeys' {
        $result = Get-AgentRegistry -Path 'HKLM:\SOFTWARE\Microsoft\Windows' -Raw
        $result.keys | Should -Not -BeNullOrEmpty
        $result.keys.Count | Should -BeGreaterThan 0
    }
    
    It 'Returns error for invalid path' {
        $result = Get-AgentRegistry -Path 'HKLM:\NONEXISTENT\PATH\12345' -Raw
        $result.error | Should -Not -BeNullOrEmpty
    }
    
    It 'Respects MaxDepth parameter' {
        $result = Get-AgentRegistry -Path 'HKLM:\SOFTWARE\Microsoft' -Recurse -MaxDepth 1 -Raw
        $result.max_depth | Should -Be 1
    }
}

Describe 'Get-AgentInstalledSoftware' {
    It 'Returns installed software list' {
        $result = Get-AgentInstalledSoftware -Raw
        $result.type | Should -Be 'installed_software'
        $result.software | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns software metadata' {
        $result = Get-AgentInstalledSoftware -MaxResults 1 -Raw
        $sw = $result.software[0]
        $sw.name | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by name' {
        $result = Get-AgentInstalledSoftware -Filter 'Microsoft' -MaxResults 5 -Raw
        $result.filter | Should -Be 'Microsoft'
        $result.software | Should -Not -BeNullOrEmpty
    }
    
    It 'Limits results' {
        $result = Get-AgentInstalledSoftware -MaxResults 3 -Raw
        $result.software.Count | Should -BeLessOrEqual 3
    }
}

Describe 'Get-AgentSession' {
    It 'Returns session list' {
        $result = Get-AgentSession -Raw
        $result.type | Should -Be 'user_sessions'
        $result.ContainsKey('sessions') | Should -Be $true
    }
}

Describe 'Get-AgentNetworkConfig' {
    It 'Returns network configuration' {
        $result = Get-AgentNetworkConfig -Raw
        $result.type | Should -Be 'network_config'
        $result.active_adapters | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns adapter details' {
        $result = Get-AgentNetworkConfig -Raw
        $adapter = $result.active_adapters | Select-Object -First 1
        $adapter.name | Should -Not -BeNullOrEmpty
        $adapter.mac_address | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns IP addresses' {
        $result = Get-AgentNetworkConfig -Raw
        $adapter = $result.active_adapters | Where-Object { $_.addresses.Count -gt 0 } | Select-Object -First 1
        $adapter | Should -Not -BeNullOrEmpty
        $adapter.addresses[0].address | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by adapter name' {
        $result = Get-AgentNetworkConfig -AdapterName 'Ethernet' -Raw
        $result.active_adapters | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentWindowsFeature' {
    It 'Returns Windows features' {
        $result = Get-AgentWindowsFeature -Raw
        $result.type | Should -Be 'windows_features'
        $result.features | Should -Not -BeNullOrEmpty
    }
    
    It 'Filters by name' {
        $result = Get-AgentWindowsFeature -Filter 'Net' -Raw
        $result.filter | Should -Be 'Net'
        $result.features | Should -Not -BeNullOrEmpty
    }
    
    It 'Can show only installed' {
        $result = Get-AgentWindowsFeature -OnlyInstalled -Raw
        foreach ($f in $result.features) {
            $f.state | Should -Be 'Installed'
        }
    }
}

Describe 'Get-AgentCertificate' {
    It 'Returns certificate list from Root store' {
        $result = Get-AgentCertificate -Store 'LocalMachine\Root' -Raw
        $result.type | Should -Be 'certificate_store'
        $result.store | Should -Be 'LocalMachine\Root'
        $result.certificates | Should -Not -BeNullOrEmpty
    }
    
    It 'Returns certificate metadata' {
        $result = Get-AgentCertificate -Store 'LocalMachine\Root' -Raw
        $cert = $result.certificates | Select-Object -First 1
        $cert.subject | Should -Not -BeNullOrEmpty
        $cert.issuer | Should -Not -BeNullOrEmpty
        $cert.thumbprint | Should -Not -BeNullOrEmpty
        $cert.not_before | Should -Not -BeNullOrEmpty
        $cert.not_after | Should -Not -BeNullOrEmpty
        $cert.days_until_expiry | Should -BeGreaterThan 0
    }
    
    It 'Can filter by issuer' {
        $result = Get-AgentCertificate -Store 'LocalMachine\Root' -FilterIssuer 'Microsoft' -Raw
        # May or may not find results depending on system
        $result.ContainsKey('certificates') | Should -Be $true
    }
    
    It 'Returns error for invalid store' {
        $result = Get-AgentCertificate -Store 'NonExistentStore' -Raw
        $result.error | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentWindowsUpdate' {
    It 'Returns Windows Update history' {
        $result = Get-AgentWindowsUpdate -MaxResults 5 -Raw
        $result.Type | Should -Be 'WindowsUpdate'
        $result.InstalledUpdates | Should -Not -BeNullOrEmpty
    }

    It 'Returns structured update data' {
        $result = Get-AgentWindowsUpdate -MaxResults 1 -Raw
        $update = $result.InstalledUpdates[0]
        $update.HotFixID | Should -Match 'KB'
        $update.Status | Should -Be 'Installed'
    }
}

Describe 'Get-AgentDefenderScan' {
    It 'Returns Defender scan status' {
        $result = Get-AgentDefenderScan -Action GetStatus -Raw
        $result.Type | Should -Be 'DefenderScan'
        $result.Data | Should -Not -BeNullOrEmpty
    }

    It 'Returns Defender protection status' {
        $result = Get-AgentDefenderScan -Action GetStatus -Raw
        $result.Data.RealTimeProtectionEnabled | Should -Be $true
    }
}

Describe 'Get-AgentGroupPolicy' {
    It 'Returns Group Policy information' {
        $result = Get-AgentGroupPolicy -Raw
        $result.Type | Should -Be 'GroupPolicy'
        $result.ComputerPolicies | Should -Not -BeNullOrEmpty
    }

    It 'Returns policy summary' {
        $result = Get-AgentGroupPolicy -Raw
        $result.Summary.TotalComputerPolicies | Should -BeGreaterThan 0
    }
}

Describe 'Get-AgentMappedDrive' {
    It 'Returns mapped drive information' {
        $result = Get-AgentMappedDrive -Raw
        $result.Type | Should -Be 'MappedDrive'
        $result.Drives | Should -Not -BeNullOrEmpty
    }

    It 'Returns drive summary' {
        $result = Get-AgentMappedDrive -Raw
        $result.Summary.TotalDrives | Should -BeGreaterOrEqual 0
    }
}

Describe 'Get-AgentBatteryHealth' {
    It 'Returns battery health information' {
        $result = Get-AgentBatteryHealth -Raw
        $result.Type | Should -Be 'BatteryHealth'
        $result.HasBattery | Should -Be $false
    }

    It 'Returns battery status message' {
        $result = Get-AgentBatteryHealth -Raw
        $result.Status.Message | Should -Match 'No battery detected'
    }
}

Describe 'Get-AgentSecureBoot' {
    It 'Returns Secure Boot status' {
        $result = Get-AgentSecureBoot -Raw
        $result.Type | Should -Be 'SecureBoot'
        $result.Status | Should -Not -BeNullOrEmpty
    }

    It 'Returns Secure Boot enabled status' {
        $result = Get-AgentSecureBoot -Raw
        $result.Status.SecureBootEnabled | Should -Be $true
    }
}

Describe 'Get-AgentBitLocker' {
    It 'Returns BitLocker status' {
        $result = Get-AgentBitLocker -Raw
        $result.Type | Should -Be 'BitLocker'
        $result.Volumes | Should -Not -BeNullOrEmpty
    }

    It 'Returns volume summary' {
        $result = Get-AgentBitLocker -Raw
        $result.Summary.TotalVolumes | Should -BeGreaterOrEqual 0
    }
}

Describe 'Get-AgentPerformanceCounter' {
    It 'Returns performance counter data' {
        $result = Get-AgentPerformanceCounter -Raw
        $result.Type | Should -Be 'PerformanceCounter'
        $result.Counters | Should -Not -BeNullOrEmpty
    }

    It 'Returns CPU usage' {
        $result = Get-AgentPerformanceCounter -Raw
        $result.Summary.CPUUsage | Should -BeGreaterOrEqual 0
    }

    It 'Returns memory usage' {
        $result = Get-AgentPerformanceCounter -Raw
        $result.Summary.MemoryUsagePercent | Should -BeGreaterOrEqual 0
    }
}
