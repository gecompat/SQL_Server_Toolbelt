# toolbelt.datetime.bucket

Portabler, typstabiler Teilvertrag von `DATE_BUCKET` für SQL Server 2019, 2022
und 2025.

## Objekte

| Objekt | Typ | Vertrag |
|---|---|---|
| `toolbelt_datetime.TVF_DateBucketDate` | Inline TVF | `date` |
| `toolbelt_datetime.TVF_DateBucketDateTime2` | Inline TVF | `datetime2(7)` |
| `toolbelt_datetime.TVF_DateBucketDateTimeOffset` | Inline TVF | `datetimeoffset(7)` |

`TVF_DateBucketDateTime2` und `TVF_DateBucketDateTimeOffset` verwenden
intern den nicht öffentlichen, stets einzeiligen `TVF_DateBucketCore`. Diese
bewusste Optimizer-Grenze verhindert SQL-Server-Fehler `8632`; die drei
öffentlichen Verträge bleiben Inline TVFs.

```sql
SELECT source.EventId, bucket.Value AS FifteenMinuteBucket
FROM dbo.SyntheticEvents AS source
CROSS APPLY toolbelt_datetime.TVF_DateBucketDateTime2
            ('minute', 15, source.EventTime, DEFAULT) AS bucket
WHERE bucket.IsValid = 1;
```

## Vertrag und Grenzen

- Width ist ein positiver `int`.
- Origin besitzt denselben Typ wie Value. `DEFAULT` verwendet den
  dokumentierten Ursprung `1900-01-01`.
- Werte vor Origin werden zum früheren Bucket-Start abgerundet.
- Version 1 verwendet Fractional Scale 7 und enthält keine `time`-,
  `datetime`- oder `smalldatetime`-Objekte.
- Ungültige parametrisierte Eingaben werden über `IsValid` und
  `ValidationCode` ausgewiesen.

## Deployment

Aus `Deployment/`:

```text
sqlcmd -S <server> -d <database> -i Deploy.sql -v DeploymentMode=local
```

## Dokumentation

- [Moduldesign](../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md)
- [Contract-Testmatrix](./Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md)
- [Runtime-Evidenz](./Tests/README.md)
- [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)
