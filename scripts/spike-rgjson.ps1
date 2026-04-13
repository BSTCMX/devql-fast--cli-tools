# Spike aislado: rg --json | Parse-RgJson | fzf (sin editor). Uso desde la raiz del repo:
#   powershell -File scripts/spike-rgjson.ps1 PATRON
param(
  [Parameter(Position = 0)]
  [string]$Pattern = 'test'
)
$Root = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..')).Path
. (Join-Path $Root 'lib\Parse-RgJson.ps1')
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
  Write-Error 'rg no esta en PATH.'
  exit 1
}
& rg --json --smart-case $Pattern . 2>$null | Parse-RgJson | fzf --delimiter "`t" --with-nth '2,3'
