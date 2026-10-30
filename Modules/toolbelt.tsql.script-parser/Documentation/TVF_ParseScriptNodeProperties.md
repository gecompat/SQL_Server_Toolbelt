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
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#sql-parser).
