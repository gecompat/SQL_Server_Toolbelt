# Module – SQL Server Toolbelt

Dieses Verzeichnis enthält ausschließlich tatsächlich implementierte Module von SQL Server Toolbelt.

## Aktueller Status

**Das erste Kernmodul ist implementiert; Runtime-Validierung ist `not executed`.**

## Implementierte Module

| Modul-ID | Name | Schema | Status | SQL Server |
|---|---|---|---|---|
| `toolbelt.core.result-table` | Result Table Infrastructure | `toolbelt_core` | `implemented`; Runtime `not executed` | 2019, 2022, 2025 |

Der Modulstatus belegt vorhandenen Code und statische Verträge, aber keine erfolgreiche SQL-Server-Ausführung.

## Hinweise für neue Module

1. Freigegebenes Arbeitspaket in `.ai/BACKLOG.md` prüfen.
2. Vorlage aus `Templates/Module/` in ein neues Modulverzeichnis kopieren.
3. Definition of Done: `Documentation/Standards/MODULE_DEFINITION_OF_DONE.md`
4. Namenskonventionen: `Documentation/Standards/SQL_OBJECT_NAMING.md`
5. USP-Vertrag: `Documentation/Standards/USP_CONTRACT.md`
6. Modulstatus erst nach vorhandener Implementierung beziehungsweise ausgeführter Evidenz erhöhen.
