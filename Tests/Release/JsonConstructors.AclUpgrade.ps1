# Nur bereits genehmigte vier Objekt-EXECUTE-Rechte im eigenen Constructor-Test.
function Assert-ConstructorAclExports($Exports){
 foreach($mode in @('local','central')){
  $paths=$Exports.$mode
  $base=[IO.File]::ReadAllText($paths.base)
  $modules=@([regex]::Matches($base,'(?m)^-- BEGIN MODULE ([a-z0-9.-]+)\r?$')|ForEach-Object{$_.Groups[1].Value})
  if(($modules-join',')-cne'toolbelt.core.result-table,toolbelt.json.core'){throw 'CONSTRUCTOR_ACL_BASE_CLOSURE_REQUIRED'}
  foreach($part in @('base','historical12','current13')){
   $text=[IO.File]::ReadAllText($paths.$part)
   $text=[regex]::Replace($text,'(?im)^\s*:ON\s+ERROR\s+EXIT\s*$','')
   if($text-match'(?m)^\s*:'-or$text.Contains('$(')){throw 'CONSTRUCTOR_ACL_EXPORT_UNRESOLVED_DIRECTIVES'}
  }
  $current=[IO.File]::ReadAllText($paths.current13)
  if([regex]::Matches($current,[regex]::Escape('  SET @AssemblyId=NULL;')).Count-ne1){throw 'CONSTRUCTOR_ACL_ROLLBACK_ANCHOR'}
 }
}
function Get-ConstructorAclSnapshot($Connection){
 $sql=@'
SELECT N'procedure' Kind,o.object_id Id,ISNULL(o.principal_id,-1) Owner,
 COALESCE(o.principal_id,s.principal_id) EffectiveOwner,o.name Name
 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name=N'toolbelt_json' AND o.type=N'P' ORDER BY o.name;
SELECT N'acl' Kind,class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state
 FROM sys.database_permissions WHERE
 (class=1 AND major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json')))
 OR (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors'))
 ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state;
SELECT N'caller' Kind,principal_id,CONVERT(varchar(128),sid,2) Sid,
 CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Created,type,authentication_type
 FROM sys.database_principals WHERE name=N'ContosoJsonCaller';
'@
 $rows=@(Invoke-ReleaseSql $Connection $sql -Rows)
 if(@($rows|Where-Object Kind -CEQ 'procedure').Count-ne5-or
  @($rows|Where-Object Kind -CEQ 'acl').Count-ne4-or
  @($rows|Where-Object Kind -CEQ 'caller').Count-ne1){throw 'CONSTRUCTOR_ACL_NONEMPTY_SNAPSHOT_REQUIRED'}
 return ($rows|ConvertTo-Json -Depth 5 -Compress)
}
function Get-ConstructorAclRollbackState($Connection){
 $sql=@'
SELECT o.object_id,o.type,ISNULL(o.principal_id,-1) Owner,o.name FROM sys.objects o
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_json') AND o.type IN(N'P',N'AF',N'FT') ORDER BY o.name;
SELECT a.assembly_id,a.principal_id,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash
 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_JsonConstructors';
SELECT class,major_id,minor_id,name,CONVERT(varchar(8000),CONVERT(varbinary(8000),value),2) ValueBytes
 FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.constructors.%')
 OR (class=1 AND major_id IN(SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json')))
 OR (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors'))
 ORDER BY class,major_id,minor_id,name;
'@
 return (@(Invoke-ReleaseSql $Connection $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-ConstructorAclInstalled($Connection,[string]$Role,[string]$Mode){
 $expected=@($runset.artifacts|Where-Object role -CEQ $Role)
 if($expected.Count-ne1){throw 'CONSTRUCTOR_ACL_ARTIFACT_ROLE'}
 $rows=@(Invoke-ReleaseSql $Connection "SELECT a.permission_set_desc Permission,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonConstructors';" -Rows)
 if($rows.Count-ne1-or$rows[0].Hash-cne$expected[0].sha512-or$rows[0].Permission-cne'SAFE_ACCESS'){throw 'CONSTRUCTOR_ACL_INSTALLED_BINARY'}
 $core=@($runset.artifacts|Where-Object role -CEQ 'core')
 $coreRows=@(Invoke-ReleaseSql $Connection "SELECT a.permission_set_desc Permission,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonCore'; SELECT COUNT(*) UserAssemblies FROM sys.assemblies WHERE is_user_defined=1;" -Rows)
 if($core.Count-ne1-or$coreRows.Count-ne2-or$coreRows[0].Hash-cne$core[0].sha512-or$coreRows[0].Permission-cne'SAFE_ACCESS'-or$coreRows[1].UserAssemblies-ne2){throw 'CONSTRUCTOR_ACL_CORE_BINARY_OR_CLOSURE'}
 $v=if($Role-ceq'historical12'){'1.2.0'}else{'1.3.0'}
 $markers=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.constructors.Version',N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode');" -Rows)
 if($markers.Count-ne2-or@($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.constructors.Version'-and$_.Value-ceq$v}).Count-ne1-or
  @($markers|Where-Object{$_.name-ceq'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'-and$_.Value-ceq$Mode}).Count-ne1){throw 'CONSTRUCTOR_ACL_INSTALLED_MARKERS'}
 $references=@(Invoke-ReleaseSql $Connection "SELECT COUNT(*) N FROM sys.assembly_references WHERE assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors') AND referenced_assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore');" -Rows)
 if($references.Count-ne1-or$references[0].N-ne$(if($Role-ceq'historical12'){0}else{1})){throw 'CONSTRUCTOR_ACL_CORE_REFERENCE'}
}
function Invoke-ConstructorAclUpgrade($Connection,[string]$Mode){
 $paths=$runset.exports.$Mode
 Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($paths.historical12))
 Assert-ConstructorAclInstalled $Connection 'historical12' $Mode
 Invoke-ReleaseSql $Connection "DECLARE @O nvarchar(32)=@Owner;EXEC sys.sp_set_session_context @key=N'Test.Constructor.AclProfile.Approved',@value=1;EXEC sys.sp_set_session_context @key=N'Test.Constructor.AclProfile.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
 $null=@(Invoke-ReleaseSql $Connection ([IO.File]::ReadAllText($runset.fixture)) -Rows)
 $before=Get-ConstructorAclSnapshot $Connection
 $rollback=Get-ConstructorAclRollbackState $Connection
 $deploy=[IO.File]::ReadAllText($paths.current13)
 $needle='  SET @AssemblyId=NULL;'
 if(([regex]::Matches($deploy,[regex]::Escape($needle))).Count-ne1){throw 'CONSTRUCTOR_ACL_ROLLBACK_ANCHOR'}
 $fault=$deploy.Replace($needle,"  THROW 53691,N'Synthetic ACL migration rollback after own DROP.',1;"+[Environment]::NewLine+$needle)
 $number=0
 try{Invoke-ReleaseBatches $Connection $fault}catch{
  $exception=$_.Exception
  while($exception-and$exception-isnot[Data.SqlClient.SqlException]){$exception=$exception.InnerException}
  if($exception){$number=$exception.Number}else{throw}
 }
 if($number-ne53691){throw 'CONSTRUCTOR_ACL_EXPECTED_ROLLBACK_ERROR'}
 $afterRollback=Get-ConstructorAclSnapshot $Connection
 $rollbackAfter=Get-ConstructorAclRollbackState $Connection
 if($before-cne$afterRollback-or$rollback-cne$rollbackAfter){throw 'CONSTRUCTOR_ACL_ROLLBACK_MUTATED_STATE'}
 Assert-ConstructorAclInstalled $Connection 'historical12' $Mode
 Invoke-ReleaseBatches $Connection $deploy
 Assert-ConstructorAclInstalled $Connection 'current13' $Mode
 $afterUpgrade=Get-ConstructorAclSnapshot $Connection
 if($before-cne$afterUpgrade){throw 'CONSTRUCTOR_ACL_UPGRADE_LOST_IDENTITY_OR_PERMISSIONS'}
 Invoke-ReleaseBatches $Connection $deploy
 Assert-ConstructorAclInstalled $Connection 'current13' $Mode
 $afterRepeat=Get-ConstructorAclSnapshot $Connection
 if($before-cne$afterRepeat){throw 'CONSTRUCTOR_ACL_REPEAT_LOST_IDENTITY_OR_PERMISSIONS'}
 $cleanup=@'
REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray FROM ContosoJsonCaller;
REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject FROM ContosoJsonCaller;
REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonArraysByGroup FROM ContosoJsonCaller;
REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonObjectsByGroup FROM ContosoJsonCaller;
DROP USER ContosoJsonCaller;
IF USER_ID(N'ContosoJsonCaller') IS NOT NULL OR @@TRANCOUNT<>0 OR XACT_STATE()<>0
 THROW 53695,N'Own ACL caller cleanup/session not complete.',5;
EXEC sys.sp_set_session_context @key=N'Test.Constructor.AclProfile.Approved',@value=NULL;
EXEC sys.sp_set_session_context @key=N'Test.Constructor.AclProfile.Owner',@value=NULL;
'@
 Invoke-ReleaseSql $Connection $cleanup
 return [ordered]@{state='COMPLETE';aclEntries=4;procedureIdentities=5;rollbackPreserved=$true;
  upgradePreserved=$true;repeatPreserved=$true;callerRemoved=$true;rightsRemoved=4;
  baseline=$before;afterRollback=$afterRollback;afterUpgrade=$afterUpgrade;afterRepeat=$afterRepeat;
  rollbackBefore=$rollback;rollbackAfter=$rollbackAfter}
}
