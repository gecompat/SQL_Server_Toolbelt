# `toolbelt_tsql.TVF_TokenizeScript`

## Zweck

Zerlegt T-SQL-Code in einen lückenlosen, verlustfreien Strom lexikalischer Tokens inklusive Bezeichnern, Schlüsselwörtern, Kommentaren, Literalen und Whitespace.

## Signatur

```sql
toolbelt_tsql.TVF_TokenizeScript
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL       -- NULL = automatischer Fallback (Standard 160); 80..170
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL       -- NULL = unbegrenzt
    , @MaxNestingDepth    int = 100        -- NULL = Standard 100
)
```

## Resultset

| Spalte | Typ | Bedeutung |
|---|---|---|
| `TokenIndex` | `int` | 0-basierter monotoner Tokenindex |
| `TokenType` | `nvarchar(64)` | Lexikalischer Tokentyp (z. B. `Identifier`, `Select`, `Whitespace`, `SingleLineComment`) |
| `TokenText` | `nvarchar(max)` | Originaltext des Tokens |
| `StartOffset` | `int` | 0-basierter Zeichenoffset im Quelltext |
| `StartLine` | `int` | 1-basierte Startzeile |
| `StartColumn` | `int` | 1-basierte Startspalte |
