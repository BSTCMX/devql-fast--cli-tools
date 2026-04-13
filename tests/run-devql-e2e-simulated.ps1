# E2E simulado: mismo flujo que devql files / devql text sin TUI interactiva.
# Uso: powershell -File tests/run-devql-e2e-simulated.ps1
# Requiere PATH con rg, fd, fzf, bat (Core).
$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root
$noop = (Resolve-Path (Join-Path $PSScriptRoot 'devql-noop-editor.cmd')).Path

foreach ($c in @('rg', 'fd', 'fzf')) {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "Falta en PATH: $c" }
}

Write-Host '--- devql files (filter README.md + editor noop) ---' -ForegroundColor Cyan
$env:EDITOR = $noop
$env:FZF_DEFAULT_OPTS = '--filter README.md --select-1'
& (Join-Path $Root 'bin\devql.ps1') files
if ($LASTEXITCODE -ne 0) { throw "devql files exit $LASTEXITCODE" }

Write-Host '--- devql text function (sin code en PATH para forzar noop; filter Parse-RgJson) ---' -ForegroundColor Cyan
$env:EDITOR = $noop
$env:FZF_DEFAULT_OPTS = '--filter Parse-RgJson --select-1'
# Evitar que Invoke-DevqlEditor use code -g antes que EDITOR (comportamiento normal si code existe)
$env:Path = ($env:Path -split ';' | Where-Object {
    $_ -and ($_ -notmatch '[\\/]cursor[\\/]') -and ($_ -notmatch 'codeBin') -and ($_ -notmatch 'Microsoft VS Code')
  }) -join ';'
if (Get-Command code -ErrorAction SilentlyContinue) {
  throw 'Aun resuelve code en PATH; ajusta el filtro de Path en este script.'
}

& (Join-Path $Root 'bin\devql.ps1') text function
if ($LASTEXITCODE -ne 0) { throw "devql text exit $LASTEXITCODE" }

Write-Host 'run-devql-e2e-simulated: OK' -ForegroundColor Green
exit 0
