<#
.SYNOPSIS
  Convierte líneas JSON de `rg --json` en una línea uniforme por match:
  archivo<TAB>numero_linea<TAB>texto
  Único punto de parseo JSON para devql en PowerShell (Opción A).
#>
function Parse-RgJson {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [string]$Line
  )
  begin {}
  process {
    if ([string]::IsNullOrWhiteSpace($Line)) { return }
    try {
      $o = $Line | ConvertFrom-Json -ErrorAction Stop
    } catch {
      return
    }
    if ($null -eq $o -or $o.type -ne 'match') { return }
    $path = $null
    if ($null -ne $o.data.path.text) {
      $path = [string]$o.data.path.text
    } elseif ($null -ne $o.data.path -and $o.data.path -is [string]) {
      $path = $o.data.path
    }
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    $lineNo = $o.data.line_number
    $text = $o.data.lines.text
    if ($null -ne $text) {
      $text = ($text -replace "[\r\n]+", ' ').TrimEnd()
    } else {
      $text = ''
    }
    "${path}`t${lineNo}`t${text}"
  }
  end {}
}
