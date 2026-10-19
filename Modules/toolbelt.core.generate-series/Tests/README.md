# Generate-Series-Testevidenz

Lastqualifikation 2026-10-19: Der vollständige Moduladapter einschließlich Pflicht-Lastfall (zehn Millionen Werte mit Anzahl, Eindeutigkeit und Grenzen 1..10000000) bestand auf SQL Server 2025 Linux/latest CL170. Zusammen mit der unveränderten Windows-/Linux-Fachmatrix gilt `validated`; Release bleibt `unreleased`. Optionale Laufzeitmessungen: `not executed`. [Aktuelle Abnahme](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

Abnahmeänderung 2026-10-19: Große Lastfälle mit Ergebnisprüfung sind Pflicht; Laufzeitmessungen sind optional und kein Validierungs- oder Release-Gate. Maßgeblich ist [DEC-2026-036](../../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen). Ältere datierte Aussagen zur verpflichtenden Performance-Abnahme beschreiben den damaligen Vertrag.

Historischer Zwischenstand vor der Abnahmeänderung am 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Die abgegrenzte Performance-Abnahme bleibt offen; Runtime: `partially validated`, Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; breitere Very-large-series-Performance-Evidenz bleibt offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Evidenzhistorie

Die Einschränkungen der datierten Einträge beschreiben den jeweiligen
damaligen Stand. Die physischen Windows-/Linux-Plattformlücken für SQL Server
2019, 2022 und 2025 wurden durch den im Modulmanifest dokumentierten Nachweis
vom 2026-09-01 geschlossen. Die breitere
Very-large-series-Performance-Evidenz bleibt offen.

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |
| 2026-07-30 | [Generate-Series Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/generate-series-runtime.yml) | Workflow, statische und Runtime-Contract-Artefakte angelegt | `not executed` | Ein vorhandener Workflow ist kein Runtime-Nachweis |
| 2026-07-30 | [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) | SQL Server 2025 Linux; Compatibility Levels 150/160/170; Semantik, native Parität, Fehler, Grenzen, eine Million Werte, Row Goal, Join, `CROSS APPLY`, lokale, zentrale und Lifecycle-Contracts | `success` | Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben offen |

Die erfolgreiche physische Windows-/Linux-Matrix belässt den Modulstatus auf
`partially validated`. Für `validated` fehlt weiterhin die breitere
Very-large-series-Performance-Evidenz einschließlich eines belastbaren
Regressionsvergleichs.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux/latest CL170; vollständiger aktueller Moduladapter einschließlich Pflicht-Lastfall: zehn Millionen Werte mit Anzahl, Eindeutigkeit und Grenzen 1..10000000; lokales/zentral Deploy, Lifecycle, Uninstall und frischer eigener Cleanupaudit erfolgreich; ergänzt die unveränderte Sechs-Ziel-Fachmatrix. Laufzeitmessung optional und nicht ausgeführt gemäß DEC-2026-036
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
