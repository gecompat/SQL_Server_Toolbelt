# Moduldesign: Date/Time Truncation

## Entscheidung

`toolbelt.datetime.truncate` implementiert `TC-2026-004` als portable
T-SQL-Inline-TVF-Familie:

- `toolbelt_datetime.TVF_TruncateDate`;
- `toolbelt_datetime.TVF_TruncateDateTime2`;
- `toolbelt_datetime.TVF_TruncateDateTimeOffset`.

Der Benutzer hat den W2a-Scope am 2026-07-30 ausdrücklich freigegeben.
Kanonische relationale APIs haben Vorrang; Version 1 enthält keine Scalar UDFs.

## Typvertrag

Die native Funktion `DATETRUNC` besitzt einen dynamischen Rückgabetyp und
erhält den Eingabetyp einschließlich Fractional Scale. Eine einzelne
T-SQL-UDF kann diesen Vertrag nicht abbilden. Version 1 verwendet deshalb eine
explizite Typfamilie:

| Objekt | Eingabe und Ausgabe | Unterstützte Dateparts |
|---|---|---|
| `TVF_TruncateDate` | `date` | Jahr bis Tag, `week`, `iso_week` |
| `TVF_TruncateDateTime2` | `datetime2(7)` | Jahr bis `microsecond` |
| `TVF_TruncateDateTimeOffset` | `datetimeoffset(7)` | Jahr bis `microsecond`; Offset bleibt erhalten |

`datetime`, `smalldatetime`, `time` und andere Fractional Scales werden nicht
als vermeintlich typgleiche APIs angeboten. Aufrufer konvertieren bewusst in
einen V1-Typ oder warten auf einen getrennt freizugebenden Ausbau.

## Datepart- und Wochenvertrag

Unterstützt werden die von `DATETRUNC` dokumentierten kanonischen Dateparts
und Aliasse:

- `year`, `quarter`, `month`;
- `dayofyear` und `day`;
- `week` anhand des aktuellen `@@DATEFIRST`;
- `iso_week` mit Montag als Wochenbeginn;
- `hour`, `minute`, `second`, `millisecond`, `microsecond` für die beiden
  Typen mit Zeitanteil.

`weekday`, `timezoneoffset` und `nanosecond` sind nicht unterstützt.
Datepart-Schlüssel werden nach `LOWER` mit
`Latin1_General_100_BIN2` als dokumentierte ASCII-Schlüssel verglichen.

## Validation Contract

Da eine Inline TVF kein `THROW` verwenden darf, liefert jede Funktion genau
eine Zeile mit `Value`, `IsValid` und `ValidationCode`.

| Code | Bedeutung |
|---:|---|
| `0` | gültig |
| `10` | unbekannter oder nicht unterstützter Datepart |
| `11` | Zeit-Datepart ist für `date` nicht zulässig |
| `12` | `week` würde den minimalen Wert des Datentyps unterschreiten |
| `NULL` | mindestens ein erforderlicher Parameter ist `NULL` |

Bei Code ungleich `0` ist `Value` `NULL`. Andere echte Datums- oder
Konvertierungsfehler bleiben unveränderte SQL-Server-Enginefehler.

## Alternativen

- Eine einzelne SVF mit festem `datetime2(7)`-Rückgabetyp wurde verworfen,
  weil sie den Eingabetyp still verlieren und die mengenorientierte
  Verwendung verschlechtern würde.
- Dynamisches SQL ist in UDFs nicht zulässig und wäre für einen Datepart
  außerdem unnötig.
- Separate native 2022-/2025-Provider würden Fachlogik duplizieren. Native
  Funktionen dienen als Testoracle.

## Quellen

- [DATETRUNC (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17)
- [Create user-defined functions](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17)
