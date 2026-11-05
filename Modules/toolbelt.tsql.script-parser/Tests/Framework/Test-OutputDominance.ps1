[CmdletBinding()]
param([Parameter(Mandatory)][string]$ScriptDomDllPath)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$pin='459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
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
