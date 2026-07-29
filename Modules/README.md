# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

## Aktueller Status

**Das erste Kernmodul ist implementiert und `partially validated`.**

## Implementierte Module

<!-- BEGIN GENERATED:MODULE_STATUS_TABLE -->
| Modul-ID | Name | Version | Schema | Implementierung | Validierung | Release | SQL Server |
|---|---|---:|---|---|---|---|---|
| `toolbelt.core.result-table` | Result Table Infrastructure | `1.0.0` | `toolbelt_core` | `implemented` | `partially validated` | `unreleased` | 2019, 2022, 2025 |
<!-- END GENERATED:MODULE_STATUS_TABLE -->

Der Modulstatus belegt vorhandenen Code und erfolgreiche Linux-Evidenz. Er bedeutet noch keine vollständige Plattform- und Pflichtmatrixvalidierung.

## Hinweise für neue Module

1. Freigegebenes Arbeitspaket in `.ai/BACKLOG.md` prüfen.
2. Vorlage aus `Templates/Module/` in ein neues Modulverzeichnis kopieren.
3. Definition of Done: `Documentation/Standards/MODULE_DEFINITION_OF_DONE.md`
4. Namenskonventionen: `Documentation/Standards/SQL_OBJECT_NAMING.md`
5. USP-Vertrag: `Documentation/Standards/USP_CONTRACT.md`
6. Modulstatus erst nach vorhandener Implementierung beziehungsweise ausgeführter Evidenz erhöhen.
