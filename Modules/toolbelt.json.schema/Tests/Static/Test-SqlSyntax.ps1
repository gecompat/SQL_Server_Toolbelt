param([Parameter(Mandatory=$true)][string]$ScriptDomPath,
 [Parameter(Mandatory=$true)][string]$SchemaModuleRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$scriptDom=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($ScriptDomPath))
$public=[IO.File]::ReadAllText((Join-Path $SchemaModuleRoot 'Source/USP_ValidateJsonSchema.sql'))
$bridge=[IO.File]::ReadAllText((Join-Path $SchemaModuleRoot 'Source/JsonSchemaBridge.sql'))
$body=[regex]::Match($public,"(?s)DECLARE @Sql nvarchar\(max\)=N'(.*)';\r?\n EXEC sys\.sp_executesql @Sql")
$slot=[regex]::Match($bridge,"(?s)EXEC sys\.sp_executesql N'(.*)';\r?\nGO")
if(-not $body.Success -or -not $slot.Success){throw 'SCHEMA_SQL_STATIC_BATCH_DISCOVERY'}
$batches=@($public,$bridge,$body.Groups[1].Value.Replace("''","'"),$slot.Groups[1].Value.Replace("''","'"))
$repoRoot=Split-Path -Parent (Split-Path -Parent ([IO.Path]::GetFullPath($SchemaModuleRoot)))
. (Join-Path $repoRoot 'Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1')
foreach($module in @('toolbelt.json.core','toolbelt.json.constructors','toolbelt.json.schema')){
 foreach($action in @('Deploy','Uninstall')){
  $expanded=Expand-JsonClosureSql -RelativePath ($module+'/Deployment/'+$action+'.sql')
  $expanded=$expanded.Replace('$(AssemblyBits)','0x00').Replace('$(DeploymentMode)','local').Replace('$(ConfirmNoExternalConsumers)','1')
  $expanded=[regex]::Replace($expanded,'(?m)^:On Error exit\r?$','')
  if($expanded -match '(?m)^:|\$\('){throw 'SCHEMA_SQL_UNRESOLVED_DIRECTIVE'}
  $batches+= $expanded
 }
}
foreach($fixture in @('Contract.Tests.sql','Safety.Tests.sql')){
 $batches+=[IO.File]::ReadAllText((Join-Path $SchemaModuleRoot ('Tests/Runtime/'+$fixture)))
}
$assertions=0
foreach($version in @(150,160,170)){
 $type=$scriptDom.GetType(('Microsoft.SqlServer.TransactSql.ScriptDom.TSql'+$version+'Parser'),$true)
 $parser=[Activator]::CreateInstance($type,[object[]]@($true))
 foreach($batch in $batches){
  $reader=[IO.StringReader]::new($batch);$errors=$null
  try{[void]$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
  if($errors.Count -ne 0){
   foreach($error in $errors){Write-Output ('SQL_SYNTAX '+$version+' BATCH '+$assertions+' LINE '+$error.Line+' CODE '+$error.Number+' '+$error.Message)}
   throw ('SCHEMA_SQL_SYNTAX_'+$version)
  }
  $assertions++
 }
}
Write-Output ('PASS SCHEMA_SQL_SYNTAX BATCHES '+$batches.Count+' ASSERTIONS '+$assertions)
