# Synthetic controller/module and host leaves, actual dedicated Linux reader.
# No provider, trust, process launch, SQL connection or filesystem write.
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$originalImportCommand=Get-Command Import-Module
$fixture=New-Module -ArgumentList $root -ScriptBlock {
    param($Root)
    . (Join-Path $Root 'LabLinuxQualifiedContract.ps1')
    $script:cases=0
    function Assert([bool]$Pass,[string]$Case){if(-not $Pass){throw ('LINUX_CONSUMER_CASE_FAILED: '+$Case)};$script:cases++}
    function Reject([scriptblock]$Action,[string]$Code){try{$null=& $Action;return $false}catch{return $_.Exception.Message -ceq $Code}}
    function Get-LabQualifiedClientHost {return $script:HostPlatform}
    function New-LabConnectionString {throw 'SYNTHETIC_SQL_OPEN_FORBIDDEN'}
    function Import-Module {
        param($Name,[switch]$PassThru,$ErrorAction)
        $null=$PassThru,$ErrorAction
        Assert ($Name -ceq (Join-Path $Root 'LabQualifiedContract.ps1')) 'module path comes only from caller'
        $script:imports++
        [pscustomobject]@{ExportedCommands=@{'Read-SqlServerLabQualifiedTestEnvironment'={
            param($ExportBytes,$StateRoot,$RunId,$InstanceId,$LinuxSessionRef,$LinuxClientStack)
            Assert ($StateRoot -ceq 'synthetic-owner-root' -and $RunId -ceq 'synthetic-run' -and $InstanceId -ceq 'primary') 'caller tuple forwarded unchanged'
            Assert ($LinuxSessionRef -ceq ('a'*64)) 'opaque session forwarded'
            $script:readerCalls++
            $script:lastStack=$LinuxClientStack
            $q=[pscustomobject]@{ClientPlatform='linux';ClientRef='11111111-1111-1111-1111-111111111111';ClientContextDigest=('b'*64);ExpiresAt=[DateTimeOffset]::UtcNow.AddMinutes(2).ToString('o')}
            switch($script:mode){
                ref {$q.ClientRef='foreign'}
                digest {$q.ClientContextDigest='c'*64}
                windows {$q.ClientPlatform='windows'}
                array {$q.ClientPlatform=@('linux')}
            }
            [pscustomobject]@{
                ContractVersion='SqlServerLab.QualifiedTestEnvironmentSnapshot/0.1'
                ExportBytes=$ExportBytes;ExportSha256=(Get-LabContractByteHash $ExportBytes)
                Contract=[pscustomobject]@{contractVersion='SqlServerLab.TestEnvironment/2.0';environments=@([pscustomobject]@{key='SYNTHETIC'})}
                Qualification=$q
            }
        }}}
    }
    function Reset {
        $script:HostPlatform='linux';$script:readerCalls=0;$script:imports=0;$script:mode=''
        $script:ctx=[pscustomobject]@{
            ModuleFile=(Join-Path $Root 'LabQualifiedContract.ps1');StateRoot='synthetic-owner-root';RunId='synthetic-run';InstanceId='primary'
            LinuxSessionRef=('a'*64);LinuxClientRef='11111111-1111-1111-1111-111111111111';LinuxClientContextDigest=('b'*64)
        }
        $script:bytes=[Text.Encoding]::UTF8.GetBytes('{"ModuleFile":"export-cannot-select-code","StateRoot":"export-cannot-select-root"}')
    }
    $script:RunChecks={
        Reset
        foreach($stack in @('SYSTEM_DATA_SQLCLIENT','ODBC_SQLCMD')){
            $null=Read-LabQualifiedSnapshot $script:bytes $script:ctx $stack
            Assert ($script:lastStack -ceq $stack) 'actual shared reader forwards selected stack'
        }
        Assert ($script:readerCalls -eq 2) 'separate fresh public verification for both calls'
        foreach($bad in @('ref','digest','windows','array')){
            Reset;$script:mode=$bad
            Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_EXPORT_REJECTED') ("reject changed returned Linux binding: "+$bad)
            Assert ($script:readerCalls -eq 1) 'no reader fallback/retry'
        }
        foreach($field in @('LinuxSessionRef','LinuxClientRef','LinuxClientContextDigest')){
            foreach($value in @('wrong',$null,@('a'*64))){
                Reset;$script:ctx.$field=$value
                Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED') ("reject malformed "+$field)
                Assert ($script:imports -eq 0 -and $script:readerCalls -eq 0) 'bad context blocks before module invocation'
            }
        }
        Reset;$script:HostPlatform='windows'
        Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED') 'Linux peer session cannot be consumed as Windows context'
        $windows=[pscustomobject]@{ModuleFile=$script:ctx.ModuleFile;StateRoot=$script:ctx.StateRoot;RunId=$script:ctx.RunId;InstanceId='primary'}
        $readerArguments=Get-LabQualifiedReaderArguments $windows 'windows'
        Assert ($readerArguments.Count -eq 3 -and -not $readerArguments.ContainsKey('LinuxSessionRef')) 'legacy Windows call arguments remain unchanged'
        Reset;$script:HostPlatform='unsupported'
        Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED') 'unknown host has no fallback'
        Reset
        $snapshot=Read-LabQualifiedSnapshot $script:bytes $script:ctx
        $window=[pscustomobject]@{ContractVersion='SqlServerLab.LinuxConnectWindow/0.1';RemainingAtApprovalMilliseconds=35000L;Clock=[Diagnostics.Stopwatch]::StartNew()}
        $snapshot|Add-Member -NotePropertyName LinuxConnectWindow -NotePropertyValue $window
        # The controller, not this receiver's UTC clock, established the
        # qualification deadline. Only the unreset live monotonic window counts.
        $snapshot.Qualification.ExpiresAt='1900-01-01T00:00:00Z'
        Assert-LabQualifiedConnectWindow $snapshot
        Assert $true 'Linux open uses current controller window rather than receiver UTC'
        foreach($bad in @('missing','array','stopped','insufficient')){
            $originalWindow=$snapshot.LinuxConnectWindow
            switch($bad){
                missing {$snapshot.LinuxConnectWindow=$null}
                array {$snapshot.LinuxConnectWindow=@($window)}
                stopped {$snapshot.LinuxConnectWindow=[pscustomobject]@{ContractVersion='SqlServerLab.LinuxConnectWindow/0.1';RemainingAtApprovalMilliseconds=35000L;Clock=[Diagnostics.Stopwatch]::new()}}
                insufficient {$snapshot.LinuxConnectWindow=[pscustomobject]@{ContractVersion='SqlServerLab.LinuxConnectWindow/0.1';RemainingAtApprovalMilliseconds=29999L;Clock=[Diagnostics.Stopwatch]::StartNew()}}
            }
            Assert (Reject {Assert-LabQualifiedConnectWindow $snapshot} 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED') ("invalid monotonic window blocks: "+$bad)
            $snapshot.LinuxConnectWindow=$originalWindow
        }
        $script:HostPlatform='windows'
        Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_CONTEXT_UNSUPPORTED') 'Dedicated Linux reader cannot be consumed by a Windows caller'
        [pscustomobject]@{Suite='LinuxQualifiedConsumerContext';Passed=$script:cases;Failed=0;ProviderActions=0;SqlLogins=0}
    }
    # New-Module otherwise exports its mocks to the caller immediately;
    # Remove-Module alone does not restore a shadowed command afterwards.
    Export-ModuleMember -Function @()
}
try {& $fixture {& $script:RunChecks}|ConvertTo-Json -Compress}
finally {
    Remove-Module $fixture -Force
    $afterImportCommand=Get-Command Import-Module
    if($afterImportCommand.CommandType -ne $originalImportCommand.CommandType -or
        $afterImportCommand.ModuleName -cne $originalImportCommand.ModuleName){throw 'LINUX_CONSUMER_FIXTURE_COMMAND_LEAK'}
}
