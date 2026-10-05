# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

Der [zentrale Beispielkatalog](../Documentation/Reference/API_CATALOG.md)
ergänzt die Modulübersicht um Aufrufe, Parameter und Voraussetzungen aller
öffentlichen Schnittstellen. Die [HTML-Ansicht](../Documentation/Reference/API_CATALOG.html)
ist lokal durchsuchbar; die Ausgabe wird in der Dokumentations-CI auf Synchronität geprüft.

## Aktueller Status

**40 Module sind implementiert. 19 sind `validated`, 21 sind `partially validated`; 0 sind `not executed`. Der Einzelstatus wird aus den Manifesten
abgeleitet.**

## Implementierte Module

<!-- BEGIN GENERATED:MODULE_STATUS_TABLE -->
| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |
|---|---|---:|---|---|---|---|---|
| `toolbelt.archive.zip-files` | Windows ZIP File Facades | `1.0.0` | `toolbelt_archive` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.archive.zip-memory` | ZIP Memory Inspection | `1.4.0` | `toolbelt_archive` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.binary.bit-operations` | Bigint Bit Operations Compatibility | `1.0.0` | `toolbelt_binary` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.base64` | Base64 and Base64URL Conversion | `1.1.0` | `toolbelt_conversion` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.integer-base` | Integer Base Conversion | `1.1.0` | `toolbelt_conversion` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.uri-component` | URI Component Percent-Encoding | `1.0.0` | `toolbelt_conversion` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.console-message` | Console Message | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.error-envelope` | Error Envelope | `1.0.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.event-log` | Rollback-independent Event Log | `1.0.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.execution-cancel` | Cooperative Execution Cancellation | `1.0.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.execution-context` | Execution Context | `1.0.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.generate-series` | Portable Integer Series | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.result-table` | Result Table Infrastructure | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.second-session` | Second Session | `1.1.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.work-queue` | Transactional Work Queue | `2.1.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.work-type` | Work Type Catalog | `1.1.0` | `toolbelt_core` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.worker-control` | Managed Worker Control | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.bucket` | Date/Time Bucket Compatibility | `1.0.0` | `toolbelt_datetime` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.calendar-difference` | Calendar Difference | `1.0.0` | `toolbelt_datetime` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.date-spine` | Relational Date Spine | `1.0.0` | `toolbelt_datetime` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.truncate` | Date/Time Truncation Compatibility | `1.0.0` | `toolbelt_datetime` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.file.content` | File Content | `1.0.0` | `toolbelt_file` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.file.csv-memory` | CSV Memory Parser and Writer | `1.0.0` | `toolbelt_file` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.file.xlsx-memory` | XLSX Binary Memory Reader | `1.2.0` | `toolbelt_file` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.filesystem.windows` | Windows Filesystem | `1.0.0` | `toolbelt_filesystem` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.json.constructors` | JSON Constructors | `1.2.0` | `toolbelt_json` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.json.path-exists` | JSON Path Exists | `1.0.0` | `toolbelt_json` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.capability-catalog` | Module Capability Catalog | `1.0.0` | `toolbelt_metadata` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.identifier` | Identifier and Multipart Name Toolkit | `1.0.0` | `toolbelt_metadata` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.table-clone` | Table Clone Planner, Executor and Data Copy | `4.1.0` | `toolbelt_metadata` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.pseudonymization.deterministic` | Deterministic Synthetic Mapping | `1.2.0` | `toolbelt_pseudonymization` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.directional-trim` | Directional TRIM Compatibility | `1.0.0` | `toolbelt_string` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.edit-distance` | Bounded Unicode Edit Distance | `1.1.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.phonetic` | Bounded Cologne Phonetic and Double Metaphone | `1.0.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.regex` | Bounded Regular Expressions | `1.3.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.split-advanced` | Quote/Escape Multi-Separator Split | `1.1.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.split-characters` | Literal Multi-Separator Split | `1.0.0` | `toolbelt_string` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.text-pairs` | Bounded Text Pair Comparison | `1.0.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.tsql.script-parser` | T-SQL Script Parser | `2.0.0` | `toolbelt_tsql` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.validation.semantic-version` | Semantic Version Validation | `1.1.0` | `toolbelt_validation` | `implemented` | `validated` | `unreleased` | 2019, 2022, 2025 |
<!-- END GENERATED:MODULE_STATUS_TABLE -->

Der Modulstatus trennt vorhandenen Code von tatsächlich ausgeführter Evidenz.
Er bedeutet keine pauschale Plattform- oder Pflichtmatrixvalidierung.

## Hinweise für neue Module

1. Freigegebenes Arbeitspaket in `.ai/BACKLOG.md` prüfen.
2. Vorlage aus `Templates/Module/` in ein neues Modulverzeichnis kopieren.
3. Definition of Done: `Documentation/Standards/MODULE_DEFINITION_OF_DONE.md`
4. Namenskonventionen: `Documentation/Standards/SQL_OBJECT_NAMING.md`
5. USP-Vertrag: `Documentation/Standards/USP_CONTRACT.md`
6. Modulstatus erst nach vorhandener Implementierung beziehungsweise ausgeführter Evidenz erhöhen.
