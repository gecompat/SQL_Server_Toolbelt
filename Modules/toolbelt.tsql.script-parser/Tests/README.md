# Tests für `toolbelt.tsql.script-parser`

## Prüfartefakte

- `Static/validate_contract.py` — statischer Code- und Artefakt-Validator.
- `Runtime/ScriptParser.Contract.sql` — Funktionsverträge (AST, Tokens, Properties, Errors, NULL-Handling).
- `Runtime/Lifecycle.Contract.sql` — Installationsmarker, Extended Properties und Assembly-Inventar.
- `Runtime/Central.Contract.sql` — Cross-Database-Aufruf im Central-Deployment-Modus.

## Status

| Umgebung | Scope | Ergebnis |
|---|---|---|
| Windows (.NET 4.8 MSBuild) | C# Assembly Build und Release-Skripte | `success` |
| Lokales SQL_Server_Lab | SQL Server 2019, 2022 und 2025 unter Windows; Deployment, Feature, Central und Uninstall | `success` |
| Statischer Validator | Artefakt- und Schnittstellenprüfung | `success` |

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-03`
- Nachweis: `statische Vertragsprüfung und Build-Validierung`
- Scope: .NET Framework 4.8 Assembly, ScriptDom-Integration, 4 CLR-TVFs, Deployment- und Lifecycle-Skripte
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
