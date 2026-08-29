# Moduldesign: Date Spine V1

## Entscheidung und Freigabe

`toolbelt.datetime.date-spine` implementiert `D1` als portable Familie aus
drei öffentlichen Inline Table-valued Functions. Zweck, öffentlicher Vertrag,
Alternativen, Risiken und Scope wurden am 2026-08-30 mit dem Benutzer
besprochen. Der Benutzer hat die Umsetzung danach mit „lass es uns so machen“
ausdrücklich freigegeben.

## Öffentliche Oberfläche

| Objekt | Periode |
|---|---|
| `toolbelt_datetime.TVF_DateSpineDay` | Kalendertag |
| `toolbelt_datetime.TVF_DateSpineIsoWeek` | ISO-Woche mit Montag als Periodenanfang |
| `toolbelt_datetime.TVF_DateSpineMonth` | Kalendermonat |

Jede Funktion akzeptiert `@RangeStart date` und
`@RangeEndExclusive date`. Das Resultset besteht aus `Ordinal int` und
`PeriodStart date`; `Ordinal` beginnt bei `0`. Eine Reihenfolge ist ohne
`ORDER BY` des Aufrufers nicht garantiert.

## Bereichs- und Periodenvertrag

Der Eingabebereich ist halboffen: `[RangeStart, RangeEndExclusive)`. Geliefert
werden alle Perioden, die diesen Bereich schneiden. Deshalb kann der erste
`PeriodStart` bei ISO-Woche und Monat vor `RangeStart` liegen.

`NULL`, `RangeStart = RangeEndExclusive` und umgekehrte Bereiche liefern eine
leere Menge. Die Funktionen werfen dafür keinen eigenen Fehler. Die natürliche
`date`-Domäne begrenzt die Ergebnisgröße; ein zusätzliches Zeilenlimit besteht
nicht. Weil `date` keinen Wert nach `9999-12-31` darstellen kann, lässt sich der
maximale Kalendertag nicht als enthaltener Tag eines halboffenen Bereichs
ausdrücken.

## Kanonischer Kern und Dependencies

`toolbelt_datetime.TVF_DateSpineCore` enthält die Fachlogik genau einmal und
ist intern. Die öffentlichen Funktionen übergeben ausschließlich einen festen
Grain-Schlüssel. Der Kern verwendet:

- `toolbelt.core.generate-series` Version `1.0.0` für nullbasierte Ordinals;
- `toolbelt.datetime.truncate` Version `1.0.0` für ISO-Wochen- und
  Monatsgrenzen.

`toolbelt.datetime.bucket` ist keine Dependency. Ein künstlicher Bezug würde
die Dependency-Closure verbreitern, ohne im freigegebenen Vertrag verwendet zu
werden.

## Alternativen

- Eine einzelne Funktion mit öffentlichem Grain-Parameter wurde verworfen,
  weil sie ungültige Laufzeitwerte und einen später schwerer erweiterbaren
  Sammelvertrag erzeugen würde.
- Eine Stored Procedure wurde verworfen, weil Date Spines primär relational
  über `APPLY`, Joins und Aggregationen verwendet werden.
- Nur vollständig im Bereich enthaltene Wochen oder Monate wurden verworfen;
  dies würde partielle Randperioden überraschend verlieren.
- Eine persistente Kalenderdimension wurde verworfen, weil Wartung,
  Aktualität, Feiertage und kundenspezifische Attribute nicht Teil von D1
  sind.
- Frei wählbare Schritte und Quartale bleiben getrennte mögliche Erweiterungen.

## Risiken und Grenzen

- Große Tagesbereiche erzeugen entsprechend viele Zeilen; der Aufrufer trägt
  Verantwortung für Filter, Joinform und Materialisierung.
- ISO-Wochen sind bewusst Montag-basiert und unabhängig von `SET DATEFIRST`.
- Das Modul liefert keine Periodenenden oder abgeleiteten Jahr-, Monats-,
  Quartals- oder ISO-Wochennummern.
- Feiertage, Arbeitstage, Locale-Texte, Geschäfts- und Fiskalkalender,
  Zeitzonen, DST und persistente Kalenderdimensionen gehören nicht zu V1.

## Quellen

- [Microsoft: Date and time data types and functions](https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver17)
- [Microsoft: date](https://learn.microsoft.com/en-us/sql/t-sql/data-types/date-transact-sql?view=sql-server-ver17)
- [dbt-utils: `date_spine` als Cross-database Prior Art](https://github.com/dbt-labs/dbt-utils#date_spine-source)

Die Implementierung ist eigenständig; es wurde kein Drittanbietercode
übernommen.
