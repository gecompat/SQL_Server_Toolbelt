# Opt-in-Vorbereitung: keine Rechtevergabe, kein TLS-/Security-Override.
# Plandaten und Änderungen bleiben ausschließlich im privaten lokalen Journal.
function Get-ToolbeltPreparationSql([string]$Database, [bool]$CreateDatabase, [bool]$EnableClr,
    [string]$ExpectedPlan = '') {
    $literal=$Database.Replace("'","''"); $identifier=$Database.Replace(']',']]')
    $dynamicIdentifier=$identifier.Replace("'","''")
    $create=[int]$CreateDatabase; $enable=[int]$EnableClr
    # Dokumentierte Engine-Normalisierungen sind keine vorgemerkten Änderungen.
    $pending="value<>value_in_use AND NOT(name=N'min server memory (MB)' AND value=0 AND value_in_use IN(8,16)) AND NOT(name=N'max server memory (MB)' AND value=0 AND value_in_use=2147483647)"
    $check=Get-ToolbeltPreflightSql $Database
    # Der reguläre Sicherheits-/Leerheitscheck bleibt kanonisch. Nur CLR darf
    # in dieser vorgeschalteten Planung noch deaktiviert sein.
    $check=$check.Replace("IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)","IF 1=0")
    $check=$check -replace '(?m)^GO\s*$', ''
    $checkLiteral=$check.Replace("'","''")
    $sql=@"
:ON ERROR EXIT
SET NOCOUNT ON;
IF DB_NAME()<>N'master' OR @@TRANCOUNT<>0 THROW 51000,N'TBX_PREPARATION_CONTEXT',1;
IF ISNULL(HAS_PERMS_BY_NAME(NULL,N'SERVER',N'CONTROL SERVER'),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1
    THROW 51000,N'TBX_SERVER_RIGHTS',1;
IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15,16,17)
   OR TRY_CONVERT(int,SERVERPROPERTY(N'EngineEdition')) NOT IN (2,3,4) THROW 51000,N'TBX_VERSION',1;
IF NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform IN (N'Windows',N'Linux')) THROW 51000,N'TBX_PLATFORM',1;
IF N'$literal' COLLATE Latin1_General_100_CI_AS IN (N'master',N'model',N'msdb',N'tempdb')
    THROW 51000,N'TBX_TARGET',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value=1 AND value_in_use=1)
   OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'lightweight pooling' AND value=0 AND value_in_use=0)
    THROW 51000,N'TBX_SECURITY',1;
IF EXISTS(SELECT 1 FROM sys.configurations WHERE $pending) THROW 51000,N'TBX_PENDING_CONFIGURATION',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1) AND $enable=0
    THROW 51000,N'TBX_CLR',1;
DECLARE @id int=DB_ID(N'$literal');
IF @id IS NULL AND $create=0 THROW 51000,N'TBX_DATABASE_MISSING',1;
IF @id IS NOT NULL EXEC(N'USE [$dynamicIdentifier]; $checkLiteral');
-- CREATE DATABASE übernimmt model. Vorher kontaminierte oder ungeeignete
-- Vorlagen ablehnen; danach folgt nochmals der reguläre Zielcheck.
IF @id IS NULL AND (EXISTS(SELECT 1 FROM sys.databases WHERE name=N'model' AND
    (state<>0 OR is_read_only=1 OR compatibility_level<150 OR is_trustworthy_on=1))
    OR EXISTS(SELECT 1 FROM model.sys.objects WHERE is_ms_shipped=0)
    OR EXISTS(SELECT 1 FROM model.sys.assemblies WHERE is_user_defined=1)
    OR EXISTS(SELECT 1 FROM model.sys.types WHERE is_user_defined=1)
    OR EXISTS(SELECT 1 FROM model.sys.schemas WHERE principal_id=1 AND name<>N'dbo'))
    THROW 51000,N'TBX_MODEL',1;
