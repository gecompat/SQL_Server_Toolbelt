# ⚠️ READ BEFORE USE

## License notice

**NOTICE: SQL Server Toolbelt is NOT Open Source. Use is governed by the custom Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Selling or charging third parties for access to this software or its contents is strictly prohibited.
2. **ATTRIBUTION REQUIRED:** You must preserve the copyright notice for **gecompat - Gerhard Pisch**.
3. **NO LIABILITY:** Use this software at your own risk. The author is **NOT liable** for damages, data loss, or business interruptions.

The complete legal terms are available in [LICENSE.md](./LICENSE.md). In case of a discrepancy, the English master version in `LICENSE.md` prevails.

---

## Lizenzhinweis

**HINWEIS: SQL Server Toolbelt ist keine Open-Source-Software. Die Nutzung richtet sich nach der projektspezifischen Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Der Verkauf der Software sowie das Entgelt für den Zugang zu dieser Software oder ihren Inhalten sind untersagt.
2. **ATTRIBUTION REQUIRED:** Der Copyright-Hinweis für **gecompat – Gerhard Pisch** muss erhalten bleiben.
3. **NO LIABILITY:** Die Nutzung erfolgt auf eigenes Risiko; der Autor haftet nicht für Schäden, Datenverlust oder Betriebsunterbrechungen.

Maßgeblich ist der vollständige englische Wortlaut in [LICENSE.md](./LICENSE.md). Die Übersetzungen dienen der Verständlichkeit.

---

# SQL Server Toolbelt

