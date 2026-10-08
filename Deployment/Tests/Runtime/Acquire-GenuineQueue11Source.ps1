# Testinterner CI-Quellenpreflight; keine öffentliche SQL-API.
# Einmal vor beiden Modi, vor New-GenuineQueue11Capture und vor jeder DB-Änderung aufrufen.
# Caller besitzt bereits einen exklusiven temporären CI-Checkout und ein NEUES privates Root/Journal.
function Acquire-GenuineQueue11Source {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][string]$RepositoryRoot,
  [Parameter(Mandatory)][string]$CaptureHelperPath,
  [Parameter(Mandatory)][System.Collections.IDictionary]$AcquisitionState,
  [Parameter(Mandatory)][switch]$CallerOwnsExclusiveCheckoutBeforeDatabase
 )
 $sourceUrl='https://github.com/gecompat/SQL_Server_Toolbelt'
 $commit='7c6cb157db39a948e14f3db1f4973f80579a5832'
 $tree='86e3b854bbf66b442cd2b19c26802628acfd0cd0'
 $moduleTree='8b0c04a64a91f7022865cc695659dd8f6e06bd39'
 $module='Modules/toolbelt.core.work-queue'
 $processHash='7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4'
 $captureHash='0DDE104052907548E6CDD29FEF0CAEC64DCC425E7DFCC418D5B5FA2ED1F52DFF'
 function Assert-Queue11Acquisition([bool]$Condition,[string]$Code){
  if(-not $Condition){throw ('QUEUE11_SOURCE_ACQUISITION.'+$Code)}
 }
 # Dieser Schalter dokumentiert Callerautorität, keinen empirischen Nachweis exklusiver Checkoutownership.
 Assert-Queue11Acquisition ($CallerOwnsExclusiveCheckoutBeforeDatabase.IsPresent) 'CALLER_BOUNDARY'
 Assert-Queue11Acquisition ($AcquisitionState.Count-eq0 -and -not$AcquisitionState.IsReadOnly -and -not$AcquisitionState.IsFixedSize) 'FRESH_STATE'
 $AcquisitionState['Status']='PRECHECK_PENDING'
 $AcquisitionState['Phase']='PRECHECK'
 $AcquisitionState['FetchInvocations']=0
 $AcquisitionState['SourceAvailability']='UNPROVEN'
 $AcquisitionState['ObjectStoreState']='NOT_TOUCHED_BY_ACQUISITION'
 $AcquisitionState['CleanupStatus']='NOT_APPLICABLE_BEFORE_FETCH'
 $watch=[Diagnostics.Stopwatch]::StartNew()
 try{
  Assert-Queue11Acquisition ($env:CI-ceq'true' -and $env:GITHUB_ACTIONS-ceq'true' -and $env:RUNNER_OS-ceq'Linux' -and $env:GITHUB_REPOSITORY-ceq'gecompat/SQL_Server_Toolbelt') 'CI_SCOPE'
  Assert-Queue11Acquisition (-not[string]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE) -and $env:GITHUB_RUN_ID-cmatch'^[1-9][0-9]*$') 'CI_IDENTITY'
  Assert-Queue11Acquisition ($env:GIT_TERMINAL_PROMPT-ceq'0' -and $env:GCM_INTERACTIVE-ceq'Never') 'NONINTERACTIVE_ENV'
  $repository=[IO.Path]::GetFullPath($RepositoryRoot)
  Assert-Queue11Acquisition ($repository-ceq[IO.Path]::GetFullPath($env:GITHUB_WORKSPACE)) 'WORKSPACE_BINDING'
  Assert-Queue11Acquisition ([IO.Directory]::Exists($repository) -and -not((Get-Item -LiteralPath $repository -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'CHECKOUT_PATH'
  # Environmentgebundene Stores/Index/Worktree/Namespace abweisen; deren Variablen niemals ändern.
  foreach($override in @('GIT_DIR','GIT_COMMON_DIR','GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES','GIT_SHALLOW_FILE','GIT_WORK_TREE','GIT_INDEX_FILE','GIT_NAMESPACE','GIT_QUARANTINE_PATH')){
   Assert-Queue11Acquisition ($null-eq[Environment]::GetEnvironmentVariable($override)) 'STORE_ENV_OVERRIDE'
  }
  function Assert-Queue11LocalStore{
   $gitDirectory=Join-Path $repository '.git'
   foreach($required in @($gitDirectory,(Join-Path $gitDirectory 'objects'))){
    Assert-Queue11Acquisition ([IO.Directory]::Exists($required) -and -not((Get-Item -LiteralPath $required -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'LOCAL_STORE_DIRECTORY'
   }
   foreach($optionalDirectory in @((Join-Path $gitDirectory 'objects/info'),(Join-Path $gitDirectory 'objects/pack'))){
    if(Test-Path -LiteralPath $optionalDirectory){
     Assert-Queue11Acquisition ([IO.Directory]::Exists($optionalDirectory) -and -not((Get-Item -LiteralPath $optionalDirectory -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'LOCAL_STORE_DIRECTORY'
    }
   }
   # Feste endliche Objektfanout-Grenze ohne Rekursion/Inventarausgabe; Fetch kann lose Objekte schreiben.
   for($bucket=0;$bucket-lt256;$bucket++){
    $path=Join-Path $gitDirectory ('objects/'+$bucket.ToString('x2',[Globalization.CultureInfo]::InvariantCulture))
    if(Test-Path -LiteralPath $path){
     Assert-Queue11Acquisition ([IO.Directory]::Exists($path) -and -not((Get-Item -LiteralPath $path -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'LOCAL_STORE_DIRECTORY'
    }
   }
   # Verknüpfte Worktrees/Commonstores/Alternates gehören nicht zum ausgewählten normalen Clone.
   foreach($forbidden in @('commondir','objects/info/alternates','objects/info/http-alternates')){
    Assert-Queue11Acquisition (-not(Test-Path -LiteralPath (Join-Path $gitDirectory $forbidden))) 'LOCAL_STORE_INDIRECTION'
   }
   $config=Join-Path $gitDirectory 'config'
   Assert-Queue11Acquisition ([IO.File]::Exists($config) -and -not((Get-Item -LiteralPath $config -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'LOCAL_STORE_FILE'
   foreach($optionalFile in @('shallow','shallow.lock')){
    $path=Join-Path $gitDirectory $optionalFile
    if(Test-Path -LiteralPath $path){
     Assert-Queue11Acquisition ([IO.File]::Exists($path) -and -not((Get-Item -LiteralPath $path -ErrorAction Stop).Attributes-band[IO.FileAttributes]::ReparsePoint)) 'LOCAL_STORE_FILE'
    }
   }
  }
  Assert-Queue11LocalStore
  $processHelper=Join-Path $repository 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
  Assert-Queue11Acquisition ((Get-FileHash -LiteralPath $processHelper -Algorithm SHA256 -ErrorAction Stop).Hash-ceq$processHash) 'PROCESS_HELPER_PIN'
  Assert-Queue11Acquisition ((Get-FileHash -LiteralPath $CaptureHelperPath -Algorithm SHA256 -ErrorAction Stop).Hash-ceq$captureHash) 'CAPTURE_HELPER_PIN'
  . $processHelper
  $git=@(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source
  $gitHash=(Get-FileHash -LiteralPath $git -Algorithm SHA256 -ErrorAction Stop).Hash
  $AcquisitionState['GitSHA256']=$gitHash
  $AcquisitionState['ProcessHelperSHA256']=$processHash
  $AcquisitionState['CaptureHelperSHA256']=$captureHash
  # Nur pro Prozess: Exakte URL-Schlüssel verhindern geerbte längere Pfadeinstellungen an
  # beiden festen Smart-HTTP-Endpunkten, die Redirects wieder aktivieren könnten. Wirksame Werte
  # werden privat vor Fetch geprüft; unbekanntes/nicht unterstütztes Verhalten wird abgewiesen.
  $requestUrls=@($sourceUrl,($sourceUrl+'/info/refs'),($sourceUrl+'/git-upload-pack'))
  $common=@('--no-lazy-fetch','--no-replace-objects','--no-optional-locks',
   '-c','fetch.prune=false','-c','fetch.pruneTags=false',
   '-c','protocol.allow=never','-c','protocol.https.allow=always',
   '-c','http.followRedirects=false')
  foreach($requestUrl in $requestUrls){$common+=@('-c',('http.'+$requestUrl+'.followRedirects=false'))}
  $common+=@('-C',$repository)
  function Invoke-Queue11AcquisitionGit([string[]]$Arguments,[int]$TimeoutMilliseconds){
   $remaining=90000-[int]$watch.ElapsedMilliseconds
   Assert-Queue11Acquisition ($remaining-gt0) 'DEADLINE'
   $budget=[Math]::Min($TimeoutMilliseconds,$remaining)
   Invoke-OwnedProcess -FileName $git -Arguments ($common+$Arguments) -TimeoutMilliseconds $budget
  }
  function Get-Queue11AcquisitionLine($Result,[string]$Code){
   Assert-Queue11Acquisition ($Result.ExitCode-eq0 -and $Result.CaptureComplete -and $Result.Stdout-is[string]) $Code
   $line=$Result.Stdout
   if($line.EndsWith("`r`n",[StringComparison]::Ordinal)){$line=$line.Substring(0,$line.Length-2)}
   elseif($line.EndsWith("`n",[StringComparison]::Ordinal)){$line=$line.Substring(0,$line.Length-1)}
   Assert-Queue11Acquisition (-not$line.Contains("`n") -and -not$line.Contains("`r")) $Code
   return $line
  }
  $AcquisitionState['Phase']='EFFECTIVE_URL'
  $result=Invoke-Queue11AcquisitionGit @('ls-remote','--get-url',$sourceUrl) 5000
  $effective=Get-Queue11AcquisitionLine $result 'EFFECTIVE_URL'
  Assert-Queue11Acquisition ($effective-ceq$sourceUrl) 'EFFECTIVE_URL'
  foreach($requestUrl in $requestUrls){
   $AcquisitionState['Phase']='REDIRECT_POLICY'
   $result=Invoke-Queue11AcquisitionGit @('config','--get-urlmatch','http.followRedirects',$requestUrl) 5000
   $effective=Get-Queue11AcquisitionLine $result 'REDIRECT_POLICY'
   Assert-Queue11Acquisition ($effective-ceq'false') 'REDIRECT_POLICY'
  }
  $AcquisitionState['Phase']='FETCH'
  $AcquisitionState['FetchInvocations']=1
  $AcquisitionState['ObjectStoreState']='PARTIAL_OR_RETAINED_UNPROVEN'
  $AcquisitionState['CleanupStatus']='DEFERRED'
  $result=Invoke-Queue11AcquisitionGit @('fetch','--no-tags','--no-write-fetch-head','--no-write-commit-graph','--no-recurse-submodules','--no-auto-gc','--depth=1','--refmap=','--no-prune','--no-prune-tags',$sourceUrl,$commit) 45000
  # Normaler Gitfortschritt darf Stderr nutzen. Kein Empty-Stderr-Gate, Rohdatenjournal oder Echo.
  $AcquisitionState['FetchExitCode']=[int]$result.ExitCode
  $AcquisitionState['FetchCaptureComplete']=[bool]$result.CaptureComplete
  Assert-Queue11Acquisition ($result.ExitCode-eq0 -and $result.CaptureComplete) 'FETCH_RESULT'
  $AcquisitionState['Phase']='SOURCE_IDENTITY'
  $result=Invoke-Queue11AcquisitionGit @('cat-file','-t',$commit) 5000
  Assert-Queue11Acquisition ((Get-Queue11AcquisitionLine $result 'COMMIT_TYPE')-ceq'commit') 'COMMIT_TYPE'
  foreach($binding in @([pscustomobject]@{Spec=$commit+'^{tree}';Expected=$tree},[pscustomobject]@{Spec=$commit+':'+$module;Expected=$moduleTree})){
   $result=Invoke-Queue11AcquisitionGit @('rev-parse','--verify',$binding.Spec) 5000
   Assert-Queue11Acquisition ((Get-Queue11AcquisitionLine $result 'TREE_ID')-ceq$binding.Expected) 'TREE_ID'
  }
  Assert-Queue11LocalStore
  Assert-Queue11Acquisition ((Get-FileHash -LiteralPath $git -Algorithm SHA256 -ErrorAction Stop).Hash-ceq$gitHash -and (Get-FileHash -LiteralPath $processHelper -Algorithm SHA256 -ErrorAction Stop).Hash-ceq$processHash -and (Get-FileHash -LiteralPath $CaptureHelperPath -Algorithm SHA256 -ErrorAction Stop).Hash-ceq$captureHash) 'TOOL_DRIFT'
  Assert-Queue11Acquisition ($watch.ElapsedMilliseconds-lt90000) 'DEADLINE'
  $AcquisitionState['Phase']='CAPTURE_REQUIRED_BEFORE_DATABASE'
  $AcquisitionState['Status']='COMMIT_AND_TREES_AVAILABLE_CAPTURE_PENDING'
  $AcquisitionState['SourceAvailability']='COMMIT_AND_TREES_ONLY'
  $AcquisitionState['ObjectStoreState']='FETCH_OBJECTS_RETAINED'
  $AcquisitionState['CleanupStatus']='RETAINED_PENDING_ALL_CONSUMERS'
  # Diese Rückgabe erfüllt weder Elf-Blob-/Expandedmanifest-Gate noch SQL- oder Cleanup-PASS.
  return [pscustomobject]@{Status=$AcquisitionState['Status'];Commit=$commit;Tree=$tree;ModuleTree=$moduleTree;FetchInvocations=1;GitSHA256=$gitHash;ProcessHelperSHA256=$processHash;CaptureHelperSHA256=$captureHash;DatabaseMutationAllowed=$false}
 }catch{
  # Auch bei fehlgeschlagener privater best-effort Statepflege den Originalfehler erhalten.
  try{
   $AcquisitionState['Status']='SOURCE_ACQUISITION_FAILED_BEFORE_DATABASE'
   if($AcquisitionState['FetchInvocations']-eq1){
    $AcquisitionState['ObjectStoreState']='PARTIAL_OR_RETAINED_UNPROVEN'
    $AcquisitionState['CleanupStatus']='DEFERRED'
   }
  }catch{}
  throw
 }
}
