[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath,[Parameter(Mandatory)][string]$ExpectedAssemblySHA512,[Parameter(Mandatory)][string]$ExpectedProviderSHA256)
$ErrorActionPreference='Stop'
# Auch isoliert extrahierte Labfunktionen benötigen den gemeinsamen Reader.
. (Join-Path $PSScriptRoot 'LabQualifiedContract.ps1')

Set-StrictMode -Version Latest
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
foreach($selection in @(
 @{File='run-lab-local.ps1';Names=@('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')},
 @{File='run-security-contracts-lab.ps1';Names=@('Read-Source','Execute','Batches','Run-Source')},
 @{File='run-regex-captures-lab.ps1';Names=@('Invoke-CaptureSql','Get-TrustedDescription','Assert-NoAssemblyConsumer')})){
 $errors=$null;$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo ('Tests/CI/'+$selection.File)),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'SECURITY_ZIP_HELPER_PARSE'}
 foreach($name in $selection.Names){
  $definitions=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
  if($definitions.Count-ne1){throw 'SECURITY_ZIP_HELPER_DISCOVERY'}
  . ([scriptblock]::Create($definitions[0].Extent.Text))
 }
}
$module=Join-Path $repo 'Modules/toolbelt.filesystem.windows'
$dll=[IO.Path]::GetFullPath($AssemblyPath)
if((Get-FileHash $dll -Algorithm SHA512).Hash-cne$ExpectedAssemblySHA512 -or
   (Get-FileHash (Join-Path $module 'Clr/WindowsFilesystemProvider.cs') -Algorithm SHA256).Hash-cne$ExpectedProviderSHA256){throw 'FILESYSTEM_SOURCE_BINARY_BINDING'}
