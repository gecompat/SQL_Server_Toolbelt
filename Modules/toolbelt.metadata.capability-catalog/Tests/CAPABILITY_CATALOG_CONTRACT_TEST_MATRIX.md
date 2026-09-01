# Contract-Testmatrix: Module Capability Catalog

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Pflichtfall | Status |
|---|---|---|
| API | View-Typ und vier Spalten | `success` – Run 30573135975 |
| gültig | kanonische Modulmarker | `success` – Run 30573135975 |
| unvollständig | fehlender Version- oder Mode-Marker sichtbar | `success` – Run 30573135975 |
| ungültig | Version, Modus, Datentyp und Schreibweise | `success` – Run 30573135975 |
| Scope | Object-level Extended Property wird ignoriert | `success` – Run 30573135975 |
| Collation | CS-, CI- und BIN2-Datenbankpfade | `success` – Run 30573135975 |
| Read-only | keine Registry und keine Mutation durch die View | `success` – Run 30573135975 |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | `success` – Run 30573135975 |
| Matrix | SQL Server 2025 Linux, Compatibility 150/160/170 | `success` – [Run 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975) |
| Release | physische SQL Server 2019/2022 und Windows | `not executed` |

Physische SQL-Server-2019-/2022- und Windows-Läufe sowie eingeschränkte
Metadata-Visibility bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
