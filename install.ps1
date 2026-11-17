# claude-x installer for Windows PowerShell 5.1+ / pwsh 7.
# Mirrors install.sh: CLAUDE.md, rules, agents, hooks, settings, MCP servers,
# plugin marketplaces, Serena UI off, ccd alias. No python dependency.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1
# Test:   $env:CLAUDE_DIR / $env:CLAUDE_JSON redirect the targets.
# Keep this file ASCII-only: PS 5.1 reads BOM-less scripts as ANSI.

$ErrorActionPreference = 'Stop'
$RepoDir    = $PSScriptRoot
$ClaudeDir  = if ($env:CLAUDE_DIR)  { $env:CLAUDE_DIR }  else { Join-Path $HOME '.claude' }
$ClaudeJson = if ($env:CLAUDE_JSON) { $env:CLAUDE_JSON } else { Join-Path $HOME '.claude.json' }
$SerenaCfg  = if ($env:SERENA_CONFIG) { $env:SERENA_CONFIG } else { Join-Path $HOME '.serena\serena_config.yml' }
$Stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8NoBom  = New-Object System.Text.UTF8Encoding $false

function Say([string]$m)  { Write-Host "==> $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host " !! $m" -ForegroundColor Yellow }
function Write-Utf8([string]$path, [string]$text) { [IO.File]::WriteAllText($path, $text, $Utf8NoBom) }
function Read-Utf8([string]$path) { [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) }
function Has([string]$cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

# 1. Backup ------------------------------------------------------------------
Say "Backing up existing config (suffix .bak-$Stamp)"
foreach ($f in 'settings.json', 'CLAUDE.md', 'keybindings.json') {
  $p = Join-Path $ClaudeDir $f
  if (Test-Path $p) { Copy-Item $p "$p.bak-$Stamp" }
}

# 2. CLAUDE.md + rules + agents + hooks + keybindings + settings -------------
Say 'Installing CLAUDE.md, rules/, agents/, hooks/, keybindings.json, settings.json'
foreach ($d in 'rules', 'agents', 'hooks') {
  New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeDir $d) | Out-Null
  Copy-Item (Join-Path $RepoDir "claude\$d\*") (Join-Path $ClaudeDir $d) -Force
}
foreach ($f in 'CLAUDE.md', 'keybindings.json', 'settings.json') {
  Copy-Item (Join-Path $RepoDir "claude\$f") (Join-Path $ClaudeDir $f) -Force
}

# 3. Vendored local MCP server (aseprite-mcp-pro) -----------------------------
Say 'Installing local MCP server: aseprite-mcp-pro'
$McpDir = Join-Path $ClaudeDir 'mcp-servers\aseprite-mcp-pro'
if (-not (Test-Path $McpDir)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $McpDir) | Out-Null
  Copy-Item (Join-Path $RepoDir 'mcp\servers\aseprite-mcp-pro') $McpDir -Recurse
} else { Warn 'aseprite-mcp-pro already present - left untouched' }
if ((Has 'npm') -and -not (Test-Path (Join-Path $McpDir 'node_modules'))) {
  Push-Location $McpDir
  try { npm ci --silent; if ($LASTEXITCODE -ne 0) { npm install --silent } } finally { Pop-Location }
  if ($LASTEXITCODE -ne 0) { Warn 'npm install failed for aseprite-mcp-pro - run it manually' }
}

# 4. Merge MCP servers into ~/.claude.json (add-only, never overwrites) -------
Say "Merging MCP servers into $ClaudeJson"
function Expand-Node($n) {
  # '~/' -> absolute path for this machine, recursively
  if ($null -eq $n) { return $null }
  if ($n -is [string]) {
    if ($n.StartsWith('~/')) { return (Join-Path $HOME $n.Substring(2)) }
    return $n
  }
  if ($n -is [System.Array]) { return ,@($n | ForEach-Object { Expand-Node $_ }) }
  if ($n -is [System.Management.Automation.PSCustomObject]) {
    foreach ($p in $n.PSObject.Properties) { $p.Value = Expand-Node $p.Value }
  }
  return $n
}
$incoming = (ConvertFrom-Json (Read-Utf8 (Join-Path $RepoDir 'mcp\mcp-servers.json'))).mcpServers
$dst = if (Test-Path $ClaudeJson) { ConvertFrom-Json (Read-Utf8 $ClaudeJson) } else { New-Object PSObject }
if (-not $dst.PSObject.Properties['mcpServers']) { $dst | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object PSObject) }
$added = @(); $skipped = @(); $needs = @()
foreach ($prop in $incoming.PSObject.Properties) {
  if ($dst.mcpServers.PSObject.Properties[$prop.Name]) { $skipped += $prop.Name; continue }
  $cfg = Expand-Node $prop.Value
  # Native Windows cannot spawn npx.cmd directly: wrap as cmd /c npx ...
  if ($cfg.PSObject.Properties['command'] -and $cfg.command -eq 'npx') {
    $cfg.command = 'cmd'
    $cfg.args = @('/c', 'npx') + @($cfg.args)
  }
  $dst.mcpServers | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $cfg
  $added += $prop.Name
  if ((ConvertTo-Json $cfg -Depth 100 -Compress) -match 'REPLACE_ME') { $needs += $prop.Name }
}
if (Test-Path $ClaudeJson) { Copy-Item $ClaudeJson "$ClaudeJson.bak-$Stamp" }
Write-Utf8 $ClaudeJson (ConvertTo-Json $dst -Depth 100)
Write-Host ("  added:   " + $(if ($added) { $added -join ', ' } else { '(none)' }))
Write-Host ("  skipped (already configured): " + $(if ($skipped) { $skipped -join ', ' } else { '(none)' }))
if ($needs) { Write-Host ("  NEEDS SECRETS (<REPLACE_ME> placeholders): " + ($needs -join ', ')) }

