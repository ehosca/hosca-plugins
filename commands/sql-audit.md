---
description: Audit a SQL Server database against Joe Celko's SQL Programming Style and write a tiered findings report.
argument-hint: [server] [database] [-E | -U <user> | --context <name>]
---

Run a Celko-style audit of a SQL Server database.

Arguments (optional — ask for anything missing): `$ARGUMENTS`
- first token → server (`-S`)
- second token → database (`-d`)
- auth: `-E` (trusted, preferred) or `-U <user>`
- `--context <name>` → use a saved **go-sqlcmd context** (server + encrypted credentials);
  then only the database is needed. If the flavor detected isn't go-sqlcmd, contexts are
  unavailable — offer to `winget install sqlcmd` or fall back to the per-run flow.

**Do not accept a password in these arguments** — they are logged in the transcript. For SQL
auth, the skill prompts for the password securely and passes it via the `SQLCMDPASSWORD`
environment variable, never on the command line. Prefer `-E` (trusted auth) when possible.
Nothing is persisted; credentials exist only for the single run.

Use the **sql-audit** skill. Steps:
1. Run `scripts/detect-sqlcmd.ps1` to locate sqlcmd; if missing, show its guidance and
   ask before installing go-sqlcmd (`winget install sqlcmd`).
2. Confirm server / database / auth with the user.
3. Execute `skills/sql-audit/queries/audit.sql` via sqlcmd (pipe-delimited, headerless).
4. Cross-reference `skills/sql-audit/references/celko-rules.md` and write `audit-report.md`
   grouped by severity (ERROR / WARN / INFO) with rule name, book section, rationale,
   affected objects, and remediation.

The audit is strictly read-only.
