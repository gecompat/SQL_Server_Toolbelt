# Queue-Producer und Handler gezielt autorisieren

Stand 2026-10-25. Der bestehende Autorisierungsvertrag von Work Queue 2.1.0
ist auf zwölf physischen Ziel-/CL-Kombinationen lokal und direkt zentral
geprüft. Die Qualifikation ergänzt die vorhandenen Nachweise; sie ist keine
vollständige API-Minimalrechte-, Worker- oder Releaseabnahme.

## Geprüftes Verhalten

| Situation | Tatsächlich geprüftes Ergebnis |
|---|---|
| Producer ohne ENQUEUE-Policy | SQL51998; kein Work Item erzeugt |
| Producer mit explizitem ALLOW | Einreihung möglich |
| Handler sichtbar, aber nicht ausführbar | Keine Claim-Zeile und kein CLAIMED-Item |
| CLAIM-Policy und Handler-EXECUTE | Genau eine Claim-Zeile |
| ENQUEUE-DENY bei vorhandener Idempotenzkennung | SQL51998 vor einer Idempotenzauskunft |
| Drain-Barrier in einer Callertransaktion | SQL51997; Callertransaktion erhalten |
| Abgewiesene Folgeaufrufe | Vorhandener Queuezustand unverändert |

Die feste kanonische Fixture
`Modules/toolbelt.core.work-queue/Tests/Runtime/Authorization.Contract.sql`
bleibt bytegleich. Ihr Benutzer ohne Login erhält nur die dort ausdrücklich
benannten Objektrechte und die gezielten Work-Type-Policyeinträge. Das ist ein
zusammengesetztes Autorisierungsprofil, kein Nachweis des isolierten
Mindestrechtesatzes jeder einzelnen Queue-API.

## Ausführung und Ergebnis

Der [Release-Testweg](../../Tests/Release/README.md#queue-autorisierungsvertrag-physisch-prüfen)
bindet den kanonischen Vertrag an einen eigenen markierten Datenbankscope.
Der zusätzliche Präfix setzt den NULL-Default für die eigene Erfassungstabelle
explizit; alle ursprünglichen Policy-, Claim-, Idempotenz- und
Transaktionsorakel bleiben unverändert. Vorhandene Fixtureobjekte und fremde
Datenbanken werden abgewiesen; ein Suffix prüft das vollständige Entfernen
der eigenen Testobjekte und den leeren Transaktionsscope.

Windows und Linux bestanden SQL2019 CL150, SQL2022 CL150/160 und SQL2025
CL150/160/170, jeweils local/direct-central: 24 Datenbankkontexte,
48 strikte SQL51998- und 24 SQL51997-Abweisungen sowie je 24 leere
Sichtbarkeitsclaims und erfolgreiche autorisierte Claims. Die Installation
enthielt ausschließlich ResultTable, Work Type und Work Queue über den
vorhandenen verbindungslosen Exporter. Modulobjekte und Definitionen blieben
erhalten. Kein externer Worker, CLR, Assemblytrust oder Serverparameter wurde
gestartet beziehungsweise verändert.

Eine absichtlich falsche erwartete Policyfehlernummer und eine falsche
Claim-Zeilenzahl wurden jeweils verworfen und bereinigt. Beide bleiben
`FAILED_CLEANED`. Alle 14 Versuche bestanden separate unabhängige Input-/
Bereinigungsaudits; nach dem letzten Verbraucher bestanden nochmals frische
Audits. Alle 26 eigenen Datenbanknamen waren abwesend. Reale Identitäten,
Claimtokens, Verbindungsdaten und Rohlogs bleiben lokal.

## Bindung und offene Grenzen

Die [JSON-Projektion](queue-authorization-qualification.json) bindet die
kanonische Fixture, Produktquellen, Exports und den unverändert ausgeführten
nativen Harness. Der Fixture-Generator erhält anschließend einen zusätzlichen
Runtime-Verzeichnisguard. Ausgeführter und aktueller Generator erzeugen
nachweislich exakt dieselben SQL-Bytes; die ursprüngliche Generatorfassung
und deren Hash bleiben getrennt erhalten. Eine gezielte Offlinegegenprobe
weist den Runtime-Alias vor jeder Ausgabe ab. Dies ist kein neuer nativer Lauf.

Functional verwendet notwendige Verschlüsselung und den expliziten Trustwert
des schema-validierten Labvertrags; authentifizierte TLS-Abnahme bleibt separat.
Offen sind insbesondere vollständige isolierte API-Minimalrechte, echte
CrossDB-Identitätsmappings, Managed-/Providerparallelität, harter Transport-/
Hostverlust und weitere modulspezifische Releasepflichtfälle. Modulstatus,
Produktquellen und bisherige Paketbytes bleiben unverändert. Die
[Releasegates](RELEASE-GATES.md) und eine separate Veröffentlichungsfreigabe
gelten weiterhin.
