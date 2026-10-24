[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$assembly=(Resolve-Path -LiteralPath $AssemblyPath).Path
Add-Type -Path $assembly
$source=Join-Path $PSScriptRoot '../Framework/ReplaceMaterialization.Contract.cs'
Add-Type -TypeDefinition ([IO.File]::ReadAllText($source)) -ReferencedAssemblies @('System.dll','System.Data.dll','System.Xml.dll',$assembly)
if([ReplaceMaterializationContract]::Check() -ne 7){throw 'REPLACE_MATERIALIZATION_INCOMPLETE'}

# Die Optimierung darf weder Größen- noch Zeitbudgets verändern.
$type=[Toolbelt.String.Regex.RegexProvider].GetNestedType('TransformationContext',[Reflection.BindingFlags]::NonPublic)
$flags=[Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic
foreach($profile in @('standard','large')){
 $context=[Activator]::CreateInstance($type,$flags,$null,[object[]]@([Data.SqlTypes.SqlString]::new($profile)),$null)
 $expectedBudget=if($profile -ceq 'standard'){500}else{2000}
 $expectedLimit=if($profile -ceq 'standard'){1048576}else{8388608}
 if($type.GetField('Budget',$flags).GetValue($context) -ne $expectedBudget -or
    $type.GetField('Limit',$flags).GetValue($context) -ne $expectedLimit){throw 'REGEX_SAFETY_BUDGET_CHANGED'}
 $type.GetMethod('ValidateFlags',$flags).Invoke($context,[object[]]@([Data.SqlTypes.SqlString]::new('c')))|Out-Null
 $type.GetMethod('Initialize',$flags).Invoke($context,[object[]]@('x'))|Out-Null
 if($type.GetField('regexTimeout',$flags).GetValue($context) -gt 250){throw 'REGEX_SEARCH_BUDGET_CHANGED'}
}
'PASS REGEX_REPLACE_MATERIALIZATION seven byte/alias/semantic cases; standard/large and search safety limits unchanged'
