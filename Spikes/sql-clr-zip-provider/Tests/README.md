# Tests – SQL CLR ZIP Provider Spike

| Prüfung | Zweck | Status |
|---|---|---|
| `Static/validate_spike.py` | Prüft .NET-Framework-Target, `System.IO.Compression`, In-memory-Probe, `SAFE` und ausgeschlossene Trust-/Permission-Pfade. | ausführbar |
| GitHub Actions Build | Baut die minimale .NET-Framework-4.8-Assembly auf Windows. | erfolgreich ([Run 30586391868](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30586391868)) |
| Linux SQL Server 2022 runtime | Übernimmt das auf Windows gebaute Binary, startet eine disposable Linux-Containerinstanz, aktiviert `clr enabled` nur dort und prüft Trust, `SAFE`-Deployment, `ZipArchive`-Aufruf sowie Uninstall. | konfiguriert, noch nicht ausgeführt |
| Deployment-Probe Windows | Trust, `CREATE ASSEMBLY`, Procedure-Aufruf und Uninstall in einer disposable Testdatenbank. | nicht ausgeführt |

Die Linux-Probe verwendet `mcr.microsoft.com/mssql/server:2022-latest` und
eine ausschließlich zur Laufzeit erzeugte Testdatenbank. Sie setzt für diese
wegwerfbare Instanz `clr enabled`; `clr strict security` muss unverändert
aktiv sein. Der reguläre Spike und sein Installer ändern weiterhin keine
Instanzoptionen. Der Container wird am Job-Ende verworfen; der Trust-Eintrag
wird innerhalb des Containers nicht entfernt.

Die Runtime-Probe muss für SQL Server 2019, 2022 und 2025 jeweils auf Windows
und Linux separat erfolgen. Ein erfolgreicher Linux-2022-Containernachweis
belegt nur diese konkrete Plattform- und Versionskombination und ersetzt keine
weiteren Matrix-Gates.
