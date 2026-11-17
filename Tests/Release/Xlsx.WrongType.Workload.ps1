# Einzige vorhandene destruktive Slotfixture; danach ausschließlich eigene DB entfernen.
. (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')

function Assert-XlsxWrongTypeInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'wrongtype-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_WRONGTYPE_SCOPE'}
    $paths=@($Runset.wrongtype.install.local,$Runset.wrongtype.install.central,$Runset.wrongtype.uninstall,
        $Runset.workbooks[0].path,(Join-Path $PSScriptRoot 'Xlsx.WrongType.Workload.ps1'),
        (Join-Path $PSScriptRoot 'Prepare-XlsxWrongTypeRunset.ps1'),
        (Join-Path $PSScriptRoot 'Test-XlsxWrongTypeAdmission.ps1'),
        (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Deploy.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path).Hash -cne $pin[0].sha256){throw 'XLSX_WRONGTYPE_REQUIRED_PIN'}
    }
}

function Get-XlsxWrongTypeWitness($Connection){
    $rows=@(Invoke-ReleaseSql $Connection @'
SELECT o.object_id Id,o.type Kind,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) DefinitionHash,
 (SELECT COUNT(*) FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id
  AND p.name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion')) ModuleMarkers,
 toolbelt_file.USP_ListXlsxWorksheets() SyntheticValue
FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id
WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name=N'USP_ListXlsxWorksheets';
'@ -Rows)
    if($rows.Count -ne 1 -or $rows[0].Id -le 0 -or $rows[0].Kind -cne 'FN' -or
       $rows[0].DefinitionHash -cnotmatch '\A[A-F0-9]{64}\z' -or
       $rows[0].ModuleMarkers -ne 0 -or $rows[0].SyntheticValue -ne 73){throw 'XLSX_WRONGTYPE_FOREIGN_FUNCTION_WITNESS'}
    return $rows[0].Id.ToString()+'|'+$rows[0].DefinitionHash
}

function Invoke-XlsxWrongType($Connection,[string]$Mode){
    $entry=@{mode=$Mode;fixture='WrongType';deployRejections=0;uninstallRejections=0;foreignWitnesses=0;status='RUNNING'}
    $script:ledger.wrongTypes+=@($entry);Save-ReleaseJournal
    $script:stage='WRONGTYPE_SETUP_'+$Mode
    $fixture=Read-XlsxSql (Join-Path $repo 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql') @{FaultCase='WrongType'}
    $fixture=[regex]::Replace($fixture,'(?im)^\s*GO\s*$','')
    $oracle=@(Invoke-ReleaseSql $Connection $fixture -Rows)
    if($oracle.Count -ne 1 -or $oracle[0].ExpectedError -ne 51534 -or
       $oracle[0].RestoreSql -isnot [string] -or $oracle[0].RestoreSql.Length -ne 0){throw 'XLSX_WRONGTYPE_FIXTURE_ORACLE'}
    $before=Get-XlsxSnapshot $Connection
    $witness=Get-XlsxWrongTypeWitness $Connection;$entry.foreignWitnesses=1;Save-ReleaseJournal
    foreach($action in @('Deploy','Uninstall')){
        $script:stage='WRONGTYPE_'+$Mode+'_'+$action
        $path=if($action -ceq 'Deploy'){$script:runset.wrongtype.install.$Mode}else{$script:runset.wrongtype.uninstall}
        Assert-XlsxRejected $Connection ([IO.File]::ReadAllText($path)) 51534
        if((Get-XlsxSnapshot $Connection) -cne $before -or (Get-XlsxWrongTypeWitness $Connection) -cne $witness){
            throw 'XLSX_WRONGTYPE_REJECTION_MUTATED'
        }
        if($action -ceq 'Deploy'){$entry.deployRejections=1}else{$entry.uninstallRejections=1}
        $entry.foreignWitnesses++;Save-ReleaseJournal
    }
    Assert-XlsxFullSizeNeutral $Connection
    $entry.status='PASS';Save-ReleaseJournal
}

function Assert-XlsxWrongTypeJournal($Prior){
    if(($Prior.completedModes -join '|') -cne 'local|central' -or ($Prior.databases.suffix -join '|') -cne 'l|c' -or
       ($Prior.wrongTypes.mode -join '|') -cne 'local|central' -or
       @($Prior.wrongTypes|Where-Object {$_.fixture -cne 'WrongType' -or $_.status -cne 'PASS' -or
           $_.deployRejections -ne 1 -or $_.uninstallRejections -ne 1 -or $_.foreignWitnesses -ne 3}).Count -or
       ($Prior.lifecycle.action -join '|') -cne 'InstallAndRepeat|InstallAndRepeat'){
        throw 'XLSX_WRONGTYPE_AUDIT_SCOPE'
    }
}

# Genau einen bereits vollständigen ersten Fall nach fehlgeschlagenem Audit
# lesend nachprüfen. Historische Dispatches/Startzeit dürfen nicht ersetzt werden.
function Assert-XlsxWrongTypeAuditRecovery($Budget,[string]$RunsetPath){
    if($Budget.audit_recoveries.Count -ne 1){throw 'XLSX_WRONGTYPE_RECOVERY_COUNT'}
    $r=$Budget.audit_recoveries[0]
    $runtime=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../.runtime'))+[IO.Path]::DirectorySeparatorChar
    if(-not [IO.Path]::GetFullPath($r.original_budget_path).StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){throw 'XLSX_WRONGTYPE_RECOVERY_PATH'}
    $old=Get-Content -LiteralPath $r.original_budget_path -Raw|ConvertFrom-Json
    if((Get-FileHash -LiteralPath $r.original_budget_path).Hash -cne $r.original_budget_sha256 -or
       $old.dispatches.Count -ne 2 -or $old.dispatches[0].phase -cne 'RUN' -or $old.dispatches[0].index -ne 0 -or
       $old.dispatches[0].state -cne 'COMPLETE' -or $old.dispatches[0].exit_code -ne 0 -or -not $old.dispatches[0].stderr_empty -or
       $old.dispatches[1].phase -cne 'AUDIT' -or $old.dispatches[1].state -cne 'AUDIT_FAILED' -or
       $old.native_dispatch_max -ne 28 -or $old.database_max -ne 28 -or $old.native_ceiling_minutes -ne 60 -or
       [string]$Budget.native_started -cne [string]$old.native_started -or
       ($Budget.dispatches[0..1]|ConvertTo-Json -Depth 12 -Compress) -cne ($old.dispatches|ConvertTo-Json -Depth 12 -Compress)){
        throw 'XLSX_WRONGTYPE_RECOVERY_HISTORY_CHANGED'
    }
    $audit=@($Budget.dispatches|Where-Object id -CEQ $r.recovery_id)
    if($audit.Count -ne 1 -or $audit[0].phase -cne 'AUDIT_RECOVERY' -or $audit[0].state -cne 'AUDIT_PASS' -or
       $audit[0].index -ne 0 -or $audit[0].exit_code -ne 0 -or -not $audit[0].stderr_empty -or
       -not $audit[0].capture_complete -or $audit[0].runset_sha256 -cne (Get-FileHash -LiteralPath $RunsetPath).Hash){
        throw 'XLSX_WRONGTYPE_RECOVERY_NOT_PASS'
    }
    $copy=Join-Path (Split-Path -Parent $RunsetPath) 'case-0.json'
    foreach($path in @($r.original_budget_path,$r.original_runset_path,$r.original_journal_path,$RunsetPath,$copy,
                       $audit[0].stdout_path,$audit[0].stderr_path)){
        if(-not [IO.Path]::GetFullPath($path).StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase) -or
           ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){
            throw 'XLSX_WRONGTYPE_RECOVERY_PATH'
        }
    }
    if((Get-FileHash -LiteralPath $r.original_runset_path).Hash -cne $old.dispatches[0].runset_sha256 -or
       (Get-FileHash -LiteralPath $r.original_journal_path).Hash -cne $audit[0].final_journal_sha256 -or
       (Get-FileHash -LiteralPath $copy).Hash -cne $audit[0].final_journal_sha256 -or
       (Get-FileHash -LiteralPath $audit[0].stdout_path).Hash -cne $audit[0].stdout_sha256 -or
       [IO.File]::ReadAllText($audit[0].stdout_path).Trim() -cne 'PASS XLSX_FULL_SIZE independent database/trust/configuration audit' -or
       (Get-Item -LiteralPath $audit[0].stderr_path).Length -ne 0){throw 'XLSX_WRONGTYPE_RECOVERY_BINDING'}
    $before=Get-Content -LiteralPath $r.original_runset_path -Raw|ConvertFrom-Json
    $after=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
    if($before.qualification_scope -cne 'wrongtype-rest' -or $after.qualification_scope -cne 'wrongtype-rest' -or
       $before.contract_sha256 -cne $after.contract_sha256 -or
       ($before.cases|ConvertTo-Json -Depth 8 -Compress) -cne ($after.cases|ConvertTo-Json -Depth 8 -Compress)){
        throw 'XLSX_WRONGTYPE_RECOVERY_TARGET_CHANGED'
    }
    foreach($mode in @('local','central')){foreach($action in @('Install','Repeat','Uninstall')){
        if((Get-FileHash -LiteralPath $before.exports.$mode.$action).Hash -cne (Get-FileHash -LiteralPath $after.exports.$mode.$action).Hash){
            throw 'XLSX_WRONGTYPE_RECOVERY_PACKAGE_CHANGED'
        }
    }}
    $prior=Get-Content -LiteralPath $copy -Raw|ConvertFrom-Json
    Assert-XlsxWrongTypeJournal $prior
    return $old.dispatches[1].id
}
