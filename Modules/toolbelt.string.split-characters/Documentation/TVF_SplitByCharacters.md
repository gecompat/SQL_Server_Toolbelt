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

Der begrenzte Statuskern normalisiert höchstens 64 unterschiedliche
Separatorcodeeinheiten über `toolbelt_core.TVF_GenerateSeriesBigInt`.
Danach validiert er Spans vollständig vor der ersten Tokenausgabe: höchstens
64 KiB UTF-16-Input und 10000 Tokens. Die alte Inlineoberfläche ist ein Wrapper
über dem MSTVF-Kern. Frühere Inline-/Plan-/Parallelitätsannahmen gelten nicht
für den Statuskern; Heap und konstante Laufzeit sind nicht zugesagt.

## Nicht Bestandteil von Version 1

- Separatorstrings mit mehr als einem Zeichen;
- Prioritätsregeln für überlappende Separatorstrings;
- Quote-, Escape-, CSV- oder Regex-Semantik;
- Graphemcluster als Separatoratom.

Diese Erweiterungen bleiben in `TC-2026-032` als eigener Vertrag.

## Aktueller Sicherheitsvertrag

SC-020: Neuer Statuskern prüft64 KiB UTF-16-Input,64 unterschiedliche Separatorcodeeinheiten und10000 Tokens vor Ausgabe. Duplikate zählen einmal. LIMIT enthält keine Tokenpräfixe. Alte TVF filtert OK und liefert bei Überschreitung keine Zeilen. EMPTY/SQL_NULL/INVALID haben eigene Kontrollzeilen im Statuskern; keine uneingeschränkte Inline-/Parallelitätszusage.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
<!-- API_PARAMETERS:END -->
