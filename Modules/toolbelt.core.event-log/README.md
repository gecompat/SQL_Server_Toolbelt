# Rollback-independent Event Log


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Aktuelle [Callerrechte](../../Releases/1.0.0/EVENT-LOG-CALLER-QUALIFICATION.md): getrennte Objektrechte auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral. Weitere Funktions-, Client-, Lifecycle- und Ressourcengates sowie Modulstatus bleiben separat.

## Status

`toolbelt.core.event-log` Version `1.0.0` ist implementiert und `validated`. Der vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich.

## Zweck

`toolbelt_core.USP_WriteEvent` schreibt strukturierte Events synchron über `toolbelt.core.second-session`. Der Remote-Commit ist von Commit oder Rollback der Caller-Transaktion unabhängig und funktioniert auch aus einem uncommittable Caller, solange der administrierte Loopback-Provider verfügbar ist.

Das Modul führt keine Eventtexte als SQL aus. `DataJson` ist auf ein JSON-Objekt
mit 65536 UTF-16-Bytes (64 KiB) begrenzt. Meldungen und optionale Fehlerdaten
müssen vor der Persistierung auf Vertraulichkeit geprüft werden. Die View
maskiert diese Inhalte nicht.

## Öffentliche Objekte

- `toolbelt_core.USP_WriteEvent`
- `toolbelt_core.VW_Events`
- `toolbelt_core.USP_DeleteEventsBefore`
- `toolbelt_core.USP_DeleteRecordedEventsBefore`

Der interne Handler `USP_WriteEventInternal` gehört zum Work Type
`toolbelt.event-log.write`. Der gemeinsame create-only-Installer registriert
einen fehlenden Eintrag nur zusammen mit den selbst neu angelegten
Abhängigkeitsobjekten; bestehende Einträge werden nicht stillschweigend ersetzt.
Den Loopback-Provider und seine vorhandenen Berechtigungen administrativ
vorbereiten; der Installer richtet keinen Linked Server oder Loginmapping ein.

Alle sechs Objekte besitzen einen vollständigen quellgeprüften
[Usage-Skill](../../Metadata/UsageSkills/README.md) in ihrer ausgelieferten DDL.
Die vier Prozeduren liefern ihn über `@Hilfe=1` zusätzlich zur bisherigen
Standardhilfe. Die neue Projektion ist offline geprüft, nicht neu nativ
qualifiziert. Schreibfehler nach einem Remote-Commit können einen unsicheren
Ausgang bedeuten; gleiche Kontext-IDs verhindern keine Duplikate bei Wiederholung.

## Historischer Lifecycle

In den früheren markerbasierten Installationsartefakten war ein wiederholter
Uninstall auch nach dem Entfernen der WorkType-Dependency
möglich, wenn sämtliche Event-Log-Objekte und Modulmarker bereits fehlten.
Ein noch installierter oder inkonsistent markierter Event-Log-Zustand ohne
WorkType blieb mit Fehler 51748 gesperrt. Dies beschreibt keinen aktuellen
Uninstallweg: der gemeinsame Installer ist create-only. Die
[Releaseprüfung](../../Releases/1.0.0/RELEASE-GATES.md) dokumentiert den tatsächlichen Scope.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37692309192`
- Scope: Commit 6f51078cfa1f13ace32212f07d46de8d55d39ef0: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf Linux2019/150,2022/160,2025/170; alle 24 Eventspalten mit NULL-/Text-/Auditbytes, verbrauchter Identityhöchstwert/Folgeinsert, ausgewählter Katalog und eigene typisierte Annotationen/MS_Description erhalten. Erster Deploy reaktiviert eigenen abweichend deaktivierten WorkType kanonisch, zweiter erhält vollständige aktive Zeile/Rowversion; andere Registrierungen unverändert. Bestehende API-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung bestanden. Neue Windows-Repeats, weitere Repeat-CLs, nichtleere Benutzergrants, Minimalrechte, historische Migrationen und Hard-Interrupt-Recovery bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-024: USP_DeleteRecordedEventsBefore ergänzt ausdrücklich aufgerufene Retention nach RecordedAtUtc und Index(RecordedAtUtc,EventId). BatchSize1..10000, MaxBatches1..100. OccurredAtUtc-Retention bleibt unverändert. Keine Jobs, automatische Löschung oder Rechtevergabe.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).
