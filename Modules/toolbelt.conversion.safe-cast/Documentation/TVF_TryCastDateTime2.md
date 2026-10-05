# toolbelt_conversion.TVF_TryCastDateTime2

Öffentliche schemagebundene Inline-TVF aus toolbelt.conversion.safe-cast 1.0.0.
Der [kanonische Vertrag](../../../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
definiert Ziellexik, genaue Fehlerpriorität, Bereich und Verlustfreiheit.

| Parameter | Typ | Default |
|---|---|---|
| Text | nvarchar(max) | keiner |
| MaxInputBytes | int | 8192 |

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
