# Five dependency/signature guard matrices. Own synthetic metadata only; no grants or owners.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonCore.Lock.Contract.ps1') @('Assert-CoreLockNeutral')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Get-SchemaGuardSignatureCases{
 @('Json|@Json nvarchar(max)|@Json nvarchar(4000)',
 'Schema|@Schema nvarchar(max)|@Schema nvarchar(4000)',
 'Profile|@Profile varchar(32)|@Profile varchar(31)',
 'MaxDocumentBytes|@MaxDocumentBytes bigint|@MaxDocumentBytes int',
 'MaxSchemaBytes|@MaxSchemaBytes bigint|@MaxSchemaBytes int',
 'MaxDepth|@MaxDepth int|@MaxDepth smallint',
 'MaxEvaluationSteps|@MaxEvaluationSteps bigint|@MaxEvaluationSteps int',
 'MaxErrors|@MaxErrors int|@MaxErrors smallint',
 'ResultTable|@ResultTable sysname|@ResultTable nvarchar(128)',
 'KeepData|@KeepData bit|@KeepData tinyint',
 'Debug|@Debug tinyint|@Debug smallint',
 'Hilfe|@Hilfe bit|@Hilfe tinyint')|ForEach-Object{$a=$_.Split('|');[pscustomobject]@{id=$a[0];before=$a[1];after=$a[2]}}
}
function New-SchemaGuardSignature([string]$Original,$Spec){
 $match=[regex]::Match($Original,'(?im)^\s*AS\s*\r?\nBEGIN\b')
 if(-not$match.Success){throw 'SCHEMA_GUARD_HEADER_BOUNDARY'}
 $head=$Original.Substring(0,$match.Index)
 $first=$head.IndexOf($Spec.before,[StringComparison]::Ordinal)
 if($first-lt0-or$head.IndexOf($Spec.before,$first+1,[StringComparison]::Ordinal)-ge0){throw 'SCHEMA_GUARD_EXACT_SINGLE_PARAMETER'}
 return $head.Replace($Spec.before,$Spec.after)+$Original.Substring($match.Index)
}
function ConvertTo-SchemaGuardAlterCommand([string]$Definition){
 # SQL Server may store CREATE OR ALTER as CREATE in OBJECT_DEFINITION.
 $match=[regex]::Match($Definition,'(?im)^(?<Indent>\s*)(?:CREATE(?:\s+OR\s+ALTER)?|ALTER)(?<Space>\s+)PROCEDURE\b')
 if(-not$match.Success){throw 'SCHEMA_GUARD_EXISTING_PROCEDURE_DDL_REQUIRED'}
 # Do not carry catalog padding from removed OR/ALTER tokens into a new command.
 $replacement=$match.Groups['Indent'].Value+'CREATE OR ALTER PROCEDURE'
 return $Definition.Substring(0,$match.Index)+$replacement+$Definition.Substring($match.Index+$match.Length)
}
function Get-SchemaGuardKeys([string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'SCHEMA_GUARD_EXACT_MODE'}
 foreach($spec in Get-SchemaGuardSignatureCases){foreach($op in @('deploy','uninstall')){'signature/'+$spec.id+'/'+$op}}
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){foreach($op in @('deploy','uninstall')){'core-tuple/'+$name+'/'+$op}}
 foreach($id in @('version-old','version-noncanonical','version-null','object-module','object-version')){'result-table/'+$id+'/deploy'}
 foreach($id in @('version-null','version-current','version-noncanonical')){'constructor-orphan/'+$id+'/deploy'}
 foreach($op in @('deploy','uninstall')){'bridge-consumer/'+$op}
}
function Test-SchemaGuardCoverage($Rows,[string[]]$Excluded=@()){
 $all=@(foreach($mode in @('local','central')){foreach($id in Get-SchemaGuardKeys $mode){$mode+'/'+$id}})
 if(@($Excluded|Select-Object -Unique).Count-ne$Excluded.Count-or@($Excluded|Where-Object{$_-cnotin$all}).Count){return $false}
 $expected=@($all|Where-Object{$_-cnotin$Excluded}|Sort-Object)
 $actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool](@($Rows).Count-eq(92-$Excluded.Count)-and@($Rows|Where-Object passed -NE $true).Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function Get-SchemaGuardReusedKeys{
 if(-not$runset.PSObject.Properties['partial_tail']){return}
 $tail=$runset.partial_tail;if($tail.case_index-ne0){throw 'SCHEMA_GUARD_TAIL_CONTEXT'}
 foreach($binding in @(@{path=$tail.journal;sha256=$tail.journal_sha256},@{path=$tail.audit;sha256=$tail.audit_sha256},@{path=$tail.original_runset;sha256=$tail.original_runset_sha256})){
  [void](Assert-ReleasePrivatePath $binding.path);Assert-ReleasePin $binding.path $binding.sha256
  if(@($runset.pins|Where-Object{$_.path-ceq$binding.path-and$_.sha256-ceq$binding.sha256}).Count-ne1){throw 'SCHEMA_GUARD_TAIL_PIN'}
 }
 $old=Get-Content $tail.journal -Raw|ConvertFrom-Json -DateKind String;$audit=Get-Content $tail.audit -Raw|ConvertFrom-Json -DateKind String
 $prior=Get-Content $tail.original_runset -Raw|ConvertFrom-Json -DateKind String
 if($old.state-cne'FAILED_CLEANED'-or$old.failure.privateDiagnostic-cne'SCHEMA_GUARD_SIGNATURE_ORIGINAL_NOT_RESTORED'-or$audit.state-cne'COMPLETE'-or$audit.originalRunPassed-ne$false-or$audit.originalJournalSHA256-cne$tail.journal_sha256-or-not$audit.databaseAbsence-or-not$audit.serverConfigurationAndTrustUnchanged-or-not$audit.postPins){throw 'SCHEMA_GUARD_TAIL_ORIGINAL_CLEANUP'}
 if($prior.contract_sha256-cne$runset.contract_sha256){throw 'SCHEMA_GUARD_TAIL_TARGET_DRIFT'}
 foreach($pin in $prior.pins|Where-Object{$_.path.StartsWith((Join-Path $repo 'Modules')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)}){
  Assert-ReleasePin $pin.path $pin.sha256;if(@($runset.pins|Where-Object{$_.path-ceq$pin.path-and$_.sha256-ceq$pin.sha256}).Count-ne1){throw 'SCHEMA_GUARD_TAIL_PRODUCT_DRIFT'}
 }
 $fixture=Join-Path $repo 'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
 $caps=@($prior.source_capsules|Where-Object originalPath -CEQ $fixture);if($caps.Count-ne1){throw 'SCHEMA_GUARD_TAIL_ORIGINAL_ORACLES'}
 [void](Assert-ReleasePrivatePath $caps[0].snapshotPath);Assert-ReleasePin $caps[0].snapshotPath $caps[0].sha256
 $e=$null;$before=[Management.Automation.Language.Parser]::ParseFile($caps[0].snapshotPath,[ref]$null,[ref]$e);if($e.Count){throw 'SCHEMA_GUARD_TAIL_PARSE'}
 $after=[Management.Automation.Language.Parser]::ParseFile($fixture,[ref]$null,[ref]$e);if($e.Count){throw 'SCHEMA_GUARD_TAIL_PARSE'}
 foreach($name in @('Get-SchemaGuardState','Assert-SchemaGuardDenied','Test-SchemaGuardError','Add-SchemaGuardReceipt','New-SchemaGuardSignature')){
  $left=@($before.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true));$right=@($after.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
  if($left.Count-ne1-or$right.Count-ne1-or$left[0].Extent.Text.Replace("`r`n","`n")-cne$right[0].Extent.Text.Replace("`r`n","`n")){throw 'SCHEMA_GUARD_TAIL_REUSED_ORACLE_CHANGED'}
 }
 $keys=@($old.profileCompletions|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 if(@($old.profileCompletions|Where-Object passed -NE $true).Count-or($keys-join'|')-cne'local/signature/Json/deploy|local/signature/Json/uninstall'){throw 'SCHEMA_GUARD_TAIL_EXACT_PREFIX'}
 if($CaseIndex-eq0){$keys}
}
function Get-SchemaGuardState($Db){
 $types=@(Sql $Db @'
SELECT class,major_id,minor_id,name,
 CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,N'BaseType')) BaseType,
 CONVERT(int,SQL_VARIANT_PROPERTY(value,N'MaxLength')) MaxLength,DATALENGTH(value) Bytes,
 CONVERT(varchar(max),CONVERT(varbinary(max),value),2) Raw
FROM sys.extended_properties WHERE name LIKE N'Toolbelt.%' ORDER BY class,major_id,minor_id,name;
'@ -Rows)
 $schema=@(Sql $Db "SELECT assembly_id,principal_id,permission_set,is_visible FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';" -Rows)

 $consumer=@(Sql $Db "SELECT o.object_id,o.principal_id,o.name,o.type,m.definition FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID(N'dbo') AND o.name=N'ContosoSchemaBridgeConsumer';" -Rows)
 $dependencies=@(Sql $Db "SELECT referencing_id,referencing_minor_id,referenced_class,referenced_id,referenced_minor_id,is_schema_bound_reference FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.ContosoSchemaBridgeConsumer') ORDER BY referencing_id,referencing_minor_id,referenced_class,referenced_id,referenced_minor_id;" -Rows)
 $parameters=@(Sql $Db "SELECT object_id,parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id IN(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal')) ORDER BY object_id,parameter_id;" -Rows)
 $setOptions=@(Sql $Db "SELECT object_id,uses_ansi_nulls,uses_quoted_identifier FROM sys.sql_modules WHERE object_id IN(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal')) ORDER BY object_id;" -Rows)
 return ([ordered]@{consumer=@($consumer);dependencies=@($dependencies);parameters=@($parameters);setOptions=@($setOptions);schema=@($schema);module=(Get-ModuleState $Db);core=(Read-CoreProjection $Db);typedProperties=@($types)}|ConvertTo-Json -Depth 6 -Compress)
}
function Invoke-PinnedLifecycle([string]$Operation){
 if($Operation-cnotin@('deploy','uninstall')){throw 'SCHEMA_GUARD_CANONICAL_OPERATION'}
 Assert-ReleaseInputs
 $path=if($Operation-ceq'deploy'){$runset.exports.($script:schemaGuardMode)}else{$runset.uninstall}
 Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($path))
}
function Test-SchemaGuardError($Errors,[int]$Number,[string]$Message){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq$Number-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq$Message)
}
function Add-SchemaGuardReceipt([string]$Mode,[string]$Id,[int]$Number,[string]$Snapshot){
 $ledger.profileCompletions+=@([ordered]@{mode=$Mode;id=$Id;passed=$true;number=$Number;snapshotPreserved=$true;snapshotSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Snapshot)))});Save-ReleaseJournal
}
function Assert-SchemaGuardDenied($Db,[string]$Mode,[string]$Id,[string]$Text,[int]$Number,[string]$Message){
 $before=Get-SchemaGuardState $Db;$caught=$null
 try{Invoke-ReleaseBatches $Db $Text}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-SchemaGuardError $caught.Errors $Number $Message)){throw 'SCHEMA_GUARD_EXACT_ERROR_REQUIRED'}
 if((Get-SchemaGuardState $Db)-cne$before){throw 'SCHEMA_GUARD_REJECTED_SCRIPT_MUTATED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-SchemaGuardReceipt $Mode $Id $Number $before
}


