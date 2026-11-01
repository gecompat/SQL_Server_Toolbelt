#Requires -Version 7.5
<#
Native Abnahme des getrennten administrativen SSIS-Trustskripts.
Nur der unveränderte, bereits qualifizierte aktuelle Releasehash darf die
Trustoperation erreichen. Keine Konfiguration, Rechtevergabe oder Labverwaltung.
Plan, Originalfehler und Wiederherstellungsdaten bleiben ausschließlich lokal.
#>
[CmdletBinding()]
param(
 [ValidateSet('Prepare','Qualify','Audit')][string]$Mode='Prepare',
 [Parameter(Mandatory)][string]$PlanPath,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPlanSha256,
 [ValidateRange(0,2)][int]$CaseIndex=0,
 [string]$JournalPath,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedJournalSha256,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$module='Modules/toolbelt.tsql.ssis-debug/'
$qualified=$module+'Tests/Qualification/Current.Functional.20261031.json'
$trustFile=$module+'Deployment/Add-TrustedAssembly.sql'
$method=$module+'Tests/InstallerTrust/Invoke-LabTrust.ps1'
. (Join-Path $root 'Tests/CI/LabQualifiedContract.ps1')
$discovery=Join-Path $root 'Tests/CI/run-lab-local.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($discovery,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'SSIS_TRUST_DISCOVERY_SYNTAX'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definitions=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
 if($definitions.Count -ne 1){throw 'SSIS_TRUST_DISCOVERY_NOT_UNIQUE'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
function FileHash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function SavePrivate([string]$Path,$Value){
 [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 14),[Text.UTF8Encoding]::new($false))
}
function Assert-Inputs($Plan){
 if($Plan.contract -cne 'ssis-administrative-trust-plan/1' -or $Plan.targets.Count -ne 3){throw 'SSIS_TRUST_PLAN_SCHEMA'}
 if((@($Plan.targets|ForEach-Object{[string]$_.version+'/'+[string]$_.patch}) -join ';') -cne '2019/CU32;2022/CU26;2025/CU8'){throw 'SSIS_TRUST_PLAN_TARGET_MATRIX'}
 $required=@($method,$trustFile,$qualified,'Tests/CI/LabQualifiedContract.ps1','Tests/CI/run-lab-local.ps1',$Plan.package)
 if(@($Plan.files.psobject.Properties).Count -ne $required.Count){throw 'SSIS_TRUST_INPUT_CLOSURE'}
 foreach($relative in $required){
  if($relative -match '\\|(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($relative)){throw 'SSIS_TRUST_INPUT_PATH'}
  if((FileHash (Join-Path $root $relative)) -cne $Plan.files.$relative){throw 'SSIS_TRUST_INPUT_CHANGED'}
 }
 if((FileHash $Plan.dllPath) -cne $Plan.dllSha256 -or
    (Get-FileHash -LiteralPath $Plan.dllPath -Algorithm SHA512).Hash -cne $Plan.approvedHash){throw 'SSIS_TRUST_APPROVED_BINARY_CHANGED'}
 # Ein vom Aufrufer neu versiegelter Plan darf keinen beliebigen Binaryhash
 # autorisieren. Herkunft nochmals unabhängig gegen die unveränderte öffentliche
 # Funktionsabnahme und deren exakt gebundenen Lieferbytes prüfen.
 if((FileHash (Join-Path $root $qualified)) -cne 'BB3BB417B4E571CE2D201A10988FA4015080586EE19E8C85CB87FA259E61E8B5'){throw 'SSIS_TRUST_QUALIFICATION_RECORD_CHANGED'}
 $delivery=Get-Content -LiteralPath (Join-Path $root $qualified) -Raw|ConvertFrom-Json
 if($Plan.package -cne $delivery.current_delivery.package -or
    (FileHash (Join-Path $root $Plan.package)).ToLowerInvariant() -cne $delivery.current_delivery.package_sha256 -or
    $Plan.dllSha256.ToLowerInvariant() -cne $delivery.current_delivery.assembly_sha256){throw 'SSIS_TRUST_APPROVED_RELEASE_ORIGIN_MISMATCH'}
 $archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $root $Plan.package))
 try{
  $reader=[IO.StreamReader]::new($archive.GetEntry('SSIS-BUILD.json').Open())
  try{$build=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
 }finally{$archive.Dispose()}
 if($Plan.approvedHash -cne $build.sha512 -or $build.sourceFingerprintSha256 -cne $delivery.current_delivery.source_fingerprint_sha256){throw 'SSIS_TRUST_APPROVED_RELEASE_ORIGIN_MISMATCH'}
}
if($Mode -ceq 'Prepare'){
 if(Test-Path -LiteralPath $PlanPath){throw 'SSIS_TRUST_PLAN_COLLISION'}
 $privateRoot=Split-Path -Parent ([IO.Path]::GetFullPath($PlanPath))
 [void][IO.Directory]::CreateDirectory($privateRoot)
 $record=Get-Content -LiteralPath (Join-Path $root $qualified) -Raw|ConvertFrom-Json
 $package=[string]$record.current_delivery.package
 if((FileHash (Join-Path $root $package)).ToLowerInvariant() -cne $record.current_delivery.package_sha256){throw 'SSIS_TRUST_DELIVERY_CHANGED'}
 $archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $root $package))
 try{
  $reader=[IO.StreamReader]::new($archive.GetEntry('SSIS-BUILD.json').Open())
  try{$build=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
  $reader=[IO.StreamReader]::new($archive.GetEntry('Install-Windows-local.sql').Open())
  try{$installer=$reader.ReadToEnd()}finally{$reader.Dispose()}
 }finally{$archive.Dispose()}
 if($build.moduleId -cne 'toolbelt.tsql.ssis-debug' -or $build.sourceFingerprintSha256 -cne $record.current_delivery.source_fingerprint_sha256){throw 'SSIS_TRUST_BUILD_IDENTITY'}
 foreach($binding in $build.sourceFiles){
  $parts=$binding.Split(':',2)
  if((FileHash (Join-Path $root ($module+$parts[0]))) -cne $parts[1]){throw 'SSIS_TRUST_PRODUCT_SOURCE_CHANGED'}
 }
 $binaries=@(foreach($match in [regex]::Matches($installer,'0x([0-9A-Fa-f]{4096,})')){
  $bytes=[Convert]::FromHexString($match.Groups[1].Value)
  if([Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($bytes)) -ceq $build.sha512){,$bytes}
 })
 if($binaries.Count -ne 1){throw 'SSIS_TRUST_DELIVERED_BINARY_NOT_UNIQUE'}
 $dllPath=Join-Path $privateRoot 'approved-current.dll'
 [IO.File]::WriteAllBytes($dllPath,$binaries[0])
 if((FileHash $dllPath).ToLowerInvariant() -cne $record.current_delivery.assembly_sha256){throw 'SSIS_TRUST_DELIVERED_BINARY_BINDING'}
 $lab=Resolve-LabContract -TestPurpose Functional
 if($lab.Snapshot){throw 'SSIS_TRUST_FUNCTIONAL_V1_CONTEXT_REQUIRED'}
 $targets=@(foreach($selector in @(@{Version='2019';Patch='CU32'},@{Version='2022';Patch='CU26'},@{Version='2025';Patch='CU8'})){
  $selected=@(Get-LabTargetsForSelector $lab.Contract ([pscustomobject]@{Platform='windows';Version=$selector.Version;Patch=$selector.Patch}))
  if($selected.Count -ne 1){throw 'SSIS_TRUST_EXACT_READY_TARGET_REQUIRED'}
  [ordered]@{key=[string]$selected[0].key;version=$selector.Version;patch=$selector.Patch}
 })
 $files=[ordered]@{}
 foreach($relative in @($method,$trustFile,$qualified,'Tests/CI/LabQualifiedContract.ps1','Tests/CI/run-lab-local.ps1',$package)){$files[$relative]=FileHash (Join-Path $root $relative)}
 $plan=[ordered]@{contract='ssis-administrative-trust-plan/1';package=$package;files=$files;dllPath=$dllPath;dllSha256=FileHash $dllPath;approvedHash=[string]$build.sha512;contractPath=$lab.Path;contractSha256=FileHash $lab.Path;schemaPath=$lab.SchemaPath;schemaSha256=FileHash $lab.SchemaPath;targets=$targets}
 SavePrivate $PlanPath $plan
 'SSIS_TRUST_PLAN_PREPARED targets=3; no SQL'
 return
}
if(-not $ExpectedPlanSha256 -or (FileHash $PlanPath) -cne $ExpectedPlanSha256){throw 'SSIS_TRUST_PLAN_CHANGED'}
$plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json -Depth 14
Assert-Inputs $plan
if($ValidateOnly){'SSIS_TRUST_INPUTS_VALIDATED; no SQL';return}
if(-not $JournalPath){throw 'SSIS_TRUST_JOURNAL_REQUIRED'}
$lab=Resolve-LabContract -TestPurpose Functional
if($lab.Snapshot -or $lab.Path -cne $plan.contractPath -or (FileHash $lab.Path) -cne $plan.contractSha256 -or
   (FileHash $lab.SchemaPath) -cne $plan.schemaSha256){throw 'SSIS_TRUST_LAB_CONTRACT_CHANGED'}
