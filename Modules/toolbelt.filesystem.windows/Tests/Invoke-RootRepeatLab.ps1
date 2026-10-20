[CmdletBinding()]
param(
    [ValidateSet('2019','2022','2025')][string]$Version='2025',
    [string]$Patch='base',
    [ValidateSet(150,160,170)][int]$CompatibilityLevel=170,
    [Parameter(Mandatory)][string]$AssemblyPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{128}$')][string]$ExpectedAssemblySHA512,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedProviderSHA256,
    [Parameter(Mandatory)][string]$JournalPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ExpectedAssemblySHA512=$ExpectedAssemblySHA512.ToUpperInvariant()
$ExpectedProviderSHA256=$ExpectedProviderSHA256.ToUpperInvariant()
$repo=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$module=Join-Path $repo 'Modules/toolbelt.filesystem.windows'
$journal=[IO.Path]::GetFullPath($JournalPath)
if(Test-Path -LiteralPath $journal){throw 'FS_REPEAT_JOURNAL_EXISTS'}
if($journal.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'FS_REPEAT_PRIVATE_JOURNAL_OUTSIDE_REPOSITORY_REQUIRED'}
$clock=[Diagnostics.Stopwatch]::StartNew();$cleanupPhase=$false;$stage='PREPARATION'
$ledger=[ordered]@{State='PREPARING';Targets=@();Pins=@{}}
$originalFailure=$null

function Get-Failure($ErrorRecord){
    # Strukturierte Diagnose bleibt privat; kein freier Exception-/SQLtext.
    $number=0;$state=0;$reason='UNCLASSIFIED';$item=$ErrorRecord.Exception
    $types=[Collections.Generic.List[string]]::new()
    $knownReasons=@(
        'FS_REPEAT_BINARY_DRIFT','FS_REPEAT_BINARY_SOURCE_BINDING','FS_REPEAT_CAPTURE_SHAPE','FS_REPEAT_CL_VERSION',
        'FS_REPEAT_CLEANUP_NAME','FS_REPEAT_CONTROL_RESTORE_CHANGED','FS_REPEAT_DATABASE_OWNERSHIP_UNCONFIRMED',
        'FS_REPEAT_DATABASE_REMAINS','FS_REPEAT_DEADLINE','FS_REPEAT_DEPLOY_TRANSACTION','FS_REPEAT_EXISTING_CLR_PRIVILEGES_REQUIRED',
        'FS_REPEAT_HELPER_DISCOVERY','FS_REPEAT_HELPER_PARSE','FS_REPEAT_INCLUDE_BOUNDARY','FS_REPEAT_INPUT_DRIFT',
        'FS_REPEAT_JOURNAL_EXISTS','FS_REPEAT_NEGATIVE_CONTROL_MISSED','FS_REPEAT_OWNERSHIP_UNCONFIRMED',
        'FS_REPEAT_PREEXISTING_TRUST_DRIFT','FS_REPEAT_PRIVATE_JOURNAL_OUTSIDE_REPOSITORY_REQUIRED',
        'FS_REPEAT_READY_TARGET_MISSING','FS_REPEAT_SNAPSHOT_CHANGED','FS_REPEAT_TRUST_ADD_UNCONFIRMED',
        'FS_REPEAT_TRUST_CONSUMER_VISIBILITY','FS_REPEAT_TRUST_DRIFT','FS_REPEAT_TRUST_OWNERSHIP_UNCONFIRMED',
        'FS_REPEAT_TRUST_REMAINS','FS_REPEAT_UNRESOLVED_TEMPLATE')
    while($item-and$types.Count-lt16){$types.Add($item.GetType().FullName);if($item-is[Data.SqlClient.SqlException]){$number=$item.Number;$state=$item.State};if($item.Message-cin$knownReasons){$reason=$item.Message};$item=$item.InnerException}
    $errorId=[string]$ErrorRecord.FullyQualifiedErrorId
    # Auch alphanumerische ErrorIds können den freien Throwtext enthalten.
    $knownIds=@('MethodInvocationException','InvokeMethodOnNull','PropertyNotFoundStrict','VariableIsUndefined',
        'InvalidCastFromAnyTypeToAnyType','ConvertToFinalInvalidCastException','MethodArgumentConversionInvalidCastArgument',
        'CannotConvertArgumentNoMessage','ParameterArgumentTransformationError,Sql',
        'ParameterArgumentValidationError,Sql','ParameterArgumentValidationErrorNullNotAllowed,Sql','PositionalParameterNotFound,Sql')
    if($errorId-cnotin$knownIds){$errorId='REDACTED_UNCLASSIFIED_ERROR_ID'}
    $sourceLine=0
    if($null-ne$ErrorRecord.InvocationInfo){$sourceLine=[int]$ErrorRecord.InvocationInfo.ScriptLineNumber}
    return [ordered]@{Stage=$stage;SqlNumber=$number;SqlState=$state;Reason=$reason;ExceptionTypes=$types.ToArray();ErrorId=$errorId;SourceLine=$sourceLine}
}

function Save-Journal {
    # Nur eigene Identitäten/Hashes/Zustände, keine Verbindungsdaten oder Endpoints.
    [IO.File]::WriteAllText($journal,($ledger|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Scalar,[switch]$Snapshot){
    $remaining=$(if($cleanupPhase){360000}else{300000})-$clock.ElapsedMilliseconds
    if($remaining-lt1000){throw 'FS_REPEAT_DEADLINE'}
    $command=$Connection.CreateCommand();$command.CommandTimeout=[int][Math]::Min(30,[Math]::Floor($remaining/1000));$command.CommandText=$Text
    try{
        foreach($key in $Parameters.Keys){[void]$command.Parameters.AddWithValue($key,$Parameters[$key])}
        if($Scalar){return $command.ExecuteScalar()}
        if(-not$Snapshot){[void]$command.ExecuteNonQuery();return}
        $result=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
        $reader=$command.ExecuteReader()
        try{
            if($reader.FieldCount-ne2){throw 'FS_REPEAT_CAPTURE_SHAPE'}
            while($reader.Read()){
                if($clock.ElapsedMilliseconds-ge300000){$command.Cancel();throw 'FS_REPEAT_DEADLINE'}
                $result.Add($reader.GetString(0),[Convert]::ToHexString([byte[]]$reader.GetValue(1)))
            }
            if($reader.NextResult()-or$result.Count-ne12){throw 'FS_REPEAT_CAPTURE_SHAPE'}
        }finally{$reader.Dispose()}
        return ,$result
    }finally{$command.Dispose()}
}
function Open-Connection($Entry,[string]$Database){
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $Entry -TestPurpose Functional))
    $builder['Initial Catalog']=$Database;$builder['Pooling']=$false
    $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
    try{$connection.Open();return $connection}catch{$connection.Dispose();throw}
}
function Read-Sql([string]$Path){
    $full=[IO.Path]::GetFullPath($Path)
    if(-not$full.StartsWith((Join-Path $repo 'Modules')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'FS_REPEAT_INCLUDE_BOUNDARY'}
    $text=[IO.File]::ReadAllText($full)
    $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($m) Read-Sql (Join-Path (Split-Path -Parent $full) $m.Groups[1].Value.Trim())})
    $text=[regex]::Replace($text,'(?im)^\s*:On\s+Error\s+exit\s*$','')
    $text=$text.Replace('$(AssemblyBits)',$assemblyBits).Replace('$(DeploymentMode)','local')
    if($text-match'(?m)^\s*:'-or$text-match'\$\('){throw 'FS_REPEAT_UNRESOLVED_TEMPLATE'}
    return $text
}
function Deploy($Entry,[string]$Database,[string]$Text){
    # Jeder echte Deploy erhält eine neue ungepoolte Sitzung und unveränderte Batches.
    $connection=Open-Connection $Entry $Database
    try{
        foreach($batch in [regex]::Split($Text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
            if(-not[string]::IsNullOrWhiteSpace($batch)){Sql $connection $batch}
        }
        if([int](Sql $connection 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END' -Scalar)-ne1){throw 'FS_REPEAT_DEPLOY_TRANSACTION'}
    }finally{$connection.Dispose()}
}
function Assert-Pins {
    foreach($path in $ledger.Pins.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne$ledger.Pins[$path]){throw 'FS_REPEAT_INPUT_DRIFT'}}
    if((Get-FileHash -LiteralPath $dll -Algorithm SHA512).Hash-cne$ExpectedAssemblySHA512){throw 'FS_REPEAT_BINARY_DRIFT'}
}
function Trust-Fingerprint($Connection){
    return [string](Sql $Connection @'
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',hash
 +CONVERT(binary(4),ISNULL(DATALENGTH(description),-1))+ISNULL(CONVERT(varbinary(max),description),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(CONVERT(varbinary(max),create_date)),-1))+ISNULL(CONVERT(varbinary(max),create_date),0x)
 +CONVERT(binary(4),ISNULL(DATALENGTH(created_by),-1))+ISNULL(CONVERT(varbinary(max),created_by),0x)),2)
FROM sys.trusted_assemblies WHERE hash=@Hash;
'@ @{'@Hash'=$assemblyHash} -Scalar)
}
function Assert-NoTrustConsumer($Connection){
    # Bestehende Verbraucher und unvollständige Sicht verhindern Add und Remove.
    if([int](Sql $Connection 'SELECT COUNT(*) FROM sys.databases WHERE state<>0' -Scalar)-ne0){throw 'FS_REPEAT_TRUST_CONSUMER_VISIBILITY'}
    $scan="DECLARE @n sysname,@sql nvarchar(max); DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.databases; OPEN dbs; FETCH NEXT FROM dbs INTO @n; WHILE @@FETCH_STATUS=0 BEGIN SET @sql=N'IF EXISTS(SELECT 1 FROM '+QUOTENAME(@n)+N'.sys.assembly_files WHERE file_id=1 AND HASHBYTES(''SHA2_512'',content)=@Hash) THROW 52971,N''Assembly consumer blocks trust mutation.'',2;';EXEC sys.sp_executesql @sql,N'@Hash varbinary(64)',@Hash; FETCH NEXT FROM dbs INTO @n; END; CLOSE dbs; DEALLOCATE dbs;"
    Sql $Connection $scan @{'@Hash'=$assemblyHash}
}

