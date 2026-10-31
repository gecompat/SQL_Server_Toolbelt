[CmdletBinding()]
param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$MasterConnection,
 [Parameter(Mandatory)][string]$AdminConnectionString,
 [Parameter(Mandatory)][string]$CrossDatabase,
 [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{32}$')][string]$RunId,
 [Parameter(Mandatory)][string]$JournalPath,
 [Parameter(Mandatory)][string]$LabModuleFile,
 [Parameter(Mandatory)][string]$TargetRunId,
 [Parameter(Mandatory)][string]$TargetInstanceId,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [ValidateRange(0,180)][int]$GuiWaitSeconds=0
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$admin=$Connection
$moduleDatabase=$admin.Database
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:v2Checks=0
$script:v2TSqlVersion=[int16](Query $admin 'SELECT compatibility_level AS C FROM sys.databases WHERE database_id=DB_ID();').Rows[0].C
# Die typisierten Aufrufe und die exakte DebugScript-Batchbindung bleiben
# dieselben wie in der aktuellen Fachabnahme. Nur Definitionen werden geladen.
foreach($source in @(
 @{File='Invoke-CurrentQualificationCases.ps1';Names=@('Assert-V2','Invoke-V2Explain')},
 @{File='Invoke-CurrentCases.ps1';Names=@('Invoke-CurrentDebugScript')}
)){
 $errors=$null
 $tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $source.File),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'SSIS_ACCESS_HELPER_SYNTAX'}
 foreach($name in $source.Names){
  $definition=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
  if($definition.Count -ne 1){throw 'SSIS_ACCESS_HELPER_AMBIGUOUS'}
  . ([scriptblock]::Create($definition[0].Extent.Text))
 }
}
function Assert-Current([bool]$Value,[string]$Name){Assert-V2 $Value $Name}
function Invoke-CurrentSql([string]$Sql){return ,(Query $Connection $Sql)}
function Sql-Access([Data.SqlClient.SqlConnection]$Channel,[string]$Sql){return ,(Query $Channel $Sql)}
function Reject-Access([scriptblock]$Action,[int]$Number,[string]$Code=''){
 $denied=$false
 try{& $Action|Out-Null}catch{
  $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
  if($leaf -isnot [Data.SqlClient.SqlException]){throw ('SSIS_ACCESS_REJECTION_CLIENT_'+$leaf.GetType().Name)}
  if($leaf.Number -ne $Number -or ($Code -and -not $leaf.Message.Contains($Code))){throw ('SSIS_ACCESS_WRONG_REJECTION_SQL_'+$leaf.Number+'_EXPECTED_'+$Number)}
  $denied=$true
 }
 Assert-V2 $denied ('DENIED_'+$Number+'_'+$Code)
}
function Open-Access {
 $channel=[Data.SqlClient.SqlConnection]::new($callerBuilder.ConnectionString)
 try{$channel.Open();return $channel}catch{$channel.Dispose();throw}
}
function Save-AccessJournal {$identityJournal|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $JournalPath -Encoding utf8}
$login='ToolbeltSsisAccess_'+$RunId.Substring(0,16)
$sid=[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
$password='aA1!'+[Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$identityJournal=[ordered]@{schemaVersion=1;profile='ssis-current-access';runId=$RunId;state='INTENT';login=$login;sid=$sid;principalId=$null;createDate=$null;checks=0;windowsChecks=0;windowsAuthentication='not executed';gui='not executed';authenticatedTls='not executed'}
if(Test-Path -LiteralPath $JournalPath){throw 'SSIS_ACCESS_JOURNAL_COLLISION'}
Save-AccessJournal
$callerBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new($AdminConnectionString)
$callerBuilder['User ID']=$login;$callerBuilder['Password']=$password;$callerBuilder['Initial Catalog']=$CrossDatabase
$callerBuilder['Pooling']=$false;$callerBuilder['Connect Timeout']=10
$procedure='['+$moduleDatabase+'].toolbelt_tsql.USP_ExplainSsisDataFlow'
$consumerBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new($AdminConnectionString)
$consumerBuilder['Initial Catalog']=$CrossDatabase
$consumer=[Data.SqlClient.SqlConnection]::new($consumerBuilder.ConnectionString)
$caller=$null;$created=$false;$failed=$false
try{
 $consumer.Open()
 $collision=Sql-Access $MasterConnection ("SELECT COUNT_BIG(*) AS N FROM sys.server_principals WHERE name=N'"+$login+"' OR sid=0x"+$sid+';')
 Assert-V2 ($collision.Rows[0].N -eq 0) 'LOGIN_AND_SID_ABSENT'
 $identityJournal.state='CREATE_DISPATCHED';Save-AccessJournal
 [void](Sql-Access $MasterConnection ("CREATE LOGIN ["+$login+"] WITH PASSWORD=N'"+$password+"',SID=0x"+$sid+",CHECK_POLICY=ON,CHECK_EXPIRATION=OFF;"))
 $created=$true
 $witness=Sql-Access $MasterConnection ("SELECT principal_id,create_date FROM sys.server_principals WHERE name=N'"+$login+"' AND sid=0x"+$sid+';')
 Assert-V2 ($witness.Rows.Count -eq 1) 'CREATED_LOGIN_IDENTITY'
 $identityJournal.principalId=[int]$witness.Rows[0].principal_id;$identityJournal.createDate=([datetime]$witness.Rows[0].create_date).ToString('o');$identityJournal.state='ACTIVE';Save-AccessJournal
 foreach($channel in @($admin,$consumer)){
  $safe=Sql-Access $channel 'SELECT is_trustworthy_on,is_db_chaining_on FROM sys.databases WHERE database_id=DB_ID();'
  Assert-V2 (-not $safe.Rows[0].is_trustworthy_on -and -not $safe.Rows[0].is_db_chaining_on) 'NO_TRUSTWORTHY_OR_DATABASE_CHAINING'
 }
 [void](Sql-Access $consumer ('CREATE USER ['+$login+'] FOR LOGIN ['+$login+'];GRANT CONNECT TO ['+$login+'];'))
 [void](Sql-Access $consumer @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
'@)
 [xml]$document=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
 foreach($component in $document.SelectNodes('//component[@name="Derived" or @name="Split"]')){
  $input=$component.SelectSingleNode('inputs/input').GetAttribute('refId')
  foreach($port in $component.SelectNodes('outputs/output')){$port.SetAttribute('synchronousInputId',$input)}
 }
 $package=[Text.Encoding]::UTF8.GetBytes($document.OuterXml)
 $catalog=@{schemaVersion=2;defaultDatabase=$CrossDatabase;databases=@($CrossDatabase);connections=@{'Package.ConnectionManagers[Synthetic]'=$CrossDatabase};flatFileInputs=@{}}|ConvertTo-Json -Depth 5 -Compress
 $caller=Open-Access;$Connection=$caller
 $identity=Sql-Access $caller ("SELECT CASE WHEN ORIGINAL_LOGIN()=N'"+$login+"' AND SUSER_SNAME()=N'"+$login+"' THEN 1 ELSE 0 END AS OwnIdentity,IS_SRVROLEMEMBER(N'sysadmin') AS Admin,IS_MEMBER(N'db_owner') AS Owner,CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) AS Auth;")
 Assert-V2 ($identity.Rows[0].OwnIdentity -eq 1 -and $identity.Rows[0].Admin -eq 0 -and $identity.Rows[0].Owner -eq 0 -and $identity.Rows[0].Auth -ceq 'SQL') 'REAL_LOWPRIV_NETWORK_LOGIN'
 Reject-Access {Invoke-V2Explain -Bytes $package -Help $true -Procedure $procedure} 916
 $caller.Dispose();$caller=$null
 [void](Sql-Access $admin ('CREATE USER ['+$login+'] FOR LOGIN ['+$login+'];GRANT CONNECT TO ['+$login+'];GRANT EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO ['+$login+'];'))
 $caller=Open-Access;$Connection=$caller
 Assert-V2 ((Invoke-V2Explain -Bytes $package -Help $true -Procedure $procedure).Rows.Count -gt 0) 'HELP_EXECUTE_ONLY_CROSS_DATABASE'
 Reject-Access {Invoke-V2Explain -Bytes $package -Procedure $procedure} 50000 'TBX_SSISDBG_unresolved_dependency'
 $caller.Dispose();$caller=$null
 foreach($channel in @($admin,$consumer)){
  [void](Sql-Access $channel ('GRANT VIEW DEFINITION TO ['+$login+'];GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO ['+$login+'];GRANT SELECT ON OBJECT::sys.security_predicates TO ['+$login+'];'))
 }
 $caller=Open-Access;$Connection=$caller
 $template=Invoke-V2Explain -Bytes $package -Procedure $procedure
 Assert-V2 ($template.Rows.Count -eq 1 -and $template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'TEMPLATE_MAPPED_IDENTITIES'
 $bindings=[string]$template.Rows[0].Content
 $artifacts=Invoke-V2Explain -Bytes $package -Operation explain -Bindings $bindings -Catalog $catalog -Stage all -Procedure $procedure
 Assert-V2 (@($artifacts.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'CROSS_DATABASE_METADATA_WITHOUT_SOURCE_SELECT'
 Assert-V2 ((Sql-Access $caller "SELECT HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'SELECT') AS N;").Rows[0].N -eq 0) 'NO_SOURCE_SELECT'
 $source=@($artifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'StageSql' -and $_.ComponentId -ceq 'Package\Flow\SourceA'})
 Assert-V2 ($source.Count -eq 2) 'SOURCE_STAGE_WITNESS'
 $detail=([string]$source[0].DetailsJson)|ConvertFrom-Json -Depth 32
 $units=@($artifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'PlanUnitSql' -and (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)}|Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).ordinal})
 $cleanup=@($artifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'CleanupSql' -and (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)}|Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).cleanupOrdinal})
 Assert-V2 ($units.Count -gt 0 -and $cleanup.Count -gt 0) 'SOURCE_PLAN_AND_CLEANUP'
 # Wie im aktuellen Rechteorakel wird der geordnete Plan gestartet. Eine
 # fehlende Planvorbereitung wäre kein Nachweis verweigerten Quell-SELECTs.
 try{Reject-Access {foreach($unit in $units){[void](Sql-Access $caller ([string]$unit.Content))}} 229}
 finally{foreach($row in $cleanup){[void](Sql-Access $caller ([string]$row.Content))}}
 $caller.Dispose();$caller=$null
 [void](Sql-Access $consumer ('GRANT SELECT ON OBJECT::dbo.SyntheticSourceA TO ['+$login+'];GRANT SELECT ON OBJECT::dbo.SyntheticSourceB TO ['+$login+'];GRANT SELECT ON OBJECT::dbo.SyntheticLookup TO ['+$login+'];'))
 $caller=Open-Access;$Connection=$caller
 $rights=Sql-Access $caller "SELECT IS_MEMBER(N'db_owner') AS Owner,HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE') AS CreateTable,HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'INSERT') AS InsertRows,HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'UPDATE') AS UpdateRows,HAS_PERMS_BY_NAME(N'dbo.SyntheticSourceA',N'OBJECT',N'DELETE') AS DeleteRows;"
 foreach($right in @('Owner','CreateTable','InsertRows','UpdateRows','DeleteRows')){Assert-V2 ($rights.Rows[0].$right -eq 0) ('NO_'+$right)}
 foreach($bundle in @($artifacts.Select("ArtifactKind='DebugScript' AND IsExecutable=true",'Ordinal'))){
  $result=Invoke-CurrentDebugScript $artifacts $bundle
  $high=$bundle.ComponentId -ceq 'Package\Flow\DestinationHigh'
  Assert-V2 ($result.TargetSql.Rows.Count -eq $(if($high){2}else{3})) 'LOWPRIV_EXECUTED_DEBUGSCRIPT_FIXED_ROWS'
  if($high){Assert-V2 (@($result.TargetSql.Select('KeyA=2 AND KeyB=10')).Count -eq 1) 'HIGH_COMPOSITE_KEY'}
  else{Assert-V2 (@($result.TargetSql.Select('KeyA=1 AND KeyB=20')).Count -eq 1 -and $result.TargetSql.Select('KeyA=1 AND KeyB=20')[0].IsNull('Score')) 'LOW_NULL_LOOKUP'}
 }
 $caller.Dispose();$caller=$null
 [void](Sql-Access $consumer ('DROP USER ['+$login+'];'))
 $callerBuilder['Initial Catalog']=$moduleDatabase
 $caller=Open-Access;$Connection=$caller
 Assert-V2 ((Sql-Access $caller ("SELECT HAS_DBACCESS(N'"+$CrossDatabase+"') AS N;")).Rows[0].N -eq 0) 'SOURCE_DATABASE_UNMAPPED'
 Reject-Access {Invoke-V2Explain -Bytes $package -Operation explain -Bindings $bindings -Catalog $catalog -Procedure $procedure} 50000 'TBX_SSISDBG_catalog_visibility'
 $caller.Dispose();$caller=$null
 $callerBuilder['Initial Catalog']=$CrossDatabase
 [void](Sql-Access $consumer ('CREATE USER ['+$login+'] FOR LOGIN ['+$login+'];GRANT CONNECT TO ['+$login+'];GRANT VIEW DEFINITION TO ['+$login+'];GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO ['+$login+'];GRANT SELECT ON OBJECT::sys.security_predicates TO ['+$login+'];GRANT SELECT ON OBJECT::dbo.SyntheticSourceA TO ['+$login+'];GRANT SELECT ON OBJECT::dbo.SyntheticSourceB TO ['+$login+'];GRANT SELECT ON OBJECT::dbo.SyntheticLookup TO ['+$login+'];'))
 # Ein korrekt gemappter Consumer ersetzt keine Identität in der Modul-DB.
 [void](Sql-Access $admin ('DROP USER ['+$login+'];'))
 $caller=Open-Access;$Connection=$caller
 Reject-Access {Invoke-V2Explain -Bytes $package -Operation explain -Bindings $bindings -Catalog $catalog -Procedure $procedure} 916
 $caller.Dispose();$caller=$null
 [void](Sql-Access $admin ('CREATE USER ['+$login+'] FOR LOGIN ['+$login+'];GRANT CONNECT TO ['+$login+'];GRANT EXECUTE ON OBJECT::toolbelt_tsql.USP_ExplainSsisDataFlow TO ['+$login+'];GRANT VIEW DEFINITION TO ['+$login+'];GRANT SELECT ON OBJECT::sys.sql_expression_dependencies TO ['+$login+'];GRANT SELECT ON OBJECT::sys.security_predicates TO ['+$login+'];'))
 # Die SID-Verknüpfung beider Datenbanken ist ein gemessener Bestandteil.
 foreach($channel in @($admin,$consumer)){
  Assert-V2 ((Sql-Access $channel ("SELECT COUNT_BIG(*) AS N FROM sys.database_principals WHERE name=N'"+$login+"' AND sid=0x"+$sid+';')).Rows[0].N -eq 1) 'EXACT_USER_LOGIN_SID_MAPPING'
 }
 $Connection=$admin
 $identityJournal.checks=$script:v2Checks;Save-AccessJournal
 & (Join-Path $PSScriptRoot 'Invoke-CurrentWindowsAccessCases.ps1') -LabModuleFile $LabModuleFile -TargetRunId $TargetRunId -TargetInstanceId $TargetInstanceId -ModuleDatabase $moduleDatabase -ConsumerDatabase $CrossDatabase -PackageBytes $package -Catalog $catalog -Artifacts $artifacts -QualifiedProviderSha512 $QualifiedProviderSha512 -JournalDirectory (Split-Path -Parent $JournalPath)
 $windowsRecord=Get-Content -LiteralPath (Join-Path (Split-Path -Parent $JournalPath) 'windows-result.json') -Raw|ConvertFrom-Json
 Assert-V2 ($windowsRecord.result -ceq 'PASS') 'WINDOWS_RESULT'
 $identityJournal.windowsChecks=$windowsRecord.checks;$identityJournal.windowsAuthentication='PASS';$identityJournal.checks=$script:v2Checks
 if($GuiWaitSeconds){
  & (Join-Path $PSScriptRoot 'Invoke-CurrentGuiAccessCase.ps1') -Connection $consumer -ModuleDatabase $moduleDatabase -PackageBytes $package -Catalog $catalog -QualifiedProviderSha512 $QualifiedProviderSha512 -JournalDirectory (Split-Path -Parent $JournalPath) -WaitSeconds $GuiWaitSeconds
  $identityJournal.gui='SQL_PASS; visual inspection required';Save-AccessJournal
 }
}catch{
 $failed=$true
 $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
 $identityJournal.failure=if($leaf -is [Data.SqlClient.SqlException]){'SQL_'+$leaf.Number}else{$leaf.Message -replace '[^A-Za-z0-9_]','_'}
 if($identityJournal.failure.Length -gt 180){$identityJournal.failure=$identityJournal.failure.Substring(0,180)}
 throw ('SSIS_ACCESS_CASE_FAILED_'+$identityJournal.failure)
}finally{
 $Connection=$admin
 if($caller){$caller.Dispose()}
 $consumer.Dispose()
 # Kein KILL und keine namenbasierte fremde Löschung. Nur exakte eigene SID,
 # Principal-ID und Erstellungsidentität erlauben den Drop des Testlogins.
 $cleanup=$false
 $remaining=Sql-Access $MasterConnection ("SELECT principal_id,create_date,sid FROM sys.server_principals WHERE name=N'"+$login+"';")
 if($remaining.Rows.Count -eq 0){$cleanup=$true}
 elseif($created -and [Convert]::ToHexString([byte[]]$remaining.Rows[0].sid) -ceq $sid -and $remaining.Rows[0].principal_id -eq $identityJournal.principalId -and ([datetime]$remaining.Rows[0].create_date).ToString('o') -ceq $identityJournal.createDate){
  $sessions=Sql-Access $MasterConnection ('SELECT COUNT_BIG(*) AS N FROM sys.dm_exec_sessions WHERE security_id=0x'+$sid+';')
  if($sessions.Rows[0].N -eq 0){[void](Sql-Access $MasterConnection ('DROP LOGIN ['+$login+'];'));$cleanup=(Sql-Access $MasterConnection ("SELECT COUNT_BIG(*) AS N FROM sys.server_principals WHERE name=N'"+$login+"' OR sid=0x"+$sid+';')).Rows[0].N -eq 0}
 }
 $identityJournal.checks=$script:v2Checks
 $identityJournal.state=if($cleanup){if($failed){'FAILED_CLEANED'}else{'PASS_CLEANED'}}else{'RECOVERY_REQUIRED'}
 Save-AccessJournal
 $password=$null;$callerBuilder.Clear()
 if(-not $cleanup){throw 'SSIS_ACCESS_LOGIN_RECOVERY_REQUIRED'}
}
"SSIS_CURRENT_ACCESS_PASS $script:v2Checks assertions; real lowpriv network login and exact cross-database SID mappings"
