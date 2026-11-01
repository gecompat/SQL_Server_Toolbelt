#Requires -Version 7.5
# Gemeinsame Testmechanik, keine Produkt-API und kein eigener Labprovider.
# Der kanonische Consumer validiert Schema, READY-Auswahl und TLS-Trustwert.
$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
. (Join-Path $repoRoot 'Tests/CI/LabQualifiedContract.ps1')
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'SSIS_CLIENT_DISCOVERY_SYNTAX'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definition=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
 if($definition.Count-ne 1){throw 'SSIS_CLIENT_DISCOVERY_NOT_UNIQUE'}
 . ([scriptblock]::Create($definition[0].Extent.Text))
}
function Save-ClientPrivate([string]$Path,$Value){
 [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
}
function Get-ClientHash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Reserve-ClientCase([string]$BudgetPath){
 $b=Get-Content -LiteralPath $BudgetPath -Raw|ConvertFrom-Json -DateKind String
 if([datetimeoffset]::UtcNow-ge [datetimeoffset]::Parse($b.ceilingUtc) -or $b.nativeUsed-ge $b.maximumNativeCaseOrAuditInvocations){throw 'SSIS_CLIENT_BUDGET_EXHAUSTED'}
 $b.nativeUsed++;Save-ClientPrivate $BudgetPath $b
}
function Read-ClientLab {
 $lab=Resolve-LabContract -TestPurpose Functional
 if($lab.Snapshot){throw 'SSIS_CLIENT_FUNCTIONAL_V1_REQUIRED'}
 return $lab
}
function Select-ClientTarget($Lab,[string]$Version,[string]$Patch){
 $t=@(Get-LabTargetsForSelector $Lab.Contract ([pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
 if($t.Count-ne 1){throw 'SSIS_CLIENT_EXACT_READY_TARGET_REQUIRED'}
 return $t[0]
}
function Open-ClientSql($Entry,[string]$Database='master',[switch]$Windows){
 $b=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $Entry -TestPurpose Functional))
 $b['Initial Catalog']=$Database;$b['Pooling']=$false;$b['Connect Timeout']=15
 if($Windows){[void]$b.Remove('User ID');[void]$b.Remove('Password');$b['Integrated Security']=$true}
 $c=[Data.SqlClient.SqlConnection]::new($b.ConnectionString)
 try{$c.Open();return $c}catch{$c.Dispose();throw 'SSIS_CLIENT_SQL_OPEN_FAILED'}finally{$b.Clear()}
}
function Query-Client([Data.SqlClient.SqlConnection]$Connection,[string]$Sql){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=30;$cmd.CommandText=$Sql
 try{$dt=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{$dt.Load($reader)}finally{$reader.Dispose()};return ,$dt}finally{$cmd.Dispose()}
}
function Exec-Client([Data.SqlClient.SqlConnection]$Connection,[string]$Sql){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=45;$cmd.CommandText=$Sql
 try{[void]$cmd.ExecuteNonQuery()}finally{$cmd.Dispose()}
}
function Get-ClientConfiguration($Connection){
 $dt=Query-Client $Connection 'SELECT name,CONVERT(int,value) AS C,CONVERT(int,value_in_use) AS R FROM sys.configurations ORDER BY name;'
 return @($dt.Rows|ForEach-Object {[ordered]@{name=[string]$_.name;C=[int]$_.C;R=[int]$_.R}})
}
function Same-Client($A,$B){($A|ConvertTo-Json -Depth 14 -Compress) -ceq ($B|ConvertTo-Json -Depth 14 -Compress)}
function Test-ClientImplicit($Row){
 $Row.C-eq 0 -and (($Row.name-ceq 'min server memory (MB)' -and $Row.R-in @(8,16)) -or ($Row.name-ceq 'max server memory (MB)' -and $Row.R-eq 2147483647))
}
