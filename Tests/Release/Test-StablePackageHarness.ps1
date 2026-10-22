Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-StablePackageLab.ps1'),[ref]$null,[ref]$errors)
if ($errors.Count) {throw 'Harness syntax failed'}
foreach ($node in @($tree.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst]})) {
    . ([scriptblock]::Create($node.Extent.Text))
}
function Expect-Rejection([scriptblock]$Action,[string]$Reason) {
    try {& $Action; throw 'EXPECTED_REJECTION_MISSING'} catch {
        if ($_.Exception.Message -cne $Reason) {throw}
    }
}
Expect-Rejection {Assert-ReleasePrivatePath (Join-Path $repo 'public.json')} 'RELEASE_PRIVATE_PATH_REQUIRED'
Expect-Rejection {Assert-ReleaseOwnIdentity $null @{name='ForeignDatabase';created='1234'}} 'RELEASE_UNKNOWN_DATABASE_OWNER'
foreach ($sql in @(':CONNECT localhost','SELECT $(Missing);',':!! ignored')) {
    Expect-Rejection {Invoke-ReleaseBatches $null $sql} 'RELEASE_UNRESOLVED_SQLCMD'
}
$script:files=@{}
Expect-Rejection {Read-ReleaseUninstall '../outside.sql'} 'RELEASE_INCLUDE_OUTSIDE_PACKAGE'
$script:clock=[Diagnostics.Stopwatch]::StartNew(); $script:clock.Stop()
$script:cleanup=$false
if ((Get-ReleaseTimeout) -gt 45) {throw 'Command budget was not bounded'}
$matrixErrors=$null
$matrixTree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-StablePackageMatrix.ps1'),[ref]$null,[ref]$matrixErrors)
if ($matrixErrors.Count) {throw 'Matrix syntax failed'}
foreach ($node in @($matrixTree.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst]})) {
    . ([scriptblock]::Create($node.Extent.Text))
}
if ((Get-ReleaseMatrixAllowance 0 -CaseStart) -ne 400000) {throw 'Initial reserve failed'}
Expect-Rejection {Get-ReleaseMatrixAllowance 4000 -CaseStart} 'RELEASE_WAVE_BUDGET_EXHAUSTED'
Expect-Rejection {Get-ReleaseMatrixAllowance 4400} 'RELEASE_WAVE_BUDGET_EXHAUSTED'
'PASS RELEASE_HARNESS negative path/ownership/directive/include guards and bounded timeout; no SQL connection'
