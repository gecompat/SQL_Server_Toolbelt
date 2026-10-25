# Tests für `toolbelt.metadata.identifier`

Aktuelle [Utility-Callerrechte](../../../Releases/1.0.0/UTILITY-CALLER-QUALIFICATION.md): einzelne SELECT-/EXECUTE-Grants für16 öffentliche Funktionen lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen; andere APIs, direkte Dependencies und Helper bleiben unzugänglich. Frühere Voll-, Last-, Client- und Lifecycle-Nachweise behalten ihren Scope; keine Statusaufwertung.

Für Scalarwrapper ist das nativ geprüfte direkte Einzelrecht EXECUTE. Die ältere generische SELECT-/REFERENCES-Formulierung im Manifest beziehungsweise Scalarheader ist veraltet und bleibt bis zum getrennten gebundenen Metadaten-/Paketrefresh ausdrücklich als Erratum geführt.

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

`Identifier.Contract.sql` prüft den öffentlichen Parser- und Quote-Vertrag.
`Lifecycle.Contract.sql` prüft Marker, Objekttypen und interne Dependency.
`Central.Contract.sql` prüft dreiteilige Aufrufe aus einer getrennten
synthetischen Konsumentendatenbank.

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Der vollständige Adapter ist seit 2026-08-29 zusätzlich auf
physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich.
Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
