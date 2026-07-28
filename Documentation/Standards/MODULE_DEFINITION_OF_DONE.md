# Definition of Done je Modul

Ein Modul gilt als vollständig implementiert und bereit für `validated`, wenn alle folgenden Kriterien erfüllt sind:

## Implementierung

- [ ] Vollständige Implementierung aller im Modul enthaltenen Objekte
- [ ] Konsistente Verträge gemäß [USP_CONTRACT.md](./USP_CONTRACT.md)
- [ ] Namenskonventionen gemäß [SQL_OBJECT_NAMING.md](./SQL_OBJECT_NAMING.md) eingehalten
- [ ] T-SQL-Regeln gemäß [TSQL_ENGINEERING.md](./TSQL_ENGINEERING.md) eingehalten
- [ ] Kein Boilerplate ohne dokumentierten Zweck

## Dokumentation

- [ ] Modul-README vorhanden
- [ ] Modul-Manifest vorhanden und vollständig
- [ ] Jedes öffentliche SQL-Objekt hat eine eigene Dokumentationsdatei
- [ ] Interne Hilfsobjekte sind dokumentiert
- [ ] Mindestens ein vollständiger Beispielaufruf
- [ ] Alle Einschränkungen ehrlich dokumentiert

## Lifecycle-Artefakte

- [ ] Install-Skript vorhanden und idempotent
- [ ] Upgrade-Skript vorhanden
- [ ] Uninstall-Skript vorhanden (vollständige Entfernung)

## Tests

- [ ] API-Contract-Tests ausgeführt und erfolgreich
- [ ] Install/Upgrade/Uninstall-Tests ausgeführt und erfolgreich
- [ ] Collation-Tests ausgeführt und erfolgreich
- [ ] Lokale Deployment-Tests ausgeführt und erfolgreich
- [ ] Zentrale Deployment-Tests ausgeführt und erfolgreich (falls unterstützt)
- [ ] Alle nicht ausgeführten Tests als `not executed` gekennzeichnet
- [ ] Keine Produktionsdaten in Tests

## Datenschutz

- [ ] Datenschutz-Stop-Gate geprüft
- [ ] Keine personenbezogenen Daten, realen Infrastrukturnamen oder Secrets

## Quellen

- [ ] Primärquellen dokumentiert
- [ ] Keine erfundenen Kompatibilitätsangaben oder Quellen

## Backlog und Status

- [ ] Status in `.ai/BACKLOG.md` aktualisiert
- [ ] Status in `Modules/README.md` aktualisiert
- [ ] `CHANGELOG.md` aktualisiert

## Hinweis

Dieser Initial-PR darf kein Modul als `implemented` oder `validated` ausweisen.
