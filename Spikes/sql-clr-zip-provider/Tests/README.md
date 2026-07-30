# Tests – SQL CLR ZIP Provider Spike

| Prüfung | Zweck | Status |
|---|---|---|
| `Static/validate_spike.py` | Prüft .NET-Framework-Target, `System.IO.Compression`, In-memory-Probe, `SAFE` und ausgeschlossene Trust-/Permission-Pfade. | ausführbar |
| GitHub Actions Build | Baut die minimale .NET-Framework-4.8-Assembly auf Windows. | noch nicht ausgeführt |
| Deployment-Probe | Trust, `CREATE ASSEMBLY`, Procedure-Aufruf und Uninstall in einer disposable Testdatenbank. | nicht ausgeführt |

Die Runtime-Probe muss für SQL Server 2019, 2022 und 2025 jeweils auf Windows
und Linux separat erfolgen. Sie wird nicht durch den GitHub-hosted Build ersetzt.
