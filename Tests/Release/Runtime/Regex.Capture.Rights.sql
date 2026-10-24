SET NOCOUNT ON;
SET XACT_ABORT OFF;

-- Nur in einer eindeutig eigenen, temporären Qualifikationsdatenbank ausführen.
-- Der Harness benötigt bestehende Adminrechte; der Fachcaller erhält weder
-- Login, Rollenmitgliedschaft, Schemagrants noch Rechte auf den CLR-Kernen.
IF USER_ID(N'ContosoRegexCaptureCaller') IS NOT NULL
 THROW 52093,N'Vorhandener Testprincipal wird nicht übernommen.',1;
DECLARE @Created bit=0,@Impersonated bit=0,@Phase int=0,@Call int,
 @Caught bit,@Sql nvarchar(max),@ExpectedError int;
DECLARE @Calls table(Id int PRIMARY KEY,SqlText nvarchar(max));
INSERT @Calls VALUES
 (1,N'DECLARE @Rows table(MatchOrdinal bigint,GroupOrdinal int,CaptureOrdinal bigint,GroupName nvarchar(128),Matched bit,StartPosition bigint,Length bigint,Value nvarchar(max));
 INSERT @Rows SELECT * FROM toolbelt_string.TVF_RegexCaptures(N''b'',N''(?<First>a)?(b)'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
 IF (SELECT COUNT(*) FROM @Rows)<>2
 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE GroupOrdinal=1 AND CaptureOrdinal=0 AND GroupName=N''First'' AND Matched=0 AND Value IS NULL)
 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE GroupOrdinal=2 AND CaptureOrdinal=1 AND Matched=1 AND StartPosition=1 AND Length=1 AND CONVERT(varbinary(max),Value)=0x6200)
 THROW 52093,N''Capture-Minimalrechte-Wertorakel verletzt.'',2;'),
 (2,N'DECLARE @Result nvarchar(max)=toolbelt_string.SVF_RegexReplaceGroups(N''b'',N''(a)?(b)'',N''$1/$2'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
 IF @Result IS NULL OR CONVERT(varbinary(max),@Result)<>0x2F006200
 THROW 52093,N''Replace-Minimalrechte-Wertorakel verletzt.'',3;'),
 (3,N'DECLARE @Count bigint; SELECT @Count=COUNT_BIG(*) FROM toolbelt_string.TVF_RegexCapturesCore(N''a'',N''(a)'',1,N''c'',N''standard'',10);'),
 (4,N'DECLARE @Result nvarchar(max)=toolbelt_string.SVF_RegexReplaceGroupsCore(N''a'',N''(a)'',N''$1'',1,0,N''c'',N''standard'');');
BEGIN TRY
 CREATE USER ContosoRegexCaptureCaller WITHOUT LOGIN;
 SET @Created=1;
 WHILE @Phase<=3
 BEGIN
  -- REFERENCES verschafft keine Ausführungsberechtigung für einen Skalaraufruf.
  -- Erst der enge EXECUTE-Grant auf die Fassade erlaubt den Fachaufruf.
  IF @Phase=1
   GRANT REFERENCES ON OBJECT::toolbelt_string.SVF_RegexReplaceGroups TO ContosoRegexCaptureCaller;
  IF @Phase=2
  BEGIN
   REVOKE REFERENCES ON OBJECT::toolbelt_string.SVF_RegexReplaceGroups FROM ContosoRegexCaptureCaller;
   GRANT SELECT ON OBJECT::toolbelt_string.TVF_RegexCaptures TO ContosoRegexCaptureCaller;
   GRANT EXECUTE ON OBJECT::toolbelt_string.SVF_RegexReplaceGroups TO ContosoRegexCaptureCaller;
  END;
  IF @Phase=3
  BEGIN
   REVOKE SELECT ON OBJECT::toolbelt_string.TVF_RegexCaptures FROM ContosoRegexCaptureCaller;
   REVOKE EXECUTE ON OBJECT::toolbelt_string.SVF_RegexReplaceGroups FROM ContosoRegexCaptureCaller;
  END;
  SET @Call=1;
  WHILE @Call<=4
  BEGIN
   SELECT @Sql=SqlText FROM @Calls WHERE Id=@Call;
   SET @ExpectedError=CASE WHEN @Phase=2 AND @Call<=2 THEN 0 ELSE 229 END;
   SET @Caught=0;
   EXECUTE AS USER=N'ContosoRegexCaptureCaller';
   SET @Impersonated=1;
   IF @Phase=2 AND (
    ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.TVF_RegexCaptures',N'OBJECT',N'SELECT'),-1)<>1
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.SVF_RegexReplaceGroups',N'OBJECT',N'EXECUTE'),-1)<>1
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string.SVF_RegexReplaceGroups',N'OBJECT',N'REFERENCES'),-1)<>0)
    THROW 52093,N'Minimalrechtephase besitzt nicht exakt die erwarteten öffentlichen Rechte.',6;
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
    THROW 52093,N'Fehlende Rechte oder interner CLR-Direktzugriff wurden nicht abgewiesen.',4;
   SET @Call+=1;
  END;
  SET @Phase+=1;
 END;
 DROP USER ContosoRegexCaptureCaller;
 SET @Created=0;
 IF USER_ID(N'ContosoRegexCaptureCaller') IS NOT NULL
  THROW 52093,N'Testprincipal wurde nicht entfernt.',5;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoRegexCaptureCaller;
 THROW;
END CATCH;
PRINT N'Capture-/Replace-Minimalrechte lokal oder direkt zentral: Wert-, Rechteentzug- und interne Abweisungsorakel bestanden.';
