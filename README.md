# hosca-plugins

A [Claude Code](https://code.claude.com/docs/en/plugins) plugin **marketplace** for database and
SQL Server tooling.

## Plugins

| Plugin | Description |
|--------|-------------|
| [**sql-audit-skill**](plugins/sql-audit-skill) | Audit a SQL Server database against Joe Celko's *SQL Programming Style* — read-only catalog queries via `sqlcmd`, severity-tiered findings report. |

## Install

```
/plugin marketplace add ehosca/hosca-plugins
/plugin install sql-audit-skill@hosca-plugins
```

The first command registers this marketplace from the GitHub repo; the second installs the plugin.
The skill is then invokable as `/sql-audit` — see the
[plugin README](plugins/sql-audit-skill/README.md) for usage, connection/credential handling, and
the full rule catalog.

### Local / development install

From a clone of this repo:

```
/plugin marketplace add ./
/plugin install sql-audit-skill@hosca-plugins
```

### Updating

```
/plugin marketplace update hosca-plugins
/plugin install sql-audit-skill@hosca-plugins
```

Users receive an update only when the plugin's `version` (in
[`plugins/sql-audit-skill/.claude-plugin/plugin.json`](plugins/sql-audit-skill/.claude-plugin/plugin.json))
is bumped. Omitting `version` instead tracks every commit SHA as a new version.

## Layout

```
.claude-plugin/marketplace.json   marketplace catalog (name: hosca-plugins)
plugins/
  sql-audit-skill/                the plugin (own .claude-plugin/plugin.json, skills, commands, scripts, tests)
```

## License

MIT — see [LICENSE](LICENSE).
