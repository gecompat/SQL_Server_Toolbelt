# T-SQL Script Parser

`toolbelt.tsql.script-parser` stellt deterministische, rein lesende SQL-CLR Table-Valued Functions (TVFs) auf Basis von Microsoft ScriptDom (.NET Framework 4.8) bereit, um beliebigen T-SQL-Code syntaktisch in AST-Knoten, Knoteneigenschaften, einen verlustfreien Tokenstrom und strukturierte Fehlerlisten zu zerlegen.

## Funktionen

- `toolbelt_tsql.TVF_ParseScriptNodes`: Hierarchischer AST-Knotenbaum in Pre-Order-Reihenfolge.
- `toolbelt_tsql.TVF_ParseScriptNodeProperties`: Skalare Knoteneigenschaften (z. B. Bezeichnernamen, Literalwerte, Enums).
- `toolbelt_tsql.TVF_TokenizeScript`: Lückenloser Tokenstrom inklusive Offsets, Zeilen und Spalten.
- `toolbelt_tsql.TVF_ParseScriptErrors`: Strukturierte Syntaxfehlerausgabe als Datenzeilen.

## Plattform- und Providerbesonderheiten

- **Plattform:** Windows (SQL Server 2019, 2022, 2025). SQL Server auf Linux unterstützt keine `UNSAFE`-Assemblies und ist nicht anwendbar.
- **Assembly:** `Toolbelt_Tsql_ScriptParser` / `Toolbelt.Tsql.ScriptParser.dll`.
- **Trust:** Die Freigabe erfolgt über den exakten SHA2-512-Hash via `sys.sp_add_trusted_assembly` unter Beibehaltung von `clr strict security = 1`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-03`
- Nachweis: `statische Vertragsprüfung und Build-Validierung`
- Scope: .NET Framework 4.8 Assembly, ScriptDom-Integration, 4 CLR-TVFs, Deployment- und Lifecycle-Skripte
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
