$ErrorActionPreference='Stop'
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'CheckLargeGitFilesPush.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SECURITY_LOG_HELPER_PARSE'}
$definition=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Resolve-SafeLogFile'},$true))
if($definition.Count-ne1){throw 'SECURITY_LOG_HELPER_DISCOVERY'}
. ([scriptblock]::Create($definition[0].Extent.Text))
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-security-'+[guid]::NewGuid().ToString('N'))
$root=Join-Path $temporary 'repository'
[void][IO.Directory]::CreateDirectory((Join-Path $root '.git'))
try {
 foreach($bad in @('../outside.log','.git/config','.GIT/objects/log','.git:stream','log.txt:stream','.git./config','.git /config','C:relative.log',(Join-Path $temporary 'outside.log'))){
  $rejected=$false
  try{$null=Resolve-SafeLogFile $root $bad}catch{$rejected=$true}
  if(-not$rejected){throw 'SECURITY_LOG_TARGET_ACCEPTED'}
 }
 if((Resolve-SafeLogFile $root 'logs/result.log')-cne(Join-Path $root 'logs/result.log')){throw 'SECURITY_LOG_VALID_TARGET'}
 if([Environment]::OSVersion.Platform-ne[PlatformID]::Win32NT){
  $rejected=$false;try{$null=Resolve-SafeLogFile $root '../Repository/outside.log'}catch{$rejected=$true}
  if(-not$rejected){throw 'SECURITY_LOG_CASE_ESCAPE'}
 }
 # Junction creation needs no additional privileges on Windows. Only synthetic paths.
 if([Environment]::OSVersion.Platform-eq[PlatformID]::Win32NT){
  $outside=Join-Path $temporary 'outside';[void][IO.Directory]::CreateDirectory($outside)
  $junction=Join-Path $root 'redirect'
  New-Item -ItemType Junction -Path $junction -Target $outside | Out-Null
  try{
   $rejected=$false;try{$null=Resolve-SafeLogFile $root 'redirect/result.log'}catch{$rejected=$true}
   if(-not$rejected){throw 'SECURITY_LOG_REPARSE_ACCEPTED'}
  }finally{[IO.Directory]::Delete($junction)}
 }
 'SECURITY_LOG_PATHS_PASS'
}finally{
 # Only this new GUID-owned temporary directory; never cross a reparse point.
 if([IO.Path]::GetFullPath($temporary).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){
  Remove-Item -LiteralPath $temporary -Recurse -Force
 }
}
