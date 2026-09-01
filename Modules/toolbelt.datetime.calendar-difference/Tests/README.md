# Test Evidence

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Die Contract- und Lifecycle-Tests verwenden ausschließlich synthetische `date`-Werte.

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-07-30 | [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) | SQL Server 2025 Linux; Compatibility 150/160/170; Anniversary, Grenzwerte, NULL, APPLY, Wiederholungsdeployment, zentrale Nutzung und Uninstall | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |

Der Modulstatus ist `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
