# Tests – SQL CLR ZIP Provider Spike

| Prüfung | Zweck | Status |
|---|---|---|
| `Static/validate_spike.py` | Prüft .NET-Framework-Target, `System.IO.Compression`, In-memory-Probe, `SAFE` und ausgeschlossene Trust-/Permission-Pfade. | erfolgreich |
| GitHub Actions Build | Baut die minimale .NET-Framework-4.8-Assembly auf Windows. | erfolgreich ([Run 30586391868](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30586391868)) |
| Linux SQL Server 2022 dependency gate | Übernimmt das auf Windows gebaute Binary, startet eine disposable Linux-Containerinstanz und prüft die tatsächliche Auflösung der direkten CLR-Abhängigkeit. | **blockiert, reproduzierbar nachgewiesen** ([Run 30587389803](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30587389803), 2026-07-30 UTC) |
| Deployment-Probe Windows | Trust, `CREATE ASSEMBLY`, Procedure-Aufruf und Uninstall in einer disposable Testdatenbank. | nicht ausgeführt |

## Linux-2022-Befund

Die Testinstanz war ein Linux-Container aus
`mcr.microsoft.com/mssql/server:2022-latest`. Das Binary wurde unter Windows
mit .NET Framework 4.8 gebaut, per SHA2-512 vertraut und anschließend als
`SAFE`-Assembly geladen. Die Instanz hatte `clr enabled = 1`; `clr strict
security` blieb aktiviert.

`CREATE ASSEMBLY` scheiterte reproduzierbar mit SQL Server-Fehler 10301:
`System.IO.Compression, Version=4.2.0.0` ist in der Testdatenbank nicht
vorhanden und wird nicht automatisch aus dem Container geladen. Deshalb wurden
keine CLR-Procedure ausgeführt und kein positiver Runtime-Nachweis behauptet.

Der CI-Job gilt als erfolgreich, wenn genau diese Abhängigkeitsgrenze
nachgewiesen wird. Ein unerwarteter Erfolg oder ein anderer Fehler lässt den Job
fehlschlagen. Die Wegwerf-Instanz wird nach dem Job verworfen; nur dort wird
`clr enabled` für den Test gesetzt. Der reguläre Spike und sein Installer
ändern weiterhin keine Instanzoptionen.

Die Runtime-Probe muss für SQL Server 2019, 2022 und 2025 jeweils auf Windows
und Linux separat erfolgen. Ein späterer positiver Linux-Nachweis benötigt
einen separat geprüften, unterstützten und lifecycle-sicheren Weg für
`System.IO.Compression` und dessen Abhängigkeiten.
