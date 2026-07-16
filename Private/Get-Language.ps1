# Get-Language.ps1 - Detects programming language from file extension

function Get-Language {
    <#
    .SYNOPSIS
    Detects programming language from file extension.
    
    .DESCRIPTION
    Maps file extensions to language names, similar to aict's language detection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Extension
    )
    
    $languageMap = @{
        # Languages
        '.py' = 'python'
        '.js' = 'javascript'
        '.ts' = 'typescript'
        '.jsx' = 'jsx'
        '.tsx' = 'tsx'
        '.go' = 'go'
        '.rs' = 'rust'
        '.java' = 'java'
        '.kt' = 'kotlin'
        '.swift' = 'swift'
        '.c' = 'c'
        '.cpp' = 'cpp'
        '.h' = 'c-header'
        '.hpp' = 'cpp-header'
        '.cs' = 'csharp'
        '.rb' = 'ruby'
        '.php' = 'php'
        '.lua' = 'lua'
        '.r' = 'r'
        '.scala' = 'scala'
        '.clj' = 'clojure'
        '.ex' = 'elixir'
        '.erl' = 'erlang'
        '.hs' = 'haskell'
        '.ml' = 'ocaml'
        '.fs' = 'fsharp'
        '.vb' = 'visual-basic'
        '.dart' = 'dart'
        '.zig' = 'zig'
        '.nim' = 'nim'
        '.crystal' = 'crystal'
        '.v' = 'v'
        '.jl' = 'julia'
        
        # Shell
        '.sh' = 'shell'
        '.bash' = 'shell'
        '.zsh' = 'shell'
        '.fish' = 'shell'
        '.ps1' = 'powershell'
        '.psm1' = 'powershell'
        '.psd1' = 'powershell'
        '.bat' = 'batch'
        '.cmd' = 'batch'
        
        # Web
        '.html' = 'html'
        '.htm' = 'html'
        '.css' = 'css'
        '.scss' = 'scss'
        '.less' = 'less'
        '.vue' = 'vue'
        '.svelte' = 'svelte'
        
        # Data
        '.json' = 'json'
        '.yaml' = 'yaml'
        '.yml' = 'yaml'
        '.toml' = 'toml'
        '.xml' = 'xml'
        '.csv' = 'csv'
        '.tsv' = 'tsv'
        '.sql' = 'sql'
        
        # Config
        '.ini' = 'ini'
        '.conf' = 'config'
        '.cfg' = 'config'
        '.env' = 'env'
        
        # Docs
        '.md' = 'markdown'
        '.rst' = 'restructuredtext'
        '.txt' = 'text'
        '.pdf' = 'pdf'
        '.doc' = 'word'
        '.docx' = 'word'
        
        # Images
        '.png' = 'image'
        '.jpg' = 'image'
        '.jpeg' = 'image'
        '.gif' = 'image'
        '.svg' = 'svg'
        '.webp' = 'image'
        '.ico' = 'image'
        
        # Other
        '.lock' = 'lock'
        '.log' = 'log'
        '.gitignore' = 'gitignore'
        '.dockerignore' = 'gitignore'
        '.editorconfig' = 'config'
    }
    
    $ext = $Extension.ToLower()
    if ($languageMap.ContainsKey($ext)) {
        return $languageMap[$ext]
    }
    
    return 'unknown'
}

Set-Alias -Name getlang -Value Get-Language
