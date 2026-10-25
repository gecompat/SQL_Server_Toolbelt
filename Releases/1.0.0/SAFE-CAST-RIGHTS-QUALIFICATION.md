# Safe Cast mit genau einem SELECT aufrufen

Stand 2026-10-25. Alle sechs öffentlichen Safe-Cast-TVFs sind mit jeweils
genau einem SELECT auf die einzelne Funktion geprüft. Breite Rollen-,
Schema- und Datenbankrechte sind ausgeschlossen. Der bisherige vollständige
Funktionsadapter bleibt ein eigener Nachweis; diese Welle ergänzt dessen
fehlende begrenzte Callerrechteprüfung.

## Ausführung und Ergebnis

Der [T-SQL-Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert ausschließlich `toolbelt.conversion.safe-cast` 1.0.0 aus den
vorhandenen verbindungslosen Exporten. In der eigenen markierten Datenbank
erhält ein Benutzer ohne Login nacheinander SELECT auf BigInt, Decimal,
Date, DateTime2, Bit und UniqueIdentifier. Vor dem Grant, nach dem Entzug
und beim Aufruf jeder der fünf anderen Funktionen wird exakt SQL229 verlangt.

Je Funktion prüfen sieben feste Datenfälle den typgenauen gültigen Wert,
SQL-NULL vor ungültigem Budget, leeren Text, ungültige Lexik, Bytegrenze,
ungültiges Budget und einen typbezogenen Sonderfall. Dazu gehören Bigint-
Überlauf, Decimal-Skalenverlust, ungültiger Schalttag, Stunde 24, Bit 2 und
GUID-Klammern. Jeder Fall verlangt genau eine Zeile und exakte Status-/
Fehlerwerte; unerwartete Werte werden nicht als zulässige Engineabweichung
umgedeutet. Die Erfassung deklariert NULL unabhängig von Sessiondefaults.

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden jeweils lokal und direkt zentral: zwölf Zielfälle mit **144
isolierten Callerprofilen, 1.008 Wertfällen und 1.008 SQL229-Abweisungen**.
Modulobjekte und Definitionen blieben erhalten. Ein absichtlich falscher
erwarteter Wert und ein zusätzliches fremdes SELECT wurden verworfen;
beide bleiben `FAILED_CLEANED`.

Alle 14 Versuche bestanden unabhängige Input-/Abwesenheitsaudits. Nach dem
letzten Verbraucher bestanden weitere frische Audits; alle 26 eigenen
Datenbanknamen waren abwesend. CLR, Assemblytrust, Serverkonfiguration,
Server-Logins und fremde Ressourcen wurden nicht verändert. Reale
Labidentitäten, Verbindungsdaten und Rohlogs bleiben lokal.

## Bindung und Grenzen

Die [JSON-Projektion](safe-cast-rights-qualification.json) bindet die sechs
Produktquellen, Deploymentquellen, Fixture, tatsächlich ausgeführten Exports,
den gemeinsamen begrenzten T-SQL-Harness und dessen importierte Helfer.
Der Harness verwendet die bisherigen SQL-/Pin-/Ownership-/Deadlinefunktionen;
er wird für weitere ausdrücklich ausgewählte T-SQL-Rechteverträge wiederverwendet,
anstatt pro Modul einen weiteren Testtreiber anzulegen. Kein neuer CI-Job
und keine Wiederholung der bereits grünen vollständigen Funktionsmatrix.

Die Funktionalprüfung nutzt erforderliche Verschlüsselung und den expliziten
Trustwert des schema-validierten Labvertrags. Authentifizierte TLS-Abnahme
bleibt separat. Direktes zentrales SELECT mit einem Benutzer ohne Login
belegt kein echtes CrossDB-Identitätsmapping. Lifecycle-DDL-/Release-Marker-
Minimalrechte, harter Runner-/Hostverlust, Produktionskapazität, die übrigen
[Releasegates](RELEASE-GATES.md) und Veröffentlichung bleiben offen.
Modulstatus, Produktquellen und bestehende Paketbytes bleiben unverändert.
