# Testhelper: unveränderte Original-Queue1.1, keine Markerrekonstruktion oder Netzbeschaffung.
# Vor jeder späteren DB-Mutation aufrufen. Originaltransaktion/GO-Batches bleiben in einer frischen Sitzung.
function New-GenuineQueue11Capture {
 param([string]$RepositoryRoot,[string]$OutputRoot,
       [ValidateSet('local','central')][string]$DeploymentMode,
       [Collections.Generic.List[object]]$OwnedFiles,[Collections.Generic.List[string]]$OwnedDirectories)
 $commit='7c6cb157db39a948e14f3db1f4973f80579a5832'
 $tree='86e3b854bbf66b442cd2b19c26802628acfd0cd0';$moduleTree='8b0c04a64a91f7022865cc695659dd8f6e06bd39'
 $module='Modules/toolbelt.core.work-queue'
 $expected=@(
  [pscustomobject]@{Relative='Deployment/Deploy.sql';Blob='ddd52ecad1f360de670ca512a5bc0cb4ab3d7135';SHA256='7003DF29CD6927158169101429F7257D54DF41005205788025F95DFA66E00514';Length=12311}
  [pscustomobject]@{Relative='Source/WorkItem.sql';Blob='ec577674d7cc57012121cc0e2a84a38ffaacf610';SHA256='D89B03A1C3AF7621F97341BCD28C8637C9FD450295917FC3CA7127D4136CCFCC';Length=9645}
  [pscustomobject]@{Relative='Source/VW_WorkQueue.sql';Blob='db23abfbc8922cd0439e7ec455a0b9200807a99e';SHA256='1A88F85CEA1245389D1FF002D477A02D2FE13FD158D3270532948C1D55D52F39';Length=1062}
  [pscustomobject]@{Relative='Source/USP_EnqueueWork.sql';Blob='cf5eee6bede500e2362623da0955df7f351699af';SHA256='0736D919B65AC0D615F74768E1B130439369B835F95BCACC59B034C5DCD370B5';Length=11713}
  [pscustomobject]@{Relative='Source/USP_ClaimWork.sql';Blob='fae5606d30f0934020e110ad864fb38c401c919d';SHA256='58722717127733A1052B5E07C7ED55908EC98055C27E80ADE3319D58F38B316E';Length=6943}
  [pscustomobject]@{Relative='Source/USP_RenewWorkLease.sql';Blob='d530b5511c65b75ccab35f757a1e7632b90dcfab';SHA256='2ED19504B7E524B71DA41F6EA03B223286C030435787B4E870917D35F9D9AAF4';Length=5884}
  [pscustomobject]@{Relative='Source/USP_RecoverExpiredWork.sql';Blob='2de80de93c8d88b269f753fd9048e9e67540de3f';SHA256='4A3442B31588CACE3B42171A7A8BADFFC1799F2514D75EFD00898563505CB28C';Length=6351}
  [pscustomobject]@{Relative='Source/USP_CompleteWork.sql';Blob='37874d7f0c46c35a818336ecbb4fa4d73190dc10';SHA256='99F2253B7A0E6058156ADD2DA8BCF2541E8DFA1D0DCA1BE7B83AF060595D761D';Length=9953}
  [pscustomobject]@{Relative='Source/USP_FailWork.sql';Blob='481667822f0a08c8967c3a6e0dc4a4489ec6687b';SHA256='216B8F9D1D0F747AF52FE114529EA84C7B4B5E0608D2B6B3EE039F3A873BFBBF';Length=10781}
  [pscustomobject]@{Relative='Source/USP_GetWorkStatus.sql';Blob='d371e631f7e293e4d941cdec50654e496120ef3e';SHA256='ECCADECB66EBC0C1712D15D8C513A5862D6805632625985DF532F1912963DA7A';Length=7889}
  [pscustomobject]@{Relative='module.yaml';Blob='8b1ad64d501e2ae68d8d82805e06517ac84b4b79';SHA256='9737BE44BAC0373B064DA0446DD5947DABCE4F877F02FE13B7FC9330C7CA6906';Length=6289}
 )
 $helper=Join-Path $RepositoryRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
 $helperHash=(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash
 Assert-Fixture ($helperHash-ceq'7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4') 'HISTORICAL_PROCESS_HELPER'
 . $helper
 $git=@(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source
 $gitHash=(Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash
 $utf8=[Text.UTF8Encoding]::new($false,$true)
 $captureRoot=[IO.Path]::GetFullPath($OutputRoot)
 Assert-Fixture (-not[IO.Directory]::Exists($captureRoot) -and -not[IO.File]::Exists($captureRoot)) 'HISTORICAL_CAPTURE_UNIQUE'
 Assert-Fixture ($DeploymentMode-ceq'local' -or $DeploymentMode-ceq'central') 'HISTORICAL_MODE_BINDING'
 Assert-Fixture ($null-ne$OwnedFiles -and $null-ne$OwnedDirectories) 'HISTORICAL_CAPTURE_OWNERS'
 $watch=[Diagnostics.Stopwatch]::StartNew()
 # Ausschließlich lokale Plumbing-Reads. Unsupported --no-lazy-fetch wird wie fehlende Objekte abgewiesen.
 function Invoke-Queue11Git([string[]]$Arguments,[string]$BinaryOutputPath){
  $budget=[Math]::Min(5000,60000-[int]$watch.ElapsedMilliseconds)
  Assert-Fixture ($budget-gt0) 'HISTORICAL_CAPTURE_DEADLINE'
  $parameters=@{FileName=$git;Arguments=@('--no-lazy-fetch','--no-replace-objects','--no-optional-locks','-C',$RepositoryRoot)+$Arguments;TimeoutMilliseconds=$budget}
  if($BinaryOutputPath){$parameters.BinaryOutputPath=$BinaryOutputPath}
  Invoke-OwnedProcess @parameters
 }
 function Assert-Queue11GitResult($Result){
  Assert-Fixture ($Result.ExitCode-eq0 -and $Result.CaptureComplete -and $Result.Stderr.Length-eq0) 'HISTORICAL_BLOB_CAPTURE'
 }
 function Add-Queue11OwnedFile([string]$Path,[string]$Relative,[string]$Blob){
  $item=Get-Item -LiteralPath $Path
  Assert-Fixture (-not($item.Attributes-band[IO.FileAttributes]::ReparsePoint)) 'HISTORICAL_CAPTURE_FILE'
  $record=[pscustomobject]@{Path=$Path;Relative=$Relative;Blob=$Blob;SHA256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash;Length=$item.Length;CreatedTicks=$item.CreationTimeUtc.Ticks;Attributes=[int]$item.Attributes}
  $OwnedFiles.Add($record);return $record
 }
 # Vollständige Quellenverfügbarkeit vor Outputroot-Anlage und vor späterer eigener DB-Mutation.
 $result=Invoke-Queue11Git -Arguments @('cat-file','-t',$commit);Assert-Queue11GitResult $result
 Assert-Fixture ($result.Stdout.Trim()-ceq'commit') 'HISTORICAL_COMMIT_TYPE'
 foreach($spec in @([pscustomobject]@{Name=$commit+'^{tree}';Hash=$tree},[pscustomobject]@{Name=$commit+':'+$module;Hash=$moduleTree})){
  $result=Invoke-Queue11Git -Arguments @('rev-parse','--verify',$spec.Name);Assert-Queue11GitResult $result
  Assert-Fixture ($result.Stdout.Trim()-ceq$spec.Hash) 'HISTORICAL_TREE_ID'
 }
 foreach($file in $expected){
  $spec=$commit+':'+$module+'/'+$file.Relative
  $result=Invoke-Queue11Git -Arguments @('rev-parse','--verify',$spec);Assert-Queue11GitResult $result
  Assert-Fixture ($result.Stdout.Trim()-ceq$file.Blob) 'HISTORICAL_BLOB_ID'
  $result=Invoke-Queue11Git -Arguments @('cat-file','-t',$file.Blob);Assert-Queue11GitResult $result
  Assert-Fixture ($result.Stdout.Trim()-ceq'blob') 'HISTORICAL_BLOB_TYPE'
  $result=Invoke-Queue11Git -Arguments @('cat-file','-s',$file.Blob);Assert-Queue11GitResult $result
  Assert-Fixture ($result.Stdout.Trim()-ceq([string]$file.Length)) 'HISTORICAL_BLOB_LENGTH'
 }
 [void][IO.Directory]::CreateDirectory($captureRoot);$OwnedDirectories.Add($captureRoot)
 $captured=[Collections.Generic.List[object]]::new()
 foreach($file in $expected){
  $target=Join-Path $captureRoot $file.Relative;$directory=Split-Path $target -Parent
  if(-not[IO.Directory]::Exists($directory)){[void][IO.Directory]::CreateDirectory($directory);$OwnedDirectories.Add($directory)}
  $result=Invoke-Queue11Git -Arguments @('cat-file','blob',$file.Blob) -BinaryOutputPath $target
  # Erst der zurückgekehrte CreateNew-Capture begründet eigene Dateiownership, auch bei nachfolgendem Pinfehler.
  $record=Add-Queue11OwnedFile $target $file.Relative $file.Blob;$captured.Add($record)
  Assert-Queue11GitResult $result
  $bytes=[IO.File]::ReadAllBytes($target)
  $prefix=[Text.Encoding]::ASCII.GetBytes('blob '+$bytes.Length+[char]0)
  $blobBytes=[byte[]]::new($prefix.Length+$bytes.Length)
  [Array]::Copy($prefix,0,$blobBytes,0,$prefix.Length);[Array]::Copy($bytes,0,$blobBytes,$prefix.Length,$bytes.Length)
  $blob=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData($blobBytes)).ToLowerInvariant()
  Assert-Fixture ($blob-ceq$file.Blob -and $record.SHA256-ceq$file.SHA256 -and $record.Length-eq$file.Length) 'HISTORICAL_BLOB_BYTES'
 }
 # Neun feste Includes vollständig, genau einmal und in Originalreihenfolge verbrauchen.
 $deploy=Join-Path $captureRoot 'Deployment/Deploy.sql'
 $deployBytes=[IO.File]::ReadAllBytes($deploy)
 Assert-Fixture ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($deployBytes))-ceq$expected[0].SHA256) 'HISTORICAL_BLOB_BYTES'
 $text=$utf8.GetString($deployBytes)
 $includes=[regex]::Matches($text,'(?m)^:r ../Source/([A-Za-z0-9_]+\.sql)\r?$')
 $sourceFiles=@($expected|Where-Object {$_.Relative.StartsWith('Source/',[StringComparison]::Ordinal)})
 Assert-Fixture ($includes.Count-eq9 -and $sourceFiles.Count-eq9) 'HISTORICAL_INCLUDE_COUNT'
 for($i=0;$i-lt9;$i++){
  Assert-Fixture (('Source/'+$includes[$i].Groups[1].Value)-ceq$sourceFiles[$i].Relative) 'HISTORICAL_INCLUDE_BINDING'
 }
 $expanded=$text;$readIndex=0
 foreach($include in $includes){
  $source=Join-Path $captureRoot ('Source/'+$include.Groups[1].Value)
  $sourceBytes=[IO.File]::ReadAllBytes($source)
  Assert-Fixture ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($sourceBytes))-ceq$sourceFiles[$readIndex].SHA256) 'HISTORICAL_BLOB_BYTES'
  $sourceText=$utf8.GetString($sourceBytes);$readIndex++
  Assert-Fixture (-not[regex]::IsMatch($sourceText,'(?m)^\s*:')) 'HISTORICAL_SOURCE_DIRECTIVE'
  Assert-Fixture ($expanded.Contains($include.Value,[StringComparison]::Ordinal)) 'HISTORICAL_INCLUDE_CONSUMPTION'
  $expanded=$expanded.Replace($include.Value,$sourceText)
 }
 Assert-Fixture (-not[regex]::IsMatch($expanded,'(?m)^\s*:r\b')) 'HISTORICAL_INCLUDE_CONSUMPTION'
 Assert-Fixture ([regex]::Matches($expanded,'\$\(DeploymentMode\)').Count-eq1) 'HISTORICAL_MODE_BINDING'
 $expanded=$expanded.Replace('$(DeploymentMode)',$DeploymentMode)
 Assert-Fixture (-not[regex]::IsMatch($expanded,'\$\(')) 'HISTORICAL_UNBOUND_VARIABLE'
 foreach($line in [regex]::Matches($expanded,'(?m)^\s*:[^\r\n]*')){
  Assert-Fixture ($line.Value.Trim()-ceq':On Error exit') 'HISTORICAL_EXPORT_DIRECTIVE'
 }
 $expandedBytes=$utf8.GetBytes($expanded)
 Assert-Fixture ($expandedBytes.Length-le4*1024*1024) 'HISTORICAL_CAPTURE_LIMIT'
 $export=Join-Path $captureRoot ('Queue11-'+$DeploymentMode+'.sql')
 $stream=[IO.File]::Open($export,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($expandedBytes,0,$expandedBytes.Length)}finally{$stream.Dispose()}
 $exportRecord=Add-Queue11OwnedFile $export ('Queue11-'+$DeploymentMode+'.sql') $null
 Assert-Fixture ($watch.ElapsedMilliseconds-lt60000) 'HISTORICAL_CAPTURE_DEADLINE'
 Assert-Fixture ((Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash-ceq$gitHash -and (Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-ceq$helperHash) 'HISTORICAL_TOOL_DRIFT'
 $manifest=Join-Path $captureRoot 'SourcePins.json'
 $json=ConvertTo-Json -InputObject ([ordered]@{Commit=$commit;Tree=$tree;ModuleTree=$moduleTree;DeploymentMode=$DeploymentMode;Includes=$sourceFiles.Relative;Files=$captured.ToArray();ExpandedSHA256=$exportRecord.SHA256;GitSHA256=$gitHash;HelperSHA256=$helperHash}) -Depth 5
 $manifestBytes=$utf8.GetBytes($json)
 $stream=[IO.File]::Open($manifest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($manifestBytes,0,$manifestBytes.Length)}finally{$stream.Dispose()}
 [void](Add-Queue11OwnedFile $manifest 'SourcePins.json' $null)
 return $export
}