# 5. Plugin marketplaces + plugins (best effort, needs claude CLI) ------------
# Scoped 'Continue': in PS 5.1, native stderr under *> becomes an ErrorRecord that 'Stop' would turn fatal.
if (Has 'claude') { & { $ErrorActionPreference = 'Continue'
  Say 'Adding plugin marketplaces'
  $markets = ConvertFrom-Json (Read-Utf8 (Join-Path $RepoDir 'plugins\marketplaces.json'))
  foreach ($m in $markets.PSObject.Properties) {
    claude plugin marketplace add $m.Value *> $null
    if ($LASTEXITCODE -eq 0) { "  + $($m.Value)" } else { "  = $($m.Value) (already added or unreachable)" }
  }
  Say 'Installing enabled plugins'
  $settings = ConvertFrom-Json (Read-Utf8 (Join-Path $RepoDir 'claude\settings.json'))
  foreach ($p in $settings.enabledPlugins.PSObject.Properties) {
    if (-not $p.Value) { continue }
    claude plugin install $p.Name *> $null
    if ($LASTEXITCODE -eq 0) { "  + $($p.Name)" } else { "  = $($p.Name) (already installed or failed - settings.json still enables it)" }
  }
} } else {
  Warn 'claude CLI not found - skipped marketplace/plugin install. Install Claude Code, then re-run.'
}

# 5b. Serena: web dashboard + GUI log window off ------------------------------
# Missing keys fall back to Serena defaults, so a partial file is valid.
Say 'Disabling Serena web dashboard / GUI log window'
New-Item -ItemType Directory -Force -Path (Split-Path $SerenaCfg) | Out-Null
$yml = if (Test-Path $SerenaCfg) { Read-Utf8 $SerenaCfg } else { '' }
foreach ($key in 'gui_log_window', 'web_dashboard', 'web_dashboard_open_on_launch') {
  $rx = "(?m)^$key\s*:.*$"
  if ($yml -match $rx) { $yml = [regex]::Replace($yml, $rx, "${key}: false") }
  else { $yml = $yml.TrimEnd("`r", "`n") + "`n${key}: false`n" }
}
Write-Utf8 $SerenaCfg $yml.TrimStart("`r", "`n")
Write-Host "  serena UI off: $SerenaCfg"

# 6. ccd alias as a PowerShell profile function (idempotent) -----------------
Say 'Installing PowerShell function: ccd -> claude --dangerously-skip-permissions'
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
  New-Item -ItemType File -Force -Path $PROFILE | Out-Null
}
if (-not (Select-String -Path $PROFILE -Pattern 'function ccd' -Quiet)) {
  Add-Content -Path $PROFILE -Value "`n# ccd - Claude Code with dangerously-skip-permissions`nfunction ccd { claude --dangerously-skip-permissions @args }"
  Write-Host "  + $PROFILE"
} else { Write-Host '  = profile (already defined)' }

# 7. Summary ------------------------------------------------------------------
foreach ($c in 'bash', 'python3') {
  if (-not (Has $c)) { Warn "$c not on PATH - hooks in settings.json call it (install Git for Windows / Python, or alias python3)." }
}
Say 'Done.'
Write-Host "  Installed into: $ClaudeDir"
Write-Host "  Backups:        *.bak-$Stamp (only for files that existed)"
Warn 'Action required:'
Write-Host "  1. Replace every <REPLACE_ME> in $ClaudeJson with your real API keys/secrets."
Write-Host '  2. shopify* MCP entries point to ~/code/StandUpCode/shopify-mcp - clone+build it or remove them.'
Write-Host '  3. Restart Claude Code so settings, hooks, and MCP servers load.'
