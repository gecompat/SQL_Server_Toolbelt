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
