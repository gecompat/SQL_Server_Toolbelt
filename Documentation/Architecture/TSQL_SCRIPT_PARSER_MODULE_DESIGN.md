# T-SQL Script Parser und AST-Provider (TC-2026-047 / DEC-2026-029)

## Status und Freigabe

- **Modul-ID:** `toolbelt.tsql.script-parser`
- **Schema:** `toolbelt_tsql`
- **Assembly:** `Toolbelt_Tsql_ScriptParser` / `Toolbelt.Tsql.ScriptParser.dll`
- **Kategorie:** T-SQL / Parsing / Metadata
- **Freigabestatus:** Zweck, Signatur, Fehlervertrag, Risiken und Scope wurden am 2026-09-03 mit dem Benutzer besprochen und für die Implementierung freigegeben.

## Zweck und Modulgrenze

Das Modul liefert einen deterministischen, rein lesenden In-Database-Parser für beliebige T-SQL-Statements auf Basis von Microsoft ScriptDom (.NET Framework 4.8) als SQL-CLR Table-Valued Functions (TVFs).

### Enthalten sind:
- Vollständige Zerlegung von T-SQL-Code in einen Abstract Syntax Tree (AST) als tabellarisches Rowset (`TVF_ParseScriptNodes`).
- Detaillierte skalare Knoteneigenschaften (`TVF_ParseScriptNodeProperties`) für Identifier, Literalwerte, Klausel- und Knotentypen.
- Verlustfreier Tokenstrom (`TVF_TokenizeScript`) mit exakten Offset- und Längenangaben für zielgenaues Token-Rewriting.
- Strukturierte Fehlerliste (`TVF_ParseScriptErrors`) bei Syntaxfehlern als Datenzeilen.
- Parameter zur Steuerung der T-SQL-Version (`@TSqlVersion`) und Quoting-Semantik (`@QuotedIdentifiers`).
- Sicherheits- und Ressourcenwächter (maximale Eingabelänge, maximale Rekursionstiefe).

### Nicht enthalten sind:
- Semantische Namens-, Alias- oder Spaltenauflösung (gehört in einen separaten T-SQL-Folgelayer).
- Automatische Token-Ersetzung / GUID-Rewriting (Aufrufer transformiert anhand des Tokenstroms).
- Katalogprüfungen (`OBJECT_ID`, `sys.tables`, Berechtigungen).
- Code-Analyse, Linting, Bad-Practice-Bewertung (gehört gemäß `DEC-2026-011` nach `gecompat/SQL_Server_Analyze`).
- Ausführung von generiertem oder geparstem SQL-Code.

## Öffentliche Schnittstellen (CLR-TVFs)

Alle Funktionen besitzen eine einheitliche Eingabesignatur:

```sql
toolbelt_tsql.TVF_ParseScriptNodes
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160        -- 150 (2019), 160 (2022), 170 (2025)
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152    -- Standard 2 MiB
    , @MaxNestingDepth    int = 256
)
RETURNS TABLE
(
      NodeId              int            -- 1-basierter Pre-Order-Knotenindex
    , ParentNodeId        int            -- NULL für Root-Knoten (Script)
    , Depth               int            -- 0 für Root, 1 für direkte Kinder...
    , SiblingOrdinal      int            -- Reihenfolge unter dem Parent
    , PropertyName        nvarchar(128)  -- Eigenschaftsname auf dem Parent-AST-Knoten
    , PropertyIndex       int            -- Index bei Listen-Eigenschaften (0-basiert), sonst NULL
    , NodeType            nvarchar(128)  -- ScriptDom-Knotentyp (z. B. SelectStatement, ColumnReferenceExpression)
    , StartOffset         int            -- 0-basierter Zeichenoffset im SqlText
    , StartLine           int            -- 1-basierte Zeilennummer
    , StartColumn         int            -- 1-basierte Spaltennummer
    , FragmentLength      int            -- Länge des Fragments in Zeichen
    , FirstTokenIndex     int            -- Index des ersten zugehörigen Tokens
    , LastTokenIndex      int            -- Index des letzten zugehörigen Tokens
)

toolbelt_tsql.TVF_ParseScriptNodeProperties
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
    , @MaxNestingDepth    int = 256
)
RETURNS TABLE
(
      NodeId              int            -- Verweis auf TVF_ParseScriptNodes.NodeId
    , PropertyName        nvarchar(128)  -- Eigenschaftsname (z. B. Value, QuoteType, BaseTime)
    , PropertyKind        nvarchar(32)   -- Identifier, String, Number, Boolean, Enum
    , PropertyValue       nvarchar(max)  -- Extrahierter skalarer Wert
)

toolbelt_tsql.TVF_TokenizeScript
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
    , @MaxNestingDepth    int = 256
)
RETURNS TABLE
(
      TokenIndex          int            -- 0-basierter monotoner Tokenindex
    , TokenType           nvarchar(64)   -- Identifier, Keyword, StringLiteral, Whitespace, Comment, ...
    , TokenText           nvarchar(max)  -- Originaltext des Tokens
    , StartOffset         int            -- 0-basierter Zeichenoffset im SqlText
    , StartLine           int            -- 1-basierte Zeile
    , StartColumn         int            -- 1-basierte Spalte
)

toolbelt_tsql.TVF_ParseScriptErrors
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
    , @MaxNestingDepth    int = 256
)
RETURNS TABLE
(
      ErrorOrdinal        int            -- 1-basierte Fehlernummer
    , Number              int            -- ScriptDom Parse-Fehlernummer
    , Message             nvarchar(4000) -- Englische Fehlermeldung des Parsers
    , StartOffset         int            -- Zeichenoffset des Syntaxfehlers
    , StartLine           int            -- Zeile
    , StartColumn         int            -- Spalte
)
```

