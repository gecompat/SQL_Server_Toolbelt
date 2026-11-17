# Unveränderte vorhandene Fixture-/Restore-Schleife, keine alte Top-level-Welle.
. (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')
$markerFaults=@('VersionUnknown','VersionPadded','ModePadded','MarkerPadded','MarkerMissing','Dependency')
$markerNodes=@($lifecycleAst.FindAll({param($n)
    $n -is [Management.Automation.Language.ForEachStatementAst] -and
    $n.Variable.VariablePath.UserPath -ceq 'fault' -and
    $n.Condition.Extent.Text -ceq "@('VersionUnknown','VersionPadded','ModePadded','MarkerPadded','MarkerMissing','Dependency')"
},$true))
if($markerNodes.Count -ne 1){throw 'XLSX_MARKER_COLLISION_ORIGINAL_LOOP_AMBIGUOUS'}
$markerOriginalLoop=[scriptblock]::Create($markerNodes[0].Extent.Text)

function Assert-XlsxMarkerCollisionInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'marker-collision-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_MARKER_COLLISION_SCOPE'}
    $paths=@($Runset.marker_collision.install.local,$Runset.marker_collision.install.central,
        $Runset.marker_collision.uninstall,$Runset.workbooks[0].path,
        (Join-Path $Repository 'Tests/Release/Xlsx.MarkerCollision.Workload.ps1'),
        (Join-Path $Repository 'Tests/Release/Prepare-XlsxMarkerCollisionRunset.ps1'),
        (Join-Path $Repository 'Tests/Release/Test-XlsxMarkerCollisionAdmission.ps1'),
        (Join-Path $Repository 'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Deploy.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.CollisionFixture.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){throw 'XLSX_MARKER_COLLISION_REQUIRED_PIN'}
    }
    foreach($path in @($Runset.marker_collision.install.local,$Runset.marker_collision.install.central,$Runset.marker_collision.uninstall)){
        $text=[IO.File]::ReadAllText($path)
        if($text -match '\$\(' -or $text -match '(?m)^\s*:'){throw 'XLSX_MARKER_COLLISION_UNRESOLVED_TEMPLATE'}
    }
}

function Invoke-XlsxMarkerCollision($Connection,[string]$Mode){
    $module=Join-Path $repo 'Modules/toolbelt.file.xlsx-memory'
    $variables=@{FaultCase=''}
    $deploy=[IO.File]::ReadAllText($script:runset.marker_collision.install.$Mode)
    $uninstall=[IO.File]::ReadAllText($script:runset.marker_collision.uninstall)
    $baseline=Get-XlsxSnapshot $Connection
    $entry=@{mode=$Mode;completedFaults=@();deployRejections=0;uninstallRejections=0;status='RUNNING'}
    $script:ledger.markerCollisions+=@($entry);Save-ReleaseJournal
    $script:stage='MARKER_COLLISIONS_'+$Mode
    # Dot-source den exakten ForEach-AST in den gebundenen lokalen Kontext.
    . $markerOriginalLoop
    if((Get-XlsxSnapshot $Connection) -cne $baseline){throw 'XLSX_MARKER_COLLISION_RESTORE_DRIFT'}
    Assert-XlsxFullSizeNeutral $Connection
    $entry.completedFaults=@($markerFaults);$entry.deployRejections=5;$entry.uninstallRejections=1
    $entry.status='PASS';Save-ReleaseJournal
}
