# PROJECT_CONTEXT.md – Projektzusammenhang

## Projektstatus

`toolbelt.file.content` ist als portabler Read-only-Dateiprovider implementiert und auf SQL Server 2025 Linux teilweise validiert. `toolbelt.filesystem.windows` ist implementiert, benötigt aber weiterhin den manuellen Windows-SQL-Server-/NTFS-Runtime-Nachweis. `toolbelt.archive.zip-memory` ist als SAFE-SQL-CLR-Provider unter SQL Server 2019/2022/2025 Linux teilweise validiert.

28 Module sind implementiert. 20 sind `validated`, 8 sind `partially
validated`; 0 sind `not executed`. Die verbindlichen Einzelstatus werden aus den jeweiligen
`module.yaml`-Manifesten abgeleitet.

`toolbelt.datetime.date-spine` implementiert D1 mit drei öffentlichen Inline
TVFs für Tag, ISO-Woche und Monat. Der halboffene Bereich liefert alle
geschnittenen Perioden mit nullbasiertem Ordinal. Die vollständigen lokalen,
zentralen, Lifecycle-, Dependency-, Kollisions-, Grenz-, `DATEFIRST`- und
Skalierungsadapter sind auf physischen SQL-Server-2019-/2022-/2025-Zielen
unter Windows base und Linux latest erfolgreich. Das Modul ist `validated`
und `unreleased`.

`toolbelt.core.work-queue` Version `1.1.0` implementiert die ausdrücklich
freigegebenen E1a-/E1b-Slices mit Enqueue, atomarem Lease-Claim, Heartbeat,
expliziter Recovery, tokengebundenem Complete/Fail und geschützten
Statusoberflächen. E1a ist auf physischen SQL-Server-2019-/2022-/2025-Linux-
Zielen erfolgreich. Die vollständige E1b-Pflichtmatrix ist auf SQL Server
2019/2022/2025 unter Windows base und Linux latest erfolgreich; das Modul ist
`validated` und `unreleased`. Recovery begründet keine Exactly-once- oder generische Idempotenzzusage;
Retry/Dead Letter/Idempotenz bleibt E1c.

Die W2c-Module `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` sind auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
Langtext-/Unicode-, Marker-/Drift-, Wiederholungs-, Lifecycle-, Central- und
Uninstall-Contracts erfolgreich. Der Capability Catalog ist einschließlich
eingeschränkter Metadatensichtbarkeit `validated`; Console Message bleibt
wegen zusätzlicher Client-/Treiber- und Buffering-Grenzen `partially validated`.

`toolbelt.core.console-message` stellt zusätzlich den ADP-008-Piloten für den
Project-Adapter-Vertrag 0.1 von `SQL_Server_Lab` bereit. Der Adapter wird
deterministisch aus den kanonischen Modulquellen erzeugt und war mit SQL Server
2025 Linux getrennt unter Docker und Podman für Install, versionsgleiches
Update, Modul-/Help-Validierung und markergebundenen Cleanup erfolgreich. Der
Toolbelt-Runner verwaltet keine Lab-Infrastruktur. Die Windows-/Linux-Matrix
2019/2022/2025 ist erfolgreich; der Modulstatus bleibt wegen zusätzlicher
Client-/Treiber- und Buffering-Grenzen `partially validated`.

Der Repository-Grundaufbau ist initialisiert und konsolidiert. Das Kernmodul
`toolbelt.core.result-table` ist implementiert und teilweise validiert: Die
Windows-/Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; eine
vergleichbare plattformübergreifende Performance-Baseline bleibt offen.
Das unabhängige Modul `toolbelt.conversion.base64` ist implementiert; sein
vollständiger Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich. Das Modul bleibt
wegen der noch offenen breiteren Large-LOB-Performance-Evidenz `partially validated`.

Das unabhängige Modul `toolbelt.core.generate-series` ist mit portablen
Inline TVFs für `int` und `bigint` implementiert. Sein vollständiger Adapter
ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base
und Linux latest erfolgreich. Das Modul bleibt wegen der noch offenen
Very-large-series-Performance-Evidenz `partially validated`.

Das Modul `toolbelt.metadata.identifier` implementiert einen zustandsbasierten
Parser und einen Quote-Wrapper für ein- bis vierteilige SQL-Namen. Code,
Lifecycle-, Dokumentations- und Testartefakte sind vorhanden. Der
vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

Das Modul `toolbelt.string.split-characters` implementiert einen literal
interpretierten Multi-Separator-Vertrag mit stabilen Ordinals, definierter
Leer-Token-Semantik und `nvarchar(max)`-Verarbeitung. Code, Lifecycle-,
Dokumentations- und Testartefakte sind vorhanden. Der vollständige Adapter
ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base
und Linux latest erfolgreich; das Modul ist `validated`. Die breitere Quote-/Escape-Version
bleibt getrennt als `TC-2026-032`.

