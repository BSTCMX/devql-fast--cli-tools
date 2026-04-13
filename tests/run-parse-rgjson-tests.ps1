# Tests manuales de Parse-RgJson (sin Pester). Ejecutar: powershell -File tests/run-parse-rgjson-tests.ps1
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root 'lib\Parse-RgJson.ps1')

function Assert-Equal {
  param($A, $B, [string]$Msg)
  if ($A -ne $B) { throw "FAIL: $Msg - expected [$B] got [$A]" }
}

$j1 = @'
{"type":"match","data":{"path":{"text":"C:\\src\\app.ts"},"lines":{"text":"hello\n"},"line_number":10,"submatches":[]}}
'@
$r1 = @($j1 | Parse-RgJson)
Assert-Equal $r1[0] "C:\src\app.ts`t10`thello" 'basic match'

$j2 = @'
{"type":"match","data":{"path":{"text":"/home/u/x.go"},"lines":{"text":"a\nb\n"},"line_number":2}}
'@
$r2 = @($j2 | Parse-RgJson)
Assert-Equal $r2[0] "/home/u/x.go`t2`ta b" 'multiline collapsed'

$j3 = @'
{"type":"begin","data":{"path":{"text":"x"}}}
'@
$r3 = @($j3 | Parse-RgJson)
if ($r3.Count -ne 0) { throw 'FAIL: begin should emit nothing' }

Write-Host 'Parse-RgJson tests: OK' -ForegroundColor Green
exit 0
