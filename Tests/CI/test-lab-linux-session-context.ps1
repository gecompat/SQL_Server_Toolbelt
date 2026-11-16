# Synthetic controller/module and host leaves, actual dedicated Linux reader.
# No provider, trust, process launch, SQL connection or filesystem write.
class SqlServerLabSyntheticLinuxReader {
    [string]$Build='17.0.5005.3';[string]$Encrypt='TRUE';[int]$ReadCount=0;[bool]$Disposed=$false;[Exception]$DisposeFailure
    [bool] Read(){ $this.ReadCount++;return $this.ReadCount-eq1 }
    [string] GetString([int]$Ordinal){if($Ordinal-eq0){return $this.Build};return $this.Encrypt}
    [void] Dispose(){ $this.Disposed=$true;if($this.DisposeFailure){throw $this.DisposeFailure} }
}
class SqlServerLabSyntheticLinuxCommand {
    [object]$Reader;[Exception]$ExecuteFailure;[Exception]$DisposeFailure;[int]$CommandTimeout;[string]$CommandText='';[bool]$Disposed=$false
    [object] ExecuteReader(){if($this.ExecuteFailure){throw $this.ExecuteFailure};return $this.Reader}
    [void] Dispose(){ $this.Disposed=$true;if($this.DisposeFailure){throw $this.DisposeFailure} }
}
class SqlServerLabSyntheticLinuxConnection {
    [object]$Command;[Exception]$OpenFailure;[Exception]$CreateCommandFailure;[Exception]$DisposeFailure;[int]$OpenCount=0;[bool]$Disposed=$false
    [void] Open(){ $this.OpenCount++;if($this.OpenFailure){throw $this.OpenFailure} }
    [object] CreateCommand(){if($this.CreateCommandFailure){throw $this.CreateCommandFailure};return $this.Command}
    [void] Dispose(){ $this.Disposed=$true;if($this.DisposeFailure){throw $this.DisposeFailure} }
}
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
            if($script:mode -ceq 'document-failure'){throw 'TLS_LINUX_EXPORT_DOCUMENT_INVALID'}
            if($script:mode -ceq 'payload-failure'){throw 'TLS_LINUX_EXPORT_PAYLOAD_INVALID'}
            if($script:mode -ceq 'binding-failure'){throw 'TLS_LINUX_EXPORT_BINDING_INVALID'}
            if($script:mode -ceq 'reader-code'){throw $script:readerCode}
            if($script:mode -ceq 'private-failure'){throw 'TLS_LINUX_EXPORT_DOCUMENT_INVALID password=synthetic-secret'}
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
    function New-SyntheticLinuxConnectSnapshot {
        return [pscustomobject]@{
            Qualification=[pscustomobject]@{ClientPlatform='linux'}
            LinuxConnectWindow=[pscustomobject]@{
                ContractVersion='SqlServerLab.LinuxConnectWindow/0.1'
                RemainingAtApprovalMilliseconds=60000L
                Clock=[Diagnostics.Stopwatch]::StartNew()
            }
        }
    }
    $script:RunChecks={
        Reset
        $timeoutInner=[TimeoutException]::new('synthetic-private-timeout-detail')
        $timeoutOuter=[InvalidOperationException]::new('wrapper password=synthetic-secret',$timeoutInner)
        $timeoutRecord=[Management.Automation.ErrorRecord]::new($timeoutOuter,'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ((Get-LabLinuxSqlClientTimeoutFailureCode $timeoutRecord OPEN)-ceq'TLS_SQLCLIENT_OPEN_TIMEOUT') 'SQL open timeout maps to its fixed stage token without exposing exception detail'
        Assert ((Get-LabLinuxSqlClientTimeoutFailureCode $timeoutRecord QUERY)-ceq'TLS_SQLCLIENT_QUERY_TIMEOUT') 'SQL query timeout maps to its fixed stage token without exposing exception detail'
        $flags=[Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Public
        $sqlAssembly=[Reflection.Assembly]::Load('System.Data.SqlClient')
        $sqlErrorType=$sqlAssembly.GetType('System.Data.SqlClient.SqlError',$true)
        $sqlErrorCollectionType=$sqlAssembly.GetType('System.Data.SqlClient.SqlErrorCollection',$true)
        $sqlExceptionType=$sqlAssembly.GetType('System.Data.SqlClient.SqlException',$true)
        $sqlErrorConstructor=$sqlErrorType.GetConstructors($flags)|Where-Object {$_.GetParameters().Count -eq 8}|Select-Object -First 1
        $sqlCollectionAdd=$sqlErrorCollectionType.GetMethod('Add',$flags)
        $sqlExceptionConstructor=$sqlExceptionType.GetConstructors($flags)|Where-Object {$_.GetParameters().Count -eq 4}|Select-Object -First 1
        foreach($sqlCase in @(@{Number=-2;Stage='OPEN';Code='TLS_SQLCLIENT_OPEN_TIMEOUT'},@{Number=-2;Stage='QUERY';Code='TLS_SQLCLIENT_QUERY_TIMEOUT'},@{Number=18456;Stage='OPEN';Code=$null})){
            $sqlError=$sqlErrorConstructor.Invoke([object[]]@($sqlCase.Number,[byte]0,[byte]0,'synthetic','synthetic-private-sql-detail','',0,$null))
            $sqlErrors=[Activator]::CreateInstance($sqlErrorCollectionType,$true);$null=$sqlCollectionAdd.Invoke($sqlErrors,[object[]]@($sqlError))
            $sqlException=$sqlExceptionConstructor.Invoke([object[]]@('synthetic-private-sql-detail',$sqlErrors,$null,[guid]::Empty))
            $sqlRecord=[Management.Automation.ErrorRecord]::new($sqlException,'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
            Assert ((Get-LabLinuxSqlClientTimeoutFailureCode $sqlRecord $sqlCase.Stage)-ceq$sqlCase.Code) ('SqlException.Number timeout classification and non-timeout rejection: '+$sqlCase.Stage+'/'+$sqlCase.Number)
            $phaseCode=Get-LabLinuxSqlClientFailureCode $sqlRecord $sqlCase.Stage
            $expectedPhaseCode=if($sqlCase.Number-eq-2){$sqlCase.Code}else{'TLS_SQLCLIENT_'+$sqlCase.Stage+'_SQL'}
            Assert ($phaseCode-ceq$expectedPhaseCode-and$phaseCode -notmatch 'synthetic-private-sql-detail') ('SqlClient phase classifier keeps only the fixed SQL category: '+$sqlCase.Stage+'/'+$sqlCase.Number)
        }
        $nonTimeout=[InvalidOperationException]::new('synthetic-private-failure')
        $nonTimeoutRecord=[Management.Automation.ErrorRecord]::new($nonTimeout,'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ($null-eq(Get-LabLinuxSqlClientTimeoutFailureCode $nonTimeoutRecord OPEN)) 'unclassified SQL open failures preserve the existing safe fallback'
        Assert ((Get-LabLinuxSqlClientFailureCode $nonTimeoutRecord OPEN)-ceq'TLS_SQLCLIENT_OPEN_UNCLASSIFIED') 'unclassified SqlClient errors retain their bounded operation phase'
        $authenticationRecord=[Management.Automation.ErrorRecord]::new([Security.Authentication.AuthenticationException]::new('synthetic-private-auth-detail'),'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ((Get-LabLinuxSqlClientFailureCode $authenticationRecord OPEN)-ceq'TLS_SQLCLIENT_OPEN_AUTHENTICATION') 'TLS authentication errors retain only a fixed phase and category'
        $wrappedSqlException=$sqlExceptionConstructor.Invoke([object[]]@('synthetic-private-sql-detail',$sqlErrors,$authenticationRecord.Exception,[guid]::Empty))
        $wrappedAuthenticationRecord=[Management.Automation.ErrorRecord]::new($wrappedSqlException,'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ((Get-LabLinuxSqlClientFailureCode $wrappedAuthenticationRecord OPEN)-ceq'TLS_SQLCLIENT_OPEN_AUTHENTICATION') 'Inner TLS authentication category is retained through a SqlException wrapper'
        $networkRecord=[Management.Automation.ErrorRecord]::new([Net.Sockets.SocketException]::new([Net.Sockets.SocketError]::ConnectionRefused),'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ((Get-LabLinuxSqlClientFailureCode $networkRecord OPEN)-ceq'TLS_SQLCLIENT_OPEN_NETWORK') 'Socket errors retain only a fixed phase and category'
        $resultRecord=[Management.Automation.ErrorRecord]::new([InvalidOperationException]::new('LAB_LINUX_SQLCLIENT_RESULT'),'synthetic',[Management.Automation.ErrorCategory]::NotSpecified,$null)
        Assert ((Get-LabLinuxSqlClientFailureCode $resultRecord QUERY)-ceq'LAB_LINUX_SQLCLIENT_RESULT') 'Qualified SQL result failures keep their existing safe token'
        $successReader=[SqlServerLabSyntheticLinuxReader]::new()
        $successCommand=[SqlServerLabSyntheticLinuxCommand]::new();$successCommand.Reader=$successReader
        $successConnection=[SqlServerLabSyntheticLinuxConnection]::new();$successConnection.Command=$successCommand
        $successFactory={param([string]$ConnectionString)if(-not$ConnectionString){throw 'SYNTHETIC_CONNECTION_STRING_MISSING'};return $successConnection}.GetNewClosure()
        $successBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Data Source=tcp:localhost,1433;Encrypt=True;TrustServerCertificate=False')
        $successCode=Invoke-LabLinuxSqlClientQualification -Builder $successBuilder -Snapshot (New-SyntheticLinuxConnectSnapshot) -ExpectedSqlBuild '17.0.5005.3' -ConnectionFactory $successFactory
        $successBuilder.Clear()
        Assert ($null-eq$successCode-and$successConnection.OpenCount-eq1-and$successConnection.Disposed-and$successCommand.Disposed-and$successReader.Disposed) 'Synthetic successful SqlClient flow completes and disposes every owned object'
        $openFailureConnection=[SqlServerLabSyntheticLinuxConnection]::new();$openFailureConnection.OpenFailure=$sqlException
        $openFailureFactory={param([string]$ConnectionString)return $openFailureConnection}.GetNewClosure()
        $openFailureBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Data Source=tcp:localhost,1433;Encrypt=True;TrustServerCertificate=False')
        $openFailureCode=Invoke-LabLinuxSqlClientQualification -Builder $openFailureBuilder -Snapshot (New-SyntheticLinuxConnectSnapshot) -ExpectedSqlBuild '17.0.5005.3' -ConnectionFactory $openFailureFactory
        $openFailureBuilder.Clear()
        Assert ($openFailureCode-ceq'TLS_SQLCLIENT_OPEN_SQL'-and$openFailureConnection.Disposed-and$openFailureConnection.OpenCount-eq1) 'Synthetic open failure preserves its phase and disposes the connection without touching uncreated query resources'
        $queryFailureConnection=[SqlServerLabSyntheticLinuxConnection]::new();$queryFailureConnection.CreateCommandFailure=$nonTimeout
        $queryFailureFactory={param([string]$ConnectionString)return $queryFailureConnection}.GetNewClosure()
        $queryFailureBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Data Source=tcp:localhost,1433;Encrypt=True;TrustServerCertificate=False')
        $queryFailureCode=Invoke-LabLinuxSqlClientQualification -Builder $queryFailureBuilder -Snapshot (New-SyntheticLinuxConnectSnapshot) -ExpectedSqlBuild '17.0.5005.3' -ConnectionFactory $queryFailureFactory
        $queryFailureBuilder.Clear()
        Assert ($queryFailureCode-ceq'TLS_SQLCLIENT_QUERY_UNCLASSIFIED'-and$queryFailureConnection.Disposed) 'Synthetic early query failure remains the query failure and does not read unset reader or command variables'
        $cleanupReader=[SqlServerLabSyntheticLinuxReader]::new()
        $cleanupCommand=[SqlServerLabSyntheticLinuxCommand]::new();$cleanupCommand.Reader=$cleanupReader;$cleanupCommand.DisposeFailure=$nonTimeout
        $cleanupConnection=[SqlServerLabSyntheticLinuxConnection]::new();$cleanupConnection.Command=$cleanupCommand
        $cleanupFactory={param([string]$ConnectionString)return $cleanupConnection}.GetNewClosure()
        $cleanupBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Data Source=tcp:localhost,1433;Encrypt=True;TrustServerCertificate=False')
        $cleanupCode=Invoke-LabLinuxSqlClientQualification -Builder $cleanupBuilder -Snapshot (New-SyntheticLinuxConnectSnapshot) -ExpectedSqlBuild '17.0.5005.3' -ConnectionFactory $cleanupFactory
        $cleanupBuilder.Clear()
        Assert ($cleanupCode-ceq'TLS_SQLCLIENT_CLEANUP_UNCLASSIFIED'-and$cleanupReader.Disposed-and$cleanupCommand.Disposed-and$cleanupConnection.Disposed) 'Synthetic cleanup failure remains distinguishable after all owned objects are closed'
        $windowConnection=[SqlServerLabSyntheticLinuxConnection]::new()
        $windowSnapshot=New-SyntheticLinuxConnectSnapshot
        $windowFactory={param([string]$ConnectionString)$windowSnapshot.LinuxConnectWindow.Clock.Stop();return $windowConnection}.GetNewClosure()
        $windowBuilder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Data Source=tcp:localhost,1433;Encrypt=True;TrustServerCertificate=False')
        $windowCode=Invoke-LabLinuxSqlClientQualification -Builder $windowBuilder -Snapshot $windowSnapshot -ExpectedSqlBuild '17.0.5005.3' -ConnectionFactory $windowFactory
        $windowBuilder.Clear()
        Assert ($windowCode-ceq'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED'-and$windowConnection.OpenCount-eq0-and$windowConnection.Disposed) 'Synthetic connection construction that exhausts the window is rejected before Open'
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
        foreach($case in @(
            @{Mode='document-failure';Code='TLS_LINUX_EXPORT_DOCUMENT_INVALID'},
            @{Mode='payload-failure';Code='TLS_LINUX_EXPORT_PAYLOAD_INVALID'},
            @{Mode='binding-failure';Code='TLS_LINUX_EXPORT_BINDING_INVALID'}
        )){
            Reset;$script:mode=$case.Mode
            Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} $case.Code) ('preserve only the fixed safe reader category: '+$case.Mode)
        }
        foreach($code in @(
            'TLS_LINUX_VERIFIER_EXCHANGE_REJECTED','TLS_LINUX_VERIFIER_REPLY_REJECTED',
            'TLS_LINUX_VERIFIER_REPLY_FRAME_REJECTED','TLS_LINUX_VERIFIER_REPLY_SCHEMA_REJECTED',
            'TLS_LINUX_VERIFIER_REPLY_BINDING_REJECTED','TLS_LINUX_VERIFIER_REPLY_TIME_REJECTED',
            'TLS_LINUX_VERIFIER_REPLY_WINDOW_REJECTED','TLS_LINUX_VERIFIER_REPLY_DEADLINE_EXCEEDED',
            'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_CREATE','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_START',
            'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_LAYOUT','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_TRUST_WRITE',
            'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_OBSERVATION','TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_NAMESPACE_CHECK',
            'TLS_LAB_RUNTIME_TIMEOUT_LINUX_CLIENT_QUALIFICATION'
        )){
            Reset;$script:mode='reader-code';$script:readerCode=$code
            Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} $code) ('preserve closed verifier diagnostic through consumer catch: '+$code)
            Assert ($script:readerCalls -eq 1) 'reader failure does not retry or fall back'
        }
        Reset;$script:mode='private-failure'
        Assert (Reject {Read-LabQualifiedSnapshot $script:bytes $script:ctx} 'LAB_QUALIFIED_EXPORT_REJECTED') 'private exception detail remains collapsed'
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
