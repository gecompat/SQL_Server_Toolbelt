#Requires -Version 7.5
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Run','Audit')][string]$Mode,
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$JournalDirectory,
 [string]$SsisReleaseDirectory,
 [string]$ParserReleaseDirectory,
 [string]$InstallationPackageRoot,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPackageManifestSha256,
 [ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][hashtable]$CaseInputSha256,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$runtime=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
$journal=[IO.Path]::GetFullPath($JournalDirectory)
if(-not $journal.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_PROCEDURE_PRIVATE_JOURNAL_REQUIRED'}
$files=@('Invoke-ProcedureDefinitionCases.ps1','Invoke-CurrentCases.ps1','../Fixtures/procedure-8.dtsx')
if($CaseInputSha256.Count -ne $files.Count){throw 'SSIS_PROCEDURE_INPUT_CLOSURE'}
foreach($file in $files){
 if($CaseInputSha256[$file] -cne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file)).Hash){throw 'SSIS_PROCEDURE_INPUT_CHANGED'}
}
$binder=Join-Path $PSScriptRoot 'Invoke-CurrentQualificationLab.ps1'
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($binder,[ref]$null,[ref]$errors)
$definitions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Bind-CurrentScriptRoot'},$true))
if($errors.Count -or $definitions.Count -ne 1){throw 'SSIS_PROCEDURE_ROOT_BINDER'}
. ([scriptblock]::Create($definitions[0].Extent.Text))
function Replace-Once([string]$Text,[string]$Anchor,[string]$Replacement){
 if($Text.Split($Anchor,[StringSplitOptions]::None).Count -ne 2){throw 'SSIS_PROCEDURE_ADAPTER_ANCHOR'}
 return $Text.Replace($Anchor,$Replacement)
}
$target=@{Version='2025';Patch='CU8';ExpectedTargetKey=$ExpectedTargetKey;ExpectedContractSha256=$ExpectedContractSha256}
if($Mode -eq 'Run'){
 $original=Join-Path $PSScriptRoot 'Invoke-LabContract.ps1'
 if((Get-FileHash -LiteralPath $original).Hash -cne '4411A966484EAF55FB05778B5E26829D7AFED94D6028CB6F77323F92C5C7E570'){throw 'SSIS_PROCEDURE_LAB_HARNESS_CHANGED'}
 if(-not $QualifiedProviderSha512){throw 'SSIS_PROCEDURE_BUILD_REQUIRED'}
 $text=[IO.File]::ReadAllText($original)
 if($InstallationPackageRoot){
  $package=[IO.Path]::GetFullPath($InstallationPackageRoot)
  if(-not $package.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase) -or
     $SsisReleaseDirectory -or $ParserReleaseDirectory -or -not $ExpectedPackageManifestSha256 -or
     (Get-FileHash -LiteralPath (Join-Path $package 'PACKAGE-MANIFEST.json')).Hash -cne $ExpectedPackageManifestSha256){
   throw 'SSIS_PROCEDURE_PACKAGE_BINDING'
  }
  $text=Replace-Once $text "'SSIS-Debug-1.0.0-Install-Windows'" "'SSIS-Debug-ProcedureV1-Install-Windows'"
  $target.InstallationPackageRoot=$package
 }elseif($SsisReleaseDirectory -and $ParserReleaseDirectory -and -not $ExpectedPackageManifestSha256){
  $target.SsisReleaseDirectory=$SsisReleaseDirectory
  $target.ParserReleaseDirectory=$ParserReleaseDirectory
 }else{throw 'SSIS_PROCEDURE_BUILD_REQUIRED'}
 foreach($line in @($text -split "`n"|Where-Object {$_ -match 'Invoke-(CoreContract|ApiCases|ReleaseRightsCases|LifecycleCases)\.ps1'})){
  $text=Replace-Once $text $line ''
 }
 $anchor="    `$phase=`$mode+'-uninstall';"
 $insert=@'
    $phase=$mode+'-procedure-definition'
    & (Join-Path $PSScriptRoot 'Invoke-ProcedureDefinitionCases.ps1') -Connection $connection -Master $master -AdminConnectionString $builder.ConnectionString -RunId $runId -IdentityJournal (Join-Path $journalRoot 'identity.private.json')
'@
 $text=Replace-Once $text $anchor ($insert+"`n"+$anchor)
 $target.Modes=@('local')
 $target.CompatibilityLevel=150
 $target.JournalDirectory=$journal
 $target.QualifiedProviderSha512=$QualifiedProviderSha512
}else{
 $original=Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1'
 if((Get-FileHash -LiteralPath $original).Hash -cne '1B8D9E877D39D6A52174922016DDE89F500D0506807A9FABBB57F6606350D4CC'){throw 'SSIS_PROCEDURE_AUDIT_HARNESS_CHANGED'}
 $text=[IO.File]::ReadAllText($original)
 $anchor="    'SSIS_V2_INDEPENDENT_CLEANUP_AUDIT_PASS Functional; authenticated TLS not executed'"
 $insert=@'
    $identityPath=Join-Path (Split-Path -Parent $JournalPath) 'identity.private.json'
    if(Test-Path -LiteralPath $identityPath){
        $identity=Get-Content -Raw -LiteralPath $identityPath|ConvertFrom-Json -AsHashtable
        if($identity.login -cne ('ToolbeltSsisProc_'+$journal.runId.Substring(0,16)) -or
            $identity.sid -cnotmatch '^[0-9A-F]{32}$'){throw 'SSIS_PROCEDURE_AUDIT_IDENTITY_BINDING'}
        $result=Read-Audit 'SELECT COUNT_BIG(*) AS N FROM sys.server_principals WHERE name=@name OR sid=@sid;' @{'@name'=[string]$identity.login;'@sid'=[Convert]::FromHexString($identity.sid)}
        if($result.Rows[0].N -ne 0){throw 'SSIS_PROCEDURE_AUDIT_OWN_LOGIN_REMAINS'}
    }
    'SSIS_PROCEDURE_INDEPENDENT_CLEANUP_AUDIT_PASS'
'@
 $text=Replace-Once $text $anchor $insert
 $target.JournalPath=Join-Path $journal 'target-1.json'
 if(-not $ValidateOnly){$target.ExpectedJournalSha256=(Get-FileHash -LiteralPath $target.JournalPath).Hash}
}
$adapted=[scriptblock]::Create((Bind-CurrentScriptRoot -Text $text -Root $PSScriptRoot))
if($ValidateOnly){'SSIS_PROCEDURE_LAB_ADAPTER_VALIDATED; no SQL';return}
& $adapted @target
