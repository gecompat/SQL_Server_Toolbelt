# toolbelt_conversion.SVF_Base64Encode

**Typ:** Scalar-valued Function

**Status:** `implemented`

## Zweck

Codiert Binärdaten als Standard-Base64 oder als ungepaddetes Base64URL gemäß
RFC 4648.

Die SVF ist eine Convenience-API und delegiert an den kanonischen
relationalen Kern
[`TVF_Base64Encode`](./TVF_Base64Encode.md). Für Spaltenwerte und
mengenorientierte Abfragen ist die inline TVF über `APPLY` zu bevorzugen.

## Parameter und Rückgabewert

| Element | Typ | Nullable | Beschreibung |
|---|---|---:|---|
| `@Value` | `varbinary(max)` | ja | zu codierende Bytes; keine Zeichenkodierung |
| `@UrlSafe` | `bit` | nein | `0`: Standard-Base64; `1`: Base64URL ohne Padding; Default `0` |
| Rückgabewert | `varchar(max)` | ja | Base64-Text oder `NULL` |

Bei Scalar UDFs wird der Default nicht durch Weglassen des Arguments aktiviert.
Der Aufrufer verwendet `DEFAULT` oder übergibt `0`.

## Verwendung

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE, DEFAULT)
    AS StandardBase64;

SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE, 1)
    AS Base64Url;
```

Erwartete synthetische Werte: `yv7K/g==` und `yv7K_g`.

## Rechte, Dependencies und Plattformen

Die Funktion benötigt keine weiteren Toolbelt-Module und verwendet nur den
T-SQL/XML-Provider. Sie ist für SQL Server 2019, 2022 und 2025 auf Windows und
Linux vorgesehen. Ausgeführte Kombinationen stehen im Modulmanifest.

## Performance und Collation

Die Funktion verspricht kein Scalar-UDF-Inlining. Der Rückgabewert verwendet
die Default-Collation der Installationsdatenbank; das Alphabet selbst besteht
nur aus ASCII-Zeichen. Große LOBs werden vollständig synchron materialisiert.

## Einschränkungen und Teststatus

Base64 schützt weder Vertraulichkeit noch Integrität. SQL Server 2025 unter
Linux ist mit Compatibility Levels 150, 160 und 170 erfolgreich geprüft.
Physische 2019-/2022- und Windows-Läufe bleiben `not executed`.
