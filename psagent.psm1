# psagent.psm1 - Module loader
# Loads all public and private functions

$Private = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue
$Public = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue

# Dot-source private functions first
foreach ($import in $Private) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import private function $($import.Name): $_"
    }
}

# Dot-source public functions
foreach ($import in $Public) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Failed to import public function $($import.Name): $_"
    }
}

Write-Verbose "psagent loaded: $($Public.Count) public functions, $($Private.Count) private functions"
