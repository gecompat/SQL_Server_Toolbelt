# Vorschlag: Kontrollierter Tabellenklon (`TC-2026-044`)

## Individuell freigegebene Welle 1: Reviewentwurf vom 2026-10-02

Der [W1-Vor-Source-Vertrag](TABLE_CLONE_WAVE1_CONTRACT.md) konkretisiert
Computed/PERSISTED, gefilterte Rowstore-Indizes und optionale Extended
Properties im bestehenden ScriptOnly-Kern. Die bestätigte Parameterposition
und sieben SESSION_OPTION-Zeilen führen zur geplanten Version 2.0.0.
Das Computed-only-Metadatengate und die eng begrenzte Extended-Property-
Batchausnahme wurden am 2026-10-02 einzeln freigegeben; der unabhängige
Vor-Source-Review ist abgeschlossen. W1 ist als 2.0.0 implementiert und teilweise validiert: Die finalen öffentlichen Adapter vom 2026-10-03 bestanden auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 lokal und zentral. Siehe [aktuellen W1-Vertrag und Scope-Nachweis](TABLE_CLONE_WAVE1_CONTRACT.md#gezielter-öffentlicher-runtime-nachweis-2026-10-03). CI am geprüften Head 76888216 bestanden; tatsächliche Minimalrechte und weitere physische Ziele bleiben offen.
Die folgenden V1- und Researchabschnitte bleiben
historisch unverändert, Welle 2 gehört nicht zu diesem Vertrag.

## Freigegebener Script-only-V1, 2026-10-01

Nach Einzelbesprechung hat der Benutzer Implementierung, Prüfung und PR-Merge
mit „ja, ich gebe das alles frei“ ausdrücklich bestätigt; kanonischer erster
Reservewellenabschnitt in `.ai/BACKLOG.md`, TC-2026-044.
`USP_ScriptTableClone` ist ausschließlich same-database Preview, keine DDL-
Ausführung oder Datenkopie. Der konkrete technische Vertrag steht im
[Objektvertrag](../../Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md).
T-SQL-Catalogkern plus Help-/Precompile-Fassade, keine SMO/CLR-Abhängigkeit.
ResultTable nutzt kanonischen Helper; vollständige Vorschau vor Mutation.
Unterstützte Typ-/Indexgrenzen und sichtbarer Unsupported-Abbruch sind dort
präzisiert; Identity optional Seed/Increment, niemals aktueller Zähler.
SHA256length-framed Constraintnamen umgehen Identifierüberlängen ohne stille
Trunkierung, voll gequotete Identifier. Metadaten benötigen datenbankweite
VIEW DEFINITION für vollständige incoming-FK-/Kollisionssicht;
Quelle strukturell stabil halten, keine spätere Driftfreiheit.
Test-DDL ausschließlich synthetisch; tatsächliche Evidenz separat im Manifest.
Keine Veröffentlichung, keine zusätzlichen Clone-/Execute-/Copy-APIs.

## Historischer Vorschlag vor Einzel-Freigabe (superseded für V1)

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
