# Semantic-Version Tests

## Testwartung 2026-10-09: bestehende Orakel schließen

Die bestehenden Parser-, Präzedenz-, Build-Metadata-, Größen-, ASCII- und
Sort-Key-Fälle erhalten NULL-geschlossene positive Erwartungen und direkte
TVF-Zeilenzählung je Fall. Fehlende oder mehrfache Ergebniszeilen sowie
NULL-offene Validitäts-/Fehlercodefelder können die vorhandenen Orakel nicht
mehr scheinbar erfüllen. Eingaben, Sollwerte und negative Vergleichsfälle
bleiben erhalten; keine neue Suite oder Produktsemantik.
Neue verschärfte Contract-Tests: **NOT_EXECUTED**, Quellenstand SOURCE_ONLY.
Historische Matrixnachweise bleiben auf ihren damaligen Testquellen gültig;
Version `1.1.0`, Manifeststatus, Produktcode, API und Workflow unverändert.

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Runtime: `validated`.

Parser-, Präzedenz-, Build-Metadata-, Overflow-, Sort-Key-, Deployment-,
Kollisions-, zentrale und Lifecycle-Contracts sind vorhanden.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
erfolgreich. Geprüft wurden Version `1.1.0`, Inline-TVF-/SVF-Parität,
`OUTER APPLY`, Präzedenz, Sort Key, Upgrade, Wiederholungsdeployment,
Kollision, lokale und zentrale Nutzung sowie Uninstall. Der vollständige
Adapter ist seit 2026-08-29 auf physischen SQL-Server-2019-, 2022- und
2025-Linux-Zielen erfolgreich; Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