DECLARE @plan nvarchar(max)=(SELECT
    CONVERT(nvarchar(128),SERVERPROPERTY(N'ServerName')) server_name,
    (SELECT host_platform FROM sys.dm_os_host_info) platform,
    N'$literal' database_name,
    (SELECT CONVERT(nvarchar(36),database_guid) FROM sys.database_recovery_status WHERE database_id=@id) database_guid,
    JSON_QUERY((SELECT configuration_id,CONVERT(int,value) configured,CONVERT(int,value_in_use) running
        FROM sys.configurations ORDER BY configuration_id FOR JSON PATH)) configurations
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
"@
    if (-not $ExpectedPlan) { return $sql+@"

DECLARE @part int=0,@wire varbinary(max)=CONVERT(varbinary(max),@plan);
WHILE @part*80<DATALENGTH(@wire)
BEGIN
    SELECT CONVERT(nvarchar(200),N'TBX_PREPARATION_PART|'+RIGHT(N'0000'+CONVERT(nvarchar(4),@part),4)+N'|'+CONVERT(varchar(160),SUBSTRING(@wire,@part*80+1,80),2));
    SET @part+=1;
END;
SELECT N'TBX_PREPARATION_PARTS|'+CONVERT(nvarchar(10),@part);
GO
"@ }
    # Exakte Snapshotprüfung unter einer instanzweiten kooperativen Sperre.
    # Beliebige fremde Administratoraktionen kann diese Sperre nicht verhindern.
    $expected=$ExpectedPlan.Replace("'","''")
    $lock=@"
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'Toolbelt.ServerPreparation',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
IF @lock<0 THROW 51000,N'TBX_LOCK',1;
"@
    $sql=$sql.Replace('DECLARE @id int=', $lock+"`nDECLARE @id int=")
    return $sql+@"

IF @plan COLLATE Latin1_General_100_BIN2<>N'$expected' COLLATE Latin1_General_100_BIN2
    THROW 51000,N'TBX_PREPARATION_DRIFT',1;
IF @id IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [$dynamicIdentifier]');
    SELECT N'TBX_PREPARATION_DATABASE_CREATED';
    SELECT N'TBX_PREPARATION_CREATED_GUID|'+CONVERT(nvarchar(36),database_guid)
        FROM sys.database_recovery_status WHERE database_id=DB_ID(N'$literal');
END;
-- Jede RECONFIGURE-Stelle autorisiert nur ihre eigene vorgemerkte Änderung.
-- clr strict security, pooling und alle anderen Optionen bleiben unangetastet.
IF $enable=1 AND EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=0)
BEGIN
    IF EXISTS(SELECT 1 FROM sys.configurations WHERE $pending) THROW 51000,N'TBX_PENDING_CONFIGURATION',1;
    EXEC sys.sp_configure N'clr enabled',1;
    IF EXISTS(SELECT 1 FROM sys.configurations WHERE $pending AND name<>N'clr enabled')
        THROW 51000,N'TBX_PENDING_CONFIGURATION',1;
    RECONFIGURE;
    IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value=1 AND value_in_use=1)
        THROW 51000,N'TBX_CLR',1;
    SELECT N'TBX_PREPARATION_CLR_ENABLED';
END;
IF EXISTS(SELECT configuration_id,CONVERT(int,value),CONVERT(int,value_in_use) FROM sys.configurations
    EXCEPT SELECT configuration_id,
        CASE WHEN configuration_id=(SELECT configuration_id FROM sys.configurations WHERE name=N'clr enabled') AND $enable=1 THEN 1 ELSE configured END,
        CASE WHEN configuration_id=(SELECT configuration_id FROM sys.configurations WHERE name=N'clr enabled') AND $enable=1 THEN 1 ELSE running END
    FROM OPENJSON(@plan,N'$.configurations') WITH(configuration_id int,configured int,running int))
    THROW 51000,N'TBX_PREPARATION_DRIFT',1;
EXEC(N'USE [$dynamicIdentifier]; $checkLiteral');
SELECT N'TBX_PREPARATION_TARGET|'+CONVERT(nvarchar(36),database_guid)
    FROM sys.database_recovery_status WHERE database_id=DB_ID(N'$literal');
SELECT N'TBX_PREPARATION_OK';
GO
"@
}

function New-ToolbeltPreparationJournal([string]$Database, [string]$Server, [string]$Plan) {
    $root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SQL_Server_Toolbelt/InstallJournals'
    # Keine vorhandenen Verzeichnisse umberechtigen oder Linkziele beschreiben.
    $path=$root
    while ($path) {
        if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Stop-ToolbeltInstall 'JOURNAL' 'Journalpfad enthält eine Dateisystemumleitung.'
        }
        $path=[IO.Path]::GetDirectoryName($path)
    }
    [void][IO.Directory]::CreateDirectory($root)
    $directory=Join-Path $root ([guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($directory)
    if ($IsWindows) {
        $acl=[Security.AccessControl.DirectorySecurity]::new()
        $acl.SetAccessRuleProtection($true,$false)
        $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
        $acl.SetOwner($sid)
        $rule=[Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
        $acl.AddAccessRule($rule)
        Set-Acl -LiteralPath $directory -AclObject $acl
    } else { [IO.File]::SetUnixFileMode($directory,[IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute) }
    $journal=Join-Path $directory 'preparation.json'
    $record=[ordered]@{state='PREPARED';server=$Server;database=$Database;before=($Plan|ConvertFrom-Json);outcome='not dispatched';automaticRollback=$false}
    [IO.File]::WriteAllText($journal,($record|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    return @{Path=$journal;Record=$record}
}
