SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_SecondSessionProbe]
      @RemoteSessionId   int     = NULL OUTPUT
    , @RemoteDatabaseName sysname = NULL OUTPUT
    , @Hilfe bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Hilfe,0)=1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,CONVERT(sysname,N'toolbelt_core') SchemaName,
            CONVERT(sysname,N'USP_SecondSessionProbe') ObjectName,v.Section,v.Ordinal,v.ItemName,v.SqlDataType,
            v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Interner Kontextprobe für einen kontrollierten Second-Session-Aufruf; liefert OUTPUT-Metadaten der tatsächlich aufrufenden Session.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@RemoteSessionId','int OUTPUT',0,1,N'NULL',N'OUTPUT-Wert @@SPID der aufrufenden Session.',NULL),
          ('PARAMETER',2,N'@RemoteDatabaseName','sysname OUTPUT',0,1,N'NULL',N'OUTPUT-Wert DB_NAME() der aufrufenden Session.',NULL),
          ('PARAMETER',3,N'@Hilfe','bit',0,0,N'0',N'1 gibt Hilfe vor jeder Sessionabfrage aus.',NULL),
          ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; die beiden Werte werden ausschließlich über OUTPUT-Parameter geliefert.',NULL),
          ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Kein allgemeiner öffentlicher Aufruf; nur über den freigegebenen Second-Session-Vertrag.',NULL),
          ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Keine eigenständige Ausführung oder beliebige Remote-Session-Erzeugung.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Interne Probe im bereits autorisierten Aufrufkontext; liefert ausschließlich OUTPUT-Werte.',N'DECLARE @SessionId int,@DatabaseName sysname; EXEC toolbelt_core.USP_SecondSessionProbe @RemoteSessionId=@SessionId OUTPUT,@RemoteDatabaseName=@DatabaseName OUTPUT; SELECT @SessionId AS SessionId,@DatabaseName AS DatabaseName;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;
        RETURN 0;
    END;

    SET @RemoteSessionId = @@SPID;
    SET @RemoteDatabaseName = DB_NAME();
    RETURN 0;
END;
GO
