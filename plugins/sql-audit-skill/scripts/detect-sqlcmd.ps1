<#
.SYNOPSIS
  Locate a usable sqlcmd executable and report its flavor. On success prints a single
  JSON line to stdout and exits 0; on failure prints install guidance to stderr, exits 1.

.OUTPUTS
  {"path":"<full path>","flavor":"go-sqlcmd"|"odbc","supportsContexts":true|false}

.DESCRIPTION
  Probe order for the executable:
    1. sqlcmd on PATH
    2. go-sqlcmd installed via winget (%LOCALAPPDATA%\Microsoft\WinGet\Links)
    3. ODBC / SSMS / Visual Studio tools (Client SDK\ODBC\<ver>\Tools\Binn)
  Flavor: go-sqlcmd supports reusable connection "contexts" (sqlcmd config ...);
  the classic ODBC sqlcmd.exe does not. Contexts require flavor = go-sqlcmd.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

function Resolve-Exe([string]$Path) {
    if ($Path -and (Test-Path -LiteralPath $Path)) { return (Get-Item -LiteralPath $Path).FullName }
    return $null
}

function Get-Flavor([string]$Path) {
    # The winget shim is always go-sqlcmd.
    if ($Path -like '*\WinGet\Links\*') { return 'go-sqlcmd' }
    # Functional probe: only go-sqlcmd understands the `config` command tree.
    # Classic ODBC sqlcmd errors on the unknown option and exits non-zero. No network I/O.
    & $Path config view *> $null 2>&1
    if ($LASTEXITCODE -eq 0) { return 'go-sqlcmd' }
    return 'odbc'
}

$resolved = $null

# 1. PATH
$resolved = (Get-Command sqlcmd -CommandType Application -ErrorAction SilentlyContinue |
             Select-Object -First 1).Source

# 2. go-sqlcmd via winget shim
if (-not $resolved) {
    $resolved = Resolve-Exe (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\sqlcmd.exe')
}

# 3. ODBC / SSMS / VS bundled tools (newest version first)
if (-not $resolved) {
    $binnRoots = @(
        (Join-Path ${env:ProgramFiles}      'Microsoft SQL Server\Client SDK\ODBC'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft SQL Server\Client SDK\ODBC')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    foreach ($root in $binnRoots) {
        $candidate = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                     Sort-Object { [int]($_.Name -replace '\D','0') } -Descending |
                     ForEach-Object { Join-Path $_.FullName 'Tools\Binn\SQLCMD.EXE' } |
                     Where-Object { Test-Path -LiteralPath $_ } |
                     Select-Object -First 1
        if ($candidate) { $resolved = (Get-Item -LiteralPath $candidate).FullName; break }
    }
}

if ($resolved) {
    $flavor = Get-Flavor $resolved
    [pscustomobject]@{
        path             = $resolved
        flavor           = $flavor
        supportsContexts = ($flavor -eq 'go-sqlcmd')
    } | ConvertTo-Json -Compress
    exit 0
}

# Not found — guidance to stderr, non-zero exit so the skill can prompt the user.
$msg = @'
sqlcmd was not found on this system.

Install the open-source go-sqlcmd (recommended — enables reusable connection contexts):
    winget install sqlcmd

Or download a release directly:
    https://github.com/microsoft/go-sqlcmd/releases

sqlcmd also ships with SSMS, Visual Studio, and the Microsoft ODBC Driver for SQL Server,
but those bundle the classic ODBC sqlcmd, which does NOT support contexts.
'@
[Console]::Error.WriteLine($msg)
exit 1
