# psagent Help Guide

## Quick Start

```powershell
# Import the module
Import-Module ./psagent.psd1

# Or from GitHub
git clone https://github.com/adw2323/psagent.git
Import-Module ./psagent/psagent.psd1
```

## Common Commands

### List Directory Contents
```powershell
# Basic listing (returns JSON)
Get-AgentChildItem -Path C:\src

# With filter
Get-AgentChildItem -Path C:\src -Filter *.ps1

# Deep listing
Get-AgentChildItem -Path C:\src -Depth 3

# Using alias
al -Path C:\src -Filter *.py -Depth 2
```

### Get File Information
```powershell
# Get file details
Get-AgentFile -Path C:\src\script.ps1

# Using alias
af C:\src\script.ps1
```

### Search Files
```powershell
# Find pattern in files
Find-AgentPattern -Pattern "function" -Path C:\src

# With filter
Find-AgentPattern -Pattern "class" -Path C:\src -Filter *.py

# Using alias
ag "function" C:\src
```

### Process Management
```powershell
# List all processes
Get-AgentProcess

# Filter by name
Get-AgentProcess -Name python

# Filter by CPU
Get-AgentProcess -MinCPU 10 -SortBy CPU -Descending

# Top 5 processes
Get-AgentProcess -Top 5

# Using alias
ap -Name node -Top 10
```

### Service Management
```powershell
# List all services
Get-AgentService

# Filter by status
Get-AgentService -Status Running

# Filter by name
Get-AgentService -Name "Windows"

# Using alias
as -Status Running
```

### Disk Information
```powershell
# Get all drives
Get-AgentDisk

# Using alias
ad
```

### Network Connections
```powershell
# List all connections
Get-AgentNetwork

# Filter by state
Get-AgentNetwork -State Established

# Filter by port
Get-AgentNetwork -LocalPort 443

# Using alias
an -State Listen
```

### Listening Ports
```powershell
# List listening ports
Get-AgentPort

# Filter by port
Get-AgentPort -LocalPort 8080

# Using alias
apo
```

### Environment Variables
```powershell
# List all variables
Get-AgentEnvironment

# Filter by name
Get-AgentEnvironment -Filter PATH

# Using alias
aenv -Filter JAVA
```

### Tool Versions
```powershell
# Check specific tools
Get-AgentToolVersion -Tools @('git', 'node', 'python')

# Using alias
atv -Tools @('git', 'docker')
```

### File Search (Ripgrep)
```powershell
# Fast regex search
Find-AgentRipgrep -Pattern "function" -Path C:\src

# With filter
Find-AgentRipgrep -Pattern "TODO" -Path C:\src -Filter *.py

# Using alias
arg "TODO" C:\src
```

### File Comparison
```powershell
# Compare two files
Compare-AgentDiff -Reference file1.txt -Difference file2.txt

# Using alias
adiff file1.txt file2.txt
```

### Word Count
```powershell
# Count words in file
Measure-AgentWordCount -Path README.md

# Recursive count
Measure-AgentWordCount -Path C:\src -Recurse

# Using alias
awc README.md
```

### Git Operations
```powershell
# Git status
Get-AgentGitStatus -Path C:\myrepo

# Git log
Get-AgentGitLog -Path C:\myrepo -Count 10

# Git diff
Get-AgentGitDiff -Path C:\myrepo

# Using aliases
ags C:\myrepo
agl C:\myrepo -Count 5
agd C:\myrepo
```

### JSON Output
```powershell
# Convert object to JSON
@{name = "test"; value = 42} | ConvertTo-AgentJson
```

## Output Format

All functions return structured JSON with:

```json
{
  "type": "function_name",
  "timestamp": 1234567890,
  ...function-specific data...
}
```

### Example: Get-AgentChildItem
```json
{
  "type": "directory_listing",
  "timestamp": 1234567890,
  "path": "C:\\src",
  "total_entries": 15,
  "files": [
    {
      "name": "script.ps1",
      "absolute": "C:\\src\\script.ps1",
      "size_bytes": 1024,
      "size_human": "1.0KB",
      "language": "powershell",
      "mime": "application/x-powershell",
      "extension": ".ps1",
      "is_dir": false,
      "modified": 1234567890,
      "modified_ago_s": 3600,
      "readable": true
    }
  ],
  "directories": [...]
}
```

### Example: Get-AgentProcess
```json
{
  "type": "process_list",
  "timestamp": 1234567890,
  "total_processes": 150,
  "processes": [
    {
      "name": "powershell",
      "id": 1234,
      "cpu": 12.5,
      "memory_working_set": 104857600,
      "memory_working_set_human": "100.0MB",
      "threads": 10,
      "handles": 500,
      "start_time": "2026-01-15T10:30:00",
      "runtime_seconds": 3600,
      "path": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "command_line": "powershell.exe -NoProfile"
    }
  ]
}
```

## Token Savings

Using psagent saves tokens by returning structured JSON instead of formatted tables:

| Command | Traditional Output | psagent Output | Savings |
|---------|-------------------|----------------|---------|
| Get-Process | ~3KB formatted table | ~1.5KB JSON | ~50% |
| Get-Service | ~8KB formatted table | ~3KB JSON | ~60% |
| Get-ChildItem | ~2KB formatted table | ~1KB JSON | ~50% |

## MCP Server

psagent includes an MCP server for direct integration with AI agents:

```bash
# Run MCP server
python MCP/server.py

# Test mode
python MCP/server.py --test
```

### Available MCP Tools
- `ps_list` - List directory contents
- `ps_search` - Search files for patterns
- `ps_processes` - List running processes
- `ps_services` - List Windows services
- `ps_disk` - Disk usage info
- `ps_network` - Network connections
- `ps_port` - Listening ports
- `ps_environment` - Environment variables
- `ps_tool_version` - Tool versions
- `ps_diff` - File comparison
- `ps_wordcount` - Word counts
- `ps_git_status` - Git status
- `ps_git_log` - Git log
- `ps_git_diff` - Git diff
- `ps_ripgrep` - Fast regex search

## Troubleshooting

### Module won't import
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Force import
Import-Module ./psagent.psd1 -Force -Verbose
```

### Functions not found
```powershell
# List available functions
Get-Command -Module psagent

# Check aliases
Get-Alias -Definition "Get-Agent*"
```

### JSON output issues
```powershell
# Force JSON output
Get-AgentChildItem -Path . -Json

# Or pipe to ConvertTo-Json
Get-AgentChildItem -Path . | ConvertTo-Json -Depth 10
```