$manifest=[pscustomobject]@{sqlServerHexLiteral=('0x'+$ExpectedAssemblySHA512)}
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version='2025';Patch='base'}))
if($targets.Count-lt1){throw 'FILESYSTEM_SELECTED_SCHEMA_READY_TARGET_MISSING'}
foreach($target in $targets){
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target));$builder['Initial Catalog']='master';$builder['Pooling']=$false
$master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$consumer=$null
$created=$false;$added=$false;$ownDirectoryCreated=$false;$database='TBX_FilesystemSecurity_'+[guid]::NewGuid().ToString('N');$description='Toolbelt filesystem security '+[guid]::NewGuid().ToString('N')
$leaf='TbxSecurity-'+[guid]::NewGuid().ToString('N');$physical='C:\Windows\Temp\'+$leaf
$journal=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-filesystem-security-'+[guid]::NewGuid().ToString('N')+'.private.json')
$ledger=[ordered]@{Hash=$manifest.sqlServerHexLiteral;Description=$description;PriorExists=$null;State='PLANNED';OwnDatabase=$database;ProviderSHA256=$ExpectedProviderSHA256;OwnDirectory=$physical;DirectoryCreated=$false;DirectoryRemoved=$false}
try{
 $master.Open()
 if([int](Execute $master "SELECT CASE WHEN (SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security')=1 AND (SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled')=1 THEN 1 ELSE 0 END;" -Scalar)-ne1){throw 'SECURITY_ZIP_EXISTING_CLR_CONFIGURATION_REQUIRED'}
 $prior=[int](Execute $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash='+$manifest.sqlServerHexLiteral+';') -Scalar)-ne0
 $ledger.PriorExists=$prior;$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 if(-not$prior){
  # Exact-hash lab trust is expressly authorized for this approved wave.
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
 $script:FilesystemStage='ROLE_DEFAULT'
 Execute $consumer (Get-Content -LiteralPath (Join-Path $module 'Tests/Runtime/ServiceAccount.Role.Contract.sql') -Raw)
 $script:FilesystemStage='OWN_DIRECTORY'
 $probe="DECLARE @p TABLE(FileExists int,DirectoryExists int,ParentExists int);INSERT @p EXEC master.dbo.xp_fileexist N'$physical';SELECT DirectoryExists FROM @p;"
 if([int](Execute $consumer $probe -Scalar)-ne0){throw 'FILESYSTEM_FIXTURE_COLLISION'}
 Execute $consumer ("EXECUTE AS USER=N'ContosoFilesystemSecurity'; BEGIN TRY EXEC toolbelt_filesystem.USP_CreateDirectory @RootAlias=N'ContosoBootstrap',@RelativePath=N'$leaf',@ExecutionIdentity='ServiceAccount'; REVERT; END TRY BEGIN CATCH REVERT; THROW; END CATCH;")
 $ownDirectoryCreated=$true;$ledger.DirectoryCreated=$true;$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 Execute $consumer ("INSERT toolbelt_filesystem.FileSystemRoot(RootAlias,RootPath,AllowWrite,AllowDelete,AllowCreateDirectory,AllowServiceAccount) VALUES(N'ContosoOwn',N'$physical',1,1,1,1);")
 $script:FilesystemStage='NINE_APIS'
 Execute $consumer (Get-Content -LiteralPath (Join-Path $module 'Tests/Runtime/Security.Contract.sql') -Raw)
 if((Get-FileHash $dll -Algorithm SHA512).Hash-cne$ExpectedAssemblySHA512 -or
    (Get-FileHash (Join-Path $module 'Clr/WindowsFilesystemProvider.cs') -Algorithm SHA256).Hash-cne$ExpectedProviderSHA256){throw 'FILESYSTEM_TEST_INPUT_DRIFT'}
 'FILESYSTEM_NATIVE_ROLE_ROOT_AND_NINE_APIS_PASS'

}catch{
 $failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException}
 if($failure-is[Data.SqlClient.SqlException]){throw ('FILESYSTEM_SQL_FAILED_'+$failure.Number+'_LINE_'+$failure.LineNumber+'_STAGE_'+$script:FilesystemStage)}
 if($failure.Message-cmatch'^[A-Z0-9_]+$'){throw $failure.Message};throw 'SECURITY_ZIP_FAILED_PRIVATE_DETAILS_SUPPRESSED'
}finally{
 if($consumer -and $ownDirectoryCreated){
  Execute $consumer "DECLARE @l TABLE(EntryOrdinal bigint,RelativePath nvarchar(4000),EntryType varchar(16),SizeBytes bigint,LastWriteTimeUtc datetime2,IsReparsePoint bit); EXECUTE AS USER=N'ContosoFilesystemSecurity'; BEGIN TRY INSERT @l EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoOwn',@RelativePath=N'',@Recursive=1,@MaxDepth=4,@MaxEntries=16,@ExecutionIdentity=N'ServiceAccount'; REVERT; END TRY BEGIN CATCH REVERT; THROW; END CATCH; IF EXISTS(SELECT 1 FROM @l WHERE RelativePath NOT IN(N'binary.bin',N'text.txt',N'converted.txt',N'child')) THROW 52991,N'Unknown fixture contents prevent cleanup.',9;"

  Execute $consumer ("EXECUTE AS USER=N'ContosoFilesystemSecurity'; BEGIN TRY EXEC toolbelt_filesystem.USP_RemoveDirectory @RootAlias=N'ContosoBootstrap',@RelativePath=N'$leaf',@Recursive=1,@MaxDepth=4,@MaxEntries=16,@ExecutionIdentity='ServiceAccount'; REVERT; END TRY BEGIN CATCH REVERT; THROW; END CATCH;")
  $probe="DECLARE @p TABLE(FileExists int,DirectoryExists int,ParentExists int);INSERT @p EXEC master.dbo.xp_fileexist N'$physical';SELECT DirectoryExists FROM @p;"
  if([int](Execute $consumer $probe -Scalar)-ne0){throw 'FILESYSTEM_OWN_DIRECTORY_CLEANUP_UNVERIFIED'}
  $ledger.DirectoryRemoved=$true;$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 }
 if($consumer){$consumer.Dispose()}
 if($created){Execute $master ('DROP DATABASE ['+$database+'];');if([int](Execute $master ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)-ne0){throw 'SECURITY_ZIP_DATABASE_CLEANUP_UNVERIFIED'}}
 if($added){
  if((Get-TrustedDescription $master $manifest.sqlServerHexLiteral)-cne$description-or-not(Assert-NoAssemblyConsumer $master $manifest.sqlServerHexLiteral)){$ledger.State='RESTORE_BLOCKED';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal;throw 'SECURITY_ZIP_TRUST_CLEANUP_BLOCKED'}
  Execute $master ('EXEC sys.sp_drop_trusted_assembly @hash='+$manifest.sqlServerHexLiteral+';')
  if([int](Execute $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash='+$manifest.sqlServerHexLiteral+';') -Scalar)-ne0){throw 'SECURITY_ZIP_TRUST_CLEANUP_UNVERIFIED'}
 }
 $ledger.State='RESTORED';$ledger|ConvertTo-Json|Set-Content -LiteralPath $journal
 $master.Dispose()
}

}
