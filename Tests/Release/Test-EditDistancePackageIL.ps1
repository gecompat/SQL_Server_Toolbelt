[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$assembly=[Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
if($assembly.GetName().Name-cne'Toolbelt.String.EditDistance'-or$assembly.GetName().Version.ToString()-cne'1.1.0.0'){
 throw 'EDIT_DISTANCE_IL_ASSEMBLY_IDENTITY'
}
$references=@($assembly.GetReferencedAssemblies()|ForEach-Object {$_.Name}|Sort-Object -Unique)
if((@($references|Where-Object {$_-notin@('mscorlib','System','System.Data')})).Count-ne0){
 throw 'EDIT_DISTANCE_IL_ASSEMBLY_REFERENCE'
}

$ops=@{}
foreach($field in [Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static')){
 $opcode=$field.GetValue($null);$ops[[int]$opcode.Value-band65535]=$opcode
}
$methodCount=0
foreach($type in $assembly.GetTypes()){
 $methods=@($type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'))+
  @($type.GetConstructors([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'))
 if($type.TypeInitializer){$methods+=$type.TypeInitializer}
 foreach($method in $methods){
  $methodCount++
  if(($method.Attributes-band[Reflection.MethodAttributes]::PinvokeImpl)-ne0){throw 'EDIT_DISTANCE_IL_PINVOKE'}
  $body=$method.GetMethodBody();if(-not$body){continue}
  $il=$body.GetILAsByteArray();$position=0
  while($position-lt$il.Length){
   $value=[int]$il[$position++]
   if($value-eq254){if($position-ge$il.Length){throw 'EDIT_DISTANCE_IL_OPERAND'};$value=65024+[int]$il[$position++]}
   if(-not$ops.ContainsKey($value)){throw 'EDIT_DISTANCE_IL_OPCODE'}
   $opcode=$ops[$value];$kind=$opcode.OperandType.ToString();$size=0
   if($opcode.Name-eq'calli'-or$kind-eq'InlineSig'){throw 'EDIT_DISTANCE_IL_INDIRECT'}
   switch($kind){
    'InlineNone'{$size=0}
    {$_-in@('ShortInlineBrTarget','ShortInlineI','ShortInlineVar')}{$size=1}
    'InlineVar'{$size=2}
    {$_-in@('InlineI8','InlineR')}{$size=8}
    'InlineSwitch'{if($position+4-gt$il.Length){throw 'EDIT_DISTANCE_IL_OPERAND'};$size=4+4*[BitConverter]::ToInt32($il,$position)}
    default{$size=4}
   }
   if($position+$size-gt$il.Length){throw 'EDIT_DISTANCE_IL_OPERAND'}
   if($kind-in@('InlineMethod','InlineTok','InlineType','InlineField')){
    $genericMethods=[Type[]]@();if($method-is[Reflection.MethodInfo]){$genericMethods=$method.GetGenericArguments()}
    try{$member=$method.Module.ResolveMember([BitConverter]::ToInt32($il,$position),$type.GetGenericArguments(),$genericMethods)}
    catch{throw 'EDIT_DISTANCE_IL_MEMBER_RESOLUTION'}
    $declaring=$member.DeclaringType;if($member-is[Type]){$declaring=$member}
    if($declaring){$name=$declaring.FullName
     if($name-match'^System\.(IO|Net|Reflection|Threading|Security|Diagnostics|Runtime\.InteropServices|Runtime\.Loader|Runtime\.Remoting|Configuration|Management)(\.|$)'-or
        $name-in@('System.Environment','System.AppDomain','System.Activator','System.Console','System.GC')-or
        $name-match'^Microsoft\.Win32(\.|$)'){
      throw 'EDIT_DISTANCE_IL_FORBIDDEN_API'
     }
    }
   }
   $position+=$size
  }
 }
}
if($methodCount-eq0){throw 'EDIT_DISTANCE_IL_EMPTY'}
"PASS EDIT_DISTANCE_IL_INSPECTION METHODS=$methodCount REFERENCES=$($references.Count)"
