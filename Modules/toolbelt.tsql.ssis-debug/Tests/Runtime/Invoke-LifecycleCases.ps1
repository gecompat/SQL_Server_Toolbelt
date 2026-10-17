param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[Parameter(Mandatory)][string]$Mode)
# Nur in der eigenen leeren Labdatenbank; kein fremder Bestand wird verändert.
$checks=0
$deploy=[IO.File]::ReadAllText((Join-Path $ssisRelease 'Deploy.WithAssembly.sql'))
$remove=[IO.File]::ReadAllText((Join-Path $ssisRelease 'Uninstall.Expanded.sql'))
function Inventory {
 $t=Query $Connection @'
SELECT (SELECT o.object_id,o.name,o.type,CONVERT(varchar(128),HASHBYTES('SHA2_512',OBJECT_DEFINITION(o.object_id)),2) AS body
 FROM sys.objects o WITH(NOLOCK) WHERE SCHEMA_NAME(o.schema_id) LIKE N'toolbelt[_]%' ORDER BY o.object_id FOR JSON PATH) AS O,
 (SELECT a.assembly_id,a.name,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) AS bits FROM sys.assemblies a WITH(NOLOCK)
 JOIN sys.assembly_files f WITH(NOLOCK) ON a.assembly_id=f.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.assembly_id FOR JSON PATH) AS A,
 (SELECT class,major_id,minor_id,name,CONVERT(nvarchar(max),value) AS value FROM sys.extended_properties WITH(NOLOCK)
 WHERE name LIKE N'Toolbelt.%' ORDER BY class,major_id,minor_id,name FOR JSON PATH) AS E;
'@
 [string]$t.Rows[0].O+[string]$t.Rows[0].A+[string]$t.Rows[0].E
}
function Refuse([scriptblock]$Action,[string]$Token,[int]$Number=50000){
 $before=Inventory;$found=$false
 try{& $Action}catch{$leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException};if($leaf -isnot [Data.SqlClient.SqlException] -or $leaf.Number -ne $Number -or $leaf.Message -notmatch $Token){throw 'SSIS_LIFECYCLE_UNEXPECTED_REJECTION'};$found=$true}
 if(-not $found -or (Inventory) -cne $before){throw 'SSIS_LIFECYCLE_REJECTION_NOT_ATOMIC'};$script:checks++
}
NonQuery $Connection 'CREATE PROCEDURE dbo.SyntheticSsisConsumer AS EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;'
try{Refuse {Batches $Connection $remove $Mode} 'TBX_SSISDBG_lifecycle_consumer'}finally{NonQuery $Connection 'DROP PROCEDURE dbo.SyntheticSsisConsumer;'}
$internal=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Source/USP_ExplainSsisDataFlowInternal.sql')).Replace('toolbelt_tsql.USP_ExplainSsisDataFlowInternal','dbo.SyntheticAssemblyConsumer')
Batches $Connection $internal $Mode
try{Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_lifecycle_consumer';Refuse {Batches $Connection $remove $Mode} 'TBX_SSISDBG_lifecycle_consumer'}finally{NonQuery $Connection 'DROP PROCEDURE dbo.SyntheticAssemblyConsumer;'}
NonQuery $Connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'synthetic.foreign',@level0type=N'SCHEMA',@level0name=N'toolbelt_tsql',@level1type=N'PROCEDURE',@level1name=N'USP_ExplainSsisDataFlow';"
try{Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_lifecycle_collision';Refuse {Batches $Connection $remove $Mode} 'TBX_SSISDBG_lifecycle_collision'}finally{NonQuery $Connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.tsql.ssis-debug',@level0type=N'SCHEMA',@level0name=N'toolbelt_tsql',@level1type=N'PROCEDURE',@level1name=N'USP_ExplainSsisDataFlow';"}
NonQuery $Connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version',@value=N'0.0.0';"
try{Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_unresolved_dependency'}finally{NonQuery $Connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version',@value=N'2.0.1';"}
foreach($resource in @('toolbelt.deploy.toolbelt.tsql.ssis-debug','toolbelt.deploy.toolbelt.tsql.script-parser')){
 $other=([ICloneable]$Connection).Clone();$other.Open()
 try{
  NonQuery $other ("DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'"+$resource+"',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';IF @r<0 THROW 50000,N'SYNTHETIC_LOCK_SETUP_FAILED',1;")
  Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_lifecycle_lock'
  Refuse {Batches $Connection $remove $Mode} 'TBX_SSISDBG_lifecycle_lock'
 }finally{$other.Dispose()}
}
NonQuery $Connection 'SET XACT_ABORT ON;BEGIN TRANSACTION;'
try{
 Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_lifecycle_transaction'
 Refuse {Batches $Connection $remove $Mode} 'TBX_SSISDBG_lifecycle_transaction'
 $state=Query $Connection 'SELECT @@TRANCOUNT AS T,XACT_STATE() AS S;'
 if($state.Rows[0].T -ne 1 -or $state.Rows[0].S -ne 1){throw 'SSIS_LIFECYCLE_CALLER_TRANSACTION_DAMAGED'};$checks++
}finally{NonQuery $Connection 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;SET XACT_ABORT OFF;'}
$parserRemove=(Expand (Join-Path $repoRoot 'Modules/toolbelt.tsql.script-parser/Deployment/Uninstall.sql')).Replace('$(ConfirmNoExternalConsumers)','1')
Refuse {Batches $Connection $parserRemove $Mode} '.' 53108
Batches $Connection $remove $Mode
NonQuery $Connection 'CREATE PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow AS SELECT 1 AS SyntheticForeign;'
try{Refuse {Batches $Connection $deploy $Mode} 'TBX_SSISDBG_lifecycle_collision'}finally{NonQuery $Connection 'DROP PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow;'}
Batches $Connection $deploy $Mode
"SSIS_NATIVE_LIFECYCLE_PASS $checks assertions"
