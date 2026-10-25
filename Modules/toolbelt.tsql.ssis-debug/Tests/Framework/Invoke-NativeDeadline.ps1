$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$path=Join-Path $PSScriptRoot '../Runtime/Invoke-LabContract.ps1'
$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$null)
$definition=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Get-SsisNativeTimeout'},$true))
if($definition.Count -ne 1){throw 'SSIS_DEADLINE_FUNCTION_MISSING'}
. ([scriptblock]::Create($definition[0].Extent.Text))
$directory=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisDeadline-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $directory)
$child=Join-Path $directory 'child.ps1'
try{
 [IO.File]::WriteAllText($child,'param([int]$Maximum) Get-SsisNativeTimeout $Maximum')
 $ssisNativeBoundedInvocation=$true
 # Ein echtes Unterskript besitzt einen anderen Script-Scope als dieser Aufrufer.
 foreach($case in @(@(0,$false,45,45),@(299,$false,40,1),@(300,$false,40,0),@(350,$true,45,10),@(359,$true,40,1),@(360,$true,40,0))){
  $ssisNativeScopeClock=[pscustomobject]@{Elapsed=[pscustomobject]@{TotalSeconds=[double]$case[0]}}
  $ssisNativeCleanupPhase=[bool]$case[1];$caught=$false
  try{
   $actual=& $child ([int]$case[2])
   if($case[3] -eq 0 -or $actual -ne $case[3]){throw 'SSIS_DEADLINE_WRONG_VALUE'}
  }catch{
   if($case[3] -ne 0 -or $_.Exception.Message -cne 'SSIS_NATIVE_SCOPE_DEADLINE'){throw}
   $caught=$true
  }
  if($case[3] -eq 0 -and -not $caught){throw 'SSIS_DEADLINE_NOT_REJECTED'}
 }
 $ssisNativeBoundedInvocation=$false
 if((& $child 40) -ne 40){throw 'SSIS_DEADLINE_LEGACY_MULTI_MODE_CHANGED'}
 'SSIS_NATIVE_DEADLINE_PASS7; inherited script scope, command caps and work/cleanup rejection; no SQL'
}finally{
 Remove-Item -LiteralPath $child -ErrorAction SilentlyContinue
 Remove-Item -LiteralPath $directory
}
