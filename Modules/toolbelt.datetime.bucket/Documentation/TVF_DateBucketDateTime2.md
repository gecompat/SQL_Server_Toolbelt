# toolbelt_datetime.TVF_DateBucketDateTime2

Ermittelt den Bucket-Start für `datetime2(7)`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDateTime2
     ('minute', 15, '2026-07-30T12:34:56.1234567', DEFAULT);
```

Parameter:

- `@DatePart varchar(16)`;
- `@Width int`;
- `@Value datetime2(7)`;
- `@Origin datetime2(7) = '19000101'`.

Das Resultset besteht aus `Value datetime2(7)`, `IsValid bit` und
`ValidationCode tinyint`. Werte vor Origin werden nicht Richtung null,
sondern zum früheren Bucket-Start abgerundet.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Width` | `int` | `kein Default` | Input | Positive ganzzahlige Bucketbreite. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Origin` | `datetime2(7)` | `'19000101'` | Input | Zeitlicher Referenzpunkt für die Bucket-Grenzen. |

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateBucketDateTime2.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
