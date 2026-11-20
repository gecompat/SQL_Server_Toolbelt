# Ausschließlich synthetische ZIPs und SQL-Texte; keine SQL-Verbindung.
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repo 'Deployment/Toolbelt.Package.ps1')
$temp=Join-Path $repo ('.runtime/markerless-package-tests-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $temp
$script:checks=0
function Assert-Test([bool]$Condition,[string]$Name) {
    if(-not $Condition){throw $Name};$script:checks++
}
function Reject-Test([scriptblock]$Action,[string]$Name) {
    $rejected=$false;try{& $Action|Out-Null}catch{$rejected=$true}
    Assert-Test $rejected $Name
}
function New-Fixture([string]$Name,[string]$Variant='valid') {
    $files=[ordered]@{};$profiles=@()
    foreach($platform in 'Windows','Portable') {foreach($mode in 'local','central') {
        $path='Sql/Install-'+$platform+'-'+$mode+'.sql'
        $bytes=[Text.Encoding]::UTF8.GetBytes("USE [ContosoToolbelt];`nDECLARE @TrustMethod varchar(24)=N'auto';`nSELECT 1;`n")
        $files[$path]=$bytes
        $profiles+=@{platform=$platform;mode=$mode;path=$path;modules=@('toolbelt.core.result-table');
            objects=@(@{schema='toolbelt_core';name='USP_PrepareResultTable';types='P,PC'});assemblies=@{}}
    }}
    if($Variant -eq 'duplicate-profile'){$profiles[3]=$profiles[0]}
    if($Variant -eq 'object-injection'){$profiles[0].objects[0].name="x';DROP TABLE dbo.Other;--"}
    if($Variant -eq 'traversal'){$files['../outside.sql']=[byte[]]@(1)}
    $hashes=[ordered]@{};foreach($key in $files.Keys){$hashes[$key]=Get-ToolbeltSha256 $files[$key]}
    $manifest=@{schema='toolbelt-install-package/v2';release='v1.0.0-rc.5';source_commit=('0'*40);profiles=$profiles;files=$hashes}
    if($Variant -eq 'tampered'){$files['Sql/Install-Windows-local.sql']=[byte[]]@(1,2,3)}
    if($Variant -eq 'extra'){$files['unknown.txt']=[byte[]]@(1)}
    $path=Join-Path $temp ($Name+'.zip')
    $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew)
    $archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
    try {
        $entries=[ordered]@{'PACKAGE.json'=[Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $manifest -Depth 16))}
        foreach($key in $files.Keys){$entries[$key]=$files[$key]}
        foreach($key in $entries.Keys){$entry=$archive.CreateEntry($key);$s=$entry.Open();try{$s.Write($entries[$key],0,$entries[$key].Length)}finally{$s.Dispose()}}
        if($Variant -eq 'duplicate-file'){$entry=$archive.CreateEntry('sql/install-windows-local.sql');$entry.Open().Dispose()}
    }finally{$archive.Dispose();$stream.Dispose()}
    $path
}
try {
    $valid=New-Fixture 'valid'
    $package=Get-ToolbeltPayload $valid
    Assert-Test (@($package.Manifest.profiles).Count -eq 4) 'FOUR_PROFILES'
    $profile=$package.Manifest.profiles[0]
    $sql=Get-ToolbeltInstallSql $package $profile 'Contoso]App' 'trustworthy-checked'
    Assert-Test ($sql.StartsWith('USE [Contoso]]App];')) 'DATABASE_IDENTIFIER_QUOTING'
    Assert-Test ($sql.Contains("DECLARE @TrustMethod varchar(24)=N'trustworthy-checked';")) 'EXPLICIT_TRUST_SELECTION'
    $receipt=Get-ToolbeltReceiptSql $profile 'ContosoApp'
    Assert-Test ($receipt.Contains('sys.objects') -and $receipt.Contains('USP_PrepareResultTable')) 'DECLARED_INTERFACE_RECEIPT'
    Assert-Test ($receipt -notmatch 'extended_properties|ModuleVersion|DeploymentMode') 'NO_MARKER_RECEIPT'
    foreach($variant in 'tampered','extra','traversal','duplicate-file','duplicate-profile','object-injection') {
        $bad=New-Fixture $variant $variant
        Reject-Test {Get-ToolbeltPayload $bad} ('REJECT_'+$variant)
    }
    Reject-Test {Get-ToolbeltPayload $valid ('0'*64)} 'EXTERNAL_PACKAGE_HASH'
    Reject-Test {Get-ToolbeltInstallSql $package $profile 'ContosoApp' 'fallback'} 'NO_TRUST_FALLBACK'
    Reject-Test {Get-ToolbeltInstallSql $package $profile "Contoso`n:!!other" 'auto'} 'NO_CLIENT_CONTROL_INJECTION'
    Reject-Test {Get-ToolbeltInstallSql $package $profile '$(SQLCMDPASSWORD)' 'auto'} 'NO_CLIENT_VARIABLE_INJECTION'
    "MARKERLESS_PACKAGE_PASS checks=$script:checks; no SQL executed"
}finally{
    $full=[IO.Path]::GetFullPath($temp)
    $boundary=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'TEST_CLEANUP_SCOPE'}
    Remove-Item -LiteralPath $full -Recurse -Force
}
