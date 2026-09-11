# Vorschlag: JSON-Aggregate (`TC-2026-013`)

## Status

`TC-2026-013` bleibt Research. Dieses Dokument bereitet die spätere
funktionsbezogene Besprechung vor. Es autorisiert weder ein Modul noch ein
öffentliches SQL-Objekt.

## Ausgangslage

SQL Server 2019 und 2022 besitzen keine nativen JSON-Aggregate. Die aktuelle
Microsoft-Dokumentation führt `JSON_ARRAYAGG` und `JSON_OBJECTAGG` für SQL
Server 2025 weiterhin als Preview. Ein Toolbelt-Modul darf sich deshalb weder
auf diese Funktionen stützen noch ihre Preview-Semantik als stabile
Versionszusage übernehmen.

Der vorhandene Path-Exists-Slice aus `TC-2026-009` ist kein gemeinsamer
Konstruktions- oder Escaping-Kern. Ein Aggregat muss seine JSON-Werte deshalb
eigenständig, deterministisch und ohne eine zweite, nicht getestete
Konstruktionslogik verarbeiten.

## Offener Nutzen und empfohlene Grenze

Der gewünschte Nutzen ist die gruppierte Erzeugung von JSON-Arrays und
JSON-Objekten für Abfragen auf SQL Server 2019, 2022 und 2025. Dafür müssen
Reihenfolge, SQL-`NULL`, JSON-`null`, Escape-Verhalten, Objektkeys und
Rückgabetyp öffentlich festgelegt werden.

Eine portable V1 sollte nur zwei getrennte Operationen anbieten:

- ein Array-Aggregat über bereits als JSON-Wert klassifizierte Eingaben;
- ein Object-Aggregat über Key-Value-Paare mit expliziter Duplicate-Key-Regel.

Beliebige Werte stillschweigend als JSON zu interpretieren, SQL-Text als
ausführbare Abfrage entgegenzunehmen, automatische Typinferenz und ein
allgemeines JSON-Transformationssystem gehören nicht zu diesem Schnitt.

## Technologieentscheidung

Für eine in `GROUP BY` verwendbare, allgemeine Aggregatoberfläche gibt es auf
SQL Server 2019 und 2022 keine rein relationale T-SQL-Aufrufoberfläche. Eine
Stored Procedure oder TVF kann keine beliebige Eingaberelation eines äußeren
Abfrageplans als Aggregat aufnehmen. `FOR JSON` bleibt für konkrete
Abfrageformungen sinnvoll, ist jedoch kein wiederverwendbares Aggregatobjekt.

Damit bleiben für einen späteren Toolbeltvertrag diese Alternativen:

| Alternative | Bewertung |
|---|---|
| Kein Backport; konkrete Abfragen verwenden `FOR JSON` | Kleinster Scope, aber keine allgemeine Aggregate-API. |
| SQL-CLR User-defined Aggregate | Erfüllt den gruppierten Aufrufvertrag auf allen Zielversionen, benötigt aber einen eigenen Assembly-, Trust-, Berechtigungs-, Serialisierungs- und Naming-Vertrag. |
| SQL Server 2025 `JSON_ARRAYAGG` / `JSON_OBJECTAGG` | Ausgeschlossen, solange Microsoft die Funktionen als Preview führt; außerdem keine 2019-/2022-Abdeckung. |
| `STRING_AGG`-basierter T-SQL-Wrapper | Kein allgemeines Aggregat und bei JSON-Werten, Reihenfolge und Escaping nur dann tragfähig, wenn jede konkrete Abfrage ihren eigenen Vertragsanteil übernimmt. |

Die Empfehlung ist daher, vor jeder Implementierung zwischen einem explizit
freigegebenen SQL-CLR-Aggregatvertrag und keinem portablen Backport zu wählen.
Ein Modulname, Aggregattyp und öffentliche Objektnamen bleiben bis zu dieser
Entscheidung offen.

## Vertragsfragen für einen SQL-CLR-Slice

Falls der CLR-Weg ausgewählt wird, muss die Funktionsbesprechung mindestens
diese Punkte verbindlich entscheiden:

| Frage | Warum sie öffentlich ist |
|---|---|
| Eingabe ist JSON-Text, SQL-Skalar oder ein typisiertes Paar | Bestimmt Validierung, Escaping und die Bedeutung von SQL-`NULL`. |
| Reihenfolge | Ohne explizite Vorsortierung ist Aggregatreihenfolge nicht garantiert; die API darf keine zufällige Ordnung versprechen. |
| `NULL`-Regel | `ABSENT ON NULL`, JSON-`null` und ein Fehler haben unterschiedliche Ergebnisse. |
| Duplicate Keys | Ein Object-Aggregat braucht eine feste Regel: Fehler, erster oder letzter Key gewinnt, oder Mehrfacheinträge bleiben sichtbar. |
| Rückgabe und Größenlimit | `nvarchar(max)`, maximale serialisierte Zustandsgröße und Fehlerverhalten beeinflussen Speicher und Compatibility. |
| Security und Deployment | `SAFE`/Assembly-Policy, Berechtigungen, Signierung sowie Windows-/Linux-Deployment müssen vor dem ersten Objekt feststehen. |

Die späteren Tests müssen Null- und Fehlersemantik, deterministische
Reihenfolge nach expliziter Sortierung, Escape- und Unicode-Fälle, große
Gruppen, parallele Gruppen, Duplicate Keys, Wiederholungsdeployment,
Kollision, Lifecycle und Uninstall abdecken. Die Runtime-Matrix umfasst die
lokalen SQL_Server_Lab-Ziele für SQL Server 2019, 2022 und 2025 unter Windows
und Linux. Ein spezifischer CU-Stand ist nur erforderlich, wenn ein Test an
einen Patch gebunden ist.

## Entscheidungspunkt

Vor einer Implementierungswelle benötigt `TC-2026-013` eine ausdrückliche
Entscheidung: Soll ein portabler SQL-CLR-Aggregatvertrag mit den oben offenen
Semantik- und Deploymentfragen ausgearbeitet werden, oder soll der Toolbelt
keinen JSON-Aggregat-Backport anbieten? Erst danach können Zweck, öffentlicher
Vertrag, Alternativen, Risiken und Scope einer konkreten Funktion besprochen
und freigegeben werden.

## Quellen

- [Microsoft: JSON_ARRAYAGG](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-arrayagg-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON_OBJECTAGG](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-objectagg-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON data in SQL Server](https://learn.microsoft.com/en-us/sql/relational-databases/json/json-data-sql-server?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-013-json-aggregate-fur-sql-server-20192022)
