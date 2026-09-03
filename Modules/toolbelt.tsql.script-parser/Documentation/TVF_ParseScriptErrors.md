# `toolbelt_tsql.TVF_ParseScriptErrors`

## Zweck

Liefert die vom ScriptDom-Parser erkannten Syntaxfehler eines T-SQL-Skripts als strukturierte Zeilen mit Fehlercode, Position und Meldung.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptErrors
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
| `ErrorOrdinal` | `int` | 1-basierte fortlaufende Fehlernummer |
| `Number` | `int` | ScriptDom Parse-Fehlernummer |
| `Message` | `nvarchar(4000)` | Englische Fehlermeldung des Parsers |
| `StartOffset` | `int` | 0-basierter Zeichenoffset des Fehlers |
| `StartLine` | `int` | 1-basierte Startzeile |
| `StartColumn` | `int` | 1-basierte Startspalte |

Bei fehlerfreiem SQL-Text gibt die Funktion 0 Zeilen zurück.
