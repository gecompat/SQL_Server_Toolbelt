# Integer-Base Tests

## Wartung 2026-10-09 – Plusziffer und positive Orakel

Der Decoder unterscheidet reguläre `+`-Alphabetziffern von einem zusätzlichen
positiven Vorzeichen. Dezimal-`+1` bleibt ungültig. Positive Encode-/Decode-,
Roundtrip- und SVF-/TVF-Vergleiche weisen unerwartetes NULL ausdrücklich ab;
die einzeilige TVF-Kardinalität bleibt Teil des Contracts. Der neue
Quellenstand ist SOURCE_ONLY, neue Runtimequalifikation NOT_EXECUTED.
Die folgenden datierten und generierten PASS-Nachweise werden beibehalten;
sie qualifizieren die geänderte Quelle nicht erneut auf Windows oder Linux.


Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Runtime: `partially validated`.

Signatur-, Alphabet-, Kanonizitäts-, Grenzwert-, Overflow-, Roundtrip-,
Deployment-, Kollisions-, zentrale und Lifecycle-Contracts sind vorhanden.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
erfolgreich. Geprüft wurden Version `1.1.0`, Inline-TVF-/SVF-Parität,
`OUTER APPLY`, der vollständige `bigint`-Bereich, Overflow, Upgrade,
Wiederholungsdeployment, Kollision, lokale und zentrale Nutzung sowie
Uninstall. Der vollständige Adapter ist seit 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe
bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
