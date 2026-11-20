-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketCore
-- Zweck:           Interner prozeduraler Bucket-Kern für datetimeoffset(7).
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value datetimeoffset(7), @Origin datetimeoffset(7)
-- Resultset:       Value datetimeoffset(7), IsValid bit,
--                  ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Sichtbarkeit:    intern; öffentliche Aufrufe verwenden die Inline-TVFs
-- Performance:     Einzeilige MSTVF als bewusste Optimizer-Grenze gegen 8632
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketCore]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    datetimeoffset(7)
    , @Origin   datetimeoffset(7)
)
RETURNS @Result TABLE
(
      Value          datetimeoffset(7) NULL
    , IsValid       bit               NULL
    , ValidationCode tinyint          NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-datetime-date-bucket-core"
-- description: "Interner einzeiliger Multistatement-Kern für originbezogene datetimeoffset-Buckets."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.datetime.bucket"
-- schema_name: "toolbelt_datetime"
-- object_name: "TVF_DateBucketCore"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Width", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode."}, {"name": "@Value", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder."}, {"name": "@Origin", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Referenz für Bucketgrenzen als datetimeoffset(7); kein technischer Default. Ergebnis behält den Origin-Offset. NULL liefert eine Zeile mit drei NULL-Werten. SQL-Wertebereich einschließlich gültiger UTC-Darstellung und Offset -14:00..+14:00 beachten."}]
-- source_paths: ["Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketCore.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_datetime.TVF_DateBucketDate", "toolbelt_datetime.TVF_DateBucketDateTime2", "toolbelt_datetime.TVF_DateBucketDateTimeOffset"]
-- ---
--
-- # TVF_DateBucketCore
--
-- ## Zweck und Einsatzfälle
--
-- Interner einzeiliger Multistatement-Kern für originbezogene datetimeoffset-Buckets. Anwendungen verwenden die drei öffentlichen typisierten Fassaden; keine neue eigenständige Fachschnittstelle.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. Auch Origin muss explizit gebunden werden.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@DatePart` | `varchar(16)` | `kein Default` | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
-- | `@Width` | `int` | `kein Default` | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
-- | `@Value` | `datetimeoffset(7)` | `kein Default` | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
-- | `@Origin` | `datetimeoffset(7)` | `kein Default` | Referenz für Bucketgrenzen als datetimeoffset(7); kein technischer Default. Ergebnis behält den Origin-Offset. NULL liefert eine Zeile mit drei NULL-Werten. SQL-Wertebereich einschließlich gültiger UTC-Darstellung und Offset -14:00..+14:00 beachten. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value datetimeoffset(7), IsValid bit und ValidationCode tinyint. NULL in irgendeiner Eingabe: drei NULL-Werte. Erfolg: Value als berechneter Bucketanfang, IsValid=1, Code=0. Unbekannter Datepart: Value=NULL, IsValid=0, Code=10. Breite <=0: Value=NULL, IsValid=0, Code=11. Unbekannter Datepart hat Vorrang vor ungültiger Width. Kein eigener Status für arithmetischen Bereichsüberlauf.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Öffentlicher Einstieg statt direkter Bindung an den internen Kern:
-- SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
--  ('day',2,CONVERT(datetimeoffset(7),'2026-01-04T12:00:00+00:00'),
--  CONVERT(datetimeoffset(7),'2026-01-01T00:00:00+00:00'));
-- -- Value=2026-01-03 00:00:00+00:00, IsValid=1, ValidationCode=0.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Interne Aufrufrechte und Cross-Database-Zuordnung bleiben projektgemäß erforderlich. Kein Rechtegrant oder Identitätswechsel.
--
-- ## Ressourcenbedarf
--
-- Einzeilige Multistatement-TVF als bewusste Optimizer-Grenze gegen übergroße Inline-Ausdrucksbäume; die datetime2-/datetimeoffset-Fassaden sind dünne Inline-Wrapper. Keine Schleife oder Serienexpansion. Konstante Kalender-/Zeitberechnung je Eingabezeile. Plan und Gesamtkosten hängen von aufrufender Abfrage und Eingabemenge ab.
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
BEGIN
    IF @DatePart IS NULL
       OR @Width IS NULL
       OR @Value IS NULL
       OR @Origin IS NULL
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, NULL, NULL);
        RETURN;
    END;

    DECLARE @CanonicalDatePart varchar(16) =
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
            WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                 IN ('hour', 'hh') THEN 'hour'
            WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                 IN ('minute', 'mi', 'n') THEN 'minute'
            WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                 IN ('second', 'ss', 's') THEN 'second'
            WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                 IN ('millisecond', 'ms') THEN 'millisecond'
        END;

    IF @CanonicalDatePart IS NULL
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, 0, 10);
        RETURN;
    END;

    IF @Width <= 0
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, 0, 11);
        RETURN;
    END;

    DECLARE @Distance bigint =
        CASE @CanonicalDatePart
            WHEN 'year' THEN DATEDIFF_BIG(year, @Origin, @Value)
            WHEN 'quarter' THEN DATEDIFF_BIG(quarter, @Origin, @Value)
            WHEN 'month' THEN DATEDIFF_BIG(month, @Origin, @Value)
            WHEN 'week' THEN DATEDIFF_BIG(week, @Origin, @Value)
            WHEN 'day' THEN DATEDIFF_BIG(day, @Origin, @Value)
            WHEN 'hour' THEN DATEDIFF_BIG(hour, @Origin, @Value)
            WHEN 'minute' THEN DATEDIFF_BIG(minute, @Origin, @Value)
            WHEN 'second' THEN DATEDIFF_BIG(second, @Origin, @Value)
            WHEN 'millisecond'
                THEN DATEDIFF_BIG(millisecond, @Origin, @Value)
        END;
    DECLARE @BucketIndex bigint = @Distance / CONVERT(bigint, @Width);

    IF @Distance < 0 AND @Distance % @Width <> 0
        SET @BucketIndex -= 1;

    DECLARE
          @UnitOffset bigint = @BucketIndex * CONVERT(bigint, @Width)
        , @DayOffset int = 0
        , @Remainder int = 0
        , @Candidate datetimeoffset(7);

    IF @CanonicalDatePart = 'hour'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 24
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 24 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 24);
        SET @Candidate =
            DATEADD(hour, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'minute'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 1440
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 1440 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 1440);
        SET @Candidate =
            DATEADD(minute, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'second'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 86400
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 86400 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 86400);
        SET @Candidate =
            DATEADD(second, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'millisecond'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 86400000
            - CASE
                  WHEN @UnitOffset < 0
                   AND @UnitOffset % 86400000 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder = CONVERT
        (
            int,
            @UnitOffset - CONVERT(bigint, @DayOffset) * 86400000
        );
        SET @Candidate =
            DATEADD(millisecond, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE
        SET @Candidate =
            CASE @CanonicalDatePart
                WHEN 'year'
                    THEN DATEADD(year, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'quarter'
                    THEN DATEADD(quarter, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'month'
                    THEN DATEADD(month, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'week'
                    THEN DATEADD(week, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'day'
                    THEN DATEADD(day, CONVERT(int, @UnitOffset), @Origin)
            END;

    IF @Candidate > @Value
        SET @Candidate =
            CASE @CanonicalDatePart
                WHEN 'year' THEN DATEADD(year, -@Width, @Candidate)
                WHEN 'quarter' THEN DATEADD(quarter, -@Width, @Candidate)
                WHEN 'month' THEN DATEADD(month, -@Width, @Candidate)
                WHEN 'week' THEN DATEADD(week, -@Width, @Candidate)
                WHEN 'day' THEN DATEADD(day, -@Width, @Candidate)
                WHEN 'hour' THEN DATEADD(hour, -@Width, @Candidate)
                WHEN 'minute' THEN DATEADD(minute, -@Width, @Candidate)
                WHEN 'second' THEN DATEADD(second, -@Width, @Candidate)
                WHEN 'millisecond'
                    THEN DATEADD(millisecond, -@Width, @Candidate)
            END;

    INSERT INTO @Result (Value, IsValid, ValidationCode)
    VALUES (@Candidate, 1, 0);
    RETURN;
END;
GO
