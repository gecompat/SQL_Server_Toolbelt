# toolbelt_datetime.TVF_DateBucketDateTimeOffset

Kanonischer Bucket-Kern für `datetimeoffset(7)`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
     (
           'hour'
         , 6
         , '2026-07-30T12:34:56.1234567+02:00'
         , '2026-01-01T00:00:00.0000000+02:00'
     );
```

Value und Origin besitzen denselben SQL-Typ. Der Default-Origin ist
`1900-01-01 00:00:00 +00:00`. Der resultierende Offset folgt dem
Origin-basierten Rechenpfad; die native Paritätsmatrix prüft auch
unterschiedliche Offsets.

Das Resultset enthält `Value datetimeoffset(7)`, `IsValid bit` und
`ValidationCode tinyint`.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).
