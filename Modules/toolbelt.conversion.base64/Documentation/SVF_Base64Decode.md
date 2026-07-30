# toolbelt_conversion.SVF_Base64Decode

**Typ:** Scalar-valued Function

**Status:** `implemented`

## Zweck

Decodiert Standard-Base64 und Base64URL in Binärdaten.

Die SVF ist eine Convenience-API und delegiert an
[`TVF_Base64Decode`](./TVF_Base64Decode.md). Für Spaltenwerte und
mengenorientierte Abfragen ist die inline TVF über `APPLY` zu bevorzugen.

## Parameter und Rückgabewert

| Element | Typ | Nullable | Beschreibung |
|---|---|---:|---|
| `@Value` | `varchar(max)` | ja | Base64- oder Base64URL-Text |
| Rückgabewert | `varbinary(max)` | ja | decodierte Bytes oder `NULL` |

## Akzeptierte Syntax

- RFC-4648-Standardalphabet und Base64URL-Alphabet;
- vorhandenes oder fehlendes Padding;
- Space, Tab, CR und LF an beliebigen Positionen.

Andere Whitespace-Zeichen werden nicht entfernt. Alphabet, Längenrest,
Paddingposition und Paddinganzahl werden vor dem XML-Decode geprüft.
Strukturelle Fehler erzeugen einen unveränderten SQL-Engine-
Konvertierungsfehler mit festem synthetischem Sentinel; die Eingabe wird nicht
in den Sentinel übernommen. Providerfehler werden ebenfalls nicht in eine
Toolbelt-Fehlernummer umgeschrieben.

## Verwendung

```sql
SELECT toolbelt_conversion.SVF_Base64Decode('yv7K/g==') AS StandardValue;
SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g') AS UrlSafeValue;
```

Beide synthetischen Beispiele ergeben `0xCAFECAFE`.

## Rechte, Dependencies und Plattformen

Die Funktion benötigt keine weiteren Toolbelt-Module und verwendet nur den
T-SQL/XML-Provider. Sie ist für SQL Server 2019, 2022 und 2025 auf Windows und
Linux vorgesehen. Ausgeführte Kombinationen stehen im Modulmanifest.

## Performance, Sicherheit und Collation

Die Funktion verspricht kein Scalar-UDF-Inlining und materialisiert große LOBs
synchron. Decodierte Werte sind untrusted binary data. Die Funktion führt die
Bytes nicht aus, prüft aber weder Dateityp noch Inhalt, Vertraulichkeit oder
Integrität.

## Einschränkungen und Teststatus

Die Fehlernummern des XML-/Engine-Providers unterscheiden sich von der nativen
SQL-Server-2025-Funktion. Der Vertrag verspricht semantische Ablehnung, keine
Imitation nativer Fehlernummern. SQL Server 2025 unter Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich geprüft. Physische
2019-/2022- und Windows-Läufe bleiben `not executed`.
