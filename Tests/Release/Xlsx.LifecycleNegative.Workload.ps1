# Originale negative Lifecycle-Orakel, aktuelle begrenzte SQL-/Ownership-Helfer.
# Nur Definitionen importieren: kein alter Top-level-Lab-/Legacy-Lauf.
$lifecycleSource=Join-Path $PSScriptRoot '../CI/run-xlsx-types-lab.ps1'
$lifecycleErrors=$null
$lifecycleAst=[Management.Automation.Language.Parser]::ParseFile($lifecycleSource,[ref]$null,[ref]$lifecycleErrors)
if($lifecycleErrors.Count){throw 'XLSX_LIFECYCLE_SOURCE_PARSE'}
foreach($lifecycleName in @('Get-XlsxCompleteSnapshotSql','Get-XlsxSnapshot','Get-XlsxFailure',
 'Invoke-XlsxBatches','Assert-XlsxRejected','Assert-XlsxLockPrepared','Assert-XlsxRollbackPrepared',
 'Assert-XlsxVisibilityPrepared','Read-XlsxSql')){
    $lifecycleNodes=@($lifecycleAst.FindAll({param($n)
        $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $lifecycleName
    },$true))
    if($lifecycleName -ceq 'Get-XlsxSnapshot'){
        $lifecycleNodes=@($lifecycleNodes|Where-Object {$_.Extent.Text.Contains('Get-XlsxCompleteSnapshotSql')})
    }
    if($lifecycleNodes.Count -ne 1){throw 'XLSX_LIFECYCLE_ORIGINAL_HELPER_AMBIGUOUS'}
    . ([scriptblock]::Create($lifecycleNodes[0].Extent.Text))
}

function Invoke-XlsxSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows){
    Invoke-ReleaseSql $Connection $Sql $Parameters -Rows:$Rows
}
function Open-XlsxConnection($Target,[string]$Database){
    # Zweite Verbindung ausschließlich über denselben ausgewählten Runset-Client.
    if($Database -cnotin @($script:ledger.databases|Where-Object state -CEQ 'OWNED'|ForEach-Object name)){
        throw 'XLSX_LIFECYCLE_HOLDER_NOT_OWNED'
    }
    Open-ReleaseConnection $Database
}

function Assert-XlsxLifecycleNegativeSeams([string]$Deploy,[string]$Uninstall){
    foreach($pair in @(@{text=$Deploy;needle=' DROP FUNCTION IF EXISTS toolbelt_file.TVF_InterpretXlsxCell;'},
                        @{text=$Uninstall;needle='  DROP FUNCTION toolbelt_file.TVF_InternalInterpretXlsxCell;'})){
        if(([regex]::Matches($pair.text,[regex]::Escape($pair.needle))).Count -ne 1){throw 'XLSX_LIFECYCLE_POSTDROP_SEAM'}
    }
    foreach($text in @($Deploy,$Uninstall)){
        if($text -match '\$\(' -or $text -match '(?m)^\s*:'){throw 'XLSX_LIFECYCLE_UNRESOLVED_TEMPLATE'}
        if(([regex]::Matches($text,'(?m)^ COMMIT TRANSACTION;\r?$')).Count -ne 1){throw 'XLSX_LIFECYCLE_COMMIT_SEAM'}
        foreach($predicate in @("HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')",
          "HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT')")){
            if(([regex]::Matches($text,[regex]::Escape($predicate))).Count -ne 1){throw 'XLSX_LIFECYCLE_VISIBILITY_SEAM'}
        }
    }
}

function Assert-XlsxLifecycleNegativeInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'lifecycle-negative-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_LIFECYCLE_SCOPE'}
    $paths=@($Runset.lifecycle_negative.install.local,$Runset.lifecycle_negative.install.central,
        $Runset.lifecycle_negative.uninstall,$Runset.workbooks[0].path,
        (Join-Path $Repository 'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/Release/Prepare-XlsxLifecycleNegativeRunset.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Deploy.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){
            throw 'XLSX_LIFECYCLE_REQUIRED_PIN'
        }
    }
    foreach($mode in @('local','central')){
        Assert-XlsxLifecycleNegativeSeams ([IO.File]::ReadAllText($Runset.lifecycle_negative.install.$mode)) `
            ([IO.File]::ReadAllText($Runset.lifecycle_negative.uninstall))
    }
}

function Invoke-XlsxLifecycleNegative($Connection,[string]$Mode){
    $deploy=[IO.File]::ReadAllText($script:runset.lifecycle_negative.install.$Mode)
    $uninstall=[IO.File]::ReadAllText($script:runset.lifecycle_negative.uninstall)
    $before=Get-XlsxSnapshot $Connection
    $entry=@{mode=$Mode;rollback=0;locks=0;visibility=0;status='RUNNING'}
    $script:ledger.lifecycleNegatives+=@($entry);Save-ReleaseJournal
    $script:stage='LIFECYCLE_ROLLBACK_'+$Mode
    Assert-XlsxRollbackPrepared $Connection $deploy $uninstall
    $entry.rollback=4;Save-ReleaseJournal
    $script:stage='LIFECYCLE_LOCK_'+$Mode
    Assert-XlsxLockPrepared $script:case $Connection.Database $Connection $deploy $uninstall
    $entry.locks=2;Save-ReleaseJournal
    $script:stage='LIFECYCLE_VISIBILITY_'+$Mode
    Assert-XlsxVisibilityPrepared $Connection $deploy $uninstall
    $entry.visibility=16;Save-ReleaseJournal
    if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_LIFECYCLE_FINAL_SNAPSHOT_DRIFT'}
    Assert-XlsxFullSizeNeutral $Connection
    $entry.status='PASS';Save-ReleaseJournal
}
