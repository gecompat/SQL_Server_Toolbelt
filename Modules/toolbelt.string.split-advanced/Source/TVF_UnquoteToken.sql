-- ============================================================================
-- Objekt:          toolbelt_string.TVF_UnquoteToken
-- Typ:             Multi-statement TVF; kanonischer bounded Transformationskern
-- Zweck:           Ein äußeres Quote-Paar entfernen und innere closing dekodieren
-- Vertrag:         Documentation/TVF_UnquoteToken.md; Freigabe 2026-10-01
-- Parameter:       Input/Qualifier/ClosingQualifier nvarchar(max), BackslashEscape bit
-- Defaults:        Qualifier=NULL (Auto), ClosingQualifier=NULL, BackslashEscape=0
-- Resultset:       Value nvarchar(max), IsValid bit, ErrorCode varchar(64), ErrorPosition bigint
-- Dependencies:    keine; keine Änderung des Split-Tokenizers
-- Rechte:          SELECT auf der TVF
-- Versionen:       SQL Server 2019/2022/2025; Compatibility >=150
-- Plattformen:     Windows/Linux; neue Runtime-Evidenz separat nachzuweisen
-- Fehlerverhalten: atomare Geschäftsfehlerzeile; Enginefehler bleiben unverändert
-- Performance:     bounded Scan; keine Streaming-/Parallelitätszusage
-- Einschränkungen: 65536 UTF-16-Codeeinheiten; kein CSV/Scalar-Wrapper
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_UnquoteToken]
(
      @Input nvarchar(max)
    , @Qualifier nvarchar(max) = NULL
    , @ClosingQualifier nvarchar(max) = NULL
    , @BackslashEscape bit = 0
)
RETURNS @Result TABLE
(
      Value nvarchar(max) NULL
    , IsValid bit NOT NULL
    , ErrorCode varchar(64) NULL
    , ErrorPosition bigint NULL
)
AS
BEGIN
    IF @Input IS NULL RETURN;
    DECLARE @Length bigint = DATALENGTH(@Input)/2,
            @QualifierLength bigint = DATALENGTH(@Qualifier)/2,
            @ClosingLength bigint = DATALENGTH(@ClosingQualifier)/2,
            @Opening int = UNICODE(@Qualifier COLLATE Latin1_General_100_BIN2),
            @Closing int = UNICODE(@ClosingQualifier COLLATE Latin1_General_100_BIN2),
            @Mode tinyint = CASE WHEN @Qualifier IS NULL THEN 0
                                WHEN DATALENGTH(@Qualifier)=0 THEN 1 ELSE 2 END,
            @Error varchar(64) = NULL, @ErrorPosition bigint = NULL,
            @Position bigint = 1, @Code int, @Next int,
            @EscapedEnd bit = 0, @Output nvarchar(max) = N'';
    SET @BackslashEscape = COALESCE(@BackslashEscape,0);

    -- Vollständige Konfiguration vor Inputlimit und Input-NUL prüfen.
    IF (@Mode<>2 AND @ClosingQualifier IS NOT NULL)
       OR (@Mode=2 AND (@QualifierLength<>1 OR @Opening=0 OR @Opening BETWEEN 55296 AND 57343))
       OR (@ClosingQualifier IS NOT NULL AND
           (@ClosingLength<>1 OR @Closing=0 OR @Closing BETWEEN 55296 AND 57343))
        SET @Error='INVALID_CONFIGURATION';
    IF @Error IS NULL AND @Mode=2 AND @ClosingQualifier IS NULL
    BEGIN
        IF @Opening IN (91,93) SELECT @Opening=91,@Closing=93;
        ELSE IF @Opening IN (8220,8221) SELECT @Opening=8220,@Closing=8221;
        ELSE IF @Opening=8222 SET @Closing=8220;
        ELSE SET @Closing=@Opening;
    END;
    IF @Error IS NULL AND @Mode=2 AND @BackslashEscape=1
       AND (@Opening=92 OR @Closing=92) SET @Error='INVALID_CONFIGURATION';
    IF @Error IS NULL AND @Length>65536 SET @Error='INPUT_LIMIT_EXCEEDED';
    WHILE @Error IS NULL AND @Position<=@Length
    BEGIN
        IF UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1))=0
            SELECT @Error='NUL_NOT_ALLOWED',@ErrorPosition=@Position;
        SET @Position+=1;
    END;

    -- Auto erkennt ausschließlich das erste Zeichen, ohne Trim oder globale Quotes.
    IF @Error IS NULL AND @Mode=0
    BEGIN
        SET @Opening=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1));
        SET @Closing=CASE @Opening WHEN 34 THEN 34 WHEN 39 THEN 39
                        WHEN 91 THEN 93 WHEN 8220 THEN 8221 WHEN 8222 THEN 8220 END;
    END;
    IF @Error IS NULL AND @Mode<>1
    BEGIN
        IF @Length<2 OR @Closing IS NULL
           OR UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1))<>@Opening
           OR UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Length,1))<>@Closing
        BEGIN
            IF @Mode=2
                SELECT @Error='OUTER_PAIR_REQUIRED',
                       @ErrorPosition=CASE WHEN @Length=0 THEN NULL WHEN @Length=1 THEN 1
                         WHEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1))<>@Opening THEN 1 ELSE @Length END;
            ELSE SET @Mode=1;
        END;
        ELSE IF @BackslashEscape=1
        BEGIN
            -- Randprüfung: erkannte Escapefolgen konsumieren zwei Originaleinheiten.
            -- Doubled closing hat hier keinen Einfluss auf das Escaped-End-Flag.
            SET @Position=2;
            WHILE @Position<=@Length
            BEGIN
                SET @Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1));
                SET @Next=CASE WHEN @Position<@Length THEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position+1,1)) END;
                IF @Code=92 AND @Next IN (@Opening,@Closing,92)
                BEGIN
                    IF @Position+1=@Length SET @EscapedEnd=1;
                    SET @Position+=2;
                END;
                ELSE SET @Position+=1;
            END;
            IF @EscapedEnd=1
            BEGIN
                IF @Mode=2 SELECT @Error='OUTER_PAIR_REQUIRED',@ErrorPosition=@Length;
                ELSE SET @Mode=1;
            END;
        END;
    END;

    IF @Error IS NULL AND @Mode=1 SET @Output=@Input;
    ELSE IF @Error IS NULL
    BEGIN
        -- Außenzeichen sind reserviert. Escape hat Vorrang vor doubled closing;
        -- ein Double darf das reservierte Endzeichen niemals als zweite Hälfte nutzen.
        SET @Position=2;
        DECLARE @SpanStart bigint=2;
        WHILE @Position<@Length AND @Error IS NULL
        BEGIN
            SET @Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1));
            SET @Next=CASE WHEN @Position+1<@Length THEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position+1,1)) END;
            IF (@BackslashEscape=1 AND @Code=92 AND @Next IN (@Opening,@Closing,92))
               OR (@Code=@Closing AND @Next=@Closing)
            BEGIN
                -- Nur an Transformationen kopieren, unveränderte Spans nicht pro Zeichen.
                SET @Output+=SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@SpanStart,@Position-@SpanStart)
                             +SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position+1,1);
                SET @Position+=2;
                SET @SpanStart=@Position;
            END;
            ELSE IF @Code=@Closing
                SELECT @Error='UNESCAPED_CLOSING_QUALIFIER',@ErrorPosition=@Position;
            ELSE SET @Position+=1;
        END;
        IF @Error IS NULL
            SET @Output+=SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@SpanStart,@Length-@SpanStart);
    END;
    IF @Error IS NULL INSERT @Result VALUES(@Output,1,NULL,NULL);
    ELSE INSERT @Result VALUES(NULL,0,@Error,@ErrorPosition);
    RETURN;
END;
GO