<!-- BEGIN GENERATED:MODULE_STATUS_BADGE -->
[![Status: 26 Module implementiert – 25 teilweise validiert](https://img.shields.io/badge/Status-26%20Module%20implementiert%20%7C%2025%20teilweise%20validiert-yellow)](./Modules/README.md)
<!-- END GENERATED:MODULE_STATUS_BADGE -->
[![Lizenz: Attribution & Non-Commercial Redistribution](https://img.shields.io/badge/Lizenz-Attribution%20%26%20Non--Commercial-red)](./LICENSE.md)
[![SQL Server: 2019, 2022, 2025](https://img.shields.io/badge/SQL%20Server-2019%20%7C%202022%20%7C%202025-blue)](./Documentation/Architecture/DEPLOYMENT_MODEL.md)

## Zweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen anbietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Scope

- Wiederverwendbare Stored Procedures, Table-valued Functions, Scalar-valued Functions, Views und bei technischer Notwendigkeit weitere Komponenten.
- T-SQL ist die bevorzugte Implementierungssprache.
- C#, SQL CLR, Python, Java oder R sind zulässig, wenn sie fachlich oder technisch besser geeignet sind und die Entscheidung dokumentiert wird.
- Lokale Installation in einer Zieldatenbank und zentrale Installation in einer dedizierten Toolbelt-Datenbank sind gleichwertige Designziele.
- Cross-database-Verwendung wird angestrebt, soweit SQL-Server-Verträge und Plattformgrenzen dies zulassen.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen gehören in [`gecompat/SQL_Server_Analyze`](https://github.com/gecompat/SQL_Server_Analyze).
- Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte werden nicht automatisch unterstützt.
- Das Repository enthält keine Produktionsdaten, Produktionsbackups oder realen Runtime-Ausgaben.

## Zielgruppe

SQL-Server-Entwickler und -Administratoren, die wiederverwendbare, dokumentierte und testbare Erweiterungsobjekte einsetzen möchten.

## Aktueller Status

**Der Repository-Grundaufbau ist abgeschlossen. 26 Module sind implementiert; Runtime-Evidenz wird pro Modul getrennt ausgewiesen.**

Die Execution-Grundlagen bestehen aus
[`toolbelt.core.error-envelope`](./Modules/toolbelt.core.error-envelope/README.md)
und
[`toolbelt.core.execution-context`](./Modules/toolbelt.core.execution-context/README.md).
Sie standardisieren explizit übergebene Fehlerdaten und verwalten eine
sessiongebundene Execution-/Correlation-ID ohne persistente Tabellen.

Der persistente
[`toolbelt.core.work-type`](./Modules/toolbelt.core.work-type/README.md)
registriert ausschließlich kontrollierte Stored-Procedure-Work-Types.
Raw SQL bleibt ausgeschlossen; Änderungen sind über `rowversion`,
explizite Update-/Reaktivierungsflags und Data-Loss-geschützten Uninstall
abgesichert.

Die freigegebenen E1a-/E1b-Slices
[`toolbelt.core.work-queue`](./Modules/toolbelt.core.work-queue/README.md)
stellen Enqueue, atomaren Lease-Claim, Heartbeat, explizite Recovery, Complete,
Fail und geschützte Statusoberflächen bereit. Die vollständige E1b-Matrix ist
auf SQL Server 2019, 2022 und 2025 unter Windows und Linux erfolgreich; das
Modul ist `validated`, aber `unreleased`. Retry, Dead Letter, Idempotenz und
Cancellation bleiben getrennte, nicht implementierte Slices.

[`toolbelt.core.second-session`](./Modules/toolbelt.core.second-session/README.md)
führt registrierte Work-Types synchron über einen administrativ vorbereiteten
Loopback-Linked-Server in einer getrennten SQL-Server-Session aus.

[`toolbelt.core.event-log`](./Modules/toolbelt.core.event-log/README.md)
persistiert strukturierte Events synchron in einer zweiten Session. Erfolgreiche
Writes überleben Caller-Rollback und uncommittable Caller-Transaktionen; Linked
Server und Login-Mappings bleiben administrativ außerhalb des Moduls.

Das portable Modul
[`toolbelt.file.content`](./Modules/toolbelt.file.content/README.md)
liest freigegebene Text- und Binärdateien über einen Root-Allowlist-Vertrag.
Die SQL-Server-2025-Linux-Matrix mit Compatibility Levels 150, 160 und
170 ist erfolgreich; Windows und nicht-ASCII-spezifische Providergrenzen
bleiben als getrennte Releasevalidierung sichtbar.

Das implementierte Modul [`toolbelt.core.result-table`](./Modules/toolbelt.core.result-table/README.md) stellt `toolbelt_core.USP_PrepareResultTable` als gemeinsame `@ResultTable`-/`@KeepData`-Infrastruktur bereit. Die Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; Windows und weitere Pflichtfälle bleiben offen.

Das unabhängige Modul
[`toolbelt.conversion.base64`](./Modules/toolbelt.conversion.base64/README.md)
stellt portable Base64-/Base64URL-Konvertierung bereit. Der vollständige
Moduladapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
erfolgreich; Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.core.generate-series`](./Modules/toolbelt.core.generate-series/README.md)
stellt portable, typstabile Ganzzahlreihen für `int` und `bigint` bereit. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Linux-Zielen erfolgreich; Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.metadata.identifier`](./Modules/toolbelt.metadata.identifier/README.md)
analysiert und begrenzt ein- bis vierteilige SQL-Namen. Der vollständige
Moduladapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
erfolgreich; Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.string.split-characters`](./Modules/toolbelt.string.split-characters/README.md)
teilt Unicode-Text an mehreren einzelnen literal interpretierten
Separatorzeichen. SQL Server 2025 Linux ist mit Compatibility Levels 150, 160
und 170 erfolgreich; die breitere Quote-/Escape-Ausbaustufe bleibt separat in
`TC-2026-032`.

Das implementierte Modul
[`toolbelt.validation.semantic-version`](./Modules/toolbelt.validation.semantic-version/README.md)
parst, vergleicht und sortiert strikte Semantic-Version-2.0.0-Werte. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Linux-Zielen erfolgreich; Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.conversion.integer-base`](./Modules/toolbelt.conversion.integer-base/README.md)
codiert und decodiert den vollständigen `bigint`-Bereich mit frei
definierbaren ASCII-Alphabeten. Der vollständige Moduladapter ist auf
physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich;
Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.datetime.calendar-difference`](./Modules/toolbelt.datetime.calendar-difference/README.md)
zerlegt `date`-Intervalle nach einer dokumentierten Anniversary-Regel. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Linux-Zielen einschließlich Lifecycle und zentraler Nutzung erfolgreich;
Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.string.directional-trim`](./Modules/toolbelt.string.directional-trim/README.md)
stellt typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und
`BOTH` bereit. Der vollständige Moduladapter ist auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; weitere Collations
und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.conversion.uri-component`](./Modules/toolbelt.conversion.uri-component/README.md)
codiert und decodiert RFC-3986-URI-Komponenten mit UTF-8 und strikter
Validierung. Der vollständige Moduladapter ist auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich;
LOB-/Performancegrenzen und Windows-Läufe bleiben offen.

Die implementierten W2a-Module
[`toolbelt.datetime.truncate`](./Modules/toolbelt.datetime.truncate/README.md),
[`toolbelt.datetime.bucket`](./Modules/toolbelt.datetime.bucket/README.md) und
[`toolbelt.binary.bit-operations`](./Modules/toolbelt.binary.bit-operations/README.md)
stellen typgetrennte Date/Time-Truncation, Origin-basiertes Bucketing und die
fünf Bitoperationen für `bigint` als kanonische relationale TVFs bereit.
Die vollständigen Moduladapter sind auf physischen SQL-Server-2019-, 2022-
und 2025-Linux-Zielen einschließlich Wiederholungsdeployment, Lifecycle,
Central und Uninstall erfolgreich; Windows-Läufe bleiben offen.

Das implementierte D1-Modul
[`toolbelt.datetime.date-spine`](./Modules/toolbelt.datetime.date-spine/README.md)
erzeugt Tages-, ISO-Wochen- und Monatsperioden für halboffene `date`-Bereiche.
Der vollständige Adapter ist auf physischen SQL-Server-2019-/2022-/2025-
Linux-Zielen erfolgreich; Windows blieb nach nicht erreichbarem SQL-
Anmeldungs-Preflight `not executed`.

Das implementierte W2b-A-Modul
[`toolbelt.json.path-exists`](./Modules/toolbelt.json.path-exists/README.md)
prüft SQL/JSON-Pfade fehlerfrei auf Existenz und stellt den Backport-Slice von
`TC-2026-009` bereit. SQL Server 2025 Linux ist mit Compatibility Levels 150,
160 und 170 einschließlich Lifecycle, Central und Uninstall erfolgreich;
Konstruktoren und JSON-Aggregate bleiben ausdrücklich zurückgestellt.

Die implementierten W2c-Module
[`toolbelt.core.console-message`](./Modules/toolbelt.core.console-message/README.md)
und
[`toolbelt.metadata.capability-catalog`](./Modules/toolbelt.metadata.capability-catalog/README.md)
stellen Unicode-sichere lange Message-Ausgabe sowie eine read-only Sicht auf
Database-level Toolbelt-Modulmarker bereit. Die vollständigen Moduladapter
sind auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
einschließlich Langtext-/Unicode-, Marker-/Drift-, Lifecycle-, Central- und
Uninstall-Contracts erfolgreich; Windows- und modulspezifische Releasefälle
bleiben offen.

Das implementierte ZIP-Memory-Modul
[`toolbelt.archive.zip-memory`](./Modules/toolbelt.archive.zip-memory/README.md)
extrahiert einzelne ZIP-Einträge aus `varbinary(max)` mit Methoden `0`
(Stored) und `8` (Deflate), Payload-CRC32 und harten Limits. Für
TC-2026-033 wurde der ZIP-Metadata-Pfad intern ergänzt; die
Windows-Runtime ist lokal (localhost,1433, SQL 2025, `sa`) für
`Runtime-`/`Smoke`-Contracts erfolgreich validiert. Die Linux-Matrix
bleibt teilweise validiert.

Das implementierte Windows-only Modul
[`toolbelt.filesystem.windows`](./Modules/toolbelt.filesystem.windows/README.md)
stellt kontrollierten `EXTERNAL_ACCESS`-SQL-CLR-Zugriff für begrenztes
Text-/Binary-I/O, Codepages, Transcoding sowie Directory-Operationen bereit.
`Caller` ist der Default, `ServiceAccount` explizit. Der Windows-SQL-Server-/
NTFS-Runtime-Nachweis ist teilweise ausgeführt: Der Lauf
`Ergänzender Windows-CLR-Preflight-Lauf` bestätigte kontrolliertes
ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`.
Windows-Authentication-,
NTFS-ACL- und weitere I/O-Tests bleiben `not executed`; Linux ist nicht
anwendbar.

## Modulprinzip

- Ein Modul ist Lifecycle-, Deployment- und Dokumentationseinheit.
- Module können einzelne zentrale Capabilities oder mehrere zusammengehörige Objekte enthalten.
- Abhängigkeiten sind versioniert, werden vor der ersten Mutation geprüft und nicht automatisch nachinstalliert.
- Wiederverwendete Fachlogik existiert genau einmal.
- Öffentliche Objekte liegen in fachlichen Schemas nach `toolbelt_<category>`.

Details: [Modul- und Abhängigkeitsmodell](./Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md)

## Unterstützte SQL-Server-Versionen

Die konkrete Grundmatrix umfasst SQL Server 2019, 2022 und 2025. Windows- und Linux-Support sowie lokale, zentrale und Cross-database-Verwendung werden je Modul getrennt ausgewiesen und validiert.

## T-SQL-first

T-SQL ist bevorzugt. Alternative Technologien benötigen eine dokumentierte Begründung zu Performance, Security, Deployment, Plattform und Wartung. Details: [T-SQL-Engineering](./Documentation/Standards/TSQL_ENGINEERING.md)

## Navigation

| Bereich | Pfad |
|---|---|
| Architektur | [Documentation/Architecture/](./Documentation/Architecture/) |
| Standards | [Documentation/Standards/](./Documentation/Standards/) |
| Module | [Modules/](./Modules/) |
| Templates | [Templates/](./Templates/) |
| Backlogs | [Backlog/](./Backlog/) |
| Tests | [Tests/](./Tests/) |
| Mitwirken | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| Sicherheit | [SECURITY.md](./SECURITY.md) |
| Changelog | [CHANGELOG.md](./CHANGELOG.md) |
| Lizenz | [LICENSE.md](./LICENSE.md) |
