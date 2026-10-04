param([Parameter(Mandatory=$true)][string]$BinaryDirectory,[Parameter(Mandatory=$true)][string]$ExpectationsPath)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$spec=Get-Content -LiteralPath $ExpectationsPath -Raw|ConvertFrom-Json
$zip=[Reflection.Assembly]::LoadFrom((Join-Path $BinaryDirectory 'Toolbelt.Archive.ZipMemory.dll'))
$a=[Reflection.Assembly]::LoadFrom((Join-Path $BinaryDirectory 'Toolbelt.File.XlsxMemory.dll'))
if($a.GetName().Name-cne$spec.AssemblyName-or$a.GetName().Version.ToString()-cne$spec.Version-or$zip.GetName().Version.ToString()-cne$spec.ZipVersion){throw 'METADATA_ASSEMBLY'}
function Shape([Type]$t){if($t.IsByRef){return 'out:'+(Shape $t.GetElementType())};$map=@{'System.Object'='object';'System.DateTime'='DateTime';'System.TimeSpan'='TimeSpan'};if($t.IsGenericType-and$t.GetGenericTypeDefinition()-eq[Nullable``1]){return (Shape $t.GetGenericArguments()[0])+'?'};if($map.ContainsKey($t.FullName)){return $map[$t.FullName]};if($t.Namespace-ceq'System.Data.SqlTypes'){return $t.Name};return $t.FullName}
$found=0
foreach($t in $a.GetTypes()){foreach($m in $t.GetMethods([Reflection.BindingFlags]'Public,Static,DeclaredOnly')){if(@($m.GetCustomAttributes($false)|Where-Object {$_.GetType().FullName-ceq'Microsoft.SqlServer.Server.SqlFunctionAttribute'}).Count){$found++}}}
if($found-ne4-or@($spec.ClrSlots).Count-ne4-or@($spec.PublicSQLObjects).Count-ne9){throw 'METADATA_SLOT_COUNT'}
foreach($e in $spec.ClrSlots){
 $t=$a.GetType($e.Type,$true);$m=$t.GetMethod($e.Method,[Reflection.BindingFlags]'Public,Static');if(-not$m-or$m.ReturnType-ne[Collections.IEnumerable]){throw 'METADATA_METHOD'}
 $p=@($m.GetParameters());if($p.Count-ne@($e.Parameters).Count){throw 'METADATA_PARAMETERS'};for($i=0;$i-lt$p.Count;$i++){if((Shape $p[$i].ParameterType)-cne$e.Parameters[$i]){throw 'METADATA_PARAMETER_TYPE'}}
 $attrs=@($m.GetCustomAttributes($false)|Where-Object {$_.GetType().FullName-ceq'Microsoft.SqlServer.Server.SqlFunctionAttribute'});if($attrs.Count-ne1){throw 'METADATA_ATTRIBUTE_COUNT'};$att=$attrs[0]
 if($att.FillRowMethodName-cne$e.Fill-or$att.TableDefinition-cne$e.TableDefinition-or$att.DataAccess.ToString()-cne'None'-or$att.SystemDataAccess.ToString()-cne'None'-or$att.IsDeterministic-ne$e.Deterministic-or$att.IsPrecise-ne$e.Precise){throw 'METADATA_ATTRIBUTE'}
 $f=$t.GetMethod($e.Fill,[Reflection.BindingFlags]'Public,Static');if(-not$f-or$f.ReturnType-ne[void]){throw 'METADATA_FILL_VOID'};$fp=@($f.GetParameters());if($fp.Count-ne@($e.FillParameters).Count){throw 'METADATA_FILL_COUNT'}
 for($i=0;$i-lt$fp.Count;$i++){if((Shape $fp[$i].ParameterType)-cne$e.FillParameters[$i]-or($i-gt0-and-not$fp[$i].IsOut)){throw 'METADATA_FILL_TYPE'}}
}
'PASS METADATA CLR_SLOTS=4 SQL_SOURCES=9 SQL_EXECUTED=FALSE'
