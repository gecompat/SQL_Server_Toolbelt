# CLR-Stringfunktionen: vorhandene API-Matrix aktuell zugeordnet

Der Abgleich vom 2026-11-09 bestätigt den unveränderten
[Gesamt-API-Nachweis vom 2026-10-23](API-QUALIFICATION.md) für Phonetik 1.0.0
und Edit Distance 1.1.0. Beide Module enthalten bereits **zwölf Windows-/Linux-
Engine-/CL-Paare lokal und direkt zentral**, ohne blockierte Modulfixtures.

| Modul | Originalfixtures je Kontext | Damals neu bestanden | Damals gültig übernommen | Summe |
|---|---:|---:|---:|---:|
| Edit Distance | 5 | 115 | 5 | 120 |
| Phonetik | 3 | 69 | 3 | 72 |

Die ursprünglichen Zahlen und Methoden bleiben unverändert in
[api-qualification.json](api-qualification.json). Die acht zugehörigen
Fixturepins wurden mit dem kanonischen Source-Resolver gegen ihre Originalbytes
geprüft und sind aktuell bytegleich. Zusätzlich entsprechen alle 29 ausgewählten
CLR-/Projekt-/SQL-/Deployment-/Manifestinputs beider Module exakt den Gitbytes
des im Originalbericht gebundenen
[Produktcommits a20ede0b](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a20ede0b8de92203244d9b15d30426bf5f9a8b37).
Dies ist ein aktueller Anwendbarkeitsabgleich, keine neue Ausführung oder
Umschreibung des historischen Records und keine Behauptung beliebiger neuer DLLs.

Damit sind pauschale fehlende physische **API-/Grenz-/Metadatenziele** für diese
Originalfixtures überholt. Sie sind kein Grund für eine neue native Phonetik-
oder Edit-Distance-API-Matrix. Vollständige Scanner-/Algorithmusabdeckung,
weitere Lifecycle-/DDL-/Markerrechte, andere Owner und echte CrossDB-Identitäten,
Heap-/Parallelitäts-/Recovery-/Betriebsprofile und Modulgesamtabnahme bleiben
separat. Bestehende [direkte Callerrechte](CLR-STRING-CALLER-CURRENT-BINDING.md)
behalten ebenfalls ihren eigenen Umfang. Beide Modulstatus bleiben unverändert.

Die später begonnene [Edit-Distance-Neuausführung](EDIT-DISTANCE-MISSING-TARGETS-QUALIFICATION.md)
hatte diesen älteren Gesamt-API-Nachweis zunächst übersehen. Sie enthält 80
redundante API-Fixtures und 16 zusätzliche read-only Lifecyclebaselines mit
ausdrücklicher Paketbytebindung. Das wird offen getrennt: alle 16 verbrauchten
Lauf-/Auditaufrufe, 16 eigenen DBs, Originaljournale und acht frischen Audits
bleiben erhalten; keine Grenzen zurückgesetzt und keine neue Wiederholung.
Die separate Quellenzuordnung hier selbst benötigt **keinen SQL-Aufruf,
Build, Benutzer, Grant oder Server-/Lab-/Paketwechsel**.

Aktuelle Einstiege: [Phonetik-Testmatrix](../../Modules/toolbelt.string.phonetic/Tests/PHONETIC_TEST_MATRIX.md),
[Edit-Distance-Testmatrix](../../Modules/toolbelt.string.edit-distance/Tests/EDIT_DISTANCE_TEST_MATRIX.md),
[Testinventar](../../Tests/README.md) und [Releaseeinstieg](README.md).
Historische datierte/generated Abschnitte, Payloads und Originalpins bleiben
unverändert. Keine Veröffentlichung oder Tags.
