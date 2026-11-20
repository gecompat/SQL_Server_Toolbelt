#Requires -Version 7.5
[CmdletBinding()]
param(
    [ValidateSet('Run','Audit')][string]$Mode='Run',
    [Parameter(Mandatory)][string]$RunRoot,
    [Parameter(Mandatory)][ValidatePattern('^[a-z0-9-]{1,48}$')][string]$CaseId,
    [ValidateSet('2019','2022','2025')][string]$SqlVersion='2025',
    [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod='auto',
    [switch]$WithoutForeign,
    [Parameter(Mandatory)][ValidatePattern('^CU[0-9]+$')][string]$Patch,
    [string]$InstallerPath,[string]$ForeignAssemblyPath,[string]$ForeignProbePath,[string]$ScriptDomDllPath,
    [string]$ExpectedJournalSha256
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$moduleRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$repo=[IO.Path]::GetFullPath((Join-Path $moduleRoot '../..'))
$runtime=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$root=[IO.Path]::GetFullPath($RunRoot)
if(-not $root.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){throw 'SIMPLE_NATIVE_PRIVATE_ROOT'}
[IO.Directory]::CreateDirectory($root)|Out-Null
$cursor=$root
while($cursor -and $cursor.StartsWith($runtime.TrimEnd([IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)) {
    if(((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)-ne 0){throw 'SIMPLE_NATIVE_REPARSE'}
    $parent=[IO.Path]::GetDirectoryName($cursor);if($parent -eq $cursor){break};$cursor=$parent
}
$journalPath=Join-Path $root ($CaseId+'.journal.private.json')
$budgetPath=Join-Path $root 'budget.private.json'
function Save([string]$Path,[object]$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))}
function Hash([byte[]]$Bytes){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes))}
function Reserve {
    # Ein gemeinsamer Rahmen fuer alle spaeteren nativen Anschlussfaelle.
    $stream=[IO.File]::Open($budgetPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
        if($stream.Length -eq 0){
            $script:budget=@{id=[guid]::NewGuid().ToString('N');started=[datetimeoffset]::UtcNow.ToString('o');expires=[datetimeoffset]::UtcNow.AddMinutes(120).ToString('o');calls=0;databases=0;maxCalls=32;maxDatabases=32;dispatches=@();reservedAudits=@()}
        }else{
            $reader=[IO.StreamReader]::new($stream,[Text.Encoding]::UTF8,$true,1024,$true)
            try{$script:budget=$reader.ReadToEnd()|ConvertFrom-Json -AsHashtable}finally{$reader.Dispose()}
        }
        $key=$CaseId+':'+$Mode
        if($key -in $script:budget.dispatches -or $script:budget.calls -ge $script:budget.maxCalls){throw 'SIMPLE_NATIVE_BUDGET_CLOSED'}
        if($Mode -eq 'Run' -and ([datetimeoffset]::UtcNow -ge [datetimeoffset]$script:budget.expires -or $script:budget.calls+$script:budget.reservedAudits.Count+2 -gt $script:budget.maxCalls)){throw 'SIMPLE_NATIVE_BUDGET_CLOSED'}
        if($Mode -eq 'Audit') {
            if($CaseId -notin $script:budget.reservedAudits){throw 'SIMPLE_NATIVE_AUDIT_NOT_RESERVED'}
            $script:budget.reservedAudits=@($script:budget.reservedAudits|Where-Object {$_ -cne $CaseId})
        }else{$script:budget.reservedAudits+=@($CaseId)}
        if($Mode -eq 'Run' -and $script:budget.databases -ge $script:budget.maxDatabases){throw 'SIMPLE_NATIVE_DB_BUDGET_CLOSED'}
        $script:budget.calls++;if($Mode -eq 'Run'){$script:budget.databases++};$script:budget.dispatches+=@($key)
        $bytes=[Text.Encoding]::UTF8.GetBytes(($script:budget|ConvertTo-Json -Depth 8));$stream.Position=0;$stream.SetLength(0);$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)
    }finally{$stream.Dispose()}
}
function Read-Target {
    $path=$env:SQL_SERVER_LAB_TEST_ENV_FILE;$schema=$env:SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE
    if(-not $path){throw 'SIMPLE_NATIVE_LAB_CONTRACT_REQUIRED'}
    if(-not $schema){$schema=Join-Path (Split-Path -Parent $path) 'TestUmgebung.schema.json'}
    $bytes=[IO.File]::ReadAllBytes($path);$text=[Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
    $valid=Test-Json -Json $text -SchemaFile $schema -ErrorAction SilentlyContinue -ErrorVariable schemaErrors
    $schemaErrors=$null
    if(-not $valid){throw 'SIMPLE_NATIVE_LAB_SCHEMA'}
    $contract=$text|ConvertFrom-Json
    if($contract.contractVersion -cne 'SqlServerLab.TestEnvironment/1.0' -or $contract.groupStatus -notin @('READY','INCOMPLETE')){throw 'SIMPLE_NATIVE_LAB_GROUP'}
    $selected=@($contract.environments|Where-Object {$_.platform -ceq 'windows' -and $_.sqlVersion -ceq $SqlVersion -and $_.patch -ceq $Patch.ToLowerInvariant() -and $_.runtimeStatus -ceq 'READY' -and $_.status -cin @('READY','GROUP_INCOMPLETE')})
    if($selected.Count -ne 1 -or $selected[0].encrypt -ne $true -or $selected[0].trustServerCertificate -isnot [bool]){throw 'SIMPLE_NATIVE_TARGET_SELECTION'}
    return @{target=$selected[0];hash=(Hash $bytes)}
}
function Connect([object]$Target,[string]$Database) {
    $builder=[System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source']='tcp:{0},{1}' -f $Target.host,$Target.port
    $builder['Initial Catalog']=$Database;$builder['User ID']=$Target.username;$builder['Password']=$Target.password
    $builder['Encrypt']=$true;$builder['TrustServerCertificate']=[bool]$Target.trustServerCertificate
    $builder['Pooling']=$false;$builder['Connect Timeout']=15;$builder['Application Name']='ToolbeltSimpleNative'
    $connection=[System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open();return $connection
}
function Table([object]$Connection,[string]$Sql,[hashtable]$Parameters=@{}) {
    $command=$Connection.CreateCommand();$command.CommandText=$Sql;$command.CommandTimeout=180
    foreach($key in $Parameters.Keys){$type=if($Parameters[$key] -is [byte[]]){[System.Data.SqlDbType]::VarBinary}else{[System.Data.SqlDbType]::NVarChar};$p=$command.Parameters.Add($key,$type,-1);$p.Value=$Parameters[$key]}
    $adapter=[System.Data.SqlClient.SqlDataAdapter]::new($command);$set=[System.Data.DataSet]::new()
    try{[void]$adapter.Fill($set);return ,$set}finally{$adapter.Dispose();$command.Dispose()}
}
function Execute([object]$Connection,[string]$Sql) {
    $command=$Connection.CreateCommand();$command.CommandTimeout=180;$command.CommandText=$Sql
    try{[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
}
function Snapshot([object]$Connection) {
    $data=Table $Connection "SELECT name,CONVERT(int,value) v,CONVERT(int,value_in_use) u FROM sys.configurations ORDER BY configuration_id; SELECT CONVERT(varchar(130),hash,1) h,description d FROM sys.trusted_assemblies ORDER BY hash;"
    $rows=@(foreach($table in $data.Tables){foreach($row in $table.Rows){,@($row.ItemArray)}})
    return Hash ([Text.Encoding]::UTF8.GetBytes(($rows|ConvertTo-Json -Depth 5 -Compress)))
}
function Check([bool]$Condition,[string]$Name){if(-not $Condition){throw ('SIMPLE_NATIVE_ASSERT_'+$Name)};$script:journal.checks++}
function Consumers([object]$Connection,[byte[]]$Hash) {
    $databases=Table $Connection 'SELECT name,state,HAS_DBACCESS(name) access FROM sys.databases;'
    $count=0
    foreach($database in $databases.Tables[0].Rows){
        if($database.state -ne 0 -or $database.access -ne 1){throw 'SIMPLE_NATIVE_CONSUMER_VISIBILITY'}
        $quoted='['+([string]$database.name).Replace(']',']]')+']'
        $rows=Table $Connection ("SELECT COUNT(*) n FROM $quoted.sys.assembly_files WHERE file_id=1 AND HASHBYTES('SHA2_512',content)=@hash;") @{'@hash'=$Hash}
        $count+=[int]$rows.Tables[0].Rows[0].n
    }
    return $count
}
function ClrInventory([object]$Connection) {
    $databases=Table $Connection 'SELECT name,state,HAS_DBACCESS(name) access FROM sys.databases WHERE database_id<>2 ORDER BY database_id;'
    $entries=@(foreach($database in $databases.Tables[0].Rows){
        if($database.state -ne 0 -or $database.access -ne 1){throw 'SIMPLE_NATIVE_CLR_CONSUMER_SCOPE'}
        $quoted='['+([string]$database.name).Replace(']',']]')+']'
        $asms=Table $Connection ("SELECT a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) hash FROM $quoted.sys.assemblies a JOIN $quoted.sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;")
        foreach($assembly in $asms.Tables[0].Rows){@{database=[string]$database.name;name=[string]$assembly.name;hash=[string]$assembly.hash}}
    })
    return Hash ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $entries -Depth 4 -Compress)))
}
function Enable-TestClr([object]$Connection) {
    $lease=Table $Connection "DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0;SELECT @r r;"
    if($lease.Tables[0].Rows[0].r -lt 0){throw 'SIMPLE_NATIVE_CLR_LEASE_BUSY'}
    $journal.configurationLease=$true;Save $journalPath $journal
    $rows=Table $Connection 'SELECT name,CONVERT(int,value) v,CONVERT(int,value_in_use) u FROM sys.configurations;'
    $clr=@($rows.Tables[0].Rows|Where-Object {$_.name -ceq 'clr enabled'})
    if($clr.Count -ne 1){throw 'SIMPLE_NATIVE_CLR_STATE'}
    if($clr[0].v -eq 1 -and $clr[0].u -eq 1){return}
    $pending=@($rows.Tables[0].Rows|Where-Object {$_.v -ne $_.u -and -not ($_.v -eq 0 -and (($_.name -ceq 'min server memory (MB)' -and $_.u -in @(8,16)) -or ($_.name -ceq 'max server memory (MB)' -and $_.u -eq 2147483647)))})
    if($clr[0].v -ne 0 -or $clr[0].u -ne 0 -or $pending.Count -ne 0){throw 'SIMPLE_NATIVE_PENDING_CONFIGURATION'}
    $journal.configurationBefore=@($rows.Tables[0].Rows|ForEach-Object {@{name=[string]$_.name;configured=[int]$_.v;running=[int]$_.u}})
    $journal.consumerBefore=ClrInventory $Connection
    $journal.clrChanged=$true;Save $journalPath $journal
    Execute $Connection "EXEC sys.sp_configure N'clr enabled',1;RECONFIGURE;"
    $journal.activeSnapshot=Snapshot $Connection;Save $journalPath $journal
}
function Restore-TestClr([object]$Connection) {
    if($journal.clrChanged){
        if(-not $journal.activeSnapshot -or (Snapshot $Connection) -cne $journal.activeSnapshot -or (ClrInventory $Connection) -cne $journal.consumerBefore){throw 'SIMPLE_NATIVE_CLR_RESTORE_SCOPE_CHANGED'}
        Execute $Connection "EXEC sys.sp_configure N'clr enabled',0;RECONFIGURE;"
        $journal.clrChanged=$false;Save $journalPath $journal
    }
    if($journal.configurationLease){
        $lease=Table $Connection "DECLARE @r int;EXEC @r=sys.sp_releaseapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session';SELECT @r r;"
        if($lease.Tables[0].Rows[0].r -lt 0){throw 'SIMPLE_NATIVE_CLR_LEASE_RELEASE'}
        $journal.configurationLease=$false;Save $journalPath $journal
    }
}

$snapshot=Read-Target
if($Mode -eq 'Audit') {
    if(-not $ExpectedJournalSha256 -or (Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash -cne $ExpectedJournalSha256){throw 'SIMPLE_NATIVE_AUDIT_JOURNAL_BINDING'}
    $journal=Get-Content -LiteralPath $journalPath -Raw -Encoding utf8|ConvertFrom-Json -AsHashtable
    if($journal.contractHash -cne $snapshot.hash -or -not $journal.cleaned){throw 'SIMPLE_NATIVE_AUDIT_SCOPE'}
    Reserve
    $master=Connect $snapshot.target 'master'
    try {
        $state=Table $master "SELECT COUNT(*) n FROM sys.databases WHERE name=N'$($journal.database)';"
        if($state.Tables[0].Rows[0].n -ne 0 -or (Snapshot $master) -cne $journal.baseline){throw 'SIMPLE_NATIVE_AUDIT_DRIFT'}
        Save (Join-Path $root ($CaseId+'.audit.private.json')) @{status='PASS';journalSha256=$ExpectedJournalSha256;checks=2}
        'SIMPLE_NATIVE_AUDIT_PASS checks=2'
    }finally{$master.Dispose()}
    exit
}
if(Test-Path -LiteralPath $journalPath){throw 'SIMPLE_NATIVE_RUN_ALREADY_DISPATCHED'}
$required=@($InstallerPath)
if(-not $WithoutForeign){$required+=@($ForeignAssemblyPath,$ForeignProbePath)}
if($TrustMethod -eq 'hash' -and -not $WithoutForeign){throw 'SIMPLE_NATIVE_HASH_FIXTURE_REQUIRES_NO_FOREIGN'}
foreach($path in $required){if(-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)){throw 'SIMPLE_NATIVE_INPUT_REQUIRED'}}
$methodBytes=[IO.File]::ReadAllBytes($PSCommandPath)
$methodPath=Join-Path $root ($CaseId+'.method.private.ps1')
if(Test-Path -LiteralPath $methodPath){throw 'SIMPLE_NATIVE_METHOD_SNAPSHOT_EXISTS'}
[IO.File]::WriteAllBytes($methodPath,$methodBytes)
$bindings=@(foreach($path in @($required)+@($methodPath)){@{path=[IO.Path]::GetFullPath($path);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}})
Reserve
$script:journal=@{status='RUNNING';database=('ContosoToolbeltSimple_'+[guid]::NewGuid().ToString('N'));guid=$null;created=$false;cleaned=$false;checks=0;contractHash=$snapshot.hash;inputs=$bindings;baseline=$null;trust=@();trustMethod=$TrustMethod;withForeign=(-not [bool]$WithoutForeign);configurationLease=$false;clrChanged=$false;activeSnapshot=$null}
Save $journalPath $journal
$master=$null;$db=$null;$failure=$null
try {
    $master=Connect $snapshot.target 'master'
    $preflight=Table $master "SELECT @@VERSION v; SELECT name,state_desc FROM sys.databases ORDER BY database_id; SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) major; SELECT name,CONVERT(int,value_in_use) u FROM sys.configurations WHERE name IN(N'clr enabled',N'clr strict security',N'lightweight pooling');"
    $expectedMajor=@{'2019'=15;'2022'=16;'2025'=17}[$SqlVersion]
    Check ($preflight.Tables[2].Rows[0].major -eq $expectedMajor) 'VERSION'
    $journal.baseline=Snapshot $master;Save $journalPath $journal
    foreach($name in @('clr strict security','lightweight pooling')){
        $row=@($preflight.Tables[3].Rows|Where-Object {$_.name -ceq $name})
        Check ($row.Count -eq 1 -and $row[0].u -eq $(if($name -eq 'lightweight pooling'){0}else{1})) 'CLR_PRECONDITION'
    }
    Enable-TestClr $master
    Execute $master "IF DB_ID(N'$($journal.database)') IS NOT NULL THROW 51000,N'Own database name already exists.',1; CREATE DATABASE [$($journal.database)];"
    $journal.created=$true
    $identity=Table $master "SELECT CONVERT(varchar(36),r.database_guid) g FROM sys.database_recovery_status r JOIN sys.databases d ON d.database_id=r.database_id WHERE d.name=N'$($journal.database)';"
    $journal.guid=$identity.Tables[0].Rows[0].g;Save $journalPath $journal
    # Ausschliesslich die eigene neue Fixture-DB, keine Produkt-/Serveroption.
    $trustValue=if($TrustMethod -eq 'hash'){'OFF'}else{'ON'}
    Execute $master "ALTER DATABASE [$($journal.database)] SET TRUSTWORTHY $trustValue;"
    $db=Connect $snapshot.target $journal.database
    $before=Table $db 'SELECT COUNT(*) n FROM sys.extended_properties;'
    if(-not $WithoutForeign){
        $foreign='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($ForeignAssemblyPath))
        $probe='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($ForeignProbePath))
        Execute $db ("CREATE ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom] FROM $foreign WITH PERMISSION_SET=UNSAFE; CREATE ASSEMBLY [ContosoForeignProbe] FROM $probe WITH PERMISSION_SET=UNSAFE;")
        Execute $db "CREATE FUNCTION dbo.ContosoForeignParse() RETURNS int AS EXTERNAL NAME [ContosoForeignProbe].[ForeignProbe].[Parse];"
        $foreignBefore=Table $db 'SELECT dbo.ContosoForeignParse() n; SELECT name,clr_name FROM sys.assemblies WHERE name=N''Microsoft.SqlServer.TransactSql.ScriptDom'';'
        Check ($foreignBefore.Tables[0].Rows[0].n -eq 0) 'FOREIGN_BEFORE'
        Check ($foreignBefore.Tables[1].Rows.Count -eq 1 -and $foreignBefore.Tables[1].Rows[0].clr_name -like 'microsoft.sqlserver.transactsql.scriptdom, version=17.*') 'FOREIGN_ORIGINAL_IDENTITY'
    }
    $installer=[IO.File]::ReadAllText($InstallerPath)
    if(-not $installer.StartsWith('USE [ContosoSsisDebug];',[StringComparison]::Ordinal)){throw 'SIMPLE_NATIVE_INSTALLER_USE'}
    $installer=$installer.Replace('USE [ContosoSsisDebug];',"USE [$($journal.database)];")
    if(-not $installer.Contains("DECLARE @TrustMethod varchar(24)='$TrustMethod';")){throw 'SIMPLE_NATIVE_INSTALLER_TRUST_BINDING'}
    if($TrustMethod -eq 'hash'){
        $bits=[regex]::Matches($installer,'DECLARE @bits(Dom|Ssis) varbinary\(max\)=0x([0-9A-F]+);')
        if($bits.Count -ne 2){throw 'SIMPLE_NATIVE_HASH_INPUTS'}
        foreach($entry in $bits){
            $hash=[Security.Cryptography.SHA512]::HashData([Convert]::FromHexString($entry.Groups[2].Value))
            $name=if($entry.Groups[1].Value -ceq 'Dom'){'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom'}else{'tlblt_Tsql_SsisDebug'}
            $existing=Table $master 'SELECT description FROM sys.trusted_assemblies WHERE hash=@hash;' @{'@hash'=$hash}
            $description='ToolbeltSimpleNative '+$journal.database+' '+$name
            $journal.trust+=@(@{hash=[Convert]::ToHexString($hash);preexisting=($existing.Tables[0].Rows.Count -ne 0);description=$description})
            if($existing.Tables[0].Rows.Count -eq 0 -and (Consumers $master $hash) -ne 0){throw 'SIMPLE_NATIVE_HASH_FOREIGN_CONSUMER'}
            # Der Trustschritt ist selbst ein SQL-Stringliteral; seine
            # inneren Anfuehrungszeichen sind deshalb bereits verdoppelt.
            $needle="@description=N''Toolbelt $name''"
            if(-not $installer.Contains($needle)){throw 'SIMPLE_NATIVE_TRUST_DESCRIPTION_BINDING'}
            $installer=$installer.Replace($needle,"@description=N''$description''")
        }
        Save $journalPath $journal
    }
    $journal.executedInstallerSha256=Hash ([Text.Encoding]::UTF8.GetBytes($installer));Save $journalPath $journal
    Execute $db $installer
    Execute $db $installer
    Check $true 'REPEAT_INSTALL'
    if(-not $WithoutForeign){$foreignAfter=Table $db 'SELECT dbo.ContosoForeignParse() n;';Check ($foreignAfter.Tables[0].Rows[0].n -eq 0) 'FOREIGN_AFTER'}
    $after=Table $db 'SELECT COUNT(*) n FROM sys.extended_properties; SELECT COUNT(*) n FROM sys.assemblies WHERE LEFT(name,5)=N''tlblt''; SELECT COUNT(*) n FROM sys.tables WHERE is_ms_shipped=0;'
    Check ($before.Tables[0].Rows[0].n -eq $after.Tables[0].Rows[0].n) 'NO_PROPERTIES'
    Check ($after.Tables[1].Rows[0].n -eq 2) 'PREFIXED_ASSEMBLIES'
    Check ($after.Tables[2].Rows[0].n -eq 0) 'NO_LOG_TABLES'
    [xml]$fixture=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Tests/Fixtures/procedure-8.dtsx'))
    $ns=[Xml.XmlNamespaceManager]::new($fixture.NameTable);$ns.AddNamespace('DTS','www.microsoft.com/SqlServer/Dts')
    $manager=$fixture.SelectSingleNode('//DTS:ConnectionManagers/DTS:ConnectionManager',$ns)
    $objectData=$fixture.CreateElement('DTS','ObjectData','www.microsoft.com/SqlServer/Dts')
    $inner=$fixture.CreateElement('DTS','ConnectionManager','www.microsoft.com/SqlServer/Dts')
    [void]$inner.SetAttribute('ConnectionString','www.microsoft.com/SqlServer/Dts',"Data Source=ContosoServer;Initial Catalog=$($journal.database)")
    [void]$objectData.AppendChild($inner);[void]$manager.AppendChild($objectData)
    $result=Table $db 'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@xml;' @{'@xml'=$fixture.OuterXml}
    $scripts=@($result.Tables[0].Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.IsComplete})
    Check ($scripts.Count -gt 0) 'XML_ONLY_DEBUG'
    Check (@($scripts|Where-Object {$_.IsExecutable -or $_.SafetyStatus -cne 'not_checked'}).Count -eq 0) 'UNVERIFIED_LABELS'
    $central=Table $master ("EXEC [$($journal.database)].toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=@xml,@StartValues=N'{""User::SourceFloor"":7}';") @{'@xml'=$fixture.OuterXml}
    $centralScripts=@($central.Tables[0].Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.IsComplete})
    Check (@($centralScripts|Where-Object {$_.Content -match 'DECLARE @v[0-9]+ int = 7;'}).Count -gt 0) 'CENTRAL_START_VALUES'
    # Die Erzeugung oben erfolgt noch ohne Quelltabelle. Erst der bewusste
    # synthetische Consumer richtet Daten ein und fuehrt das Resultat aus.
    Execute $db 'CREATE TABLE dbo.SyntheticSourceA(KeyA int,KeyB int,Amount int); INSERT dbo.SyntheticSourceA VALUES(1,10,5),(2,20,8);'
    . (Join-Path $PSScriptRoot 'SimpleSqlBatches.ps1')
    $batches=@(Get-SimpleSqlBatches ([string]$scripts[0].Content) $ScriptDomDllPath)
    $rowCounts=@(foreach($batch in $batches){
        $executed=Table $db $batch
        foreach($resultTable in $executed.Tables){$resultTable.Rows.Count}
    })
    Check ($rowCounts.Count -gt 0 -and @($rowCounts|Where-Object {$_ -ne 2}).Count -eq 0) 'GENERATED_DEBUG_CONSUMER'
    $journal.status='PASS_CLEANED'
}catch{
    $failure=$_;$journal.status='FAILED_CLEANED'
    $message=$_.Exception.Message.Replace([string]$snapshot.target.password,'[redacted]')
    $journal.failure=$message
    $inner=$_.Exception.InnerException
    if($inner -is [System.Data.SqlClient.SqlException]){$journal.sqlErrors=@($inner.Errors|ForEach-Object {@{number=$_.Number;line=$_.LineNumber;state=$_.State}})}
    if($db -and $db.State -eq 'Open'){
        try{$registered=Table $db 'SELECT name,clr_name,permission_set FROM sys.assemblies WHERE is_user_defined=1;';$journal.registeredAssemblies=@($registered.Tables[0].Rows|ForEach-Object {@{name=$_.name;identity=$_.clr_name;permissionSet=$_.permission_set}})}catch{$journal.diagnosticUnavailable=$true}
    }
}finally{
    if($db){$db.Dispose()}
    if($journal.created -and $master -and $journal.guid){
        try {
            $scope=Table $master "SELECT CONVERT(varchar(36),r.database_guid) g,(SELECT COUNT(*) FROM sys.dm_exec_sessions s WHERE s.database_id=d.database_id) sessions FROM sys.database_recovery_status r JOIN sys.databases d ON d.database_id=r.database_id WHERE d.name=N'$($journal.database)';"
            if($scope.Tables[0].Rows.Count -ne 1 -or $scope.Tables[0].Rows[0].g -cne $journal.guid -or $scope.Tables[0].Rows[0].sessions -ne 0){throw 'SIMPLE_NATIVE_CLEANUP_OWNERSHIP'}
            Execute $master "DROP DATABASE [$($journal.database)];"
        }catch{$journal.status='CLEANUP_BLOCKED';$journal.cleanupFailure=$_.Exception.Message}
    }elseif(-not $journal.created){$journal.cleaned=$true}
    if($master -and $journal.status -cne 'CLEANUP_BLOCKED'){
        try{
            foreach($entry in $journal.trust|Where-Object {-not $_.preexisting}){
                $hash=[Convert]::FromHexString($entry.hash)
                $existing=Table $master 'SELECT description FROM sys.trusted_assemblies WHERE hash=@hash;' @{'@hash'=$hash}
                if($existing.Tables[0].Rows.Count -eq 0){continue}
                if($existing.Tables[0].Rows.Count -ne 1 -or $existing.Tables[0].Rows[0].description -cne $entry.description -or (Consumers $master $hash) -ne 0){throw 'SIMPLE_NATIVE_HASH_CLEANUP_OWNERSHIP'}
                Execute $master ("EXEC sys.sp_drop_trusted_assembly @hash=0x"+$entry.hash+';')
            }
            Restore-TestClr $master
            if((Snapshot $master) -cne $journal.baseline){throw 'SIMPLE_NATIVE_CLEANUP_DRIFT'}
            $journal.cleaned=$true
        }catch{$journal.status='CLEANUP_BLOCKED';$journal.cleanupFailure=$_.Exception.Message}
    }
    Save $journalPath $journal
    if($master){$master.Dispose()}
}
if($journal.status -cne 'PASS_CLEANED'){throw 'SIMPLE_NATIVE_RUN_FAILED_PRIVATE_JOURNAL'}
'SIMPLE_NATIVE_RUN_PASS checks='+$journal.checks
