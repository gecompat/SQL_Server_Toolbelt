# Semantic-Version Tests

Runtime: `partially validated`.

Parser-, Präzedenz-, Build-Metadata-, Overflow-, Sort-Key-, Deployment-,
Kollisions-, zentrale und Lifecycle-Contracts sind vorhanden.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
erfolgreich. Geprüft wurden Version `1.1.0`, Inline-TVF-/SVF-Parität,
`OUTER APPLY`, Präzedenz, Sort Key, Upgrade, Wiederholungsdeployment,
Kollision, lokale und zentrale Nutzung sowie Uninstall. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben `not executed`.
