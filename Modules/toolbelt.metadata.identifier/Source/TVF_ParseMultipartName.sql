SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- Objekt:          toolbelt_metadata.TVF_ParseMultipartName
-- Typ:             Multi-statement Table-valued Function
-- Zweck:           Zerlegt und validiert ein- bis vierteilige SQL-Namen.
-- Vertrag:         Documentation/TVF_ParseMultipartName.md
-- Parameter:       @MultipartName nvarchar(1035)
-- Resultset:       Eine Zeile mit Status, Teilen und sicher begrenztem Namen.
-- Dependencies:    Keine Modulabhängigkeit.
-- Rechte:          SELECT oder REFERENCES
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux
-- Fehlerverhalten: Ungültige Eingaben werden als ValidationCode zurückgegeben.
-- Performance:     Zustandsautomat mit linearer Laufzeit und maximal 1035 Zeichen.
-- Einschränkungen: Doppelte Anführungszeichen sind keine Identifier-Delimiter.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_metadata].[TVF_ParseMultipartName]
(
    @MultipartName nvarchar(1035)
)
RETURNS @Result TABLE
(
      IsValid        bit            NOT NULL
    , ValidationCode varchar(32)     NOT NULL
    , PartCount      tinyint         NULL
    , ServerName     sysname         NULL
    , DatabaseName   sysname         NULL
    , SchemaName     sysname         NULL
    , ObjectName     sysname         NULL
    , QuotedName     nvarchar(1035)  NULL
)
AS
BEGIN
    DECLARE
          @IsValid          bit = 1
        , @ValidationCode   varchar(32) = 'VALID'
        , @InputLength      int
        , @Position         int = 1
        , @PartOrdinal      tinyint = 1
        , @CurrentPart      nvarchar(1035) = N''
        , @Character        nchar(1)
        , @NextCharacter    nchar(1)
        , @InsideDelimited  bit = 0
        , @AfterDelimited   bit = 0
        , @PartIsDelimited  bit = 0;

    DECLARE @Parts TABLE
    (
          PartOrdinal tinyint         NOT NULL PRIMARY KEY
        , PartValue   nvarchar(1035)  NULL
        , IsDelimited bit             NOT NULL
        , IsOmitted   bit             NOT NULL
    );

    IF @MultipartName IS NULL
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'NULL_INPUT';
    END;
    ELSE
    BEGIN
        /*
         * Das angehängte Zeichen verhindert, dass LEN nachgestellte
         * Leerzeichen aus der Eingabelänge entfernt.
         */
        SET @InputLength = LEN(@MultipartName + N'#') - 1;

        IF @InputLength = 0
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'EMPTY_INPUT';
        END;
    END;

    WHILE @IsValid = 1 AND @Position <= @InputLength
    BEGIN
        SET @Character = SUBSTRING(@MultipartName, @Position, 1);
        SET @NextCharacter =
            CASE
                WHEN @Position < @InputLength
                    THEN SUBSTRING(@MultipartName, @Position + 1, 1)
                ELSE NULL
            END;

        IF UNICODE(@Character) < 32 OR UNICODE(@Character) = 127
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'CONTROL_CHARACTER';
        END;
        ELSE IF @InsideDelimited = 1
        BEGIN
            IF @Character = N']'
            BEGIN
                IF @NextCharacter = N']'
                BEGIN
                    SET @CurrentPart += N']';
                    SET @Position += 2;
                END;
                ELSE
                BEGIN
                    SET @InsideDelimited = 0;
                    SET @AfterDelimited = 1;
                    SET @Position += 1;
                END;
            END;
            ELSE
            BEGIN
                SET @CurrentPart += @Character;
                SET @Position += 1;
            END;
        END;
        ELSE IF @AfterDelimited = 1
        BEGIN
            IF @Character <> N'.'
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'TEXT_AFTER_DELIMITER';
            END;
            ELSE
            BEGIN
                INSERT INTO @Parts
                (
                      PartOrdinal
                    , PartValue
                    , IsDelimited
                    , IsOmitted
                )
                VALUES
                (
                      @PartOrdinal
                    , @CurrentPart
                    , 1
                    , 0
                );

                SET @PartOrdinal += 1;
                SET @CurrentPart = N'';
                SET @InsideDelimited = 0;
                SET @AfterDelimited = 0;
                SET @PartIsDelimited = 0;
                SET @Position += 1;
            END;
        END;
        ELSE IF @Character = N'.'
        BEGIN
            INSERT INTO @Parts
            (
                  PartOrdinal
                , PartValue
                , IsDelimited
                , IsOmitted
            )
            VALUES
            (
                  @PartOrdinal
                , NULLIF(@CurrentPart, N'')
                , @PartIsDelimited
                , CASE WHEN @CurrentPart = N'' THEN 1 ELSE 0 END
            );

            SET @PartOrdinal += 1;
            SET @CurrentPart = N'';
            SET @PartIsDelimited = 0;
            SET @Position += 1;
        END;
        ELSE IF @Character = N'['
        BEGIN
            IF @CurrentPart <> N''
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'BRACKET_SYNTAX';
            END;
            ELSE
            BEGIN
                SET @InsideDelimited = 1;
                SET @PartIsDelimited = 1;
                SET @Position += 1;
            END;
        END;
        ELSE IF @Character = N']'
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'BRACKET_SYNTAX';
        END;
        ELSE
        BEGIN
            /*
             * Ausdrucks- und Wildcard-Metazeichen sind in der unquoted Form
             * nicht Teil dieses Vertrags. Innerhalb von [...] bleiben sie
             * normale Identifierzeichen.
             */
            IF CHARINDEX
               (
                   @Character COLLATE Latin1_General_100_BIN2,
                   N'*%''";(),=+-/\:?!{}|&<>'
                       COLLATE Latin1_General_100_BIN2
               ) > 0
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'UNQUOTED_META_CHARACTER';
            END;
            ELSE
            BEGIN
                SET @CurrentPart += @Character;
                SET @Position += 1;
            END;
        END;

        IF LEN(@CurrentPart + N'#') - 1 > 128
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'PART_TOO_LONG';
        END;

        IF @PartOrdinal > 4
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'TOO_MANY_PARTS';
        END;
    END;

    IF @IsValid = 1 AND @InsideDelimited = 1
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'UNCLOSED_DELIMITER';
    END;

    IF @IsValid = 1
    BEGIN
        INSERT INTO @Parts
        (
              PartOrdinal
            , PartValue
            , IsDelimited
            , IsOmitted
        )
        VALUES
        (
              @PartOrdinal
            , CASE
                  WHEN @AfterDelimited = 1 THEN @CurrentPart
                  ELSE NULLIF(@CurrentPart, N'')
              END
            , @PartIsDelimited
            , CASE
                  WHEN @AfterDelimited = 0 AND @CurrentPart = N'' THEN 1
                  ELSE 0
              END
        );
    END;

    DECLARE @PartCount tinyint =
        CASE
            WHEN @IsValid = 1 THEN (SELECT COUNT(*) FROM @Parts)
            ELSE @PartOrdinal
        END;

    IF @IsValid = 1 AND @PartCount > 4
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'TOO_MANY_PARTS';
    END;

    IF @IsValid = 1
       AND EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE IsDelimited = 1
                 AND ISNULL(PartValue, N'') = N''
           )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'EMPTY_IDENTIFIER';
    END;

    IF @IsValid = 1
       AND EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE IsDelimited = 0
                 AND PartValue IS NOT NULL
                 AND
                 (
                     LEFT(PartValue, 1) = N' '
                     OR RIGHT(PartValue, 1) = N' '
                 )
           )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'OUTER_WHITESPACE';
    END;

    IF @IsValid = 1
       AND
       (
           EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE PartOrdinal IN (1, @PartCount)
                 AND IsOmitted = 1
           )
           OR EXISTS
              (
                  SELECT 1
                  FROM @Parts
                  WHERE IsOmitted = 1
                    AND
                    (
                        @PartCount < 3
                        OR PartOrdinal NOT BETWEEN 2 AND @PartCount - 1
                    )
              )
       )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'INVALID_OMISSION';
    END;

    DECLARE
          @Part1 sysname
        , @Part2 sysname
        , @Part3 sysname
        , @Part4 sysname
        , @ServerName sysname
        , @DatabaseName sysname
        , @SchemaName sysname
        , @ObjectName sysname
        , @QuotedName nvarchar(1035);

    IF @IsValid = 1
    BEGIN
        SELECT
              @Part1 = MAX(CASE WHEN PartOrdinal = 1 THEN PartValue END)
            , @Part2 = MAX(CASE WHEN PartOrdinal = 2 THEN PartValue END)
            , @Part3 = MAX(CASE WHEN PartOrdinal = 3 THEN PartValue END)
            , @Part4 = MAX(CASE WHEN PartOrdinal = 4 THEN PartValue END)
        FROM @Parts;

        SELECT
              @ServerName =
                  CASE WHEN @PartCount = 4 THEN @Part1 END
            , @DatabaseName =
                  CASE
                      WHEN @PartCount = 4 THEN @Part2
                      WHEN @PartCount = 3 THEN @Part1
                  END
            , @SchemaName =
                  CASE
                      WHEN @PartCount = 4 THEN @Part3
                      WHEN @PartCount = 3 THEN @Part2
                      WHEN @PartCount = 2 THEN @Part1
                  END
            , @ObjectName =
                  CASE @PartCount
                      WHEN 4 THEN @Part4
                      WHEN 3 THEN @Part3
                      WHEN 2 THEN @Part2
                      WHEN 1 THEN @Part1
                  END;

        SET @QuotedName =
            CASE @PartCount
                WHEN 1
                    THEN QUOTENAME(@Part1)
                WHEN 2
                    THEN QUOTENAME(@Part1) + N'.' + QUOTENAME(@Part2)
                WHEN 3
                    THEN QUOTENAME(@Part1) + N'.'
                       + COALESCE(QUOTENAME(@Part2), N'') + N'.'
                       + QUOTENAME(@Part3)
                WHEN 4
                    THEN QUOTENAME(@Part1) + N'.'
                       + COALESCE(QUOTENAME(@Part2), N'') + N'.'
                       + COALESCE(QUOTENAME(@Part3), N'') + N'.'
                       + QUOTENAME(@Part4)
            END;

        IF @QuotedName IS NULL OR @ObjectName IS NULL
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'INVALID_IDENTIFIER';
            SET @ServerName = NULL;
            SET @DatabaseName = NULL;
            SET @SchemaName = NULL;
            SET @ObjectName = NULL;
            SET @QuotedName = NULL;
        END;
    END;

    INSERT INTO @Result
    (
          IsValid
        , ValidationCode
        , PartCount
        , ServerName
        , DatabaseName
        , SchemaName
        , ObjectName
        , QuotedName
    )
    VALUES
    (
          @IsValid
        , @ValidationCode
        , @PartCount
        , CASE WHEN @IsValid = 1 THEN @ServerName END
        , CASE WHEN @IsValid = 1 THEN @DatabaseName END
        , CASE WHEN @IsValid = 1 THEN @SchemaName END
        , CASE WHEN @IsValid = 1 THEN @ObjectName END
        , CASE WHEN @IsValid = 1 THEN @QuotedName END
    );

    RETURN;
END;
GO
