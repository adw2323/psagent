# PowerShell Structured Data Provider for AI Agents

> Date: 2026-07-15
> Status: Project plan — beginning implementation

## Problem

AI agents running on Windows waste tokens parsing human-formatted terminal output. PowerShell returns .NET objects natively, but agents still invoke `terminal(command="...")` which captures stdout as a string, losing structure. The fix: wrap common commands in a way that preserves structure and exposes it via MCP.

## Architecture

### Layer 1: Structured PowerShell Module

PowerShell module (`psagent`) that exposes cmdlets returning JSON objects:

```powershell
# Instead of: Get-ChildItem C:\src\*.py | Format-Table
# Agent calls: Get-AgentChildItem -Path C:\src -Filter *.py -Depth 2
# Returns: [{Name, FullName, Length, LastWriteTime, IsDir, Language, MIMEType}, ...]

# Instead of: Get-Content file.py | Select-String "class "
# Agent calls: Find-AgentPattern -Path C:\src -Pattern "class " -Filter *.py
# Returns: [{File, LineNum, Line, MatchStart, MatchEnd}, ...]

# Instead of: Get-Process | Where { $_.CPU -gt 10 }
# Agent calls: Get-AgentProcess -MinCPU 10 -SortBy CPU -Descending
# Returns: [{Name, Id, CPU, WorkingSet64, StartTime}, ...]
```

### Layer 2: MCP Server

Expose cmdlets as typed MCP tools with schemas:

```json
{
  "name": "ps_list",
  "description": "List directory contents with metadata",
  "parameters": {
    "path": {"type": "string", "required": true},
    "filter": {"type": "string", "default": "*"},
    "depth": {"type": "integer", "default": 1},
    "include_hidden": {"type": "boolean", "default": false}
  }
}
```

### Layer 3: Context Window Optimization

| Command | Human Output | Structured Output | Token Savings |
|---------|-------------|-------------------|---------------|
| `Get-ChildItem` | 2000 tokens | 800 tokens | 60% |
| `Select-String` | 3000 tokens | 1200 tokens | 60% |
| `Get-Process` | 600 tokens | 400 tokens | 33% |
| `Get-Service` | 400 tokens | 250 tokens | 37% |

## Implementation Plan

### Phase 1: Core Module (This Session)
- [x] Project structure and manifest
- [ ] File inspection cmdlets (list, stat, read, search)
- [ ] Path utilities (resolve, basename, dirname)
- [ ] System cmdlets (process, service, disk, network)
- [ ] JSON output pipeline

### Phase 2: MCP Server (Next Session)
- [ ] MCP server wrapper
- [ ] Tool definitions and schemas
- [ ] Stdio transport
- [ ] Claude Desktop integration

### Phase 3: Azure/Cloud Integration (Future)
- [ ] Azure resource queries
- [ ] Active Directory lookups
- [ ] Registry queries
- [ ] WMI/CIM queries

## Directory Structure

```
psagent/
├── psagent.psd1          # Module manifest
├── psagent.psm1          # Module loader
├── Public/               # Exported cmdlets
│   ├── Get-AgentChildItem.ps1
│   ├── Find-AgentPattern.ps1
│   ├── Get-AgentProcess.ps1
│   └── ...
├── Private/              # Internal functions
│   ├── ConvertTo-AgentJson.ps1
│   ├── Get-Language.ps1
│   └── Get-MIMEType.ps1
├── MCP/                  # MCP server
│   └── server.py         # MCP server wrapper
└── Tests/                # Pester tests
    ├── Get-AgentChildItem.Tests.ps1
    └── ...
```

## Key Design Decisions

1. **PowerShell module** — Native, no compilation needed
2. **JSON output** — Universal, agent-friendly
3. **Always absolute paths** — No ambiguity
4. **Language/MIME detection** — Rich metadata like aict
5. **MCP server** — Direct agent integration
6. **Read-only by default** — Safety first
