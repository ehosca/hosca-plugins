# Changelog

All notable changes to **sql-audit-skill** are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/). The authoritative version is the `version` field in
[`.claude-plugin/plugin.json`](.claude-plugin/plugin.json); bump it on every release (see the
marketplace [`RELEASING.md`](../../RELEASING.md)).

## [Unreleased]

## [0.1.1] - 2026-07-05
### Fixed
- **N04** no longer false-flags ordinary names like `Vendor`/`Version`: the camel-prefix patterns
  (`tbl[A-Z]%`, `v[A-Z]%`) now use a binary collation — under case-insensitive collations `[A-Z]`
  also matched lowercase, so any object starting with "v" + letter tripped the rule.
- **N02** now catches non-ASCII identifier characters (e.g. `é`): the `[^A-Za-z0-9_]` /
  `[^A-Za-z]` patterns use a binary collation — under CI collations accented letters sort inside
  the a–z range and slipped through.
- D06/C01 object names use ASCII `->` instead of `→`, which rendered as `?` through sqlcmd's
  console codepage.
- The SQL-auth context-creation snippet in `references/contexts.md` works on Windows
  PowerShell 5.1 (`ConvertFrom-SecureString -AsPlainText` is PowerShell 7+ only).
- SKILL step 2b no longer asks the agent to prompt for a password (its shell is
  non-interactive); it now pulls from Windows Credential Manager or hands the block to the user.
- Runnable examples use one shell dialect (PowerShell backticks + `&` invocation) instead of
  mixing cmd.exe `^` continuations.
- Command workflow paths are anchored to `${CLAUDE_PLUGIN_ROOT}` instead of being relative to
  the user's working directory.
### Changed
- Documented that the plugin is Windows-only (PowerShell, winget, Windows Credential
  Manager/DPAPI) in the README and manifest descriptions.
- Instructions now tell the agent to substitute the real plugin path for `${CLAUDE_PLUGIN_ROOT}`
  when presenting `!` commands to the user (the variable is undefined in the user's shell).

## [0.1.0] - 2026-07-03
### Added
- Initial release: audits a SQL Server database against Joe Celko's *SQL Programming Style*
  (18 rules across naming, data-type/DDL, view, and coding categories) and writes a
  severity-tiered findings report from read-only `sqlcmd` catalog queries.
- `sqlcmd` auto-detection (PATH, winget go-sqlcmd, ODBC/SSMS/VS bundled tools) with an offer to
  install go-sqlcmd when none is found.
- Secure SQL-auth credential handling: prefer trusted auth (`-E`); otherwise store the password in
  Windows Credential Manager (DPAPI, user-scoped) and pass it via `SQLCMDPASSWORD` — never `-P` on
  the command line. Includes a `--store` setup mode for first-time credential storage.
- go-sqlcmd connection-context support for reusable named targets.
- Regression fixture under `tests/` covering the six rules absent from AdventureWorks.
