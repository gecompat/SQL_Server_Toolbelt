# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

## Aktueller Status

**Noch keine fachlichen Module implementiert.**

Das erste Kernmodul ist implementierungsreif spezifiziert. Seine Source-, Deployment- und Testartefakte werden erst im freigegebenen Implementierungsarbeitspaket unter `Modules/` angelegt.

## Implementierte Module

| Modul-ID | Name | Schema | Status | SQL Server |
|---|---|---|---|---|
| – | – | – | – | – |

## Implementierungsreif geplante Module

| Modul-ID | Name | Schema | Status | Spezifikation |
|---|---|---|---|---|
| `toolbelt.core.result-table` | Result Table Infrastructure | `toolbelt_core` | `planned` | [RESULT_TABLE_MODULE_DESIGN.md](../Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md) |

Ein Design oder Manifest ist kein Runtime-Nachweis und wird nicht als implementiertes Modul geführt.

## Hinweise für neue Module

1. Freigegebenes Arbeitspaket in `.ai/BACKLOG.md` prüfen.
2. Vorlage aus `Templates/Module/` in ein neues Modulverzeichnis kopieren.
3. Definition of Done: `Documentation/Standards/MODULE_DEFINITION_OF_DONE.md`
4. Namenskonventionen: `Documentation/Standards/SQL_OBJECT_NAMING.md`
5. USP-Vertrag: `Documentation/Standards/USP_CONTRACT.md`
6. Modulstatus erst nach vorhandener Implementierung beziehungsweise ausgeführter Evidenz erhöhen.
