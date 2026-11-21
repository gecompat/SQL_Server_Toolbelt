# `toolbelt_tsql.TVF_ParseScriptNodeProperties`

## Zweck

Liest alle skalaren Eigenschaften (z. B. Bezeichnernamen, Literalwerte, Enums, Boolesche Flags) der über `TVF_ParseScriptNodes` erzeugten AST-Knoten als Key-Value-Paare aus.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptNodeProperties
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
| `NodeId` | `int` | Verweis auf die `NodeId` in `TVF_ParseScriptNodes` |
| `PropertyName` | `nvarchar(128)` | Name der skalaren Eigenschaft (z. B. `Value`, `QuoteType`, `BaseTime`) |
| `PropertyKind` | `nvarchar(32)` | Eigenschaftstyp: `String`, `Number`, `Boolean`, `Enum` oder `Value` |
| `PropertyValue` | `nvarchar(max) NULL` | Extrahierter skalarer Wert als Textdarstellung |

## Gemeinsamer Vertrag 2.0.0

NULL-Text liefert vor jeder anderen Parameterprüfung null Zeilen. Für nicht NULL-Text gelten gemeinsame strikte Parameterprüfung, vorgeschalteter Rohtextwächter und atomare begrenzte Ausgabe gemäß [Hardening-Vertrag](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). UTF-16-Codeeinheiten bestimmen Eingabegröße und Offsets; NULL bei QuotedIdentifiers bedeutet true. Unbekannte Parser-Versionen werden zurückgewiesen.

Nur erfolgreich geparste ASTs liefern Eigenschaften, maximal 131.072 Zeilen. NodeIds stimmen bei gleichen Argumenten mit Nodes überein; Reihenfolge und skalare Formatierung sind kulturunabhängig. Ein Grenzfehler liefert keine Teilmenge.

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

Der [quellgeprüfte Vertrag](../../../Metadata/UsageSkills/toolbelt_tsql/TVF_ParseScriptNodeProperties.md) enthält sämtliche Parameter, technische Defaults und NULL-Fallbacks, die konkreten Ergebnisspalten, Rechte und Limits. Der identische Skill steht als Kommentar in der kanonischen DDL. Parserdialekt, Hostversion, Datenbank-CL, konservativer Rohtextwächter und AST-Tiefe sind getrennte Begriffe. Native Qualifikation bleibt von diesem Quellnachweis getrennt.
