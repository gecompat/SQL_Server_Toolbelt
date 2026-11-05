#Requires -Version 7.5
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$driver=Join-Path $root 'Tests/CI/Invoke-ScriptParserCurrentLab.ps1'
. (Join-Path $root 'Tests/CI/ParserCurrentSnapshot.ps1')
$checks=0
function Assert-ParserProbe([bool]$Condition){if(-not $Condition){throw 'PARSER_CURRENT_OFFLINE_PROBE'};$script:checks++}
$composed=(& $driver -Mode Describe)|Out-String
$errors=$null;[void][Management.Automation.Language.Parser]::ParseInput($composed,[ref]$null,[ref]$errors)
Assert-ParserProbe ($errors.Count -eq 0)
Assert-ParserProbe ($composed.Contains('$command.CommandTimeout = Get-CurrentParserTimeout') -and -not $composed.Contains('$command.CommandTimeout = 90'))
Assert-ParserProbe ($composed.IndexOf('& $frameworkGate') -lt $composed.IndexOf('$script:parserCurrentJournal.baseline='))
Assert-ParserProbe ($composed.Contains('$script:parserCurrentCleanup=$true') -and $composed.Contains('AddSeconds(120)'))
Assert-ParserProbe ($composed.Contains('Assert-NoAssemblyConsumer') -and $composed.Contains('PRIVATE_JOURNAL_MUST_BE_OUTSIDE_GIT'))
$tokens=$null;$errors=$null
$composedAst=[Management.Automation.Language.Parser]::ParseInput($composed,[ref]$tokens,[ref]$errors)
Assert-ParserProbe ($composed.Contains("elseif (`$Version -eq '2022') {@(150,160)}"))
Assert-ParserProbe ($composed.Contains("'OutputCeilings.Contract.sql','MinimalRights.Contract.sql'"))
Assert-ParserProbe ($composed.Contains('ExpectedProviderHash=$manifest.sqlServerHexLiteral') -and $composed.Contains('ExpectedScriptDomHash=$manifest.scriptDomSqlServerHexLiteral'))
$readScript=$composedAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Read-ParserScript'},$true)
. ([scriptblock]::Create($readScript[0].Extent.Text))
$lifecyclePath=Join-Path $root 'Modules/toolbelt.tsql.script-parser/Tests/Runtime/Lifecycle.Contract.sql'
$boundLifecycle=Read-ParserScript $lifecyclePath @{ExpectedProviderHash=('0x'+('A'*128));ExpectedScriptDomHash=('0x'+('B'*128))}
Assert-ParserProbe ($boundLifecycle.Contains('0x'+('A'*128)) -and $boundLifecycle.Contains('0x'+('B'*128)) -and -not $boundLifecycle.Contains('$('))
Assert-ParserProbe (@($composedAst.FindAll({param($n)$n -is [Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -ieq 'mode'},$true)).Count -eq 0)
# Reproduce the native inherited-ValidateSet failure without loading a SQL provider.
$modeLoop=$composedAst.FindAll({param($n)$n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Variable.VariablePath.UserPath -ceq 'parserCurrentDeploymentMode'},$true)
Assert-ParserProbe (@($modeLoop).Count -eq 1)
& {
 param([ValidateSet('Run')][string]$Mode='Run')
 $loop='foreach ('+$modeLoop[0].Variable.Extent.Text+' in '+$modeLoop[0].Condition.Extent.Text+') { $parserCurrentDeploymentMode }'
 $values=@(. ([scriptblock]::Create($loop)))
 Assert-ParserProbe ($values.Count -eq 2 -and $values[0] -ceq 'local' -and $values[1] -ceq 'central' -and $Mode -ceq 'Run')
}
$script:parserCurrentCleanup=$false;$script:parserCurrentRunEnd=[datetimeoffset]::UtcNow.AddSeconds(120)
Assert-ParserProbe ((Get-CurrentParserTimeout) -eq 90)
$script:parserCurrentRunEnd=[datetimeoffset]::UtcNow.AddSeconds(-1)
try{[void](Get-CurrentParserTimeout);throw 'UNEXPECTED_TIMEOUT_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_DEADLINE')}
$script:parserCurrentCleanup=$true;$script:parserCurrentCleanupEnd=[datetimeoffset]::UtcNow.AddSeconds(30)
Assert-ParserProbe ((Get-CurrentParserTimeout) -gt 0)
$good=[pscustomobject]@{State='COMPLETE';OwnedDatabases=@([pscustomobject]@{Name=('ToolbeltParserContract_'+('a'*32));Created=$true;Dropped=$true;State='DROPPED'});Entries=@([pscustomobject]@{AddedByWave=$true;State='RESTORED'})}
Assert-CurrentParserLedger $good;$checks++
$good.OwnedDatabases[0].Name='ToolbeltParserCaller_'+('b'*32)
Assert-CurrentParserLedger $good;$checks++
$good.OwnedDatabases[0].Name='ToolbeltParser_'+('a'*32)
try{Assert-CurrentParserLedger $good;throw 'UNEXPECTED_DATABASE_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_DATABASE_SCOPE')}
$good.OwnedDatabases[0].Name='ContosoOutsideScope'
try{Assert-CurrentParserLedger $good;throw 'UNEXPECTED_DATABASE_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_DATABASE_SCOPE')}
$good.OwnedDatabases=@();$good.Entries[0].State='RESTORE_BLOCKED'
try{Assert-CurrentParserLedger $good;throw 'UNEXPECTED_TRUST_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_TRUST_NOT_RESTORED')}
class ParserFakeReader{
 [string[]]$Chunks;[int]$Index=-1
 ParserFakeReader([string[]]$Chunks){$this.Chunks=$Chunks}
 [bool]Read(){$this.Index++;return $this.Index -lt $this.Chunks.Count}
 [string]GetString([int]$Column){return $this.Chunks[$this.Index]}
 [void]Dispose(){}
}
class ParserFakeCommand{
 [string[]]$Chunks;[int]$CommandTimeout;[string]$CommandText
 ParserFakeCommand([string[]]$Chunks){$this.Chunks=$Chunks}
 [object]ExecuteReader(){return [ParserFakeReader]::new($this.Chunks)}
 [void]Dispose(){}
}
class ParserFakeConnection{
 [string[]]$Chunks
 ParserFakeConnection([string[]]$Chunks){$this.Chunks=$Chunks}
 [object]CreateCommand(){return [ParserFakeCommand]::new($this.Chunks)}
}
$script:parserCurrentCleanupEnd=[datetimeoffset]::UtcNow.AddSeconds(60)
$fake=[ParserFakeConnection]::new(@('{"a":','1}'))
Assert-ParserProbe ((Read-CurrentParserJson $fake 'synthetic only') -ceq '{"a":1}')
$fake=[ParserFakeConnection]::new(@('x'*4194305))
try{[void](Read-CurrentParserJson $fake 'synthetic only');throw 'UNEXPECTED_SNAPSHOT_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_SNAPSHOT_LIMIT')}
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('ContosoParserPlan_'+[guid]::NewGuid().ToString('N')+'.json')
try{
 [IO.File]::WriteAllText($temporary,'{"schema":"contoso-unsupported"}')
 try{& $driver -Mode Run -PlanPath $temporary -ExpectedPlanSha256 ('0'*64);throw 'UNEXPECTED_PLAN_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_PLAN_CHANGED')}
 try{& $driver -Mode Run -PlanPath $temporary -ExpectedPlanSha256 (Get-FileHash $temporary).Hash;throw 'UNEXPECTED_SCOPE_ACCEPTANCE'}catch{Assert-ParserProbe ($_.Exception.Message -ceq 'PARSER_CURRENT_SELECTED_SCOPE')}
}finally{[IO.File]::Delete($temporary)}
"PARSER_CURRENT_OFFLINE_PASS $checks checks; no SQL, credentials or GUI"
