-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_TruncateDateTimeOffset
-- Zweck:           Portabler DATETRUNC-Kern für datetimeoffset(7).
-- Parameter:       @DatePart varchar(16), @Value datetimeoffset(7)
-- Resultset:       Value datetimeoffset(7), IsValid bit,
--                  ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; geeignet für CROSS APPLY und OUTER APPLY
-- Collation:       Datepart wird als ASCII-Schlüssel binär verglichen.
-- Einschränkungen: Fester Rückgabetyp datetimeoffset(7); ungültige
--                  Parameter werden relational statt per THROW ausgewiesen.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_TruncateDateTimeOffset]
(
      @DatePart varchar(16)
    , @Value    datetimeoffset(7)
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-datetime-tvf-truncatedatetimeoffset"
-- description: "Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.datetime.truncate"
-- schema_name: "toolbelt_datetime"
-- object_name: "TVF_TruncateDateTimeOffset"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Value", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler."}]
-- source_paths: ["Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTimeOffset.sql", "Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTime2.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_TruncateDateTimeOffset
--
-- ## Zweck und Einsatzfälle
--
-- Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.
--
-- ## Voraussetzungen
--
-- SQL Server 2019, 2022 oder 2025, Windows oder Linux; unterstützte Compatibility Levels 150/160/170. Modul und seine deklarierten Funktionsabhängigkeiten müssen installiert sein. Kein CLR oder externer Datenzugriff. Alle SQL-Funktionsargumente positionsbezogen angeben.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Eingabevertrag |
-- |---|---|---|---|
-- | `@DatePart` | `varchar(16)` | `kein Default` | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
-- | `@Value` | `datetimeoffset(7)` | `kein Default` | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile: Value datetimeoffset(7), IsValid bit, ValidationCode tinyint. NULL in einer Eingabe ergibt drei NULL-Felder. Erfolg: gekürzter Wert, IsValid=1, Code=0. Ungültiger Datepart: Value=NULL, IsValid=0, Code=10. Wochenunterlauf unter 0001-01-01 beim DATEFIRST-abhängigen week: Value=NULL, IsValid=0, Code=12.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('month', CONVERT(datetimeoffset(7),'2026-11-20T12:34:56.1234567+02:00'));
-- -- Beginn November 2026, IsValid=1, ValidationCode=0.
-- ```
--
-- ## Rechte
--
-- Für SELECT-Aufrufe vorhandenes SELECT auf der Funktion; REFERENCES gilt für entsprechende Referenzverwendungen. Die Funktion vergibt keine Rechte. Cross-Database-Identitätszuordnung und Rechte der aufgerufenen Objekte bleiben erforderlich.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF mit fester Datepart-Normalisierung und Kalender-/Zeitkomponenten, ohne Schleifen oder Serienexpansion. Die date- und datetime2-Wrapper delegieren an den gemeinsamen datetimeoffset-Kern. Aufwand je Eingabezeile ist begrenzt; äußere Abfragen bestimmen Gesamtvolumen und Plan.
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
-- week richtet sich nach SET DATEFIRST; iso_week beginnt immer montags. Kein nanosecond/weekday/tzoffset. Kleinere Einheiten werden abgeschnitten, nicht gerundet. Bei datetimeoffset wird die lokale Uhrzeit gekürzt und der feste Offset erhalten, keine UTC-Normalisierung oder Zeitzonen-/Sommerzeitauflösung. datetime2 wird intern mit Offset +00:00 gebunden. Liegt ein konstruierter datetimeoffset trotz gültiger lokaler Komponenten außerhalb des UTC-Darstellungsbereichs, bleibt dies ein Enginefehler und wird nicht in einen Validierungscode umgedeutet.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    WITH Normalized AS
    (
        SELECT CanonicalDatePart =
            CASE
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('year', 'yy', 'yyyy') THEN 'year'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('quarter', 'qq', 'q') THEN 'quarter'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('month', 'mm', 'm') THEN 'month'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('dayofyear', 'dy', 'y', 'day', 'dd', 'd') THEN 'day'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('week', 'wk', 'ww') THEN 'week'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('iso_week', 'isowk', 'isoww') THEN 'iso_week'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('hour', 'hh') THEN 'hour'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('minute', 'mi', 'n') THEN 'minute'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('second', 'ss', 's') THEN 'second'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('millisecond', 'ms') THEN 'millisecond'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('microsecond', 'mcs') THEN 'microsecond'
            END
    ),
    Parts AS
    (
        SELECT
              normalized.CanonicalDatePart
            , LocalDate = CONVERT(date, @Value)
            , OffsetMinutes = DATEPART(tzoffset, @Value)
            , WeekOffset = DATEPART(weekday, CONVERT(date, @Value)) - 1
            , IsoWeekOffset =
                (
                    (
                        DATEDIFF
                        (
                              day
                            , CONVERT(date, '19000101', 112)
                            , CONVERT(date, @Value)
                        ) % 7
                    ) + 7
                ) % 7
        FROM Normalized AS normalized
    ),
    Validated AS
    (
        SELECT
              parts.*
            , HasWeekUnderflow = CONVERT
              (
                  bit,
                  CASE
                      WHEN parts.CanonicalDatePart = 'week'
                       AND parts.WeekOffset >
                           DATEDIFF
                           (
                                 day
                               , CONVERT(date, '00010101', 112)
                               , parts.LocalDate
                           )
                          THEN 1
                      ELSE 0
                  END
              )
        FROM Parts AS parts
    ),
    TruncatedParts AS
    (
        SELECT
              validated.CanonicalDatePart
            , validated.HasWeekUnderflow
            , TruncatedDate =
                CASE validated.CanonicalDatePart
                    WHEN 'year'
                        THEN DATEFROMPARTS(YEAR(validated.LocalDate), 1, 1)
                    WHEN 'quarter'
                        THEN DATEFROMPARTS
                             (
                                   YEAR(validated.LocalDate)
                                 , ((MONTH(validated.LocalDate) - 1) / 3) * 3 + 1
                                 , 1
                             )
                    WHEN 'month'
                        THEN DATEFROMPARTS
                             (
                                   YEAR(validated.LocalDate)
                                 , MONTH(validated.LocalDate)
                                 , 1
                             )
                    WHEN 'week'
                        THEN DATEADD
                             (
                                   day
                                 , -CASE
                                       WHEN validated.HasWeekUnderflow = 1
                                           THEN 0
                                       ELSE validated.WeekOffset
                                    END
                                 , validated.LocalDate
                             )
                    WHEN 'iso_week'
                        THEN DATEADD
                             (
                                   day
                                 , -validated.IsoWeekOffset
                                 , validated.LocalDate
                             )
                    ELSE validated.LocalDate
                  END
            , TruncatedHour =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         (
                             'hour', 'minute', 'second',
                             'millisecond', 'microsecond'
                         )
                        THEN DATEPART(hour, @Value)
                    ELSE 0
                END
            , TruncatedMinute =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         ('minute', 'second', 'millisecond', 'microsecond')
                        THEN DATEPART(minute, @Value)
                    ELSE 0
                END
            , TruncatedSecond =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         ('second', 'millisecond', 'microsecond')
                        THEN DATEPART(second, @Value)
                    ELSE 0
                END
            , TruncatedFraction =
                CASE validated.CanonicalDatePart
                    WHEN 'millisecond'
                        THEN (DATEPART(nanosecond, @Value) / 1000000) * 10000
                    WHEN 'microsecond'
                        THEN (DATEPART(nanosecond, @Value) / 1000) * 10
                    ELSE 0
                END
            , OffsetHour = validated.OffsetMinutes / 60
            , OffsetMinute = validated.OffsetMinutes % 60
        FROM Validated AS validated
    )
    SELECT
          Value = CONVERT
          (
              datetimeoffset(7),
              CASE
                  WHEN @Value IS NULL
                    OR @DatePart IS NULL
                    OR truncated.CanonicalDatePart IS NULL
                    OR truncated.HasWeekUnderflow = 1
                      THEN NULL
                  ELSE DATETIMEOFFSETFROMPARTS
                       (
                             YEAR(truncated.TruncatedDate)
                           , MONTH(truncated.TruncatedDate)
                           , DAY(truncated.TruncatedDate)
                           , truncated.TruncatedHour
                           , truncated.TruncatedMinute
                           , truncated.TruncatedSecond
                           , truncated.TruncatedFraction
                           , truncated.OffsetHour
                           , truncated.OffsetMinute
                           , 7
                       )
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN truncated.CanonicalDatePart IS NULL
                    OR truncated.HasWeekUnderflow = 1 THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN truncated.CanonicalDatePart IS NULL THEN 10
                  WHEN truncated.HasWeekUnderflow = 1 THEN 12
                  ELSE 0
              END
          )
    FROM TruncatedParts AS truncated
);
GO
