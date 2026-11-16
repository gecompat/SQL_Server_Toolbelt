# Der genuine Vorgänger ist Originalcode, kein umbenanntes aktuelles Binary.
function Assert-XlsxGenuine11Inputs($Runset,[string]$Repository) {
    $legacy=$Runset.legacy
    $provenance=Get-Content -LiteralPath $legacy.provenance -Raw|ConvertFrom-Json
    if($provenance.revision -cne 'f64ee9eb8f6a7f66fd441821c7c40fcf2d92ee1e' -or
       $provenance.moduleVersion -cne '1.1.0' -or $legacy.artifact.module_id -cne 'toolbelt.file.xlsx-memory' -or
       $legacy.artifact.sql_name -cne 'Toolbelt_File_XlsxMemory' -or
       $legacy.artifact.sha512 -cne $provenance.assemblySHA512 -or
       (Get-FileHash -LiteralPath $legacy.artifact.path -Algorithm SHA512).Hash -cne $provenance.assemblySHA512 -or
       (Get-FileHash -LiteralPath $legacy.repro -Algorithm SHA512).Hash -cne $provenance.assemblySHA512){throw 'XLSX_GENUINE11_ORIGIN'}
    $paths=@($legacy.provenance,$legacy.artifact.path,$legacy.repro,$legacy.remove_current,
      $legacy.install.local,$legacy.install.central,
      (Join-Path $Repository 'Tests/Release/Xlsx.Genuine11.Workload.ps1'),
      (Join-Path $Repository 'Tests/Release/Prepare-XlsxGenuine11Runset.ps1'),
      (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Scripts/New-Xlsx11LegacyFixture.ps1'),
      (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'))
    if(@($provenance.sourcePins.PSObject.Properties).Count -ne 15){throw 'XLSX_GENUINE11_SOURCE_SET'}
    foreach($item in $provenance.sourcePins.PSObject.Properties){
        $path=Join-Path $legacy.module $item.Name
        if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $item.Value.sha256){throw 'XLSX_GENUINE11_SOURCE_CHANGED'}
        $blob=(& git -C $Repository rev-parse ($provenance.revision+':Modules/toolbelt.file.xlsx-memory/'+$item.Name)).Trim()
        $actual=(& git -C $Repository hash-object --no-filters $path).Trim()
        if($LASTEXITCODE -or $blob -cne $item.Value.gitBlob -or $actual -cne $blob){throw 'XLSX_GENUINE11_ORIGINAL_BLOB'}
        $paths+=@($path)
    }
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){throw 'XLSX_GENUINE11_REQUIRED_PIN'}
    }
}

function Invoke-XlsxGenuine11Setup($Connection,[string]$Mode) {
    # Gemeinsames aktuelles Paket liefert die qualifizierten Dependencies.
    # Nur XLSX wird anschließend öffentlich deinstalliert; ZIP/Core bleiben.
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.exports.$Mode.Install,[Text.Encoding]::UTF8))
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.legacy.remove_current,[Text.Encoding]::UTF8))
    Invoke-ReleaseBatches $Connection ([IO.File]::ReadAllText($script:runset.legacy.install.$Mode,[Text.Encoding]::UTF8))
    $old=@(Invoke-ReleaseSql $Connection @'
SELECT CONVERT(nvarchar(64),e.value) Version,
 (SELECT CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode') Mode,
 (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file')) Slots,
 (SELECT COUNT(*) FROM sys.assembly_modules WHERE assembly_id=a.assembly_id) Bindings,
 CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) Hash,a.permission_set_desc Permission
FROM sys.extended_properties e CROSS JOIN sys.assemblies a
JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
WHERE e.class=0 AND e.name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version'
 AND a.name=N'Toolbelt_File_XlsxMemory';
'@ -Rows)
    if($old.Count -ne 1 -or $old[0].Version -cne '1.1.0' -or $old[0].Mode -cne $Mode -or $old[0].Slots -ne 7 -or
       $old[0].Bindings -ne 3 -or $old[0].Hash -cne $script:runset.legacy.artifact.sha512 -or
       $old[0].Permission -cne 'SAFE_ACCESS'){throw 'XLSX_GENUINE11_NATIVE_BASELINE'}
    $script:ledger.genuine+=@(@{mode=$Mode;status='PASS_GENUINE_1_1'})
    Save-ReleaseJournal
}