$selection=$plan.targets[$CaseIndex]
$selected=@(Get-LabTargetsForSelector $lab.Contract ([pscustomobject]@{Platform='windows';Version=$selection.version;Patch=$selection.patch}))
if($selected.Count -ne 1 -or [string]$selected[0].key -cne $selection.key){throw 'SSIS_TRUST_SELECTED_TARGET_CHANGED'}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString $selected[0] -TestPurpose Functional))
$builder['Initial Catalog']='master';$builder['Pooling']=$false;$builder['ConnectRetryCount']=0
$master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$hash=[Convert]::FromHexString($plan.approvedHash)
$script:checks=[Collections.Generic.List[object]]::new()
function Query([Data.SqlClient.SqlConnection]$Connection,[string]$Text){
 $command=$Connection.CreateCommand();$command.CommandTimeout=20;$command.CommandText=$Text
 [void]$command.Parameters.Add('@Hash',[Data.SqlDbType]::VarBinary,64);$command.Parameters['@Hash'].Value=$hash
 try{$data=[Data.DataTable]::new();$reader=$command.ExecuteReader();try{$data.Load($reader)}finally{$reader.Dispose()};return ,$data}finally{$command.Dispose()}
}
function RunSql([Data.SqlClient.SqlConnection]$Connection,[string]$Text){
 $command=$Connection.CreateCommand();$command.CommandTimeout=20;$command.CommandText=$Text
 try{[void]$command.ExecuteNonQuery();return 0}catch [Data.SqlClient.SqlException]{return [int]$_.Exception.Number}finally{$command.Dispose()}
}
function Check([bool]$Pass,[string]$Name){$script:checks.Add([pscustomobject]@{name=$Name;pass=$Pass})}
function Catalog([Data.SqlClient.SqlConnection]$Connection){
 $rows=Query $Connection 'SELECT CONVERT(varchar(128),hash,2) AS H,description,CONVERT(varchar(33),create_date,126) AS C,created_by FROM sys.trusted_assemblies WHERE hash<>@Hash ORDER BY hash;'
 $text=@($rows.Rows|ForEach-Object{[ordered]@{hash=[string]$_.H;description=[string]$_.description;created=[string]$_.C;by=[string]$_.created_by}})|ConvertTo-Json -Depth 4 -Compress
 [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$text)))
}
function Config([Data.SqlClient.SqlConnection]$Connection){
 $rows=Query $Connection 'SELECT name,CONVERT(int,value) AS C,CONVERT(int,value_in_use) AS R FROM sys.configurations ORDER BY name;'
 $text=@($rows.Rows|ForEach-Object{[ordered]@{name=[string]$_.name;configured=[int]$_.C;running=[int]$_.R}})|ConvertTo-Json -Depth 3 -Compress
 [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$text)))
}
function Entry([Data.SqlClient.SqlConnection]$Connection){
 $rows=Query $Connection 'SELECT description,CONVERT(varchar(33),create_date,126) AS Created,CONVERT(bit,CASE WHEN created_by=SUSER_SNAME() THEN 1 ELSE 0 END) AS Actor FROM sys.trusted_assemblies WHERE hash=@Hash;'
 if($rows.Rows.Count -eq 0){return $null}
 [pscustomobject]@{description=[string]$rows.Rows[0].description;created=[string]$rows.Rows[0].Created;actor=[bool]$rows.Rows[0].Actor}
}
function Same($A,$B){($A|ConvertTo-Json -Compress) -ceq ($B|ConvertTo-Json -Compress)}
function Consumers([Data.SqlClient.SqlConnection]$Connection){
 $databases=Query $Connection 'SELECT name FROM sys.databases WHERE state=0;'
 $count=0
 foreach($database in $databases.Rows){
  $name=([string]$database.name).Replace(']',']]')
  $rows=Query $Connection ("SELECT COUNT_BIG(*) AS N FROM ["+$name+"].sys.assembly_files WHERE file_id=1 AND HASHBYTES('SHA2_512',content)=@Hash;")
  $count += [int]$rows.Rows[0].N
 }
 return $count
}
function TrustSql([string]$Literal){
 $sql=[IO.File]::ReadAllText((Join-Path $root $trustFile)).Replace('$(AssemblySha512)',$Literal)
 $sql=[regex]::Replace($sql,'(?im)^:On Error exit\s*$','')
 if($sql -match '(?m)^:' -or $sql -match '\$\('){throw 'SSIS_TRUST_UNRESOLVED_SQLCMD'}
 return $sql
}
try{$master.Open()}catch{$builder.Clear();throw 'SSIS_TRUST_SQL_OPEN_FAILED'}
try{
 # Tatsächlicher SQL-Preflight am exakt gewählten READY-Ziel, ohne Ausgabe von
 # Hostnamen, Datenbanknamen, Zugangsdaten oder vollständigen Connection Strings.
 [void](Query $master 'SELECT @@VERSION AS V;')
 [void](Query $master 'SELECT name,state_desc FROM sys.databases;')
 $identity=Query $master "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS V,CONVERT(nvarchar(32),SERVERPROPERTY('ProductUpdateLevel')) AS P,(SELECT host_platform FROM sys.dm_os_host_info) AS O,IS_SRVROLEMEMBER(N'sysadmin') AS A,(SELECT CONVERT(int,value) FROM sys.configurations WHERE name=N'clr strict security') AS C,(SELECT CONVERT(int,value_in_use) FROM sys.configurations WHERE name=N'clr strict security') AS R;"
 if($identity.Rows[0].V -ne (@{'2019'=15;'2022'=16;'2025'=17}[$selection.version]) -or $identity.Rows[0].P -ine $selection.patch -or $identity.Rows[0].O -cne 'Windows' -or $identity.Rows[0].A -ne 1 -or $identity.Rows[0].C -ne 1 -or $identity.Rows[0].R -ne 1){throw 'SSIS_TRUST_EXISTING_ADMIN_STRICT_OR_IDENTITY_MISSING'}
 if($Mode -ceq 'Audit'){
  if(-not $ExpectedJournalSha256 -or (FileHash $JournalPath) -cne $ExpectedJournalSha256){throw 'SSIS_TRUST_AUDIT_JOURNAL_CHANGED'}
  $journal=Get-Content -LiteralPath $JournalPath -Raw|ConvertFrom-Json -Depth 14 -DateKind String
  if($journal.contract -cne 'ssis-administrative-trust-run/1' -or $journal.planSha256 -cne $ExpectedPlanSha256 -or $journal.caseIndex -ne $CaseIndex -or $journal.state -cnotin @('PASS_CLEANED','FAILED_CLEANED')){throw 'SSIS_TRUST_AUDIT_BINDING'}
  if(-not (Same (Entry $master) $journal.beforeEntry) -or (Catalog $master) -cne $journal.beforeCatalog -or (Config $master) -cne $journal.beforeConfig){throw 'SSIS_TRUST_AUDIT_BASELINE_DRIFT'}
  SavePrivate ($JournalPath+'.audit.json') ([ordered]@{result='PASS';journalSha256=$ExpectedJournalSha256;planSha256=$ExpectedPlanSha256;caseIndex=$CaseIndex;trustRestored=$true;otherTrustUnchanged=$true;configurationUnchanged=$true})
  'SSIS_TRUST_INDEPENDENT_AUDIT_PASS'
  return
 }
 if(Test-Path -LiteralPath $JournalPath){throw 'SSIS_TRUST_JOURNAL_COLLISION'}
 $lease=Query $master "DECLARE @R int;EXEC @R=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0;SELECT @R AS R;"
 if($lease.Rows[0].R -lt 0){throw 'SSIS_TRUST_EXISTING_LEASE_BUSY'}
 $before=Entry $master
 if($null -eq $before -and (Consumers $master) -ne 0){throw 'SSIS_TRUST_EXISTING_ASSEMBLY_CONSUMER'}
 $journal=[ordered]@{contract='ssis-administrative-trust-run/1';planSha256=$ExpectedPlanSha256;caseIndex=$CaseIndex;version=[string]$selection.version;patch=[string]$selection.patch;state='PREPARED';beforeEntry=$before;beforeCatalog=Catalog $master;beforeConfig=Config $master;ownedEntry=$null;approvedHash=$plan.approvedHash;insertExecuted=$false;guestErrorNumber=$null;checks=@();errorCode=$null}
 SavePrivate $JournalPath $journal
 $owned=$null;$failure=$null
 try{
  Assert-Inputs $plan
  $journal.state='IN_PROGRESS';SavePrivate $JournalPath $journal
  # Fehlendes Serverrecht vor dem Eintrag prüfen: Ein bereits vorhandener
  # öffentlicher Hash kann andernfalls zu einem zulässigen No-op führen.
  if($null -eq $before){
   $guest=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
   try{
    try{$guest.Open()}catch{throw 'SSIS_TRUST_GUEST_CONNECTION_FAILED'}
    if((RunSql $guest "EXECUTE AS USER=N'guest';") -ne 0){throw 'SSIS_TRUST_GUEST_CONTEXT_NOT_ESTABLISHED'}
    $authority=Query $guest "SELECT COALESCE(HAS_PERMS_BY_NAME(NULL,NULL,N'CONTROL SERVER'),0) AS P,COALESCE(IS_SRVROLEMEMBER(N'sysadmin'),0) AS R;"
    Check ($authority.Rows[0].P -eq 0 -and $authority.Rows[0].R -eq 0) 'database_guest_has_no_server_trust_authority'
    $code=RunSql $guest (TrustSql ('0x'+$plan.approvedHash))
    $journal.guestErrorNumber=$code
   }finally{$guest.Dispose()}
   Check ($null -eq (Entry $master)) 'guest_did_not_add_entry'
  }else{throw 'SSIS_TRUST_INSERT_PATH_ALREADY_PRESENT'}
  $code=RunSql $master (TrustSql ('0x'+$plan.approvedHash))
  if($code -ne 0){throw 'SSIS_TRUST_VALID_INSERT_FAILED'}
  $current=Entry $master
  if($null -eq $current){throw 'SSIS_TRUST_VALID_ENTRY_MISSING'}
  if($null -eq $before){
   if(-not $current.actor -or $current.description -cne 'SQL Server Toolbelt toolbelt.tsql.ssis-debug 1.0.0'){throw 'SSIS_TRUST_INSERT_OWNERSHIP_UNKNOWN'}
   $owned=$current;$journal.ownedEntry=$owned;$journal.insertExecuted=$true;SavePrivate $JournalPath $journal
  }
  Check ($null -ne $current) 'exact_approved_hash_present'
  Check (($null -eq $before) -or (Same $before $current)) 'existing_entry_preserved'
  Check ((Catalog $master) -ceq $journal.beforeCatalog) 'no_other_hash_added'
  Check ((RunSql $master (TrustSql ('0x'+$plan.approvedHash))) -eq 0) 'public_opt_in_repeat'
  Check (Same (Entry $master) $current) 'repeat_preserves_descriptor'
  foreach($case in @(@{name='empty';literal='0x'},@{name='null';literal='NULL'},@{name='overlong';literal=('0x'+$plan.approvedHash+'00')})){
   # Auch der überlange Negativfall beginnt ausschließlich mit dem bereits
   # geprüften/freigegebenen Hash; kein unbekannter Hash darf Trust erhalten.
   $code=RunSql $master (TrustSql $case.literal)
   Check ($code -eq 50000) ($case.name+'_rejected_by_public_guard')
   Check (Same (Entry $master) $current) ($case.name+'_entry_unchanged')
   Check ((Catalog $master) -ceq $journal.beforeCatalog) ($case.name+'_other_hashes_unchanged')
  }
  Check ((Config $master) -ceq $journal.beforeConfig) 'configuration_unchanged'
  Check ((Catalog $master) -ceq $journal.beforeCatalog) 'other_trust_unchanged'
 }catch{$failure=if($_.Exception.Message -cmatch '^SSIS_TRUST_[A-Z_]+$'){$_.Exception.Message}else{'SSIS_TRUST_CASE_ABORTED'};$journal.errorCode=$failure}
 finally{
  try{
   if($owned){
    if(-not (Same (Entry $master) $owned) -or (Consumers $master) -ne 0){throw 'SSIS_TRUST_CLEANUP_OWNERSHIP_OR_CONSUMER_DRIFT'}
    $drop=Query $master 'EXEC sys.sp_drop_trusted_assembly @hash=@Hash; SELECT 1 AS N;'
    if($null -ne (Entry $master)){throw 'SSIS_TRUST_OWN_ENTRY_STILL_PRESENT'}
   }elseif($journal.state -ceq 'IN_PROGRESS' -and $null -eq $before -and $null -ne (Entry $master)){
    throw 'SSIS_TRUST_UNKNOWN_INSERT_OUTCOME'
   }
   if(-not (Same (Entry $master) $before) -or (Catalog $master) -cne $journal.beforeCatalog -or (Config $master) -cne $journal.beforeConfig){throw 'SSIS_TRUST_FINAL_BASELINE_DRIFT'}
   $allPassed=($null -eq $failure) -and @($script:checks|Where-Object{-not $_.pass}).Count -eq 0
   $journal.state=if($allPassed){'PASS_CLEANED'}else{'FAILED_CLEANED'}
  }catch{$journal.state='RECOVERY_REQUIRED';$journal.errorCode='SSIS_TRUST_CLEANUP_UNVERIFIED'}
  $journal.checks=@($script:checks);SavePrivate $JournalPath $journal
 }
 if($journal.state -cne 'PASS_CLEANED'){throw ('SSIS_TRUST_NATIVE_'+$journal.state)}
 'SSIS_ADMINISTRATIVE_TRUST_PASS assertions='+$script:checks.Count
}finally{$master.Dispose();$builder.Clear()}