`toolbelt.validation.semantic-version` ist mit strengem SemVer-2.0.0-Parser,
Comparator und binärem Sort Key implementiert. Der vollständige Adapter ist
auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und
Linux latest erfolgreich; das Modul ist `validated`.

`toolbelt.conversion.integer-base` codiert und decodiert den vollständigen
`bigint`-Bereich mit frei definierbaren binär eindeutigen ASCII-Alphabeten.
Der vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

`toolbelt.datetime.calendar-difference` zerlegt `date`-Intervalle nach einer
dokumentierten Anniversary-Regel. `toolbelt.string.directional-trim` stellt
typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und `BOTH`
bereit. `toolbelt.conversion.uri-component` codiert und decodiert
RFC-3986-URI-Komponenten mit expliziter UTF-8-Sequenzvalidierung. Die drei
Module sind mit ihren vollständigen Adaptern auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
Wiederholungsdeployment, zentraler Nutzung, Kollisionsschutz und Uninstall
erfolgreich. Die zusätzlichen Collation- sowie ASCII-/Unicode-/Large-Input-
Pflichtfälle sind ebenfalls erfolgreich; die Module sind `validated`.

W2a ist mit drei weiteren portablen Inline-TVF-Modulen implementiert:
`toolbelt.datetime.truncate` bietet typgetrennte Truncation für `date`,
`datetime2(7)` und `datetimeoffset(7)`, `toolbelt.datetime.bucket` ergänzt
Origin-basierte Buckets derselben Typfamilie und
`toolbelt.binary.bit-operations` portiert die fünf SQL-Server-2022-
Bitoperationen für `bigint`. Die vollständigen Adapter sind auf physischen
SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest
einschließlich Wiederholungsdeployment, Lifecycle, zentraler Nutzung,
Kollisionsschutz, nativer Parität und Uninstall erfolgreich. Der Bucket-
Optimizer-Workload umfasst zusätzlich 100.000 synthetische Zeilen; die drei
Module sind `validated`.

W2b-A ist als `toolbelt.json.path-exists` implementiert. Die
Multi-statement TVF prüft Root-, Property-, Array-Index- und
Array-Wildcard-Pfade, propagiert SQL `NULL` und liefert für ungültiges JSON
oder ungültige Pfade fehlerfrei `0`. Konstruktoren aus `TC-2026-009` und
JSON-Aggregate aus `TC-2026-013` bleiben zurückgestellt. Der vollständige
Adapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter
Windows base und Linux latest einschließlich nativer Parität,
Wiederholungsdeployment, Kollisionsschutz, Lifecycle, Central und Uninstall
erfolgreich; das Modul ist `validated`.

W2c ist als `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` implementiert. Die Console-USP
verwendet Unicode-sichere `PRINT`- beziehungsweise
`RAISERROR ... WITH NOWAIT`-Chunks. Die Capability-View liest ausschließlich
Database-level Extended Properties und weist Marker als `valid`,
`incomplete` oder `invalid` aus. Die vollständige Windows-/Linux-Matrix
2019/2022/2025 ist einschließlich Langtext-/Unicode-, Marker-/Drift-,
Wiederholungs-, Lifecycle-, Central- und Uninstall-Contracts erfolgreich.
Die eingeschränkte Metadatensichtbarkeit wurde ohne Rechteausweitung geprüft;
der Capability Catalog ist `validated`. Console Message bleibt wegen der
zusätzlichen Client-/Treibergrenzen `partially validated`.

`toolbelt.archive.zip-memory` ist als V1A-In-memory-Slice implementiert und
stellt `toolbelt_archive.USP_ExtractZipEntryFromBinary` bereit. Version
`1.0.0` extrahiert einen einzelnen Entry aus einem ZIP-Container im Speicher,
erzwingt Default-Limits fuer Entry-Groesse und Kompressionsverhaeltnis,
behandelt Duplicate-Namen als expliziten Fehler und liefert bei
`@FailIfEncrypted = 0` einen verschluesselten Status ohne Payload. Version
`1.2.0` ergänzt das Metadaten-Listing. Extraktion und Listing sind im
[GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453)
auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich; die automatisierte
Windows-/Linux-Matrix 2019/2022/2025 war am 2026-09-01 ebenfalls erfolgreich.
Reale Archive, echte Extremgrößen, historische Upgrades und Interoperabilität
bleiben offen.

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

Arbeitspakete und Kandidaten verwenden einen Workflow-Status wie `proposed`,
`researched`, `active`, `blocked`, `completed`, `rejected` oder `curiosity`.

Module trennen dagegen verbindlich:

- `implementation_status`: Stand der Implementierung;
- `validation_status`: tatsächlich belegter Testscope;
- `release_status`: Veröffentlichungsstand.

Die zulässigen Modulwerte und ihre Bedeutung stehen im
[Modul- und Abhängigkeitsmodell](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md).
Plan, Dokumentation, Manifest und vorhandener Testcode sind kein
Runtime-Nachweis.