function Invoke-SchemaGuardProfiles($Db,[string]$Mode){
 $script:guardConnection=$Db;$script:schemaGuardMode=$Mode
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode));Invoke-PinnedLifecycle 'deploy'
 # Capture the stable existing-object DDL branch, including its catalog text/hash.
 # This setup is not counted as a new Repeat qualification profile.
 Invoke-PinnedLifecycle 'deploy'
 $installed=Get-SchemaGuardState $Db
 $original=[string](Read-Scalar $Db "SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema')) ScalarValue;")
 $ledger.definitionSnapshots+=@(@{mode=$Mode;scope='owned-public-procedure';definition=$original});Save-ReleaseJournal
 $catalogSql="SELECT parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') ORDER BY parameter_id;"
 $originalParameters=@(Sql $Db $catalogSql -Rows)
 if($originalParameters.Count-ne12){throw 'SCHEMA_GUARD_ORIGINAL_PUBLIC_PARAMETER_COUNT'}
 foreach($spec in Get-SchemaGuardSignatureCases){
  if(@('deploy','uninstall'|Where-Object{($Mode+'/signature/'+$spec.id+'/'+$_)-cnotin$script:schemaGuardExcluded}).Count-eq0){continue}
  $changed=New-SchemaGuardSignature $original $spec
  if($changed-ceq$original){throw 'SCHEMA_GUARD_SIGNATURE_NOT_CHANGED'}
  Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $changed);$damaged=Get-SchemaGuardState $Db
  $actualParameters=@(Sql $Db $catalogSql -Rows)
  if($actualParameters.Count-ne12){throw 'SCHEMA_GUARD_ACTUAL_PARAMETER_COUNT'}
  $changedNames=@(for($i=0;$i-lt12;$i++){if(($actualParameters[$i]|ConvertTo-Json -Compress)-cne($originalParameters[$i]|ConvertTo-Json -Compress)){$actualParameters[$i].name}})
  if($changedNames.Count-ne1-or$changedNames[0]-cne('@'+$spec.id)){throw 'SCHEMA_GUARD_EXACT_ACTUAL_PARAMETER_DRIFT'}
  if($damaged-ceq$installed){throw 'SCHEMA_GUARD_SIGNATURE_NOT_VISIBLE'}
  try{foreach($op in @('deploy','uninstall')){
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-SchemaGuardDenied $Db $Mode ('signature/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: öffentliche Parametersignatur inkohärent.'
  }}finally{
   if((Get-SchemaGuardState $Db)-cne$damaged){throw 'SCHEMA_GUARD_SIGNATURE_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $original)
  }
  if((Get-SchemaGuardState $Db)-cne$installed){throw 'SCHEMA_GUARD_SIGNATURE_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db "SELECT name,value INTO #SchemaGuardCoreMarkers FROM sys.extended_properties WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore');"
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #SchemaGuardCoreMarkers;')-ne6){throw 'SCHEMA_GUARD_SIX_CORE_MARKERS'}
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){
  Sql $Db @'
DECLARE @V sql_variant,@Bad sql_variant;
SELECT @V=value FROM #SchemaGuardCoreMarkers WHERE name=@Name;
SET @Bad=CONVERT(varchar(128),CASE WHEN CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(@V,N'BaseType'))=N'varbinary' THEN CONVERT(varchar(128),CONVERT(varbinary(64),@V),2) ELSE CONVERT(varchar(128),@V) END);
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonCore';
'@ @{'@Name'=$name}
  $damaged=Get-SchemaGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-SchemaGuardDenied $Db $Mode ('core-tuple/'+$name+'/'+$op) ([IO.File]::ReadAllText($path)) 55623 'JSON Core: typisiertes bekanntes Markertuple ist inkohärent.'
  }}finally{
   if((Get-SchemaGuardState $Db)-cne$damaged){throw 'SCHEMA_GUARD_CORE_RESTORE_DRIFT'}
   Sql $Db "DECLARE @V sql_variant;SELECT @V=value FROM #SchemaGuardCoreMarkers WHERE name=@Name;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonCore';" @{'@Name'=$name}
  }
  if((Get-SchemaGuardState $Db)-cne$installed){throw 'SCHEMA_GUARD_CORE_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db "DROP TABLE #SchemaGuardCoreMarkers;SELECT class,name,value INTO #SchemaGuardResultMarkers FROM sys.extended_properties WHERE (class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version') OR (class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion'));"
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #SchemaGuardResultMarkers;')-ne3){throw 'SCHEMA_GUARD_THREE_RESULT_MARKERS'}
 foreach($id in @('version-old','version-noncanonical','version-null','object-module','object-version')){
  $dbMarker=$id.StartsWith('version-',[StringComparison]::Ordinal)
  $name=if($dbMarker){'Toolbelt.Module.toolbelt.core.result-table.Version'}elseif($id-ceq'object-module'){'Toolbelt.ModuleId'}else{'Toolbelt.ModuleVersion'}
  $badValue=switch -CaseSensitive ($id){'version-old'{'0.9.0'};'version-noncanonical'{'1.0.00'};'version-null'{[DBNull]::Value};'object-module'{'ContosoInvalidModule'};'object-version'{'0.0.0'}}
  $parameters=@{'@Name'=$name;'@Value'=$badValue;'@L0'=$(if($dbMarker){[DBNull]::Value}else{'SCHEMA'});'@N0'=$(if($dbMarker){[DBNull]::Value}else{'toolbelt_core'});'@L1'=$(if($dbMarker){[DBNull]::Value}else{'PROCEDURE'});'@N1'=$(if($dbMarker){[DBNull]::Value}else{'USP_PrepareResultTable'})}
  Sql $Db 'DECLARE @V nvarchar(64)=@Value;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;' $parameters
  $damaged=Get-SchemaGuardState $Db
  try{Assert-SchemaGuardDenied $Db $Mode ('result-table/'+$id+'/deploy') ([IO.File]::ReadAllText($runset.exports.$Mode)) 55632 'JSON Schema lifecycle: registrierte ResultTable-Dependency >=1.0.0 fehlt.'}
  finally{
   if((Get-SchemaGuardState $Db)-cne$damaged){throw 'SCHEMA_GUARD_RESULT_RESTORE_DRIFT'}
   $parameters['@Class']=if($dbMarker){0}else{1}
   Sql $Db 'DECLARE @V sql_variant;SELECT @V=value FROM #SchemaGuardResultMarkers WHERE class=TRY_CONVERT(int,@Class) AND name=@Name;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;' $parameters
  }
  if((Get-SchemaGuardState $Db)-cne$installed){throw 'SCHEMA_GUARD_RESULT_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #SchemaGuardResultMarkers;'
 if([int](Read-Scalar $Db "SELECT (SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')+(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.constructors.%') ScalarValue;")-ne0){throw 'SCHEMA_GUARD_CONSTRUCTOR_MUST_BE_ABSENT'}
 foreach($id in @('version-null','version-current','version-noncanonical')){
  $value=if($id-ceq'version-null'){[DBNull]::Value}elseif($id-ceq'version-current'){'1.3.0'}else{'1.3.00'}
  Sql $Db "DECLARE @V nvarchar(16)=@Value,@M nvarchar(16)=@Mode;EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version',@value=@V;EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode',@value=@M;" @{'@Value'=$value;'@Mode'=$Mode}
  $damaged=Get-SchemaGuardState $Db
  try{Assert-SchemaGuardDenied $Db $Mode ('constructor-orphan/'+$id+'/deploy') ([IO.File]::ReadAllText($runset.exports.$Mode)) 55633 'JSON Schema lifecycle: vorhandene Constructors zuerst explizit und kohärent auf1.3 migrieren.'}
  finally{
   if((Get-SchemaGuardState $Db)-cne$damaged){throw 'SCHEMA_GUARD_CONSTRUCTOR_RESTORE_DRIFT'}
   Sql $Db "EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version';EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';"
  }
  if((Get-SchemaGuardState $Db)-cne$installed){throw 'SCHEMA_GUARD_CONSTRUCTOR_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db "CREATE VIEW dbo.ContosoSchemaBridgeConsumer AS SELECT RowKind FROM toolbelt_json.FT_ValidateJsonSchemaInternal(N'1',N'true',N'toolbelt-2020-12-v1',CONVERT(bigint,1024),CONVERT(bigint,1024),1,CONVERT(bigint,10),1);"
 $damaged=Get-SchemaGuardState $Db
 if([int](Read-Scalar $Db "SELECT COUNT(*) ScalarValue FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.ContosoSchemaBridgeConsumer') AND referenced_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal');")-lt1){throw 'SCHEMA_GUARD_REAL_BRIDGE_DEPENDENCY_REQUIRED'}
 try{foreach($op in @('deploy','uninstall')){
  $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
  Assert-SchemaGuardDenied $Db $Mode ('bridge-consumer/'+$op) ([IO.File]::ReadAllText($path)) 55636 'JSON Schema lifecycle: fremder Verbraucher blockiert Lifecycle.'
 }}finally{
  if((Get-SchemaGuardState $Db)-cne$damaged){throw 'SCHEMA_GUARD_CONSUMER_RESTORE_DRIFT'}
  Sql $Db 'DROP VIEW dbo.ContosoSchemaBridgeConsumer;'
 }
 if((Get-SchemaGuardState $Db)-cne$installed){throw 'SCHEMA_GUARD_FINAL_ORIGINAL_NOT_RESTORED'}
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-SchemaGuardKeys $Mode|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'SCHEMA_GUARD_EXACT_FIVE_POINT_COVERAGE'}
 Invoke-PinnedLifecycle 'uninstall';Assert-CoreLockNeutral $Db
}
