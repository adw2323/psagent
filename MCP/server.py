#!/usr/bin/env python3
"""
psagent MCP Server

Exposes PowerShell cmdlets as MCP tools via stdio transport.
Agents call tools natively — no shell wrapping needed.

Usage:
    python server.py          # Run MCP server
    python server.py --test   # Test mode
"""

import json
import subprocess
import sys
from typing import Any, Dict, List, Optional


# Tool definitions
TOOLS = [
    {
        "name": "ps_list",
        "description": "List directory contents with metadata (size, language, MIME type)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Directory path"},
                "filter": {"type": "string", "description": "File filter (e.g., *.py)"},
                "depth": {"type": "integer", "description": "Directory depth", "default": 1},
                "include_hidden": {"type": "boolean", "description": "Include hidden files", "default": False}
            },
            "required": ["path"]
        }
    },
    {
        "name": "ps_search",
        "description": "Search files for patterns with structured output",
        "inputSchema": {
            "type": "object",
            "properties": {
                "pattern": {"type": "string", "description": "Search pattern (regex)"},
                "path": {"type": "string", "description": "Directory path"},
                "filter": {"type": "string", "description": "File filter"},
                "context": {"type": "integer", "description": "Context lines", "default": 0}
            },
            "required": ["pattern"]
        }
    },
    {
        "name": "ps_processes",
        "description": "List running processes with CPU/memory stats",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Filter by process name"},
                "min_cpu": {"type": "number", "description": "Minimum CPU seconds"},
                "sort_by": {"type": "string", "description": "Sort field (CPU, memory)", "default": "CPU"},
                "top": {"type": "integer", "description": "Max results", "default": 50}
            }
        }
    },
    {
        "name": "ps_services",
        "description": "List Windows services with status",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Filter by service name"},
                "status": {"type": "string", "description": "Filter by status (Running, Stopped)"}
            }
        }
    },
    {
        "name": "ps_disk",
        "description": "List disk drives with usage info",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "ps_network",
        "description": "List network connections",
        "inputSchema": {
            "type": "object",
            "properties": {
                "state": {"type": "string", "description": "Filter by state (Established, Listen)"},
                "local_port": {"type": "integer", "description": "Filter by local port"}
            }
        }
    },
    {
        "name": "ps_diff",
        "description": "Compare two files and show differences",
        "inputSchema": {
            "type": "object",
            "properties": {
                "reference": {"type": "string", "description": "Reference file path"},
                "difference": {"type": "string", "description": "Difference file path"}
            },
            "required": ["reference", "difference"]
        }
    },
    {
        "name": "ps_wordcount",
        "description": "Count words, lines, and characters in files",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "File or glob pattern"},
                "recurse": {"type": "boolean", "description": "Recurse into directories", "default": False}
            },
            "required": ["path"]
        }
    },
    {
        "name": "ps_git_status",
        "description": "Get git repository status (branch, staged, unstaged, untracked)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Repository path"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "ps_git_log",
        "description": "Get git commit log",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Repository path"},
                "count": {"type": "integer", "description": "Number of commits", "default": 10},
                "author": {"type": "string", "description": "Filter by author"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "ps_git_diff",
        "description": "Get git diff (staged or unstaged)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Repository path"},
                "staged": {"type": "boolean", "description": "Show staged changes", "default": False}
            },
            "required": ["path"]
        }
    },
    {
        "name": "ps_ripgrep",
        "description": "Fast regex search using ripgrep with structured JSON output",
        "inputSchema": {
            "type": "object",
            "properties": {
                "pattern": {"type": "string", "description": "Search pattern (regex)"},
                "path": {"type": "string", "description": "Search path"},
                "filter": {"type": "string", "description": "File filter (e.g., *.py)"},
                "context": {"type": "integer", "description": "Context lines", "default": 0}
            },
            "required": ["pattern", "path"]
        }
    },
    {
        "name": "ps_environment",
        "description": "List environment variables with optional filtering",
        "inputSchema": {
            "type": "object",
            "properties": {
                "filter": {"type": "string", "description": "Filter by variable name"}
            }
        }
    },
    {
        "name": "ps_port",
        "description": "List listening ports with process mapping",
        "inputSchema": {
            "type": "object",
            "properties": {
                "local_port": {"type": "integer", "description": "Filter by local port"},
                "process_name": {"type": "string", "description": "Filter by process name"}
            }
        }
    },
    {
        "name": "ps_tool_version",
        "description": "Get version information for installed tools",
        "inputSchema": {
            "type": "object",
            "properties": {
                "tools": {"type": "array", "items": {"type": "string"}, "description": "List of tool names to check"}
            },
            "required": ["tools"]
        }
    }
]


def run_powershell(cmd: str, timeout: int = 30) -> Dict[str, Any]:
    """Execute a PowerShell command and return structured result."""
    try:
        result = subprocess.run(
            ["powershell.exe", "-NoProfile", "-Command", cmd],
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding='utf-8',
            errors='replace'
        )
        
        if result.returncode != 0:
            return {"error": result.stderr.strip() or "Command failed"}
        
        # Try to parse as JSON
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return {"raw_output": result.stdout.strip()}
            
    except subprocess.TimeoutExpired:
        return {"error": f"Command timed out after {timeout}s"}
    except Exception as e:
        return {"error": str(e)}


