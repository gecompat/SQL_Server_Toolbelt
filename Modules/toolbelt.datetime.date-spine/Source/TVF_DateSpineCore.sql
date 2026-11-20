-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateSpineCore
-- Typ:             Inline Table-valued Function (intern)
-- Zweck:           Gemeinsamer relationaler Kern für periodische Date Spines
-- Vertrag:         Documentation/Architecture/DATE_SPINE_MODULE_DESIGN.md
-- Parameter:       @RangeStart date, @RangeEndExclusive date,
--                  @Grain varchar(16)
-- Resultset:       Ordinal int, PeriodStart date
-- Dependencies:    toolbelt.core.generate-series 1.0.0;
--                  toolbelt.datetime.truncate 1.0.0
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Plattformen:     Windows und Linux
-- Fehlerverhalten: Ungültiger Grain sowie NULL-, leere und umgekehrte
--                  Bereiche liefern keine Zeilen.
-- Performance:     Inline TVF; Aufwand und Ergebnisgröße wachsen linear mit
--                  der Zahl der geschnittenen Perioden.
-- Einschränkungen: Internes Objekt; keine garantierte Reihenfolge.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateSpineCore]
(
      @RangeStart        date
    , @RangeEndExclusive date
    , @Grain             varchar(16)
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-datetime-date-spine-core"
-- description: "Interner gemeinsamer Kern für Tages-, ISO-Wochen- und Monatsserien."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.datetime.date-spine"
-- schema_name: "toolbelt_datetime"
-- object_name: "TVF_DateSpineCore"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RangeStart", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start >= Ende liefert keine Zeilen."}, {"name": "@RangeEndExclusive", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31."}, {"name": "@Grain", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ 'day' = Kalendertage, 'iso_week' = ISO-Wochen ab Montag, 'month' = Kalendermonate. Binärer Vergleich ohne LOWER: Großschreibung ist ungültig; nachgestellte Leerzeichen folgen SQL-Gleichheitsregeln. NULL, leer oder unbekannt liefert keine Zeilen."}]
-- source_paths: ["Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineCore.sql", "Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_datetime.TVF_DateSpineDay", "toolbelt_datetime.TVF_DateSpineIsoWeek", "toolbelt_datetime.TVF_DateSpineMonth"]
-- ---
--
-- # TVF_DateSpineCore
--
-- ## Zweck und Einsatzfälle
--
-- Interner gemeinsamer Kern für Tages-, ISO-Wochen- und Monatsserien. Interner Implementierungsvertrag; für Anwendungen die drei typisierten öffentlichen Einstiegspunkte verwenden.
--
-- ## Voraussetzungen
--
-- SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
--
-- ## Parameter und Zugriff
--
-- `@RangeStart date` (kein SQL-Default): SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start >= Ende liefert keine Zeilen.
--
-- `@RangeEndExclusive date` (kein SQL-Default): SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31.
--
-- `@Grain varchar(16)` (kein SQL-Default): Taxativ 'day' = Kalendertage, 'iso_week' = ISO-Wochen ab Montag, 'month' = Kalendermonate. Binärer Vergleich ohne LOWER: Großschreibung ist ungültig; nachgestellte Leerzeichen folgen SQL-Gleichheitsregeln. NULL, leer oder unbekannt liefert keine Zeilen.
--
-- ## Ergebnisse
--
-- Null bis mehrere Zeilen mit Ordinal int ab 0 und PeriodStart date, beide nullfrei. day beginnt am Startdatum, iso_week am Montag der geschnittenen Woche und month am Ersten des geschnittenen Monats. NULL, ungültiger Grain oder nicht aufsteigender Bereich liefert keine Zeilen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Öffentlicher Einstieg statt direkter Bindung an den internen Kern:
-- SELECT * FROM toolbelt_datetime.TVF_DateSpineMonth('20260115','20260402')
-- ORDER BY Ordinal;
-- ```
--
-- ## Rechte
--
-- Für SELECT-Aufrufe vorhandenes SELECT auf der Funktion; REFERENCES gilt für entsprechende Referenzverwendungen. Die Funktion vergibt keine Rechte. Cross-Database-Identitätszuordnung und Rechte der aufgerufenen Objekte bleiben erforderlich.
--
-- ## Ressourcenbedarf
--
-- Inline-Wrapper über TVF_DateSpineCore und TVF_GenerateSeriesInt. Ergebnis und Aufwand wachsen mit der Anzahl geschnittener Perioden; kein zusätzliches internes Zeilenlimit. Der gültige date-Bereich begrenzt die maximale Zahl von Tagen auf 3.652.058 bei exklusivem Ende 9999-12-31. Kein Versprechen einer konstanten Laufzeit.
--
-- ## Nebenwirkungen
--
-- Rein relational lesend: keine Tabellen-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderung und keine Änderung des Caller-Transaktionszustands.
--
-- ## Fehlerbehandlung
--
-- Fachliche NULL-/Ungültigfälle werden im jeweiligen Ergebnisvertrag beschrieben. Typbindung, Konvertierung und unerwartete SQL-Enginefehler bleiben Enginefehler; kein automatischer Retry.
--
-- ## Aussagegrenzen
--
-- Keine garantierte Zeilenreihenfolge: ORDER BY Ordinal verwenden. PeriodStart darf bei ISO-Wochen und Monaten vor @RangeStart liegen. Die Obergrenze ist exklusiv; kein Sentinel jenseits 9999-12-31 und damit kein Bereich einschließlich des letzten SQL-date-Tages. ISO-Wochen sind DATEFIRST-unabhängig. Keine Geschäfts-/Feiertagslogik.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    /*
     * Der Ersatzwert schützt DATEADD bei einer ungültigen minimalen
     * Exklusivgrenze. Die ValidRange-CTE entfernt diesen Pfad vollständig aus
     * dem Ergebnis; sie vermeidet zugleich eine optimizerabhängige
     * Kurzschlussannahme für den date-Unterlauf.
     */
    WITH InputContract AS
    (
        SELECT
              IsValidRange = CONVERT
              (
                  bit,
                  CASE
                      WHEN @RangeStart IS NOT NULL
                       AND @RangeEndExclusive IS NOT NULL
                       AND @RangeStart < @RangeEndExclusive
                       AND @Grain COLLATE Latin1_General_100_BIN2
                           IN ('day', 'iso_week', 'month')
                          THEN 1
                      ELSE 0
                  END
              )
            , LastIncludedDate = DATEADD
              (
                  day,
                  -1,
                  CASE
                      WHEN @RangeStart IS NOT NULL
                       AND @RangeEndExclusive IS NOT NULL
                       AND @RangeStart < @RangeEndExclusive
                          THEN @RangeEndExclusive
                      ELSE CONVERT(date, '00010102', 112)
                  END
              )
    ),
    Boundaries AS
    (
        SELECT
              FirstPeriodStart = CONVERT
              (
                  date,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN @RangeStart
                      WHEN 'iso_week' THEN first_iso_week.Value
                      WHEN 'month' THEN first_month.Value
                  END
              )
            , LastPeriodStart = CONVERT
              (
                  date,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN input.LastIncludedDate
                      WHEN 'iso_week' THEN last_iso_week.Value
                      WHEN 'month' THEN last_month.Value
                  END
              )
        FROM InputContract AS input
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('iso_week', @RangeStart) AS first_iso_week
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('month', @RangeStart) AS first_month
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('iso_week', input.LastIncludedDate) AS last_iso_week
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('month', input.LastIncludedDate) AS last_month
        WHERE input.IsValidRange = 1
    ),
    CountedBoundaries AS
    (
        SELECT
              boundaries.FirstPeriodStart
            , LastOrdinal = CONVERT
              (
                  int,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN DATEDIFF
                           (day, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart)
                      WHEN 'iso_week' THEN DATEDIFF
                           (day, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart) / 7
                      WHEN 'month' THEN DATEDIFF
                           (month, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart)
                  END
              )
        FROM Boundaries AS boundaries
    )
    SELECT
          Ordinal = series.Value
        , PeriodStart = CONVERT
          (
              date,
              CASE @Grain COLLATE Latin1_General_100_BIN2
                  WHEN 'day' THEN DATEADD
                       (day, series.Value, counted.FirstPeriodStart)
                  WHEN 'iso_week' THEN DATEADD
                       (day, series.Value * 7, counted.FirstPeriodStart)
                  WHEN 'month' THEN DATEADD
                       (month, series.Value, counted.FirstPeriodStart)
              END
          )
    FROM CountedBoundaries AS counted
    CROSS APPLY toolbelt_core.TVF_GenerateSeriesInt
                (0, counted.LastOrdinal, 1) AS series
);
GO
