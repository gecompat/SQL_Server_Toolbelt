-- Explicitly approved disposable database-only identity. No login or server grants.
IF DATABASE_PRINCIPAL_ID(N'ContosoParserMinimalRights') IS NOT NULL
    THROW 53140, N'Test principal already exists.', 1;
CREATE USER ContosoParserMinimalRights WITHOUT LOGIN;
GRANT SELECT ON OBJECT::toolbelt_tsql.TVF_ParseScriptNodes TO ContosoParserMinimalRights;
GRANT SELECT ON OBJECT::toolbelt_tsql.TVF_ParseScriptNodeProperties TO ContosoParserMinimalRights;
GRANT SELECT ON OBJECT::toolbelt_tsql.TVF_TokenizeScript TO ContosoParserMinimalRights;
GRANT SELECT ON OBJECT::toolbelt_tsql.TVF_ParseScriptErrors TO ContosoParserMinimalRights;
BEGIN TRY
    EXECUTE AS USER = N'ContosoParserMinimalRights';
    IF USER_NAME() <> N'ContosoParserMinimalRights'
       OR IS_MEMBER(N'db_owner') <> 0
       OR HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CONTROL') <> 0
       OR HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'ALTER ANY ASSEMBLY') <> 0
        THROW 53140, N'Test identity has excessive authority.', 2;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1;',160,1,2097152,256))
       OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1;',160,1,2097152,256))
       OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1;',160,1,2097152,256))
       OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT FROM;',160,1,2097152,256))
        THROW 53140, N'Minimal SELECT caller did not receive the expected rows.', 3;
    REVERT;
    DENY SELECT ON OBJECT::toolbelt_tsql.TVF_TokenizeScript TO ContosoParserMinimalRights;
    EXECUTE AS USER = N'ContosoParserMinimalRights';
    DECLARE @Denied bit = 0;
    BEGIN TRY
        SELECT COUNT(*) FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1;',160,1,2097152,256);
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 229 THROW;
        SET @Denied = 1;
    END CATCH;
    IF @Denied <> 1 THROW 53140, N'Denied SELECT was accepted.', 4;
    REVERT;
    DROP USER ContosoParserMinimalRights;
END TRY
BEGIN CATCH
    IF USER_NAME() = N'ContosoParserMinimalRights' REVERT;
    IF DATABASE_PRINCIPAL_ID(N'ContosoParserMinimalRights') IS NOT NULL
        DROP USER ContosoParserMinimalRights;
    THROW;
END CATCH;
PRINT N'PARSER_MINIMAL_RIGHTS_PASS';
