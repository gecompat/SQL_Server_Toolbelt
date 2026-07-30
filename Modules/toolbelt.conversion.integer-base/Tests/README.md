# Integer-Base Tests

Runtime: `partially validated`.

Signatur-, Alphabet-, Kanonizitäts-, Grenzwert-, Overflow-, Roundtrip-,
Deployment-, Kollisions-, zentrale und Lifecycle-Contracts sind vorhanden.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
erfolgreich. Geprüft wurden Version `1.1.0`, Inline-TVF-/SVF-Parität,
`OUTER APPLY`, der vollständige `bigint`-Bereich, Overflow, Upgrade,
Wiederholungsdeployment, Kollision, lokale und zentrale Nutzung sowie
Uninstall. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben `not
executed`.
