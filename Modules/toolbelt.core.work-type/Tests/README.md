# Work-Type-Testevidenz

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Der Basisvertrag mit Registrierung, Update und `rowversion`, Disable/Reaktivierung, Resolve, ResultTable, vier parallelen Sessions, Redeploy, Central, Lifecycle und Data-Loss-Uninstall-Schutz ist auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich.

Basis-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193

Version `1.1.0` ergänzt capabilitybezogene Tests für `USP_RemoveWorkType`: aktive Einträge, explizite Datenverlustfreigabe, stale `rowversion`, Caller-Savepoint und Rollback, uncommittable Caller, endgültige Entfernung sowie ResultTable-Ausgabe. Die capabilitybezogene Runtime-Matrix ist erfolgreich. Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger W4-Moduladapter
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
