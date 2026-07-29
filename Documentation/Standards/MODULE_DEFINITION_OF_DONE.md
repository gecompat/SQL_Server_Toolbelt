# Definition of Done je Modul

Ein Modul darf den `implementation_status: implemented` erhalten, wenn Implementierung, statische Verträge, Dokumentation und Lifecycle-Artefakte vollständig und konsistent sind. `validation_status: validated` ist erst zulässig, wenn alle für den deklarierten Support erforderlichen Prüfungen tatsächlich erfolgreich ausgeführt wurden.

## Implementierung

- [ ] Alle Modulobjekte vollständig implementiert.
- [ ] Öffentliche Verträge und Namenskonventionen eingehalten.
- [ ] Kanonische Fachlogik ohne unnötige Duplikation.
- [ ] Set-basierte und Inline-Lösungen bevorzugt, soweit fachlich möglich.
- [ ] Error Handling an geeigneten Grenzen.
- [ ] Collation-, Datentyp-, Performance- und Plattformvertrag dokumentiert.

## Dokumentation

- [ ] Modul-README und vollständiges Manifest.
- [ ] Gekoppelte Modul-, Objekt-, Architektur- und Testdokumentation im Manifest registriert.
- [ ] Verwendete Contract-Versionen im Manifest registriert.
- [ ] Eigene Dokumentationsseite für jedes öffentliche SQL-Objekt.
- [ ] Interne Hilfsobjekte dokumentiert.
- [ ] Codekommentare erklären Absicht und Besonderheiten auf Deutsch.
- [ ] Synthetische Beispiele entsprechen der tatsächlichen Implementierung.
- [ ] Rechte, Fehlerverhalten, Performance und Einschränkungen dokumentiert.
- [ ] Primärquellen und Aussagegrenzen nachvollziehbar.

## Lifecycle

- [ ] Parametergesteuertes Deploy-Skript mit vollständigem Preflight.
- [ ] Kontrolliert wiederholbare Erst-, Upgrade- und Wiederholungsinstallation.
- [ ] Versionierte Release-Manifeste für unterstützte Vorgängerversionen.
- [ ] Neue Namenskollisionen und entfernte Release-Objekte objektgenau behandelt.
- [ ] Uninstall mit Dependency-Schutz und ohne fremde Daten zu entfernen.
- [ ] Cleanup- und Recovery-Pfad geprüft.

## Tests

- [ ] Statische und öffentliche API-Contract-Tests erfolgreich.
- [ ] USP-Contract-Tests für `@Hilfe`, `@Debug`, `@ResultTable` und `@KeepData`, soweit zutreffend.
- [ ] Erst-, Wiederholungs-, Upgrade- und Uninstall-Tests erfolgreich.
- [ ] Collation- und Datentests erfolgreich.
- [ ] Lokale und zentrale Deployment-Tests entsprechend Capability.
- [ ] Cross-database-Test oder begründetes `not applicable`.
- [ ] SQL Server 2019, 2022 und 2025 entsprechend deklariertem Support geprüft.
- [ ] Windows, Linux und alternative Provider getrennt bewertet.
- [ ] Nicht ausgeführte Prüfungen sichtbar und begründet.

## Datenschutz und Security

- [ ] Datenschutz- und Secret-Stop-Gate geprüft.
- [ ] Keine personenbezogenen/sensiblen, internen/vertraulichen, Original-, nicht öffentlichen Infrastruktur-, realen Runtime- oder konkreten Remote-Runner-Hardwaredaten im Repository; öffentliche relevante Organisations-/Projektnamen und Links sind zulässig.
- [ ] Keine privaten Schlüssel oder Secrets.
- [ ] CLR- und `TRUSTWORTHY`-Ausnahmen ausdrücklich freigegeben, falls vorhanden.

## Status und Release

- [ ] `.ai/BACKLOG.md`, `Modules/README.md` und `CHANGELOG.md` aktualisiert.
- [ ] `implementation_status`, `validation_status` und `release_status` stimmen mit tatsächlichem Stand und Evidenz überein.
- [ ] Generierte Statusabschnitte stimmen mit dem Manifest überein.
- [ ] Inkrementeller Change-Impact-Validator erfolgreich.
- [ ] Breaking Changes und Migrationspfad dokumentiert.
- [ ] Keine offene Pflichtprüfung wird durch eine pauschale Erfolgsaussage verdeckt.
