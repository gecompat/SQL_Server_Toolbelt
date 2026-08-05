# Event Log – Moduldesign

## Providerentscheidung

Version 1 verwendet ausschließlich `toolbelt.core.second-session` mit einem administrierten Loopback-Linked-Server. Service Broker ist kein Ersatz für rollback-unabhängiges Logging, weil `SEND` Teil der Caller-Transaktion ist. SQL CLR mit externer Verbindung wäre nicht plattformgleich auf SQL Server Linux. Das Modul erzeugt oder verändert weder Linked Server noch Credentials.

## Transaktionssemantik

Der öffentliche Writer sammelt ausschließlich begrenzte Werte und ruft den internen Work Type mit `@SuppressResult = 1` auf. Der Remote-Handler startet und committed seine eigene Session-Transaktion. Caller-Rollback und `XACT_STATE() = -1` beeinflussen den bereits erfolgreichen Remote-Commit nicht.

## Sicherheits- und Datenschutzgrenze

EventName und Level sind begrenzte ASCII-Werte. Message ist `nvarchar(4000)`. DataJson ist ein JSON-Objekt mit höchstens 32 KiB UTF-16-Speicher. Das Modul verhindert keine fachlich vertraulichen Inhalte; Caller dürfen keine Secrets oder ungeprüften personenbezogenen beziehungsweise Unternehmensdaten persistieren.

## Persistenz und Retention

`toolbelt_core.EventLog` ist append-orientiert. Redeploy erhält Daten. Retention ist ein expliziter, begrenzter Administratoraufruf. Uninstall mit Daten benötigt `AllowDataLoss = 1`.

## Work-Type-Lifecycle

Deploy registriert beziehungsweise reaktiviert `toolbelt.event-log.write`. Uninstall prüft den exakten Handlervertrag und entfernt den Eintrag ausschließlich über Disable → `USP_RemoveWorkType`; direkte Katalog-DML ist ausgeschlossen.
