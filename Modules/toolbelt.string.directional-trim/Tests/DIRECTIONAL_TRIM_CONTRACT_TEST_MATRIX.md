# Directional TRIM Contract-Testmatrix

| Bereich | Synthetische Fälle | Status |
|---|---|---|
| Position | `LEADING`, `TRAILING`, `BOTH`, leerer Zeichensatz | vorgesehen |
| Literalität | `%`, `_`, `[`, `]` und doppelte Zeichen | vorgesehen |
| Datentypen | `varchar`, `nvarchar`, `NULL`, `NCHAR(0)` | vorgesehen |
| Collation | CI, CS, BIN2 und UTF-8-varchar | vorgesehen |
| Parität | SQL Server 2022/2025 bei Compatibility 160/170 | vorgesehen |

Aktuelle Evidenz: [W1 Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml) – `not executed`.
