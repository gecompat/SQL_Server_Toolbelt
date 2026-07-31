# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

## Aktueller Status

**18 Module sind implementiert. 17 sind `partially validated`, 1 ist
`not executed`. Der Einzelstatus wird aus den Manifesten abgeleitet.**

## Implementierte Module

<!-- BEGIN GENERATED:MODULE_STATUS_TABLE -->
| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |
|---|---|---:|---|---|---|---|---|
| `toolbelt.archive.zip-memory` | ZIP Memory Extraction | `1.1.0` | `toolbelt_archive` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.binary.bit-operations` | Bigint Bit Operations Compatibility | `1.0.0` | `toolbelt_binary` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.base64` | Base64 and Base64URL Conversion | `1.1.0` | `toolbelt_conversion` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.integer-base` | Integer Base Conversion | `1.1.0` | `toolbelt_conversion` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.conversion.uri-component` | URI Component Percent-Encoding | `1.0.0` | `toolbelt_conversion` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.console-message` | Console Message | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.generate-series` | Portable Integer Series | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.result-table` | Result Table Infrastructure | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.bucket` | Date/Time Bucket Compatibility | `1.0.0` | `toolbelt_datetime` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.calendar-difference` | Calendar Difference | `1.0.0` | `toolbelt_datetime` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.datetime.truncate` | Date/Time Truncation Compatibility | `1.0.0` | `toolbelt_datetime` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.filesystem.windows` | Windows Filesystem | `1.0.0` | `toolbelt_filesystem` | `implemented` | `not executed` | `unreleased` | 2019, 2022, 2025 (Windows only) |
| `toolbelt.json.path-exists` | JSON Path Exists | `1.0.0` | `toolbelt_json` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.capability-catalog` | Module Capability Catalog | `1.0.0` | `toolbelt_metadata` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.identifier` | Identifier and Multipart Name Toolkit | `1.0.0` | `toolbelt_metadata` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.directional-trim` | Directional TRIM Compatibility | `1.0.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.split-characters` | Literal Multi-Separator Split | `1.0.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.validation.semantic-version` | Semantic Version Validation | `1.1.0` | `toolbelt_validation` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
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
