-- ============================================================================
-- Objekt:          toolbelt_string.TVF_SplitByCharactersStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Input nvarchar(max), @Separators nvarchar(4000), @KeepEmpty bit = 1
-- Resultset:       Value nvarchar(max), Ordinal bigint, Status varchar(16)
-- Vertrag:         Documentation/TVF_SplitByCharactersStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharactersStatus]
(@Input nvarchar(max),@Separators nvarchar(4000),@KeepEmpty bit=1)
RETURNS @Result TABLE(Value nvarchar(max) NULL,Ordinal bigint NULL,Status varchar(16) NOT NULL)
AS
BEGIN
    IF @Input IS NULL OR @Separators IS NULL
    BEGIN INSERT @Result VALUES(NULL,NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Input)>65536
    BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
    DECLARE @SeparatorCodes TABLE(Code int NOT NULL PRIMARY KEY);
    DECLARE @Position int=1,@Length int=CONVERT(int,DATALENGTH(@Input)/2),
            @SeparatorLength int=CONVERT(int,DATALENGTH(@Separators)/2),@Code int,
            @Start int=1,@Count int=0;
    WHILE @Position<=@SeparatorLength
    BEGIN
        SET @Code=UNICODE(SUBSTRING(@Separators COLLATE Latin1_General_100_BIN2,@Position,1));
        IF @Code=0 BEGIN INSERT @Result VALUES(NULL,NULL,'INVALID'); RETURN; END;
        IF NOT EXISTS(SELECT 1 FROM @SeparatorCodes WHERE Code=@Code)
        BEGIN
            IF (SELECT COUNT(*) FROM @SeparatorCodes)>=64
            BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
            INSERT @SeparatorCodes VALUES(@Code);
        END;
        SET @Position+=1;
    END;
    DECLARE @Spans TABLE(Ordinal int NOT NULL PRIMARY KEY,StartPosition int NOT NULL,SpanLength int NOT NULL);
    SET @Position=1;
    WHILE @Position<=@Length+1
    BEGIN
        IF @Position=@Length+1 OR EXISTS(SELECT 1 FROM @SeparatorCodes
            WHERE Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1)))
        BEGIN
            IF COALESCE(@KeepEmpty,1)=1 OR @Position>@Start
            BEGIN
                IF @Count>=10000 BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
                SET @Count+=1;
                INSERT @Spans VALUES(@Count,@Start,@Position-@Start);
            END;
            SET @Start=@Position+1;
        END;
        SET @Position+=1;
    END;
    IF @Count=0 INSERT @Result VALUES(NULL,NULL,'EMPTY');
    ELSE INSERT @Result SELECT SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,StartPosition,SpanLength),Ordinal,'OK' FROM @Spans;
    RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_SplitByCharacters.md
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharacters]
(@Input nvarchar(max),@Separators nvarchar(4000),@KeepEmpty bit=1)
RETURNS TABLE AS RETURN
(SELECT Value,Ordinal FROM toolbelt_string.TVF_SplitByCharactersStatus(@Input,@Separators,@KeepEmpty) WHERE Status='OK');
GO
