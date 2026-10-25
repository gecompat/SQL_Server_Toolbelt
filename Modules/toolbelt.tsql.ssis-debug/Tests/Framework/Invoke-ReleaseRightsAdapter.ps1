$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
# Der echte Parameterbuilder wird ohne Öffnen einer Verbindung geprüft.
# SqlValue erzwingt die Typkonvertierung, die sonst erst ExecuteReader auslöst.
$file=Join-Path $PSScriptRoot '../Runtime/Invoke-ReleaseRightsCases.ps1'
$ast=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$null,[ref]$null)
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'New-ReleaseRightsCommand'},$true))
if($nodes.Count -ne 1){throw 'SSIS_RIGHTS_ADAPTER_BUILDER_NOT_UNIQUE'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
function Get-SsisNativeTimeout([int]$Maximum){return [Math]::Min($Maximum,40)}
$Connection=[Data.SqlClient.SqlConnection]::new('Initial Catalog=ContosoSsisDebug')
$package=[byte[]]@(0,128,255);$catalog='{"schemaVersion":1}'
$checks=0
try{
 foreach($help in @($false,$true)){
  $c=New-ReleaseRightsCommand -Operation 'bindings-template' -Help $help
  try{
   if($c.Parameters['@PackageBytes'].Value -isnot [byte[]] -or $c.Parameters['@PackageBytes'].SqlValue.Length -ne 3){throw 'SSIS_RIGHTS_ADAPTER_BINARY_TYPE'};$checks++
   if($c.Parameters['@Bindings'].Value -isnot [DBNull] -or -not $c.Parameters['@Bindings'].SqlValue.IsNull){throw 'SSIS_RIGHTS_ADAPTER_NULL'};$checks++
   if([bool]$c.Parameters['@Hilfe'].Value -ne $help){throw 'SSIS_RIGHTS_ADAPTER_HELP'};$checks++
   foreach($p in $c.Parameters){[void]$p.SqlValue}
   if($Connection.State -ne 'Closed'){throw 'SSIS_RIGHTS_ADAPTER_OPENED_CONNECTION'};$checks++
  }finally{$c.Dispose()}
 }
}finally{$Connection.Dispose()}
"SSIS_RELEASE_RIGHTS_ADAPTER_PASS$checks; real parameter conversions, no SQL"
