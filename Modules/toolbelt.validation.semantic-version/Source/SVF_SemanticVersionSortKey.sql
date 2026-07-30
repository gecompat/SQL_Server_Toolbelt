CREATE OR ALTER FUNCTION [toolbelt_validation].[SVF_SemanticVersionSortKey]
(
    @Version varchar(8000)
)
RETURNS varbinary(max)
AS
BEGIN
    DECLARE
          @IsValid    bit
        , @Major      varchar(8000)
        , @Minor      varchar(8000)
        , @Patch      varchar(8000)
        , @PreRelease varchar(8000);

    SELECT
          @IsValid = IsValid
        , @Major = Major
        , @Minor = Minor
        , @Patch = Patch
        , @PreRelease = PreRelease
    FROM toolbelt_validation.TVF_ParseSemanticVersion(@Version);

    IF ISNULL(@IsValid, 0) = 0 RETURN NULL;

    DECLARE @Key varbinary(max) = 0x01;
    SET @Key = @Key
        + CONVERT(binary(2), CONVERT(smallint, DATALENGTH(@Major)))
        + CONVERT(varbinary(max), @Major) + 0x00
        + 0x01 + CONVERT(binary(2), CONVERT(smallint, DATALENGTH(@Minor)))
        + CONVERT(varbinary(max), @Minor) + 0x00
        + 0x01 + CONVERT(binary(2), CONVERT(smallint, DATALENGTH(@Patch)))
        + CONVERT(varbinary(max), @Patch) + 0x00;

    IF @PreRelease IS NULL RETURN @Key + 0x02;

    SET @Key = @Key + 0x01;
    DECLARE
          @Position int = 1
        , @NextDot int
        , @Identifier varchar(8000)
        , @Numeric bit;

    WHILE @Position <= DATALENGTH(@PreRelease)
    BEGIN
        SET @NextDot = CHARINDEX('.', @PreRelease, @Position);
        SET @Identifier = CASE WHEN @NextDot = 0
            THEN SUBSTRING(@PreRelease, @Position, DATALENGTH(@PreRelease) - @Position + 1)
            ELSE SUBSTRING(@PreRelease, @Position, @NextDot - @Position) END;
        SET @Numeric = CASE WHEN @Identifier COLLATE Latin1_General_100_BIN2
            NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END;

        IF @Numeric = 1
            SET @Key = @Key + 0x01
                + CONVERT(binary(2), CONVERT(smallint, DATALENGTH(@Identifier)))
                + CONVERT(varbinary(max), @Identifier) + 0x00;
        ELSE
            SET @Key = @Key + 0x02
                + CONVERT(varbinary(max), @Identifier) + 0x00;

        SET @Position = CASE WHEN @NextDot = 0
            THEN DATALENGTH(@PreRelease) + 1 ELSE @NextDot + 1 END;
    END;

    RETURN @Key + 0x00;
END;
GO
