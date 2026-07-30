# toolbelt.datetime.truncate

Portabler, typstabiler Teilvertrag von `DATETRUNC` für SQL Server 2019, 2022
und 2025.

## Objekte

| Objekt | Typ | Vertrag |
|---|---|---|
| `toolbelt_datetime.TVF_TruncateDate` | Inline TVF | `date` |
| `toolbelt_datetime.TVF_TruncateDateTime2` | Inline TVF | `datetime2(7)` |
| `toolbelt_datetime.TVF_TruncateDateTimeOffset` | Inline TVF | `datetimeoffset(7)` |

Alle Funktionen liefern `Value`, `IsValid` und `ValidationCode`. Die
relationale Oberfläche bleibt für mengenorientierte Aufrufe per `APPLY`
sichtbar und parallelisierbar.

```sql
SELECT source.EventId, truncated.Value AS MonthStart
FROM dbo.SyntheticEvents AS source
CROSS APPLY toolbelt_datetime.TVF_TruncateDateTime2
            ('month', source.EventTime) AS truncated
WHERE truncated.IsValid = 1;
```

## Grenzen

- Version 1 vereinheitlicht `datetime2` und `datetimeoffset` bewusst auf
  Fractional Scale 7.
- `datetime`, `smalldatetime` und `time` sind nicht Bestandteil von V1.
- `week` folgt `@@DATEFIRST`; `iso_week` beginnt immer am Montag.
- Ungültige parametrisierte Eingaben werden relational ausgewiesen. Engine-
  Overflows werden nicht umgeschrieben.

## Deployment

Aus `Deployment/` mit SQLCMD:

```text
sqlcmd -S <server> -d <database> -i Deploy.sql -v DeploymentMode=local
```

Lokale und zentrale Installation werden unterstützt. Zentrale Deinstallation
erfordert `ConfirmNoExternalConsumers=1`.

## Dokumentation

- [Moduldesign](../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md)
- [Contract-Testmatrix](./Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md)
- [Runtime-Evidenz](./Tests/README.md)
- [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)
