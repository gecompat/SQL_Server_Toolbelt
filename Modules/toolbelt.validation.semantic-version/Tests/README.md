# Semantic-Version Tests

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Runtime: `partially validated`.

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
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/semantic-version-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
