# Gepinnte Originalquellen; keine Rekonstruktion historischer Versionmarker.
function New-GenuineQueue20Capture {
 param([string]$RepositoryRoot,[string]$OutputRoot,
       [Collections.Generic.List[object]]$OwnedFiles,[Collections.Generic.List[string]]$OwnedDirectories)
 $commit='62e7b06588b28c45c58f7ec335e4e5c45f120e3e'
 $module='Modules/toolbelt.core.work-queue'
 $files=@('Deployment/Deploy.sql','Source/WorkItem.sql','Source/VW_WorkQueue.sql','Source/VW_WorkQueueBarrierBlockers.sql','Source/USP_EnqueueWork.sql','Source/USP_EnqueueWorkWithPolicy.sql','Source/USP_EnqueueBarrierWork.sql','Source/USP_ClaimWork.sql','Source/USP_RenewWorkLease.sql','Source/USP_RecoverExpiredWork.sql','Source/USP_CompleteWork.sql','Source/USP_FailWork.sql','Source/USP_ScheduleWorkRetry.sql','Source/USP_RequeueDeadLetter.sql','Source/USP_GetWorkStatus.sql')
 $helper=Join-Path $RepositoryRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
 $helperHash=(Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash
 Assert-Fixture ($helperHash-ceq'7B3E838EE5D294B3DECF3153D2D02276BE401E6F76EE8D810F20C5DCC51D1BD4') 'HISTORICAL_PROCESS_HELPER'
 . $helper
 $git=@(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source
 $gitHash=(Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash
 Assert-Fixture (-not[IO.Directory]::Exists($OutputRoot)) 'HISTORICAL_CAPTURE_UNIQUE'
 [void][IO.Directory]::CreateDirectory($OutputRoot);$OwnedDirectories.Add($OutputRoot)
 $watch=[Diagnostics.Stopwatch]::StartNew()
 foreach($relative in $files){
  $target=Join-Path $OutputRoot $relative
  $directory=Split-Path $target -Parent
  if(-not[IO.Directory]::Exists($directory)){[void][IO.Directory]::CreateDirectory($directory);$OwnedDirectories.Add($directory)}
  $budget=[Math]::Min(5000,60000-[int]$watch.ElapsedMilliseconds)
  Assert-Fixture ($budget-gt0) 'HISTORICAL_CAPTURE_DEADLINE'
  $spec=$commit+':'+$module+'/'+$relative
  $blob=Invoke-OwnedProcess -FileName $git -Arguments @('-C',$RepositoryRoot,'rev-parse','--verify',$spec) -TimeoutMilliseconds $budget
  Assert-Fixture ($blob.ExitCode-eq0 -and $blob.CaptureComplete -and $blob.Stderr.Length-eq0 -and $blob.Stdout.Trim()-cmatch'^[0-9a-f]{40}$') 'HISTORICAL_BLOB_ID'
  $budget=[Math]::Min(5000,60000-[int]$watch.ElapsedMilliseconds)
  Assert-Fixture ($budget-gt0) 'HISTORICAL_CAPTURE_DEADLINE'
  $capture=Invoke-OwnedProcess -FileName $git -Arguments @('-C',$RepositoryRoot,'cat-file','blob',$spec) -TimeoutMilliseconds $budget -BinaryOutputPath $target
  Assert-Fixture ($capture.ExitCode-eq0 -and $capture.CaptureComplete -and $capture.Stderr.Length-eq0) 'HISTORICAL_BLOB_CAPTURE'
  $bytes=[IO.File]::ReadAllBytes($target)
  $prefix=[Text.Encoding]::ASCII.GetBytes('blob '+$bytes.Length+[char]0)
  $inputBytes=[byte[]]::new($prefix.Length+$bytes.Length)
  [Array]::Copy($prefix,0,$inputBytes,0,$prefix.Length);[Array]::Copy($bytes,0,$inputBytes,$prefix.Length,$bytes.Length)
  $actualBlob=[Convert]::ToHexString([Security.Cryptography.SHA1]::HashData($inputBytes)).ToLowerInvariant()
  Assert-Fixture ($actualBlob-ceq$blob.Stdout.Trim()) 'HISTORICAL_BLOB_BYTES'
  $item=Get-Item -LiteralPath $target
  $OwnedFiles.Add([pscustomobject]@{Path=$target;Relative=$relative;Blob=$actualBlob;SHA256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash;Length=$item.Length;CreatedTicks=$item.CreationTimeUtc.Ticks;Attributes=[int]$item.Attributes})
 }
 Assert-Fixture ((Get-FileHash -LiteralPath $git -Algorithm SHA256).Hash-ceq$gitHash -and (Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash-ceq$helperHash) 'HISTORICAL_TOOL_DRIFT'
 $deploy=Join-Path $OutputRoot 'Deployment/Deploy.sql'
 $includes=@([IO.File]::ReadAllLines($deploy)|Where-Object {$_-match'^:r '})
 Assert-Fixture ($includes.Count-eq14) 'HISTORICAL_INCLUDE_COUNT'
 foreach($line in $includes){
  Assert-Fixture ($line-cmatch'^:r ../Source/([A-Za-z0-9_]+\.sql)$') 'HISTORICAL_INCLUDE_SHAPE'
  Assert-Fixture ($files-ccontains('Source/'+$Matches[1])) 'HISTORICAL_INCLUDE_BINDING'
 }
 $manifest=Join-Path $OutputRoot 'SourcePins.json'
 [IO.File]::WriteAllText($manifest,(ConvertTo-Json -InputObject ([ordered]@{Commit=$commit;Files=$OwnedFiles.ToArray();GitSHA256=$gitHash;HelperSHA256=$helperHash}) -Depth 5),[Text.UTF8Encoding]::new($false))
 $item=Get-Item -LiteralPath $manifest
 $OwnedFiles.Add([pscustomobject]@{Path=$manifest;SHA256=(Get-FileHash -LiteralPath $manifest).Hash;Length=$item.Length;CreatedTicks=$item.CreationTimeUtc.Ticks;Attributes=[int]$item.Attributes})
 return $deploy
}
