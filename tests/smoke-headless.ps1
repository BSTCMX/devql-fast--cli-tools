# Smoke no interactivo (sin abrir fzf TUI). Requiere PATH con rg, fd, fzf.
# Ejecutar: powershell -File tests/smoke-headless.ps1
$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root

foreach ($c in @('rg', 'fd', 'fzf', 'bat')) {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) {
    throw "Missing on PATH: $c"
  }
}

. (Join-Path $Root 'lib\Parse-RgJson.ps1')

$pick = (fd --type f | fzf -f 'devql.ps1' | Select-Object -First 1)
if ($pick -notmatch 'devql\.ps1') { throw "fzf filter files: esperaba devql.ps1, obtuve: $pick" }

$line = (& rg --json 'function' lib 2>$null | Parse-RgJson | fzf -f 'Parse-RgJson' | Select-Object -First 1)
if (-not $line) { throw 'pipeline text vacia' }
if ($line -notmatch 'Parse-RgJson\.ps1') { throw "fzf filter text: linea inesperada: $line" }

Write-Host 'smoke-headless: OK' -ForegroundColor Green
exit 0
