#Requires -Version 5.1
<#
.SYNOPSIS
  Instala tier Core con winget y genera shims en %USERPROFILE%\bin apuntando a este repo.
.PARAMETER Extended
  Best-effort: delta, jq, PSFzf (puede fallar en redes restringidas).
#>
param(
  [switch]$Extended
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Ps1 = Join-Path $RepoRoot 'bin\devql.ps1'
$UserBin = Join-Path $env:USERPROFILE 'bin'
New-Item -ItemType Directory -Force -Path $UserBin | Out-Null

function Install-WingetCore {
  $ids = @(
    'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd',
    'junegunn.fzf',
    'ajeetdsouza.zoxide',
    'sharkdp.bat'
  )
  foreach ($id in $ids) {
    try {
      winget install -e --id $id --accept-package-agreements --accept-source-agreements
    } catch {
      Write-Warning "winget fallo para ${id}: $_"
    }
  }
}

Write-Host '=== devql setup (Core) ===' -ForegroundColor Cyan
if (Get-Command winget -ErrorAction SilentlyContinue) {
  Install-WingetCore
} else {
  Write-Warning 'winget no encontrado. Instala rg, fd, fzf, zoxide, bat manualmente (ver INSTALACION.md).'
}

# Shims con ruta absoluta al launcher
$devqlCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$Ps1" %*
"@
$qfilesCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$Ps1" files %*
"@
$qtxtCmd = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$Ps1" text %*
"@

Set-Content -Path (Join-Path $UserBin 'devql.cmd') -Value $devqlCmd -Encoding ASCII
Set-Content -Path (Join-Path $UserBin 'qfiles.cmd') -Value $qfilesCmd -Encoding ASCII
Set-Content -Path (Join-Path $UserBin 'qtxt.cmd') -Value $qtxtCmd -Encoding ASCII

Write-Host "Shims escritos en: $UserBin"

$pathUser = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($pathUser -notmatch [regex]::Escape($UserBin)) {
  [Environment]::SetEnvironmentVariable('Path', "$UserBin;$pathUser", 'User')
  Write-Host "PATH de usuario actualizado: se anadio $UserBin" -ForegroundColor Green
  Write-Host 'Abre una NUEVA ventana de terminal para que herede el PATH.' -ForegroundColor Yellow
} else {
  Write-Host 'PATH de usuario ya contiene ~/bin.' -ForegroundColor Green
}

[Environment]::SetEnvironmentVariable('DEV_ENV_ROOT', $RepoRoot, 'User')
Write-Host "DEV_ENV_ROOT=$RepoRoot (variable de usuario)"

if ($Extended) {
  Write-Host '=== Extended (best-effort) ===' -ForegroundColor Cyan
  $ext = @('dandavison.delta', 'jqlang.jq')
  foreach ($id in $ext) {
    try { winget install -e --id $id --accept-package-agreements --accept-source-agreements } catch { Write-Warning $_ }
  }
  try {
    Install-Module -Name PSFzf -Scope CurrentUser -Force -ErrorAction Stop
    Write-Host 'PSFzf instalado. Importa el modulo en tu perfil (ver GUIA-CLI.md).' -ForegroundColor Green
  } catch {
    Write-Warning "PSFzf no instalado: $_"
  }
}

Write-Host 'Listo. Verifica: rg --version; fd --version; fzf --version; Get-Command bat' -ForegroundColor Cyan
exit 0
