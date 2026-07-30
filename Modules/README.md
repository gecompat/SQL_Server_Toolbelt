# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

## Aktueller Status

**Sechs Module sind implementiert; ihr Validierungsstand wird getrennt aus den Manifesten abgeleitet.**

## Implementierte Module

<!-- BEGIN GENERATED:MODULE_STATUS_TABLE -->
| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |
|---|---|---:|---|---|---|---|---|
| `toolbelt.conversion.base64` | Base64 and Base64URL Conversion | `1.0.0` | `toolbelt_conversion` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.generate-series` | Portable Integer Series | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.core.result-table` | Result Table Infrastructure | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.metadata.identifier` | Identifier and Multipart Name Toolkit | `1.0.0` | `toolbelt_metadata` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.string.split-characters` | Literal Multi-Separator Split | `1.0.0` | `toolbelt_string` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
| `toolbelt.validation.semantic-version` | Semantic Version Validation | `1.0.0` | `toolbelt_validation` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
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
