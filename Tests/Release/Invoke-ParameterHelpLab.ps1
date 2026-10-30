[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidateRange(0,99)][int]$CaseIndex,
      [switch]$AuditOnly,[switch]$PreflightOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$control=$null;$stage='PREFLIGHT'
# Existing bounded SQL, lab validation, identity and trust-consumer guards only.
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'PARAMETER_HELP_IMPORT_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'PARAMETER_HELP_IMPORT_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin','Assert-ReleasePrivatePath','Invoke-ReleaseSql','Open-ReleaseConnection',
    'Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
    'Get-CsvTrust'='Get-HelpTrust';'Assert-CsvTrustCleanupScope'='Assert-HelpTrustCleanupScope';
    'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}
function Get-ReleaseTimeout {
    $remaining=($(if($script:cleanup){1200000}else{900000}))-$script:clock.ElapsedMilliseconds
    if($remaining -lt 1000){throw 'PARAMETER_HELP_DEADLINE'}
    [int][Math]::Min(120,[Math]::Floor($remaining/1000))
}
try {
    $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
    $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
    if($runset.schema_version -cne 'toolbelt-parameter-help-runset/v1' -or $CaseIndex -ge $runset.cases.Count){throw 'PARAMETER_HELP_RUNSET'}
    $case=$runset.cases[$CaseIndex]
    if($case.Platform -cnotin @('windows','linux') -or $case.Version -cnotin @('2019','2022','2025') -or
       $case.CL -ne @{'2019'=150;'2022'=160;'2025'=170}[[string]$case.Version]){throw 'PARAMETER_HELP_SELECTOR'}
    Assert-ReleaseInputs
    foreach($required in @($PSCommandPath,$runset.fixture,$runset.package,(Join-Path $PSScriptRoot 'Runtime/Invoke-ParameterHelpCases.ps1'),
        (Join-Path $PSScriptRoot 'Invoke-ApiQualificationLab.ps1'),(Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),(Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'))){
        if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'PARAMETER_HELP_REQUIRED_PIN'}
    }
    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
        'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
    $lab=Resolve-LabContract -TestPurpose Functional
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'PARAMETER_HELP_LAB_DRIFT'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if($targets.Count -ne 1){throw 'PARAMETER_HELP_EXACT_TARGET'}
    $target=$targets[0]
    $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
    if($PreflightOnly){'PASS PARAMETER_HELP schema-valid exact target and pinned inputs; no SQL';exit 0}
    $control=Open-ReleaseConnection 'master'
    # Required real-login reachability preflight; runtime/inventory values stay
    # in memory and are never emitted as repository or public evidence.
    Invoke-ReleaseSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
    if($AuditOnly){
        $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
        if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$'){throw 'PARAMETER_HELP_AUDIT_STATE'}
        foreach($entry in $prior.databases){
            if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'PARAMETER_HELP_AUDIT_OWNER'}
            $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'PARAMETER_HELP_AUDIT_DATABASE'}
        }
        foreach($entry in $prior.trust){if(-not $entry.preexisting -and $null -ne (Get-HelpTrust $control ([Convert]::FromHexString($entry.hash)))){throw 'PARAMETER_HELP_AUDIT_TRUST'}}
        Assert-ReleaseInputs
    } else {
        if(Test-Path -LiteralPath $journal){throw 'PARAMETER_HELP_ALREADY_ATTEMPTED'}
        $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin,(SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled') Clr;" -Rows)
        if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1 -or $actual[0].Clr -ne 1){throw 'PARAMETER_HELP_TARGET_OR_CLR_NOT_READY'}
        $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();results=@();failure=$null}
        Save-ReleaseJournal
        $zip=[IO.Compression.ZipFile]::OpenRead($runset.package)
        try {
            $payload=@{}
            foreach($entry in $zip.Entries){
                if($payload.ContainsKey($entry.FullName) -or $entry.Length -gt 67108864){throw 'PARAMETER_HELP_PACKAGE_ENTRY'}
                $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8)
                try{$payload[$entry.FullName]=$reader.ReadToEnd()}finally{$reader.Dispose()}
            }
        }finally{$zip.Dispose()}
        $metadata=$payload['PACKAGE.json']|ConvertFrom-Json
        $profilePlatform=if($case.Platform -ceq 'windows'){'Windows'}else{'Portable'}
        $trustNames=@($metadata.binary_sha512.PSObject.Properties|Where-Object {$profilePlatform -ceq 'Windows' -or $_.Name -notin @('Toolbelt.Filesystem.Windows.dll','Toolbelt.Tsql.ScriptParser.dll','Toolbelt.Tsql.SsisDebug.dll','Microsoft.SqlServer.TransactSql.ScriptDom.dll')})
        foreach($property in $trustNames){
            $hash=[Convert]::FromHexString($property.Value);$before=Get-HelpTrust $control $hash
            $entry=[ordered]@{hash=$property.Value;preexisting=($null -ne $before);state='PREEXISTING';fingerprint=$null;description=$null}
            $ledger.trust+=@($entry);Save-ReleaseJournal
            if($before){continue}
            Assert-HelpTrustCleanupScope $control $hash
            $entry.state='ADDING';$entry.description='Toolbelt Parameter Help '+$ledger.owner+' '+$property.Name;Save-ReleaseJournal
            Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
            $after=Get-HelpTrust $control $hash
            if($null -eq $after -or $after.description -cne $entry.description){throw 'PARAMETER_HELP_TRUST_IDENTITY'}
            $entry.fingerprint=$after.Fingerprint;$entry.state='ADDED';Save-ReleaseJournal
        }
        foreach($mode in @('local','central')){
            $stage='CREATE_'+$mode;$suffix=if($mode -ceq 'local'){'l'}else{'c'}
            $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
            $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
            $ledger.databases+=@($entry);Save-ReleaseJournal
            Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
            $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
            if($id.Count -ne 1){throw 'PARAMETER_HELP_DATABASE_IDENTITY'}
            $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
            $db=Open-ReleaseConnection $name
            Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
            Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
            $stage='INSTALL_'+$mode
            Invoke-ReleaseBatches $db $payload['Install-'+$profilePlatform+'-'+$mode+'.sql']
            $stage='HELP_'+$mode
            $result=& (Join-Path $PSScriptRoot 'Runtime/Invoke-ParameterHelpCases.ps1') -Connection $db -Fixture $runset.fixture -Platform $profilePlatform -Mode $mode -Deadline ([datetime]::UtcNow.AddMilliseconds(900000-$clock.ElapsedMilliseconds))
            $ledger.results+=@(@{mode=$mode;platform=$profilePlatform;result=$result});Save-ReleaseJournal
            $db.Dispose()
        }
        Assert-ReleaseInputs
    }
} catch {
    $failure=$_.Exception
    if($ledger -and -not $AuditOnly){$ledger.failure=@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace};Save-ReleaseJournal}
    elseif($runset -and $RunsetPath){
        $diagnostic=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('preflight-'+$CaseIndex+'.json'))
        [IO.File]::WriteAllText($diagnostic,(@{stage=$stage;privateDiagnostic=$failure.Message;privatePosition=$_.ScriptStackTrace}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    }
} finally {
    foreach($connection in $connections){try{$connection.Dispose()}catch{}}
    if($ledger -and -not $AuditOnly){
        $cleanup=$true
        try {
            $control=Open-ReleaseConnection 'master'
            foreach($entry in $ledger.databases){Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal}
            foreach($entry in $ledger.trust){
                if($entry.preexisting){continue}
                $hash=[Convert]::FromHexString($entry.hash);$actual=Get-HelpTrust $control $hash
                if($entry.state -ceq 'ADDING' -and $null -eq $actual){$entry.state='NOT_ADDED';Save-ReleaseJournal;continue}
                if($null -eq $actual -or $entry.state -cne 'ADDED' -or $actual.description -cne $entry.description -or $actual.Fingerprint -cne $entry.fingerprint){throw 'PARAMETER_HELP_TRUST_CLEANUP_DRIFT'}
                Assert-HelpTrustCleanupScope $control $hash
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
                if($null -ne (Get-HelpTrust $control $hash)){throw 'PARAMETER_HELP_TRUST_REMAINS'}
                $entry.state='REMOVED';Save-ReleaseJournal
            }
            $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
        } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
        finally {if($control){$control.Dispose()}}
    }
}
if($failure){'FAIL PARAMETER_HELP; inspect private journal; reconcile before a new attempt';exit 1}
if($AuditOnly){'PASS PARAMETER_HELP input/absence/trust audit'}else{'PASS PARAMETER_HELP installed local/central APIs; absence audit required'}
