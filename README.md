# psagent — PowerShell Structured Data Provider for AI Agents

> Version: 0.2.0
> Status: Implementation complete, 34/34 tests passing

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

```powershell
Import-Module ./psagent.psd1
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
| `Get-AgentDisk` | — | Disk info with usage percentages |
| `Get-AgentNetwork` | — | Network connections with addresses and ports |
| `Get-AgentPort` | — | Listening ports with process mapping |
| `Get-AgentEnvironment` | — | Environment variables with secret detection |
| `Get-AgentToolVersion` | — | Tool versions (git, node, python, etc.) |

### Search
| Function | Alias | Description |
|----------|-------|-------------|
| `Find-AgentRipgrep` | `arg` | Fast content search via ripgrep with JSON output |
| `Compare-AgentDiff` | — | File diff comparison |
| `Measure-AgentWordCount` | — | Word/line/character counts |

### Git
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentGitStatus` | — | Git status with branch, staged, modified files |
| `Get-AgentGitLog` | — | Git log with structured commit data |
| `Get-AgentGitDiff` | — | Git diff output |

### Output
| Function | Alias | Description |
|----------|-------|-------------|
| `ConvertTo-AgentJson` | — | Wrap any object in standard JSON envelope |

## Output Format

All functions return a hashtable with:
- `type` — function identifier (e.g., `directory_listing`, `process_list`)
- `timestamp` — Unix epoch when generated
- Function-specific data (e.g., `files`, `processes`, `matches`)

## Testing

```powershell
Invoke-Pester ./Tests/psagent.Tests.ps1
```

34 tests covering all 16 public functions.

## Architecture

```
psagent/
├── Public/           # 16 exported functions
├── Private/          # 3 internal helpers (JSON, language, MIME)
├── Tests/            # Pester test suite
├── psagent.psd1      # Module manifest
└── psagent.psm1      # Module loader
```

## Token Savings

| Command | Human Output | Structured Output | Savings |
|---------|-------------|-------------------|---------|
| `Get-Process` | ~3KB table | ~1.5KB JSON | ~50% |
| `Get-Service` | ~8KB table | ~3KB JSON | ~60% |
| `Get-ChildItem` | ~2KB table | ~1KB JSON | ~50% |
| `Select-String` | ~4KB output | ~2KB JSON | ~50% |
