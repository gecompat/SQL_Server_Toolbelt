# Cancellation mit getrennten Callerrechten verwenden

Stand 2026-10-25. Die drei öffentlichen Cancellation-APIs sind mit jeweils
genau einem Objektrecht lokal und direkt zentral geprüft:

| API | Geprüftes einzelnes Recht |
|---|---|
| `USP_RequestExecutionCancellation` | EXECUTE |
| `TVF_ExecutionCancellationStatus` | SELECT |
| `SVF_IsCancellationRequested` | EXECUTE |

## Tatsächlich geprüfter Umfang

Der [gemeinsame T-SQL-Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert ausschließlich Execution Context und Execution Cancellation 1.0.0
über die vorhandenen verbindungslosen Exports. Die feste
`Runtime/Cancellation.Rights.sql` verwendet eine eigene markierte Datenbank,
einen Benutzer ohne Login und vorher nicht vorhandene synthetische IDs.
Vorhandene Fixtureobjekte oder ein fremder Sessioncontext werden abgewiesen.

Das Request-Profil prüft explizite und aktuelle Execution-ID, gespeicherten
Grund und Bindung an den anfordernden Datenbankprincipal. Ein Wiederholungs-
request erhält Erstgrund, Zeit und RowVersion. TVF und SVF prüfen vorhandene,
unbekannte und NULL-IDs. Fehlendes oder entzogenes Recht, die zwei jeweils
anderen APIs und direkter SELECT/UPDATE auf die interne Tabelle müssen mit
genau SQL229 scheitern. Breite Rollen-, Schema- oder Datenbankrechte entfallen.

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden jeweils local/direct-central: zwölf Fälle, 72 positive API-Profile
und 432 strikte SQL229-Abweisungen. Ein absichtlich falsches Statusflag und
ein zusätzliches fremdes Objektrecht wurden verworfen; beide Kontrollen
bleiben `FAILED_CLEANED`. Keine Session wird beendet und keine Queue verändert.

Alle 14 Versuche bestanden unabhängige Input-/Abwesenheitsaudits. Nach dem
letzten Verbraucher bestanden nochmals frische Audits; alle 26 eigenen
Datenbanknamen waren abwesend. Eigene Principals, Context und Fixturezeilen
sind entfernt. Modulobjekte und Definitionen, CLR, Assemblytrust sowie
Serverkonfiguration blieben unverändert. Private Identitäten und Logs bleiben lokal.

## Quellen und Grenzen

Die [JSON-Projektion](cancellation-rights-qualification.json) bindet die
tatsächlich konsumierten Quellen, Exports, Fixture und vorhandenen gemeinsamen
Harness-/Labadapter. Keine neue Testinfrastruktur, zusätzliche CI-Labmatrix
oder Wiederholung der bisherigen vollständigen Funktionssuite.

Functional verwendet erforderliche Verschlüsselung und den expliziten
Trustwert des schema-validierten Labvertrags. Authentifizierte TLS-Abnahme,
echte Lowpriv-CrossDB-Mappings, vollständige Quoten-/Konkurrenz-/Retention-/
Lifecycleverträge, harte Recovery und andere Modulpflichtfälle bleiben separat.
Dies ist keine vollständige Modul- oder Releaseabnahme. Produktquellen,
Paketbytes und Statuswerte bleiben unverändert; die [Releasegates](RELEASE-GATES.md)
und die separate Veröffentlichungsfreigabe gelten weiterhin.
