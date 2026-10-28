# Dot-sourced by the bounded V2 cases inside the existing owned lab database.
$database=[string](Invoke-V2Sql 'SELECT DB_NAME() AS N;').Rows[0].N
function Get-V2PlanParts($Artifacts,$TargetRow){
    $detail=([string]$TargetRow.DetailsJson)|ConvertFrom-Json -Depth 32
    $units=@($Artifacts.Rows | Where-Object {
        $_.ArtifactKind -ceq 'PlanUnitSql' -and
        (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)
    } | Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).ordinal})
    $manifests=@($Artifacts.Rows | Where-Object {
        $_.ArtifactKind -ceq 'PlanManifest' -and
        (([string]$_.Content|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)
    })
    Assert-V2 ($manifests.Count -eq 1 -and $units.Count -eq $detail.unitCount) 'PLAN_MANIFEST_CARDINALITY'
    $manifest=([string]$manifests[0].Content)|ConvertFrom-Json -Depth 32
    Assert-V2 ($manifest.units.Count -eq $units.Count) 'PLAN_MANIFEST_UNITS'
    for($i=0;$i -lt $units.Count;$i++){
        $unit=([string]$units[$i].DetailsJson)|ConvertFrom-Json -Depth 32
        $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$units[$i].Content)))
        Assert-V2 ($unit.ordinal -eq $i -and $manifest.units[$i].unitId -ceq [string]$units[$i].StageId -and $unit.unitContentSha256 -ceq $hash) 'PLAN_TRANSPORT_ORDER_HASH'
        Assert-V2 ($units[$i].IsExecutable -eq $true -and $units[$i].SafetyStatus -ceq 'passed') 'PLAN_UNIT_SAFETY'
    }
    $cleanups=@($Artifacts.Rows | Where-Object {
        $_.ArtifactKind -ceq 'CleanupSql' -and
        (([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).planHash -ceq $detail.planHash)
    } | Sort-Object {([string]$_.DetailsJson|ConvertFrom-Json -Depth 32).cleanupOrdinal})
    Assert-V2 ($cleanups.Count -gt 0) 'PLAN_HAS_CLEANUP'
    [pscustomobject]@{Detail=$detail;Units=$units;Cleanups=$cleanups}
}
function Invoke-V2Units($Parts){foreach($unit in $Parts.Units){[void](Invoke-V2Sql ([string]$unit.Content))}}
function Clear-V2Plan($Parts){foreach($cleanup in $Parts.Cleanups){[void](Invoke-V2Sql ([string]$cleanup.Content))}}
function Get-V2Catalog([bool]$Flat=$false){
    $catalog=@{schemaVersion=2;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database};flatFileInputs=@{}}
    if($Flat){
        $catalog.flatFileInputs=@{'Package.ConnectionManagers[FlatInput]'=@{
            database=$database;schema='dbo';object='SyntheticFlatFileRows';columns=@{
                'Package\Flow\FlatSource.output[Rows].Columns[KeyA]'='KeyA'
                'Package\Flow\FlatSource.output[Rows].Columns[Amount]'='Amount'
            }
        }}
    }
    return $catalog
}
[void](Invoke-V2Sql @'
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
CREATE TABLE dbo.SyntheticFlatFileRows(KeyA int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticFlatFileErrorRows(KeyA int NOT NULL,Amount int NOT NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
INSERT dbo.SyntheticFlatFileRows VALUES(11,110),(22,220);
INSERT dbo.SyntheticFlatFileErrorRows VALUES(-1,-999);
'@)
try{
    $rowBytes=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/components-v2-rowcount.dtsx'))
    $catalog=(Get-V2Catalog)|ConvertTo-Json -Depth 12 -Compress
    . (Join-Path $PSScriptRoot 'Invoke-ComponentsV2ExpressionCases.ps1')
    . (Join-Path $PSScriptRoot 'Invoke-ComponentsV2VariableCases.ps1')
    $rowTemplate=Invoke-V2Explain -Bytes $rowBytes
    $rowArtifacts=Invoke-V2Explain -Bytes $rowBytes -Operation 'explain' -Bindings ([string]$rowTemplate.Rows[0].Content) -Catalog $catalog
    $counts=@($rowArtifacts.Select("ArtifactKind='RowCountSql'"))
    Assert-V2 ($counts.Count -eq 1 -and $counts[0].IsComplete) 'ROWCOUNT_ONE_COMPLETED_TARGET'
    $target=@($rowArtifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'TargetSql' -and $_.TargetFlowId -ceq $counts[0].TargetFlowId})[0]
    $parts=Get-V2PlanParts $rowArtifacts $target
    Reject-V2 {Invoke-V2Sql ([string]$target.Content)} 'plan_state'
    if($parts.Units.Count -gt 1){Reject-V2 {Invoke-V2Sql ([string]$parts.Units[1].Content)} 'plan_state'}
    [void](Invoke-V2Sql ([string]$parts.Units[0].Content))
    Clear-V2Plan $parts
    Clear-V2Plan $parts
    Assert-V2 $true 'PARTIAL_UNIT0_CLEANUP_AND_REPLAY_NOOP'
    [void](Invoke-V2Sql 'BEGIN TRANSACTION;')
    try{
        Reject-V2 {Invoke-V2Sql ([string]$parts.Units[0].Content)} 'cache_context_changed'
        $state=Invoke-V2Sql ('SELECT @@TRANCOUNT AS T,XACT_STATE() AS S,OBJECT_ID(N''tempdb..'+$parts.Detail.planStateTemp.Replace("'","''")+''',N''U'') AS O;')
        Assert-V2 ($state.Rows[0].T -eq 1 -and $state.Rows[0].S -eq 1 -and $state.Rows[0].IsNull('O')) 'PLAN_PREFLIGHT_NO_CALLER_MUTATION'
    }finally{[void](Invoke-V2Sql 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;')}
    Invoke-V2Units $parts
    try{
        $projection=Invoke-V2Sql ([string]$target.Content)
        $count=Invoke-V2Sql ([string]$counts[0].Content)
        Assert-V2 ($projection.Rows.Count -eq 2 -and $count.Rows.Count -eq 1 -and $count.Rows[0].CountValue -eq 2 -and $count.Rows[0].FitsTargetVariable -eq $true) 'ROWCOUNT_FIXED_TYPED_ORACLE'
        Assert-V2 ($count.Rows[0].CountValue -is [long]) 'ROWCOUNT_COUNT_BIG_TYPE'
        $timing=([string]$counts[0].DetailsJson)|ConvertFrom-Json -Depth 32
        Assert-V2 ($timing.assignmentTiming -ceq 'after-last-row' -and $timing.snapshotSharedWithProjection -eq $true) 'ROWCOUNT_POST_FLOW_SNAPSHOT_METADATA'
        $lastUnit=$parts.Units[-1]
        $lastDetail=([string]$lastUnit.DetailsJson)|ConvertFrom-Json -Depth 32
        $marker=[regex]::Match([string]$lastUnit.Content,'CREATE TABLE \[(#tbx_SsisDebug_Q_[A-Za-z0-9_]+)\]').Groups[1].Value
        Assert-V2 ($marker -and $lastDetail.ownerSha256 -cmatch '^[A-F0-9]{64}$') 'OWN_GENERATION_MARKER_IDENTIFIED'
        $markerSql='['+$marker+']'
        $before=Invoke-V2Sql ('SELECT [Fingerprint] FROM '+$markerSql+' WHERE [Owner]=0x'+$lastDetail.ownerSha256+';')
        Assert-V2 ($before.Rows.Count -eq 1) 'OWN_GENERATION_MARKER_SINGLE_ROW'
        $oldFingerprint=[byte[]]($before.Rows[0].Fingerprint)
        $badFingerprint=[byte[]]$oldFingerprint.Clone();$badFingerprint[0]=$badFingerprint[0] -bxor 1
        $oldHex=[Convert]::ToHexString($oldFingerprint);$badHex=[Convert]::ToHexString($badFingerprint)
        [void](Invoke-V2Sql ('UPDATE '+$markerSql+' SET [Fingerprint]=0x'+$badHex+' WHERE [Owner]=0x'+$lastDetail.ownerSha256+' AND [Fingerprint]=0x'+$oldHex+'; IF @@ROWCOUNT<>1 THROW 50000,N''SSIS_V2_TEST_DRIFT_SETUP_CHANGED'',1;'))
        try{Reject-V2 {Invoke-V2Sql ([string]$target.Content)} 'plan_dependency'}
        finally{
            # Restore only the exact artificial change made immediately above.
            [void](Invoke-V2Sql ('UPDATE '+$markerSql+' SET [Fingerprint]=0x'+$oldHex+' WHERE [Owner]=0x'+$lastDetail.ownerSha256+' AND [Fingerprint]=0x'+$badHex+'; IF @@ROWCOUNT<>1 THROW 50000,N''SSIS_V2_TEST_DRIFT_RESTORE_BLOCKED'',1;'))
        }
        [void](Invoke-V2Sql 'UPDATE dbo.SyntheticSourceA SET Amount=0; DELETE dbo.SyntheticSourceB;')
        $sameProjection=Invoke-V2Sql ([string]$target.Content)
        $sameCount=Invoke-V2Sql ([string]$counts[0].Content)
        Assert-V2 ($sameProjection.Rows.Count -eq 2 -and $sameCount.Rows[0].CountValue -eq 2) 'ROWCOUNT_SHARED_MATERIALIZED_SNAPSHOT_AFTER_SOURCE_CHANGE'
        Reject-V2 {Invoke-V2Sql ([string]$parts.Units[0].Content)} 'plan_ownership'
    }finally{Clear-V2Plan $parts}
    Clear-V2Plan $parts
    Assert-V2 $true 'PLAN_CLEANUP_IDEMPOTENT'
    [void](Invoke-V2Sql 'UPDATE dbo.SyntheticSourceA SET Amount=CASE WHEN KeyA=1 AND KeyB=10 THEN 100 WHEN KeyA=1 AND KeyB=20 THEN 20 ELSE 200 END; INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);')
    [xml]$missing=[Text.Encoding]::UTF8.GetString($rowBytes)
    $missing.SelectSingleNode('//component[@name="RowCount"]/properties/property[@name="VariableName"]').InnerText='User::MissingCountTarget'
    $invalidCount=Invoke-V2Explain -Bytes ([Text.Encoding]::UTF8.GetBytes($missing.OuterXml)) -Operation 'explain' -Catalog $catalog
    Assert-V2 (@($invalidCount.Select("ArtifactKind='Diagnostic' AND DiagnosticCode='missing_context'")).Count -gt 0) 'ROWCOUNT_MISSING_VARIABLE_EXPLICIT'
    $flatBytes=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/components-v2-flatfile.dtsx'))
    $flatCatalog=Get-V2Catalog -Flat $true
    $flatTemplate=Invoke-V2Explain -Bytes $flatBytes
    $flat=Invoke-V2Explain -Bytes $flatBytes -Operation 'explain' -Bindings ([string]$flatTemplate.Rows[0].Content) -Catalog ($flatCatalog|ConvertTo-Json -Depth 12 -Compress)
    Assert-V2 (@($flat.Select("ArtifactKind='Diagnostic' AND DiagnosticCode='missing_context'")).Count -gt 0) 'FLATFILE_MISSING_ERROR_ROWS_EXPLICIT'
    $flatTarget=@($flat.Rows|Where-Object {$_.ArtifactKind -ceq 'TargetSql' -and $_.ComponentId -ceq 'Package\Flow\FlatTarget'})[0]
    $flatParts=Get-V2PlanParts $flat $flatTarget
    Invoke-V2Units $flatParts
    try{
        $rows=Invoke-V2Sql ([string]$flatTarget.Content)
        Assert-V2 ($rows.Rows.Count -eq 2 -and @($rows.Select('KeyA=11 AND Amount=110')).Count -eq 1 -and @($rows.Select('KeyA=22 AND Amount=220')).Count -eq 1) 'FLATFILE_DECLARED_ROWSET_FIXED_ORACLE'
        $mode=([string]$flatTarget.DetailsJson)|ConvertFrom-Json -Depth 32
        Assert-V2 ($mode.targetMode -ceq 'flatfile-debug-projection' -and $mode.fileWriteSimulated -eq $false) 'FLATFILE_NO_FILE_WRITER_CLAIM'
    }finally{Clear-V2Plan $flatParts}
    $errorColumns=@{}
    [xml]$flatXml=[Text.Encoding]::UTF8.GetString($flatBytes)
    foreach($column in $flatXml.SelectNodes('//component[@name="FlatSource"]/outputs/output[@isErrorOut="true"]/outputColumns/outputColumn')){
        $errorColumns[$column.GetAttribute('refId')]=$column.GetAttribute('name')
    }
    $flatCatalog.flatFileInputs['Package.ConnectionManagers[FlatInput]'].errorRows=@{database=$database;schema='dbo';object='SyntheticFlatFileErrorRows';columns=$errorColumns}
    $withErrors=Invoke-V2Explain -Bytes $flatBytes -Operation 'explain' -Bindings ([string]$flatTemplate.Rows[0].Content) -Catalog ($flatCatalog|ConvertTo-Json -Depth 12 -Compress)
    $errorTarget=@($withErrors.Rows|Where-Object {$_.ArtifactKind -ceq 'TargetSql' -and $_.ComponentId -ceq 'Package\Flow\FlatErrorTarget'})[0]
    $errorParts=Get-V2PlanParts $withErrors $errorTarget
    Invoke-V2Units $errorParts
    try{
        $rows=Invoke-V2Sql ([string]$errorTarget.Content)
        Assert-V2 ($rows.Rows.Count -eq 1 -and $rows.Rows[0].KeyA -eq -1 -and $rows.Rows[0].Amount -eq -999) 'FLATFILE_EXPLICIT_ERROR_ROWSET_FIXED_ORACLE'
    }finally{Clear-V2Plan $errorParts}
}finally{
    [void](Invoke-V2Sql 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup,dbo.SyntheticFlatFileRows,dbo.SyntheticFlatFileErrorRows;')
}
"SSIS_V2_NATIVE_DOMAIN_PASS $script:v2Checks cumulative assertions; synthetic fixed oracles"
