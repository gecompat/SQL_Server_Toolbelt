# `toolbelt_tsql.TVF_TokenizeScript`

## Zweck

Zerlegt T-SQL-Code in einen lückenlosen, verlustfreien Strom lexikalischer Tokens inklusive Bezeichnern, Schlüsselwörtern, Kommentaren, Literalen und Whitespace.

## Signatur

```sql
toolbelt_tsql.TVF_TokenizeScript
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160        -- NULL = 160; exakt 80,90,100,110,120,130,140,150,160,170
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152    -- NULL = 2097152; explizit 1..2097152
    , @MaxNestingDepth    int = 100        -- NULL = 100; explizit 1..256
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

## Gemeinsamer Vertrag 2.0.0

NULL-Text liefert vor jeder anderen Parameterprüfung null Zeilen. Für nicht NULL-Text gelten gemeinsame strikte Parameterprüfung, vorgeschalteter Rohtextwächter und atomare begrenzte Ausgabe gemäß [Hardening-Vertrag](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). UTF-16-Codeeinheiten bestimmen Eingabegröße und Offsets; NULL bei QuotedIdentifiers bedeutet true. Unbekannte Parser-Versionen werden zurückgewiesen.

Tokenize ruft ausschließlich den Lexer auf. Lexikalische Fehler ergeben null Zeilen; grammatikfehlerhafter, lexikalisch gültiger Text kann vollständige Tokens liefern. Die Tiefenprüfung betrifft den Rohtextwächter, keinen AST. Trivia und EOF zählen zur Grenze von 8.192 Tokens.

Alle Ausgaben unterliegen außerdem 16.777.216 verrechneten Bytes pro Aufruf und den bestehenden Spaltenbreiten. CLR-Grenzfehler verwenden die stabilen Präfixe des Hardening-Vertrags, regulär im SQL-Fehler-6522-Wrapper. Eingereichter SQL-Text wird nicht in Grenzmeldungen aufgenommen. Windows-only und UNSAFE bleiben unverändert; Parsing erteilt keine sichere Rewriting-Freigabe.
