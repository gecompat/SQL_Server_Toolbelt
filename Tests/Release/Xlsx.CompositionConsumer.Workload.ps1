# Vorhandene bytegebundene Workbook-/Metadatenhelfer; keine neue Produktlogik.
. (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1')

function Assert-XlsxCompositionConsumerInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'composition-consumer-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_COMPOSITION_SCOPE'}
    $paths=@($Runset.composition_consumer.unconfirmed,$Runset.workbooks[0].path,
        (Join-Path $PSScriptRoot 'Xlsx.CompositionConsumer.Workload.ps1'),
        (Join-Path $PSScriptRoot 'Prepare-XlsxCompositionConsumerRunset.ps1'),
        (Join-Path $PSScriptRoot 'Test-XlsxCompositionConsumerAdmission.ps1'),
        (Join-Path $PSScriptRoot 'Xlsx.OwnedDatabase.ps1'),
        (Join-Path $PSScriptRoot 'Xlsx.CallerCatalog.Workload.ps1'),
        (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    $runtime=Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime'
    foreach($name in @('Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1','Types.Metadata.ps1',
        'Display.Metadata.ps1','Types.Composition.xlsx','Types.Composition.sql','Display.Composition.sql')){
        $paths+=@(Join-Path $runtime $name)
    }
    if(($Runset.composition_consumer.helpers.PSObject.Properties.Name -join '|') -cne
       'Types.Metadata.ps1|Display.Metadata.ps1|Invoke-TypesComposition.ps1|Invoke-DisplayComposition.ps1'){
        throw 'XLSX_COMPOSITION_HELPER_SET'
    }
    foreach($property in $Runset.composition_consumer.helpers.PSObject.Properties){
        if($property.Value -cne (Join-Path $runtime $property.Name)){throw 'XLSX_COMPOSITION_HELPER_ROUTING'}
    }
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){throw 'XLSX_COMPOSITION_REQUIRED_PIN'}
    }
    # Die unveränderten Originalhelfer enthalten dieselben festen Byteorakel.
    foreach($pair in @(@{name='Types.Composition.xlsx';hash='7B690C7C0EC6C2EEBBEA180B031C7BDAED1A6D1DC5F2D3CEC360135B8F530BC1'},
        @{name='Types.Composition.sql';hash='9C63E84B28B066555A20D6354F2154E8C5A830CA3372C52D40F73B02F13B923E'},
        @{name='Display.Composition.sql';hash='A44F37281DEC7D74E82DE44D62D9A6A929A47AAF9849D4458E68278713901A44'})){
        if((Get-FileHash -LiteralPath (Join-Path $runtime $pair.name)).Hash -cne $pair.hash){throw 'XLSX_COMPOSITION_ORIGINAL_BYTE_ORACLE'}
    }
}

