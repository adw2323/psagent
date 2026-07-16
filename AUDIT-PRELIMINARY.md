# psagent Independent Critic Audit — Preliminary Findings

## CRITICAL FINDINGS

### F001: Command Injection in MCP Server (BLOCKING)
**Category:** security
**File:** MCP/server.py, lines 229-255
**Issue:** User input from MCP tool arguments is directly interpolated into PowerShell commands without sanitization.
**Evidence:**
```python
cmd = f"Get-AgentChildItem -Path '{arguments['path']}'"
```
If `arguments['path']` contains `'; Remove-Item -Recurse -Force C:\*; '`, it becomes:
```powershell
Get-AgentChildItem -Path ''; Remove-Item -Recurse -Force C:\*; ''
```
**Remediation:** Use parameter binding instead of string interpolation. Pass arguments as a hashtable to PowerShell's `-Command` parameter, or use `Invoke-Command` with proper parameter passing.

### F002: No Error Handling in Most Functions (REQUIRED)
**Category:** correctness
**Files:** Public/Get-AgentChildItem.ps1, Public/Get-AgentDisk.ps1, Public/Get-AgentNetwork.ps1, Public/Get-AgentPort.ps1, Public/Get-AgentProcess.ps1, Public/Get-AgentService.ps1, Public/Compare-AgentDiff.ps1, Public/Find-AgentPattern.ps1, Public/Get-AgentGitDiff.ps1, Public/Get-AgentGitLog.ps1, Public/Measure-AgentWordCount.ps1
**Issue:** 12 of 16 functions have ZERO try/catch blocks. Any error (file not found, access denied, WMI failure) will throw an unhandled exception.
**Evidence:** grep shows 0 try blocks in these files.
**Remediation:** Add try/catch to each function, return structured error JSON on failure.

### F003: No Input Validation (REQUIRED)
**Category:** schema
**Files:** All Public/*.ps1
**Issue:** No ValidateScript, ValidateSet, ValidatePattern, or ValidateNotNull attributes on any parameters. Users can pass arbitrary strings to -Path, -Pattern, -Name etc.
**Evidence:** grep shows 0 validators in all files.
**Remediation:** Add parameter validation:
- Validate paths exist before processing
- Validate patterns are valid regex
- Validate enums (SortBy, Status, State)
- Validate numeric ranges (Top, Depth, Context)

### F004: Missing Module Manifest Fields (REQUIRED)
**Category:** compatibility
**File:** psagent.psd1
**Issue:** Module manifest is missing Minimum PowerShell version validation and CompatiblePSEditions.
**Evidence:** No PowerShellVersion constraint beyond '5.1', no CompatiblePSEditions.
**Remediation:** Add CompatiblePSEditions = @('Desktop', 'Core') and validate PowerShell 5.1+ features work.

## ACCEPTED RISKS

### F005: MCP Server Uses Subprocess (ACCEPTED RISK)
**Category:** operations
**File:** MCP/server.py
**Issue:** MCP server executes PowerShell via subprocess. This is inherent to the design but creates a process per tool call.
**Mitigation:** Timeout is set to 30s. No shell=True. Acceptable for this use case.

### F006: No HTTPS in MCP Server (ACCEPTED RISK)
**Category:** operations
**File:** MCP/server.py
**Issue:** MCP server uses stdio transport, not HTTP. This is standard for MCP but means it's only accessible locally.
**Mitigation:** Stdio is the intended MCP transport. No external exposure.

## CLAIMS VERIFICATION

README.md claims:
1. "16 functions returning JSON" — VERIFIED (functions exist and return JSON by default)
2. "42 tests passing" — VERIFIED (tests exist and pass)
3. "MCP server with 15 tools" — VERIFIED (server.py has 15 tools defined)
4. "Token savings of 50-60%" — UNVERIFIED (no benchmark data provided)
5. "Works on PowerShell 5.1" — PARTIALLY VERIFIED (manifest says 5.1 but no actual testing on 5.1)
6. "Published to PSGallery" — NOT YET DONE (preparation complete but not published)

## REGRESSION ADDITIONS NEEDED

1. Test command injection in MCP server
2. Test error handling in all functions
3. Test input validation boundaries
4. Test on PowerShell 5.1 (not just 7.x)
5. Test MCP server with malformed JSON-RPC
6. Test concurrent access to MCP server
7. Test large directory listings (memory usage)
8. Test special characters in paths/patterns

## CRITIC EFFECTIVENESS

| Category | Count |
|----------|-------|
| Security | 1 (CRITICAL) |
| Correctness | 1 |
| Schema | 1 |
| Compatibility | 1 |
| Operations | 2 (accepted) |
| Tests | 0 |
| **Total** | **6** |

**Critical finding:** Command injection in MCP server is a showstopper for any production use.
