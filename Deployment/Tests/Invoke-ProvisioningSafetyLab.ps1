# Separater nativer Fehlergrenzentest, keine Modul-/Installationswiederholung.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,[switch]$AuditOnly)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$control=$null;$ledger=$null;$failure=$null
$connections=[Collections.Generic.List[object]]::new()
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/Release/Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$null)
$node=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($node.Count -ne 1){throw 'SAFETY_IMPORT'}
. ([scriptblock]::Create($node[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-StablePackageLab.ps1') @('Assert-ReleasePin','Assert-ReleasePrivatePath','Invoke-ReleaseSql','Open-ReleaseConnection','Assert-ReleaseInputs')){. $block}
$RunsetPath=Assert-ReleasePrivatePath $RunsetPath
$runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
if($runset.schema_version -cne 'toolbelt-installer-provisioning-runset/v1' -or $runset.cases.Count -lt 3){throw 'SAFETY_RUNSET'}
$case=$runset.cases[2]
$journal=Assert-ReleasePrivatePath (Join-Path (Split-Path $RunsetPath) 'safety.private.json')
function Get-ReleaseTimeout {
    $left=([DateTimeOffset]$runset.deadline_utc-[DateTimeOffset]::UtcNow).TotalSeconds
    if($left -lt 1){throw 'SAFETY_DEADLINE'}
    [int][Math]::Min(60,[Math]::Floor($left))
}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
. (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
function Snapshot {
    @((Invoke-ReleaseSql $control 'SELECT configuration_id Id,CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations ORDER BY configuration_id;' -Rows))
}
function TrustSnapshot {
    @((Invoke-ReleaseSql $control 'SELECT CONVERT(varchar(128),hash,2) Hash,description Description,CONVERT(nvarchar(50),create_date,126) Created FROM sys.trusted_assemblies ORDER BY hash;' -Rows))|ConvertTo-Json -Depth 4 -Compress
}
try{
    Assert-ReleaseInputs
    foreach($required in @($PSCommandPath,(Join-Path $repo 'Deployment/Install-Toolbelt.ps1'),(Join-Path $repo 'Deployment/Toolbelt.Provisioning.ps1'))){
        if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'SAFETY_REQUIRED_PIN'}
    }
    $lab=Resolve-LabContract -TestPurpose Functional
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'SAFETY_CONTRACT_DRIFT'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if($targets.Count -ne 1){throw 'SAFETY_EXACT_TARGET'}
    $target=$targets[0];$control=Open-ReleaseConnection 'master'
    $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin;" -Rows)
    if($actual.Count -ne 1 -or $actual[0].Major -ne 17 -or $actual[0].Platform -cne 'Windows' -or $actual[0].Admin -ne 1){throw 'SAFETY_TARGET_IDENTITY'}
    if($AuditOnly){
        $prior=Get-Content $journal -Raw|ConvertFrom-Json
        if($prior.state -cne 'COMPLETE' -or (($prior.before|ConvertTo-Json -Depth 4 -Compress) -cne ((Snapshot)|ConvertTo-Json -Depth 4 -Compress)) -or $prior.trust -cne (TrustSnapshot)){throw 'SAFETY_AUDIT_DRIFT'}
        $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$prior.database} -Rows)
        if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'SAFETY_AUDIT_DATABASE'}
    }else{
        if(Test-Path -LiteralPath $journal){throw 'SAFETY_ALREADY_ATTEMPTED'}
        $ledger=@{state='RUNNING';before=@(Snapshot);trust=(TrustSnapshot);database=('Toolbelt_Release_'+[guid]::NewGuid().ToString('N')+'_u');pendingOwned=$false;checks=0}
        $ledger|ConvertTo-Json -Depth 8|Set-Content $journal -Encoding utf8
        $option=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations WHERE name=N'user options';" -Rows)
        if($option.Count -ne 1 -or $option[0].Configured -ne $option[0].Effective){throw 'SAFETY_OPTION_BASELINE'}
        $ledger['optionBefore']=[int]$option[0].Configured
        $credential=[Management.Automation.PSCredential]::new([string]$target.username,(ConvertTo-SecureString ([string]$target.password) -AsPlainText -Force))
        $argsBase=@{ServerInstance=('tcp:{0},{1}' -f $target.host,$target.port);Database=$ledger.database;DeploymentMode='local';Credential=$credential;PackageZip=$runset.package;TrustServerCertificate=[bool]$target.trustServerCertificate}
        $r=& (Join-Path $repo 'Deployment/Install-Toolbelt.ps1') @argsBase -CreateDatabase -EnableClr -PreflightOnly
        if($r.Status -cne 'PREPARATION_PREFLIGHT_OK' -or $r.Mutations -or $r.DatabaseExists){throw 'SAFETY_PREFLIGHT_MUTATED'}
        $ledger.checks++
        $missingRejected=$false
        try{& (Join-Path $repo 'Deployment/Install-Toolbelt.ps1') @argsBase -EnableClr|Out-Null}catch{$missingRejected=$_.Exception.Message.Contains('[TBX_DATABASE_MISSING]')}
        if(!$missingRejected){throw 'SAFETY_MISSING_DATABASE_NOT_REJECTED'}
        $ledger.checks++
        # Nur einen konfigurierten, noch nicht wirksamen synthetischen Wert
        # vormerken. Produkt darf ihn weder aktivieren noch zurückschreiben.
        $ledger.pendingOwned=$true;$ledger|ConvertTo-Json -Depth 8|Set-Content $journal -Encoding utf8
        $staged=$ledger.optionBefore -bxor 512
        Invoke-ReleaseSql $control 'DECLARE @V int=@Value; EXEC sys.sp_configure N''user options'',@V;' @{'@Value'=$staged}
        $rejected=$false
        try{& (Join-Path $repo 'Deployment/Install-Toolbelt.ps1') @argsBase -CreateDatabase -EnableClr|Out-Null}catch{$rejected=$_.Exception.Message.Contains('[TBX_PENDING_CONFIGURATION]')}
        if(!$rejected){throw 'SAFETY_PENDING_NOT_REJECTED'}
        $now=@(Snapshot)
        # Vergleich über den tatsächlichen Katalognamen, keine Annahme über Ids.
        $id=@(Invoke-ReleaseSql $control "SELECT configuration_id Id FROM sys.configurations WHERE name=N'user options';" -Rows)[0].Id
        foreach($row in $now){$prior=@($ledger.before|Where-Object Id -eq $row.Id)[0];if($row.Effective -ne $prior.Effective -or $row.Configured -ne $(if($row.Id -eq $id){$staged}else{$prior.Configured})){throw 'SAFETY_FOREIGN_PENDING_DRIFT'}}
        $ledger.checks++
    }
}catch{
    $failure=$_.Exception
    if($ledger){$ledger['failure']=$failure.Message}
    else{@{state='FAILED_BEFORE_MUTATION';errorId=$_.FullyQualifiedErrorId;type=$failure.GetType().FullName;position=$_.ScriptStackTrace}|ConvertTo-Json|Set-Content (Join-Path (Split-Path $RunsetPath) 'safety-preflight.private.json') -Encoding utf8}
}
finally{
    if($ledger -and $ledger.pendingOwned -and $control){
        try{
            $rows=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,value) Configured,CONVERT(int,value_in_use) Effective FROM sys.configurations WHERE name=N'user options';" -Rows)
            if($rows.Count -ne 1 -or $rows[0].Configured -ne ($ledger.optionBefore -bxor 512) -or $rows[0].Effective -ne $ledger.optionBefore){throw 'SAFETY_PENDING_OWNERSHIP_DRIFT'}
            Invoke-ReleaseSql $control 'DECLARE @V int=@Value; EXEC sys.sp_configure N''user options'',@V;' @{'@Value'=$ledger.optionBefore}
            $ledger.pendingOwned=$false
            if(($ledger.before|ConvertTo-Json -Depth 4 -Compress) -cne ((Snapshot)|ConvertTo-Json -Depth 4 -Compress) -or $ledger.trust -cne (TrustSnapshot)){throw 'SAFETY_FINAL_DRIFT'}
            $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$ledger.database} -Rows)
            if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'SAFETY_UNEXPECTED_DATABASE'}
        }catch{$failure=$_.Exception;$ledger['cleanupFailure']=$failure.Message}
    }
    if($ledger){$ledger.state=$(if($failure){'FAILED'}else{'COMPLETE'});$ledger|ConvertTo-Json -Depth 8|Set-Content $journal -Encoding utf8}
    if($control){$control.Dispose()}
    $credential=$null
}
if($failure){'FAIL PROVISIONING_SAFETY; private diagnostic retained';exit 1}
if($AuditOnly){'PASS PROVISIONING_SAFETY fresh independent full configuration/trust/database audit'}else{'PASS PROVISIONING_SAFETY read-only opt-in and pending configuration rejection'}