def handle_tool(name: str, arguments: Dict[str, Any]) -> Any:
    """Handle a tool call by executing the corresponding PowerShell cmdlet."""
    
    if name == "ps_list":
        cmd = f"Get-AgentChildItem -Path '{arguments['path']}'"
        if arguments.get('filter'):
            cmd += f" -Filter '{arguments['filter']}'"
        if arguments.get('depth'):
            cmd += f" -Depth {arguments['depth']}"
        if arguments.get('include_hidden'):
            cmd += " -IncludeHidden"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_search":
        cmd = f"Find-AgentPattern -Pattern '{arguments['pattern']}'"
        if arguments.get('path'):
            cmd += f" -Path '{arguments['path']}'"
        if arguments.get('filter'):
            cmd += f" -Filter '{arguments['filter']}'"
        if arguments.get('context'):
            cmd += f" -Context {arguments['context']}"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_processes":
        cmd = "Get-AgentProcess"
        if arguments.get('name'):
            cmd += f" -Name '{arguments['name']}'"
        if arguments.get('min_cpu'):
            cmd += f" -MinCPU {arguments['min_cpu']}"
        if arguments.get('sort_by'):
            cmd += f" -SortBy {arguments['sort_by']}"
        if arguments.get('top'):
            cmd += f" -Top {arguments['top']}"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_services":
        cmd = "Get-AgentService"
        if arguments.get('name'):
            cmd += f" -Name '{arguments['name']}'"
        if arguments.get('status'):
            cmd += f" -Status {arguments['status']}"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_disk":
        cmd = "Get-AgentDisk | ConvertTo-Json -Depth 10"
        
    elif name == "ps_network":
        cmd = "Get-AgentNetwork"
        if arguments.get('state'):
            cmd += f" -State {arguments['state']}"
        if arguments.get('local_port'):
            cmd += f" -LocalPort {arguments['local_port']}"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_diff":
        cmd = f"Compare-AgentDiff -Reference '{arguments['reference']}' -Difference '{arguments['difference']}' | ConvertTo-Json -Depth 10"
        
    elif name == "ps_wordcount":
        cmd = f"Measure-AgentWordCount -Path '{arguments['path']}'"
        if arguments.get('recurse'):
            cmd += " -Recurse"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_git_status":
        cmd = f"Get-AgentGitStatus -Path '{arguments['path']}' | ConvertTo-Json -Depth 10"
        
    elif name == "ps_git_log":
        cmd = f"Get-AgentGitLog -Path '{arguments['path']}'"
        if arguments.get('count'):
            cmd += f" -Count {arguments['count']}"
        if arguments.get('author'):
            cmd += f" -Author '{arguments['author']}'"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_git_diff":
        cmd = f"Get-AgentGitDiff -Path '{arguments['path']}'"
        if arguments.get('staged'):
            cmd += " -Staged"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_ripgrep":
        cmd = f"Find-AgentRipgrep -Pattern '{arguments['pattern']}' -Path '{arguments['path']}'"
        if arguments.get('filter'):
            cmd += f" -Filter '{arguments['filter']}'"
        if arguments.get('context'):
            cmd += f" -Context {arguments['context']}"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_environment":
        cmd = "Get-AgentEnvironment"
        if arguments.get('filter'):
            cmd += f" -Filter '{arguments['filter']}'"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_port":
        cmd = "Get-AgentPort"
        if arguments.get('local_port'):
            cmd += f" -LocalPort {arguments['local_port']}"
        if arguments.get('process_name'):
            cmd += f" -ProcessName '{arguments['process_name']}'"
        cmd += " | ConvertTo-Json -Depth 10"
        
    elif name == "ps_tool_version":
        tools_list = arguments.get('tools', [])
        tools_str = ", ".join(f"'{t}'" for t in tools_list)
        cmd = f"Get-AgentToolVersion -Tools @({tools_str}) | ConvertTo-Json -Depth 10"
        
    else:
        return {"error": f"Unknown tool: {name}"}
    
    return run_powershell(cmd)


def mcp_server():
    """Run the MCP server over stdio."""
    # Read JSON-RPC messages from stdin
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        
        try:
            request = json.loads(line)
        except json.JSONDecodeError:
            continue
        
        method = request.get("method")
        params = request.get("params", {})
        request_id = request.get("id")
        
        if method == "initialize":
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {
                        "name": "psagent",
                        "version": "0.1.0"
                    }
                }
            }
        elif method == "tools/list":
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {"tools": TOOLS}
            }
        elif method == "tools/call":
            tool_name = params.get("name")
            arguments = params.get("arguments", {})
            
            result = handle_tool(tool_name, arguments)
            
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result, indent=2, default=str)
                        }
                    ]
                }
            }
        else:
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"}
            }
        
        print(json.dumps(response))
        sys.stdout.flush()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        print("Testing psagent MCP server...")
        for tool in TOOLS:
            print(f"  Tool: {tool['name']} - {tool['description']}")
        print("All tools registered.")
    else:
        mcp_server()
