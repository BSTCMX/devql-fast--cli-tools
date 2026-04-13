#Requires -Version 5.1
<#
  devql — PowerShell (Windows). Same contract as bin/devql (bash).
  text: rg --json | Parse-RgJson | fzf (Option A).
  Runtime messages: English (v1.0). Read-only + open in editor (no repo/system writes).
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptRoot '..')).Path
. (Join-Path $RepoRoot 'lib\Parse-RgJson.ps1')

function Get-DevqlVersion {
  $vf = Join-Path $RepoRoot 'lib\VERSION'
  if (Test-Path -LiteralPath $vf) {
    return (Get-Content -LiteralPath $vf -Raw).Trim()
  }
  return '0.0.0'
}

function Test-CommandExists {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Single package manager hint per OS (Windows): winget one-liners from INSTALACION.md
function Get-CoreInstallHint {
  param([string]$Binary)
  switch ($Binary) {
    'rg' { return 'winget install -e --id BurntSushi.ripgrep.MSVC' }
    'fd' { return 'winget install -e --id sharkdp.fd' }
    'fzf' { return 'winget install -e --id junegunn.fzf' }
    default { return 'See INSTALACION.md (Windows / Core).' }
  }
}

function Write-DevqlPreflightError {
  param([string]$Binary)
  $hint = Get-CoreInstallHint -Binary $Binary
  Write-Host "Error: '$Binary' not found in PATH." -ForegroundColor Red
  Write-Host "Install (Windows): $hint"
  Write-Host 'Or run .\setup.ps1 from the repo root (see INSTALACION.md).'
}

function Invoke-DevqlEditor {
  param(
    [string]$FilePath,
    [int]$LineNumber = 0
  )
  if ([string]::IsNullOrWhiteSpace($FilePath)) { return }

  if ($LineNumber -gt 0 -and (Test-CommandExists 'code')) {
    & code -g "${FilePath}:${LineNumber}"
    return
  }

  $ed = if (-not [string]::IsNullOrWhiteSpace($env:EDITOR)) { $env:EDITOR } else { $null }

  if (-not [string]::IsNullOrWhiteSpace($ed)) {
    if ($LineNumber -gt 0 -and ($ed -match 'vim|nvim|gvim')) {
      & $ed "+$LineNumber" $FilePath
      return
    }
    if ($LineNumber -gt 0 -and ($ed -match '^code')) {
      & code -g "${FilePath}:${LineNumber}"
      return
    }
    if ($LineNumber -gt 0) {
      Write-Host "Notice: opening file without reliable line jump for this editor." -ForegroundColor Yellow
    }
    & $ed $FilePath
    return
  }

  if ($LineNumber -gt 0) {
    Write-Host 'Notice: no EDITOR set; opening with Notepad (no line jump).' -ForegroundColor Yellow
  }
  notepad.exe $FilePath
}

function Invoke-DevqlFiles {
  if (-not (Test-CommandExists 'fd')) {
    Write-DevqlPreflightError 'fd'
    exit 1
  }
  if (-not (Test-CommandExists 'fzf')) {
    Write-DevqlPreflightError 'fzf'
    exit 1
  }

  $preview = if (Test-CommandExists 'bat') {
    'bat --style=numbers --color=always {}'
  } else {
    'type {}'
  }

  $fdOut = & fd --type f --hidden --exclude .git 2>$null
  if ($null -eq $fdOut) { $fdOut = @() }
  $list = @($fdOut | ForEach-Object { $_ })
  if ($list.Count -eq 0) {
    Write-Host 'No files found in this tree.' -ForegroundColor Yellow
    exit 0
  }

  $sel = $list | fzf --preview $preview --preview-window 'right:60%'
  if ([string]::IsNullOrWhiteSpace($sel)) { exit 0 }
  Invoke-DevqlEditor $sel.Trim() 0
}

function Invoke-DevqlText {
  param([string]$Pattern)
  if ([string]::IsNullOrWhiteSpace($Pattern)) {
    $Pattern = Read-Host 'Search pattern (ripgrep)'
  }
  if ([string]::IsNullOrWhiteSpace($Pattern)) {
    Write-Host 'Error: empty pattern.' -ForegroundColor Red
    exit 1
  }

  if (-not (Test-CommandExists 'rg')) {
    Write-DevqlPreflightError 'rg'
    exit 1
  }
  if (-not (Test-CommandExists 'fzf')) {
    Write-DevqlPreflightError 'fzf'
    exit 1
  }

  $preview = if (Test-CommandExists 'bat') {
    'bat --style=numbers --color=always {1}'
  } else {
    'type {1}'
  }

  $normalized = @(& rg --json --smart-case $Pattern . 2>$null | Parse-RgJson)
  if ($normalized.Count -eq 0) {
    Write-Host 'No matches.' -ForegroundColor Yellow
    exit 0
  }

  $sel = $normalized | fzf --delimiter "`t" --with-nth '2,3' --preview $preview --preview-window 'right:60%'
  if ([string]::IsNullOrWhiteSpace($sel)) { exit 0 }

  $parts = $sel -split "`t", 3
  $fpath = $parts[0]
  $ln = 0
  [void][int]::TryParse($parts[1], [ref]$ln)
  Invoke-DevqlEditor $fpath $ln
}

function Show-DevqlHelp {
  $ver = Get-DevqlVersion
  @"
devql v$ver — read-only search/navigation; opens your editor only when you pick a result.

USAGE:
  devql files           Pick a file by name (fd -> fzf -> editor)
  devql text [PATTERN]  Search file contents (rg --json -> fzf -> editor; line jump when supported)
  devql help
  devql --version

Shortcuts (after setup / shims on PATH):
  qfiles  -> devql files
  qtxt    -> devql text

Editor: VS Code / Cursor (code on PATH) is best for line jumps in text mode.
        Otherwise EDITOR, else Notepad on Windows.

More: GUIA-CLI.md
"@ | Write-Host
}

$verFlag = $false
$sub = $null
if ($args.Count -gt 0) {
  $a0 = [string]$args[0]
  if ($a0 -eq '--version' -or $a0 -eq '-v') { $verFlag = $true }
  else { $sub = $a0 }
}

if ($verFlag) {
  $v = Get-DevqlVersion
  Write-Host "devql v$v"
  exit 0
}

if ($null -eq $sub -or [string]::IsNullOrWhiteSpace([string]$sub)) {
  Show-DevqlHelp
  exit 0
}

switch -Regex ($sub) {
  '^files$' { Invoke-DevqlFiles }
  '^text$' {
    $rest = @()
    if ($args.Count -gt 1) { $rest = $args[1..($args.Count - 1)] }
    $pat = $rest -join ' '
    Invoke-DevqlText $pat
  }
  '^(help|-h|--help)$' { Show-DevqlHelp }
  default {
    Write-Host "Error: unknown subcommand: $sub" -ForegroundColor Red
    Write-Host 'Use: devql help'
    exit 1
  }
}
