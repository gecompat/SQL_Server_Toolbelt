# Originale Caller-/Katalognullability-Orakel, aktueller begrenzter SQL-Kern.
. (Join-Path $PSScriptRoot 'Xlsx.LifecycleNegative.Workload.ps1')
foreach($callerName in @('Assert-XlsxCallerPrepared','Assert-XlsxNativeNullablePrepared')){
    $nodes=@($lifecycleAst.FindAll({param($n)
        $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $callerName
    },$true))
    if($nodes.Count -ne 1){throw 'XLSX_CALLER_CATALOG_HELPER_AMBIGUOUS'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}

function Get-XlsxCommandTimeout {Get-ReleaseTimeout}
function Assert-XlsxReadBudget($Command){
    try{[void](Get-ReleaseTimeout)}catch{try{$Command.Cancel()}catch{};throw}
}

function Assert-XlsxCallerCatalogInputs($Runset,[string]$Repository){
    if($Runset.qualification_scope -cne 'caller-catalog-rest' -or $Runset.workbooks.Count -ne 1 -or
       $Runset.workbooks[0].name -cne 'Display.Lifecycle.sql'){throw 'XLSX_CALLER_CATALOG_SCOPE'}
    $paths=@($Runset.caller_catalog.install.local,$Runset.caller_catalog.install.central,
        $Runset.caller_catalog.uninstall,$Runset.workbooks[0].path,
        (Join-Path $Repository 'Tests/Release/Xlsx.CallerCatalog.Workload.ps1'),
        (Join-Path $Repository 'Tests/Release/Prepare-XlsxCallerCatalogRunset.ps1'),
        (Join-Path $Repository 'Tests/Release/Xlsx.LifecycleNegative.Workload.ps1'),
        (Join-Path $Repository 'Tests/CI/run-xlsx-types-lab.ps1'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Deploy.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Deployment/Uninstall.sql'),
        (Join-Path $Repository 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Display.Lifecycle.sql'))
    foreach($path in $paths){
        $pin=@($Runset.pins|Where-Object path -CEQ $path)
        if($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256){
            throw 'XLSX_CALLER_CATALOG_REQUIRED_PIN'
        }
    }
    foreach($path in @($Runset.caller_catalog.install.local,$Runset.caller_catalog.install.central,$Runset.caller_catalog.uninstall)){
        $text=[IO.File]::ReadAllText($path)
        if($text -match '\$\(' -or $text -match '(?m)^\s*:'){throw 'XLSX_CALLER_CATALOG_UNRESOLVED_TEMPLATE'}
    }
}

function Invoke-XlsxCallerCatalog($Connection,[string]$Mode){
    $deploy=[IO.File]::ReadAllText($script:runset.caller_catalog.install.$Mode)
    $uninstall=[IO.File]::ReadAllText($script:runset.caller_catalog.uninstall)
    $before=Get-XlsxSnapshot $Connection
    $entry=@{mode=$Mode;profiles=@();callerRejections=0;nullability=0;status='RUNNING'}
    $script:ledger.callerCatalog+=@($entry);Save-ReleaseJournal
    foreach($abort in @('OFF','ON')){
        foreach($doomed in @($false,$true)){
            $profile=$abort+'/'+$(if($doomed){'doomed'}else{'intact'})
            $script:stage='CALLER_TX_'+$Mode+'_'+$profile
            Assert-XlsxCallerPrepared $Connection $deploy $uninstall $abort $doomed
            Assert-XlsxFullSizeNeutral $Connection
            $entry.profiles+=@($profile);$entry.callerRejections+=2;Save-ReleaseJournal
        }
    }
    $script:stage='CATALOG_NULLABILITY_'+$Mode
    Assert-XlsxNativeNullablePrepared $Connection $Connection.Database
    $entry.nullability=1;Save-ReleaseJournal
    if((Get-XlsxSnapshot $Connection) -cne $before){throw 'XLSX_CALLER_CATALOG_SNAPSHOT_DRIFT'}
    Assert-XlsxFullSizeNeutral $Connection
    $entry.status='PASS';Save-ReleaseJournal
}
