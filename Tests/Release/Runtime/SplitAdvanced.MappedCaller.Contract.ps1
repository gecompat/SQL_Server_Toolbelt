# Reine Vorschau; keine Verbindung und keine SQL-Ausführung.
function Get-SplitMappedPermissionPlan([string]$Owner){
 if($Owner-cnotmatch'^[a-f0-9]{32}$'){throw 'SPLIT_MAPPED_OWNER_REQUIRED'}
 $login='ToolbeltSplitMapped_'+$Owner
 $install='Toolbelt_Release_'+$Owner+'_c';$consumer='Toolbelt_Release_'+$Owner+'_u'
 # @Password bleibt ausschließlich im Speicher; @Sid wird vor CREATE separat
 # im privaten Own-Journal gebunden. Diese Vorschau enthält keine Credentials.
 $create=@"
IF EXISTS(SELECT 1 FROM sys.server_principals WHERE name=@Login OR sid=@Sid)
 THROW 52099,N'Owned login name/SID collision.',1;
DECLARE @Ddl nvarchar(max)=N'CREATE LOGIN '+QUOTENAME(@Login)+N' WITH PASSWORD='+QUOTENAME(@Password,N'''')+
 N',SID='+CONVERT(nvarchar(max),@Sid,1)+N',DEFAULT_DATABASE='+QUOTENAME(@Consumer)+N',CHECK_POLICY=ON,CHECK_EXPIRATION=ON;';
EXEC sys.sp_executesql @Ddl;
"@
 return [ordered]@{login=$login;installationDatabase=$install;consumerDatabase=$consumer;
  createLoginCommand=$create;
  consumerMapping="CREATE USER [$login] FOR LOGIN [$login]; GRANT CONNECT TO [$login];";
  installationMapping="CREATE USER [$login] FOR LOGIN [$login]; GRANT CONNECT TO [$login];";
  grant="GRANT SELECT ON OBJECT::toolbelt_string.TVF_SplitAdvanced TO [$login];";
  revoke="REVOKE SELECT ON OBJECT::toolbelt_string.TVF_SplitAdvanced FROM [$login];";
  databaseRightSet=@('CONNECT consumer','CONNECT installation','SELECT installation.toolbelt_string.TVF_SplitAdvanced');
  previewOnly=$true}
}

# Reine Ownership-Prädikate und SQL-Text; keine Verbindung oder Ausführung.
function Test-SplitMappedLoginIdentity($Expected,$Rows){
 $rows=@($Rows)
 return [bool]($rows.Count-eq1-and$Expected.name-cmatch'^ToolbeltSplitMapped_[a-f0-9]{32}$'-and
  $Expected.sid-cmatch'^[A-F0-9]{32}$'-and$Expected.id-gt0-and$Expected.created-cmatch'^[A-F0-9]{16}$'-and
  $rows[0].Name-ceq$Expected.name-and$rows[0].Sid-ceq$Expected.sid-and$rows[0].Id-eq$Expected.id-and
  $rows[0].Created-ceq$Expected.created-and$rows[0].DefaultDatabase-ceq$Expected.consumer-and
  $rows[0].Type-ceq'S'-and$rows[0].Disabled-eq0-and$rows[0].Policy-eq1-and$rows[0].Expiration-eq1)
}
function Get-SplitMappedDropSql{
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
  AND (permission_name<>N'CONNECT SQL' OR state<>N'G'))
 OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE security_id=@Sid OR original_security_id=@Sid)
 THROW 52099,N'Own login role,permission or session consumer changed; cleanup blocked.',2;
DECLARE @Drop nvarchar(max)=N'DROP LOGIN '+QUOTENAME(@Login)+N';';
EXEC sys.sp_executesql @Drop;
'@
}

# Nur echte eigene Netzwerkverbindungen; keine EXECUTE-AS-Simulation.
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'SplitAdvanced.LifecycleProfiles.Contract.ps1') @('Get-SplitLifecycleState')){. $block}
function Get-SplitMappedLoginRows($Master,$Login){
 return @(Invoke-ReleaseSql $Master @'
SELECT p.name Name,CONVERT(varchar(32),p.sid,2) Sid,p.principal_id Id,
 CONVERT(varchar(16),CONVERT(varbinary(8),p.create_date),2) Created,p.default_database_name DefaultDatabase,
 p.type Type,CONVERT(int,p.is_disabled) Disabled,CONVERT(int,l.is_policy_checked) Policy,CONVERT(int,l.is_expiration_checked) Expiration
FROM sys.server_principals p LEFT JOIN sys.sql_logins l ON l.principal_id=p.principal_id
WHERE p.name=@Login OR p.sid=@Sid;
'@ @{'@Login'=$Login.name;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
}
function Get-SplitMappedSidConsumers($Master,$Login,[string[]]$AllowedDatabases=@()){
 $databases=@(Invoke-ReleaseSql $Master 'SELECT name Name,state State FROM sys.databases WHERE database_id>4;' -Rows)
 if($databases.Count-gt128-or@($databases|Where-Object State -NE 0).Count){throw 'SPLIT_MAPPED_FOREIGN_DATABASE_VISIBILITY'}
 $sum=0
 foreach($database in $databases){
  if($database.Name-in$AllowedDatabases){continue}
  $rows=@(Invoke-ReleaseSql $Master @'
DECLARE @Q nvarchar(max)=N'SELECT COUNT(*) N FROM '+QUOTENAME(@Database)+N'.sys.database_principals WHERE sid=@Sid;';
EXEC sys.sp_executesql @Q,N'@Sid varbinary(85)',@Sid;
'@ @{'@Database'=$database.Name;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
  if($rows.Count-ne1){throw 'SPLIT_MAPPED_CONSUMER_OBSERVER_SHAPE'};$sum+=[int]$rows[0].N
 }
 return $sum
}
function Assert-SplitMappedCleanupConsumers($Master,$Login,[string[]]$AllowedDatabases){
 if($null-eq$Login){return}
 $rows=@(Get-SplitMappedLoginRows $Master $Login)
 $Login['cleanupIdentityObservation']=@($rows);Save-ReleaseJournal
 if($rows.Count-eq0){if($Login.state-ceq'ACTIVE'){throw 'SPLIT_MAPPED_LOGIN_DISAPPEARED'};return}
 if($Login.state-cnotin@('CREATE_DISPATCHED','ACTIVE')){throw 'SPLIT_MAPPED_UNKNOWN_LOGIN_OWNER'}
 if($null-eq$Login.id-and$Login.initialAbsenceVerified){
  # Vorab gebundene zufällige SID und Name erlauben die Reconciliation nach
  # verlorener CREATE-Antwort. Default-DB/Typ/Policy bleiben zusätzliche Zeugen.
  if($rows.Count-ne1-or$rows[0].Sid-cne$Login.sid-or$rows[0].Name-cne$Login.name-or$rows[0].DefaultDatabase-cne$Login.consumer){throw 'SPLIT_MAPPED_CREATE_RECONCILIATION_BLOCKED'}
  $Login.id=$rows[0].Id;$Login.created=$rows[0].Created;Save-ReleaseJournal
 }
 if(-not(Test-SplitMappedLoginIdentity $Login $rows)){throw 'SPLIT_MAPPED_LOGIN_IDENTITY_DRIFT'}
 $state=@(Invoke-ReleaseSql $Master @'
SELECT (SELECT COUNT(*) FROM sys.server_role_members WHERE member_principal_id=TRY_CONVERT(int,@Id)) Roles,
 (SELECT COUNT(*) FROM sys.server_permissions WHERE grantee_principal_id=TRY_CONVERT(int,@Id) AND (permission_name<>N'CONNECT SQL' OR state<>N'G')) ExtraPermissions,
 (SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE security_id=@Sid OR original_security_id=@Sid) Sessions;
'@ @{'@Id'=$Login.id;'@Sid'=[Convert]::FromHexString($Login.sid)} -Rows)
 if($state.Count-ne1-or$state[0].Roles-ne0-or$state[0].ExtraPermissions-ne0-or$state[0].Sessions-ne0-or(Get-SplitMappedSidConsumers $Master $Login $AllowedDatabases)-ne0){throw 'SPLIT_MAPPED_FOREIGN_CONSUMER_OR_RIGHT_DRIFT'}
 $Login.connectionCount=0;Save-ReleaseJournal
}
function Remove-SplitMappedLogin($Master,$Login){
 if($null-eq$Login){return}
 $rows=@(Get-SplitMappedLoginRows $Master $Login)
 if($rows.Count-eq0){$Login.state='ABSENT';return}
 Assert-SplitMappedCleanupConsumers $Master $Login @()
 Invoke-ReleaseSql $Master (Get-SplitMappedDropSql) @{'@Login'=$Login.name;'@Sid'=[Convert]::FromHexString($Login.sid);'@PrincipalId'=$Login.id;'@Created'=[Convert]::FromHexString($Login.created);'@Consumer'=$Login.consumer}
 if(@(Get-SplitMappedLoginRows $Master $Login).Count-ne0){throw 'SPLIT_MAPPED_LOGIN_DROP_UNVERIFIED'}
 $Login.state='DROPPED'
}
function Assert-SplitMappedLoginAbsent($Master,$Login){
 if($null-eq$Login){return}
 if($Login.name-cnotmatch'^ToolbeltSplitMapped_[a-f0-9]{32}$'-or$Login.sid-cnotmatch'^[A-F0-9]{32}$'-or$Login.state-cnotin@('ABSENT','DROPPED')){throw 'SPLIT_MAPPED_AUDIT_LOGIN_STATE'}
 if(@(Get-SplitMappedLoginRows $Master $Login).Count-ne0-or(Get-SplitMappedSidConsumers $Master $Login @())-ne0){throw 'SPLIT_MAPPED_AUDIT_LOGIN_OR_MAPPING_PRESENT'}
}
function Open-SplitMappedCaller($Admin,[string]$Database,[string]$Password){
 $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new($Admin.ConnectionString)
 $builder['Integrated Security']=$false;$builder['User ID']=$ledger.login.name;$builder['Password']=$Password
 $builder['Initial Catalog']=$Database;$builder['Pooling']=$false;$builder['Enlist']=$false;$builder['ConnectRetryCount']=0
 $builder['MultipleActiveResultSets']=$false
 $builder['Connect Timeout']=[Math]::Min(10,(Get-ReleaseTimeout))
 $caller=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$builder.Clear()
 $connections.Add($caller)
 try{$caller.Open();return $caller}catch{$caller.Dispose();throw}
}
function Assert-SplitMappedDenied($Channel,[string]$Text,[int]$Number,[string]$Profile){
 $observed=$false
 try{Invoke-ReleaseSql $Channel $Text}catch{
  $leaf=$_.Exception;while($leaf-and$leaf-isnot[Data.SqlClient.SqlException]){$leaf=$leaf.InnerException}
  if(-not$leaf){throw}
  $errors=@($leaf.Errors|Where-Object Class -GE 11)
  if($errors.Count-eq0-or@($errors|Where-Object Number -NE $Number).Count){
   $ledger['privateDenialDiagnostic']=@{profile=$Profile;expected=$Number;actualNumbers=@($errors|ForEach-Object Number);actualStates=@($errors|ForEach-Object State)};Save-ReleaseJournal
   throw 'SPLIT_MAPPED_WRONG_DENIAL'
  }
  $observed=$true
 }
 if(-not$observed){throw 'SPLIT_MAPPED_EXPECTED_DENIAL_MISSING'}
 $ledger.profileCompletions+=@(@{mode='central';profile=$Profile;number=$Number;passed=$true});Save-ReleaseJournal
}
function Get-SplitMappedGoldenSql([string]$Database){
 if($Database-cnotmatch'^Toolbelt_Release_[a-f0-9]{32}_c$'){throw 'SPLIT_MAPPED_OWN_INSTALL_DATABASE_REQUIRED'}
 return @"
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM [$Database].toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT) ORDER BY Ordinal;
"@
}
function Assert-SplitMappedNetwork($Caller){
 $tag=[guid]::NewGuid().ToByteArray()
 Invoke-ReleaseSql $Caller 'SET CONTEXT_INFO @Tag;' @{'@Tag'=$tag}
 $row=@(Invoke-ReleaseSql $Caller 'SELECT @@SPID Spid,ORIGINAL_LOGIN() LoginName,SUSER_SID() Sid,USER_NAME() UserName,IS_SRVROLEMEMBER(N''sysadmin'') Admin,IS_ROLEMEMBER(N''db_owner'') OwnerRole,HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''CONTROL'') DbControl,HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''VIEW DEFINITION'') Definition,HAS_PERMS_BY_NAME(NULL,NULL,N''CONTROL SERVER'') ServerControl,HAS_PERMS_BY_NAME(NULL,NULL,N''VIEW ANY DEFINITION'') AnyDefinition,HAS_PERMS_BY_NAME(NULL,NULL,N''VIEW SERVER STATE'') ServerState,HAS_PERMS_BY_NAME(NULL,NULL,N''VIEW SERVER PERFORMANCE STATE'') ServerPerformanceState;' -Rows)
 $sample=[ordered]@{rows=@($row);networkObserver=@()};$ledger.mappedReceipts[-1].networkObservations+=@($sample);Save-ReleaseJournal
 if($row.Count-ne1-or$row[0].LoginName-cne$ledger.login.name-or$row[0].UserName-cne$ledger.login.name-or
    [Convert]::ToHexString([byte[]]$row[0].Sid)-cne$ledger.login.sid-or@('Admin','OwnerRole','DbControl','Definition','ServerControl','AnyDefinition','ServerState','ServerPerformanceState'|Where-Object{$row[0].$_-ne0}).Count){throw 'SPLIT_MAPPED_CALLER_NOT_MINIMAL'}
 $observed=@(Invoke-ReleaseSql $control @'
SELECT COUNT(*) N FROM sys.dm_exec_connections c JOIN sys.dm_exec_sessions s ON s.session_id=c.session_id
WHERE s.session_id=TRY_CONVERT(int,@Spid) AND s.context_info=@Tag
AND s.security_id=@Sid AND s.original_security_id=@Sid AND c.auth_scheme=N'SQL' AND c.net_transport=N'TCP';
'@ @{'@Tag'=$tag;'@Spid'=$row[0].Spid;'@Sid'=[Convert]::FromHexString($ledger.login.sid)} -Rows)
 $sample.networkObserver=@($observed);Save-ReleaseJournal
 if($observed.Count-ne1-or$observed[0].N-ne1){throw 'SPLIT_MAPPED_REAL_SQL_TCP_IDENTITY_REQUIRED'}
}
function Invoke-SplitMappedProfiles($Db,[string]$Mode){
 if($Mode-cne'central'){throw 'SPLIT_MAPPED_CENTRAL_ONLY'}
 $before=Get-SplitLifecycleState $Db
 $plan=Get-SplitMappedPermissionPlan $ledger.owner
 if($Db.Database-cne$plan.installationDatabase){throw 'SPLIT_MAPPED_INSTALLATION_OWNER_MISMATCH'}
 $name=$plan.consumerDatabase;$entry=[ordered]@{name=$name;suffix='u';id=$null;created=$null;state='CREATING'}
 $ledger.databases+=@($entry);Save-ReleaseJournal
 Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Owned consumer collision.',1;CREATE DATABASE [$name] COLLATE Latin1_General_100_BIN2;"
 $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
 if($identity.Count-ne1){throw 'SPLIT_MAPPED_CONSUMER_IDENTITY'};$entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
 $consumer=Open-ReleaseConnection $name
 Invoke-ReleaseSql $consumer "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
 $entry.state='OWNED';Save-ReleaseJournal;Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=170;"
 foreach($channel in @($Db,$consumer)){
  $safe=@(Invoke-ReleaseSql $channel 'SELECT is_trustworthy_on T,is_db_chaining_on C FROM sys.databases WHERE database_id=DB_ID();' -Rows)
  if($safe.Count-ne1-or$safe[0].T-or$safe[0].C){throw 'SPLIT_MAPPED_DATABASE_SECURITY_BASELINE'}
 }
 $ledger.login=[ordered]@{name=$plan.login;sid=[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(16));consumer=$name;id=$null;created=$null;state='INTENT';initialAbsenceVerified=$false;connectionCount=$null};Save-ReleaseJournal
 if(@(Get-SplitMappedLoginRows $control $ledger.login).Count-or(Get-SplitMappedSidConsumers $control $ledger.login @())-ne0){throw 'SPLIT_MAPPED_LOGIN_OR_SID_COLLISION'}
 $ledger.login.initialAbsenceVerified=$true;$ledger.login.state='CREATE_DISPATCHED';Save-ReleaseJournal
 $password='aA1!'+[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
 $receipt=[ordered]@{mode='central';realNetwork=$false;sidMappings=$false;goldenRows=0;networkObservations=@();passed=$false};$ledger.mappedReceipts+=@($receipt);Save-ReleaseJournal
 try{
  Invoke-ReleaseSql $control $plan.createLoginCommand @{'@Login'=$plan.login;'@Sid'=[Convert]::FromHexString($ledger.login.sid);'@Password'=$password;'@Consumer'=$name}
  $created=@(Get-SplitMappedLoginRows $control $ledger.login)
  if($created.Count-ne1){throw 'SPLIT_MAPPED_CREATED_LOGIN_REQUIRED'}
  $ledger.login.id=$created[0].Id;$ledger.login.created=$created[0].Created;$ledger.login.state='ACTIVE';Save-ReleaseJournal
  if(-not(Test-SplitMappedLoginIdentity $ledger.login $created)){throw 'SPLIT_MAPPED_CREATED_LOGIN_SHAPE'}
  Invoke-ReleaseSql $consumer $plan.consumerMapping
  $query=Get-SplitMappedGoldenSql $Db.Database
  $caller=Open-SplitMappedCaller $Db $name $password
  try{
   Assert-SplitMappedNetwork $caller;$receipt.realNetwork=$true;Save-ReleaseJournal
   Assert-SplitMappedDenied $caller ('EXEC ['+$Db.Database+'].sys.sp_executesql N''SELECT USER_NAME();'';') 916 'unmapped-916'
  }finally{$caller.Dispose()}
  Invoke-ReleaseSql $Db $plan.installationMapping
  $caller=Open-SplitMappedCaller $Db $name $password
  try{Assert-SplitMappedDenied $caller $query 229 'connect-only-229'}finally{$caller.Dispose()}
  Invoke-ReleaseSql $Db $plan.grant
  foreach($channel in @($Db,$consumer)){
   $mapping=@(Invoke-ReleaseSql $channel 'SELECT COUNT(*) N FROM sys.database_principals WHERE name=@Login AND sid=@Sid AND type=N''S'';' @{'@Login'=$plan.login;'@Sid'=[Convert]::FromHexString($ledger.login.sid)} -Rows)
   if($mapping.Count-ne1-or$mapping[0].N-ne1){throw 'SPLIT_MAPPED_EXACT_SID_MAPPING_REQUIRED'}
  }
  $receipt.sidMappings=$true;Save-ReleaseJournal
  $caller=Open-SplitMappedCaller $Db $name $password
  try{
   Assert-SplitMappedNetwork $caller
   $rows=@(Invoke-ReleaseSql $caller $query -Rows);$values=@('a','"b;c"','d')
   $receipt['goldenObservation']=@($rows);Save-ReleaseJournal
   if($rows.Count-ne3){throw 'SPLIT_MAPPED_GOLDEN_ROW_COUNT'}
   for($i=0;$i-lt3;$i++){if($rows[$i].Value-cne$values[$i]-or$rows[$i].Ordinal-ne($i+1)-or$rows[$i].IsValid-ne$true-or$rows[$i].ErrorCode-isnot[DBNull]-or$rows[$i].ErrorPosition-isnot[DBNull]){throw 'SPLIT_MAPPED_GOLDEN_VALUES'}}
   $receipt.goldenRows=3;$ledger.profileCompletions+=@(@{mode='central';profile='select-golden';passed=$true});Save-ReleaseJournal
   Assert-SplitMappedDenied $caller ('SELECT * FROM ['+$Db.Database+'].toolbelt_string.TVF_UnquoteToken(N''a'',DEFAULT,DEFAULT,DEFAULT);') 229 'other-api-229'
   Assert-SplitMappedDenied $caller ('EXEC ['+$Db.Database+'].toolbelt_core.USP_PrepareResultTable @Hilfe=1;') 229 'helper-229'
  }finally{$caller.Dispose()}
  Invoke-ReleaseSql $Db $plan.revoke
  $caller=Open-SplitMappedCaller $Db $name $password
  try{Assert-SplitMappedDenied $caller $query 229 'revoked-229'}finally{$caller.Dispose()}
  $receipt.passed=$true;Save-ReleaseJournal
 }finally{$password=$null}
 if((Get-SplitLifecycleState $Db)-cne$before){throw 'SPLIT_MAPPED_MODULE_STATE_CHANGED'}
}
