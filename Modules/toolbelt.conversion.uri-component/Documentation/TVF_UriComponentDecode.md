# TVF_UriComponentDecode

`toolbelt_conversion.TVF_UriComponentDecode(@Value nvarchar(max))` liefert `DecodedValue`, `IsValid` und `ValidationCode`. Codes: `0` gültig, `10` Nicht-ASCII-Input, `11` ungültiges Prozent-Triplet, `12` ungültige UTF-8-Sequenz, `13` dekodiertes NUL. `NULL` bleibt in allen drei Spalten `NULL`.

Die Funktion führt genau eine Runde aus: `%252F` wird zu `%2F`, nicht zu `/`.

## Ergebnis verstehen

Das Beispiel unten erwartet `DecodedValue=N'a b/ä'`, `IsValid=1` und
`ValidationCode=0`. Dies ist eine synthetische Erwartung aus dem Vertrag.
Ein Pluszeichen bleibt ein Pluszeichen; die Funktion ist kein Decoder für
Form-URL-Encoding. Prüfe vor Verwendung des Werts `IsValid`.

Bei mehr als 65536 UTF-16-Eingabebytes meldet die Funktion
`DecodedValue=NULL`, `IsValid=0`, `ValidationCode=14`.
[TVF_UriComponentDecodeStatus](TVF_UriComponentDecodeStatus.md) ergänzt die
eindeutigen Statuswerte `OK`, `SQL_NULL`, `INVALID` und `LIMIT`.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecode(N'a%20b%2F%C3%A4');
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#uri).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_UriComponentDecode.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
