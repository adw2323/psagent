# psagent — PowerShell Structured Data Provider for AI Agents

> Version: 0.2.0
> Status: Implementation complete, 60 tests passing (42 PowerShell + 18 MCP)

## What It Does

psagent wraps common Windows commands in PowerShell functions that return structured JSON instead of human-formatted text. AI agents get clean data without parsing table output.

```powershell
# Instead of parsing terminal output:
# Get-ChildItem C:\src\*.py | Format-Table

# Agent calls structured functions:
Get-AgentChildItem -Path C:\src -Filter *.py -Depth 2
# Returns: {type: "directory_listing", files: [{name, path, size, language, mime}, ...]}

Get-AgentProcess -MinCPU 10 -SortBy CPU -Descending
# Returns: {type: "process_list", processes: [{name, id, cpu, memory, threads}, ...]}

Find-AgentPattern -Pattern "function" -Path ./Public
# Returns: {type: "search_results", matches: [{file, line_number, line}, ...]}
```

## Installation

### From GitHub (Recommended)

```powershell
# Clone and import
git clone https://github.com/adw2323/psagent.git
Import-Module ./psagent/psagent.psd1

# Or add to your profile
Copy-Item ./psagent/psagent.psd1 $HOME\Documents\PowerShell\Modules\psagent\
Import-Module psagent
```

### From PSGallery (Coming Soon)

```powershell
Install-Module -Name psagent -Scope CurrentUser
Import-Module psagent
```

## Functions

### File Inspection
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentChildItem` | `al` | List directory contents with metadata (language, MIME, sizes) |
| `Get-AgentFile` | `af` | Get file info with language detection and MIME type |
| `Find-AgentPattern` | `ag` | Search files for patterns with structured output |

### System
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentProcess` | `ap` | Process list with CPU, memory, handles, command line |
| `Get-AgentService` | `as` | Service status with start type, process ID, path |
| `Get-AgentDisk` | `ad` | Disk info with usage percentages |
| `Get-AgentNetwork` | `an` | Network connections with addresses and ports |
| `Get-AgentPort` | `apo` | Listening ports with process mapping |
| `Get-AgentEnvironment` | `aenv` | Environment variables with secret detection |
| `Get-AgentToolVersion` | `atv` | Tool versions (git, node, python, etc.) |

### Search
| Function | Alias | Description |
|----------|-------|-------------|
| `Find-AgentRipgrep` | `arg` | Fast content search via ripgrep with JSON output |
| `Compare-AgentDiff` | `adiff` | File diff comparison |
| `Measure-AgentWordCount` | `awc` | Word/line/character counts |

### Git
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentGitStatus` | `ags` | Git status with branch, staged, modified files |
| `Get-AgentGitLog` | `agl` | Git log with structured commit data |
| `Get-AgentGitDiff` | `agd` | Git diff output |

### Output
| Function | Alias | Description |
|----------|-------|-------------|
| `ConvertTo-AgentJson` | — | Wrap any object in standard JSON envelope |

## MCP Server

psagent includes an MCP server for direct integration with AI agents:

```bash
# Run MCP server
python MCP/server.py

# Test mode
python MCP/server.py --test
```

### Available MCP Tools (15)
- `ps_list` — List directory contents
- `ps_search` — Search files for patterns
- `ps_processes` — List running processes
- `ps_services` — List Windows services
- `ps_disk` — Disk usage info
- `ps_network` — Network connections
- `ps_port` — Listening ports
- `ps_environment` — Environment variables
- `ps_tool_version` — Tool versions
- `ps_diff` — File comparison
- `ps_wordcount` — Word counts
- `ps_git_status` — Git status
- `ps_git_log` — Git log
- `ps_git_diff` — Git diff
- `ps_ripgrep` — Fast regex search

## Testing

### PowerShell Tests
```powershell
Invoke-Pester ./Tests/psagent.Tests.ps1
```

### MCP Server Tests
```bash
python Tests/test_mcp_server.py
```

## Output Format

All functions return a hashtable with:
- `type` — function identifier (e.g., `directory_listing`, `process_list`)
- `timestamp` — Unix epoch when generated
- Function-specific data (e.g., `files`, `processes`, `matches`)

## Token Savings

| Command | Human Output | Structured Output | Savings |
|---------|-------------|-------------------|---------|
| `Get-Process` | ~3KB table | ~1.5KB JSON | ~50% |
| `Get-Service` | ~8KB table | ~3KB JSON | ~60% |
| `Get-ChildItem` | ~2KB table | ~1KB JSON | ~50% |
| `Select-String` | ~4KB output | ~2KB JSON | ~50% |

## Architecture

```
psagent/
├── Public/           # 16 exported functions
├── Private/          # 3 internal helpers (JSON, language, MIME)
├── MCP/              # MCP server (Python)
│   └── server.py     # 15 MCP tools
├── Tests/            # Test suites
│   ├── psagent.Tests.ps1      # 42 PowerShell tests
│   └── test_mcp_server.py     # 18 MCP tests
├── psagent.psd1      # Module manifest
├── psagent.psm1      # Module loader
├── Publish-PSGallery.ps1  # Publishing script
├── LICENSE           # MIT License
└── README.md         # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functions
4. Run `Invoke-Pester ./Tests/psagent.Tests.ps1`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.
