# `toolbelt_tsql.TVF_ParseScriptNodeProperties`

## Zweck

Liest alle skalaren Eigenschaften (z. B. Bezeichnernamen, Literalwerte, Enums, Boolesche Flags) der über `TVF_ParseScriptNodes` erzeugten AST-Knoten als Key-Value-Paare aus.

## Signatur

```sql
toolbelt_tsql.TVF_ParseScriptNodeProperties
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
| `NodeId` | `int` | Verweis auf die `NodeId` in `TVF_ParseScriptNodes` |
| `PropertyName` | `nvarchar(128)` | Name der skalaren Eigenschaft (z. B. `Value`, `QuoteType`, `BaseTime`) |
| `PropertyKind` | `nvarchar(32)` | Eigenschaftstyp: `Identifier`, `String`, `Number`, `Boolean`, `Enum` |
| `PropertyValue` | `nvarchar(max) NULL` | Extrahierter skalarer Wert als Textdarstellung |
