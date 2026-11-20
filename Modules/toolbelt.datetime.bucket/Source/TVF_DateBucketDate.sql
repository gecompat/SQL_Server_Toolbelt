-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDate
-- Zweck:           Portabler DATE_BUCKET-Vertrag für date.
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value date, @Origin date = 1900-01-01
-- Resultset:       Value date, IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; eigener schlanker date-Ausdrucksbaum
-- Einschränkungen: Zeit-Dateparts sind für date ungültig.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketDate]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    date
    , @Origin   date = '19000101'
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-datetime-tvf-datebucketdate"
-- description: "Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.datetime.bucket"
-- schema_name: "toolbelt_datetime"
-- object_name: "TVF_DateBucketDate"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Width", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode."}, {"name": "@Value", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder."}, {"name": "@Origin", "sql_type": "date", "sql_default": "'19000101'", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder."}]
-- source_paths: ["Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDate.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_DateBucketDate
--
-- ## Zweck und Einsatzfälle
--
-- Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu. Für originbezogene Zeit-/Kalendergruppierungen; keine Rundung auf die nächste Grenze.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@DatePart` | `varchar(16)` | `kein Default` | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
-- | `@Width` | `int` | `kein Default` | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
-- | `@Value` | `date` | `kein Default` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
-- | `@Origin` | `date` | `'19000101'` | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value date, IsValid bit und ValidationCode tinyint. NULL in irgendeiner Eingabe: drei NULL-Werte. Erfolg: Value als berechneter Bucketanfang, IsValid=1, Code=0. Unbekannter Datepart: Value=NULL, IsValid=0, Code=10. Breite <=0: Value=NULL, IsValid=0, Code=11. Für date sind hour/minute/second/millisecond einschließlich ihrer oben genannten Aliase ungültig: Value=NULL, IsValid=0, Code=12; diese Erkennung hat Vorrang vor ungültiger Width. microsecond ist auch hier unbekannt und ergibt Code=10.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_datetime.TVF_DateBucketDate
--  ('day',2,CONVERT(date,'2026-01-04T12:00:00'),
--  CONVERT(date,'2026-01-01T00:00:00'));
-- -- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Interne Aufrufrechte und Cross-Database-Zuordnung bleiben projektgemäß erforderlich. Kein Rechtegrant oder Identitätswechsel.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF mit festen CTE-Ausdrucksstufen, ohne Iteration oder Serienexpansion. Konstante Kalender-/Zeitberechnung je Eingabezeile. Plan und Gesamtkosten hängen von aufrufender Abfrage und Eingabemenge ab.
--
-- ## Nebenwirkungen
--
-- Rein lesend ohne persistente DML-, Datei-, Netzwerk-, Konfigurations- oder Truständerungen. Der interne Multistatement-Kern befüllt ausschließlich seine lokale Rückgabetabelle.
--
-- ## Fehlerbehandlung
--
-- NULL und fachlich ungültige Dateparts/Breiten liefern die oben beschriebenen Ergebniszustände. Typbindung sowie DATEADD-/CONVERT-Bereichsüberläufe bleiben Enginefehler; keine pauschale Umdeutung in ValidationCode und kein Retry.
--
-- ## Aussagegrenzen
--
-- Der Algorithmus bildet DATEDIFF_BIG vom Origin, teilt mit Abrundung bei negativen Abständen durch Width, addiert ganze Bucketbreiten zum Origin und korrigiert einen zu großen Kandidaten um eine Breite. Kalenderaddition folgt SQL-Monatsendklammerung; Zeitanteil des Origins bleibt Bezug. week benutzt die DATEDIFF-Wochengrenzen, nicht die DATEFIRST-abhängige Truncate-Wochenlogik. datetimeoffset-Ausgabe behält den Origin-Offset; keine Zeitzonen-/Sommerzeitdatenbank und keine Garantie eines Value-Offsets im Ergebnis. datetime2 wird intern mit +00:00 gebunden. Extreme Breiten nahe Datumsgrenzen können vor oder bei der abschließenden Korrektur außerhalb des SQL-Wertebereichs liegen. Keine iso_week-, microsecond- oder nanosecond-Unterstützung.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    WITH Normalized AS
    (
        SELECT
              CanonicalDatePart =
                CASE
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('year', 'yy', 'yyyy') THEN 'year'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('quarter', 'qq', 'q') THEN 'quarter'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('month', 'mm', 'm') THEN 'month'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('week', 'wk', 'ww') THEN 'week'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN
                         (
                             'dayofyear', 'dy', 'y',
                             'day', 'dd', 'd',
                             'weekday', 'dw', 'w'
                         ) THEN 'day'
                END
            , IsTimeDatePart = CONVERT
              (
                  bit,
                  CASE
                      WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                           IN
                           (
                               'hour', 'hh',
                               'minute', 'mi', 'n',
                               'second', 'ss', 's',
                               'millisecond', 'ms'
                           )
                          THEN 1
                      ELSE 0
                  END
              )
    ),
    Distances AS
    (
        SELECT
              normalized.CanonicalDatePart
            , normalized.IsTimeDatePart
            , Distance = CONVERT
              (
                  bigint,
                  CASE normalized.CanonicalDatePart
                      WHEN 'year' THEN DATEDIFF_BIG(year, @Origin, @Value)
                      WHEN 'quarter'
                          THEN DATEDIFF_BIG(quarter, @Origin, @Value)
                      WHEN 'month' THEN DATEDIFF_BIG(month, @Origin, @Value)
                      WHEN 'week' THEN DATEDIFF_BIG(week, @Origin, @Value)
                      WHEN 'day' THEN DATEDIFF_BIG(day, @Origin, @Value)
                  END
              )
        FROM Normalized AS normalized
    ),
    BucketIndexes AS
    (
        SELECT
              distances.CanonicalDatePart
            , distances.IsTimeDatePart
            , BucketIndex =
                CASE
                    WHEN @Width > 0
                     AND distances.Distance < 0
                     AND distances.Distance % @Width <> 0
                        THEN distances.Distance / @Width - 1
                    WHEN @Width > 0 THEN distances.Distance / @Width
                END
        FROM Distances AS distances
    ),
    Candidates AS
    (
        SELECT
              indexes.CanonicalDatePart
            , indexes.IsTimeDatePart
            , Value = CONVERT
              (
                  date,
                  CASE indexes.CanonicalDatePart
                      WHEN 'year'
                          THEN DATEADD
                               (
                                   year,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'quarter'
                          THEN DATEADD
                               (
                                   quarter,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'month'
                          THEN DATEADD
                               (
                                   month,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'week'
                          THEN DATEADD
                               (
                                   week,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'day'
                          THEN DATEADD
                               (
                                   day,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                  END
              )
        FROM BucketIndexes AS indexes
    ),
    Adjusted AS
    (
        SELECT
              candidates.CanonicalDatePart
            , candidates.IsTimeDatePart
            , Value = CONVERT
              (
                  date,
                  CASE
                      WHEN candidates.Value <= @Value THEN candidates.Value
                      WHEN candidates.CanonicalDatePart = 'year'
                          THEN DATEADD
                               (
                                   year,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'quarter'
                          THEN DATEADD
                               (
                                   quarter,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'month'
                          THEN DATEADD
                               (
                                   month,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'week'
                          THEN DATEADD
                               (
                                   week,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'day'
                          THEN DATEADD
                               (
                                   day,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                  END
              )
        FROM Candidates AS candidates
    )
    SELECT
          Value = CONVERT
          (
              date,
              CASE
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                    OR adjusted.CanonicalDatePart IS NULL
                    OR @Width <= 0
                      THEN NULL
                  ELSE adjusted.Value
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                      THEN NULL
                  WHEN adjusted.CanonicalDatePart IS NULL OR @Width <= 0 THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                      THEN NULL
                  WHEN adjusted.IsTimeDatePart = 1 THEN 12
                  WHEN adjusted.CanonicalDatePart IS NULL THEN 10
                  WHEN @Width <= 0 THEN 11
                  ELSE 0
              END
          )
    FROM Adjusted AS adjusted
);
GO
