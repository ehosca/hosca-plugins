# Celko Rule Catalog

Rules extracted from *Joe Celko's SQL Programming Style* (Morgan-Kaufmann, 2005),
mapped to catalog-queryable checks in `queries/audit.sql`. Section numbers cite the book.

Severity: **ERROR** objective violation · **WARN** deprecated/portability · **INFO** opinionated/preference.

---

## Naming — Chapters 1–2

### N01 — Identifier length > 30 · WARN · §1.1.1
**Rationale:** SQL-92 caps identifiers at 18 chars (from COBOL); modern engines allow more,
but overly long names are hard to read, type, and share with host programs. Oracle historically
capped at 30. **Fix:** shorten to a readable, standard name ≤ 30 chars without vowel-dropping.
**Exception:** legacy systems with fixed names.

### N02 — Non-standard identifier characters · ERROR · §1.1.2
**Rationale:** A name should start with a letter and contain only letters, digits, and single
underscores. Special characters (`$ # @` etc.), a leading non-letter, a trailing underscore, or
doubled underscores break portability and host-language interop; Intermediate SQL-92 forbids a
trailing underscore, and chained underscores are unreadable. **Fix:** rename using
`[A-Za-z][A-Za-z0-9_]*` with single underscores.

### N03 — Name requires quoting · WARN · §1.1.3
**Rationale:** Names that are reserved words or contain spaces force delimited/quoted
identifiers (`[ ]`, `" "`), which destroy portability and break tools like ADO. **Fix:** rename
to a non-reserved, space-free identifier. **Exception:** quoted aliases for display output only.

### N04 — Descriptive/Hungarian prefix · INFO · §1.2.3
**Rationale:** Prefixes like `tbl_`, `vw_`, `sp_`, `usp_`, `fn_` encode the object's type into its
name (Hungarian notation). The type is metadata the engine already tracks; the prefix is noise and
breaks if the object's role changes. Note `sp_` on procedures also triggers a master-database lookup
in SQL Server. **Fix:** drop the prefix; name by what the object *is*.

### N05 — CamelCase column name · INFO · §2.1.2 / §2.1.5
**Rationale:** Celko's typography convention: scalars (column names, parameters, variables) in
lowercase, schema-level objects (tables, views) capitalized, reserved words uppercase. CamelCase
columns are harder to scan and collide with case-sensitivity differences across engines.
**Fix:** `lowercase_with_underscores` for columns. **Exception:** house styles that consistently
choose otherwise.

### N06 — Missing ISO-11179 postfix · INFO · §1.2.4
**Rationale:** ISO-11179 attribute names end in a postfix that states the attribute's property:
`_id` (unique identifier), `_date`/`_dt`, `_nbr`/`_num` (tag number), `_name`/`_nm`, `_code`/`_cd`,
`_size`, `_tot` (aggregate total), `_seq` (ordinal), `_cat` (external category), `_class` (internal
encoding), `_status` (state). A recognized postfix makes the column self-documenting.
Reported as a per-table coverage count, not per-column spam. **Fix:** add the appropriate postfix.

### N07 — Generic 'id' primary key · INFO · §1.2.3
**Rationale:** A PK column named literally `id` (or `pk`/`key`) carries no business meaning and is
the physical-locator anti-pattern in disguise — every table's key looks the same and joins lose
their semantics. **Fix:** name the key for the entity/attribute it identifies (e.g. `invoice_nbr`),
or at minimum `<entity>_id`. **Exception:** deliberate surrogate-key house style.

---

## Data Declaration — Chapter 3

### D01 — Table has no PRIMARY KEY · ERROR · §3.4
**Rationale:** A relational table *must* have a key. A heap has no logical identity for its rows,
permits duplicates, and forces physical-locator hacks. The PK should be declared first in the
`CREATE TABLE`. **Fix:** add a `PRIMARY KEY` (ideally a natural/business key).

### D02 — IDENTITY used as key · INFO · §1.3.3
**Rationale:** `IDENTITY` (like `GUID`/`ROWID`) is an auto-numbering vendor extension that imitates
a magnetic tape's sequential access. Using it *as the key* exposes a proprietary physical locator
and violates the relational notion of a key. **Fix:** prefer a natural key; if a surrogate is truly
needed, don't treat insertion order as meaningful. **Exception:** staging/scrub tables outside the
"real" schema.

