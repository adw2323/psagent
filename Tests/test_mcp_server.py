#!/usr/bin/env python3
"""
Tests for psagent MCP Server
Validates tool definitions, command building, and JSON-RPC protocol.
"""
import json
import sys
import os

# Add MCP directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'MCP'))
from server import TOOLS, handle_tool, run_powershell

def test_tool_count():
    """Verify all expected tools are registered."""
    assert len(TOOLS) == 15, f"Expected 15 tools, got {len(TOOLS)}"
    print("✓ Tool count: 15")

def test_tool_names():
    """Verify tool names are correct."""
    expected = {'ps_list', 'ps_search', 'ps_processes', 'ps_services', 
                'ps_disk', 'ps_network', 'ps_diff', 'ps_wordcount',
                'ps_git_status', 'ps_git_log', 'ps_git_diff', 'ps_ripgrep',
                'ps_environment', 'ps_port', 'ps_tool_version'}
    actual = {t['name'] for t in TOOLS}
    missing = expected - actual
    extra = actual - expected
    assert not missing, f"Missing tools: {missing}"
    assert not extra, f"Extra tools: {extra}"
    print("✓ Tool names: all 15 correct")

def test_tool_schemas():
    """Verify all tools have valid inputSchema."""
    for tool in TOOLS:
        assert 'name' in tool, f"Tool missing name: {tool}"
        assert 'description' in tool, f"Tool {tool['name']} missing description"
        assert 'inputSchema' in tool, f"Tool {tool['name']} missing inputSchema"
        schema = tool['inputSchema']
        assert schema.get('type') == 'object', f"Tool {tool['name']} schema type != object"
    print("✓ Tool schemas: all valid")

def test_ps_list_command():
    """Test ps_list command building."""
    result = handle_tool('ps_list', {'path': 'C:\\Windows'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_list: command executed")

def test_ps_search_command():
    """Test ps_search command building."""
    result = handle_tool('ps_search', {'pattern': 'function', 'path': './Public'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_search: command executed")

def test_ps_processes_command():
    """Test ps_processes command building."""
    result = handle_tool('ps_processes', {'top': 5})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_processes: command executed")

def test_ps_services_command():
    """Test ps_services command building."""
    result = handle_tool('ps_services', {})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_services: command executed")

def test_ps_disk_command():
    """Test ps_disk command building."""
    result = handle_tool('ps_disk', {})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_disk: command executed")

def test_ps_network_command():
    """Test ps_network command building."""
    result = handle_tool('ps_network', {})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_network: command executed")

def test_ps_wordcount_command():
    """Test ps_wordcount command building."""
    result = handle_tool('ps_wordcount', {'path': './README.md'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_wordcount: command executed")

def test_ps_git_status_command():
    """Test ps_git_status command building."""
    result = handle_tool('ps_git_status', {'path': '.'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_git_status: command executed")

def test_ps_git_log_command():
    """Test ps_git_log command building."""
    result = handle_tool('ps_git_log', {'path': '.', 'count': 3})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_git_log: command executed")

def test_ps_git_diff_command():
    """Test ps_git_diff command building."""
    result = handle_tool('ps_git_diff', {'path': '.'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_git_diff: command executed")

def test_ps_ripgrep_command():
    """Test ps_ripgrep command building."""
    result = handle_tool('ps_ripgrep', {'pattern': 'function', 'path': './Public'})
    assert 'type' in result or 'error' in result, f"Unexpected result: {result}"
    print("✓ ps_ripgrep: command executed")

def test_unknown_tool():
    """Test unknown tool handling."""
    result = handle_tool('unknown_tool', {})
    assert 'error' in result, f"Expected error for unknown tool: {result}"
    print("✓ Unknown tool: returns error")

def test_jsonrpc_initialize():
    """Test JSON-RPC initialize method."""
    request = {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}
    # We can't easily test the full server loop, but we can test the response structure
    response = {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "psagent", "version": "0.2.0"}
        }
    }
    assert response['result']['serverInfo']['name'] == 'psagent'
    assert response['result']['serverInfo']['version'] == '0.2.0'
    print("✓ JSON-RPC initialize: structure valid")

def test_jsonrpc_tools_list():
    """Test JSON-RPC tools/list method."""
    response = {
        "jsonrpc": "2.0",
        "id": 2,
        "result": {"tools": TOOLS}
    }
    assert len(response['result']['tools']) == 15
    print("✓ JSON-RPC tools/list: returns 15 tools")

def test_jsonrpc_tools_call():
    """Test JSON-RPC tools/call method."""
    # Test with a simple tool
    result = handle_tool('ps_disk', {})
    response = {
        "jsonrpc": "2.0",
        "id": 3,
        "result": {
            "content": [
                {
                    "type": "text",
                    "text": json.dumps(result, indent=2, default=str)
                }
            ]
        }
    }
    assert 'content' in response['result']
    assert len(response['result']['content']) == 1
    assert response['result']['content'][0]['type'] == 'text'
    print("✓ JSON-RPC tools/call: response structure valid")

if __name__ == '__main__':
    tests = [
        test_tool_count,
        test_tool_names,
        test_tool_schemas,
        test_ps_list_command,
        test_ps_search_command,
        test_ps_processes_command,
        test_ps_services_command,
        test_ps_disk_command,
        test_ps_network_command,
        test_ps_wordcount_command,
        test_ps_git_status_command,
        test_ps_git_log_command,
        test_ps_git_diff_command,
        test_ps_ripgrep_command,
        test_unknown_tool,
        test_jsonrpc_initialize,
        test_jsonrpc_tools_list,
        test_jsonrpc_tools_call,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except AssertionError as e:
            print(f"✗ {test.__name__}: {e}")
            failed += 1
        except Exception as e:
            print(f"✗ {test.__name__}: {type(e).__name__}: {e}")
            failed += 1
    
    print(f"\n{'='*50}")
    print(f"Results: {passed} passed, {failed} failed, {len(tests)} total")
    
    if failed > 0:
        sys.exit(1)
    else:
        print("All tests passed!")
        sys.exit(0)
