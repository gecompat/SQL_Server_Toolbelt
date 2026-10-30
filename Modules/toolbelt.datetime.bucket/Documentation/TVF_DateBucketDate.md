# toolbelt_datetime.TVF_DateBucketDate

Ermittelt den Bucket-Start für `date`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDate
     ('week', 2, '2026-07-30', DEFAULT);
```

Parameter sind `@DatePart varchar(16)`, `@Width int`, `@Value date` und
`@Origin date = '19000101'`. `DEFAULT` aktiviert den dokumentierten
Default-Origin; ein explizites `NULL` wird weitergegeben.

Das Resultset enthält `Value date`, `IsValid bit` und
`ValidationCode tinyint`. Zeit-Dateparts sind mit Code `12` ungültig.
Unbekannte Dateparts verwenden Code `10`, nicht positive Widths Code `11`.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Unterstützte Zeiteinheit gemäß Objektvertrag; Beispiele verwenden day. |
| `@Width` | `int` | `kein Default` | Input | Positive ganzzahlige Bucketbreite. |
| `@Value` | `date` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Origin` | `date` | `'19000101'` | Input | Zeitlicher Referenzpunkt für die Bucket-Grenzen. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateBucketDate.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
