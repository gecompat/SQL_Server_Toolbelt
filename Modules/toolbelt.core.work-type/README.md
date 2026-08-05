# Work Type Catalog

## Status

`toolbelt.core.work-type` Version `1.1.0` ist implementiert. Der bisherige Version-1.0-Vertrag ist auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert; die neue kontrollierte Removal-Capability wird capabilitybezogen nachgewiesen.

## Zweck

Das Modul registriert ausschließlich vorhandene Stored Procedures als benannte Work Types. Es akzeptiert und speichert keinen frei ausführbaren SQL-Text.

Der persistente Katalog hält Handler, ParameterMode, deklarativen JSON-Payloadvertrag, Default-Timeout, Idempotenzhinweis, Enabled-Zustand, Auditwerte und `rowversion`. Direkte DML auf die interne Tabelle ist kein öffentlicher Vertrag.

Version `1.1.0` ergänzt die kontrollierte Entfernung eines deaktivierten Work Types. `USP_RemoveWorkType` verlangt ausdrücklich `@AllowDelete = 1`, unterstützt eine optionale `rowversion`-Prüfung, arbeitet in Caller-Transaktionen mit einem Modul-Savepoint und lehnt Änderungen bei `XACT_STATE() = -1` ab. Ein aktiver Work Type kann nicht direkt gelöscht werden.

## Öffentliche Objekte

- `toolbelt_core.VW_WorkTypes`
- `toolbelt_core.USP_RegisterWorkType`
- `toolbelt_core.USP_DisableWorkType`
- `toolbelt_core.USP_RemoveWorkType`
- `toolbelt_core.USP_ResolveWorkType`

Registrierung, Änderung, Deaktivierung und Entfernung sind administrative Vorgänge. Ein registrierender Principal muss `EXECUTE` auf die Zielprocedure besitzen. Ausführungsprovider erhalten einen getrennten Berechtigungs- und Ausführungsvertrag.

Basis-Evidenz Version `1.0.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193
