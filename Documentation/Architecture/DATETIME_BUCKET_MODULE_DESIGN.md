# Moduldesign: Date/Time Bucket

## Entscheidung

`toolbelt.datetime.bucket` implementiert `TC-2026-005` im freigegebenen
W2a-Scope als typgetrennte T-SQL-Inline-TVFs:

- `toolbelt_datetime.TVF_DateBucketDate`;
- `toolbelt_datetime.TVF_DateBucketDateTime2`;
- `toolbelt_datetime.TVF_DateBucketDateTimeOffset`.

Version 1 besitzt keine Abhängigkeit zum Truncation-Modul. Beide Capabilities
teilen keine Fachlogik: Truncation richtet sich an Kalendergrenzen,
Bucketing an frei definierbare Breiten ab einem Origin.

## Typ- und Origin-Vertrag

| Objekt | Value, Origin und Ausgabe | Default-Origin |
|---|---|---|
| `TVF_DateBucketDate` | `date` | `1900-01-01` |
| `TVF_DateBucketDateTime2` | `datetime2(7)` | `1900-01-01 00:00:00` |
| `TVF_DateBucketDateTimeOffset` | `datetimeoffset(7)` | `1900-01-01 00:00:00 +00:00` |

Der Default wird bei Funktionsaufrufen mit dem T-SQL-Schlüsselwort `DEFAULT`
verwendet. Ein explizites `NULL` für Origin bleibt `NULL`. Andere Date/Time-
Typen und Fractional Scales sind nicht Teil von Version 1.

## Bucket-Vertrag

Unterstützt sind die nativen Dateparts und Aliasse für `year`, `quarter`,
`month`, `week`, `day`/`dayofyear`/`weekday`, `hour`, `minute`, `second` und
`millisecond`. `Width` muss ein positiver `int` sein.

Die Bucket-Position wird vom Origin aus berechnet. Für Werte vor dem Origin
wird mathematisch zum früheren Bucket-Start abgerundet; Integerdivision darf
diesen Fall nicht Richtung null verschieben. Ein Kandidat, der wegen
Boundary-Zählung oder Origin-Zeitanteil nach `Value` liegt, wird um genau eine
Bucketbreite zurückgesetzt.

Für `hour` bis `millisecond` wird ein großer Abstand in Tage und einen
Restanteil zerlegt. Dadurch bleibt die Implementierung mit der
`DATEADD`-`int`-Grenze von SQL Server 2019 kompatibel.

## Validation Contract

| Code | Bedeutung |
|---:|---|
| `0` | gültig |
| `10` | unbekannter oder nicht unterstützter Datepart |
| `11` | Width ist null oder nicht positiv; bei `NULL` bleibt der Gesamtstatus `NULL` |
| `12` | Zeit-Datepart ist für `date` nicht zulässig |
| `NULL` | mindestens ein erforderlicher Parameter ist `NULL` |

Bei einem ungültigen Vertrag ist `Value` `NULL`. Echte Datumsüberläufe bleiben
unveränderte Enginefehler.

## Alternativen

- `TC-2026-004` wird nicht als Dependency verwendet, weil `DATE_BUCKET`
  keinen bloßen Truncation-Aufruf darstellt.
- Native Fast Paths ab SQL Server 2022 wurden nicht aufgenommen; ein zweiter
  Provider würde Deployment und Parität ohne belegten Nutzen verdoppeln.
- Scalar UDFs bleiben außerhalb von V1. Für mengenorientierte Aufrufe ist
  `CROSS APPLY` beziehungsweise `OUTER APPLY` der dokumentierte Pfad.

## Quelle

- [DATE_BUCKET (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/date-bucket-transact-sql?view=sql-server-ver17)
