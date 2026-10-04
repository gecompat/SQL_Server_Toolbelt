param([Parameter(Mandatory=$true)][string]$BinaryPath,[Parameter(Mandatory=$true)][string]$ExpectedSha256,[Parameter(Mandatory=$true)][string]$EvidencePath)
$ErrorActionPreference='Stop'
# Eigene Produktcalls; keine transitive Framework-/SAFE-Zulassung. Unbekannte Bindung blockiert.
function HashBytes([byte[]]$bytes){$h=[Security.Cryptography.SHA256]::Create();try{return ([BitConverter]::ToString($h.ComputeHash($bytes))).Replace('-','')}finally{$h.Dispose()}}
function Shape([Type]$t){if($t.IsByRef){return (Shape $t.GetElementType())+'&'};if($t.IsArray){return (Shape $t.GetElementType())+'[]'};if($t.IsGenericParameter){return '!'+$t.GenericParameterPosition};if($t.IsGenericType){return $t.GetGenericTypeDefinition().FullName+'<'+((@($t.GetGenericArguments()|ForEach-Object{Shape $_}))-join',')+'>'};return $t.FullName}
# Klassenbindungen sind konkrete, endliche Instanzen; keine beliebigen Product- oder Reflectionargumente.
$closed=@('System.Collections.Generic.List`1<System.Byte[]>','System.Collections.Generic.List`1<Toolbelt.JsonConstructors.VEntry>','System.Collections.Generic.List`1<System.Int32>','System.Collections.Generic.SortedSet`1<System.Int32>','System.Collections.Generic.SortedSet`1<System.Byte[]>','System.Collections.Generic.IComparer`1<System.Byte[]>','System.Collections.Generic.IComparer`1<Toolbelt.JsonConstructors.VEntry>','System.Collections.Generic.Comparison`1<System.Byte[]>','System.Comparison`1<Toolbelt.JsonConstructors.VEntry>','System.Collections.Generic.List`1+Enumerator<System.Byte[]>','System.Collections.Generic.List`1+Enumerator<Toolbelt.JsonConstructors.VEntry>','System.Collections.Generic.List`1+Enumerator<System.Int32>','System.Collections.Generic.SortedSet`1+Enumerator<System.Int32>','System.Collections.Generic.SortedSet`1+Enumerator<System.Byte[]>')
# Vollständige Return-/Parameterformen. !0 ist ausschließlich die oben geschlossene Typinstanz.
$allow=@{}
function Permit([string]$type,[string[]]$bindings){$allow[$type]=$bindings}
Permit 'System.Object' @('System.Void .ctor()','System.Boolean ReferenceEquals(System.Object,System.Object)')
Permit 'System.Array' @('System.Object Clone()','System.Void Copy(System.Array,System.Int32,System.Array,System.Int32,System.Int32)','System.Void Copy(System.Array,System.Array,System.Int32)','System.Void Sort(System.Array)','System.Void Sort(!0[])','System.Void Sort(System.Array,System.Collections.IComparer)','System.Int32 BinarySearch(System.Array,System.Object)','System.Void Sort(!0[],System.Collections.Generic.IComparer`1<!0>)','System.Void Sort(!0[],System.Comparison`1<!0>)','System.Int32 BinarySearch(!0[],!0)','System.Int32 BinarySearch(!0[],!0,System.Collections.Generic.IComparer`1<!0>)')
Permit 'System.String' @('System.Void .ctor(System.Char[])','System.Char get_Chars(System.Int32)','System.Int32 get_Length()','System.Boolean op_Equality(System.String,System.String)','System.Boolean op_Inequality(System.String,System.String)','System.String Concat(System.String,System.String)','System.String Concat(System.String,System.String,System.String)','System.String Concat(System.String,System.String,System.String,System.String)','System.Char[] ToCharArray()','System.Int32 IndexOf(System.String,System.StringComparison)')
Permit 'System.Char' @('System.Boolean IsHighSurrogate(System.Char)','System.Boolean IsLowSurrogate(System.Char)')
Permit 'System.Math' @('System.Int32 Max(System.Int32,System.Int32)','System.Int32 Min(System.Int32,System.Int32)','System.Int64 Min(System.Int64,System.Int64)')
Permit 'System.Int32' @('System.Int32 CompareTo(System.Int32)','System.String ToString(System.String,System.IFormatProvider)')
Permit 'System.Byte' @('System.Int32 CompareTo(System.Byte)')
Permit 'System.Int64' @('System.Int32 CompareTo(System.Int64)')
Permit 'System.BitConverter' @('System.Int32 ToInt32(System.Byte[],System.Int32)')
Permit 'System.IDisposable' @('System.Void Dispose()')
Permit 'System.Exception' @('System.Void .ctor()','System.Void .ctor(System.String)')
foreach($type in @('System.InvalidOperationException','System.ArgumentException','System.ArgumentNullException')){Permit $type @('System.Void .ctor(System.String)')}
Permit 'System.NotSupportedException' @('System.Void .ctor()')
Permit 'System.IO.Stream' @('System.Void .ctor()','System.Int32 Read(System.Byte[],System.Int32,System.Int32)','System.Void Write(System.Byte[],System.Int32,System.Int32)','System.Void Dispose(System.Boolean)','System.Void Dispose()')
Permit 'System.IO.MemoryStream' @('System.Void .ctor()','System.Void .ctor(System.Byte[])','System.Byte[] ToArray()','System.Void Dispose()')
Permit 'System.IO.BinaryReader' @('System.Void .ctor(System.IO.Stream)','System.Byte[] ReadBytes(System.Int32)','System.Byte ReadByte()','System.UInt16 ReadUInt16()','System.UInt32 ReadUInt32()','System.Int32 ReadInt32()','System.Int64 ReadInt64()','System.IO.Stream get_BaseStream()','System.Void Dispose()')
Permit 'System.IO.BinaryWriter' @('System.Void .ctor(System.IO.Stream,System.Text.Encoding,System.Boolean)','System.Void Write(System.Byte[])','System.Void Write(System.UInt16)','System.Void Write(System.Int64)','System.Void Write(System.Byte)','System.Void Write(System.UInt32)','System.Void Write(System.Int32)','System.Void Flush()','System.Void Dispose()')
Permit 'System.Security.Cryptography.SHA256' @('System.Security.Cryptography.SHA256 Create()')
Permit 'System.Security.Cryptography.HashAlgorithm' @('System.Byte[] ComputeHash(System.Byte[])','System.Int32 TransformBlock(System.Byte[],System.Int32,System.Int32,System.Byte[],System.Int32)','System.Byte[] TransformFinalBlock(System.Byte[],System.Int32,System.Int32)','System.Byte[] get_Hash()','System.Void Dispose()')
Permit 'System.Text.Encoding' @('System.Text.Encoding get_UTF8()')
Permit 'System.Text.StringBuilder' @('System.Void .ctor()','System.Void .ctor(System.Int32)','System.Text.StringBuilder Append(System.Char)','System.Text.StringBuilder Append(System.String)','System.String ToString()')
Permit 'System.Globalization.CultureInfo' @('System.Globalization.CultureInfo get_InvariantCulture()')
Permit 'System.Runtime.CompilerServices.RuntimeHelpers' @('System.Void InitializeArray(System.Array,System.RuntimeFieldHandle)')
Permit 'System.Collections.Generic.List`1' @('System.Void .ctor()','System.Void Add(!0)','!0[] ToArray()','System.Void Clear()','System.Int32 get_Count()','!0 get_Item(System.Int32)','System.Collections.Generic.List`1+Enumerator<!0> GetEnumerator()')
Permit 'System.Collections.Generic.List`1+Enumerator' @('System.Boolean MoveNext()','!0 get_Current()','System.Void Dispose()')
Permit 'System.Collections.Generic.SortedSet`1' @('System.Void .ctor()','System.Void .ctor(System.Collections.Generic.IComparer`1<!0>)','System.Boolean Add(!0)','System.Void Clear()','System.Int32 get_Count()','System.Void CopyTo(!0[])','System.Boolean Contains(!0)','System.Collections.Generic.SortedSet`1+Enumerator<!0> GetEnumerator()')
Permit 'System.Collections.Generic.SortedSet`1+Enumerator' @('System.Boolean MoveNext()','!0 get_Current()','System.Void Dispose()')
Permit 'System.Comparison`1' @('System.Void .ctor(System.Object,System.IntPtr)')
Permit 'System.Collections.Generic.IComparer`1' @('System.Int32 Compare(!0,!0)')
foreach($t in @('SqlInt32','SqlInt64','SqlByte','SqlBoolean')){$v=@{SqlInt32='System.Int32';SqlInt64='System.Int64';SqlByte='System.Byte';SqlBoolean='System.Boolean'}[$t];Permit ('System.Data.SqlTypes.'+$t) @(('System.Void .ctor('+$v+')'),'System.Boolean get_IsNull()',($v+' get_Value()'))}
Permit 'System.Data.SqlTypes.SqlChars' @('System.Void .ctor(System.Char[])','System.Data.SqlTypes.SqlChars get_Null()','System.Boolean get_IsNull()','System.Int64 get_Length()','System.Int64 Read(System.Int64,System.Char[],System.Int32,System.Int32)')
Permit 'Microsoft.SqlServer.Server.IBinarySerialize' @('System.Void Read(System.IO.BinaryReader)','System.Void Write(System.IO.BinaryWriter)')
function Binding([Reflection.MethodBase]$m){$type=$m.DeclaringType;if($type.IsGenericType){$def=$type.GetGenericTypeDefinition();$matches=@($def.GetMembers([Reflection.BindingFlags]'Public,NonPublic,Instance,Static')|Where-Object {$_ -is [Reflection.MethodBase] -and $_.MetadataToken-eq$m.MetadataToken});if($matches.Count-ne1){throw 'IL_GENERIC_BINDING'};$m=$matches[0]};if($m.IsGenericMethod){$m=$m.GetGenericMethodDefinition()};$ret='System.Void';if($m-is[Reflection.MethodInfo]){$ret=Shape $m.ReturnType};return $ret+' '+$m.Name+'('+((@($m.GetParameters()|ForEach-Object{Shape $_.ParameterType}))-join',')+')'}
function Is-MscorlibIdentity([Reflection.Assembly]$assembly){$n=$assembly.GetName();return $n.Name-ceq'mscorlib'-and$n.Version-eq[Version]'4.0.0.0'-and[BitConverter]::ToString($n.GetPublicKeyToken()).Replace('-','').ToLowerInvariant()-ceq'b77a5c561934e089'}
function Is-FrameworkStringBuilder([Type]$type){return $type-eq[Text.StringBuilder]-and(Is-MscorlibIdentity $type.Assembly)}
function Allow-StringBuilderLength([string]$binding,[bool]$frameworkIdentity){return $binding-ceq'System.Text.StringBuilder|System.Int32 get_Length()'-and$frameworkIdentity}
function Allow-StringBuilderReceiver([string]$caller,[bool]$isStatic,[string]$binding,[string]$opcode,[string]$previousOpcode,[int]$localIndex,[string]$localType,[bool]$frameworkIdentity,[int]$callOffset,[int[]]$targets,[int[]]$entries){
 $callerOK=($caller-ceq'Toolbelt.JsonConstructors.JsonCanonicalCore|System.String Escape(System.String)'-and$isStatic)-or($caller-ceq'Toolbelt.JsonConstructors.OwnedAggregateBuilder|System.String Finish()'-and-not$isStatic)
 return $callerOK-and$binding-ceq'System.Object|System.String ToString()'-and$opcode-ceq'callvirt'-and$previousOpcode-in@('ldloc.0','ldloc.1','ldloc.2','ldloc.3','ldloc','ldloc.s')-and$localIndex-ge0-and$localType-ceq'System.Text.StringBuilder'-and$frameworkIdentity-and$callOffset-notin$targets-and$callOffset-notin$entries
}
function Decode-ControlFlow([byte[]]$il,$body,$ops){
 $instructions=[Collections.Generic.List[object]]::new();$boundaries=[Collections.Generic.HashSet[int]]::new();$targets=[Collections.Generic.HashSet[int]]::new();$entries=[Collections.Generic.HashSet[int]]::new();$at=0
 while($at-lt$il.Length){$offset=$at;[void]$boundaries.Add($offset);$v=[int]$il[$at++];if($v-eq254){if($at-ge$il.Length){throw 'IL_OPERAND'};$v=65024+[int]$il[$at++]};if(-not$ops.ContainsKey($v)){throw 'IL_OPCODE'};$op=$ops[$v];$kind=$op.OperandType.ToString();if($op.Name-eq'calli'-or$kind-eq'InlineSig'){throw 'IL_INDIRECT'};$size=4L
  switch($kind){'InlineNone'{$size=0};{$_-in@('ShortInlineBrTarget','ShortInlineI','ShortInlineVar')}{$size=1};'InlineVar'{$size=2};{$_-in@('InlineI8','InlineR')}{$size=8};'InlineSwitch'{if($at+4-gt$il.Length){throw 'IL_OPERAND'};$count=[BitConverter]::ToInt32($il,$at);if($count-lt0){throw 'IL_OPERAND'};$size=4+4L*$count}}
  if($size-lt0-or$at+$size-gt$il.Length){throw 'IL_OPERAND'};$next=[long]$at+$size
  if($kind-eq'ShortInlineBrTarget'){$relative=[int]$il[$at];if($relative-ge128){$relative-=256};$target=$next+$relative;if($target-lt0-or$target-ge$il.Length){throw 'IL_BRANCH_TARGET'};[void]$targets.Add([int]$target)}
  elseif($kind-eq'InlineBrTarget'){$target=$next+[BitConverter]::ToInt32($il,$at);if($target-lt0-or$target-ge$il.Length){throw 'IL_BRANCH_TARGET'};[void]$targets.Add([int]$target)}
  elseif($kind-eq'InlineSwitch'){for($i=0;$i-lt$count;$i++){$target=$next+[BitConverter]::ToInt32($il,$at+4+4*$i);if($target-lt0-or$target-ge$il.Length){throw 'IL_BRANCH_TARGET'};[void]$targets.Add([int]$target)}}
  $localIndex=-1;switch($op.Name){'ldloc.0'{$localIndex=0};'ldloc.1'{$localIndex=1};'ldloc.2'{$localIndex=2};'ldloc.3'{$localIndex=3};'ldloc.s'{$localIndex=[int]$il[$at]};'ldloc'{$localIndex=[BitConverter]::ToUInt16($il,$at)}}
  $instructions.Add([pscustomobject]@{Offset=$offset;OperandOffset=$at;Op=$op;Kind=$kind;Size=[int]$size;LocalIndex=$localIndex});$at=[int]$next
 }
 foreach($target in $targets){if(-not$boundaries.Contains($target)){throw 'IL_BRANCH_BOUNDARY'}}
 foreach($clause in $body.ExceptionHandlingClauses){[void]$entries.Add($clause.HandlerOffset);if($clause.Flags-eq[Reflection.ExceptionHandlingClauseOptions]::Filter){[void]$entries.Add($clause.FilterOffset)}}
 foreach($entry in $entries){if(-not$boundaries.Contains($entry)){throw 'IL_EXCEPTION_ENTRY'}}
 return [pscustomobject]@{Instructions=$instructions;Targets=@($targets);Entries=@($entries)}
}
$record=@{status='FAILED';scope='own product IL only';externalBindings=@();unknown=@();frameworkTransitiveSafe=$false};$calls=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$unknown=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
try{
 $bytes=[IO.File]::ReadAllBytes($BinaryPath);if((HashBytes $bytes)-cne$ExpectedSha256){throw 'IL_PIN'};$asm=[Reflection.Assembly]::Load($bytes)
 foreach($r in $asm.GetReferencedAssemblies()){if($r.Name-notin@('mscorlib','System','System.Data')-or$r.Version-ne[Version]'4.0.0.0'){throw 'IL_REFERENCE'}}
 $ops=@{};foreach($f in [Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static')){$o=$f.GetValue($null);$ops[([int]$o.Value-band65535)]=$o}
 foreach($type in $asm.GetTypes()){
  if($type.FullName-match'Diagnostic|Witness|Harness'){throw 'IL_DIAGNOSTIC'}
  $methods=@($type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'))+@($type.GetConstructors([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'));if($type.TypeInitializer){$methods+=$type.TypeInitializer}
  foreach($m in $methods){if(($m.Attributes-band[Reflection.MethodAttributes]::PinvokeImpl)-ne0){throw 'IL_PINVOKE'};$body=$m.GetMethodBody();if(-not$body){continue};$il=$body.GetILAsByteArray();$decoded=Decode-ControlFlow $il $body $ops;$previous=$null
   foreach($instruction in $decoded.Instructions){$at=$instruction.OperandOffset;$op=$instruction.Op;$kind=$instruction.Kind;$size=$instruction.Size
    if($kind-in@('InlineMethod','InlineTok','InlineType','InlineField')){$ga=[Type[]]@();if($m-is[Reflection.MethodInfo]){$ga=$m.GetGenericArguments()};$member=$m.Module.ResolveMember([BitConverter]::ToInt32($il,$at),$type.GetGenericArguments(),$ga);$decl=$member.DeclaringType;if($member-is[Type]){$decl=$member};if($decl-and$decl.Assembly-ne$asm){
      $shape=Shape $decl;$name=$decl.FullName;if($decl.IsGenericType){if($shape-notin$closed){[void]$unknown.Add('TYPE '+$shape)};$name=$decl.GetGenericTypeDefinition().FullName}
      if($member-is[Reflection.MethodBase]){if($member.IsGenericMethod){foreach($argument in $member.GetGenericArguments()){if((Shape $argument)-notin@('System.Int32','System.Byte[]','Toolbelt.JsonConstructors.VEntry')){[void]$unknown.Add('GENERIC_ARGUMENT '+(Shape $argument))}}};$bind=Binding $member;$entry=$name+'|'+$bind;[void]$calls.Add($entry);$special=$false;if($entry-ceq'System.Object|System.String ToString()'-and$previous){$index=$previous.LocalIndex;$localType='';$localIdentity=$false;if($index-ge0-and$index-lt$body.LocalVariables.Count){$actualLocalType=$body.LocalVariables[$index].LocalType;$localType=Shape $actualLocalType;$localIdentity=Is-FrameworkStringBuilder $actualLocalType};$caller=$m.DeclaringType.FullName+'|'+(Binding $m);$special=Allow-StringBuilderReceiver $caller $m.IsStatic $entry $op.Name $previous.Op.Name $index $localType ((Is-MscorlibIdentity $decl.Assembly)-and$localIdentity) $instruction.Offset @($decoded.Targets) @($decoded.Entries)};if($entry-ceq'System.Text.StringBuilder|System.Int32 get_Length()'){$special=Allow-StringBuilderLength $entry (Is-MscorlibIdentity $decl.Assembly)};if(-not$special-and(-not$allow.ContainsKey($name)-or$bind-notin$allow[$name])){[void]$unknown.Add($entry)}}
      elseif($member-is[Reflection.FieldInfo]){$field=$shape+'|'+(Shape $member.FieldType)+' '+$member.Name;$fields=@('System.BitConverter|System.Boolean IsLittleEndian','System.String|System.String Empty','System.Data.SqlTypes.SqlChars|System.Data.SqlTypes.SqlChars Null','System.Data.SqlTypes.SqlInt64|System.Data.SqlTypes.SqlInt64 Null');if($field-notin$fields){[void]$unknown.Add('FIELD '+$field)}}
      elseif($member-is[Type]){$exactType=(Is-MscorlibIdentity $decl.Assembly)-and$kind-ceq'InlineType'-and(($shape-ceq'System.Boolean'-and$op.Name-ceq'newarr')-or($shape-ceq'System.Byte[]'-and$op.Name-in@('newarr','castclass'))-or($shape-ceq'System.Int32[]'-and$op.Name-ceq'castclass'));if(-not$exactType-and$name-notin@('System.Char','System.Byte','System.Int32','System.IO.InvalidDataException','System.IO.EndOfStreamException')-and-not$allow.ContainsKey($name)){[void]$unknown.Add('TYPE '+$shape)}}
    }};$previous=$instruction
   }
  }
 }
 $record.externalBindings=@($calls|Sort-Object);$record.unknown=@($unknown|Sort-Object);if($unknown.Count){throw 'IL_UNKNOWN_BINDING'};if((HashBytes ([IO.File]::ReadAllBytes($BinaryPath)))-cne$ExpectedSha256){throw 'IL_POSTPIN'};$record.status='PASS'
}catch{$record.failure='PRODUCT_IL_FAILED'}finally{[IO.File]::WriteAllText($EvidencePath,($record|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))}
if($record.status-ne'PASS'){[Console]::WriteLine('FAIL PRODUCT_IL');exit 1};[Console]::WriteLine('PASS PRODUCT_IL');exit 0