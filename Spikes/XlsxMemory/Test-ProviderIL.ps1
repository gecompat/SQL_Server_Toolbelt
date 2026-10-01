param([string]$BinaryDirectory = (Join-Path $PSScriptRoot 'bin/Release'))
$ErrorActionPreference = 'Stop'
# Nur eigene Providerbinaries. Kein Anspruch auf Prüfung sämtlicher Framework-
# Implementierungen; deren Zugriffsgrenze wird separat adversarial qualifiziert.
$opcodes = @{}
foreach ($field in [Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static')) {
    $op = $field.GetValue($null); $opcodes[[int]$op.Value -band 65535] = $op
}
foreach ($file in @('Toolbelt.Archive.ZipMemory.dll','Toolbelt.File.XlsxMemory.dll','Toolbelt.Xlsx.Qualification.dll')) {
    $assembly = [Reflection.Assembly]::LoadFrom((Join-Path $BinaryDirectory $file))
    foreach ($reference in $assembly.GetReferencedAssemblies()) {
        if ($reference.Name -notin @('mscorlib','System','System.Data','System.Xml','Toolbelt.Archive.ZipMemory','Toolbelt.File.XlsxMemory')) { throw 'Unerwartete Provider-Assemblyreferenz.' }
    }
    foreach ($type in $assembly.GetTypes()) {
        $methods = @($type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly')) + @($type.GetConstructors([Reflection.BindingFlags]'Public,NonPublic,Instance,Static,DeclaredOnly'))
        if ($type.TypeInitializer) { $methods += $type.TypeInitializer }
        foreach ($method in $methods) {
            if (($method.Attributes -band [Reflection.MethodAttributes]::PinvokeImpl) -ne 0) { throw 'Provider enthält P/Invoke.' }
            $body = $method.GetMethodBody(); if (-not $body) { continue }
            $il = $body.GetILAsByteArray(); $position = 0
            while ($position -lt $il.Length) {
                $value = [int]$il[$position++]; if ($value -eq 254) { $value = 65024 + [int]$il[$position++] }
                if (-not $opcodes.ContainsKey($value)) { throw ('Unbekannter IL-Opcode {0} in {1}.{2} bei {3}.' -f $value,$type.Name,$method.Name,$position) }
                $op = $opcodes[$value]; $size = 0
                if ($op.Name -eq 'calli' -or $op.OperandType.ToString() -eq 'InlineSig') { throw 'Indirekter Provider-Aufruf ist nicht erlaubt.' }
                switch ($op.OperandType.ToString()) {
                    'InlineNone' { $size = 0 }
                    {$_ -in 'ShortInlineBrTarget','ShortInlineI','ShortInlineVar'} { $size = 1 }
                    'InlineVar' { $size = 2 }
                    {$_ -in 'InlineI8','InlineR'} { $size = 8 }
                    'InlineSwitch' { $size = 4 + 4 * [BitConverter]::ToInt32($il,$position) }
                    default { $size = 4 }
                }
                if ($position + $size -gt $il.Length) { throw 'Unvollständiges IL-Operand.' }
                if ($op.OperandType.ToString() -in @('InlineMethod','InlineTok','InlineType','InlineField')) {
                    $genericMethods = [Type[]]@()
                    if ($method -is [Reflection.MethodInfo]) { $genericMethods = $method.GetGenericArguments() }
                    $member = $method.Module.ResolveMember([BitConverter]::ToInt32($il,$position),$type.GetGenericArguments(),$genericMethods)
                    $declaring = $member.DeclaringType
                    if ($member -is [Type]) { $declaring = $member }
                    if ($declaring) {
                        $name = $declaring.FullName
                        if ($name -eq 'System.Xml.XmlReader' -and $member.Name -eq 'Create' -and
                            $member.GetParameters()[0].ParameterType.FullName -ne 'System.IO.Stream') { throw 'XmlReader.Create ist ausschließlich mit Stream erlaubt.' }
                        $namespace = $declaring.Namespace
                        $simpleSystem = @('Object','String','StringComparer','StringComparison','Array','Buffer','BitConverter','Convert','DateTime','TimeSpan','Math','Decimal','Boolean','Byte','Char','Int16','Int32','Int64','UInt16','UInt32','UInt64','Double','Single','Exception','ArgumentException','ArgumentNullException','InvalidOperationException','NotSupportedException','OverflowException','IDisposable','Nullable`1','Action','Action`1','Func`1','Comparison`1','Delegate','Type','Enum')
                        $allowedNamespaces = @('Toolbelt.Archive.ZipMemory','Toolbelt.Xlsx.Qualification','System.Collections','System.Collections.Generic','System.Text','System.Globalization','System.Data.SqlTypes','Microsoft.SqlServer.Server')
                        $special = $name -eq 'System.Diagnostics.Stopwatch' -or $name -eq 'System.Runtime.CompilerServices.RuntimeHelpers' -or
                            $name -in @('System.Xml.XmlReader','System.Xml.XmlReaderSettings','System.Xml.XmlNodeType','System.Xml.DtdProcessing','System.Xml.XmlException')
                        if ($namespace -notin $allowedNamespaces -and -not ($namespace -eq 'System' -and $declaring.Name -in $simpleSystem) -and
                            -not $special -and $namespace -notin @('System.IO','System.IO.Compression')) { throw ('Provider-API außerhalb der Allowlist: ' + $name) }
                        if ($name -match '^System\.(Net\.|Reflection\.|Threading\.|Runtime\.InteropServices\.|Security\.)' -or
                            $name -match '^System\.Diagnostics\.' -and $name -ne 'System.Diagnostics.Stopwatch') { throw 'Nicht erlaubter Provider-API-Namespace.' }
                        if ($name -match '^System\.IO\.' -and $name -notin @('System.IO.Stream','System.IO.MemoryStream','System.IO.BinaryReader','System.IO.BinaryWriter','System.IO.InvalidDataException','System.IO.EndOfStreamException','System.IO.IOException','System.IO.Compression.DeflateStream','System.IO.Compression.CompressionMode')) { throw 'Nicht erlaubte I/O-API im Provider.' }
                    }
                }
                $position += $size
            }
        }
    }
}
'PASS: own provider IL/reference allowlist, no P/Invoke/File/Network/Process/IsolatedStorage APIs. Framework transitive behavior remains separately scoped.'
