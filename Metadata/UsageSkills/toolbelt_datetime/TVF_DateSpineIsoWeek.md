---
name: "toolbelt-toolbelt-toolbelt-datetime-tvf-datespineisoweek"
description: "Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden."
skill_format_version: "1.0"
module_id: "toolbelt.datetime.date-spine"
schema_name: "toolbelt_datetime"
object_name: "TVF_DateSpineIsoWeek"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@RangeStart", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start >= Ende liefert keine Zeilen."}, {"name": "@RangeEndExclusive", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31."}]
source_paths: ["Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineIsoWeek.sql", "Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineCore.sql", "Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_DateSpineIsoWeek

## Zweck und Einsatzfälle

Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.

## Voraussetzungen

SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Eingabevertrag |
|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start >= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

## Ergebnisse

Null bis mehrere Zeilen: Ordinal int, nullfrei ab 0 in Einerschritten, und PeriodStart date, nullfrei. Jede ausgegebene Periode schneidet [@RangeStart,@RangeEndExclusive). Grain: ISO-Woche mit Montag als Periodenanfang. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeile, keine NULL-Platzhalterzeile.

## Aufrufbeispiele

```sql
SELECT Ordinal,PeriodStart FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231','20260108')
ORDER BY Ordinal;
-- zwei Zeilen mit 2025-12-29 und 2026-01-05.
```

## Rechte

Für SELECT-Aufrufe vorhandenes SELECT auf der Funktion; REFERENCES gilt für entsprechende Referenzverwendungen. Die Funktion vergibt keine Rechte. Cross-Database-Identitätszuordnung und Rechte der aufgerufenen Objekte bleiben erforderlich.

## Ressourcenbedarf

Inline-Wrapper über TVF_DateSpineCore und TVF_GenerateSeriesInt. Ergebnis und Aufwand wachsen mit der Anzahl geschnittener Perioden; kein zusätzliches internes Zeilenlimit. Der gültige date-Bereich begrenzt die maximale Zahl von Tagen auf 3.652.058 bei exklusivem Ende 9999-12-31. Kein Versprechen einer konstanten Laufzeit.

## Nebenwirkungen

Rein relational lesend: keine Tabellen-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderung und keine Änderung des Caller-Transaktionszustands.

## Fehlerbehandlung

Fachliche NULL-/Ungültigfälle werden im jeweiligen Ergebnisvertrag beschrieben. Typbindung, Konvertierung und unerwartete SQL-Enginefehler bleiben Enginefehler; kein automatischer Retry.

## Aussagegrenzen

Keine garantierte Zeilenreihenfolge: ORDER BY Ordinal verwenden. PeriodStart darf bei ISO-Wochen und Monaten vor @RangeStart liegen. Die Obergrenze ist exklusiv; kein Sentinel jenseits 9999-12-31 und damit kein Bereich einschließlich des letzten SQL-date-Tages. ISO-Wochen sind DATEFIRST-unabhängig. Keine Geschäfts-/Feiertagslogik.
