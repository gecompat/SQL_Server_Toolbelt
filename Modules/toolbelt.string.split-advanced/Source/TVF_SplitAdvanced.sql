-- ============================================================================
-- Objekt:          toolbelt_string.TVF_SplitAdvanced
-- Typ:             Multi-statement TVF; kanonischer zustandsbasierter Kern
-- Zweck:           Originaltokens an mehreren Separatorstrings zerlegen
-- Vertrag:         Documentation/TVF_SplitAdvanced.md; S2-Freigabe 2026-10-01
-- Parameter:       Input/SeparatorsJson/Quote/Escape nvarchar(max), KeepEmpty bit
-- Defaults:        Quote=N'"', Escape=N'\', KeepEmpty=1
-- Resultset:       Value, Ordinal, IsValid, ErrorCode, ErrorPosition
-- Dependencies:    keine; OPENJSON erfordert Compatibility Level >=150 im Scope
-- Rechte:          SELECT auf der TVF
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux
-- Fehlerverhalten: eine Geschäftsfehlerzeile, keine Teiltokens; Enginefehler bleiben
-- Performance:     begrenzter sequenzieller Scan; materialisierte Tabellenvariablen
-- Einschränkungen: UTF-16-Codeeinheiten, kein CSV/Unquoting/Parallelitätsversprechen
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitAdvanced]
(
      @Input nvarchar(max)
    , @SeparatorsJson nvarchar(max)
    , @Quote nvarchar(max) = N'"'
    , @Escape nvarchar(max) = N'\'
    , @KeepEmpty bit = 1
)
RETURNS @Result TABLE
(
      Value nvarchar(max) NULL
    , Ordinal bigint NULL
    , IsValid bit NOT NULL
    , ErrorCode varchar(64) NULL
    , ErrorPosition bigint NULL
)
AS
BEGIN
    -- NULL ist ein früher No-op, selbst bei ungültiger Konfiguration.
    IF @Input IS NULL RETURN;

    DECLARE @InputLength bigint = DATALENGTH(@Input) / 2,
            @JsonLength bigint = DATALENGTH(@SeparatorsJson) / 2,
            @QuoteLength bigint = DATALENGTH(@Quote) / 2,
            @EscapeLength bigint = DATALENGTH(@Escape) / 2,
            @Error varchar(64) = NULL, @ErrorPosition bigint = NULL,
            @Position bigint = 1, @Character int, @SeparatorOrdinal int,
            @SeparatorCount int, @Separator nvarchar(max), @SeparatorLength bigint,
            @JsonType int, @QuoteCode int = UNICODE(@Quote COLLATE Latin1_General_100_BIN2),
            @EscapeCode int = UNICODE(@Escape COLLATE Latin1_General_100_BIN2);

    IF @SeparatorsJson IS NULL OR @Quote IS NULL OR @Escape IS NULL
        SET @Error = 'INVALID_CONFIGURATION';
    ELSE IF @InputLength > 65536 SET @Error = 'INPUT_LIMIT_EXCEEDED';
    ELSE IF @JsonLength > 16384 SET @Error = 'JSON_LIMIT_EXCEEDED';
    ELSE IF @QuoteLength > 1 OR @EscapeLength > 1 SET @Error = 'INVALID_CONFIGURATION';

    DECLARE @Separators TABLE
    (
        SeparatorOrdinal int NOT NULL PRIMARY KEY,
        Separator nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        SeparatorLength bigint NULL,
        JsonType int NOT NULL
    );

    IF @Error IS NULL
    BEGIN
        -- Syntax zuerst prüfen: OPENJSON darf keine erwartete ungültige Eingabe sehen.
        IF ISJSON(@SeparatorsJson) <> 1 SET @Error = 'INVALID_SEPARATOR_JSON';
        ELSE
        BEGIN
            SET @Position = 1;
            WHILE @Position <= @JsonLength
              AND UNICODE(SUBSTRING(@SeparatorsJson COLLATE Latin1_General_100_BIN2, @Position, 1)) IN (9,10,13,32)
                SET @Position += 1;
            IF SUBSTRING(@SeparatorsJson COLLATE Latin1_General_100_BIN2, @Position, 1) <> N'['
                SET @Error = 'INVALID_SEPARATOR_JSON';
        END;
    END;
    IF @Error IS NULL
    BEGIN
        INSERT @Separators (SeparatorOrdinal, Separator, SeparatorLength, JsonType)
        SELECT CONVERT(int, [key]) + 1, value, DATALENGTH(value) / 2, type
        FROM OPENJSON(@SeparatorsJson);
        SET @SeparatorCount = (SELECT COUNT(*) FROM @Separators);
        IF @SeparatorCount = 0 SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @SeparatorCount > 16 SET @Error = 'SEPARATOR_LIMIT_EXCEEDED';
    END;

    -- Validierung exakt in Arrayreihenfolge, vor allen Steuerzeichenkonflikten.
    SET @SeparatorOrdinal = 1;
    WHILE @Error IS NULL AND @SeparatorOrdinal <= @SeparatorCount
    BEGIN
        SELECT @Separator = Separator, @SeparatorLength = SeparatorLength, @JsonType = JsonType
        FROM @Separators WHERE SeparatorOrdinal = @SeparatorOrdinal;
        IF @JsonType <> 1 SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @SeparatorLength = 0 SET @Error = 'EMPTY_SEPARATOR';
        ELSE IF @SeparatorLength > 64 SET @Error = 'SEPARATOR_LIMIT_EXCEEDED';
        ELSE
        BEGIN
            SET @Position = 1;
            WHILE @Position <= @SeparatorLength AND @Error IS NULL
            BEGIN
                IF UNICODE(SUBSTRING(@Separator COLLATE Latin1_General_100_BIN2, @Position, 1)) = 0
                    SET @Error = 'NUL_NOT_ALLOWED';
                SET @Position += 1;
            END;
            -- Binäre Bytes statt SQL-Textgleichheit: nachfolgende Spaces sind relevant.
            IF @Error IS NULL AND EXISTS
            (
                SELECT 1 FROM @Separators WHERE SeparatorOrdinal < @SeparatorOrdinal
                AND CONVERT(varbinary(max), Separator) = CONVERT(varbinary(max), @Separator)
            ) SET @Error = 'DUPLICATE_SEPARATOR';
        END;
        SET @SeparatorOrdinal += 1;
    END;

    IF @Error IS NULL
    BEGIN
        IF (@QuoteLength = 1 AND @QuoteCode = 0) OR (@EscapeLength = 1 AND @EscapeCode = 0)
            SET @Error = 'NUL_NOT_ALLOWED';
        ELSE IF (@QuoteLength = 1 AND @QuoteCode BETWEEN 55296 AND 57343)
             OR (@EscapeLength = 1 AND @EscapeCode BETWEEN 55296 AND 57343)
            SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @QuoteLength = 1 AND @EscapeLength = 1 AND @QuoteCode = @EscapeCode
            SET @Error = 'INVALID_CONFIGURATION';
    END;
    SET @SeparatorOrdinal = 1;
    WHILE @Error IS NULL AND @SeparatorOrdinal <= @SeparatorCount
    BEGIN
        SELECT @Separator = Separator, @SeparatorLength = SeparatorLength
        FROM @Separators WHERE SeparatorOrdinal = @SeparatorOrdinal;
        SET @Position = 1;
        WHILE @Position <= @SeparatorLength AND @Error IS NULL
        BEGIN
            SET @Character = UNICODE(SUBSTRING(@Separator COLLATE Latin1_General_100_BIN2, @Position, 1));
            IF (@QuoteLength = 1 AND @Character = @QuoteCode)
              OR (@EscapeLength = 1 AND @Character = @EscapeCode)
                SET @Error = 'INVALID_CONFIGURATION';
            SET @Position += 1;
        END;
        SET @SeparatorOrdinal += 1;
    END;

    -- NUL-Prüfung geht Parserfehlern vor; Position bleibt auf den Originalinput bezogen.
    SET @Position = 1;
    WHILE @Error IS NULL AND @Position <= @InputLength
    BEGIN
        IF UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, 1)) = 0
        BEGIN
            SET @Error = 'NUL_NOT_ALLOWED';
            SET @ErrorPosition = @Position;
        END;
        SET @Position += 1;
    END;

    DECLARE @Tokens TABLE (TokenOrdinal bigint NOT NULL PRIMARY KEY, TokenStart bigint NOT NULL, TokenLength bigint NOT NULL);
    DECLARE @TokenStart bigint = 1, @TokenOrdinal bigint = 1,
            @QuoteStart bigint = NULL, @MatchedLength bigint;
    SET @Position = 1;
    WHILE @Error IS NULL AND @Position <= @InputLength
    BEGIN
        SET @Character = UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, 1));
        IF @EscapeLength = 1 AND @Character = @EscapeCode
        BEGIN
            IF @Position = @InputLength
            BEGIN
                SET @Error = 'DANGLING_ESCAPE';
                SET @ErrorPosition = @Position;
            END;
            -- Auch vor High Surrogate nur eine Codeeinheit schützen; Originaltext bleibt.
            SET @Position += 2;
        END;
        ELSE IF @QuoteLength = 1 AND @Character = @QuoteCode
        BEGIN
            SET @QuoteStart = CASE WHEN @QuoteStart IS NULL THEN @Position ELSE NULL END;
            SET @Position += 1;
        END;
        ELSE
        BEGIN
            SET @MatchedLength = NULL;
            IF @QuoteStart IS NULL
                SELECT @MatchedLength = MAX(SeparatorLength)
                FROM @Separators
                WHERE @Position + SeparatorLength - 1 <= @InputLength
                  AND SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, SeparatorLength) = Separator;
            IF @MatchedLength IS NOT NULL
            BEGIN
                INSERT @Tokens VALUES (@TokenOrdinal, @TokenStart, @Position - @TokenStart);
                SET @TokenOrdinal += 1;
                SET @Position += @MatchedLength;
                SET @TokenStart = @Position;
            END;
            ELSE SET @Position += 1;
        END;
    END;
    IF @Error IS NULL AND @QuoteStart IS NOT NULL
    BEGIN
        SET @Error = 'UNTERMINATED_QUOTE';
        SET @ErrorPosition = @QuoteStart;
    END;
    IF @Error IS NOT NULL
        INSERT @Result VALUES (NULL, NULL, 0, @Error, @ErrorPosition);
    ELSE
    BEGIN
        INSERT @Tokens VALUES (@TokenOrdinal, @TokenStart, @InputLength - @TokenStart + 1);
        -- Erst hier Tokens publizieren: spätes Parserproblem darf keine Teilwerte liefern.
        INSERT @Result (Value, Ordinal, IsValid, ErrorCode, ErrorPosition)
        SELECT SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, TokenStart, TokenLength),
               ROW_NUMBER() OVER (ORDER BY TokenOrdinal), 1, NULL, NULL
        FROM @Tokens WHERE COALESCE(@KeepEmpty, 1) = 1 OR TokenLength > 0;
    END;
    RETURN;
END;
GO
