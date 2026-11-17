# Originale vier Zukunftsslots, aktuelle begrenzte SQL-/Snapshot-/Ownershipschicht.
. (Join-Path $PSScriptRoot 'Xlsx.Genuine10.Workload.ps1')
. (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')
$script:module=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Modules/toolbelt.file.xlsx-memory'))
$script:typeFutureEntry=$null;$script:typeFutureMode=$null
foreach($futureName in @('Get-XlsxForeignSlotPrepared','Invoke-XlsxHistoricalFuturePrepared')){
    $futureNodes=@($lifecycleAst.FindAll({param($n)
        $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $futureName
    },$true))
    if($futureNodes.Count -ne 1){throw 'XLSX_FUTURE_ORIGINAL_HELPER_AMBIGUOUS'}
    . ([scriptblock]::Create($futureNodes[0].Extent.Text))
}

function Open-XlsxConnection($Target,[string]$Database){
    if(-not $script:typeFutureEntry -or $script:typeFutureEntry.status -cne 'RUNNING' -or
       $Database -cnotin @($script:ledger.databases|Where-Object state -CEQ 'OWNED'|ForEach-Object name)){
        throw 'XLSX_FUTURE_RESTORE_NOT_OWNED'
    }
    $connection=Open-ReleaseConnection $Database
    try{
        Assert-XlsxGenuine10Baseline $connection $script:typeFutureMode
        $ordinal=[int]$script:typeFutureEntry.legacyWitnesses-1
        if($ordinal -lt 0 -or $ordinal -ge 4){throw 'XLSX_FUTURE_RESTORE_COUNT'}
        $script:typeFutureEntry.completedFaults+=@(@('FuturePublic','ImitatedFuturePublic','FutureInternal','ImitatedFutureInternal')[$ordinal])
        $script:typeFutureEntry.legacyWitnesses++;Save-ReleaseJournal
        return $connection
    }catch{$connection.Dispose();throw}
}

function Assert-XlsxTypeFutureCollisionInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'type-future-collision-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_FUTURE_SCOPE'}
    $paths=@($Runset.type_future_collision.install.local,$Runset.type_future_collision.install.central,
        $Runset.type_future_collision.uninstall,$Runset.workbooks[0].path,
        (Join-Path $Repository 'Tests/Release/Xlsx.TypeFutureCollision.Workload.ps1'),
        (Join-Path $Repository 'Tests/Release/Prepare-XlsxTypeFutureCollisionRunset.ps1'),
        (Join-Path $Repository 'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/Release/Invoke-XlsxFullSizeLab.ps1'),
        (Join-Path $Repository 'Tests/Release/Invoke-XlsxFullSizeMatrix.ps1'),
        (Join-Path $Repository 'Tests/Release/Xlsx.CellApi.Workload.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){
            throw 'XLSX_FUTURE_REQUIRED_PIN'
        }
    }
    Assert-XlsxGenuine10Inputs $Runset $Repository
    foreach($mode in @('local','central')){
        Assert-XlsxLifecycleNegativeSeams ([IO.File]::ReadAllText($Runset.type_future_collision.install.$mode)) `
            ([IO.File]::ReadAllText($Runset.type_future_collision.uninstall))
    }
}

function Invoke-XlsxTypeFutureCollision($Connection,[string]$Mode){
    $old=@($script:ledger.genuine|Where-Object {$_.mode -ceq $Mode -and $_.status -ceq 'PASS_GENUINE_1_0'})
    if($old.Count -ne 1){throw 'XLSX_FUTURE_GENUINE_SETUP_REQUIRED'}
    $entry=@{mode=$Mode;legacyWitnesses=1;completedFaults=@();status='RUNNING'}
    $script:ledger.typeFutureCollisions+=@($entry);$script:typeFutureEntry=$entry;$script:typeFutureMode=$Mode;Save-ReleaseJournal
    try{
        $variables=@{DeploymentMode=$Mode;ConfirmNoExternalConsumers=1}
        $next=Invoke-XlsxHistoricalFuturePrepared $script:case $Connection.Database $Connection $variables `
            ([IO.File]::ReadAllText($script:runset.type_future_collision.install.$Mode)) `
            ([IO.File]::ReadAllText($script:runset.type_future_collision.uninstall)) `
            ([IO.File]::ReadAllText($script:runset.legacy.install.$Mode))
        if($next -isnot [Data.SqlClient.SqlConnection] -or $entry.legacyWitnesses -ne 5 -or
           ($entry.completedFaults -join '|') -cne 'FuturePublic|ImitatedFuturePublic|FutureInternal|ImitatedFutureInternal'){
            throw 'XLSX_FUTURE_ORIGINAL_CASE_SET'
        }
        Assert-XlsxFullSizeNeutral $next
        $entry.status='PASS';Save-ReleaseJournal
        return $next
    }catch{$entry.status='FAILED';Save-ReleaseJournal;throw}
    finally{$script:typeFutureEntry=$null;$script:typeFutureMode=$null}
}
