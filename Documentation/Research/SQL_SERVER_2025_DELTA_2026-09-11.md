# SQL Server 2025: Delta-Research

## Status

| Feld | Wert |
|---|---|
| Zweck | Deduplizierung möglicher SQL-Server-2025-Funktionslücken gegen den Toolbelt-Backlog |
| Prüfdatum | 2026-09-11 |
| Implementierungsfreigabe | Keine |
| Ergebnis | Kein neuer Implementierungskandidat wird aus diesem Delta ohne eigene Vertragsbesprechung abgeleitet. |

## Ergebnis je Funktion

| Funktion | Aktueller Microsoft-Dokumentationsstand | Toolbelt-Folge |
|---|---|---|
| `UNISTR` | SQL Server 2025; Unicode-Escapes, anpassbares Escape-Zeichen und UTF-8-Collationgrenzen für `char`/`varchar`. | Potenzieller eigener, portabler Unicode-Parser-Slice. Er wird nicht mit String-Split oder JSON-Escaping vermischt; Bedarf und Fehlervertrag sind noch offen. |
| `PRODUCT` | SQL Server 2025; numerisches Aggregate, `DISTINCT` und Window-Form, mit typabhängigen Rückgaben. | Kein Kandidat: ein 2019-/2022-Backport benötigt einen eigenen Aggregat-/CLR-Vertrag und darf nicht aus der nativen Form abgeleitet werden. |
| `DATEADD` mit `bigint` | Die aktuelle Seite beschreibt sowohl `int`- als auch `bigint`-Varianten, enthält aber weiterhin beide Grenzfallabschnitte. | Kein Kandidat: Vor einer Portabilitätsaussage ist ein gezielter SQL-Server-2025-Runtime-Spike nötig. Ein Wrapper ohne klaren Nutzen würde lediglich `DATEADD` duplizieren. |
| Vector-Scalar-Funktionen | `VECTOR_DISTANCE`, `VECTOR_NORM`, `VECTOR_NORMALIZE` und `VECTORPROPERTY` werden für SQL Server 2025 dokumentiert; `VECTOR_SEARCH` bleibt als Preview markiert. | Kein Kandidat: Vektortyp und 2019-/2022-Provider fehlen. Vector Search und Index bleiben außerhalb der Welle. |

## Folge

Die Research-Welle ist abgeschlossen. `UNISTR` kann bei künftigem konkretem
Interoperabilitätsbedarf als eigener Kandidat besprochen werden. `PRODUCT`,
`DATEADD bigint` und Vector-Funktionen bleiben ohne belegte portable Lücke
außerhalb der Implementierungsqueue. JSON-Aggregate und Fuzzy Matching bleiben
von dieser Delta-Bewertung unberührt und weiterhin nach ihren bestehenden
Preview-/Providergrenzen zurückgestellt.

## Quellen

- [Microsoft: UNISTR](https://learn.microsoft.com/en-us/sql/t-sql/functions/unistr-transact-sql?view=sql-server-ver17)
- [Microsoft: PRODUCT](https://learn.microsoft.com/en-us/sql/t-sql/functions/product-aggregate-transact-sql?view=sql-server-ver17)
- [Microsoft: DATEADD](https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver17)
- [Microsoft: Vector functions](https://learn.microsoft.com/en-us/sql/t-sql/functions/vector-functions-transact-sql?view=sql-server-ver17)