## Provider-, Security- und Trust-Entscheidung

1. **CLR-Provider:** C# .NET Framework 4.8 Assembly `Toolbelt_Tsql_ScriptParser` unter Verwendung von `Microsoft.SqlServer.TransactSql.ScriptDom.dll` (v180.x, MIT-Lizenz).
2. **Permission Set:** Evaluation in Phase 0 (Spike); Ziel ist `SAFE`. Falls unveränderliche statische Felder `UNSAFE` erfordern, gilt Windows-only mit separater Autorisierung.
3. **Trust-Modell:** Exakte SHA2-512-Hashes für beide Assemblies (`Toolbelt_Tsql_ScriptParser` und `Microsoft.SqlServer.TransactSql.ScriptDom`) via `sys.sp_add_trusted_assembly`. `clr strict security` bleibt aktiv; kein `TRUSTWORTHY ON`.
4. **Kein Datenzugriff:** `DataAccessKind.None`, `SystemDataAccessKind.None`.
5. **Determinismus:** Deterministisch für identische Eingabeparameter.

## Fehler- und Ressourcenvertrag

- **Syntaxfehler im SQL-Text:** Werden nicht als Engine-Fehler geworfen, sondern als strukturierte Ergebniszeilen über `TVF_ParseScriptErrors` zurückgegeben.
- **Vertragsverletzungen:** Ungültige Parameterwerte (`@MaxInputBytes <= 0`, unbekannte `@TSqlVersion`, Überschreitung des Größenlimits) werfen deterministische CLR-Exceptions mit stabilem Fehlerpräfix `TBX_TSQLPARSE_*` (SQL-Fehler 6522).
- **Stack-Overflow-Schutz:** Ein vor- oder mitlaufender Tiefenzähler verweigert Ausdrücke mit einer Schachtelungstiefe $> \text{@MaxNestingDepth}$ geordnet mit `TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED`, um Prozessabstürze zu verhindern.

## Alternativen und Risiken

| Alternative | Bewertung |
|---|---|
| Reiner T-SQL-Parser | Verworfen. Eine vollständige T-SQL-Grammatik für 2019/2022/2025 ist in T-SQL nicht vollständig und wartbar abbildbar. |
| Reiner Tokenizer ohne AST | Verworfen. Für strukturierte AST-Navigation (z. B. Klauselzuordnung) reicht reines Token-Splitting nicht aus. |
| Stored Procedures mit Temp-Tabellen | Verworfen. TVFs ermöglichen Streaming und direkte Komposition via `CROSS APPLY`. |
| Externer Parsing-Service | Verworfen. Erfordert Netzwerk-/Prozessaufrufe; In-Database-Verarbeitung ist bevorzugt. |

## Quellen

- Microsoft SqlScriptDOM: https://github.com/microsoft/SqlScriptDOM
- NuGet-Paket: https://www.nuget.org/packages/Microsoft.SqlServer.TransactSql.ScriptDom
- Research-Inbox: `RI-2026-140`
- Toolbelt-Kandidat: `TC-2026-047`
- Architekturentscheidungen: `DEC-2026-001`, `DEC-2026-009`, `DEC-2026-011`, `DEC-2026-014`, `DEC-2026-029`
