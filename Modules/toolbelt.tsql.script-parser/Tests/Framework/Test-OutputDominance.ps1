[CmdletBinding()]
param([Parameter(Mandatory)][string]$ScriptDomDllPath)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '../../../../Scripts/Clr/Resolve-ToolbeltScriptDom.ps1')
$ScriptDomDllPath=Resolve-ToolbeltScriptDom -Path $ScriptDomDllPath
$pin='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
if((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $pin){throw 'OUTPUT_DOMINANCE_PIN'}
$assembly=[Reflection.Assembly]::LoadFrom([IO.Path]::GetFullPath($ScriptDomDllPath))
if((Get-FileHash -LiteralPath $assembly.Location -Algorithm SHA512).Hash -cne $pin){throw 'OUTPUT_DOMINANCE_LOADED_BINARY'}
$fragment=$assembly.GetType('Microsoft.SqlServer.TransactSql.ScriptDom.TSqlFragment',$true)
$types=@($assembly.GetTypes()|Where-Object {$fragment.IsAssignableFrom($_)})
$maxType=[long]($types|ForEach-Object {$_.Name.Length}|Measure-Object -Maximum).Maximum
$maxProperty=[long]($types|ForEach-Object {$_.GetProperties([Reflection.BindingFlags]'Public,Instance')}|ForEach-Object {$_.Name.Length}|Measure-Object -Maximum).Maximum
$minProperty=[long]($types|ForEach-Object {$_.GetProperties([Reflection.BindingFlags]'Public,Instance')}|ForEach-Object {$_.Name.Length}|Measure-Object -Minimum).Minimum
$nodeBytes=32768L*(128L+2L*($maxType+$maxProperty))
$tokenBytes=8192L*(128L+2L*64L)+2097152L
$errorBytes=256L*(128L+2L*4000L)
$propertyRows=[long][math]::Floor(16777216L/138L)
if($types.Count -lt 1 -or $maxType -lt 1 -or $maxType -gt 128 -or $minProperty -lt 1 -or $maxProperty -gt 128 -or
   $nodeBytes -gt 16777216L -or $tokenBytes -gt 16777216L -or $errorBytes -gt 16777216L -or $propertyRows -ge 131071){throw 'OUTPUT_DOMINANCE_BOUND_NOT_PROVEN'}
[pscustomobject]@{result='PASS';kind='PINNED_CATALOG_AND_ARITHMETIC';nativeApiExecuted=$false;
 nodeByteBound=$nodeBytes;tokenByteBound=$tokenBytes;errorByteBound=$errorBytes;
 propertyRowBound=$propertyRows;byteCap=16777216L;maximumTypeName=$maxType;maximumPropertyName=$maxProperty}
