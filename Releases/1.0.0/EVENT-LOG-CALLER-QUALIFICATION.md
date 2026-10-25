# Event Log: Lesen und lokale Retention mit Einzelrechten

Beide Retention-Profile treffen in diesen synthetischen Daten jeweils zwei
alte Zeilen. Die Callerfixture belegt daher Zugriff, begrenzte Löschzahlen und
exakte Wiederherstellung; sie unterscheidet nicht zusätzlich die Identitäten
der je Zeitachse ausgewählten Zeilen. Deren fachliche Auswahlorakel bleiben im
bestehenden Retentionvertrag und dessen separaten Nachweisen.

Stand 2026-10-25. Die vorhandene View besteht eine feste vollständige 24-Spalten-Projektion von vier synthetischen Events. Beide Retention-Prozeduren bestehen je einen einzelnen EXECUTE-Grant: unterschiedliche OccurredAtUtc-/RecordedAtUtc-Achsen, begrenzte Löschzahlen 1/1/0, exakte SQL51711-Abweisung und unveränderte Callertransaktion. Nach eigenem Rollback und dem gemeinsamen Principal-Cleanup prüft ein vierter fester Fixtureteil die exakte ursprüngliche Zeilenmenge und den Root-Kontext. Direkte Tabelle, Event-Producer, interner Writer, Sessiontransport und ResultTable-Helfer bleiben gesperrt. Producer-Routing, neue Sessions, Standalone-Commit-, Infrastruktur-, Client- und Ressourcengates behalten ihren gesonderten Scope.

Zwölf Ziel-/CL-Kombinationen auf Windows und Linux: SQL2019/CL150,
SQL2022/CL150/160 und SQL2025/CL150/160/170, jeweils lokal und direkt zentral.
Der eigene Benutzer ohne Login erhält nacheinander genau ein Objektrecht.
Ohne Grant, nach REVOKE und für die getrennt genannten anderen Objekte muss
die Engine exakt SQL229 liefern; breite Datenbank-/Schemarechte bleiben ausgeschlossen.

| API | Einziger Grant |
|---|---|
| `toolbelt_core.VW_Events` | SELECT |
| `toolbelt_core.USP_DeleteEventsBefore` | EXECUTE |
| `toolbelt_core.USP_DeleteRecordedEventsBefore` | EXECUTE |

Die feste kanonische Fixture `EventLog.FunctionCases.sql` verwendet
den unveränderten [gemeinsamen Callerablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).
Die [öffentliche JSON-Projektion](event-log-caller-qualification.json) bindet
Komposition, Source-/Treiber-/Exportbytes, Matrix, Orakelkontrollen und Grenzen.
Es bestehen 72 positive Einzelgrantprofile und
648 erwartete SQL229-Abweisungen. Zwei frische Kontrollen
mit falschem Orakel und zusätzlichem Grant werden verworfen. Nach allen Verbrauchern
sind 14 akzeptierte terminale Journale unabhängig frisch auditiert; alle
26 eigenen Datenbanknamen sind abwesend. Keine Serverkonfigurations-, Login-,
Assemblytrust- oder fremden Änderungen; private Journale bleiben lokal.

Fünf frühere Versuche bleiben erhalten: eine Nullbarkeitsabweichung der lokalen
Erwartungstabelle, zwei ursprüngliche Gegenkontrollen, ein positiver Lauf mit
falschpositiver kombinierter Kontextprüfung und eine begrenzte Kontextdiagnose.
Die endgültige Komposition verwendet getrennte Transaktions-/Metadatenprüfungen
mit unveränderten Bedingungen. Alle fünf früheren Datenbanknamen sind nach
allen Verbrauchern separat frisch als abwesend bestätigt; ursprüngliche Pins
und Audits bleiben erhalten und werden nicht als aktuelle Qualifikation ausgegeben.

Diese Callerprofile ersetzen keine vollständige API-, Ausgabe-, Client-,
Lifecycle-, Ressourcen- oder Supportabnahme. Frühere Nachweise behalten ihren
eigenen Scope. Echte Lowpriv-CrossDB-Mappings und authentifiziertes TLS bleiben
separat. Functional verwendet Verschlüsselung und den expliziten Trustwert des
schema-validen Labvertrags ohne automatischen Transportfallback. Produkt-SQL,
Manifeste, Status und Pakete bleiben unverändert; keine Veröffentlichung oder Tags.
Weitere [Releasegates](RELEASE-GATES.md) bleiben offen.
