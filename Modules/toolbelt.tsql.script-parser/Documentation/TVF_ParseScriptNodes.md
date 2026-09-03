# `toolbelt_tsql.TVF_ParseScriptNodes`

## Zweck

Zerlegt T-SQL-Code in einen hierarchischen Abstract Syntax Tree (AST) auf Basis von Microsoft ScriptDom und gibt die AST-Knoten als tabellarisches Rowset in Pre-Order-Reihenfolge zurück.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptNodes
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL       -- NULL = automatischer Fallback (Standard 160 / SQL 2022); 80..170
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL       -- NULL = unbegrenzt
    , @MaxNestingDepth    int = 100        -- NULL = Standard 100
)
```

## Resultset

| Spalte | Typ | Bedeutung |
|---|---|---|
| `NodeId` | `int` | 1-basierter, monoton steigender Pre-Order-Knotenindex |
| `ParentNodeId` | `int NULL` | `NodeId` des übergeordneten Knotens (`NULL` für Root) |
| `Depth` | `int` | Schachtelungstiefe (0 für Root, 1 für direkte Kinder) |
| `SiblingOrdinal` | `int` | 0-basierte Position unter Geschwisterknoten |
| `PropertyName` | `nvarchar(128) NULL` | Name der Eigenschaft auf dem übergeordneten Knoten |
| `PropertyIndex` | `int NULL` | 0-basierter Index bei Listeneigenschaften, sonst `NULL` |
| `NodeType` | `nvarchar(128)` | ScriptDom-Knotentyp (z. B. `SelectStatement`, `ColumnReferenceExpression`) |
| `StartOffset` | `int` | 0-basierter Zeichenoffset im Quelltext |
| `StartLine` | `int` | 1-basierte Startzeile |
| `StartColumn` | `int` | 1-basierte Startspalte |
| `FragmentLength` | `int` | Länge des Code-Fragments in Zeichen |
| `FirstTokenIndex` | `int` | Index des ersten zugehörigen Tokens in `TVF_TokenizeScript` |
| `LastTokenIndex` | `int` | Index des letzten zugehörigen Tokens in `TVF_TokenizeScript` |

## Verhalten bei Fehlern und Grenzwerten

- Syntaxfehler im Quellcode führen nicht zum Abbruch, sondern liefern den partiellen Syntaxbaum; Fehler werden über `TVF_ParseScriptErrors` ausgewiesen.
- Überschreitung von `@MaxInputBytes` oder `@MaxNestingDepth` löst eine CLR-Ausnahme mit Präfix `TBX_TSQLPARSE_*` aus.
