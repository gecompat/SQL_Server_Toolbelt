# toolbelt_conversion.TVF_TryCastDateTime2

Öffentliche schemagebundene Inline-TVF aus toolbelt.conversion.safe-cast 1.0.0.
Der [kanonische Vertrag](../../../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
definiert Ziellexik, genaue Fehlerpriorität, Bereich und Verlustfreiheit.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Genau YYYY-MM-DDTHH:mm:ss, optional gefolgt von Punkt und 1..7 ASCII-Nachkommastellen (großes T, insgesamt 19 oder 21..27 Codeeinheiten). Kein Z, Offset, Leerzeichen, 24-Uhr-Zeit, Schaltsekunde oder Rundung; gültiger SQL-datetime2(7)-Bereich. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |
<!-- API_PARAMETERS:END -->

Genau eine Zeile: Value datetime2(7) NULL, Status varchar(16) NOT NULL,
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
FROM (VALUES(N'2024-02-29T01:02:03.1234567'),(N'2024-02-29T24:00:00'),(CONVERT(nvarchar(32),NULL))) input(TextValue)
CROSS APPLY toolbelt_conversion.TVF_TryCastDateTime2(input.TextValue,DEFAULT) converted;
```

Relationaler Ausdruck ohne rekursiven Callerhint. Begrenzt auf 4096 UTF16-
Codeeinheiten; Optimizer darf Konversionen früher auswerten, daher sind auch
abgewiesene Operanden sicher. Keine allgemeine Performance-/Parallelitätszusage.
SQL Server 2019/2022/2025 Windows/Linux sind Zielplattformen; aktuelle ausgeführte
Nachweise und offene Kontexte stehen in [Tests/README.md](../Tests/README.md).

## Voraussetzungen für den Aufruf

- Vorhandenes SELECT; datetime2(7), keine Offset-/Zeitzoneninterpretation.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#safe-cast).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TryCastDateTime2.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
