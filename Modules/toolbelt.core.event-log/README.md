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
