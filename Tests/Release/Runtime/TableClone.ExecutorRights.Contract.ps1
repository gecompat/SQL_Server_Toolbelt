# Exact approved temporary Executor identity; no product changes.
function Test-ExecutorLoginIdentity($Expected,$Rows){
 $rows=@($Rows)
 return [bool]($rows.Count-eq1-and$Expected.name-cmatch'^ContosoCloneExecutor_[a-f0-9]{32}$'-and
  $Expected.sid-cmatch'^[A-F0-9]{32}$'-and$Expected.id-gt0-and$Expected.created-cmatch'^[A-F0-9]{16}$'-and
  $rows[0].Name-ceq$Expected.name-and$rows[0].Sid-ceq$Expected.sid-and$rows[0].Id-eq$Expected.id-and
  $rows[0].Created-ceq$Expected.created-and$rows[0].DefaultDatabase-ceq$Expected.consumer-and
  $rows[0].Type-ceq'S'-and$rows[0].Disabled-eq0-and$rows[0].Policy-eq1-and$rows[0].Expiration-eq1)
}
function Get-ExecutorDropSql{
 # Aufruf ausschließlich nach bestätigter Abwesenheit eigener DBs und globaler
 # Prüfung auf unerwartete SID-Mappings. Direkt vor DROP erneut Identität prüfen.
 return @'
IF NOT EXISTS(SELECT 1 FROM sys.server_principals p JOIN sys.sql_logins l ON l.principal_id=p.principal_id
 WHERE CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),@Login) AND p.sid=@Sid
 AND p.principal_id=TRY_CONVERT(int,@PrincipalId) AND CONVERT(varbinary(8),p.create_date)=@Created
 AND CONVERT(varbinary(max),p.default_database_name)=CONVERT(varbinary(max),@Consumer)
 AND p.type=N'S' AND p.is_disabled=0 AND l.is_policy_checked=1 AND l.is_expiration_checked=1)
 THROW 52099,N'Own login identity changed; cleanup blocked.',1;
IF EXISTS(SELECT 1 FROM sys.server_role_members WHERE member_principal_id=TRY_CONVERT(int,@PrincipalId))
 OR EXISTS(SELECT 1 FROM sys.server_permissions WHERE grantee_principal_id=TRY_CONVERT(int,@PrincipalId)
  AND (permission_name NOT IN(N'CONNECT SQL',N'VIEW ANY DEFINITION') OR state<>N'G'))
 OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE security_id=@Sid OR original_security_id=@Sid)
 THROW 52099,N'Own login role,permission or session consumer changed; cleanup blocked.',2;
DECLARE @Drop nvarchar(max)=N'DROP LOGIN '+QUOTENAME(@Login)+N';';
EXEC sys.sp_executesql @Drop;
'@
}

