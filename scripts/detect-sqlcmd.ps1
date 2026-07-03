<#
.SYNOPSIS
  Locate a usable sqlcmd executable. Prints the resolved full path to stdout and
  exits 0 on success; prints install guidance to stderr and exits 1 if not found.

.DESCRIPTION
  Probe order:
    1. sqlcmd on PATH
    2. go-sqlcmd installed via winget (%LOCALAPPDATA%\Microsoft\WinGet\Links)
    3. ODBC / SSMS / Visual Studio tools (Client SDK\ODBC\<ver>\Tools\Binn)
  The caller (the sql-audit skill) uses the printed path to run audit.sql.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

function Test-Sqlcmd([string]$Path) {
    if ($Path -and (Test-Path -LiteralPath $Path)) { return (Get-Item -LiteralPath $Path).FullName }
    return $null
}

# 1. PATH
$onPath = (Get-Command sqlcmd -CommandType Application -ErrorAction SilentlyContinue |
           Select-Object -First 1).Source
if ($onPath) { Write-Output $onPath; exit 0 }

# 2. go-sqlcmd via winget shim
$wingetShim = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\sqlcmd.exe'
$found = Test-Sqlcmd $wingetShim
if ($found) { Write-Output $found; exit 0 }

# 3. ODBC / SSMS / VS bundled tools (newest version first)
$binnRoots = @(
    (Join-Path ${env:ProgramFiles}        'Microsoft SQL Server\Client SDK\ODBC'),
    (Join-Path ${env:ProgramFiles(x86)}   'Microsoft SQL Server\Client SDK\ODBC')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

foreach ($root in $binnRoots) {
    $candidate = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                 Sort-Object { [int]($_.Name -replace '\D','0') } -Descending |
                 ForEach-Object { Join-Path $_.FullName 'Tools\Binn\SQLCMD.EXE' } |
                 Where-Object { Test-Path -LiteralPath $_ } |
                 Select-Object -First 1
    if ($candidate) { Write-Output ((Get-Item -LiteralPath $candidate).FullName); exit 0 }
}

# Not found — guidance to stderr, non-zero exit so the skill can prompt the user.
$msg = @'
sqlcmd was not found on this system.

Install the open-source go-sqlcmd (recommended):
    winget install sqlcmd

Or download a release directly:
    https://github.com/microsoft/go-sqlcmd/releases

sqlcmd also ships with SSMS, Visual Studio, and the Microsoft ODBC Driver for SQL Server.
'@
[Console]::Error.WriteLine($msg)
exit 1