function Invoke-XlsxCompositionOriginalHelper($Connection,[string]$ProviderDatabase,[string]$Name){
    if($Name -cnotin @('Types.Metadata.ps1','Display.Metadata.ps1','Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1')){
        throw 'XLSX_COMPOSITION_HELPER_UNKNOWN'
    }
    $providers=New-XlsxClientBudgetProviders $script:clock (Get-ReleaseTimeout)
    $output=@(& $script:runset.composition_consumer.helpers.$Name -Connection $Connection -ToolbeltDatabase $ProviderDatabase `
        -CommandTimeoutProvider $providers.Timeout -ReadBudgetProvider $providers.Read)
    if($Name.StartsWith('Invoke-',[StringComparison]::Ordinal)){
        $composition=if($Name -ceq 'Invoke-TypesComposition.ps1'){'RawCells-to-InterpretXlsxCell'}else{'RawCells-to-Interpret-and-FormatXlsxCell'}
        if($output.Count -ne 1 -or $output[0].Status -cne 'PASS' -or $output[0].SyntheticCells -ne 9 -or
           $output[0].PublicComposition -cne $composition){throw 'XLSX_COMPOSITION_ORIGINAL_RESULT'}
    }elseif($output.Count -ne 1 -or $output[0] -isnot [string] -or -not $output[0].StartsWith('PASS:',[StringComparison]::Ordinal)){
        throw 'XLSX_COMPOSITION_METADATA_RESULT'
    }
    Assert-XlsxFullSizeNeutral $Connection
}

function Assert-XlsxProviderFreeConsumer($Connection){
    $owned=@($script:ledger.databases|Where-Object {$_.name -ceq $Connection.Database -and $_.suffix -ceq 'u' -and $_.state -ceq 'OWNED'})
    if($owned.Count -ne 1){throw 'XLSX_COMPOSITION_CONSUMER_NOT_OWNED'}
    $rows=@(Invoke-ReleaseSql $Connection @'
SELECT DB_NAME() DbName,CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation')) Collation,
 (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) CL,
 (SELECT COUNT(*) FROM sys.objects WHERE is_ms_shipped=0) Objects,
 (SELECT COUNT(*) FROM sys.assemblies WHERE is_user_defined=1) Assemblies,
 (SELECT COUNT(*) FROM sys.schemas WHERE name LIKE N'toolbelt[_]%') Schemas,
 (SELECT COUNT(*) FROM sys.extended_properties WHERE name LIKE N'Toolbelt.Module.%') Modules;
'@ -Rows)
    if($rows.Count -ne 1 -or $rows[0].DbName -cne $Connection.Database -or
       $rows[0].Collation -cne 'Latin1_General_100_CS_AS' -or $rows[0].CL -ne $script:case.CL -or
       $rows[0].Objects -ne 0 -or $rows[0].Assemblies -ne 0 -or $rows[0].Schemas -ne 0 -or $rows[0].Modules -ne 0){
        throw 'XLSX_COMPOSITION_CONSUMER_PROVIDER_PRESENT_OR_CONTEXT_DRIFT'
    }
    Assert-XlsxFullSizeNeutral $Connection
}

function Invoke-XlsxCompositionConsumer($Connection,[string]$Mode,$Control){
    $before=Get-XlsxSnapshot $Connection
    $entry=@{mode=$Mode;installedHelpers=@();consumerHelpers=@();providerFreeWitnesses=0;nullability=0;confirm0=0;status='RUNNING'}
    $script:ledger.compositions+=@($entry);Save-ReleaseJournal
    foreach($name in @('Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1')){
        $script:stage='COMPOSITION_'+$Mode+'_'+$name
        Invoke-XlsxCompositionOriginalHelper $Connection $Connection.Database $name
        $entry.installedHelpers+=@($name);Save-ReleaseJournal
    }
    if($Mode -ceq 'central'){
        $consumer=$null
        try{
            $script:stage='CONSUMER_CREATE'
            $consumer=New-XlsxFullSizeOwnedDatabase $Control 'u' 'Latin1_General_100_CS_AS' $script:case.CL
            Assert-XlsxProviderFreeConsumer $consumer;$entry.providerFreeWitnesses++;Save-ReleaseJournal
            foreach($name in @('Types.Metadata.ps1','Display.Metadata.ps1','Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1')){
                $script:stage='CONSUMER_'+$name
                Invoke-XlsxCompositionOriginalHelper $consumer $Connection.Database $name
                $entry.consumerHelpers+=@($name);Save-ReleaseJournal
            }
            Assert-XlsxNativeNullablePrepared $consumer $Connection.Database $Connection
            $entry.nullability=1;Save-ReleaseJournal
            Assert-XlsxProviderFreeConsumer $consumer;$entry.providerFreeWitnesses++;Save-ReleaseJournal
        }finally{if($consumer){$consumer.Dispose()}}
        $script:stage='CONSUMER_CONFIRM0'
        Assert-XlsxRejected $Connection ([IO.File]::ReadAllText($script:runset.composition_consumer.unconfirmed)) 51536
        $entry.confirm0=1;Save-ReleaseJournal
    }
    if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_COMPOSITION_PROVIDER_DRIFT'}
    Assert-XlsxFullSizeNeutral $Connection
    $entry.status='PASS';Save-ReleaseJournal
}

function Assert-XlsxCompositionConsumerJournal($Prior){
    if(($Prior.completedModes -join '|') -cne 'local|central' -or ($Prior.databases.suffix -join '|') -cne 'l|c|u' -or
       ($Prior.compositions.mode -join '|') -cne 'local|central'){throw 'XLSX_COMPOSITION_AUDIT_CONTEXTS'}
    foreach($group in $Prior.compositions){
        $central=$group.mode -ceq 'central'
        $helpers=if($central){@('Types.Metadata.ps1','Display.Metadata.ps1','Invoke-TypesComposition.ps1','Invoke-DisplayComposition.ps1')}else{@()}
        if($group.status -cne 'PASS' -or ($group.installedHelpers -join '|') -cne 'Invoke-TypesComposition.ps1|Invoke-DisplayComposition.ps1' -or
           ($group.consumerHelpers -join '|') -cne ($helpers -join '|') -or
           $group.providerFreeWitnesses -ne $(if($central){2}else{0}) -or
           $group.nullability -ne $(if($central){1}else{0}) -or $group.confirm0 -ne $(if($central){1}else{0})){
            throw 'XLSX_COMPOSITION_AUDIT_GROUP'
        }
    }
}
