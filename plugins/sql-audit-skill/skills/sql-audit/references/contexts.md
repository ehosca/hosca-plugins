# go-sqlcmd Connection Contexts

A **context** is a named, reusable connection saved by go-sqlcmd, so the user picks a target
once instead of re-entering server/database/credentials on every audit. For SQL logins the
password is stored **encrypted** (Windows DPAPI) rather than retyped or passed on the command line.

> Contexts are a **go-sqlcmd-only** feature. The classic ODBC `sqlcmd.exe` (the one under
> `Client SDK\ODBC\<ver>\Tools\Binn`) does not support `config` or `--context`.
> `scripts/detect-sqlcmd.ps1` reports `"supportsContexts": true` only when the resolved binary
> is go-sqlcmd. If it isn't, either use the per-run `SQLCMDPASSWORD` flow or install go-sqlcmd
> (`winget install sqlcmd`).

## Model

```
context ──references──> endpoint (address + port)
        └─references──> user (optional; omit for Windows/integrated auth)
```

Config lives at `%USERPROFILE%\.sqlcmd\sqlconfig` (YAML). Never commit it — the repo's
`.gitignore` excludes `sqlconfig` and `.sqlcmd/`.

## List / inspect

```
sqlcmd config get-contexts        # names to choose from
sqlcmd config get-endpoints
sqlcmd config get-users
sqlcmd config current-context
sqlcmd config view                # full config (passwords are encrypted, not shown plaintext)
```

## Create — trusted (Windows) auth · no stored secret

```
sqlcmd config add-endpoint --name auditsrv-ep --address localhost --port 1433
sqlcmd config add-context  --name auditsrv    --endpoint auditsrv-ep
```

Omit `--user` → the context uses integrated security.

## Create — SQL login · password stored encrypted

If the password is already in Windows Credential Manager, the agent can do this non-interactively:

```powershell
$env:SQLCMDPASSWORD = & "<plugin>/scripts/credential.ps1" get -Server db.example.com -User auditor
try {
    sqlcmd config add-endpoint --name auditsrv-ep --address db.example.com --port 1433
    sqlcmd config add-user     --name audit-login --username auditor --password-encryption dpapi
    sqlcmd config add-context  --name auditsrv    --endpoint auditsrv-ep --user audit-login
}
finally { Remove-Item Env:\SQLCMDPASSWORD -ErrorAction SilentlyContinue }
```

Otherwise run the block yourself with an interactive prompt (the agent's shell cannot prompt).
Works on Windows PowerShell 5.1 and PowerShell 7:

```powershell
$sec  = Read-Host 'SQL password' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$env:SQLCMDPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
try {
    sqlcmd config add-endpoint --name auditsrv-ep --address db.example.com --port 1433
    sqlcmd config add-user     --name audit-login --username auditor --password-encryption dpapi
    sqlcmd config add-context  --name auditsrv    --endpoint auditsrv-ep --user audit-login
}
finally { Remove-Item Env:\SQLCMDPASSWORD -ErrorAction SilentlyContinue }
```

**Always pass `--password-encryption dpapi` on Windows.** The default (`none`) stores the
password base64-encoded — effectively plaintext — in `sqlconfig`. `add-user` reads the secret
from the `SQLCMDPASSWORD` environment variable, so it never appears in `argv` or shell history.
(On macOS/Linux the equivalent value is `keychain-...`; go-sqlcmd rejects `dpapi` off-Windows.)

## Run the audit against a context

```powershell
sqlcmd --context auditsrv -d <database> -C -N `
  -i "<plugin>/skills/sql-audit/queries/audit.sql" `
  -s "|" -W -h -1 -w 65535
```

- `--context` supplies server + auth; `-d` selects the database to audit (contexts don't bind one).
- No credentials touch the command line — the stored (encrypted) password is used automatically.
- `sqlcmd config use-context <name>` sets a default so plain `sqlcmd -d <db> -i …` also works.

## Named instances

Endpoints are `address` + `port`. For a named instance (`HOST\SQLEXPRESS`) supply its TCP port
(or enable SQL Browser). If the port is unknown and you're local, skip contexts and use the
per-run flow with `-S HOST\SQLEXPRESS -E`.

## Delete / clean up

```
sqlcmd config delete-context  --name auditsrv
sqlcmd config delete-endpoint --name auditsrv-ep
sqlcmd config delete-user     --name audit-login
```
