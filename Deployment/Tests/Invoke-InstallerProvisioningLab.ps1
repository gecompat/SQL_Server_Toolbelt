[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunsetPath,
      [Parameter(Mandatory)][ValidateRange(0,99)][int]$CaseIndex,
      [switch]$AuditOnly,[switch]$PreflightOnly,[switch]$CleanupOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanup=$false
$connections=[Collections.Generic.List[object]]::new();$ledger=$null;$failure=$null;$control=$null;$stage='PREFLIGHT'
# Vorhandene Journal-, Identitäts-, Konfigurations- und Trust-Cleanupguards wiederverwenden.
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/Release/Invoke-ApiQualificationLab.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'ONE_CALL_IMPORT_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$true))
if($nodes.Count -ne 1){throw 'ONE_CALL_IMPORT_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-StablePackageLab.ps1') @(
    'Assert-ReleasePin','Assert-ReleasePrivatePath','Invoke-ReleaseSql','Open-ReleaseConnection',
    'Invoke-ReleaseBatches','Save-ReleaseJournal','Assert-ReleaseInputs','Assert-ReleaseOwnIdentity')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1') @('Get-CsvTrust','Assert-CsvTrustCleanupScope') @{
    'Get-CsvTrust'='Get-HelpTrust';'Assert-CsvTrustCleanupScope'='Assert-HelpTrustCleanupScope';
    'Invoke-CsvOwnSql'='Invoke-ReleaseSql';'Invoke-CsvSql'='Invoke-ReleaseSql'}){. $block}