# Nur echte eigene Netzwerkverbindungen; keine EXECUTE-AS-Simulation.
function Get-ExecutorLoginRows($Master,$Login){
 return @(Invoke-ReleaseSql $Master @'
SELECT p.name Name,CONVERT(varchar(32),p.sid,2) Sid,p.principal_id Id,
 CONVERT(varchar(16),CONVERT(varbinary(8),p.create_date),2) Created,p.default_database_name DefaultDatabase,
 p.type Type,CONVERT(int,p.is_disabled) Disabled,CONVERT(int,l.is_policy_checked) Policy,CONVERT(int,l.is_expiration_checked) Expiration
FROM sys.server_principals p LEFT JOIN sys.sql_logins l ON l.principal_id=p.principal_id
WHERE p.name=@Login OR p.sid=@Sid;
'@ @{'@Login'=$Login.name;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
}
function Get-ExecutorSidConsumers($Master,$Login,[string[]]$AllowedDatabases=@()){
 $databases=@(Invoke-ReleaseSql $Master 'SELECT name Name,state State FROM sys.databases WHERE database_id>4;' -Rows)
 if($databases.Count-gt128-or@($databases|Where-Object State -NE 0).Count){throw 'CLONE_EXECUTOR_RIGHTS_FOREIGN_DATABASE_VISIBILITY'}
 $sum=0
 foreach($database in $databases){
  if($database.Name-in$AllowedDatabases){continue}
  $rows=@(Invoke-ReleaseSql $Master @'
DECLARE @Q nvarchar(max)=N'SELECT COUNT(*) N FROM '+QUOTENAME(@Database)+N'.sys.database_principals WHERE sid=@Sid;';
EXEC sys.sp_executesql @Q,N'@Sid varbinary(85)',@Sid;
'@ @{'@Database'=$database.Name;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
  if($rows.Count-ne1){throw 'CLONE_EXECUTOR_RIGHTS_CONSUMER_OBSERVER_SHAPE'};$sum+=[int]$rows[0].N
 }
 return $sum
}
function Assert-ExecutorCleanupConsumers($Master,$Login,[string[]]$AllowedDatabases){
 if($null-eq$Login){return}
 $rows=@(Get-ExecutorLoginRows $Master $Login)
 $Login['cleanupIdentityObservation']=@($rows);Save-ReleaseJournal
 if($rows.Count-eq0){if($Login.state-ceq'ACTIVE'){throw 'CLONE_EXECUTOR_RIGHTS_LOGIN_DISAPPEARED'};return}
 if($Login.state-cnotin@('CREATE_DISPATCHED','ACTIVE')){throw 'CLONE_EXECUTOR_RIGHTS_UNKNOWN_LOGIN_OWNER'}
 if($null-eq$Login.id-and$Login.initialAbsenceVerified){
  # Vorab gebundene zufällige SID und Name erlauben die Reconciliation nach
  # verlorener CREATE-Antwort. Default-DB/Typ/Policy bleiben zusätzliche Zeugen.
  if($rows.Count-ne1-or$rows[0].Sid-cne$Login.sid-or$rows[0].Name-cne$Login.name-or$rows[0].DefaultDatabase-cne$Login.consumer){throw 'CLONE_EXECUTOR_RIGHTS_CREATE_RECONCILIATION_BLOCKED'}
  $Login.id=$rows[0].Id;$Login.created=$rows[0].Created;Save-ReleaseJournal
 }
 if(-not(Test-ExecutorLoginIdentity $Login $rows)){throw 'CLONE_EXECUTOR_RIGHTS_LOGIN_IDENTITY_DRIFT'}
 $state=@(Invoke-ReleaseSql $Master @'
SELECT (SELECT COUNT(*) FROM sys.server_role_members WHERE member_principal_id=TRY_CONVERT(int,@Id)) Roles,
 (SELECT COUNT(*) FROM sys.server_permissions WHERE grantee_principal_id=TRY_CONVERT(int,@Id) AND (permission_name NOT IN(N'CONNECT SQL',N'VIEW ANY DEFINITION') OR state<>N'G')) ExtraPermissions,
 (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE security_id=@Sid OR original_security_id=@Sid) Sessions;
'@ @{'@Id'=$Login.id;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
 if($state.Count-ne1-or$state[0].Roles-ne0-or$state[0].ExtraPermissions-ne0-or$state[0].Sessions-ne0-or(Get-ExecutorSidConsumers $Master $Login $AllowedDatabases)-ne0){throw 'CLONE_EXECUTOR_RIGHTS_FOREIGN_CONSUMER_OR_RIGHT_DRIFT'}
 $Login.connectionCount=0;Save-ReleaseJournal
}
function Remove-ExecutorLogin($Master,$Login){
 if($null-eq$Login){return}
 $rows=@(Get-ExecutorLoginRows $Master $Login)
 if($rows.Count-eq0){$Login.state='ABSENT';return}
 Assert-ExecutorCleanupConsumers $Master $Login @()
 Invoke-ReleaseSql $Master ('REVOKE VIEW ANY DEFINITION FROM ['+$Login.name+'];')
 Invoke-ReleaseSql $Master (Get-ExecutorDropSql) @{'@Login'=$Login.name;'@Sid'=[Convert]::FromHexString($Login.sid);'@PrincipalId'=$Login.id;'@Created'=[Convert]::FromHexString($Login.created);'@Consumer'=$Login.consumer}
 if(@(Get-ExecutorLoginRows $Master $Login).Count-ne0){throw 'CLONE_EXECUTOR_RIGHTS_LOGIN_DROP_UNVERIFIED'}
 $Login.state='DROPPED'
}
function Assert-ExecutorLoginAbsent($Master,$Login){
 if($null-eq$Login){return}
 if($Login.name-cnotmatch'^ContosoCloneExecutor_[a-f0-9]{32}$'-or$Login.sid-cnotmatch'^[A-F0-9]{32}$'-or$Login.state-cnotin@('ABSENT','DROPPED')){throw 'CLONE_EXECUTOR_RIGHTS_AUDIT_LOGIN_STATE'}
 if(@(Get-ExecutorLoginRows $Master $Login).Count-ne0-or(Get-ExecutorSidConsumers $Master $Login @())-ne0){throw 'CLONE_EXECUTOR_RIGHTS_AUDIT_LOGIN_OR_MAPPING_PRESENT'}
}
function Open-ExecutorCaller($Admin,[string]$Database,[string]$Password){
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($Admin.ConnectionString)
 $builder['Integrated Security']=$false;$builder['User ID']=$ledger.login.name;$builder['Password']=$Password
 $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0
 $builder['MultipleActiveResultSets']=$false
 $builder['Connect Timeout']=[Math]::Min(10,(Get-ReleaseTimeout))
 $caller=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$builder.Clear()
 $connections.Add($caller)
 try{$caller.Open();return $caller}catch{$caller.Dispose();throw}
}

# The approved grammar is closed; callers cannot supply arbitrary permissions.
function Get-ExecutorDatabaseGrant([string]$Login,[ValidateSet('CONNECT','EXECUTE','METADATA','DDL','REVOKE_EXECUTE')][string]$Phase){
 if($Login-cnotmatch'^ContosoCloneExecutor_[a-f0-9]{32}$'){throw 'CLONE_EXECUTOR_RIGHTS_OWN_LOGIN_REQUIRED'}
 switch($Phase){
  'CONNECT'{return "CREATE USER [$Login] FOR LOGIN [$Login];GRANT CONNECT TO [$Login];"}
  'EXECUTE'{return "GRANT EXECUTE ON OBJECT::toolbelt_metadata.USP_ExecuteTableClone TO [$Login];"}
  'METADATA'{return "GRANT VIEW DEFINITION TO [$Login];GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO [$Login];"}
  'DDL'{return "GRANT CREATE TABLE TO [$Login];GRANT ALTER ON SCHEMA::ContosoCloneTarget TO [$Login];"}
  'REVOKE_EXECUTE'{return "REVOKE EXECUTE ON OBJECT::toolbelt_metadata.USP_ExecuteTableClone FROM [$Login];"}
 }
}
function Get-ExecutorPlanHash([int]$DatabaseId,[string]$Database,[object[]]$Plan){
 # Hash v1, independently compared with the canonical client example offline.
 $stream=[IO.MemoryStream]::new()
 function Write-I32([int]$Value){if($Value-lt0){throw 'CLONE_EXECUTOR_RIGHTS_HASH_INT'};$b=[BitConverter]::GetBytes($Value);if([BitConverter]::IsLittleEndian){[Array]::Reverse($b)};$stream.Write($b,0,4)}
 function Write-Frame([string]$Value){$b=[Text.Encoding]::Unicode.GetBytes($Value);Write-I32 $b.Length;$stream.Write($b,0,$b.Length)}
 try{
  Write-Frame 'Toolbelt.TableClone.Execute.Hash';Write-I32 1;Write-Frame '4.1.1';Write-I32 $DatabaseId;Write-Frame $Database
  $stream.Write([byte[]]@(0,0,0),0,3);Write-Frame 'REJECT';Write-Frame 'CREATE';Write-I32 1;Write-I32 1
  foreach($text in @('dbo','ContosoExecutorSource','ContosoCloneTarget','ContosoExecutorTarget')){Write-Frame $text}
  $hash=[Security.Cryptography.SHA256]::HashData($stream.ToArray())
  $ordinal=0
  foreach($row in @($Plan|Sort-Object Ordinal)){
   $ordinal++;if($row.Ordinal-ne$ordinal){throw 'CLONE_EXECUTOR_RIGHTS_HASH_PLAN_ORDINAL'}
   $stream.SetLength(0);$stream.Write($hash,0,$hash.Length);Write-I32 $row.Ordinal
   foreach($field in @('ObjectKind','TargetName','ScriptText')){Write-Frame $row.$field}
   $hash=[Security.Cryptography.SHA256]::HashData($stream.ToArray())
  }
  if($ordinal-lt8){throw 'CLONE_EXECUTOR_RIGHTS_HASH_PLAN_EMPTY'}
  $stream.SetLength(0);$stream.Write($hash,0,$hash.Length);Write-I32 $ordinal;Write-Frame 'Toolbelt.TableClone.Execute.Final'
  return ,([Security.Cryptography.SHA256]::HashData($stream.ToArray()))
 }finally{$stream.Dispose()}
}
function Test-ExecutorGrantRows($Rows,[int]$ExecutorId,[int]$DependencyId,[int]$TargetSchemaId){
 $expected=@("ALTER/3/$TargetSchemaId",'CONNECT/0/0','CREATE TABLE/0/0',"EXECUTE/1/$ExecutorId","SELECT/1/$DependencyId",'VIEW DEFINITION/0/0')|Sort-Object
 $actual=@($Rows|ForEach-Object{$_.Permission+'/'+$_.Class+'/'+$_.Major}|Sort-Object)
 return [bool](@($Rows).Count-eq6-and@($Rows|Where-Object State -CNE 'G').Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function New-ExecutorLogin($Db){
 if($null-ne$ledger.login){return}
 $ledger.login=[ordered]@{name=('ContosoCloneExecutor_'+$ledger.owner);sid=[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(16));consumer=$Db.Database;id=$null;created=$null;state='INTENT';initialAbsenceVerified=$false;connectionCount=$null};Save-ReleaseJournal
 $login=$ledger.login
 if(@(Get-ExecutorLoginRows $control $login).Count-or(Get-ExecutorSidConsumers $control $login @())-ne0){throw 'CLONE_EXECUTOR_RIGHTS_LOGIN_COLLISION'}
 $login.initialAbsenceVerified=$true;$login.state='CREATE_DISPATCHED';Save-ReleaseJournal
 $script:executorPassword='aA1!'+[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
 Invoke-ReleaseSql $control @'
IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name=@Login OR sid=@Sid) THROW 52099,N'Owned login collision.',1;
DECLARE @D nvarchar(max)=N'CREATE LOGIN '+QUOTENAME(@Login)+N' WITH PASSWORD='+QUOTENAME(@Password,N'''')+
 N',SID='+CONVERT(nvarchar(max),@Sid,1)+N',DEFAULT_DATABASE='+QUOTENAME(@Database)+N',CHECK_POLICY=ON,CHECK_EXPIRATION=ON;';
EXEC sys.sp_executesql @D;
'@ @{'@Login'=$login.name;'@Sid'=[Convert]::FromHexString($login.sid);'@Password'=$script:executorPassword;'@Database'=$Db.Database}
 $rows=@(Get-ExecutorLoginRows $control $login);if($rows.Count-ne1){throw 'CLONE_EXECUTOR_RIGHTS_CREATED_LOGIN_REQUIRED'}
 $login.id=$rows[0].Id;$login.created=$rows[0].Created;$login.state='ACTIVE';Save-ReleaseJournal
 if(-not(Test-ExecutorLoginIdentity $login $rows)){throw 'CLONE_EXECUTOR_RIGHTS_LOGIN_IDENTITY'}
 Invoke-ReleaseSql $control ('GRANT VIEW ANY DEFINITION TO ['+$login.name+'];')
}
function Assert-ExecutorNetwork($Caller,$Receipt){
 $tag=[guid]::NewGuid().ToByteArray();Invoke-ReleaseSql $Caller 'SET CONTEXT_INFO @Tag;' @{'@Tag'=$tag}
 $rows=@(Invoke-ReleaseSql $Caller "SELECT @@SPID Spid,DB_ID() DatabaseId,ORIGINAL_LOGIN() LoginName,SUSER_SID() Sid,USER_NAME() UserName,IS_SRVROLEMEMBER(N'sysadmin') Admin,IS_ROLEMEMBER(N'db_owner') OwnerRole,HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL') DbControl,HAS_PERMS_BY_NAME(NULL,NULL,N'CONTROL SERVER') ServerControl,HAS_PERMS_BY_NAME(NULL,NULL,N'VIEW ANY DEFINITION') AnyDefinition;" -Rows)
 $sample=[ordered]@{caller=@($rows);observer=@()};$Receipt.network+=@($sample);Save-ReleaseJournal
 if($rows.Count-ne1-or$rows[0].LoginName-cne$ledger.login.name-or$rows[0].UserName-cne$ledger.login.name-or[Convert]::ToHexString([byte[]]$rows[0].Sid)-cne$ledger.login.sid-or$rows[0].AnyDefinition-ne1-or@('Admin','OwnerRole','DbControl','ServerControl'|Where-Object{$rows[0].$_-ne0}).Count){throw 'CLONE_EXECUTOR_RIGHTS_CALLER_IDENTITY'}
 $seen=@(Invoke-ReleaseSql $control "SELECT COUNT(*) N FROM sys.dm_exec_sessions s JOIN sys.dm_exec_connections c ON s.session_id=c.session_id WHERE s.session_id=TRY_CONVERT(int,@Id) AND s.database_id=TRY_CONVERT(int,@Database) AND s.context_info=@Tag AND s.security_id=@Sid AND s.original_security_id=@Sid AND c.auth_scheme=N'SQL' AND c.net_transport=N'TCP';" @{'@Id'=$rows[0].Spid;'@Database'=$rows[0].DatabaseId;'@Tag'=$tag;'@Sid'=[Convert]::FromHexString($ledger.login.sid)} -Rows)
 $sample.observer=@($seen);Save-ReleaseJournal
 if($seen.Count-ne1-or$seen[0].N-ne1){throw 'CLONE_EXECUTOR_RIGHTS_REAL_NETWORK_REQUIRED'}
}
function Assert-ExecutorDenied($Caller,[string]$Sql,[hashtable]$Parameters,[int]$Number,[string]$Profile,$Receipt){
 $caught=$false
 try{Invoke-ReleaseSql $Caller $Sql $Parameters}catch{
  $leaf=$_.Exception;while($leaf-and$leaf-isnot[Data.SqlClient.SqlException]){$leaf=$leaf.InnerException}
  if(-not$leaf){throw};$errors=@($leaf.Errors|Where-Object Class -GE 11)
  $Receipt.denials+=@(@{profile=$Profile;errors=@($errors|ForEach-Object{@{number=$_.Number;state=$_.State}})});Save-ReleaseJournal
  if($errors.Count-eq0-or@($errors|Where-Object Number -NE $Number).Count){throw 'CLONE_EXECUTOR_RIGHTS_WRONG_DENIAL'};$caught=$true
 }
 if(-not$caught){throw 'CLONE_EXECUTOR_RIGHTS_DENIAL_MISSING'}
 $Receipt.profiles+=@($Profile);Save-ReleaseJournal
}
function Invoke-ExecutorRightsProfiles($Db,[string]$Mode){
 New-ExecutorLogin $Db
 $login=$ledger.login.name
 Invoke-ReleaseSql $Db "CREATE SCHEMA ContosoCloneTarget;"
 Invoke-ReleaseSql $Db 'CREATE TABLE dbo.ContosoExecutorSource(Id int NOT NULL);INSERT dbo.ContosoExecutorSource VALUES(1),(2);'
 Invoke-ReleaseSql $Db (Get-ExecutorDatabaseGrant $login CONNECT)
 $mapping=@(Invoke-ReleaseSql $Db "SELECT COUNT(*) N FROM sys.database_principals WHERE name=@Login AND sid=@Sid AND type=N'S';SELECT is_trustworthy_on T,is_db_chaining_on C FROM sys.databases WHERE database_id=DB_ID();" @{'@Login'=$login;'@Sid'=[Convert]::FromHexString($ledger.login.sid)} -Rows)
 if($mapping.Count-ne2-or$mapping[0].N-ne1-or$mapping[1].T-or$mapping[1].C){throw 'CLONE_EXECUTOR_RIGHTS_DATABASE_SECURITY'}
 $receipt=[ordered]@{mode=$Mode;sidMapped=$true;network=@();denials=@();profiles=@();permissions=@();output=@();post=@();passed=$false};$ledger.executorReceipts+=@($receipt);Save-ReleaseJournal
 $plan=@(Invoke-ReleaseSql $Db "EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoExecutorSource',@TargetSchema=N'ContosoCloneTarget',@TargetTable=N'ContosoExecutorTarget';" -Rows)
 $dbid=@(Invoke-ReleaseSql $Db 'SELECT DB_ID() Id;' -Rows)[0].Id
 $hash=Get-ExecutorPlanHash $dbid $Db.Database $plan
 $query="EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'ContosoExecutorSource',@TargetSchema=N'ContosoCloneTarget',@TargetTable=N'ContosoExecutorTarget',@ExpectedPlanHash=@Hash;"
 $parameters=@{'@Hash'=$hash}
 $caller=Open-ExecutorCaller $Db $Db.Database $script:executorPassword
 try{Assert-ExecutorNetwork $caller $receipt;Assert-ExecutorDenied $caller $query $parameters 229 'no-execute' $receipt}finally{$caller.Dispose()}
 Invoke-ReleaseSql $Db (Get-ExecutorDatabaseGrant $login EXECUTE)
 Invoke-ReleaseSql $Db (Get-ExecutorDatabaseGrant $login METADATA)
 $caller=Open-ExecutorCaller $Db $Db.Database $script:executorPassword
 try{Assert-ExecutorDenied $caller $query $parameters 53932 'no-ddl' $receipt}finally{$caller.Dispose()}
 if(@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'ContosoCloneTarget.ContosoExecutorTarget') Id;" -Rows)[0].Id-isnot[DBNull]){throw 'CLONE_EXECUTOR_RIGHTS_DENIED_DDL_LEAK'}
 Invoke-ReleaseSql $Db (Get-ExecutorDatabaseGrant $login DDL)
 $rights=@(Invoke-ReleaseSql $Db "SELECT p.permission_name Permission,p.class Class,p.major_id Major,p.state State FROM sys.database_permissions p JOIN sys.database_principals u ON u.principal_id=p.grantee_principal_id WHERE u.name=@Login ORDER BY p.permission_name;" @{'@Login'=$login} -Rows)
 $receipt.permissions=@($rights);Save-ReleaseJournal
 $ids=@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'toolbelt_metadata.USP_ExecuteTableClone') ExecutorId,OBJECT_ID(N'sys.sql_expression_dependencies') DependencyId,SCHEMA_ID(N'ContosoCloneTarget') TargetSchemaId;" -Rows)
 if($ids.Count-ne1-or-not(Test-ExecutorGrantRows $rights $ids[0].ExecutorId $ids[0].DependencyId $ids[0].TargetSchemaId)){throw 'CLONE_EXECUTOR_RIGHTS_EXPLICIT_GRANTS_DRIFT'}
 $caller=Open-ExecutorCaller $Db $Db.Database $script:executorPassword
 try{
  Assert-ExecutorNetwork $caller $receipt
  $output=@(Invoke-ReleaseSql $caller $query $parameters -Rows);$receipt.output=@($output);Save-ReleaseJournal
  if($output.Count-ne1-or[Convert]::ToHexString([byte[]]$output[0].PlanHash)-cne[Convert]::ToHexString($hash)-or$output[0].TablesCreated-ne1-or$output[0].StatementsExecuted-ne@($plan|Where-Object ObjectKind -CNE 'SESSION_OPTION').Count){throw 'CLONE_EXECUTOR_RIGHTS_OUTPUT'}
  $neutral=@(Invoke-ReleaseSql $caller 'DECLARE @T int=@@TRANCOUNT,@X int=XACT_STATE();SELECT @T T,@X X;' -Rows)
  if($neutral.Count-ne1-or$neutral[0].T-ne0-or$neutral[0].X-ne0){throw 'CLONE_EXECUTOR_RIGHTS_TRANSACTION'}
  $receipt.profiles+=@('create');Save-ReleaseJournal
  Assert-ExecutorDenied $caller 'SELECT * FROM dbo.ContosoExecutorSource;' @{} 229 'data-select-denied' $receipt
  Assert-ExecutorDenied $caller 'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;' @{} 229 'helper-denied' $receipt
 }finally{$caller.Dispose()}
 Invoke-ReleaseSql $Db (Get-ExecutorDatabaseGrant $login REVOKE_EXECUTE)
 $caller=Open-ExecutorCaller $Db $Db.Database $script:executorPassword
 try{Assert-ExecutorDenied $caller $query $parameters 229 'revoked-execute' $receipt}finally{$caller.Dispose()}
 $post=@(Invoke-ReleaseSql $Db 'SELECT (SELECT COUNT(*) FROM dbo.ContosoExecutorSource) SourceRows,(SELECT SUM(Id) FROM dbo.ContosoExecutorSource) SourceSum,(SELECT COUNT(*) FROM ContosoCloneTarget.ContosoExecutorTarget) TargetRows,(SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N''ContosoCloneTarget.ContosoExecutorTarget'') AND name=N''Id'' AND system_type_id=56 AND is_nullable=0) Columns; ' -Rows)
 $receipt.post=@($post);Save-ReleaseJournal
 if($post.Count-ne1-or$post[0].SourceRows-ne2-or$post[0].SourceSum-ne3-or$post[0].TargetRows-ne0-or$post[0].Columns-ne1){throw 'CLONE_EXECUTOR_RIGHTS_FINAL_SHAPE'}
 $receipt.passed=$true;Save-ReleaseJournal
}
