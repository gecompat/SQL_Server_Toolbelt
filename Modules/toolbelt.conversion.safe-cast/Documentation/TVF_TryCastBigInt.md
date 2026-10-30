# toolbelt_conversion.TVF_TryCastBigInt

Öffentliche schemagebundene Inline-TVF aus toolbelt.conversion.safe-cast 1.0.0.
Der [kanonische Vertrag](../../../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
definiert Ziellexik, genaue Fehlerpriorität, Bereich und Verlustfreiheit.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit mindestens einer Ziffer 0..9 und optional einem führenden + oder -. Führende Nullen/negative Null sind zulässig. Kein Trim, kein Unicode-Ziffernersatz, Dezimalpunkt, Exponent oder Tausendertrennzeichen. Zielbereich -9223372036854775808..9223372036854775807. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |
<!-- API_PARAMETERS:END -->

Genau eine Zeile: Value bigint NULL, Status varchar(16) NOT NULL,
ErrorCode varchar(32) NULL. Textdiagnosen Latin1_General_100_BIN2.
Nur OK enthält einen Wert; SQL_NULL enthält keinen ErrorCode.
SQL_NULL → INVALID_ARGUMENT → LIMIT → EMPTY → INVALID_FORMAT →
OUT_OF_RANGE → LOSSY → OK. LOSSY bezeichnet ausschließlich Decimal-Skalenverlust.

Keine Eingabewiederholung, Localeinterpretation, stille Rundung oder
Trunkierung. UTF16-Bytebudget 1..8192 einschließlich trailing spaces; kein Trim.
Keine Seiteneffekte oder eigenen Transaktionen. Vorhandenes SELECT erforderlich;
CrossDB benötigt passende bestehende Rechte. Kein CLR und keine Dependencies.

```sql
SELECT input.TextValue,converted.Value,converted.Status,converted.ErrorCode
FROM (VALUES(N'0'),(N''),(CONVERT(nvarchar(16),NULL))) input(TextValue)
CROSS APPLY toolbelt_conversion.TVF_TryCastBigInt(input.TextValue,DEFAULT) converted;
```

Relationaler Ausdruck ohne rekursiven Callerhint. Begrenzt auf 4096 UTF16-
Codeeinheiten; Optimizer darf Konversionen früher auswerten, daher sind auch
abgewiesene Operanden sicher. Keine allgemeine Performance-/Parallelitätszusage.
SQL Server 2019/2022/2025 Windows/Linux sind Zielplattformen; aktuelle ausgeführte
Nachweise und offene Kontexte stehen in [Tests/README.md](../Tests/README.md).

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT; genau eine Zeile, keine Seiteneffekte.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#safe-cast).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TryCastBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
