param([Parameter(Mandatory=$true)][string]$BinaryPath,[Parameter(Mandatory=$true)][string]$ExpectedSha256,
 [Parameter(Mandatory=$true)][string]$EvidencePath,[string]$CorePath,[string]$ExpectedCoreSha256)
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
# Prospektive 1.3/Core/Schema-Bindungen, anhand der konkreten Source geprüft.
# Collections sind unten zusätzlich auf tatsächliche geschlossene Typen begrenzt.
$closed+=@('System.Collections.Generic.List`1<Toolbelt.JsonCore.JsonToken>',
 'System.Collections.Generic.Dictionary`2<System.String,System.Int32>',
 'System.Collections.Generic.Dictionary`2<System.Int32,System.Collections.Generic.Dictionary`2<System.String,System.Int32>>',
 'System.Collections.Generic.Dictionary`2<System.Int32,System.String>',
 'System.Collections.Generic.Dictionary`2<System.Int32,Toolbelt.JsonSchema.SchemaNode>',
 'System.Collections.Generic.Dictionary`2<System.String,Toolbelt.JsonSchema.ExactJsonNumber>',
 'System.Collections.Generic.Dictionary`2<System.Int32,Toolbelt.JsonSchema.ExactJsonNumber>',
 'System.Collections.Generic.SortedDictionary`2<System.String,System.Int32>',
 'System.Collections.Generic.SortedDictionary`2+Enumerator<System.String,System.Int32>',
 'System.Collections.Generic.KeyValuePair`2<System.String,System.Int32>',
 'System.Collections.Generic.List`1<Toolbelt.JsonSchema.SchemaResultRow>',
 'System.Collections.Generic.List`1+Enumerator<Toolbelt.JsonSchema.SchemaResultRow>',
 'System.Collections.Generic.List`1<Toolbelt.JsonSchema.SchemaEvaluation+EvaluationFrame>',
 'System.Nullable`1<System.Boolean>')
Permit 'System.ArgumentOutOfRangeException' @('System.Void .ctor(System.String)')
$allow['System.String']+=@('System.String Substring(System.Int32,System.Int32)','System.Void .ctor(System.Char[],System.Int32,System.Int32)','System.Int32 IndexOf(System.Char)')
$allow['System.Int32']+=@('System.String ToString(System.IFormatProvider)')
$allow['System.Collections.Generic.List`1']+=@('System.Void .ctor(System.Int32)','System.Int32 get_Capacity()',
 'System.Void set_Capacity(System.Int32)','System.Void set_Item(System.Int32,!0)',
 'System.Void RemoveAt(System.Int32)','System.Collections.ObjectModel.ReadOnlyCollection`1<!0> AsReadOnly()')
Permit 'System.Collections.Generic.Dictionary`2' @('System.Void .ctor(System.Int32)',
 'System.Void .ctor(System.Int32,System.Collections.Generic.IEqualityComparer`1<!0>)',
 'System.Void Add(!0,!1)','System.Boolean ContainsKey(!0)','System.Boolean TryGetValue(!0,!1&)',
 '!1 get_Item(!0)','System.Int32 get_Count()')
Permit 'System.Collections.Generic.SortedDictionary`2' @('System.Void .ctor(System.Collections.Generic.IComparer`1<!0>)',
 'System.Void Add(!0,!1)','System.Boolean Remove(!0)','System.Int32 get_Count()',
 'System.Collections.Generic.SortedDictionary`2+Enumerator<!0,!1> GetEnumerator()')
Permit 'System.Collections.Generic.SortedDictionary`2+Enumerator' @('System.Boolean MoveNext()',
 'System.Collections.Generic.KeyValuePair`2<!0,!1> get_Current()','System.Void Dispose()')
Permit 'System.Collections.Generic.KeyValuePair`2' @('!0 get_Key()','!1 get_Value()')
Permit 'System.Nullable`1' @('System.Void .ctor(!0)','System.Boolean get_HasValue()','!0 get_Value()')
$allow['System.Text.Encoding']+=@('System.String GetString(System.Byte[],System.Int32,System.Int32)')
Permit 'System.Text.UTF8Encoding' @('System.Void .ctor(System.Boolean,System.Boolean)')
$allow['System.Data.SqlTypes.SqlChars']+=@('System.Char[] get_Value()','System.Void .ctor(System.Data.SqlTypes.SqlString)')
Permit 'System.Data.SqlTypes.SqlString' @('System.Boolean get_IsNull()','System.String get_Value()',
 'System.Void .ctor(System.String)','System.Data.SqlTypes.SqlString op_Implicit(System.String)')
