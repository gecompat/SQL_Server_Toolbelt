[CmdletBinding()]
param([Parameter(Mandatory)][string]$ReleaseDirectory,[switch]$OptInExactTrust)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
foreach($selection in @(
 @{File='run-lab-local.ps1';Names=@('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')},
 @{File='run-security-contracts-lab.ps1';Names=@('Read-Source','Execute','Batches','Run-Source')},
 @{File='run-regex-captures-lab.ps1';Names=@('Invoke-CaptureSql','Get-TrustedDescription','Assert-NoAssemblyConsumer')})){
 $errors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $selection.File),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'SECURITY_ZIP_HELPER_PARSE'}
 foreach($name in $selection.Names){
  $definitions=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
  if($definitions.Count-ne1){throw 'SECURITY_ZIP_HELPER_DISCOVERY'}
  . ([scriptblock]::Create($definitions[0].Extent.Text))
 }
}
$module=Join-Path $repo 'Modules/toolbelt.archive.zip-memory'
$dll=Join-Path $ReleaseDirectory 'Toolbelt.Archive.ZipMemory.dll'
$manifest=Get-Content -LiteralPath (Join-Path $ReleaseDirectory 'Toolbelt.Archive.ZipMemory.trust-manifest.json') -Raw|ConvertFrom-Json
$hash=(Get-FileHash -LiteralPath $dll -Algorithm SHA512).Hash
if($manifest.moduleId-cne'toolbelt.archive.zip-memory'-or$manifest.moduleVersion-cne'1.4.0'-or$manifest.permissionSet-cne'SAFE'-or$hash-cne$manifest.sha512-or$manifest.sqlServerHexLiteral-cne('0x'+$hash)-or
 (Get-FileHash -LiteralPath (Join-Path $module 'Clr/bin/Release/Toolbelt.Archive.ZipMemory.dll') -Algorithm SHA512).Hash-cne$hash){throw 'SECURITY_ZIP_CURRENT_RELEASE_BINARY_REQUIRED'}
$deploy=Get-Content -LiteralPath (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') -Raw
$expected=(Get-Content -LiteralPath (Join-Path $module 'Deployment/Deploy.sql') -Raw).Replace('$(AssemblyBits)','0x'+[BitConverter]::ToString([IO.File]::ReadAllBytes($dll)).Replace('-',''))
if($deploy.Replace("`r`n","`n").TrimEnd()-cne$expected.Replace("`r`n","`n").TrimEnd()){throw 'SECURITY_ZIP_RELEASE_DEPLOY_BINDING'}
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='linux';Version='2019';Patch='latest'}))
if($targets.Count-ne1){throw 'SECURITY_ZIP_EXACT_SINGLE_TARGET'}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0]));$builder['Initial Catalog']='master';$builder['Pooling']=$false
$master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$consumer=$null
$created=$false;$added=$false;$database='TBX_SecurityZip_'+[guid]::NewGuid().ToString('N');$description='Toolbelt security ZIP '+[guid]::NewGuid().ToString('N')
$journal=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-security-zip-'+[guid]::NewGuid().ToString('N')+'.private.json')
$ledger=[ordered]@{Hash=$manifest.sqlServerHexLiteral;Description=$description;PriorExists=$null;State='PLANNED';OwnDatabase=$database}
try{
 $master.Open()
 if([int](Execute $master "SELECT CASE WHEN (SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security')=1 AND (SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled')=1 THEN 1 ELSE 0 END;" -Scalar)-ne1){throw 'SECURITY_ZIP_EXISTING_CLR_CONFIGURATION_REQUIRED'}
 $prior=[int](Execute $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash='+$manifest.sqlServerHexLiteral+';') -Scalar)-ne0
 $ledger.PriorExists=$prior;$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 if(-not$prior){
  if(-not$OptInExactTrust){throw 'SECURITY_ZIP_EXACT_TRUST_OPT_IN_REQUIRED'}
  $ledger.State='ADDING';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
  # A lost reply cannot be mislabeled as no mutation. Exact ownership is
  # reconciled below; an unconfirmed add blocks restoration.
  $added=$true
  Execute $master ('EXEC sys.sp_add_trusted_assembly @hash='+$manifest.sqlServerHexLiteral+",@description=N'"+$description+"';")
  $ledger.State='ADDED';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 }
 Execute $master ('CREATE DATABASE ['+$database+'] COLLATE Latin1_General_100_CS_AS;');$created=$true
 $builder['Initial Catalog']=$database;$consumer=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$consumer.Open()
 Run-Source $consumer (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')
 # Read-Source expands only repository files. The release replaces only the assembly marker.
 $text=Read-Source (Join-Path $module 'Deployment/Deploy.sql') ('0x'+[BitConverter]::ToString([IO.File]::ReadAllBytes($dll)).Replace('-',''))
 foreach($batch in (Batches $text)){Execute $consumer $batch}
 foreach($name in @('ZipMemory.Contract.sql','Writer.Contract.sql')){
  $path=Join-Path $module ('Tests/Runtime/'+$name)
  $text=(Get-Content -LiteralPath $path -Raw).Replace('$(CompatibilityLevel)','150').Replace('$(ToolbeltDatabase)',$database)
  foreach($batch in (Batches $text)){Execute $consumer $batch}
 }
 'SECURITY_ZIP_FRESH_API_PASS'
}catch{
 $failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException}
 if($failure-is[Data.SqlClient.SqlException]){throw ('SECURITY_ZIP_SQL_FAILED_'+$failure.Number+'_LINE_'+$failure.LineNumber)}
 if($failure.Message-cmatch'^[A-Z0-9_]+$'){throw $failure.Message};throw 'SECURITY_ZIP_FAILED_PRIVATE_DETAILS_SUPPRESSED'
}finally{
 if($consumer){$consumer.Dispose()}
 if($created){Execute $master ('ALTER DATABASE ['+$database+'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE ['+$database+'];');if([int](Execute $master ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)-ne0){throw 'SECURITY_ZIP_DATABASE_CLEANUP_UNVERIFIED'}}
 if($added){
  if((Get-TrustedDescription $master $manifest.sqlServerHexLiteral)-cne$description-or-not(Assert-NoAssemblyConsumer $master $manifest.sqlServerHexLiteral)){$ledger.State='RESTORE_BLOCKED';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal;throw 'SECURITY_ZIP_TRUST_CLEANUP_BLOCKED'}
  Execute $master ('EXEC sys.sp_drop_trusted_assembly @hash='+$manifest.sqlServerHexLiteral+';')
  if([int](Execute $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash='+$manifest.sqlServerHexLiteral+';') -Scalar)-ne0){throw 'SECURITY_ZIP_TRUST_CLEANUP_UNVERIFIED'}
 }
 $ledger.State='RESTORED';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 $master.Dispose()
}
