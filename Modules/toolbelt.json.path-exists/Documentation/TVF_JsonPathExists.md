# TVF_JsonPathExists

`toolbelt_json.TVF_JsonPathExists(@Json nvarchar(max),
@Path nvarchar(max))` liefert genau eine Zeile mit
`PathExists int NULL`.

## Rückgabevertrag

| Bedingung | `PathExists` |
|---|---:|
| Pfad findet mindestens einen Wert | `1` |
| Pfad fehlt | `0` |
| JSON oder Pfad ungültig | `0` |
| `@Json` oder `@Path` ist SQL `NULL` | SQL `NULL` |

JSON `null` ist ein vorhandener Wert. Deshalb liefert beispielsweise
`{"value":null}` mit `$.value` den Wert `1`.

## Pfadvertrag

Version 1 unterstützt:

- `$` als Context Item;
- optionale Präfixe `lax` und `strict`;
- nicht quotierte ASCII-Schlüssel aus `A-Z`, `a-z`, `0-9` und `_`;
- mit JSON-Escapes quotierte Schlüssel, etwa `$."first name"` oder
  `$."key.with.dot"`;
- nullbasierte Array-Indizes wie `$[0]`;
- Array-Wildcards wie `$.items[*].id`.

Property-Namen werden unabhängig von Datenbank- oder Caller-Collation mit
`Latin1_General_100_BIN2` verglichen. `Name` und `name` sind daher
verschieden.

Nicht unterstützt werden die in SQL Server 2025 als Preview eingeführten
Array-Ranges, Indexlisten und `last`. Pfade über 4.000 UTF-16-Codeunits
liefern `0`.

`lax` und `strict` werden syntaktisch angenommen, verändern das Ergebnis
jedoch nicht: Die native Existenzprüfung wirft selbst keine fachlichen Fehler,
und der Toolbelt-Vertrag bildet diese fehlerfreie Semantik ab.

## Verwendung

```sql
DECLARE @Input TABLE
(
      Id int NOT NULL
    , Document nvarchar(max) NULL
);

INSERT @Input (Id, Document)
VALUES
    (1, N'{"payload":{"id":42}}'),
    (2, N'{"payload":null}');

SELECT source.Id, path_result.PathExists
FROM @Input AS source
OUTER APPLY toolbelt_json.TVF_JsonPathExists
            (source.Document, N'$.payload.id') AS path_result;
```

## Performance und Grenzen

Die Function ist eine Multi-statement TVF, weil beliebig tiefe Pfade und
Wildcard-Fan-out einen zustandsbehafteten Frontier benötigen. Jeder
Pfadschritt materialisiert seine aktuellen Treffer in einer Table Variable.
Die Kosten wachsen daher mit Pfadtiefe und Anzahl der Wildcard-Treffer.

Für selektive Abfragen auf großen Tabellen ist eine normalisierte Spalte,
eine persisted computed column mit einer geeigneten nativen JSON-Funktion
oder eine vorgelagerte Filterung meist günstiger. Der V1-Vertrag behauptet
keine SARGability.

## Quellen

- [Microsoft: JSON_PATH_EXISTS](https://learn.microsoft.com/en-us/sql/t-sql/functions/json-path-exists-transact-sql?view=sql-server-ver17)
- [Microsoft: JSON path expressions](https://learn.microsoft.com/en-us/sql/relational-databases/json/json-path-expressions-sql-server?view=sql-server-ver17)
- [Microsoft: OPENJSON](https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql?view=sql-server-ver17)

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#json-pfade).
