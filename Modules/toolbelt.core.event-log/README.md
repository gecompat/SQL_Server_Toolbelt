# Rollback-independent Event Log

## Status

`toolbelt.core.event-log` Version `1.0.0` ist implementiert und `validated`. Der vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich.

## Zweck

`toolbelt_core.USP_WriteEvent` schreibt strukturierte Events synchron über `toolbelt.core.second-session`. Der Remote-Commit ist von Commit oder Rollback der Caller-Transaktion unabhängig und funktioniert auch aus einem uncommittable Caller, solange der administrierte Loopback-Provider verfügbar ist.

Das Modul speichert keinen frei ausführbaren SQL-Text. `DataJson` ist auf ein JSON-Objekt mit 32 KiB UTF-16-Speicher begrenzt. Meldungen und optionale Fehlerdaten müssen vor der Persistierung auf Vertraulichkeit geprüft werden.

## Öffentliche Objekte

- `toolbelt_core.USP_WriteEvent`
- `toolbelt_core.VW_Events`
- `toolbelt_core.USP_DeleteEventsBefore`

Der interne Handler `USP_WriteEventInternal` wird als Work Type `toolbelt.event-log.write` registriert. Deploy und Uninstall verändern keinen Linked Server und keine Login-Mappings.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, Caller-Rollback, uncommittable Caller, Kontext, Validierung, Retention, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
