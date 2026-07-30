# `toolbelt_string.TVF_SplitByCharacters`

## Signatur

```sql
toolbelt_string.TVF_SplitByCharacters
(
    @Input      nvarchar(max),
    @Separators nvarchar(4000),
    @KeepEmpty  bit = 1
)
```

## Resultset

| Ordinal | Spalte | Typ | Nullability |
|---:|---|---|---|
| 1 | `Value` | `nvarchar(max)` | `NULL` nur typbedingt; ausgegebene Tokens sind nicht `NULL` |
| 2 | `Ordinal` | `bigint` | nicht `NULL` |

`Ordinal` beginnt bei 1 und ist nach dem optionalen Entfernen leerer Tokens
lückenlos. Nur `ORDER BY Ordinal` garantiert die Tokenreihenfolge.

## Parametervertrag

### `@Input`

- `NULL` liefert keine Zeile.
- Leere Eingabe liefert bei `@KeepEmpty = 1` ein leeres Token, sonst keine
  Zeile.
- Whitespace, einschließlich nachfolgender Leerzeichen, bleibt erhalten.

### `@Separators`

- Jedes enthaltene UTF-16-Codeelement trennt literal.
- Wiederholte Separatorzeichen ändern das Ergebnis nicht.
- `NULL` liefert keine Zeile.
- Die leere Zeichenfolge liefert die vollständige Eingabe als ein Token.
- NUL (`U+0000`) ist ungültig und liefert keine Zeile.
- Der Vergleich erfolgt mit `Latin1_General_100_BIN2`; Groß-/Kleinschreibung
  und Akzente werden nicht gleichgesetzt.

### `@KeepEmpty`

- `1` erhält führende, aufeinanderfolgende und nachfolgende leere Tokens.
- `0` entfernt leere Tokens.
- `NULL` entspricht `1`.

Ein ausschließlich aus Whitespace bestehendes Token ist nicht leer.

## Beispiele

```sql
SELECT Value, Ordinal
FROM toolbelt_string.TVF_SplitByCharacters
(
    N'A,B;C|D',
    N',;|',
    DEFAULT
)
ORDER BY Ordinal;
```

```sql
SELECT Value, Ordinal
FROM toolbelt_string.TVF_SplitByCharacters
(
    N',A;;',
    N',;',
    0
)
ORDER BY Ordinal;
```

## Fehler- und Sicherheitsvertrag

Die Funktion wirft für Eingabewerte keine eigene Exception. Ungültige
`NULL`-/NUL-Konstellationen liefern eine leere Ergebnismenge. Eingaben werden
nicht als Regex oder SQL-Text interpretiert.

## Performance

Die Inline-TVF verwendet `toolbelt_core.TVF_GenerateSeriesBigInt` zur
Positionsbildung. Die Verarbeitung ist synchron und linear zur Anzahl der
UTF-16-Codeelemente in `@Input`; die Eingabe wird nicht künstlich auf
`nvarchar(4000)` begrenzt. Sehr große LOBs können entsprechend CPU- und
Speicherressourcen beanspruchen.

## Nicht Bestandteil von Version 1

- Separatorstrings mit mehr als einem Zeichen;
- Prioritätsregeln für überlappende Separatorstrings;
- Quote-, Escape-, CSV- oder Regex-Semantik;
- Graphemcluster als Separatoratom.

Diese Erweiterungen bleiben in `TC-2026-032` als eigener Vertrag.
