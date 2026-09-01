# Rollback-independent Event Log

## Status

`toolbelt.core.event-log` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

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
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w5b-event-log-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; erstmals auf allen drei Zielversionen erfolgreich, nachdem der Testadapter den Loopback-Provider versionsabhängig konfiguriert
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
