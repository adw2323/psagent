# psagent — PowerShell Structured Data Provider for AI Agents

> Version: 0.6.0 | 42 functions | 98 tests passing

## What It Does

psagent wraps Windows system commands in PowerShell functions that return structured JSON instead of human-formatted text. AI agents get clean data without parsing table output.

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
# Clone and import
git clone https://github.com/adw2323/psagent.git
Import-Module ./psagent/psagent.psd1

# Or add to your profile
Copy-Item ./psagent/psagent.psd1 $HOME\Documents\PowerShell\Modules\psagent\
Import-Module psagent
```

## Functions (42)

### File Inspection
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentChildItem` | `al` | List directory contents with metadata |
| `Get-AgentFile` | `af` | Get file info with language detection |
| `Find-AgentPattern` | `ag` | Search files for patterns |

### System
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentProcess` | `ap` | Process list with CPU, memory, handles |
| `Get-AgentService` | `as` | Service status with start type, PID |
| `Get-AgentDisk` | `ad` | Disk info with usage percentages |
| `Get-AgentNetwork` | `an` | Network connections |
| `Get-AgentPort` | `apo` | Listening ports with process mapping |
| `Get-AgentEnvironment` | `aenv` | Environment variables with secret detection |
| `Get-AgentToolVersion` | `atv` | Tool versions (git, node, python) |
| `Get-AgentSystemInfo` | `asi` | OS, CPU, memory, uptime, hostname |
| `Get-AgentUser` | `ausr` | User accounts and groups |
| `Get-AgentStartup` | `asu` | Startup/autorun items |
| `Get-AgentSession` | `ases` | Active user sessions |
| `Get-AgentNetworkConfig` | `ancfg` | IP config, DNS, gateways |

### Search
| Function | Alias | Description |
|----------|-------|-------------|
| `Find-AgentRipgrep` | `arg` | Fast regex search via ripgrep |
| `Compare-AgentDiff` | `adiff` | File diff comparison |
| `Measure-AgentWordCount` | `awc` | Word/line/character counts |

### Git
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentGitStatus` | `ags` | Git status with branch, staged files |
| `Get-AgentGitLog` | `agl` | Git log with structured commits |
| `Get-AgentGitDiff` | `agd` | Git diff output |

### Security
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentSecurityAudit` | `asa` | Firewall, Defender, password policy |
| `Get-AgentScheduledTask` | `ast` | Scheduled tasks with triggers |
| `Get-AgentEventLog` | `ael` | Windows event logs |
| `Get-AgentFirewall` | `afw` | Firewall rules and profiles |
| `Get-AgentDefender` | `adf` | Windows Defender status |
| `Get-AgentHotfix` | `ahf` | Installed patches/updates |
| `Get-AgentDefenderScan` | `adscan` | Start/stop/monitor Defender scans |

### Network
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentDns` | `adns` | DNS resolution + hosts file |

### Software & Configuration
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentInstalledSoftware` | `asw` | Installed software from registry |
| `Get-AgentWindowsFeature` | `awf` | Windows features and capabilities |
| `Get-AgentCertificate` | `acert` | Certificate store inspection |
| `Get-AgentRegistry` | `areg` | Read-only registry access |

### Clipboard
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentClipboard` | `aclip` | Read/write clipboard content |

### New in v0.6.0
| Function | Alias | Description |
|----------|-------|-------------|
| `Get-AgentWindowsUpdate` | `awup` | Windows Update history and status |
| `Get-AgentGroupPolicy` | `agpol` | Group Policy objects and settings |
| `Get-AgentMappedDrive` | `amap` | Mapped network drives |
| `Get-AgentBatteryHealth` | `abat` | Battery status and health |
| `Get-AgentSecureBoot` | `asboot` | Secure Boot configuration |
| `Get-AgentBitLocker` | `ablock` | BitLocker encryption status |
| `Get-AgentPerformanceCounter` | `aperf` | CPU, memory, disk, network counters |

### Output
| Function | Alias | Description |
|----------|-------|-------------|
| `ConvertTo-AgentJson` | `agentjson` | Wrap any object in standard JSON envelope |

## Testing

```powershell
# PowerShell tests (98 tests)
Invoke-Pester ./Tests/psagent.Tests.ps1
```

## Output Format

All functions return a hashtable with:
- `type` — function identifier (e.g., `directory_listing`, `process_list`)
- `timestamp` — Unix epoch when generated
- Function-specific data (e.g., `files`, `processes`, `matches`)

## Architecture

```
psagent/
├── Public/              # 42 exported functions
├── Private/             # 3 internal helpers (JSON, language, MIME)
├── Tests/               # Test suites (98 tests)
├── psagent.psd1         # Module manifest
├── psagent.psm1         # Module loader
├── LICENSE              # MIT License
└── README.md            # This file
```

## License

MIT License - see [LICENSE](LICENSE) for details.
