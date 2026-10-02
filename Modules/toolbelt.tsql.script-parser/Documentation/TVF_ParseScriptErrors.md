# `toolbelt_tsql.TVF_ParseScriptErrors`

## Zweck

Liefert die vom ScriptDom-Parser erkannten Syntaxfehler eines T-SQL-Skripts als strukturierte Zeilen mit Fehlercode, Position und Meldung.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptErrors
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
| `ErrorOrdinal` | `int` | 1-basierte fortlaufende Fehlernummer |
| `Number` | `int` | ScriptDom Parse-Fehlernummer |
| `Message` | `nvarchar(4000)` | Englische Fehlermeldung des Parsers |
| `StartOffset` | `int` | 0-basierter Zeichenoffset des Fehlers |
| `StartLine` | `int` | 1-basierte Startzeile |
| `StartColumn` | `int` | 1-basierte Startspalte |

Bei fehlerfreiem SQL-Text gibt die Funktion 0 Zeilen zurück.

## Gemeinsamer Vertrag 2.0.0

NULL-Text liefert vor jeder anderen Parameterprüfung null Zeilen. Für nicht NULL-Text gelten gemeinsame strikte Parameterprüfung, vorgeschalteter Rohtextwächter und atomare begrenzte Ausgabe gemäß [Hardening-Vertrag](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). UTF-16-Codeeinheiten bestimmen Eingabegröße und Offsets; NULL bei QuotedIdentifiers bedeutet true. Unbekannte Parser-Versionen werden zurückgewiesen.

Lexikalische und Syntaxdiagnosen erscheinen als Datenzeilen, höchstens 256; Meldungen werden nicht gekürzt. Bei fehlerfreiem Text wird vor der leeren Ausgabe die AST-Tiefe geprüft. Ein partieller AST wird nicht traversiert.

Alle Ausgaben unterliegen außerdem 16.777.216 verrechneten Bytes pro Aufruf und den bestehenden Spaltenbreiten. CLR-Grenzfehler verwenden die stabilen Präfixe des Hardening-Vertrags, regulär im SQL-Fehler-6522-Wrapper. Eingereichter SQL-Text wird nicht in Grenzmeldungen aufgenommen. Windows-only und UNSAFE bleiben unverändert; Parsing erteilt keine sichere Rewriting-Freigabe.
