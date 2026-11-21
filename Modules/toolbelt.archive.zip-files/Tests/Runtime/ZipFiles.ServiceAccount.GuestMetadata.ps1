param(
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{32}$')][string]$Owner,
    [Parameter(Mandatory)][ValidateSet('Verify', 'Audit')][string]$Action
)

$ErrorActionPreference = 'Stop'
$base = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'Temp')
if ([IO.File]::GetAttributes($base) -band [IO.FileAttributes]::ReparsePoint) {
    throw 'ZIP_GUEST_METADATA_ANCHOR'
}
$root = [IO.Path]::Combine($base, "TbxArchiveMetadata-$Owner")
if ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($root)) -ine $base) {
    throw 'ZIP_GUEST_METADATA_CONTAINMENT'
}

function Test-RootAbsent {
    try {
        $null = [IO.File]::GetAttributes($root)
        return $false
    } catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] {
        return $true
    }
}

if (!(Test-RootAbsent)) { throw 'ZIP_GUEST_METADATA_ROOT_PRESENT' }
if ($Action -eq 'Audit') { return 'PASS_ABSENT' }

$admins = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
$principal = [Security.Principal.WindowsIdentity]::GetCurrent().User
if ($principal.Equals($admins)) { throw 'ZIP_GUEST_METADATA_PRINCIPAL' }
$acl = [Security.AccessControl.DirectorySecurity]::new()
$acl.SetOwner($admins)
$acl.SetAccessRuleProtection($true, $false)
$inherit = [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
foreach ($sid in @($principal, $admins)) {
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
        $sid, 'FullControl', $inherit, 'None', 'Allow'))
}

function Get-SafeRootContents {
    if (!([IO.Directory]::Exists($root)) -or
        ([IO.File]::GetAttributes($root) -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'ZIP_GUEST_METADATA_ROOT_TYPE'
    }
    $contents = @(Get-ChildItem -LiteralPath $root -Force)
    $unexpected = @($contents | Where-Object {
        $_.Name -cnotin @('owner.txt', 'replace.bin') -or $_.PSIsContainer -or
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
    })
    if ($unexpected.Count) { throw 'ZIP_GUEST_METADATA_UNEXPECTED_ENTRY' }
    return $contents
}

function Test-ReplacementMetadata($Contents, $Policy) {
    $rules = @($Policy.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    $matching = @($rules | Where-Object {
        $_.IdentityReference.Equals($principal) -or $_.IdentityReference.Equals($admins)
    })
    $markers = @($Contents | Where-Object Name -CEQ 'owner.txt')
    $replacements = @($Contents | Where-Object { $_.Name -ceq 'replace.bin' -and $_.Length -eq 2 })
    return ($Policy.AreAccessRulesProtected -and $rules.Count -eq 2 -and $matching.Count -eq 2 -and
        $Contents.Count -eq 2 -and $markers.Count -eq 1 -and $replacements.Count -eq 1)
}

$null = [IO.Directory]::CreateDirectory($root, $acl)
$marker = Join-Path $root 'owner.txt'
$replacement = Join-Path $root 'replace.bin'
try {
    $stream = [IO.File]::Open($marker, 'CreateNew')
    try {
        $bytes = [Text.Encoding]::ASCII.GetBytes($Owner)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
    $actual = [IO.Directory]::GetAccessControl($root)
    if (!$actual.GetOwner([Security.Principal.SecurityIdentifier]).Equals($admins) -or
        [IO.File]::ReadAllText($marker) -cne $Owner) { throw 'ZIP_GUEST_METADATA_OWNER' }
    if (Test-ReplacementMetadata @(Get-SafeRootContents) $actual) { throw 'ZIP_GUEST_METADATA_MISSING' }
    [IO.File]::WriteAllBytes($replacement, [byte[]](1, 2, 3))
    if (Test-ReplacementMetadata @(Get-SafeRootContents) $actual) { throw 'ZIP_GUEST_METADATA_LENGTH' }
    [IO.File]::WriteAllBytes($replacement, [byte[]](4, 5))
    $observed = @(Get-SafeRootContents)
    if (!(Test-ReplacementMetadata $observed $actual)) { throw 'ZIP_GUEST_METADATA_EXPECTED' }
    if (Test-ReplacementMetadata $observed ([IO.Directory]::GetAccessControl($base))) {
        throw 'ZIP_GUEST_METADATA_DACL'
    }
} finally {
    $contents = @(Get-SafeRootContents)
    if (@($contents | Where-Object Name -CEQ 'owner.txt').Count -ne 1 -or
        [IO.File]::ReadAllText($marker) -cne $Owner -or
        !([IO.Directory]::GetAccessControl($root)).GetOwner([Security.Principal.SecurityIdentifier]).Equals($admins)) {
        throw 'ZIP_GUEST_METADATA_CLEANUP_OWNER'
    }
    [IO.File]::Delete($replacement)
    [IO.File]::Delete($marker)
    [IO.Directory]::Delete($root, $false)
}
if (!(Test-RootAbsent)) { throw 'ZIP_GUEST_METADATA_CLEANUP' }
'PASS_CLEANED'
