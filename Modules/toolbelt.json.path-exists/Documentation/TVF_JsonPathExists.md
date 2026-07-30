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
