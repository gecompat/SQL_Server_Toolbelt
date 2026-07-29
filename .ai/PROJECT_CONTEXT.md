# PROJECT_CONTEXT.md – Projektzusammenhang

## Projektstatus

Der Repository-Grundaufbau ist initialisiert und konsolidiert. Das erste Kernmodul `toolbelt.core.result-table` ist implementiert und teilweise validiert: Die GitHub-hosted Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; Windows und noch nicht automatisierte Pflichtfälle bleiben `not executed`.

## Projektzweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen anbietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Nutzen

- wiederverwendbare, getestete und dokumentierte SQL-Server-Objekte;
- Reduzierung wiederkehrender Implementierungslogik;
- stabile öffentliche Verträge und versionsbezogene Compatibility-Informationen;
- lokale oder zentrale Installation, soweit die Capability dies erlaubt.

## Scope

- SQL Server 2019, 2022 und 2025; spätere Versionen werden nach Erscheinen ausdrücklich bewertet;
- Windows und Linux, jeweils pro Modul und Provider ausgewiesen;
- T-SQL bevorzugt;
- SQL CLR, C#, Python, Java oder R nur mit technischer Begründung;
- lokale und zentrale Deployment-Modi;
- Cross-database-Verwendung als Designziel, nicht als pauschale Garantie.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen; diese gehören in `gecompat/SQL_Server_Analyze`;
- automatische Unterstützung von Azure SQL Database oder Azure SQL Managed Instance;
- Demo-Anwendungen, Produktionsdaten, Produktionsbackups oder reale Runtime-Ausgaben;
- ungeprüfte Drittanbieterabhängigkeiten.

## Repository-Grenzen

- Dieses Repository ändert kein anderes Repository ohne ausdrücklichen Auftrag.
- Analyseideen dürfen in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` erfasst werden.
- Vor einem Analyze-Kandidaten wird das Ziel-Repository nach Möglichkeit lesend auf vorhandene oder gleichwertige Funktionalität geprüft.

## Plattformmatrix

| Plattform | Grundstatus |
|---|---|
| SQL Server 2019 Windows | Zielplattform |
| SQL Server 2022 Windows | Zielplattform |
| SQL Server 2025 Windows | Zielplattform |
| SQL Server 2019 Linux | Zielplattform, modulabhängig |
| SQL Server 2022 Linux | Zielplattform, modulabhängig |
| SQL Server 2025 Linux | Zielplattform, modulabhängig |
| Azure SQL Database | kein automatischer Support |
| Azure SQL Managed Instance | kein automatischer Support |
| SQL Server vor 2019 | nicht unterstützt |

## Statusbegriffe

- `proposed`: Idee ohne Implementierung.
- `researched`: recherchiert, aber nicht zur Umsetzung freigegeben.
- `planned`: freigegebenes oder vorbereitetes Arbeitspaket.
- `implemented`: Code und statische Verträge vorhanden; Runtime-Nachweis kann fehlen.
- `partially validated`: ein ausdrücklich abgegrenzter Pflichtscope wurde tatsächlich erfolgreich ausgeführt; weitere Pflichtkombinationen bleiben offen.
- `validated`: relevante Prüfungen tatsächlich erfolgreich ausgeführt.
- `experimental`: funktionsfähig, aber nicht vollständig validiert.
- `deprecated`: veraltet und zur Ablösung vorgesehen.
- `unsupported`: bewusst nicht unterstützt.
- `not executed`: vorgesehene Prüfung nicht ausgeführt.
- `not applicable`: im konkreten Scope nicht anwendbar.
- `curiosity`: theoretische oder unterhaltsame Idee ohne Implementierungszusage.

Plan, Dokumentation, Manifest und Testcode sind kein Runtime-Nachweis.
