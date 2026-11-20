-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_CalendarDifference
-- Zweck:           Zerlegt einen Datumsabstand in vollständige Kalenderjahre,
--                  -monate und Resttage.
-- Parameter:       @StartDate date, @EndDate date
-- Resultset:       Sign smallint, Years int, Months int, Days int
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; geeignet für CROSS APPLY
-- Collation:       nicht anwendbar
-- Einschränkungen: Anniversary-Regel klammert nicht vorhandene Monatstage an
--                  den letzten Tag des Zielmonats.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_CalendarDifference]
(
      @StartDate date
    , @EndDate   date
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-datetime-tvf-calendardifference"
-- description: "Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.datetime.calendar-difference"
-- schema_name: "toolbelt_datetime"
-- object_name: "TVF_CalendarDifference"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@StartDate", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten."}, {"name": "@EndDate", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten."}]
-- source_paths: ["Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_CalendarDifference
--
-- ## Zweck und Einsatzfälle
--
-- Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.
--
-- ## Voraussetzungen
--
-- SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Eingabevertrag |
-- |---|---|---|---|
-- | `@StartDate` | `date` | `kein Default` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten. |
-- | `@EndDate` | `date` | `kein Default` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile: Sign smallint, Years int, Months int, Days int. Sign ist 1 bei Start < Ende, -1 bei Start > Ende und 0 bei Gleichheit. Die übrigen Werte sind nichtnegative Abstände zwischen früherem und späterem Datum, nicht signierte Einzelkomponenten. NULL in einer Eingabe ergibt NULL in allen vier Spalten. Gleiche Daten ergeben vier Nullen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_datetime.TVF_CalendarDifference('20240131','20250302');
-- -- Sign=1, Years=1, Months=1, Days=2.
-- ```
--
-- ## Rechte
--
-- Für SELECT-Aufrufe vorhandenes SELECT auf der Funktion; REFERENCES gilt für entsprechende Referenzverwendungen. Die Funktion vergibt keine Rechte. Cross-Database-Identitätszuordnung und Rechte der aufgerufenen Objekte bleiben erforderlich.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF mit konstanter Zahl von DATEDIFF-/DATEADD-Ausdrücken pro Eingabezeile. Kein Kalender, keine Hilfstabelle und keine zeilenexpandierende Serie; Kosten eines äußeren APPLY hängen von dessen Eingabemenge ab.
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
-- Anniversary-Regel: DATEADD klammert fehlende Monatstage an das Monatsende. Erst volle Jahre, dann volle Monate ab dem Jahresanker und anschließend Resttage. Kein Zeit-/Offsetanteil, keine Geschäftstage und keine Gleichsetzung mit einer bloßen Zahl überschrittener Kalendergrenzen. Rückwärtsvergleich ändert Sign; Komponenten werden immer vom früheren Datum aus gebildet.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    /* DATEADD klammert nicht vorhandene Monatstage an das Monatsende. */
    WITH OrderedDates AS
    (
        SELECT
              Sign = CONVERT(smallint, CASE
                  WHEN @StartDate IS NULL OR @EndDate IS NULL THEN NULL
                  WHEN @StartDate < @EndDate THEN 1
                  WHEN @StartDate > @EndDate THEN -1 ELSE 0 END)
            , EarlierDate = CASE WHEN @StartDate <= @EndDate THEN @StartDate ELSE @EndDate END
            , LaterDate = CASE WHEN @StartDate <= @EndDate THEN @EndDate ELSE @StartDate END
    ),
    Years AS
    (
        SELECT
              ordered.Sign, ordered.EarlierDate, ordered.LaterDate
            , Years = CASE
                WHEN DATEADD(year, DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate), ordered.EarlierDate) > ordered.LaterDate
                    THEN DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate) - 1
                ELSE DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate) END
        FROM OrderedDates AS ordered
    ),
    Months AS
    (
        SELECT
              years.Sign, years.Years, years.LaterDate
            , YearAnchor = DATEADD(year, years.Years, years.EarlierDate)
        FROM Years AS years
    ),
    Resolved AS
    (
        SELECT
              months.Sign, months.Years, months.YearAnchor, months.LaterDate
            , Months = CASE
                WHEN DATEADD(month, DATEDIFF(month, months.YearAnchor, months.LaterDate), months.YearAnchor) > months.LaterDate
                    THEN DATEDIFF(month, months.YearAnchor, months.LaterDate) - 1
                ELSE DATEDIFF(month, months.YearAnchor, months.LaterDate) END
        FROM Months AS months
    )
    SELECT
          resolved.Sign, resolved.Years, resolved.Months
        , Days = DATEDIFF(day, DATEADD(month, resolved.Months, resolved.YearAnchor), resolved.LaterDate)
    FROM Resolved AS resolved
);
GO
