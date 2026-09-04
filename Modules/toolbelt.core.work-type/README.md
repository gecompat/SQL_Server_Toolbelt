# Work Type Catalog

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.work-type` Version `1.1.0` ist implementiert und einschließlich der kontrollierten Removal-Capability auf SQL Server 2019/2022/2025 unter Windows base und Linux latest `validated`.

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

Removal-Evidenz Version `1.1.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937

Der vollständige Moduladapter war am 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Konkurrenz-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
