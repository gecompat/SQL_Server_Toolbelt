. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState')){. $block}
function Get-LifecycleGuardState($Db){
 $objects=@(Sql $Db "SELECT o.object_id,o.name,o.type,o.principal_id,m.definition FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_json') ORDER BY o.object_id;" -Rows)
 $bindings=@(Sql $Db "SELECT m.* FROM sys.assembly_modules m JOIN sys.objects o ON o.object_id=m.object_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_json') ORDER BY m.object_id;" -Rows)
 return ([ordered]@{baseline=(Get-SchemaGuardState $Db);constructorObjects=@($objects);constructorBindings=@($bindings)}|ConvertTo-Json -Depth 7 -Compress)
}
function Get-AggregateErrorSpecs{
 foreach($aggregate in @('array','object')){
  foreach($id in @('null','zero','three','max')){[pscustomobject]@{aggregate=$aggregate;wave='profile-invalid';id=$id;profile=0;tag='TBX_JSON_AGG_PROFILE_INVALID'}}
  foreach($id in @('forward','reverse','ordinal-priority','kind-priority')){[pscustomobject]@{aggregate=$aggregate;wave='profile-mixed';id=$id;profile=0;tag='TBX_JSON_AGG_PROFILE_INVALID'}}
  foreach($profile in @(1,2)){
   foreach($id in @('null','zero','negative','min')){[pscustomobject]@{aggregate=$aggregate;wave='ordinal-invalid';id=$id;profile=$profile;tag='TBX_JSON_AGG_ORDINAL_INVALID'}}
   foreach($id in @('forward','reverse')){[pscustomobject]@{aggregate=$aggregate;wave='ordinal-duplicate';id=$id;profile=$profile;tag='TBX_JSON_AGG_ORDINAL_INVALID'}}
   foreach($id in @('null','long','empty','upper','space','unknown')){[pscustomobject]@{aggregate=$aggregate;wave='kind-invalid';id=$id;profile=$profile;tag=$(if($id-cin@('null','long')){'TBX_JSON_AGG_KIND_LENGTH'}else{'TBX_JSON_AGG_KIND_INVALID'})}}
   foreach($id in @('string','number','boolean','json','null-value')){[pscustomobject]@{aggregate=$aggregate;wave='value-null';id=$id;profile=$profile;tag='TBX_JSON_AGG_NULL_INVALID'}}
   foreach($id in @('leading-zero','plus','fraction','exponent','nan')){[pscustomobject]@{aggregate=$aggregate;wave='number-invalid';id=$id;profile=$profile;tag='TBX_JSON_AGG_NUMBER_INVALID'}}
   foreach($id in @('upper','space','mixed','numeric')){[pscustomobject]@{aggregate=$aggregate;wave='boolean-invalid';id=$id;profile=$profile;tag='TBX_JSON_AGG_BOOLEAN_INVALID'}}
  }
  foreach($profile in @(1,2)){[pscustomobject]@{aggregate=$aggregate;wave=('entry-limit-'+$profile);id='one-over';profile=$profile;tag='TBX_JSON_AGG_ENTRY_LIMIT'}}
 }
}
function Assert-AggregateErrorSpec($Spec){
 $known=@(Get-AggregateErrorSpecs|Where-Object{$_.aggregate-ceq$Spec.aggregate-and$_.wave-ceq$Spec.wave-and$_.id-ceq$Spec.id-and$_.profile-eq$Spec.profile-and$_.tag-ceq$Spec.tag})
 if($known.Count-ne1){throw 'AGGREGATE_ERRORS_EXACT_VECTOR'}
}
function Get-AggregateErrorKey($Spec){$Spec.aggregate+'/'+$Spec.wave+'/'+$Spec.id+'/p'+$Spec.profile}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'AGGREGATE_ERRORS_EXACT_CONTEXT'}
 foreach($spec in Get-AggregateErrorSpecs){Get-AggregateErrorKey $spec}
}
function Get-AggregateErrorInput($Spec){
 Assert-AggregateErrorSpec $Spec
 $ordinal=1;$kind='number';$value='1';$profile=$Spec.profile;$second=$false;$ordinal2=2;$kind2='number';$profile2=$profile;$count=0
 switch -CaseSensitive($Spec.wave){
  'profile-invalid'{$profile=switch -CaseSensitive($Spec.id){'null'{$null};'zero'{0};'three'{3};'max'{255}}}
  'profile-mixed'{$profile=1;$profile2=2;$second=$true;if($Spec.id-ceq'reverse'){$profile=2;$profile2=1};if($Spec.id-ceq'ordinal-priority'){$ordinal=0;$ordinal2=-1};if($Spec.id-ceq'kind-priority'){$kind='other';$kind2='other'}}
  'ordinal-invalid'{$ordinal=switch -CaseSensitive($Spec.id){'null'{$null};'zero'{0};'negative'{-1};'min'{[int]::MinValue}}}
  'ordinal-duplicate'{$second=$true;$ordinal2=1}
  'kind-invalid'{$kind=switch -CaseSensitive($Spec.id){'null'{$null};'long'{'12345678'};'empty'{''};'upper'{'STRING'};'space'{'string '};'unknown'{'other'}}}
  'value-null'{if($Spec.id-ceq'null-value'){$kind='null';$value='x'}else{$kind=$Spec.id;$value=$null}}
  'number-invalid'{$value=switch -CaseSensitive($Spec.id){'leading-zero'{'01'};'plus'{'+1'};'fraction'{'1.'};'exponent'{'1e'};'nan'{'NaN'}}}
  'boolean-invalid'{$kind='boolean';$value=switch -CaseSensitive($Spec.id){'upper'{'TRUE'};'space'{' false'};'mixed'{'False'};'numeric'{'1'}}}
  default{if($Spec.wave-cnotin@('entry-limit-1','entry-limit-2')){throw 'AGGREGATE_ERRORS_INPUT_SCOPE'};$count=if($profile-eq1){10001}else{100001}}
 }
 return @{'@Ordinal'=$(if($null-eq$ordinal){[DBNull]::Value}else{$ordinal});'@Ordinal2'=$ordinal2;'@Kind'=$(if($null-eq$kind){[DBNull]::Value}else{$kind});'@Kind2'=$kind2;'@Value'=$(if($null-eq$value){[DBNull]::Value}else{$value});'@Profile'=$(if($null-eq$profile){[DBNull]::Value}else{$profile});'@Profile2'=$profile2;'@Second'=[int]$second;'@Reverse'=[int]($Spec.wave-ceq'ordinal-duplicate'-and$Spec.id-ceq'reverse');'@Count'=$count}
}
function Get-AggregateInputState($Db){
 $r=@(Sql $Db @'
SELECT (SELECT COUNT_BIG(*) FROM #AggregateWaveInput) EntryCount,
 CONVERT(varchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),(SELECT InputId,Ordinal,[Key],ValueKind,[Value],Profile FROM #AggregateWaveInput ORDER BY InputId FOR XML RAW,BINARY BASE64))),2) Digest;
'@ -Rows)
 if($r.Count-ne1){throw 'AGGREGATE_ERRORS_INPUT_WITNESS_REQUIRED'}
 return ($r[0]|ConvertTo-Json -Depth 3 -Compress)
}
function Get-AggregateErrorStatement($Spec){
 Assert-AggregateErrorSpec $Spec
 if($Spec.aggregate-ceq'array'){'SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) JsonValue FROM #AggregateWaveInput;'}
 else{'SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) JsonValue FROM #AggregateWaveInput;'}
}
function Test-AggregateErrorTuple($Errors,[string]$Tag){
 $severe=@($Errors|Where-Object Class -GE 11)
 if($severe.Count-ne1-or$severe[0].Number-ne6522-or$severe[0].Class-ne16){return $false}
 $tags=@([regex]::Matches($severe[0].Message,'TBX_JSON_AGG_[A-Z_]+')|ForEach-Object Value|Select-Object -Unique)
 return [bool]($tags.Count-eq1-and$tags[0]-ceq$Tag)
}
function Assert-AggregateError($Db,[string]$Mode,$Spec){
 $before=Get-LifecycleGuardState $Db;$input=Get-AggregateInputState $Db;$rows=0;$caught=$null
 $parameters=Get-AggregateErrorInput $Spec;$expectedCount=if($parameters['@Count']-gt0){$parameters['@Count']}elseif($parameters['@Second']-eq1){2}else{1}
 if(($input|ConvertFrom-Json).EntryCount-ne$expectedCount){throw 'AGGREGATE_ERRORS_ACTUAL_INPUT_COUNT'}
 $command=$Db.CreateCommand();$command.CommandTimeout=Get-ReleaseTimeout;$command.CommandText=Get-AggregateErrorStatement $Spec
 try{
  $reader=$command.ExecuteReader()
  try{do{while($reader.Read()){$rows++}}while($reader.NextResult())}finally{$reader.Dispose()}
 }catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}finally{$command.Dispose()}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-AggregateErrorTuple $caught.Errors $Spec.tag)-or$rows-ne0){throw 'AGGREGATE_ERRORS_EXACT_FAILURE_WITHOUT_PARTIAL_ROW_REQUIRED'}
 if((Get-LifecycleGuardState $Db)-cne$before-or(Get-AggregateInputState $Db)-cne$input){throw 'AGGREGATE_ERRORS_MUTATED_MODULE_OR_INPUT'}
 Assert-CoreLockNeutral $Db
 Add-LifecycleGuardReceipt $Mode (Get-AggregateErrorKey $Spec) 6522 $before
 $receipt=$ledger.profileCompletions[-1]
 $receipt['aggregateTag']=$Spec.tag;$receipt['sqlState']=@($caught.Errors|Where-Object Class -GE 11)[0].State
 $receipt['partialRows']=$rows;$receipt['inputCount']=$expectedCount;$receipt['inputDigest']=($input|ConvertFrom-Json).Digest
 $receipt['wave']=$Spec.aggregate+'/'+$Spec.wave;Save-ReleaseJournal
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_exports.$Mode))
 Sql $Db 'CREATE TABLE #AggregateWaveInput(InputId int IDENTITY,Ordinal int NULL,[Key] nvarchar(max) NULL,ValueKind nvarchar(max) NULL,[Value] nvarchar(max) NULL,Profile tinyint NULL);'
 foreach($spec in Get-AggregateErrorSpecs){
  $p=Get-AggregateErrorInput $spec
  Sql $Db @'
TRUNCATE TABLE #AggregateWaveInput;
IF TRY_CONVERT(int,@Count)=0
BEGIN
 IF TRY_CONVERT(int,@Reverse)=0
 BEGIN
  INSERT #AggregateWaveInput(Ordinal,[Key],ValueKind,[Value],Profile) VALUES(TRY_CONVERT(int,@Ordinal),N'a',@Kind,@Value,TRY_CONVERT(tinyint,@Profile));
  IF TRY_CONVERT(int,@Second)=1 INSERT #AggregateWaveInput(Ordinal,[Key],ValueKind,[Value],Profile) VALUES(TRY_CONVERT(int,@Ordinal2),N'b',@Kind2,N'2',TRY_CONVERT(tinyint,@Profile2));
 END
 ELSE
 BEGIN
  INSERT #AggregateWaveInput(Ordinal,[Key],ValueKind,[Value],Profile) VALUES(TRY_CONVERT(int,@Ordinal2),N'b',@Kind2,N'2',TRY_CONVERT(tinyint,@Profile2));
  INSERT #AggregateWaveInput(Ordinal,[Key],ValueKind,[Value],Profile) VALUES(TRY_CONVERT(int,@Ordinal),N'a',@Kind,@Value,TRY_CONVERT(tinyint,@Profile));
 END;
END
ELSE
BEGIN
 IF TRY_CONVERT(int,@Count) NOT IN(10001,100001) THROW 52098,N'Owned bounded count required.',1;
 ;WITH D(n) AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))v(n)),
 N(n) AS(SELECT TOP(TRY_CONVERT(int,@Count)) CONVERT(int,ROW_NUMBER() OVER(ORDER BY(SELECT NULL))) FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d CROSS JOIN D e CROSS JOIN D f)
 INSERT #AggregateWaveInput(Ordinal,[Key],ValueKind,[Value],Profile)
 SELECT n,N'k'+CONVERT(nvarchar(12),n),N'null',NULL,TRY_CONVERT(tinyint,@Profile) FROM N;
END;
'@ $p
  Assert-AggregateError $Db $Mode $spec
 }
 Sql $Db 'DROP TABLE #AggregateWaveInput;'
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'AGGREGATE_ERRORS_TWENTY_WAVE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_uninstall));Assert-CoreLockNeutral $Db
 if([int](Read-Scalar $Db "SELECT (SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')+(SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json')) ScalarValue;")-ne0){throw 'AGGREGATE_ERRORS_CONSTRUCTOR_NOT_REMOVED'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