. (Join-Path $repo 'Tests/Release/ClrCaller.Environment.ps1')
function Get-ReleaseTimeout {
    $localRemaining=($(if($script:cleanup){1200000}else{900000}))-$script:clock.ElapsedMilliseconds
    # ConvertFrom-Json liefert je nach PowerShell-Version String oder DateTime.
    # Typkonversion erhält Kind/Offset statt kulturabhängig erneut zu parsen.
    $sharedEnd=[DateTimeOffset]$script:runset.deadline_utc
    if($script:cleanup -or $AuditOnly){$sharedEnd=$sharedEnd.AddMinutes(5)}
    $sharedRemaining=($sharedEnd-[DateTimeOffset]::UtcNow).TotalMilliseconds
    $remaining=[Math]::Min($localRemaining,$sharedRemaining)
    if($remaining -lt 1000){throw 'ONE_CALL_DEADLINE'}
    [int][Math]::Min(120,[Math]::Floor($remaining/1000))
}
try {
    $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
    $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
    if($runset.schema_version -cne 'toolbelt-installer-provisioning-runset/v1' -or $CaseIndex -ge $runset.cases.Count){throw 'ONE_CALL_RUNSET'}
    $case=$runset.cases[$CaseIndex]
    if($case.Platform -cnotin @('windows','linux') -or $case.Version -cnotin @('2019','2022','2025') -or
       $case.CL -ne @{'2019'=150;'2022'=160;'2025'=170}[[string]$case.Version]){throw 'ONE_CALL_SELECTOR'}
    if(@($case.modes).Count -notin @(1,2) -or @($case.modes | Where-Object {$_ -cnotin @('local','central')}).Count){throw 'ONE_CALL_MODES'}
    Assert-ReleaseInputs
    foreach($required in @($PSCommandPath,$runset.package,(Join-Path $repo 'Deployment/Install-Toolbelt.ps1'),(Join-Path $repo 'Deployment/Toolbelt.Provisioning.ps1'),
        (Join-Path $repo 'Tests/Release/Invoke-ApiQualificationLab.ps1'),(Join-Path $repo 'Tests/Release/Invoke-StablePackageLab.ps1'),
        (Join-Path $repo 'Tests/CI/run-csv-memory-lab.ps1'),(Join-Path $repo 'Tests/CI/run-lab-local.ps1'),
        (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1'),(Join-Path $repo 'Tests/Release/ClrCaller.Environment.ps1'))){
        if(@($runset.pins|Where-Object path -CEQ $required).Count -ne 1){throw 'ONE_CALL_REQUIRED_PIN'}
    }
    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/CI/run-lab-local.ps1') @(
        'Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){. $block}
    $lab=Resolve-LabContract -TestPurpose Functional
    if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contract_sha256){throw 'ONE_CALL_LAB_DRIFT'}
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if($targets.Count -ne 1){throw 'ONE_CALL_EXACT_TARGET'}
    $target=$targets[0]
    $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
    if($PreflightOnly){'PASS ONE_CALL schema-valid exact target and pinned inputs; no SQL';exit 0}
    $control=Open-ReleaseConnection 'master'
    # Reale Anmeldung prüfen; konkrete Runtimewerte bleiben im privaten Scope.
    Invoke-ReleaseSql $control 'SELECT @@VERSION; SELECT name,state_desc FROM sys.databases ORDER BY database_id;'
    if($CleanupOnly){
        $ledger=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json -AsHashtable
        if($ledger.state -cne 'CLEANUP_BLOCKED' -or $ledger.owner -cnotmatch '^[a-f0-9]{32}$'){throw 'PROVISIONING_CLEANUP_STATE'}
        $failure=[InvalidOperationException]::new('Original native failure retained; cleanup-only continuation.')
    } elseif($AuditOnly){
        $prior=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
        if($prior.state -cnotin @('COMPLETE','FAILED_CLEANED') -or $prior.owner -cnotmatch '^[a-f0-9]{32}$'){throw 'ONE_CALL_AUDIT_STATE'}
        foreach($entry in $prior.databases){
            if($entry.name -cne ('Toolbelt_Release_'+$prior.owner+'_'+$entry.suffix) -or $entry.state -cne 'DROPPED'){throw 'ONE_CALL_AUDIT_OWNER'}
            $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if($rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]){throw 'ONE_CALL_AUDIT_DATABASE'}
        }
        foreach($entry in $prior.trust){if(-not $entry.preexisting -and $null -ne (Get-HelpTrust $control ([Convert]::FromHexString($entry.hash)))){throw 'ONE_CALL_AUDIT_TRUST'}}
        Assert-ClrCallerConfiguration $control $prior.configuration
        Assert-ReleaseInputs
    } else {
        if(Test-Path -LiteralPath $journal){throw 'ONE_CALL_ALREADY_ATTEMPTED'}
        $actual=@(Invoke-ReleaseSql $control "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info) Platform,IS_SRVROLEMEMBER(N'sysadmin') Admin,(SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled') Clr;" -Rows)
        if($actual.Count -ne 1 -or $actual[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[[string]$case.Version] -or $actual[0].Platform -ine $case.Platform -or $actual[0].Admin -ne 1){throw 'ONE_CALL_TARGET_OR_CLR_NOT_READY'}
        $ledger=[ordered]@{configuration=@{before=@();changed=$false;state='NEW'};owner=[guid]::NewGuid().ToString('N');state='RUNNING';databases=@();trust=@();results=@();failure=$null}
        Save-ReleaseJournal
        # CLR-Vorzustand erfassen, nicht im Harness vorab aktivieren. Nur der
        # neue Produktweg darf den tatsächlichen Übergang 0 -> 1 ausführen.
        $ledger.configuration.before=@(Get-ClrCallerConfiguration $control)
        $ledger.configuration.state='PREEXISTING';Save-ReleaseJournal
        if(@(Get-ClrCallerPendingConfiguration $ledger.configuration.before).Count){throw 'PROVISIONING_PENDING_BASELINE'}
        $clr=@($ledger.configuration.before|Where-Object Name -ceq 'clr enabled')
        if($clr.Count -ne 1){throw 'PROVISIONING_CLR_BASELINE'}
        if($clr[0].Effective -eq 0){
            if((Get-ClrCallerUserAssemblyCount $control) -ne 0){throw 'PROVISIONING_EXISTING_CONSUMERS'}
            $ledger.configuration.changed=$true;$ledger.configuration.state='ACTIVATING';Save-ReleaseJournal
        }
        $zip=[IO.Compression.ZipFile]::OpenRead($runset.package)
        try {
            $payload=@{}
            foreach($entry in $zip.Entries){
                if($payload.ContainsKey($entry.FullName) -or $entry.Length -gt 67108864){throw 'ONE_CALL_PACKAGE_ENTRY'}
                $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8)
                try{$payload[$entry.FullName]=$reader.ReadToEnd()}finally{$reader.Dispose()}
            }
        }finally{$zip.Dispose()}
        $metadata=$payload['PACKAGE.json']|ConvertFrom-Json
        if($metadata.scope -cne 'CURRENT_COMBINED_FRESH_INSTALL' -or $metadata.publication_authorized){throw 'ONE_CALL_PACKAGE_SCOPE'}
        $profilePlatform=if($case.Platform -ceq 'windows'){'Windows'}else{'Portable'}
        $trustNames=@($metadata.binary_sha512.PSObject.Properties|Where-Object {$profilePlatform -ceq 'Windows' -or $_.Name -notin @('Toolbelt.Filesystem.Windows.dll','Toolbelt.Tsql.ScriptParser.dll','Toolbelt.Tsql.SsisDebug.dll','Microsoft.SqlServer.TransactSql.ScriptDom.dll')})
        foreach($property in $trustNames){
            $hash=[Convert]::FromHexString($property.Value);$before=Get-HelpTrust $control $hash
            $entry=[ordered]@{hash=$property.Value;preexisting=($null -ne $before);state='PREEXISTING';fingerprint=$null;description=$null}
            $ledger.trust+=@($entry);Save-ReleaseJournal
            if($before){continue}
            Assert-HelpTrustCleanupScope $control $hash
            $entry.state='ADDING';$entry.description='Toolbelt OneCall Test '+$ledger.owner+' '+$property.Name;Save-ReleaseJournal
            Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash,@D nvarchar(4000)=@Description; EXEC sys.sp_add_trusted_assembly @hash=@H,@description=@D;' @{'@Hash'=$hash;'@Description'=$entry.description}
            $after=Get-HelpTrust $control $hash
            if($null -eq $after -or $after.description -cne $entry.description){throw 'ONE_CALL_TRUST_IDENTITY'}
            $entry.fingerprint=$after.Fingerprint;$entry.state='ADDED';Save-ReleaseJournal
        }
        foreach($mode in $case.modes){
            $stage='CREATE_'+$mode;$suffix=if($mode -ceq 'local'){'l'}else{'c'}
            $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
            $entry=[ordered]@{name=$name;suffix=$suffix;id=$null;created=$null;state='CREATING'}
            $ledger.databases+=@($entry);Save-ReleaseJournal
            Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12;"
            $stage='INSTALL_'+$mode
            # Das Testsetup markiert seine Trusteinträge eindeutig als eigene;
            # der Produktlauf prüft/übernimmt diesen vorhandenen exakten Trust.
            # Die originale Neueintragung behält ihren separaten nativen Nachweis.
            $credential=[Management.Automation.PSCredential]::new([string]$target.username,
                (ConvertTo-SecureString ([string]$target.password) -AsPlainText -Force))
            try {
                $installArgs=@{DeploymentMode=$mode;ServerInstance=('tcp:{0},{1}' -f $target.host,$target.port);Database=$name
                    Credential=$credential;PackageZip=$runset.package;TrustServerCertificate=[bool]$target.trustServerCertificate;CommandTimeoutSeconds=600;Verbose=$true;CreateDatabase=$true;EnableClr=$true}
                $result=& (Join-Path $repo 'Deployment/Install-Toolbelt.ps1') @installArgs
                if($result.Status -cne 'INSTALLED' -or $result.Profile -cne ($profilePlatform+'-'+$mode)){throw 'ONE_CALL_COMPLETION'}
            } finally {$credential=$null}
            $id=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
            if($id.Count -ne 1){throw 'ONE_CALL_DATABASE_IDENTITY'}
            $entry.id=$id[0].Id;$entry.created=$id[0].Created;$entry.state='CREATED';Save-ReleaseJournal
            $db=Open-ReleaseConnection $name
            Invoke-ReleaseSql $db "DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}
            $preparation=Get-Content -LiteralPath $result.PreparationJournal -Raw|ConvertFrom-Json
            if($preparation.state -cne 'PREPARATION_COMPLETE' -or !$preparation.outcome.DatabaseCreated){throw 'PROVISIONING_JOURNAL_RECEIPT'}
            if($clr[0].Effective -eq 0 -and $mode -ceq $case.modes[0] -and !$preparation.outcome.ClrEnabled){throw 'PROVISIONING_NATIVE_CLR_TRANSITION'}
            if($ledger.configuration.changed){$ledger.configuration.state='OWNED';Save-ReleaseJournal}
            $stage='INVENTORY_'+$mode
            $profile=@($metadata.profiles|Where-Object name -ceq ($profilePlatform+'-'+$mode))
            if($profile.Count -ne 1){throw 'ONE_CALL_PROFILE'}
            foreach($module in $profile[0].modules){
                $property=if($module -cin @('toolbelt.filesystem.windows','toolbelt.tsql.ssis-debug')){'Version'}else{'DeploymentMode'}
                $expected=if($property -ceq 'Version'){'1.0.0'}else{$mode}
                $rows=@(Invoke-ReleaseSql $db 'SELECT CONVERT(nvarchar(128),value) Value FROM sys.extended_properties WHERE class=0 AND name=@Name;' @{'@Name'=('Toolbelt.Module.'+$module+'.'+$property)} -Rows)
                if($rows.Count -ne 1 -or $rows[0].Value -cne $expected){throw ('ONE_CALL_MODULE_INVENTORY '+$module)}
            }
                $ledger.results+=@(@{mode=$mode;platform=$profilePlatform;created=$preparation.outcome.DatabaseCreated;clrEnabled=$preparation.outcome.ClrEnabled;result=@{status=$result.Status;modules=$result.Modules;profile=$result.Profile}});Save-ReleaseJournal
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
            foreach($entry in $ledger.databases){
                if($entry.state -ceq 'DROPPED'){continue}
                if(!$entry.created){
                    $rows=@(Invoke-ReleaseSql $control 'SELECT d.database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),d.create_date),2) Created,CONVERT(nvarchar(36),r.database_guid) Guid FROM sys.databases d JOIN sys.database_recovery_status r ON r.database_id=d.database_id WHERE d.name=@Name;' @{'@Name'=$entry.name} -Rows)
                    if(!$rows.Count){$entry.state='DROPPED';Save-ReleaseJournal;continue}
                    # Nur ein vom Produkt selbst bestätigter CREATE-GUID erlaubt
                    # Ownership-Rekonstruktion nach einem späteren Testfehler.
                    $journalRoot=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SQL_Server_Toolbelt/InstallJournals'
                    $matches=@(Get-ChildItem -LiteralPath $journalRoot -Filter preparation.json -Recurse -File|ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw|ConvertFrom-Json}|Where-Object {$_.database -ceq $entry.name -and $_.server -ceq ('tcp:{0},{1}' -f $target.host,$target.port) -and $_.outcome.CreatedGuid -ceq $rows[0].Guid})
                    if($rows.Count -ne 1 -or $matches.Count -ne 1){throw 'PROVISIONING_CREATED_OWNERSHIP_UNKNOWN'}
                    $entry.id=$rows[0].Id;$entry.created=$rows[0].Created;$entry.state='CREATED';Save-ReleaseJournal
                    $owned=Open-ReleaseConnection $entry.name
                    try{Invoke-ReleaseSql $owned "IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner') THROW 52096,N'Unexpected ownership marker.',1; DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@O;" @{'@Owner'=$ledger.owner}}finally{$owned.Dispose()}
                }
                Assert-ReleaseOwnIdentity $control $entry;$entry.state='DROPPED';Save-ReleaseJournal
            }
            foreach($entry in $ledger.trust){
                if($entry.preexisting){continue}
                $hash=[Convert]::FromHexString($entry.hash);$actual=Get-HelpTrust $control $hash
                if($entry.state -ceq 'ADDING' -and $null -eq $actual){$entry.state='NOT_ADDED';Save-ReleaseJournal;continue}
                if($null -eq $actual -or $entry.state -cne 'ADDED' -or $actual.description -cne $entry.description -or $actual.Fingerprint -cne $entry.fingerprint){throw 'ONE_CALL_TRUST_CLEANUP_DRIFT'}
                Assert-HelpTrustCleanupScope $control $hash
                Invoke-ReleaseSql $control 'DECLARE @H varbinary(64)=@Hash; EXEC sys.sp_drop_trusted_assembly @hash=@H;' @{'@Hash'=$hash}
                if($null -ne (Get-HelpTrust $control $hash)){throw 'ONE_CALL_TRUST_REMAINS'}
                $entry.state='REMOVED';Save-ReleaseJournal
            }
            Restore-ClrCallerConfiguration $control
            $ledger.state=if($failure){'FAILED_CLEANED'}else{'COMPLETE'};Save-ReleaseJournal
        } catch {$ledger.state='CLEANUP_BLOCKED';$ledger['privateCleanupDiagnostic']=$_.Exception.Message;Save-ReleaseJournal;$failure=$_.Exception}
        finally {if($control){$control.Dispose()}}
    }
}
if($failure){'FAIL ONE_CALL; inspect private journal; reconcile before a new attempt';exit 1}
if($AuditOnly){'PASS ONE_CALL_INSTALL input/database/trust/configuration audit'}else{'PASS ONE_CALL_INSTALL selected profiles through actual ODBC client; independent audit required'}
