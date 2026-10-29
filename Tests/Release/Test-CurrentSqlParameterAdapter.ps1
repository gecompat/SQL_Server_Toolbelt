$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$path=Join-Path $PSScriptRoot '../../Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentCases.ps1'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
if($errors.Count){throw 'CURRENT_PARAMETER_ADAPTER_PARSE'}
$nodes=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Invoke-CurrentExplain'},$true))
if($nodes.Count -ne 1){throw 'CURRENT_PARAMETER_ADAPTER_FUNCTION'}
$text=$nodes[0].Extent.Text.Replace("`r`n","`n")
$anchor=" try{`n  `$table=[Data.DataTable]::new();`$reader=`$cmd.ExecuteReader()"
if(([regex]::Matches($text,[regex]::Escape($anchor))).Count -ne 1){throw 'CURRENT_PARAMETER_ADAPTER_EXECUTION_ANCHOR'}
# Return the actual command immediately before the sole SQL execution site.
# SqlValue forces the same provider conversions without opening a connection.
$text=$text.Substring(0,$text.IndexOf($anchor))+" return ,`$cmd`n}"
. ([scriptblock]::Create($text))
function Get-SsisNativeTimeout([int]$Maximum=45){return $Maximum}
$Connection=[Data.SqlClient.SqlConnection]::new();$script:currentDialect=[int16]150
$checks=0
try{
 foreach($help in @($false,$true)){
  foreach($bytes in @([byte[]]@(0,1,2,255),$null)){
   $command=Invoke-CurrentExplain -Bytes $bytes -Help $help -Limits @{'@MaxPackageBytes'=0}
   try{
    foreach($parameter in $command.Parameters){[void]$parameter.SqlValue;$checks++}
    if($null -eq $bytes){if(-not $command.Parameters['@PackageBytes'].SqlValue.IsNull){throw 'CURRENT_PARAMETER_ADAPTER_NULL_BYTES'}}
    elseif($command.Parameters['@PackageBytes'].Value -isnot [byte[]] -or $command.Parameters['@PackageBytes'].SqlValue.Value.Length -ne 4){throw 'CURRENT_PARAMETER_ADAPTER_BYTE_ARRAY'}
    foreach($name in @('@Bindings','@ProjectContext','@CatalogBindings','@ResultTable')){if($command.Parameters[$name].Value -isnot [DBNull]){throw 'CURRENT_PARAMETER_ADAPTER_NULL_STRING'}}
    if([bool]$command.Parameters['@Hilfe'].SqlValue.Value -ne $help){throw 'CURRENT_PARAMETER_ADAPTER_HELP_BIT'}
   }finally{$command.Dispose()}
  }
 }
 if($Connection.State -ne 'Closed'){throw 'CURRENT_PARAMETER_ADAPTER_OPENED_CONNECTION'}
}finally{$Connection.Dispose()}
"PASS SSIS_CURRENT_SQL_PARAMETER_ADAPTER checks=$checks; no SQL"
