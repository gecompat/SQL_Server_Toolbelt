-- ============================================================================
-- Objekt:          toolbelt_json.TVF_ResolveJsonPointer
-- Typ:             Multi-statement Table-valued Function (TF)
-- Zweck:           Einen RFC6901-Pointer lesend gegen ein vollständiges JSON auflösen.
-- Vertrag:         Documentation/Architecture/JSON_POINTER_CONTRACT.md, 1.0.0
-- Parameter:       @Json/@Pointer nvarchar(max); @MaxInputBytes bigint=16777216;
--                  @MaxDepth int=128; beide Budgets positiv und nur absenkbar
-- Resultset:       Status varchar(16) NOT NULL; JsonType varchar(8) NULL;
--                  Value nvarchar(max) NULL; ErrorCode varchar(32) NULL; BIN2
-- Dependencies:    Keine Module, Tabellen, Helper oder CLR-Assembly; ISJSON/OPENJSON
-- Rechte:          SELECT auf der Funktion; keine Daten-, Rechte- oder Servermutation
-- Versionen:       SQL Server 2019, 2022 und 2025, Compatibility Level mindestens150
-- Plattformen:     Windows und Linux; jeweilige native Abnahme separat
-- Fehlerverhalten: Genau eine Zeile; keine Enginefehlertexte oder Input-Echos.
--                  SQL_NULL, Parameter, Limits, Pointer, JSON-Syntax, Tiefe,
--                  Dokument-Unicode und erst danach Traversal bestimmen die Priorität.
-- Performance:     Ein vollständiger Policy-Scan in festen Chunks; bis MaxDepth
--                  Containerenumerationen mit wiederholter Fragmentprüfung/-kopie.
--                  Kein Heap-, Laufzeit- oder APPLY-Performanceversprechen.
-- Einschränkungen: Pointer höchstens4000 UTF-16-Einheiten; kein URIfragment/Patch.
--                  MSTVF wegen sequenzieller Unicode-/Traversalzustände und expliziter
--                  sicherer Parseroperanden; keine behauptete Inline-Alternative.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_json.TVF_ResolveJsonPointer
(
    @Json nvarchar(max),
    @Pointer nvarchar(max),
    @MaxInputBytes bigint=16777216,
    @MaxDepth int=128
)
RETURNS @Result TABLE
(
    Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
    JsonType varchar(8) COLLATE Latin1_General_100_BIN2 NULL,
    Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2 NULL
)
AS
BEGIN
    IF @Json IS NULL OR @Pointer IS NULL
    BEGIN
        INSERT @Result VALUES('SQL_NULL',NULL,NULL,NULL);
        RETURN;
    END;
    IF @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>16777216
       OR @MaxDepth IS NULL OR @MaxDepth<1 OR @MaxDepth>128
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'PARAMETER');
        RETURN;
    END;
    IF DATALENGTH(@Json)>@MaxInputBytes
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'INPUT_LIMIT');
        RETURN;
    END;
    IF DATALENGTH(@Pointer)>8000
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'POINTER_LIMIT');
        RETURN;
    END;

    DECLARE @PointerUnits int=CONVERT(int,DATALENGTH(@Pointer)/2),
            @JsonUnits int=CONVERT(int,DATALENGTH(@Json)/2),
            @Position int=1,@Unit int,@NextUnit int,@PendingHigh bit=0,
            @PointerSyntax bit=0,@UnicodeFault bit=0;
    IF @PointerUnits>0 AND UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,1,1))<>47
        SET @PointerSyntax=1;
    -- Originale Codeeinheiten prüfen: ~-Syntax und Unicode gelten für den ganzen
    -- Pointer, auch wenn ein früherer Traversalschritt später MISSING ergeben würde.
    WHILE @Position<=@PointerUnits
    BEGIN
        SET @Unit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1));
        IF @Unit=126
        BEGIN
            SET @NextUnit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position+1,1));
            IF @NextUnit IS NULL OR @NextUnit NOT IN(48,49) SET @PointerSyntax=1;
        END;
        IF @PendingHigh=1
        BEGIN
            IF @Unit NOT BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
            SET @PendingHigh=0;
        END
        ELSE IF @Unit BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
        IF @Unit BETWEEN 55296 AND 56319 SET @PendingHigh=1;
        SET @Position+=1;
    END;
    IF @PendingHigh=1 SET @UnicodeFault=1;
    IF @PointerSyntax=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'POINTER_SYNTAX');
        RETURN;
    END;
    IF @UnicodeFault=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'UNICODE');
        RETURN;
    END;

    DECLARE @Current nvarchar(max)=NULL,@CurrentType int=NULL,
            @SafeJson nvarchar(max)=N'[]',@RootCount bigint=0,
            @Chunk nvarchar(4000),@ChunkStart int=0,@ChunkUnits int=0;
    -- ISJSON bleibt die einzige JSON-Grammatik. Containerroots werden direkt
    -- geprüft, damit kein künstlicher Wrapper die vereinbarte Tiefe erhöht.
    IF ISJSON(@Json)=1
    BEGIN
        SET @Current=@Json;
        SET @Position=1;
        WHILE @Position<=@JsonUnits
        BEGIN
            IF @Position>=@ChunkStart+@ChunkUnits
            BEGIN
                SET @Chunk=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position,4000);
                SET @ChunkStart=@Position;
                SET @ChunkUnits=CONVERT(int,DATALENGTH(@Chunk)/2);
            END;
            SET @Unit=UNICODE(SUBSTRING(@Chunk COLLATE Latin1_General_100_BIN2,@Position-@ChunkStart+1,1));
            IF @Unit NOT IN(9,10,13,32) BREAK;
            SET @Position+=1;
        END;
        SET @CurrentType=CASE WHEN @Unit=91 THEN 4 ELSE 5 END;
    END
    ELSE
    BEGIN
        -- Max-Typ vor Konkatenation, nach Input-Precharge. OPENJSON bekommt
        -- erst in einem separaten, erfolgreichen IF-Zweig den gültigen Wrapper.
        DECLARE @Wrapper nvarchar(max)=CAST(N'[' AS nvarchar(max))+@Json+N']';
        IF ISJSON(@Wrapper)<>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
        SET @SafeJson=@Wrapper;
        SELECT @RootCount=COUNT_BIG(*),@Current=MAX([value]),@CurrentType=MAX([type])
        FROM OPENJSON(@SafeJson);
        IF @RootCount<>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'JSON_SYNTAX');
            RETURN;
        END;
    END;

    -- Nach der nativen Syntaxprüfung nur Policy prüfen: String-/Escapegrenzen,
    -- gleichzeitig offene Container und decodierte UTF-16-Paare. Keine zweite
    -- Number-, Literal-, Member- oder Separatorgrammatik. Der Originaltext wird
    -- vorwärts in4000-Einheiten-Chunks gelesen, nie als schrumpfender Rest kopiert.
    DECLARE @InsideString bit=0,@Depth int=0,@Advance int,@HexText nvarchar(4),
            @HexPosition int,@HexUnit int;
    SET @Position=1;
    SET @ChunkStart=0;
    SET @ChunkUnits=0;
    SET @PendingHigh=0;
    SET @UnicodeFault=0;
    WHILE @Position<=@JsonUnits
    BEGIN
        IF @Position>=@ChunkStart+@ChunkUnits
        BEGIN
            SET @Chunk=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position,4000);
            SET @ChunkStart=@Position;
            SET @ChunkUnits=CONVERT(int,DATALENGTH(@Chunk)/2);
        END;
        SET @Unit=UNICODE(SUBSTRING(@Chunk COLLATE Latin1_General_100_BIN2,@Position-@ChunkStart+1,1));
        SET @Advance=1;
        IF @InsideString=0
        BEGIN
            IF @Unit=34
            BEGIN
                SET @InsideString=1;
                SET @PendingHigh=0;
            END
            ELSE IF @Unit IN(91,123)
            BEGIN
                SET @Depth+=1;
                IF @Depth>@MaxDepth
                BEGIN
                    INSERT @Result VALUES('INVALID',NULL,NULL,'DEPTH_LIMIT');
                    RETURN;
                END;
            END
            ELSE IF @Unit IN(93,125) SET @Depth-=1;
        END
        ELSE IF @Unit=34
        BEGIN
            IF @PendingHigh=1 SET @UnicodeFault=1;
            SET @PendingHigh=0;
            SET @InsideString=0;
        END
        ELSE
        BEGIN
            IF @Unit=92
            BEGIN
                SET @NextUnit=UNICODE(SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position+1,1));
                IF @NextUnit=117
                BEGIN
                    SET @HexText=SUBSTRING(@Json COLLATE Latin1_General_100_BIN2,@Position+2,4);
                    SET @Unit=0;
                    SET @HexPosition=1;
                    WHILE @HexPosition<=4
                    BEGIN
                        SET @HexUnit=UNICODE(SUBSTRING(@HexText COLLATE Latin1_General_100_BIN2,@HexPosition,1));
                        SET @Unit=@Unit*16+CASE WHEN @HexUnit BETWEEN 48 AND 57 THEN @HexUnit-48
                                              WHEN @HexUnit BETWEEN 65 AND 70 THEN @HexUnit-55 ELSE @HexUnit-87 END;
                        SET @HexPosition+=1;
                    END;
                    SET @Advance=6;
                END
                ELSE
                BEGIN
                    -- Die übrigen gültigen Escapes liefern ausschließlich
                    -- Nicht-Surrogate; ihr ASCII-Escapezeichen genügt hier.
                    SET @Unit=@NextUnit;
                    SET @Advance=2;
                END;
            END;
            IF @PendingHigh=1
            BEGIN
                IF @Unit NOT BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
                SET @PendingHigh=0;
            END
            ELSE IF @Unit BETWEEN 56320 AND 57343 SET @UnicodeFault=1;
            IF @Unit BETWEEN 55296 AND 56319 SET @PendingHigh=1;
        END;
        SET @Position+=@Advance;
    END;
    -- Unicodefehler werden gespeichert statt früh zurückgegeben: ein späteres
    -- Tiefenlimit hat nach gültiger Syntax den vereinbarten Vorrang.
    IF @UnicodeFault=1
    BEGIN
        INSERT @Result VALUES('INVALID',NULL,NULL,'UNICODE');
        RETURN;
    END;

    DECLARE @Token nvarchar(max),@TokenUnits int,@Matches bigint,
            @NextValue nvarchar(max),@NextType int,@TokenPosition int,
            @ArraySyntax bit;
    SET @Position=1;
    WHILE @Position<=@PointerUnits
    BEGIN
        -- Eine Slashposition einlesen, dann genau ein Token decodieren. Kein
        -- REPLACE: Pointer/Keys dürfen NUL enthalten. ~01 wird korrekt zu ~1.
        SET @Position+=1;
        SET @Token=CAST(N'' AS nvarchar(max));
        WHILE @Position<=@PointerUnits
        BEGIN
            SET @Unit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1));
            IF @Unit=47 BREAK;
            IF @Unit=126
            BEGIN
                SET @NextUnit=UNICODE(SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position+1,1));
                SET @Token+=CASE WHEN @NextUnit=49 THEN N'/' ELSE N'~' END;
                SET @Position+=2;
            END
            ELSE
            BEGIN
                SET @Token+=SUBSTRING(@Pointer COLLATE Latin1_General_100_BIN2,@Position,1);
                SET @Position+=1;
            END;
        END;
        IF @CurrentType NOT IN(4,5)
        BEGIN
            INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
            RETURN;
        END;
        SET @TokenUnits=CONVERT(int,DATALENGTH(@Token)/2);
        IF @CurrentType=4
        BEGIN
            IF @TokenUnits=1 AND @Token COLLATE Latin1_General_100_BIN2=N'-'
            BEGIN
                INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
                RETURN;
            END;
            SET @ArraySyntax=0;
            IF @TokenUnits=0 SET @ArraySyntax=1;
            IF @TokenUnits>1 AND UNICODE(SUBSTRING(@Token COLLATE Latin1_General_100_BIN2,1,1))=48 SET @ArraySyntax=1;
            SET @TokenPosition=1;
            WHILE @TokenPosition<=@TokenUnits
            BEGIN
                SET @Unit=UNICODE(SUBSTRING(@Token COLLATE Latin1_General_100_BIN2,@TokenPosition,1));
                IF @Unit NOT BETWEEN 48 AND 57 SET @ArraySyntax=1;
                SET @TokenPosition+=1;
            END;
            IF @ArraySyntax=1
            BEGIN
                INSERT @Result VALUES('INVALID',NULL,NULL,'ARRAY_INDEX');
                RETURN;
            END;
            -- Lexikalischer Vergleich mit nativen Indexkeys vermeidet jede
            -- Ganzzahlkonvertierung; beliebig große gültige Indizes sind MISSING.
        END;
        SET @Matches=0;
        SET @NextValue=NULL;
        SET @NextType=NULL;
        -- Aktueller Wert stammt ausschließlich aus dem vollständig validierten
        -- Root oder einem nativen Containerfragment. IF schützt den Parseraufruf,
        -- kein Optimizer-Prädikat. Nur passende Werte werden aggregiert gehalten.
        IF @CurrentType IN(4,5)
        BEGIN
            SET @SafeJson=@Current;
            SELECT @Matches=COUNT_BIG(*),@NextValue=MAX([value]),@NextType=MAX([type])
            FROM OPENJSON(@SafeJson)
            WHERE [key] COLLATE Latin1_General_100_BIN2=@Token COLLATE Latin1_General_100_BIN2
              AND DATALENGTH([key])=DATALENGTH(@Token);
        END;
        IF @Matches=0
        BEGIN
            INSERT @Result VALUES('MISSING',NULL,NULL,NULL);
            RETURN;
        END;
        IF @Matches>1
        BEGIN
            INSERT @Result VALUES('INVALID',NULL,NULL,'DUPLICATE_KEY');
            RETURN;
        END;
        SET @Current=@NextValue;
        SET @CurrentType=@NextType;
    END;
    IF @CurrentType=0
        INSERT @Result VALUES('JSON_NULL','NULL',NULL,NULL);
    ELSE
        INSERT @Result VALUES('FOUND',CASE @CurrentType WHEN 1 THEN 'STRING' WHEN 2 THEN 'NUMBER'
            WHEN 3 THEN 'BOOLEAN' WHEN 4 THEN 'ARRAY' ELSE 'OBJECT' END,@Current,NULL);
    RETURN;
END;
GO
