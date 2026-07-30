CREATE OR ALTER FUNCTION [toolbelt_validation].[SVF_CompareSemanticVersion]
(
      @LeftVersion  varchar(8000)
    , @RightVersion varchar(8000)
)
RETURNS smallint
AS
BEGIN
    DECLARE @Parsed TABLE
    (
          Side             tinyint       NOT NULL
        , IsValid          bit           NOT NULL
        , Major            varchar(8000) NULL
        , Minor            varchar(8000) NULL
        , Patch            varchar(8000) NULL
        , PreRelease       varchar(8000) NULL
    );

    INSERT INTO @Parsed (Side, IsValid, Major, Minor, Patch, PreRelease)
    SELECT 1, IsValid, Major, Minor, Patch, PreRelease
    FROM toolbelt_validation.TVF_ParseSemanticVersion(@LeftVersion)
    UNION ALL
    SELECT 2, IsValid, Major, Minor, Patch, PreRelease
    FROM toolbelt_validation.TVF_ParseSemanticVersion(@RightVersion);

    IF EXISTS (SELECT 1 FROM @Parsed WHERE IsValid = 0)
        RETURN NULL;

    DECLARE
          @Left      varchar(8000)
        , @Right     varchar(8000)
        , @Component tinyint = 1
        , @Result    smallint = 0;

    WHILE @Component <= 3 AND @Result = 0
    BEGIN
        SELECT
            @Left = CASE @Component
                WHEN 1 THEN Major WHEN 2 THEN Minor ELSE Patch END
        FROM @Parsed WHERE Side = 1;
        SELECT
            @Right = CASE @Component
                WHEN 1 THEN Major WHEN 2 THEN Minor ELSE Patch END
        FROM @Parsed WHERE Side = 2;

        IF DATALENGTH(@Left) < DATALENGTH(@Right) SET @Result = -1;
        ELSE IF DATALENGTH(@Left) > DATALENGTH(@Right) SET @Result = 1;
        ELSE IF @Left COLLATE Latin1_General_100_BIN2
                  < @Right COLLATE Latin1_General_100_BIN2 SET @Result = -1;
        ELSE IF @Left COLLATE Latin1_General_100_BIN2
                  > @Right COLLATE Latin1_General_100_BIN2 SET @Result = 1;

        SET @Component += 1;
    END;

    IF @Result <> 0 RETURN @Result;

    DECLARE
          @LeftPre   varchar(8000)
        , @RightPre  varchar(8000)
        , @LeftPos   int = 1
        , @RightPos  int = 1
        , @LeftDot   int
        , @RightDot  int
        , @LeftId    varchar(8000)
        , @RightId   varchar(8000)
        , @LeftEnd   bit
        , @RightEnd  bit
        , @LeftNumeric bit
        , @RightNumeric bit;

    SELECT @LeftPre = PreRelease FROM @Parsed WHERE Side = 1;
    SELECT @RightPre = PreRelease FROM @Parsed WHERE Side = 2;

    IF @LeftPre IS NULL AND @RightPre IS NULL RETURN 0;
    IF @LeftPre IS NULL RETURN 1;
    IF @RightPre IS NULL RETURN -1;

    WHILE @Result = 0
    BEGIN
        SET @LeftEnd = CASE WHEN @LeftPos > DATALENGTH(@LeftPre) THEN 1 ELSE 0 END;
        SET @RightEnd = CASE WHEN @RightPos > DATALENGTH(@RightPre) THEN 1 ELSE 0 END;
        IF @LeftEnd = 1 AND @RightEnd = 1 BREAK;
        IF @LeftEnd = 1 RETURN -1;
        IF @RightEnd = 1 RETURN 1;

        SET @LeftDot = CHARINDEX('.', @LeftPre, @LeftPos);
        SET @RightDot = CHARINDEX('.', @RightPre, @RightPos);
        SET @LeftId = CASE WHEN @LeftDot = 0
            THEN SUBSTRING(@LeftPre, @LeftPos, DATALENGTH(@LeftPre) - @LeftPos + 1)
            ELSE SUBSTRING(@LeftPre, @LeftPos, @LeftDot - @LeftPos) END;
        SET @RightId = CASE WHEN @RightDot = 0
            THEN SUBSTRING(@RightPre, @RightPos, DATALENGTH(@RightPre) - @RightPos + 1)
            ELSE SUBSTRING(@RightPre, @RightPos, @RightDot - @RightPos) END;
        SET @LeftNumeric = CASE WHEN @LeftId COLLATE Latin1_General_100_BIN2
            NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;
        SET @RightNumeric = CASE WHEN @RightId COLLATE Latin1_General_100_BIN2
            NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;

        IF @LeftNumeric = 1 AND @RightNumeric = 0 SET @Result = -1;
        ELSE IF @LeftNumeric = 0 AND @RightNumeric = 1 SET @Result = 1;
        ELSE IF @LeftNumeric = 1
        BEGIN
            IF DATALENGTH(@LeftId) < DATALENGTH(@RightId) SET @Result = -1;
            ELSE IF DATALENGTH(@LeftId) > DATALENGTH(@RightId) SET @Result = 1;
            ELSE IF @LeftId COLLATE Latin1_General_100_BIN2
                      < @RightId COLLATE Latin1_General_100_BIN2 SET @Result = -1;
            ELSE IF @LeftId COLLATE Latin1_General_100_BIN2
                      > @RightId COLLATE Latin1_General_100_BIN2 SET @Result = 1;
        END;
        ELSE
        BEGIN
            IF @LeftId COLLATE Latin1_General_100_BIN2
                  < @RightId COLLATE Latin1_General_100_BIN2 SET @Result = -1;
            ELSE IF @LeftId COLLATE Latin1_General_100_BIN2
                  > @RightId COLLATE Latin1_General_100_BIN2 SET @Result = 1;
        END;

        SET @LeftPos = CASE WHEN @LeftDot = 0
            THEN DATALENGTH(@LeftPre) + 1 ELSE @LeftDot + 1 END;
        SET @RightPos = CASE WHEN @RightDot = 0
            THEN DATALENGTH(@RightPre) + 1 ELSE @RightDot + 1 END;
    END;

    RETURN @Result;
END;
GO