try{
    $helper=Join-Path $repo 'Tests/CI/run-lab-local.ps1';$errors=$null
    $tree=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'FS_REPEAT_HELPER_PARSE'}
    foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')){
        $definitions=@($tree.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
        if($definitions.Count-ne1){throw 'FS_REPEAT_HELPER_DISCOVERY'}
        . ([scriptblock]::Create($definitions[0].Extent.Text))
    }
    $dll=[IO.Path]::GetFullPath($AssemblyPath)
    if((Get-FileHash -LiteralPath $dll -Algorithm SHA512).Hash-cne$ExpectedAssemblySHA512-or
       (Get-FileHash -LiteralPath (Join-Path $module 'Clr/WindowsFilesystemProvider.cs') -Algorithm SHA256).Hash-cne$ExpectedProviderSHA256){throw 'FS_REPEAT_BINARY_SOURCE_BINDING'}
    $assemblyBytes=[IO.File]::ReadAllBytes($dll)
    $assemblyHash=[Security.Cryptography.SHA512]::HashData($assemblyBytes);$assemblyBits='0x'+[Convert]::ToHexString($assemblyBytes)
    $ledger['AssemblyHash']='0x'+[Convert]::ToHexString($assemblyHash)
    $pinPaths=@($PSCommandPath,$helper,$dll)
    foreach($folder in @((Join-Path $module 'Source'),(Join-Path $module 'Deployment'),(Join-Path $module 'Clr'),(Join-Path $repo 'Modules/toolbelt.core.result-table/Source'),(Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment'))){
        $pinPaths+=@(Get-ChildItem -LiteralPath $folder -File -Recurse|Where-Object{$_.Extension-in'.sql','.cs','.csproj'}|Select-Object -ExpandProperty FullName)
    }
    $fixture=Join-Path $module 'Tests/Runtime/FileSystemRoot.Repeat.sql';$pinPaths+=$fixture
    foreach($path in $pinPaths){$ledger.Pins[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
    $lab=Resolve-LabContract
    $ledger['LabContractSHA256']=(Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
    if($targets.Count-lt1){throw 'FS_REPEAT_READY_TARGET_MISSING'}
    if($CompatibilityLevel-gt(@{'2019'=150;'2022'=160;'2025'=170}[$Version])){throw 'FS_REPEAT_CL_VERSION'}
    $product=Read-Sql (Join-Path $module 'Deployment/Deploy.sql')
    $dependency=Read-Sql (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql')
    $fixtureText=[IO.File]::ReadAllText($fixture)
    Save-Journal
    foreach($target in $targets){
        $stage='PREFLIGHT';[void](Invoke-LabPreflight -Entry $target)
        $master=$null;$work=$null;$record=[ordered]@{Database='Toolbelt_FsRootRepeat_'+[guid]::NewGuid().ToString('N');Run=[guid]::NewGuid().ToString();Created=$false;Identity=$null;TrustBefore=$null;TrustAdded=$false;TrustFingerprint=$null;TrustDescription='Toolbelt FileSystemRoot repeat '+[guid]::NewGuid().ToString('N');State='PLANNED';Comparisons=0;NegativeControls=0;Cleanup='PENDING'}
        $ledger.Targets+=@($record);Save-Journal
        try{
            $master=Open-Connection $target 'master'
            if([int](Sql $master "SELECT CASE WHEN ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)=1 AND (SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled')=1 AND (SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security')=1 AND (SELECT host_platform FROM sys.dm_os_host_info)=N'Windows' THEN 1 ELSE 0 END" -Scalar)-ne1){throw 'FS_REPEAT_EXISTING_CLR_PRIVILEGES_REQUIRED'}
            $record.TrustBefore=Trust-Fingerprint $master
            if(-not$record.TrustBefore){
                Assert-NoTrustConsumer $master
                # Vor Mutation journalisieren; eine verlorene Antwort bleibt ausdrücklich unbestätigt.
                $record.State='TRUST_ADDING';Save-Journal;Assert-Pins
                Sql $master 'EXEC sys.sp_add_trusted_assembly @hash=@Hash,@description=@Description' @{'@Hash'=$assemblyHash;'@Description'=$record.TrustDescription}
                $record.TrustAdded=$true;$record.TrustFingerprint=Trust-Fingerprint $master
                if(-not$record.TrustFingerprint){throw 'FS_REPEAT_TRUST_ADD_UNCONFIRMED'}
                $record.State='TRUST_ADDED';Save-Journal
            }
            $stage='CREATE';$record.State='DATABASE_CREATING';Save-Journal;Assert-Pins
            Sql $master ('CREATE DATABASE ['+$record.Database+'] COLLATE Latin1_General_100_CS_AS;')
            $record.Created=$true;Save-Journal
            Sql $master ('ALTER DATABASE ['+$record.Database+'] SET COMPATIBILITY_LEVEL='+$CompatibilityLevel+';')
            $work=Open-Connection $target $record.Database
            Sql $work "EXEC sys.sp_addextendedproperty @name=N'Contoso.FsRootRepeat.Run',@value=@Run;" @{'@Run'=$record.Run}
            $record.Identity=[string](Sql $master "SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(binary(4),database_id)+CONVERT(binary(9),CONVERT(datetime2(7),create_date))+owner_sid),2) FROM sys.databases WHERE name=@Name AND owner_sid=SUSER_SID();" @{'@Name'=$record.Database} -Scalar)
            if(-not$record.Identity){throw 'FS_REPEAT_OWNERSHIP_UNCONFIRMED'}
            $work.Dispose();$work=$null;$record.State='OWNED';Save-Journal
            $stage='INSTALL';Deploy $target $record.Database $dependency;Deploy $target $record.Database $product
            $stage='FIXTURE_SETUP';$work=Open-Connection $target $record.Database;Sql $work $fixtureText @{'@Phase'='Setup'}
            $stage='FIXTURE_CAPTURE';$before=Sql $work $fixtureText @{'@Phase'='Capture'} -Snapshot
            # Zwei echte inverse Kontrollen: NULL ist nicht leer; Padding ist signifikant.
            foreach($control in @(
                @{Change="UPDATE toolbelt_filesystem.FileSystemRoot SET WorkPath=N'' WHERE RootAlias=N'ContosoEmpty';";Restore="UPDATE toolbelt_filesystem.FileSystemRoot SET WorkPath=NULL WHERE RootAlias=N'ContosoEmpty';"},
                @{Change="UPDATE toolbelt_filesystem.FileSystemRoot SET WorkPath=N'work\' WHERE RootAlias=N'ContosoUnicode';";Restore="UPDATE toolbelt_filesystem.FileSystemRoot SET WorkPath=N'work\ ' WHERE RootAlias=N'ContosoUnicode';"}
            )){
                $stage='CONTROL_CHANGE';Sql $work $control.Change
                $stage='CONTROL_CAPTURE';$changed=Sql $work $fixtureText @{'@Phase'='Capture'} -Snapshot
                if($changed['rows']-ceq$before['rows']){throw 'FS_REPEAT_NEGATIVE_CONTROL_MISSED'}
                $stage='CONTROL_RESTORE';Sql $work $control.Restore
                $stage='CONTROL_RESTORE_CAPTURE';$restored=Sql $work $fixtureText @{'@Phase'='Capture'} -Snapshot
                foreach($key in $before.Keys){if($restored[$key]-cne$before[$key]){throw 'FS_REPEAT_CONTROL_RESTORE_CHANGED'}}
                $record.NegativeControls++
            }
            $work.Dispose();$work=$null
            foreach($cycle in 1..2){
                $stage='REPEAT';Assert-Pins;Deploy $target $record.Database $product
                $work=Open-Connection $target $record.Database;$after=Sql $work $fixtureText @{'@Phase'='Capture'} -Snapshot
                foreach($key in $before.Keys){if(-not$after.ContainsKey($key)-or$after[$key]-cne$before[$key]){throw 'FS_REPEAT_SNAPSHOT_CHANGED'}}
                $record.Comparisons++;Save-Journal;$work.Dispose();$work=$null
            }
            Assert-Pins;$record.State='PASS';Save-Journal
        }catch{
            $record['Failure']=Get-Failure $_;$originalFailure=$record.Failure
            try{Save-Journal}catch{}
            throw
        }finally{
            $cleanupPhase=$true;$stage='CLEANUP'
            if($work){$work.Dispose()}
            if($master){$master.Dispose();$master=$null}
            # Frische Verbindung, genaue eigene Identität und keine fremden Verbraucher.
            $master=Open-Connection $target 'master'
            try{
                if($record.Created-and$record.Identity){
                    if($record.Database-cnotmatch'^Toolbelt_FsRootRepeat_[0-9a-f]{32}$'){throw 'FS_REPEAT_CLEANUP_NAME'}
                    $check="IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 OR NOT EXISTS(SELECT 1 FROM sys.databases WHERE name=@Name AND owner_sid=SUSER_SID() AND CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(binary(4),database_id)+CONVERT(binary(9),CONVERT(datetime2(7),create_date))+owner_sid),2)=@Identity) OR NOT EXISTS(SELECT 1 FROM ["+$record.Database+"].sys.extended_properties WHERE class=0 AND name=N'Contoso.FsRootRepeat.Run' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(nvarchar(36),value)=@Run) OR EXISTS(SELECT 1 FROM sys.dm_exec_sessions WHERE database_id=DB_ID(@Name) AND session_id<>@@SPID) OR EXISTS(SELECT 1 FROM sys.dm_exec_requests WHERE database_id=DB_ID(@Name) AND session_id<>@@SPID) THROW 52971,N'Own cleanup unproven.',1; DROP DATABASE ["+$record.Database+'];'
                    Sql $master $check @{'@Name'=$record.Database;'@Identity'=$record.Identity;'@Run'=$record.Run}
                    if([int](Sql $master 'SELECT COUNT(*) FROM sys.databases WHERE name=@Name' @{'@Name'=$record.Database} -Scalar)-ne0){throw 'FS_REPEAT_DATABASE_REMAINS'}
                }elseif($record.State-in'DATABASE_CREATING'-or$record.Created){throw 'FS_REPEAT_DATABASE_OWNERSHIP_UNCONFIRMED'}
                if($record.TrustAdded){
                    if((Trust-Fingerprint $master)-cne$record.TrustFingerprint){throw 'FS_REPEAT_TRUST_DRIFT'}
                    Assert-NoTrustConsumer $master
                    Sql $master 'EXEC sys.sp_drop_trusted_assembly @hash=@Hash' @{'@Hash'=$assemblyHash}
                    if(Trust-Fingerprint $master){throw 'FS_REPEAT_TRUST_REMAINS'}
                }elseif($record.State-ceq'TRUST_ADDING'){throw 'FS_REPEAT_TRUST_OWNERSHIP_UNCONFIRMED'}
                elseif($null-ne$record.TrustBefore-and(Trust-Fingerprint $master)-cne$record.TrustBefore){throw 'FS_REPEAT_PREEXISTING_TRUST_DRIFT'}
                $record.Cleanup='VERIFIED';Save-Journal
            }catch{
                $record.Cleanup='BLOCKED';$record['CleanupFailure']=Get-Failure $_
                try{Save-Journal}catch{}
                throw
            }finally{$master.Dispose()}
            $cleanupPhase=$false
        }
    }
    $ledger.State='PASS_CLEANED';Save-Journal
    [Console]::Out.WriteLine('FILESYSTEM_ROOT_REPEAT_PASS_CLEANED')
}catch{
    $failure=Get-Failure $_
    $reported=if($originalFailure){$originalFailure}else{$failure}
    $ledger.State='FAILED';$ledger['Failure']=$reported;$ledger['OriginalFailure']=$originalFailure
    try{Save-Journal}catch{}
    [Console]::Out.WriteLine(('FILESYSTEM_ROOT_REPEAT_FAILED stage={0} reason={1} sql={2}/{3}'-f$reported.Stage,$reported.Reason,$reported.SqlNumber,$reported.SqlState));exit 1
}
