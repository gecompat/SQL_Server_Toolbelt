# Tests – SQL CLR ZIP Provider Spike

| Prüfung | Zweck | Status |
|---|---|---|
| `Static/validate_spike.py` | Prüft .NET-Framework-Target, ausschließliche Framework-Abhängigkeiten, Deflate-/CRC32-Probe, binäres Deployment, `SAFE` und ausgeschlossene Trust-/Permission-Pfade. | automatisiert |
| GitHub Actions Build | Baut die minimale .NET-Framework-4.8-Assembly auf Windows und erzeugt das SHA2-512-Trust-Manifest. | automatisiert |
| Linux SQL Server 2022 Runtime | Übernimmt das Windows-Binary, richtet eine disposable Linux-Containerinstanz ein und prüft Trust, `CREATE ASSEMBLY`, tatsächlichen CLR-Aufruf, Deflate-Payload, CRC32 und Uninstall. | automatisierter positiver Gate |
| Deployment-Probe Windows | Trust, `CREATE ASSEMBLY`, Procedure-Aufruf und Uninstall auf einer Windows-SQL-Server-Instanz. | nicht ausgeführt |
| Physische SQL-Versionen | Entsprechender Runtime-Lauf auf SQL Server 2019 und 2025. | nicht ausgeführt |

## Erwarteter Linux-Nachweis

Die Assembly darf keine direkte Referenz auf `System.IO.Compression.dll`
enthalten. `DeflateStream` muss zur Laufzeit aus `System, Version=4.0.0.0`
geladen werden. Die Probe muss exakt den UTF-8-Payload
`SQL Server Toolbelt CLR ZIP probe`, eine Länge von `33` Bytes und die CRC32
`BD97DF6A` liefern.

Der CI-Job gilt nur dann als erfolgreich, wenn Deployment, tatsächliche
Dekomprimierung, CRC32-Prüfung und Uninstall erfolgreich sind. Ein erwarteter
Deployment-Fehlschlag ist kein positiver Test mehr.

## Aussagegrenze

Der Runtime-Gate prüft den für ZIP Method 8 benötigten Deflate-/CRC32-Kern,
nicht den Parser beliebiger ZIP-Container. ZIP-Header, Central Directory,
Duplicate Names, Encryption Flags, ZIP64 und Ressourcenlimits bleiben Aufgabe
des späteren produktiven Implementierungs-Slices.
