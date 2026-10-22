[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunsetPath,
    [Parameter(Mandatory)][ValidateRange(0,11)][int]$CaseIndex,
    [switch]$AuditOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$clock = [Diagnostics.Stopwatch]::StartNew()
$cleanup = $false
$stage = 'PREPARE'
$connections = [Collections.Generic.List[object]]::new()

# Ein endlicher Pakettest, keine erneute Vollqualifikation der einzelnen APIs.
# Die private Runsetdatei bindet Paket, Harness, Labvertrag und Zusatzprompt.
function Assert-ReleasePin([string]$Path,[string]$Expected) {
    if ($Expected -cnotmatch '^[A-F0-9]{64}$' -or
        (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -cne $Expected) {
        throw 'RELEASE_INPUT_DRIFT'
    }
}
function Assert-ReleasePrivatePath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    $private = [IO.Path]::GetFullPath((Join-Path $repo '.runtime')) + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($private,[StringComparison]::OrdinalIgnoreCase)) { throw 'RELEASE_PRIVATE_PATH_REQUIRED' }
    $parent = [IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($full))
    while ($parent -and $parent.FullName.Length -ge $private.TrimEnd('\','/').Length) {
        if (($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'RELEASE_REPARSE_PATH' }
        $parent = $parent.Parent
    }
    return $full
}
function Get-ReleaseTimeout {
    $limit = if ($script:cleanup) { 360000 } else { 300000 }
    $remaining = $limit - $script:clock.ElapsedMilliseconds
    if ($remaining -lt 1000) { throw 'RELEASE_DEADLINE' }
    return [int][Math]::Min(45,[Math]::Floor($remaining / 1000))
}
function Invoke-ReleaseSql($Connection,[string]$Sql,[hashtable]$Parameters=@{},[switch]$Rows) {
    $cmd=$Connection.CreateCommand(); $cmd.CommandTimeout=Get-ReleaseTimeout; $cmd.CommandText=$Sql
    try {
        foreach ($name in $Parameters.Keys) {
            $value=$Parameters[$name]
            $type=if ($value -is [byte[]]) {[Data.SqlDbType]::VarBinary} else {[Data.SqlDbType]::NVarChar}
            $cmd.Parameters.Add($name,$type,-1).Value=$value
        }
        $reader=$cmd.ExecuteReader()
        $records=[Collections.Generic.List[object]]::new()
        try {
            do {
                while ($reader.Read()) {
                    [void](Get-ReleaseTimeout)
                    if ($Rows) {
                        $record=[ordered]@{}
                        for ($i=0;$i -lt $reader.FieldCount;$i++) {$record[$reader.GetName($i)]=$reader.GetValue($i)}
                        $records.Add([pscustomobject]$record)
                    }
                }
                [void](Get-ReleaseTimeout)
            } while ($reader.NextResult())
        } finally {$reader.Dispose()}
        if ($Rows) {return $records.ToArray()}
    } finally {$cmd.Dispose()}
}
function Open-ReleaseConnection([string]$Database) {
    Assert-ReleaseInputs
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $script:target -TestPurpose Functional))
    $builder['Initial Catalog']=$Database; $builder['Pooling']=$false; $builder['Enlist']=$false
    $builder['ConnectRetryCount']=0; $builder['Connect Timeout']=[Math]::Min(15,(Get-ReleaseTimeout))
    $connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
    try {$connection.Open(); $script:connections.Add($connection); return $connection}
    catch {$connection.Dispose(); throw}
    finally {$builder.Clear()}
}
function Invoke-ReleaseBatches($Connection,[string]$Text) {
    $Text=[regex]::Replace($Text,'(?im)^\s*:ON\s+ERROR\s+EXIT\s*$','')
    if ($Text -match '(?m)^\s*:' -or $Text.Contains('$(')) {throw 'RELEASE_UNRESOLVED_SQLCMD'}
    foreach ($batch in [regex]::Split($Text,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) {Invoke-ReleaseSql $Connection $batch}
    }
}
function Read-ReleaseUninstall([string]$Path) {
    $full=[IO.Path]::GetFullPath((Join-Path $script:repo $Path))
    $relative=[IO.Path]::GetRelativePath($script:repo,$full).Replace('\','/')
    if (-not $script:files.ContainsKey($relative)) {throw 'RELEASE_INCLUDE_OUTSIDE_PACKAGE'}
    $text=$script:files[$relative]
    $text=[regex]::Replace($text,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{
        param($match)
        Read-ReleaseUninstall (Join-Path ([IO.Path]::GetDirectoryName($relative)) $match.Groups[1].Value.Trim())
    })
    return $text.Replace('$(ConfirmNoExternalConsumers)','1')
}
function Save-ReleaseJournal {
    $tmp=$script:journal+'.writing'
    [IO.File]::WriteAllText($tmp,($script:ledger|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    [IO.File]::Move($tmp,$script:journal,$true)
}
function Assert-ReleaseInputs {
    foreach ($pin in $script:runset.pins) {Assert-ReleasePin $pin.path $pin.sha256}
}
function Assert-ReleaseOwnIdentity($Control,$Entry) {
    $name=$Entry.name
    if ($name -cnotmatch '^Toolbelt_Release_[a-f0-9]{32}_[lcu]$' -or -not $Entry.created) {throw 'RELEASE_UNKNOWN_DATABASE_OWNER'}
    $rows=@(Invoke-ReleaseSql $Control @"
IF ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51591,N'Cleanup visibility required.',1;
IF NOT EXISTS(SELECT 1 FROM sys.databases WITH (NOLOCK) WHERE name=@Name
 AND database_id=TRY_CONVERT(int,@Id) AND CONVERT(varbinary(8),create_date)=@Created)
 THROW 51591,N'Owned database identity changed.',2;
DECLARE @Count int;
EXEC [$name].sys.sp_executesql N'SELECT @N=COUNT(*) FROM sys.extended_properties WITH (NOLOCK)
 WHERE class=0 AND name=N''Test.Release.Owner'' AND CONVERT(nvarchar(32),value)=@Owner;',
 N'@Owner nvarchar(32),@N int OUTPUT',@Owner,@Count OUTPUT;
IF @Count IS NULL OR @Count<>1 THROW 51591,N'Owned database marker changed.',3;
IF NOT EXISTS(SELECT 1 FROM sys.databases WITH (NOLOCK) WHERE name=@Name
 AND database_id=TRY_CONVERT(int,@Id) AND CONVERT(varbinary(8),create_date)=@Created)
 THROW 51591,N'Owned database identity changed before cleanup.',2;
DROP DATABASE [$name];
IF DB_ID(@Name) IS NOT NULL THROW 51591,N'Owned database still present.',5;
SELECT 1 AS Owned;
"@ @{'@Name'=$name;'@Id'=[string]$Entry.id;'@Created'=[Convert]::FromHexString($Entry.created);'@Owner'=$script:ledger.owner} -Rows)
    if ($rows.Count -ne 1 -or $rows[0].Owned -ne 1) {throw 'RELEASE_UNKNOWN_DATABASE_OWNER'}
}
function Assert-ReleaseInstalled($Connection,[string]$Mode) {
    $rows=@(Invoke-ReleaseSql $Connection "SELECT name,CONVERT(nvarchar(128),value) value FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name LIKE N'Toolbelt.Module.%';" -Rows)
    foreach ($module in $script:stable) {
        foreach ($pair in @(@('Version',$module.module_version),@('DeploymentMode',$Mode))) {
            $expected='Toolbelt.Module.'+$module.module_id+'.'+$pair[0]
            $found=@($rows|Where-Object {$_.name -ceq $expected -and $_.value -ceq $pair[1]})
            if ($found.Count -ne 1) {throw 'RELEASE_INSTALLED_MANIFEST_MISMATCH'}
        }
    }
    if (@($rows|Where-Object {$_.name.EndsWith('.Version',[StringComparison]::Ordinal)}).Count -ne 19) {throw 'RELEASE_UNEXPECTED_MODULE'}
    $objects=@(Invoke-ReleaseSql $Connection "SELECT s.name schema_name,o.name,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(o.object_id))),2) definition_hash FROM sys.objects o WITH (NOLOCK) JOIN sys.schemas s WITH (NOLOCK) ON s.schema_id=o.schema_id WHERE s.name LIKE N'toolbelt[_]%' AND o.is_ms_shipped=0 ORDER BY s.name,o.name;" -Rows)
    if ($objects.Count -lt 19) {throw 'RELEASE_INSTALLED_OBJECTS_MISSING'}
    return ($objects|ConvertTo-Json -Depth 4 -Compress)
}
function Invoke-ReleaseSmoke($Connection,[string]$Prefix='') {
    Invoke-ReleaseSql $Connection @"
IF (SELECT COUNT(*) FROM ${Prefix}toolbelt_core.TVF_GenerateSeriesInt(1,5,1))<>5
 OR (SELECT SUM(Value) FROM ${Prefix}toolbelt_core.TVF_GenerateSeriesInt(1,5,1))<>15
 THROW 51592,N'Package series oracle failed.',1;
IF ${Prefix}toolbelt_conversion.SVF_Base64Encode(0x666F6F,0)<>'Zm9v'
 OR ${Prefix}toolbelt_conversion.SVF_Base64Decode('Zm9v')<>0x666F6F
 THROW 51592,N'Package Base64 oracle failed.',2;
IF (SELECT COUNT(*) FROM ${Prefix}toolbelt_datetime.TVF_DateSpineDay('20260101','20260104'))<>3
 THROW 51592,N'Package date oracle failed.',3;
IF NOT EXISTS(SELECT 1 FROM ${Prefix}toolbelt_json.TVF_JsonPathExists(N'{"a":[1]}',N'$.a[0]') WHERE PathExists=1)
 THROW 51592,N'Package JSON oracle failed.',4;
CREATE TABLE #ReleaseShape(Item int NOT NULL);
CREATE TABLE #ReleaseResult(Placeholder int NULL);
EXEC ${Prefix}toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N'#ReleaseResult',@LikeTable=N'#ReleaseShape';
INSERT #ReleaseResult(Item) VALUES(42);
IF (SELECT Item FROM #ReleaseResult)<>42 THROW 51592,N'Package ResultTable oracle failed.',5;
DROP TABLE #ReleaseResult; DROP TABLE #ReleaseShape;
"@
}

$control=$null; $ledger=$null; $journal=$null; $failure=$null
try {
    $RunsetPath=Assert-ReleasePrivatePath $RunsetPath
    $runset=Get-Content -LiteralPath $RunsetPath -Raw|ConvertFrom-Json
    if ($runset.cases.Count -ne 12 -or $runset.productCommit -cne '756e7fb0444aedf04949409a8fab2189b9fa890f') {throw 'RELEASE_RUNSET_INVALID'}
    $case=$runset.cases[$CaseIndex]
    $journal=Assert-ReleasePrivatePath (Join-Path (Split-Path -Parent $RunsetPath) ('case-'+$CaseIndex+'.json'))
    Assert-ReleaseInputs
    if (@($runset.pins|Where-Object {$_.path -ceq $PSCommandPath}).Count -ne 1) {throw 'RELEASE_DRIVER_PIN_REQUIRED'}
    # Dieselbe kanonische Discovery und Zielauswahl wie die vorhandenen Labadapter.
    . (Join-Path $repo 'Tests/CI/LabQualifiedContract.ps1')
    $errors=$null
    $tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/CI/run-lab-local.ps1'),[ref]$null,[ref]$errors)
    if ($errors.Count) {throw 'RELEASE_LAB_HELPER_PARSE'}
    foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) {
        $nodes=@($tree.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
        if ($nodes.Count -ne 1) {throw 'RELEASE_LAB_HELPER_AMBIGUOUS'}
        . ([scriptblock]::Create($nodes[0].Extent.Text))
    }
    $lab=Resolve-LabContract -TestPurpose Functional
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector $case)
    if ($targets.Count -ne 1) {throw 'RELEASE_EXACT_TARGET_REQUIRED'}
    $target=$targets[0]
    if ((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $runset.contractSha256 -or
        (Get-FileHash -LiteralPath $lab.SchemaPath -Algorithm SHA256).Hash -cne $runset.schemaSha256 -or
        (Get-FileHash -LiteralPath (Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE') -Algorithm SHA256).Hash -cne $runset.promptSha256) {throw 'RELEASE_LAB_INPUT_DRIFT'}
    $targetIdentity=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$target.key)))
    $control=Open-ReleaseConnection 'master'
    if ($AuditOnly) {
        $ledger=Get-Content -LiteralPath $journal -Raw|ConvertFrom-Json
        if ($ledger.targetIdentity -cne $targetIdentity -or $ledger.state -cne 'COMPLETE') {throw 'RELEASE_AUDIT_IDENTITY'}
        foreach ($entry in $ledger.databases) {
            $rows=@(Invoke-ReleaseSql $control 'SELECT DB_ID(@Name) Id;' @{'@Name'=$entry.name} -Rows)
            if ($entry.state -cne 'DROPPED' -or $rows.Count -ne 1 -or $rows[0].Id -isnot [DBNull]) {throw 'RELEASE_AUDIT_DATABASE_PRESENT'}
        }
        Assert-ReleaseInputs
        'PASS RELEASE_INDEPENDENT_CLEANUP_AND_PINS'; exit 0
    }
    if (Test-Path -LiteralPath $journal) {throw 'RELEASE_CASE_ALREADY_ATTEMPTED'}
    $ledger=[ordered]@{owner=[guid]::NewGuid().ToString('N');targetIdentity=$targetIdentity;state='PREPARED';databases=@();completedModes=@();stage='PREPARE';failure=$null}
    Save-ReleaseJournal
    $stage='PREFLIGHT'
    $pre=@(Invoke-ReleaseSql $control "SELECT @@VERSION Version,CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) Major,(SELECT host_platform FROM sys.dm_os_host_info WITH (NOLOCK)) Platform,IS_SRVROLEMEMBER(N'sysadmin') IsAdmin; SELECT name,state_desc FROM sys.databases WITH (NOLOCK) ORDER BY database_id;" -Rows)
    if ($pre[0].IsAdmin -ne 1 -or $pre[0].Major -ne @{'2019'=15;'2022'=16;'2025'=17}[$case.Version] -or $pre[0].Platform -ine $case.Platform) {throw 'RELEASE_SQL_PREFLIGHT_MISMATCH'}
    $archive=[IO.Compression.ZipFile]::OpenRead($runset.package)
    $files=@{}
    try {
        foreach ($entry in $archive.Entries) {
            $path=$entry.FullName.Substring('SQL-Server-Toolbelt-1.0.0-candidate-source/'.Length)
            if ($path.EndsWith('.sql') -or $path -ceq 'Releases/1.0.0/release-plan.json') {
                $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8)
                try {$files[$path]=$reader.ReadToEnd()} finally {$reader.Dispose()}
            }
        }
    } finally {$archive.Dispose()}
    $plan=$files['Releases/1.0.0/release-plan.json']|ConvertFrom-Json
    $stable=@($plan.modules|Where-Object {$_.proposed_channel -ceq 'stable'})
    if ($stable.Count -ne 19) {throw 'RELEASE_STABLE_SET_INVALID'}
    $names=@{}
    foreach ($label in @('local','central','consumer')) {
        $stage='CREATE_'+$label
        $suffix=@{local='l';central='c';consumer='u'}[$label]
        $name='Toolbelt_Release_'+$ledger.owner+'_'+$suffix
        $entry=[ordered]@{name=$name;id=$null;created=$null;state='CREATING'}
        $ledger.databases+=@($entry); Save-ReleaseJournal
        Invoke-ReleaseSql $control "IF DB_ID(N'$name') IS NOT NULL THROW 51591,N'Database collision.',4; CREATE DATABASE [$name] COLLATE Latin1_General_100_CI_AS_SC;"
        $identity=@(Invoke-ReleaseSql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WITH (NOLOCK) WHERE name=@Name;' @{'@Name'=$name} -Rows)
        if ($identity.Count -ne 1) {throw 'RELEASE_DATABASE_IDENTITY_UNKNOWN'}
        $entry.id=$identity[0].Id; $entry.created=$identity[0].Created; $entry.state='CREATED'; Save-ReleaseJournal
        $db=Open-ReleaseConnection $name
        Invoke-ReleaseSql $db "DECLARE @MarkerOwner nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N'Test.Release.Owner',@value=@MarkerOwner;" @{'@Owner'=$ledger.owner}
        $entry.state='OWNED'; Save-ReleaseJournal
        Invoke-ReleaseSql $control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$($case.CL);"
        $level=@(Invoke-ReleaseSql $control 'SELECT compatibility_level CL FROM sys.databases WITH (NOLOCK) WHERE name=@Name;' @{'@Name'=$name} -Rows)
        if ($level.Count -ne 1 -or $level[0].CL -ne $case.CL) {throw 'RELEASE_COMPATIBILITY_MISMATCH'}
        $db.Dispose(); $names[$label]=$name
    }
    foreach ($mode in @('local','central')) {
        $stage='INSTALL_'+$mode
        $db=Open-ReleaseConnection $names[$mode]
        Invoke-ReleaseBatches $db $files["Install-Stable-$mode.sql"]
        $first=Assert-ReleaseInstalled $db $mode; Invoke-ReleaseSmoke $db; $db.Dispose()
        $stage='REPEAT_'+$mode
        $db=Open-ReleaseConnection $names[$mode]
        Invoke-ReleaseBatches $db $files["Install-Stable-$mode.sql"]
        if ((Assert-ReleaseInstalled $db $mode) -cne $first) {throw 'RELEASE_REPEAT_METADATA_DRIFT'}
        Invoke-ReleaseSmoke $db; $db.Dispose()
        if ($mode -ceq 'central') {
            $consumer=Open-ReleaseConnection $names.consumer
            Invoke-ReleaseSmoke $consumer ('['+$names.central+'].'); $consumer.Dispose()
        }
        $stage='UNINSTALL_'+$mode
        # Dependencyreihenfolge aus dem tatsächlich ausgeführten Paketexport.
        $order=@([regex]::Matches($files["Install-Stable-$mode.sql"],'(?m)^-- BEGIN MODULE (toolbelt\.[a-z0-9.-]+)')|ForEach-Object {$_.Groups[1].Value})
        if ($order.Count -ne 19 -or @($order|Select-Object -Unique).Count -ne 19) {throw 'RELEASE_EXPORT_MODULE_ORDER'}
        [array]::Reverse($order)
        foreach ($repeat in 1..2) {
            foreach ($mid in $order) {
                $db=Open-ReleaseConnection $names[$mode]
                Invoke-ReleaseBatches $db (Read-ReleaseUninstall "Modules/$mid/Deployment/Uninstall.sql")
                $db.Dispose()
            }
        }
        $db=Open-ReleaseConnection $names[$mode]
        $left=@(Invoke-ReleaseSql $db "SELECT (SELECT COUNT(*) FROM sys.objects o WITH (NOLOCK) JOIN sys.schemas s WITH (NOLOCK) ON s.schema_id=o.schema_id WHERE s.name LIKE N'toolbelt[_]%' AND o.is_ms_shipped=0) Objects,(SELECT COUNT(*) FROM sys.extended_properties WITH (NOLOCK) WHERE class=0 AND name LIKE N'Toolbelt.Module.%') Markers;" -Rows)
        if ($left.Count -ne 1 -or $left[0].Objects -ne 0 -or $left[0].Markers -ne 0) {throw 'RELEASE_UNINSTALL_RESIDUE'}
        $db.Dispose(); $ledger.completedModes+=@($mode); Save-ReleaseJournal
    }
    Assert-ReleaseInputs
} catch {
    $sqlError=$_.Exception; while ($sqlError.InnerException) {$sqlError=$sqlError.InnerException}
    $number=if ($sqlError -is [Data.SqlClient.SqlException]) {$sqlError.Number} else {0}
    $reason=if ($sqlError.Message -cmatch '^RELEASE_[A-Z0-9_]+$') {$sqlError.Message} else {'RELEASE_UNCLASSIFIED'}
    $failure=[ordered]@{stage=$stage;sqlNumber=$number;reason=$reason}
    # Diagnosen bleiben ausschließlich im privaten Journal; stdout enthält
    # weder SQL-Fehlertexte noch Namen des ausgewählten Labs.
    if ($ledger -and -not $AuditOnly) {
        $ledger['privateDiagnostic']=$sqlError.Message
    }
    if ($ledger -and -not $AuditOnly) {$ledger.failure=$failure; Save-ReleaseJournal}
} finally {
    foreach ($connection in $connections) {try {$connection.Dispose()} catch {}}
    if ($ledger -and -not $AuditOnly) {
        $cleanup=$true
        try {
            $control=Open-ReleaseConnection 'master'
            foreach ($entry in $ledger.databases) {
                Assert-ReleaseOwnIdentity $control $entry
                $entry.state='DROPPED'; Save-ReleaseJournal
            }
            $ledger.state=if ($failure) {'FAILED_CLEANED'} else {'COMPLETE'}
            Save-ReleaseJournal
        } catch {$ledger.state='CLEANUP_BLOCKED'; Save-ReleaseJournal; $failure=@{stage='CLEANUP';sqlNumber=0;reason='RELEASE_CLEANUP_BLOCKED'}}
        finally {if ($control) {$control.Dispose()}}
    }
}
if ($failure) {Write-Output ('FAIL '+($failure|ConvertTo-Json -Compress)); exit 1}
Write-Output 'PASS RELEASE_STABLE_PACKAGE_INSTALL_REPEAT_CONSUMER_UNINSTALL'
