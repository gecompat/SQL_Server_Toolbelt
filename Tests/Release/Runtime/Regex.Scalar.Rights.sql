SET NOCOUNT ON;
SET XACT_ABORT OFF;

-- Ausschließlich eigene temporäre Qualifikationsdatenbank. Keine Logins,
-- Rollen-/Schemagrants oder direkten Grants auf technische CLR-Kerne.
IF USER_ID(N'ContosoRegexScalarCaller') IS NOT NULL
 THROW 52094,N'Vorhandener Testprincipal wird nicht übernommen.',1;
DECLARE @Created bit=0,@Impersonated bit=0,@Phase int=0,@Call int,
 @Caught bit,@Sql nvarchar(max),@ExpectedError int,@Name sysname;
DECLARE @Public table(Id int PRIMARY KEY,Name sysname NOT NULL);
INSERT @Public VALUES
 (1,N'SVF_RegexIsMatch'),(2,N'SVF_RegexInstr'),(3,N'SVF_RegexCount'),
 (4,N'SVF_RegexReplace'),(5,N'SVF_RegexSubstring'),(6,N'SVF_RegexReplaceGroups');
DECLARE @Calls table(Id int PRIMARY KEY,SqlText nvarchar(max));
INSERT @Calls VALUES
 (1,N'IF ISNULL(toolbelt_string.SVF_RegexIsMatch(N''a12b34'',N''[0-9]+'',N''c''),0)<>1
 THROW 52094,N''IsMatch-Rechtewertorakel verletzt.'',2;'),
 (2,N'IF ISNULL(toolbelt_string.SVF_RegexInstr(N''a12b34'',N''[0-9]+'',1,2,0,N''c''),0)<>5
 THROW 52094,N''Instr-Rechtewertorakel verletzt.'',3;'),
 (3,N'IF ISNULL(toolbelt_string.SVF_RegexCount(N''a12b34'',N''[0-9]+'',1,N''c''),0)<>2
 THROW 52094,N''Count-Rechtewertorakel verletzt.'',4;'),
 (4,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexReplace(N''a12b34'',N''[0-9]+'',N''$1'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
 IF @V IS NULL OR CONVERT(varbinary(max),@V)<>0x610024003100620024003100
 THROW 52094,N''Literal-Replace-Rechtewertorakel verletzt.'',5;'),
 (5,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexSubstring(N''a12b34'',N''[0-9]+'',1,2,DEFAULT,DEFAULT);
 IF @V IS NULL OR CONVERT(varbinary(max),@V)<>0x33003400
 THROW 52094,N''Substring-Rechtewertorakel verletzt.'',6;'),
 (6,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexReplaceGroups(N''abb'',N''(?<First>a)(b)+'',N''${First}:$2:$$'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
 IF @V IS NULL OR CONVERT(varbinary(max),@V)<>0x61003A0062003A002400
 THROW 52094,N''Gruppen-Replace-Rechtewertorakel verletzt.'',7;'),
 (7,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexReplaceCore(N''a'',N''a'',N''b'',1,0,N''c'',N''standard'');'),
 (8,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexSubstringCore(N''a'',N''a'',1,1,N''c'',N''standard'');'),
 (9,N'DECLARE @V nvarchar(max)=toolbelt_string.SVF_RegexReplaceGroupsCore(N''a'',N''(a)'',N''$1'',1,0,N''c'',N''standard'');');
BEGIN TRY
 CREATE USER ContosoRegexScalarCaller WITHOUT LOGIN;
 SET @Created=1;
 WHILE @Phase<=3
 BEGIN
  SET @Call=1;
  WHILE @Call<=6
  BEGIN
   SELECT @Name=Name FROM @Public WHERE Id=@Call;
   SET @Sql=CASE @Phase
    WHEN 1 THEN N'GRANT REFERENCES ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' TO ContosoRegexScalarCaller;'
    WHEN 2 THEN N'REVOKE REFERENCES ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' FROM ContosoRegexScalarCaller; GRANT EXECUTE ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' TO ContosoRegexScalarCaller;'
    WHEN 3 THEN N'REVOKE EXECUTE ON OBJECT::toolbelt_string.'+QUOTENAME(@Name)+N' FROM ContosoRegexScalarCaller;'
    ELSE NULL END;
   IF @Sql IS NOT NULL EXEC sys.sp_executesql @Sql;
   SET @Call+=1;
  END;
  SET @Call=1;
  WHILE @Call<=9
  BEGIN
   SELECT @Sql=SqlText FROM @Calls WHERE Id=@Call;
   SET @ExpectedError=CASE WHEN @Phase=2 AND @Call<=6 THEN 0 ELSE 229 END;
   SET @Caught=0;
   EXECUTE AS USER=N'ContosoRegexScalarCaller';
   SET @Impersonated=1;
   IF @Phase=2 AND EXISTS(
    SELECT 1 FROM @Public
    WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.'+Name,N'OBJECT',N'EXECUTE'),-1)<>1
       OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.'+Name,N'OBJECT',N'REFERENCES'),-1)<>0)
    THROW 52094,N'Positive Phase besitzt nicht exakt die erwarteten Skalarrechte.',8;
   BEGIN TRY
    EXEC sys.sp_executesql @Sql;
   END TRY
   BEGIN CATCH
    IF @ExpectedError=0 OR ERROR_NUMBER()<>@ExpectedError THROW;
    SET @Caught=1;
   END CATCH;
   REVERT;
   SET @Impersonated=0;
   IF @ExpectedError<>0 AND @Caught=0
    THROW 52094,N'Fehlende Rechte oder interner Direktzugriff wurden nicht abgewiesen.',9;
   SET @Call+=1;
  END;
  SET @Phase+=1;
 END;
 DROP USER ContosoRegexScalarCaller;
 SET @Created=0;
 IF USER_ID(N'ContosoRegexScalarCaller') IS NOT NULL
  THROW 52094,N'Testprincipal wurde nicht entfernt.',10;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoRegexScalarCaller;
 THROW;
END CATCH;
PRINT N'Regex-Skalarrechte: sechs Wertorakel, REFERENCES-Abweisung, EXECUTE allein, Rechteentzug und drei interne Abweisungen bestanden.';
