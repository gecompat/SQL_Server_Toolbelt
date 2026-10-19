# Semantic-Version Tests

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

## Testwartung 2026-10-09: bestehende Orakel schließen

Die bestehenden Parser-, Präzedenz-, Build-Metadata-, Größen-, ASCII- und
Sort-Key-Fälle erhalten NULL-geschlossene positive Erwartungen und direkte
TVF-Zeilenzählung je Fall. Fehlende oder mehrfache Ergebniszeilen sowie
NULL-offene Validitäts-/Fehlercodefelder können die vorhandenen Orakel nicht
mehr scheinbar erfüllen. Eingaben, Sollwerte und negative Vergleichsfälle
bleiben erhalten; keine neue Suite oder Produktsemantik.
Stand 2026-10-09: verschärfte Contract-Tests **NOT_EXECUTED**, Quellenstand SOURCE_ONLY.
Nachqualifikation 2026-10-19: Die verschärften Tests und der vollständige Adapter bestanden auf SQL Server 2019/2022/2025 unter Windows und Linux. Historische Matrixnachweise bleiben auf ihren damaligen Testquellen gültig;
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
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger Adapter einschließlich der am 2026-10-09 verschärften NULL- und Kardinalitätsorakel, Upgrade, Central, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
