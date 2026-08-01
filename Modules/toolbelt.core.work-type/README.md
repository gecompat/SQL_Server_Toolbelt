# Work Type Catalog

## Status

`toolbelt.core.work-type` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Zweck

Das Modul registriert ausschließlich vorhandene Stored Procedures als benannte Work Types. Es akzeptiert und speichert keinen frei ausführbaren SQL-Text.

Der persistente Katalog hält Handler, ParameterMode, deklarativen JSON-Payloadvertrag, Default-Timeout, Idempotenzhinweis, Enabled-Zustand, Auditwerte und `rowversion`. Direkte DML auf die interne Tabelle ist kein öffentlicher Vertrag.

## Öffentliche Objekte

- `toolbelt_core.VW_WorkTypes`
- `toolbelt_core.USP_RegisterWorkType`
- `toolbelt_core.USP_DisableWorkType`
- `toolbelt_core.USP_ResolveWorkType`

Registrierung und Änderung sind administrative Vorgänge. Ein registrierender Principal muss `EXECUTE` auf die Zielprocedure besitzen. Der zukünftige Session-Provider erhält einen getrennten Berechtigungs- und Ausführungsvertrag.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703294213
