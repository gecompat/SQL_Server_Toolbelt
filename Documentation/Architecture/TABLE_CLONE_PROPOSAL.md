# Vorschlag: Kontrollierter Tabellenklon (`TC-2026-044`)

## Status

`TC-2026-044` bleibt Research. Dieses Dokument bereitet die spätere
Funktionsbesprechung vor. Es autorisiert keine DDL-Ausführung, keinen Zugriff
auf reale Metadaten und kein öffentliches SQL-Objekt.

## Empfohlene erste Grenze

V1 soll ausschließlich ein **Script-only-Planer** sein: Er liest eine
ausdrücklich angegebene Quelle in derselben Datenbank, erzeugt eine
deterministische DDL-Vorschau und führt sie niemals aus. Datenkopie,
`SELECT ... INTO`, dynamische Ausführung, datenbankübergreifende Quellen und
automatische Recovery gehören nicht zu V1.

Dieser Schnitt trennt die schwierige Metadaten- und Namensplanung von einer
irreversiblen Mutation. `SELECT ... INTO` ist kein Ersatz, weil es weder
vollständige Constraints noch Indizes, Trigger und weitere Tabelleigenschaften
reproduziert.

## Vorgeschlagener V1-Umfang

| Eingeschlossen | Ausgeschlossen |
|---|---|
| reguläre diskbasierte Benutzertabellen ohne Spezialfeatures | temporäre, externe, FileTable-, graph-, ledger-, temporal-, partitionierte und memory-optimierte Tabellen |
| Spalten, `NULL`/`NOT NULL`, Default- und Check-Constraints | Daten, Identity-Werte, Rowguidcol, Computed Columns und Sparse/Columnset-Eigenschaften |
| Primär-/Unique-Constraints und nicht gefilterte, nicht partitionierte Nonclustered-Indizes | Foreign Keys, Trigger, Berechtigungen, Extended Properties, Statistik, Volltext, XML-/Spatial-/Columnstore-Indizes |
| explizit beantragtes Ziel-Schema und Zieltabellenname | automatische Zielnamen, Überschreiben, `DROP`, `ALTER` oder Ausführung |

Die Liste ist absichtlich eng. Jede spätere Objektklasse kann Dependencies,
Ownership, Reihenfolge oder Sicherheitswirkung verändern und wird deshalb als
eigener Ausbau behandelt.

## Plan- und Naming-Vertrag

Der Planer soll eine normale ResultTable zurückgeben, keine ausführbare
Nebenwirkung. Jede Zeile beschreibt ein einzelnes geplantes DDL-Statement mit
stabiler positiver Reihenfolge, Objektart, Zielname und Scripttext. Der
Caller ist für Sichtung, Speicherung und Ausführung außerhalb des Toolbelts
verantwortlich.

Quell- und Zielnamen werden getrennt validiert. Der vorhandene
Identifier-Vertrag ist für Zeichen- und Längengrenzen wiederzuverwenden;
Quoting muss die erzeugte DDL gegen Identifier-Injection schützen. Jeder
generierte Constraint- oder Indexname wird aus Zieltabelle, Objektart und
einem deterministischen Suffix gebildet. Kollisionen und Überschreiten der
Identifierlänge sind vor der vollständigen Planausgabe als Fehler sichtbar;
es gibt weder stilles Trunkieren noch zufällige Namen.

Der Planer prüft, dass die Zieltabelle zum Planzeitpunkt nicht existiert und
dass der Aufrufer Metadatenzugriff auf die Quelle besitzt. Das ist eine
Momentaufnahme: Zwischen Plan und einer späteren, externen Ausführung können
Quelle oder Ziel driften. Ein Ausführungsfeature benötigt deshalb später
einen eigenen Snapshot-, Berechtigungs-, Transaktions- und Recoveryvertrag.

## Technologie und Prüfungen

Ein portabler T-SQL-Metadatenkern auf Systemkatalogen ist für die enge
V1-Menge ausreichend. SMO/DacFx ist für diesen ersten Scope nicht erforderlich
und würde externe Runtime-, Versions- und Deploymentabhängigkeiten einführen.
Die ResultTable darf keine Quell-DDL oder Metadaten protokollieren; Tests
verwenden ausschließlich synthetische Tabellen- und Objektnamen.

Die Testmatrix umfasst leere und befüllte synthetische Quelltabellen,
zusammengesetzte Schlüssel, Default-/Check-Constraints, kollidierende Namen,
maximale Identifier, fehlende Sichtbarkeit, nicht unterstützte Features,
Wiederholbarkeit, lokales/zentral/Uninstall und die SQL_Server_Lab-Matrix für
2019, 2022 und 2025 unter Windows und Linux. Ein spezieller CU-Stand ist nur
bei einer nachgewiesen patchgebundenen Abweichung relevant.

## Entscheidungspunkt

Vor einer Implementierungsfreigabe wird der Script-only-V1-Schnitt bestätigt
oder angepasst: dieselbe Datenbank, reguläre diskbasierte Tabellen, klar
begrenzte Metadaten und eine ResultTable mit DDL-Vorschau. Erst danach werden
Signatur, Resultset-Schema, Fehlerbereich und präzise unterstützte
Spalten-/Constraint-/Indexmerkmale als konkreter Funktionsvertrag festgelegt.

## Quellen

- [Microsoft: SELECT INTO](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-into-clause-transact-sql?view=sql-server-ver17)
- [Microsoft: sys.tables](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-tables-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-044-framework-zum-kontrollierten-klonen-von-tabellenobjekten)
