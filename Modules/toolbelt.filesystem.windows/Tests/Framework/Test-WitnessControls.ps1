# Synthetische Kontrollen des tatsächlichen Witness-Parsers; kein Compiler/Provideraufruf.
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$path=Join-Path $PSScriptRoot 'Invoke-NoOverwrite.ps1';$bytes=[IO.File]::ReadAllBytes($path)
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput([Text.UTF8Encoding]::new($false,$true).GetString($bytes),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'FS_TEST_CONTROL_AST'}
$functions=@($ast.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq'Test-NoOverwriteWitness'},$true))
if($functions.Count-ne1){throw 'FS_TEST_CONTROL_FUNCTION'}
. ([scriptblock]::Create($functions[0].Extent.Text))
$good="PASS FIXED_HELPER CASES=9 STAGING_CREATE_ACTIONS=9 SENTINEL_CREATE_ACTIONS=5 DISTINCT_OWN_PATHS=10 MAX_SIMULTANEOUS_OWN_FILES=2 ASSERTIONS=254 STREAMING_CASES=7 STREAMING_ASSERTIONS=100 DELETE_CASES=12 DELETE_ASSERTIONS=500 CLEANUP_VERIFIED=1 OFFLINE_ONLY`n"
$n=0;foreach($text in @($good,$good.Replace("`n","`r`n"))){$r=Test-NoOverwriteWitness $text;if($r.Cases-ne9-or$r.Assertions-ne254-or$r.StreamingCases-ne7-or$r.StreamingAssertions-ne100-or$r.DeleteCases-ne12-or$r.DeleteAssertions-ne500){throw 'FS_TEST_CONTROL_VALID'};$n++}
$bad=@(($good+'extra'),$good.Replace('CASES=9','CASES=8'),$good.Replace('STAGING_CREATE_ACTIONS=9','STAGING_CREATE_ACTIONS=8'),$good.Replace('SENTINEL_CREATE_ACTIONS=5','SENTINEL_CREATE_ACTIONS=4'),$good.Replace('DISTINCT_OWN_PATHS=10','DISTINCT_OWN_PATHS=11'),$good.Replace('MAX_SIMULTANEOUS_OWN_FILES=2','MAX_SIMULTANEOUS_OWN_FILES=3'),$good.Replace('ASSERTIONS=254','ASSERTIONS=0'),$good.Replace('CLEANUP_VERIFIED=1','CLEANUP_VERIFIED=0'),$good.Replace('ASSERTIONS=254','ASSERTIONS=999999999999999999999'),$good.Replace('STREAMING_CASES=7','STREAMING_CASES=6'),$good.Replace('STREAMING_ASSERTIONS=100','STREAMING_ASSERTIONS=0'),$good.Replace('STREAMING_ASSERTIONS=100','STREAMING_ASSERTIONS=4097'))
$bad+=@(
 $good.Replace('DELETE_CASES=12','DELETE_CASES=11'),
 $good.Replace('DELETE_CASES=12','DELETE_CASES=0'),
 $good.Replace('DELETE_ASSERTIONS=500','DELETE_ASSERTIONS=0'),
 $good.Replace('DELETE_ASSERTIONS=500','DELETE_ASSERTIONS=4097'),
 $good.Replace('DELETE_ASSERTIONS=500','DELETE_ASSERTIONS=999999999999999999999'),
 $good.Replace(' DELETE_CASES=12 DELETE_ASSERTIONS=500',''),
 $good.Replace('DELETE_CASES=12','DELETE_CASES=12 DELETE_CASES=12'),
 $good.Replace('DELETE_ASSERTIONS=500','DELETE_ASSERTIONS=500 DELETE_ASSERTIONS=500'),
 $good.Replace('DELETE_CASES=12','delete_cases=12'),
 $good.Replace('DELETE_CASES=12','DELETE_CASES=-12'),
 $good.Replace('DELETE_CASES=12','DELETE_CASES='+[char]0x0661+[char]0x0662),
 $good.TrimEnd("`n")
)
foreach($text in $bad){$rejected=$false;try{[void](Test-NoOverwriteWitness $text)}catch{$rejected=$true};if(-not$rejected){throw 'FS_TEST_CONTROL_FALSE_ACCEPT'};$n++}
if((Get-FileHash -LiteralPath $path).Hash-cne$hash){throw 'FS_TEST_CONTROL_SOURCE_DRIFT'}
if($n-ne26){throw 'FS_TEST_CONTROL_COUNT'}
'PASS NO_OVERWRITE_WITNESS_CONTROLS CHECKS='+$n+' SYNTHETIC_ONLY'
