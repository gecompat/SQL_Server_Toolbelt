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
