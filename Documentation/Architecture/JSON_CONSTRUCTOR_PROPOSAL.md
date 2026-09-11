# Vorschlag: JSON-Konstruktoren (`TC-2026-009`, Slice B)

## Status

Der Path-Exists-Slice von `TC-2026-009` bleibt unverändert und validiert.
Dieses Dokument bereitet die getrennten JSON-Konstruktoren vor. Es autorisiert
keine öffentlichen SQL-Objekte, keine Änderung des bestehenden Moduls und
keine JSON-Serialisierung.

## Problem

SQL Server 2019 besitzt keine variadische T-SQL-Aufrufoberfläche für eine
portable Entsprechung von `JSON_ARRAY` oder `JSON_OBJECT`. Eine Scalar-UDF
kann keine beliebige Anzahl heterogener Argumente entgegennehmen. Dynamischen
SQL-Text oder untypisierte JSON-Fragmente als Ausweichschnittstelle zu
akzeptieren, würde Escaping, Injektion und Nullsemantik unklar machen.

## Empfohlener V1-Schnitt

V1 sollte zwei getrennte In-memory-Procedure-Aufrufe mit expliziten,
typisierten Table Types verwenden:

1. **Array-Konstruktion:** positive Ordinalspalte, `ValueKind` und
   `nvarchar(max)`-Wert.
2. **Object-Konstruktion:** positive Ordinalspalte, nicht leerer Key,
   `ValueKind` und `nvarchar(max)`-Wert.

`ValueKind` unterscheidet mindestens String, Number, Boolean, JSON-`null` und
bereits validiertes JSON-Fragment. Die Values sind nicht durch SQL-
Datentypinferenz implizit: ein Textwert `"12"` und eine JSON-Zahl `12` haben
bewusst verschiedene Kind-Werte. Die späteren Type- und Procedure-Namen
bleiben vor der Funktionsbesprechung offen.

## Vertragsvorschlag

| Aspekt | Vorschlag |
|---|---|
| Reihenfolge | Einzigartige positive Ordinals; Array- und Objektmember erscheinen in dieser Reihenfolge. |
| SQL `NULL` | SQL-`NULL` in Wert oder Key ist Fehler, außer ein expliziter `ValueKind` definiert JSON-`null`. |
| Strings | Immer als JSON-String serialisieren und vollständig escapen. |
| Numbers / Boolean | Vor Einbau gegen eine festgelegte JSON-Literalgrammatik validieren; keine datenbankcollationabhängige Interpretation. |
| JSON-Fragment | Vor Einbau mit festgelegter JSON-Validierung prüfen; ungültige Fragmente sind Fehler. |
| Keys | Nicht leer, maximal festgelegte Länge und binär verglichen. Duplicate Keys sind V1-Fehler. |
| Ausgabe | `nvarchar(max)` mit kanonischer, nicht formatierter Serialisierung; keine Pretty-Print- oder Property-Reordering-Zusage. |

Caller liefern keine Propertynamen, JSON-Pfade, SQL-Ausdrücke oder Formatflags
als ausführbaren Text. Das Modul erzeugt nur den JSON-Wert und führt ihn nicht
aus. Große Werte benötigen explizite Eintrags- und Gesamtlängenlimits.

## Abgrenzung und Tests

Die V1-API ist eine Eingabeoberfläche für einzelne JSON-Werte, kein JSON-
Aggregate und kein allgemeines Transformationssystem. Gruppierte Erzeugung
bleibt `TC-2026-013`; JSON-Patch, Schema-Validierung und Abfrageausdrücke sind
eigene Kandidaten.

Tests verwenden nur synthetische Werte und prüfen Escaping, Control-
Characters, Unicode, SQL-`NULL`, JSON-`null`, alle ValueKinds, ungültige
Literale/Fragmente, Duplicate Keys, Ordinals, Grenzen, ResultTable-
Integration, Wiederholungsdeployment, Lifecycle und lokale SQL_Server_Lab-
Ziele für 2019, 2022 und 2025 unter Windows und Linux. Ein CU wird nur bei
patchgebundenem Verhalten ausgewählt.

## Entscheidungspunkt

Vor Implementierung wird der vorgeschlagene Table-Type-Schnitt bestätigt oder
geändert: getrennte Array-/Object-APIs, explizite ValueKinds, binäre Keys und
Duplicate-Key-Fehler. Danach werden Signaturen, genaue Literalgrammatik,
Limits, Fehlerbereich und Modulgrenze als konkrete Funktionen besprochen und
freigegeben.

## Quellen

- [Microsoft: JSON_OBJECT](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON_ARRAY](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-array-transact-sql?view=sql-server-ver17)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-009-json-konstruktion-und-pfadprufung-fur-sql-server-2019)