function Binding([Reflection.MethodBase]$m){$type=$m.DeclaringType;if($type.IsGenericType){$def=$type.GetGenericTypeDefinition();$matches=@($def.GetMembers([Reflection.BindingFlags]'Public,NonPublic,Instance,Static')|Where-Object {$_ -is [Reflection.MethodBase] -and $_.MetadataToken-eq$m.MetadataToken});if($matches.Count-ne1){throw 'IL_GENERIC_BINDING'};$m=$matches[0]};if($m.IsGenericMethod){$m=$m.GetGenericMethodDefinition()};$ret='System.Void';if($m-is[Reflection.MethodInfo]){$ret=Shape $m.ReturnType};return $ret+' '+$m.Name+'('+((@($m.GetParameters()|ForEach-Object{Shape $_.ParameterType}))-join',')+')'}
function Is-MscorlibIdentity([Reflection.Assembly]$assembly){$n=$assembly.GetName();return $n.Name-ceq'mscorlib'-and$n.Version-eq[Version]'4.0.0.0'-and[BitConverter]::ToString($n.GetPublicKeyToken()).Replace('-','').ToLowerInvariant()-ceq'b77a5c561934e089'}
function Is-FrameworkStringBuilder([Type]$type){return $type-eq[Text.StringBuilder]-and(Is-MscorlibIdentity $type.Assembly)}
function Allow-StringBuilderLength([string]$binding,[bool]$frameworkIdentity){return $binding-ceq'System.Text.StringBuilder|System.Int32 get_Length()'-and$frameworkIdentity}
function Allow-StringBuilderReceiver([string]$caller,[bool]$isStatic,[string]$binding,[string]$opcode,[string]$previousOpcode,[int]$localIndex,[string]$localType,[bool]$frameworkIdentity,[int]$callOffset,[int[]]$targets,[int[]]$entries){
 $callerOK=($caller-ceq'Toolbelt.JsonConstructors.JsonCanonicalCore|System.String Escape(System.String)'-and$isStatic)-or($caller-ceq'Toolbelt.JsonConstructors.OwnedAggregateBuilder|System.String Finish()'-and-not$isStatic)
 $callerOK=$callerOK-or($caller-ceq'Toolbelt.JsonCore.JsonTokenDocument|System.Boolean Decode(System.Int32,System.Int32,System.String&,System.Int32&)'-and-not$isStatic)
 $callerOK=$callerOK-or($caller-ceq'Toolbelt.JsonSchema.SchemaTree|System.String Escape(System.String,Toolbelt.JsonCore.JsonWorkBudget)'-and$isStatic)
 $callerOK=$callerOK-or($caller-ceq'Toolbelt.JsonSchema.LocalSchemaReference|System.Int32 Resolve(Toolbelt.JsonSchema.SchemaTree,System.Int32)'-and$isStatic)
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
$record=@{status='FAILED';scope='own product and pinned shared Core calls only';externalBindings=@();unknown=@();frameworkTransitiveSafe=$false};$calls=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$unknown=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
try{
 $coreAsm=$null;if($CorePath){$coreBytes=[IO.File]::ReadAllBytes($CorePath);if((HashBytes $coreBytes)-cne$ExpectedCoreSha256){throw 'IL_CORE_PIN'};$coreAsm=[Reflection.Assembly]::Load($coreBytes);if($coreAsm.GetName().Name-cne'Toolbelt.JsonCore'-or$coreAsm.GetName().Version-ne[Version]'1.0.0.0'){throw 'IL_CORE_IDENTITY'}}
 $bytes=[IO.File]::ReadAllBytes($BinaryPath);if((HashBytes $bytes)-cne$ExpectedSha256){throw 'IL_PIN'};$asm=[Reflection.Assembly]::Load($bytes)
 $identity=$asm.GetName();$expectedVersions=@{'Toolbelt.JsonCore'='1.0.0.0';'Toolbelt.JsonConstructors'='1.3.0.0';'Toolbelt.JsonSchema'='1.0.0.0'}
 if(-not$expectedVersions.ContainsKey($identity.Name)-or$identity.Version.ToString()-cne$expectedVersions[$identity.Name]-or$identity.GetPublicKeyToken().Length-ne0){throw 'IL_PRODUCT_IDENTITY'}
 foreach($r in $asm.GetReferencedAssemblies()){if($r.Name-ceq'Toolbelt.JsonCore'){if(-not$coreAsm-or$r.Version-ne[Version]'1.0.0.0'-or$r.GetPublicKeyToken().Length-ne0){throw 'IL_REFERENCE'}}elseif($r.Name-notin@('mscorlib','System','System.Data')-or$r.Version-ne[Version]'4.0.0.0'-or[BitConverter]::ToString($r.GetPublicKeyToken()).Replace('-','').ToLowerInvariant()-cne'b77a5c561934e089'){throw 'IL_REFERENCE'}}
 $ops=@{};foreach($f in [Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static')){$o=$f.GetValue($null);$ops[([int]$o.Value-band65535)]=$o}
 foreach($type in $asm.GetTypes()){
  if($type.FullName-match'Diagnostic|Witness|Harness'){throw 'IL_DIAGNOSTIC'}
  # Neuer Core und Schema erlauben keinen veränderlichen globalen Produktzustand.
  # SignedDecimalDigits.Zero ist das einzige statische nichtliterale Feld dort.
  if($identity.Name-cne'Toolbelt.JsonConstructors'){
   foreach($field in $type.GetFields([Reflection.BindingFlags]'Public,NonPublic,Static,DeclaredOnly')){
    if($field.IsLiteral){continue}
    if($type.FullName-cne'Toolbelt.JsonSchema.SignedDecimalDigits'-or$field.Name-cne'Zero'-or-not$field.IsInitOnly-or$field.FieldType-ne$type){throw 'IL_MUTABLE_STATIC'}
    foreach($state in $type.GetFields([Reflection.BindingFlags]'Public,NonPublic,Instance,DeclaredOnly')){
     if(-not$state.IsInitOnly-or$state.FieldType-notin@([int],[string])){throw 'IL_MUTABLE_SINGLETON'}
    }
   }
  }
  $methods=@($type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'))+@($type.GetConstructors([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'));if($type.TypeInitializer){$methods+=$type.TypeInitializer}
  foreach($m in $methods){if(($m.Attributes-band[Reflection.MethodAttributes]::PinvokeImpl)-ne0){throw 'IL_PINVOKE'};$body=$m.GetMethodBody();if(-not$body){continue};$il=$body.GetILAsByteArray();$decoded=Decode-ControlFlow $il $body $ops;$previous=$null
   foreach($clause in $body.ExceptionHandlingClauses){
    if($clause.Flags-eq[Reflection.ExceptionHandlingClauseOptions]::Clause){
     $caught=$clause.CatchType
     $frameworkCatch=($caught.FullName-ceq'System.Text.DecoderFallbackException'-and(Is-MscorlibIdentity $caught.Assembly))
     $legacyBoundary=$identity.Name-ceq'Toolbelt.JsonConstructors'-and$m.DeclaringType.FullName-cin@('Toolbelt.JsonConstructors.JsonArrayAggregate','Toolbelt.JsonConstructors.JsonObjectAggregate','Toolbelt.JsonConstructors.JsonEntryEvaluateBridge')
     $frameworkCatch=$frameworkCatch-or($legacyBoundary-and$caught.FullName-ceq'System.Exception'-and(Is-MscorlibIdentity $caught.Assembly))
     if($caught.Assembly-ne$asm-and$caught.Assembly-ne$coreAsm-and-not$frameworkCatch){throw 'IL_CATCH_TYPE'}
    }
   }
   foreach($instruction in $decoded.Instructions){$at=$instruction.OperandOffset;$op=$instruction.Op;$kind=$instruction.Kind;$size=$instruction.Size
    if($kind-in@('InlineMethod','InlineTok','InlineType','InlineField')){$ga=[Type[]]@();if($m-is[Reflection.MethodInfo]){$ga=$m.GetGenericArguments()};$member=$m.Module.ResolveMember([BitConverter]::ToInt32($il,$at),$type.GetGenericArguments(),$ga);$decl=$member.DeclaringType;if($member-is[Type]){$decl=$member};if($decl-and$decl.Assembly-ne$asm-and$decl.Assembly-ne$coreAsm){
      $shape=Shape $decl;$name=$decl.FullName;if($decl.IsGenericType){if($shape-notin$closed){[void]$unknown.Add('TYPE '+$shape)};$name=$decl.GetGenericTypeDefinition().FullName}
      if($member-is[Reflection.MethodBase]){if($member.IsGenericMethod){foreach($argument in $member.GetGenericArguments()){if((Shape $argument)-notin@('System.Int32','System.Byte[]','Toolbelt.JsonConstructors.VEntry')){[void]$unknown.Add('GENERIC_ARGUMENT '+(Shape $argument))}}};$bind=Binding $member;$entry=$name+'|'+$bind;[void]$calls.Add($entry);$special=$false;if($entry-ceq'System.Object|System.String ToString()'-and$previous){$index=$previous.LocalIndex;$localType='';$localIdentity=$false;if($index-ge0-and$index-lt$body.LocalVariables.Count){$actualLocalType=$body.LocalVariables[$index].LocalType;$localType=Shape $actualLocalType;$localIdentity=Is-FrameworkStringBuilder $actualLocalType};$caller=$m.DeclaringType.FullName+'|'+(Binding $m);$special=Allow-StringBuilderReceiver $caller $m.IsStatic $entry $op.Name $previous.Op.Name $index $localType ((Is-MscorlibIdentity $decl.Assembly)-and$localIdentity) $instruction.Offset @($decoded.Targets) @($decoded.Entries)};if($entry-ceq'System.Text.StringBuilder|System.Int32 get_Length()'){$special=Allow-StringBuilderLength $entry (Is-MscorlibIdentity $decl.Assembly)};if(-not$special-and(-not$allow.ContainsKey($name)-or$bind-notin$allow[$name])){[void]$unknown.Add($entry)}}
      elseif($member-is[Reflection.FieldInfo]){$field=$shape+'|'+(Shape $member.FieldType)+' '+$member.Name;$fields=@('System.BitConverter|System.Boolean IsLittleEndian','System.String|System.String Empty','System.Data.SqlTypes.SqlChars|System.Data.SqlTypes.SqlChars Null','System.Data.SqlTypes.SqlInt64|System.Data.SqlTypes.SqlInt64 Null','System.Data.SqlTypes.SqlBoolean|System.Data.SqlTypes.SqlBoolean Null','System.Data.SqlTypes.SqlString|System.Data.SqlTypes.SqlString Null');if($field-notin$fields){[void]$unknown.Add('FIELD '+$field)}}
      elseif($member-is[Type]){$exactType=(Is-MscorlibIdentity $decl.Assembly)-and$kind-ceq'InlineType'-and(($shape-ceq'System.Boolean'-and$op.Name-ceq'newarr')-or($shape-ceq'System.Byte[]'-and$op.Name-in@('newarr','castclass'))-or($shape-ceq'System.Int32[]'-and$op.Name-ceq'castclass'));if(-not$exactType-and$name-notin@('System.Char','System.Byte','System.Int32','System.IO.InvalidDataException','System.IO.EndOfStreamException')-and-not$allow.ContainsKey($name)){[void]$unknown.Add('TYPE '+$shape)}}
    }};$previous=$instruction
   }
  }
 }
 $record.externalBindings=@($calls|Sort-Object);$record.unknown=@($unknown|Sort-Object);if($unknown.Count){throw 'IL_UNKNOWN_BINDING'};if((HashBytes ([IO.File]::ReadAllBytes($BinaryPath)))-cne$ExpectedSha256){throw 'IL_POSTPIN'};if($coreAsm-and(HashBytes ([IO.File]::ReadAllBytes($CorePath)))-cne$ExpectedCoreSha256){throw 'IL_CORE_POSTPIN'};$record.status='PASS'
}catch{$record.failure='PRODUCT_IL_FAILED';if($_.Exception.Message-cmatch'^IL_[A-Z_]+$'){$record.failure=$_.Exception.Message}}finally{[IO.File]::WriteAllText($EvidencePath,($record|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))}
if($record.status-ne'PASS'){[Console]::WriteLine('FAIL JSON_SHARED_PRODUCT_IL');exit 1};[Console]::WriteLine('PASS JSON_SHARED_PRODUCT_IL');exit 0
