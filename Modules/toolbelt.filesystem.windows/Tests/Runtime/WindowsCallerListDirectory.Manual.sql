:On Error exit
/*
 * Manueller Windows-Caller-Smoke-Test.
 *
 * In SSMS SQLCMD Mode aktivieren und Betreibervariablen vor diesem Script
 * definieren oder mit sqlcmd -v RootAlias=... RelativePath="" ausführen.
 * RootAlias und RelativePath sind Betreiberwerte und werden nicht in dieses
 * Repository oder in Test-Evidence übernommen.
 */
-- Keine :setvar-Defaults: sie würden explizite sqlcmd -v-Werte überschreiben.
-- Fehlende Variablen werden von SQLCMD vor Ausführung abgewiesen.

SET NOCOUNT ON;

IF NULLIF(N'$(RootAlias)', N'') IS NULL OR N'$(RootAlias)' = N'__REQUIRED__'
    THROW 51549, N'Die SQLCMD-Variable RootAlias muss einen aktiven, fuer Listing freigegebenen Root-Alias enthalten.', 1;

SELECT
      ORIGINAL_LOGIN() AS OriginalLogin
    , SUSER_SNAME() AS CurrentLogin
    , connectionData.auth_scheme AS AuthenticationScheme
FROM sys.dm_exec_connections AS connectionData
WHERE connectionData.session_id = @@SPID;

EXEC [toolbelt_filesystem].[USP_ListDirectory]
      @RootAlias = N'$(RootAlias)'
    , @RelativePath = N'$(RelativePath)'
    , @Recursive = 0
    , @MaxDepth = 1
    , @MaxEntries = 10000
    , @ExecutionIdentity = 'Caller';
