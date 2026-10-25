# Work-Type-Testevidenz

Für die zusätzliche Callerrechteprüfung führt der
[Release-Testweg](../../../Tests/Release/README.md#work-type-mit-getrennten-handler--und-policyrechten-prüfen)
über eingefrorene T-SQL-Exports und ein privates Runset zu eigenen markierten
Testdatenbanken. Erwartet werden sechs positive Profile und 57 strikte
Abweisungen je Datenbank sowie ein separater Bereinigungsaudit. Der
[Bericht vom 2026-10-25](../../../Releases/1.0.0/WORK-TYPE-RIGHTS-QUALIFICATION.md)
belegt zwölf Ziel-/CL-Fälle lokal und direkt zentral, verworfene Orakelkontrollen
und den bereinigten ersten Fixturefehler. Keine vollständige neue
Policy-/Modulabnahme oder CrossDB-Identitätszusage.

## Historische Funktionsnachweise

Die folgenden datierten Nachweise behalten ihren damaligen Versions- und
Quellbezug. Insbesondere ist die Basisplattformmatrix kein Vollnachweis aller
später ergänzten Policyfunktionen.

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Der Basisvertrag mit Registrierung, Update und `rowversion`, Disable/Reaktivierung, Resolve, ResultTable, vier parallelen Sessions, Redeploy, Central, Lifecycle und Data-Loss-Uninstall-Schutz ist auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich.

Basis-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193

Version `1.1.0` ergänzt capabilitybezogene Tests für `USP_RemoveWorkType`: aktive Einträge, explizite Datenverlustfreigabe, stale `rowversion`, Caller-Savepoint und Rollback, uncommittable Caller, endgültige Entfernung sowie ResultTable-Ausgabe. Die capabilitybezogene Runtime-Matrix ist erfolgreich. Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Konkurrenz-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