### D03 — uniqueidentifier primary key · INFO · §1.3.3
**Rationale:** Same physical-locator objection as D02, plus GUID keys bloat indexes and fragment
clustered storage. **Fix:** prefer a natural key; if a surrogate is required, weigh a sequence over
a random GUID.

### D04 — FLOAT/REAL column · ERROR · §3.8.4
**Rationale:** Binary floating point carries rounding error unsuitable for commercial/monetary data.
SQL's `NUMERIC`/`DECIMAL` give exact scale and precision. **Fix:** convert to `DECIMAL(p,s)`.
**Exception:** genuine scientific/statistical data.

### D05 — Deprecated/proprietary data type · WARN · §3.3
**Rationale:** Proprietary types hurt portability; `TEXT`/`NTEXT`/`IMAGE` are deprecated (removed in
future SQL Server versions) and `MONEY`/`SMALLMONEY`/`SQL_VARIANT` are proprietary. **Fix:**
`VARCHAR(MAX)`/`NVARCHAR(MAX)`/`VARBINARY(MAX)` for the LOB types; `DECIMAL` for money.

### D06 — System-generated constraint name · WARN · §3.7
**Rationale:** Unnamed constraints get machine names (`PK__…__hash`, `DF__…`) that are unreadable,
unstable across deployments, and useless in error messages. Production code should name every
constraint. **Fix:** `CONSTRAINT <clear_name> …`. **Exception:** Celko allows omitting names on
PK/UNIQUE/FK during development, but production DDL should name them for consistency.

### D07 — Numeric column without range CHECK · INFO · §3.8.1
**Rationale:** The database is the single trusted repository; business rules (e.g. "≥ 0") belong in
`CHECK` constraints, not just application code. Most numeric columns ship with no range constraint.
Reported as a per-table coverage count (columns not referenced by any CHECK). **Fix:** add range
`CHECK`s. **Exception:** columns that genuinely accept any value.

---

## Views — Chapter 7

### V01 — SELECT * in view · WARN · §7.1.1
**Rationale:** `SELECT *` in a view binds it to the base table's current column list; adding/dropping
base columns silently changes or breaks the view, and column order is undefined. Always enumerate
columns. **Fix:** list columns explicitly and refresh with `sp_refreshview` if needed.
*Heuristic check — verify the match isn't `a * b` arithmetic.*

---

## Coding / Modules — Chapter 6

### C01 — Trigger present · INFO · §6.5
**Rationale:** Prefer declarative referential integrity (`FOREIGN KEY … ON DELETE/UPDATE`) over
procedural triggers; triggers hide logic, fire per-statement, and complicate reasoning. **Fix:**
replace with DRI actions or CHECK/computed columns where possible. **Exception:** logic DRI can't
express (cross-table assertions, audit trails).

### C02 — Optimizer hint in module · WARN · §6.4
**Rationale:** Hints (`WITH (NOLOCK)`, `FORCESEEK`, `INDEX(...)`, `OPTION (...)`) freeze plan choices
and mask design/statistics problems; `NOLOCK` also permits dirty reads. **Fix:** remove hints; fix
the underlying indexing/statistics. *Heuristic — confirm the hint is live code, not a comment.*

### C03 — Legacy outer-join syntax · WARN · §6.1.1
**Rationale:** The old `*=` / `=*` outer-join operators are ambiguous, non-standard, and removed
under modern compatibility levels. **Fix:** rewrite with ANSI `LEFT/RIGHT OUTER JOIN`.
*Heuristic — `*=` can appear in `SET x *= y`; verify.*

### C04 — Proprietary function in module · INFO · §6.1.4
**Rationale:** Prefer standard/portable functions: `CURRENT_TIMESTAMP` over `GETDATE()`, `COALESCE`
over `ISNULL` (COALESCE is standard and n-ary). **Fix:** substitute the standard function.
*Heuristic — string match may hit comments.*
