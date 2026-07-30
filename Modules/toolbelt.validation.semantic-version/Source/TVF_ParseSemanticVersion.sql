CREATE OR ALTER FUNCTION [toolbelt_validation].[TVF_ParseSemanticVersion]
(
    @Version varchar(8000)
)
RETURNS @Result TABLE
(
      IsValid          bit           NOT NULL
    , ValidationCode   varchar(32)   NOT NULL
    , Major            varchar(8000) NULL
    , Minor            varchar(8000) NULL
    , Patch            varchar(8000) NULL
    , PreRelease       varchar(8000) NULL
    , BuildMetadata    varchar(8000) NULL
    , CanonicalVersion varchar(8000) NULL
)
AS
BEGIN
    DECLARE
          @Code       varchar(32) = 'VALID'
        , @InputLength int = DATALENGTH(@Version)
        , @PlusPos      int
        , @DashPos      int
        , @Dot1         int
        , @Dot2         int
        , @Precedence   varchar(8000)
        , @Major        varchar(8000)
        , @Minor        varchar(8000)
        , @Patch        varchar(8000)
        , @PreRelease   varchar(8000)
        , @Build        varchar(8000)
        , @Position     int
        , @NextDot      int
        , @Identifier   varchar(8000);

    IF @Version IS NULL
        SET @Code = 'NULL_INPUT';
    ELSE IF @InputLength = 0
        SET @Code = 'EMPTY_INPUT';
    ELSE IF @Version COLLATE Latin1_General_100_BIN2
                 LIKE '%[^0-9A-Za-z.+-]%' COLLATE Latin1_General_100_BIN2
        SET @Code = 'INVALID_CHARACTER';

    IF @Code = 'VALID'
    BEGIN
        SET @PlusPos = CHARINDEX('+', @Version COLLATE Latin1_General_100_BIN2);

        IF @PlusPos > 0
           AND CHARINDEX
               (
                   '+',
                   @Version COLLATE Latin1_General_100_BIN2,
                   @PlusPos + 1
               ) > 0
            SET @Code = 'BUILD_FORMAT';
        ELSE
        BEGIN
            SET @Precedence =
                CASE WHEN @PlusPos = 0
                    THEN @Version
                    ELSE LEFT(@Version, @PlusPos - 1)
                END;
            SET @Build =
                CASE WHEN @PlusPos = 0
                    THEN NULL
                    ELSE SUBSTRING
                         (
                             @Version,
                             @PlusPos + 1,
                             @InputLength - @PlusPos
                         )
                END;

            IF @PlusPos > 0 AND DATALENGTH(@Build) = 0
                SET @Code = 'EMPTY_BUILD';
        END;
    END;

    IF @Code = 'VALID'
    BEGIN
        SET @DashPos =
            CHARINDEX('-', @Precedence COLLATE Latin1_General_100_BIN2);
        SET @PreRelease =
            CASE WHEN @DashPos = 0
                THEN NULL
                ELSE SUBSTRING
                     (
                         @Precedence,
                         @DashPos + 1,
                         DATALENGTH(@Precedence) - @DashPos
                     )
            END;
        SET @Precedence =
            CASE WHEN @DashPos = 0
                THEN @Precedence
                ELSE LEFT(@Precedence, @DashPos - 1)
            END;

        IF @DashPos > 0 AND DATALENGTH(@PreRelease) = 0
            SET @Code = 'EMPTY_PRERELEASE';
    END;

    IF @Code = 'VALID'
    BEGIN
        SET @Dot1 = CHARINDEX('.', @Precedence COLLATE Latin1_General_100_BIN2);
        SET @Dot2 =
            CASE WHEN @Dot1 = 0 THEN 0
                 ELSE CHARINDEX
                      (
                          '.',
                          @Precedence COLLATE Latin1_General_100_BIN2,
                          @Dot1 + 1
                      )
            END;

        IF @Dot1 = 0
           OR @Dot2 = 0
           OR CHARINDEX
              (
                  '.',
                  @Precedence COLLATE Latin1_General_100_BIN2,
                  @Dot2 + 1
              ) > 0
            SET @Code = 'CORE_FORMAT';
        ELSE
        BEGIN
            SET @Major = LEFT(@Precedence, @Dot1 - 1);
            SET @Minor = SUBSTRING(@Precedence, @Dot1 + 1, @Dot2 - @Dot1 - 1);
            SET @Patch = SUBSTRING
            (
                @Precedence,
                @Dot2 + 1,
                DATALENGTH(@Precedence) - @Dot2
            );

            IF DATALENGTH(@Major) = 0
               OR DATALENGTH(@Minor) = 0
               OR DATALENGTH(@Patch) = 0
               OR @Major COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
               OR @Minor COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
               OR @Patch COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'CORE_FORMAT';
            ELSE IF (DATALENGTH(@Major) > 1 AND LEFT(@Major, 1) = '0')
                 OR (DATALENGTH(@Minor) > 1 AND LEFT(@Minor, 1) = '0')
                 OR (DATALENGTH(@Patch) > 1 AND LEFT(@Patch, 1) = '0')
                SET @Code = 'CORE_LEADING_ZERO';
        END;
    END;

    IF @Code = 'VALID' AND @PreRelease IS NOT NULL
    BEGIN
        IF RIGHT(@PreRelease, 1) = '.'
            SET @Code = 'PRERELEASE_FORMAT';
        SET @Position = 1;
        WHILE @Position <= DATALENGTH(@PreRelease) AND @Code = 'VALID'
        BEGIN
            SET @NextDot = CHARINDEX
            (
                '.',
                @PreRelease COLLATE Latin1_General_100_BIN2,
                @Position
            );
            SET @Identifier =
                CASE WHEN @NextDot = 0
                    THEN SUBSTRING
                         (
                             @PreRelease,
                             @Position,
                             DATALENGTH(@PreRelease) - @Position + 1
                         )
                    ELSE SUBSTRING
                         (
                             @PreRelease,
                             @Position,
                             @NextDot - @Position
                         )
                END;

            IF DATALENGTH(@Identifier) = 0
               OR @Identifier COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9A-Za-z-]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'PRERELEASE_FORMAT';
            ELSE IF @Identifier COLLATE Latin1_General_100_BIN2
                          NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
                    AND DATALENGTH(@Identifier) > 1
                    AND LEFT(@Identifier, 1) = '0'
                SET @Code = 'PRERELEASE_LEADING_ZERO';

            SET @Position =
                CASE WHEN @NextDot = 0
                    THEN DATALENGTH(@PreRelease) + 1
                    ELSE @NextDot + 1
                END;
        END;
    END;

    IF @Code = 'VALID' AND @Build IS NOT NULL
    BEGIN
        IF RIGHT(@Build, 1) = '.'
            SET @Code = 'BUILD_FORMAT';
        SET @Position = 1;
        WHILE @Position <= DATALENGTH(@Build) AND @Code = 'VALID'
        BEGIN
            SET @NextDot = CHARINDEX
            (
                '.',
                @Build COLLATE Latin1_General_100_BIN2,
                @Position
            );
            SET @Identifier =
                CASE WHEN @NextDot = 0
                    THEN SUBSTRING
                         (
                             @Build,
                             @Position,
                             DATALENGTH(@Build) - @Position + 1
                         )
                    ELSE SUBSTRING
                         (
                             @Build,
                             @Position,
                             @NextDot - @Position
                         )
                END;

            IF DATALENGTH(@Identifier) = 0
               OR @Identifier COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9A-Za-z-]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'BUILD_FORMAT';

            SET @Position =
                CASE WHEN @NextDot = 0
                    THEN DATALENGTH(@Build) + 1
                    ELSE @NextDot + 1
                END;
        END;
    END;

    INSERT INTO @Result
    (
          IsValid
        , ValidationCode
        , Major
        , Minor
        , Patch
        , PreRelease
        , BuildMetadata
        , CanonicalVersion
    )
    VALUES
    (
          CASE WHEN @Code = 'VALID' THEN 1 ELSE 0 END
        , @Code
        , CASE WHEN @Code = 'VALID' THEN @Major END
        , CASE WHEN @Code = 'VALID' THEN @Minor END
        , CASE WHEN @Code = 'VALID' THEN @Patch END
        , CASE WHEN @Code = 'VALID' THEN @PreRelease END
        , CASE WHEN @Code = 'VALID' THEN @Build END
        , CASE WHEN @Code = 'VALID' THEN @Version END
    );

    RETURN;
END;
GO
