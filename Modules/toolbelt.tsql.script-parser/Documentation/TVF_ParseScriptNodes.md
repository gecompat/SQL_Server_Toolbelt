# `toolbelt_tsql.TVF_ParseScriptNodes`

## Zweck

Zerlegt T-SQL-Code in einen hierarchischen Abstract Syntax Tree (AST) auf Basis von Microsoft ScriptDom und gibt die AST-Knoten als tabellarisches Rowset in Pre-Order-Reihenfolge zurück.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptNodes
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

- Lexikalische oder Syntaxfehler liefern null AST-Zeilen; es wird kein partieller Syntaxbaum ausgegeben. Diagnosen stehen in `TVF_ParseScriptErrors`.
- Überschreitung von `@MaxInputBytes` oder `@MaxNestingDepth` löst eine CLR-Ausnahme mit Präfix `TBX_TSQLPARSE_*` aus.

## Gemeinsamer Vertrag 2.0.0

NULL-Text liefert vor jeder anderen Parameterprüfung null Zeilen. Für nicht NULL-Text gelten gemeinsame strikte Parameterprüfung, vorgeschalteter Rohtextwächter und atomare begrenzte Ausgabe gemäß [Hardening-Vertrag](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). UTF-16-Codeeinheiten bestimmen Eingabegröße und Offsets; NULL bei QuotedIdentifiers bedeutet true. Unbekannte Parser-Versionen werden zurückgewiesen.

Nur erfolgreich geparste ASTs werden iterativ traversiert. Wurzel ist Tiefe 0; maximal 32.768 Knoten. Nodes und Properties verwenden bei gleichen Argumenten dieselbe deterministische Traversierung; NodeIds sind keine dauerhaften IDs über Dependency-Versionen.

Alle Ausgaben unterliegen außerdem 16.777.216 verrechneten Bytes pro Aufruf und den bestehenden Spaltenbreiten. CLR-Grenzfehler verwenden die stabilen Präfixe des Hardening-Vertrags, regulär im SQL-Fehler-6522-Wrapper. Eingereichter SQL-Text wird nicht in Grenzmeldungen aufgenommen. Windows-only und UNSAFE bleiben unverändert; Parsing erteilt keine sichere Rewriting-Freigabe.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
| `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
| `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#sql-parser).

## Vollständiger Usage-Skill

Der [quellgeprüfte Vertrag](../../../Metadata/UsageSkills/toolbelt_tsql/TVF_ParseScriptNodes.md) enthält sämtliche Parameter, technische Defaults und NULL-Fallbacks, die konkreten Ergebnisspalten, Rechte und Limits. Der identische Skill steht als Kommentar in der kanonischen DDL. Parserdialekt, Hostversion, Datenbank-CL, konservativer Rohtextwächter und AST-Tiefe sind getrennte Begriffe. Native Qualifikation bleibt von diesem Quellnachweis getrennt.
