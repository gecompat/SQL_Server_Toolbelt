-- ============================================================================
-- Objekt:          toolbelt_json.TVF_JsonPathExists
-- Typ:             Multi-statement Table-valued Function
-- Zweck:           Prüft einen SQL/JSON-Pfad portabel auf Existenz.
-- Vertrag:         Documentation/TVF_JsonPathExists.md
-- Parameter:       @Json nvarchar(max), @Path nvarchar(max)
-- Resultset:       PathExists int
-- Dependencies:    keine Modulabhängigkeit
-- Rechte:          SELECT oder REFERENCES
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux, T-SQL
-- Fehlerverhalten: Keine fachlichen Fehler; ungültiges JSON oder ungültige
--                  Pfade liefern 0, SQL-NULL wird propagiert.
-- Performance:     Pfadsegmente und Wildcard-Treffer werden zustandsbehaftet
--                  in Table Variables materialisiert.
-- Einschränkungen: Pfade sind auf 4.000 UTF-16-Codeunits begrenzt. SQL Server
--                  2025 Preview-Ranges, Listen und last sind nicht enthalten.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_json].[TVF_JsonPathExists]
(
      @Json nvarchar(max)
    , @Path nvarchar(max)
)
RETURNS @Result TABLE
(
    PathExists int NULL
)
AS
BEGIN
    IF @Json IS NULL OR @Path IS NULL
    BEGIN
        INSERT @Result (PathExists) VALUES (NULL);
        RETURN;
    END;

    -- Der V1-Vertrag begrenzt den Pfad bewusst. Dadurch bleiben alle
    -- Parserpositionen int-basiert und der pro Aufruf materialisierte Zustand
    -- kontrollierbar.
    IF DATALENGTH(@Path) > 8000
    BEGIN
        INSERT @Result (PathExists) VALUES (0);
        RETURN;
    END;

    DECLARE
          @PathText nvarchar(max) = LTRIM(RTRIM(@Path))
        , @PathLength int
        , @Position int = 1
        , @Start int
        , @Scan int
        , @Escaped bit
        , @Invalid bit = 0
        , @Token nvarchar(max)
        , @Literal nvarchar(max)
        , @Envelope nvarchar(max)
        , @SegmentType char(1)
        , @SegmentOrdinal int = 1
        , @SegmentCount int;

    -- lax und strict werden angenommen, beeinflussen den fehlerfreien
    -- Existenzvertrag aber nicht. JSON_PATH_EXISTS wirft selbst in strict
    -- mode keinen Fehler.
    IF LEFT(@PathText, 4) COLLATE Latin1_General_100_CI_AS = N'lax '
        SET @PathText = LTRIM(SUBSTRING(@PathText, 5, 4000));
    ELSE IF LEFT(@PathText, 7) COLLATE Latin1_General_100_CI_AS = N'strict '
        SET @PathText = LTRIM(SUBSTRING(@PathText, 8, 4000));

    SET @PathLength = CONVERT(int, LEN(@PathText));

    IF @PathLength = 0 OR SUBSTRING(@PathText, 1, 1) <> N'$'
        SET @Invalid = 1;
    ELSE
        SET @Position = 2;

    DECLARE @Segments TABLE
    (
          Ordinal int NOT NULL PRIMARY KEY
        , SegmentType char(1) NOT NULL
        , SegmentValue nvarchar(max) NULL
    );

    WHILE @Invalid = 0 AND @Position <= @PathLength
    BEGIN
        IF SUBSTRING(@PathText, @Position, 1) = N'.'
        BEGIN
            SET @Position += 1;

            IF @Position > @PathLength
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            IF SUBSTRING(@PathText, @Position, 1) = N'"'
            BEGIN
                SET @Start = @Position;
                SET @Scan = @Position + 1;
                SET @Escaped = 0;

                WHILE @Scan <= @PathLength
                BEGIN
                    IF @Escaped = 1
                        SET @Escaped = 0;
                    ELSE IF SUBSTRING(@PathText, @Scan, 1) = N'\'
                        SET @Escaped = 1;
                    ELSE IF SUBSTRING(@PathText, @Scan, 1) = N'"'
                        BREAK;

                    SET @Scan += 1;
                END;

                IF @Scan > @PathLength
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                SET @Literal =
                    SUBSTRING(@PathText, @Start, @Scan - @Start + 1);
                SET @Envelope = N'[' + @Literal + N']';

                -- ISJSON schützt OPENJSON vor einem Providerfehler und prüft
                -- zugleich Escapes einschließlich \uXXXX.
                IF ISJSON(@Envelope) <> 1
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                SELECT @Token = json_value.[value]
                FROM OPENJSON(@Envelope) AS json_value
                WHERE json_value.[key] = N'0'
                  AND json_value.[type] = 1;

                IF @Token IS NULL
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                INSERT @Segments (Ordinal, SegmentType, SegmentValue)
                VALUES (@SegmentOrdinal, 'P', @Token);

                SET @SegmentOrdinal += 1;
                SET @Position = @Scan + 1;
            END;
            ELSE
            BEGIN
                SET @Start = @Position;

                WHILE @Position <= @PathLength
                  AND SUBSTRING(@PathText, @Position, 1) NOT IN (N'.', N'[')
                    SET @Position += 1;

                SET @Token =
                    SUBSTRING(@PathText, @Start, @Position - @Start);

                -- Nicht quotierte V1-Schlüssel folgen der dokumentierten
                -- alphanumerischen SQL/JSON-Kurzform; weitere Zeichen und
                -- Unicode-Schlüssel werden in doppelten Anführungszeichen
                -- geschrieben.
                IF @Token = N''
                   OR PATINDEX
                      (
                          N'%[^0-9A-Za-z_]%',
                          @Token COLLATE Latin1_General_100_BIN2
                      ) > 0
                BEGIN
                    SET @Invalid = 1;
                    BREAK;
                END;

                INSERT @Segments (Ordinal, SegmentType, SegmentValue)
                VALUES (@SegmentOrdinal, 'P', @Token);

                SET @SegmentOrdinal += 1;
            END;
        END;
        ELSE IF SUBSTRING(@PathText, @Position, 1) = N'['
        BEGIN
            SET @Start = @Position + 1;
            SET @Scan = CHARINDEX(N']', @PathText, @Start);

            IF @Scan = 0
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            SET @Token = SUBSTRING(@PathText, @Start, @Scan - @Start);

            IF @Token = N'*'
                SET @SegmentType = 'W';
            ELSE IF @Token <> N''
                 AND PATINDEX
                     (
                         N'%[^0-9]%',
                         @Token COLLATE Latin1_General_100_BIN2
                     ) = 0
                 AND
                     (
                         @Token = N'0'
                         OR LEFT(@Token, 1) <> N'0'
                     )
                SET @SegmentType = 'I';
            ELSE
            BEGIN
                SET @Invalid = 1;
                BREAK;
            END;

            INSERT @Segments (Ordinal, SegmentType, SegmentValue)
            VALUES
            (
                  @SegmentOrdinal
                , @SegmentType
                , CASE WHEN @SegmentType = 'I' THEN @Token END
            );

            SET @SegmentOrdinal += 1;
            SET @Position = @Scan + 1;
        END;
        ELSE
        BEGIN
            SET @Invalid = 1;
            BREAK;
        END;
    END;

    IF @Invalid = 1
    BEGIN
        INSERT @Result (PathExists) VALUES (0);
        RETURN;
    END;

    -- Das zusätzliche Array macht auch skalare JSON-Werte auf SQL Server 2019
    -- prüfbar. Genau ein Element verhindert, dass eine kommaseparierte Folge
    -- fälschlich als einzelner JSON-Wert gilt.
    SET @Envelope = N'[' + @Json + N']';

    IF ISJSON(@Envelope) <> 1
    BEGIN
        INSERT @Result (PathExists) VALUES (0);
        RETURN;
    END;

    DECLARE @Frontier TABLE
    (
          JsonValue nvarchar(max) NULL
        , JsonType int NOT NULL
    );
    DECLARE @NextFrontier TABLE
    (
          JsonValue nvarchar(max) NULL
        , JsonType int NOT NULL
    );

    INSERT @Frontier (JsonValue, JsonType)
    SELECT json_value.[value], json_value.[type]
    FROM OPENJSON(@Envelope) AS json_value;

    IF (SELECT COUNT_BIG(*) FROM @Frontier) <> 1
    BEGIN
        INSERT @Result (PathExists) VALUES (0);
        RETURN;
    END;

    SET @SegmentCount = @SegmentOrdinal - 1;
    SET @SegmentOrdinal = 1;

    WHILE @SegmentOrdinal <= @SegmentCount
    BEGIN
        SELECT
              @SegmentType = segment.SegmentType
            , @Token = segment.SegmentValue
        FROM @Segments AS segment
        WHERE segment.Ordinal = @SegmentOrdinal;

        DELETE @NextFrontier;

        INSERT @NextFrontier (JsonValue, JsonType)
        SELECT child.[value], child.[type]
        FROM @Frontier AS parent
        CROSS APPLY OPENJSON
        (
            CASE
                WHEN parent.JsonType IN (4, 5) THEN parent.JsonValue
                ELSE N'{}'
            END
        ) AS child
        WHERE
            (
                @SegmentType = 'P'
                AND parent.JsonType = 5
                AND child.[key] COLLATE Latin1_General_100_BIN2 =
                    @Token COLLATE Latin1_General_100_BIN2
            )
            OR
            (
                @SegmentType = 'I'
                AND parent.JsonType = 4
                AND child.[key] COLLATE Latin1_General_100_BIN2 =
                    @Token COLLATE Latin1_General_100_BIN2
            )
            OR
            (
                @SegmentType = 'W'
                AND parent.JsonType = 4
            );

        DELETE @Frontier;

        INSERT @Frontier (JsonValue, JsonType)
        SELECT next_value.JsonValue, next_value.JsonType
        FROM @NextFrontier AS next_value;

        IF NOT EXISTS (SELECT 1 FROM @Frontier)
            BREAK;

        SET @SegmentOrdinal += 1;
    END;

    INSERT @Result (PathExists)
    SELECT CASE WHEN EXISTS (SELECT 1 FROM @Frontier) THEN 1 ELSE 0 END;

    RETURN;
END;
GO
