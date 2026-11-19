# Gegenproben mit synthetischem sqlcmd; niemals eine SQL-Verbindung öffnen.
param([string]$BundleRoot=(Join-Path $PSScriptRoot '../..'))
class ProvisioningConnectionStub {
    ProvisioningConnectionStub([string]$unused) {}
    [void]Open() {}
    [void]Dispose() {}
}
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $BundleRoot 'Deployment/Install-Toolbelt.ps1') -DeploymentMode local
$script:count=0;$script:calls=0;$script:failure='';$script:ambiguous=$false;$script:journalPaths=@()
$script:createdGuid='00000000-0000-0000-0000-000000000001'
function Check([bool]$Ok,[string]$Message){$script:count++;if(!$Ok){throw ('PROVISIONING_TEST '+$Message)}}
function Fails([scriptblock]$Action,[string]$Code){$caught=$false;try{& $Action|Out-Null}catch{$caught=$_.Exception.Message.Contains('['+$Code+']')};Check $caught ('expected '+$Code)}
$script:plan=@{database_name="Contoso]O'Brien ";platform='Windows';database_guid=$null;configurations=@(@{configuration_id=1;configured=0;running=0})}|ConvertTo-Json -Compress
$script:realJournal=(Get-Item Function:New-ToolbeltPreparationJournal).ScriptBlock
function New-ToolbeltPreparationJournal($Database,$Server,$Plan){$j=& $script:realJournal $Database $Server $Plan;$script:journalPaths+=$j.Path;return $j}
function Invoke-ToolbeltNativeProcess($StartInfo,$TimeoutSeconds){
    if($StartInfo.ArgumentList.Contains('-?')){return @{ExitCode=0;Stdout='SQL Server Command Line Tool';Stderr=''}}
    $script:calls++
    Check ($StartInfo.ArgumentList.Contains('-N') -and $StartInfo.ArgumentList.Contains('-b') -and $StartInfo.ArgumentList.Contains('-x')) 'secure client flags'
    $argsList=@($StartInfo.ArgumentList);$file=$argsList[[array]::IndexOf($argsList,'-i')+1]
    $sql=[IO.File]::ReadAllText($file)
    if([IO.Path]::GetFileName($file) -eq 'prepare.sql'){
        Check ($StartInfo.ArgumentList[$StartInfo.ArgumentList.IndexOf('-d')+1] -ceq 'master') 'preparation always master'
        if($sql.Contains('TBX_PREPARATION_OK')){
            Check ($script:calls -eq 2) 'plan precedes mutation'
            Check ($sql.Contains("EXEC(N'CREATE DATABASE [Contoso]]O''Brien ]')")) 'dynamic identifier/literal double escaped'
            if($script:failure){return @{ExitCode=1;Stdout='';Stderr=$script:failure}}
            $createdLine=$(if($script:createdGuid){"TBX_PREPARATION_DATABASE_CREATED`nTBX_PREPARATION_CREATED_GUID|$script:createdGuid`n"}else{''})
            return @{ExitCode=0;Stdout=($createdLine+"TBX_PREPARATION_CLR_ENABLED`nTBX_PREPARATION_TARGET|00000000-0000-0000-0000-000000000001`nTBX_PREPARATION_OK");Stderr=''}
        }
        Check ($sql -notmatch 'RECONFIGURE|CREATE DATABASE \[') 'plan read-only'
        $hex=[Convert]::ToHexString([Text.Encoding]::Unicode.GetBytes($script:plan));$lines=@();$i=0
        for($offset=0;$offset -lt $hex.Length;$offset+=160){$lines+=('TBX_PREPARATION_PART|{0:d4}|{1}' -f $i,$hex.Substring($offset,[Math]::Min(160,$hex.Length-$offset)));$i++}
        if($script:ambiguous){$lines[0]=$lines[0].Replace('0000','0001')}
        return @{ExitCode=0;Stdout=(($lines+('TBX_PREPARATION_PARTS|'+$i)) -join "`n");Stderr=''}
    }
    if([IO.Path]::GetFileName($file) -eq 'preflight.sql'){return @{ExitCode=0;Stdout='TBX_PREFLIGHT|Windows|00000000-0000-0000-0000-000000000001';Stderr=''}}
    return @{ExitCode=0;Stdout='TBX_INSTALL_OK|45';Stderr=''}
}
$package=Join-Path $BundleRoot 'Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip'
$argsBase=@{DeploymentMode='local';ServerInstance='localhost';Database="Contoso]O'Brien ";PackageZip=$package;SqlcmdPath=(Get-Command pwsh -CommandType Application|Select-Object -First 1).Source}
try{
    foreach($create in @($false,$true)){foreach($enable in @($false,$true)){
        $script:calls=0
        $r=Invoke-ToolbeltInstall @argsBase -CreateDatabase:$create -EnableClr:$enable
        Check ($r.Status -eq 'INSTALLED' -and $script:calls -eq $(if($create -or $enable){4}else{2})) 'opt-in composition and receipt'
        if($r.PreparationJournal){
            $j=Get-Content $r.PreparationJournal -Raw|ConvertFrom-Json
            Check ($j.state -ceq 'PREPARATION_COMPLETE' -and $j.before.database_name -ceq $argsBase.Database -and $j.outcome.ClrEnabled) 'journal preserves unicode and trailing spaces'
            if($IsWindows){Check ((Get-Acl $r.PreparationJournal).AreAccessRulesProtected -or (Get-Acl (Split-Path $r.PreparationJournal)).AreAccessRulesProtected) 'private journal ACL'}
        }
    }}
    $script:calls=0
    $r=Invoke-ToolbeltInstall @argsBase -CreateDatabase -EnableClr -PreflightOnly
    Check ($r.Status -ceq 'PREPARATION_PREFLIGHT_OK' -and !$r.Mutations -and $script:calls -eq 1) 'preflight-only never prepares'
    $script:calls=0
    $r=Invoke-ToolbeltInstall @argsBase -CreateDatabase -EnableClr -ValidateOnly
    Check ($r.Status -ceq 'PACKAGE_OK' -and $script:calls -eq 0) 'validate-only stays offline'
    foreach($code in @('TBX_PENDING_CONFIGURATION','TBX_PREPARATION_DRIFT','TBX_MODEL','TBX_SECURITY','TBX_DATABASE_MISSING')){
        $script:calls=0;$script:failure=$code
        Fails {Invoke-ToolbeltInstall @argsBase -EnableClr -CreateDatabase} $code
        Check ($script:calls -eq 2) 'no install or retry after failed preparation'
    }
    $script:failure='';$script:ambiguous=$true;$script:calls=0
    Fails {Invoke-ToolbeltInstall @argsBase -EnableClr} 'PROBE'
    Check ($script:calls -eq 1) 'invalid plan blocks mutation'
    $script:ambiguous=$false
    $originalPlan=$script:plan
    foreach($scenario in @('existing','created')){
        $script:calls=0
        if($scenario -eq 'existing'){
            $p=$originalPlan|ConvertFrom-Json;$p.database_guid='00000000-0000-0000-0000-000000000002';$script:plan=$p|ConvertTo-Json -Compress;$script:createdGuid=''
        }else{$script:plan=$originalPlan;$script:createdGuid='00000000-0000-0000-0000-000000000002'}
        Fails {Invoke-ToolbeltInstall @argsBase -EnableClr -CreateDatabase} 'TBX_TARGET_CHANGED'
        Check ($script:calls -eq 2) ('replaced '+$scenario+' target rejected before regular probe/trust')
    }
    $script:plan=$originalPlan;$script:createdGuid='00000000-0000-0000-0000-000000000001'
    $planSql=Get-ToolbeltPreparationSql Contoso $true $true
    $mutation=Get-ToolbeltPreparationSql Contoso $true $true '{}'
    Check ($planSql -notmatch '(?m)^\s*RECONFIGURE|EXEC\(N''CREATE DATABASE') 'read-only SQL has no DDL'
    Check ($mutation.IndexOf('TBX_PREPARATION_DRIFT') -lt $mutation.IndexOf("EXEC(N'CREATE DATABASE")) 'snapshot guard before create'
    Check ($mutation -notmatch 'WITH OVERRIDE|TRUSTWORTHY ON|GRANT |CREATE LOGIN|DROP DATABASE') 'no unsafe mutations or rollback'
    Check ($mutation.Contains("name=N'clr strict security' AND value=1 AND value_in_use=1") -and $mutation.Contains("name=N'lightweight pooling' AND value=0 AND value_in_use=0")) 'strict and pooling configured/running guards'
    Check (([regex]::Matches($mutation,'(?m)^\s*RECONFIGURE;')).Count -eq 1) 'single bounded reconfigure site'
    Check (($mutation -split '(?m)^\s*RECONFIGURE;')[0].Contains('TBX_PENDING_CONFIGURATION')) 'reconfigure guarded'
    Check (-not $mutation.Contains("sp_configure N'show advanced options'")) 'advanced visibility untouched'
    # Gemeinsamen Connectionhelper ohne Netzwerk ausführen: der Hostadapter
    # muss dessen script:connections-Abhängigkeit initialisieren.
    $stable=Join-Path $PSScriptRoot '../../Tests/Release/Invoke-StablePackageLab.ps1'
    $ast=[Management.Automation.Language.Parser]::ParseFile($stable,[ref]$null,[ref]$null)
    $node=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Open-ReleaseConnection'},$true))
    Check ($node.Count -eq 1) 'canonical connection helper discovered'
    $source=$node[0].Extent.Text.Replace('[Data.SqlClient.SqlConnection]::new','[ProvisioningConnectionStub]::new')
    $source=$source.Replace('[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $script:target -TestPurpose Functional))', '[Data.Common.DbConnectionStringBuilder]::new(); $builder.ConnectionString=(New-LabConnectionString)')
    . ([scriptblock]::Create($source))
    function Assert-ReleaseInputs {}
    function Get-ReleaseTimeout { 10 }
    function New-LabConnectionString { 'Server=localhost;Integrated Security=True;Encrypt=True;TrustServerCertificate=False' }
    $script:target=@{}
    Remove-Variable connections -Scope Script -ErrorAction SilentlyContinue
    $missingCollection=$false;try{Open-ReleaseConnection master|Out-Null}catch{$missingCollection=$true}
    Check $missingCollection 'counterprobe reproduces absent adapter collection without SQL'
    $script:connections=[Collections.Generic.List[object]]::new()
    $stub=Open-ReleaseConnection master
    Check ($script:connections.Count -eq 1 -and $stub -is [ProvisioningConnectionStub]) 'initialized adapter collection accepts connection'
    $stub.Dispose()
}finally{
    # Auch fehlgeschlagene synthetische Journale gehören zum Test; nur unsere
    # localhost-/Contoso-Datensätze löschen, keine fremden Installationsjournale.
    $root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SQL_Server_Toolbelt/InstallJournals'
    foreach($path in $script:journalPaths){[IO.File]::Delete($path);[IO.Directory]::Delete((Split-Path $path),$false)}
}
"PASS INSTALLER_PROVISIONING: $script:count synthetic assertions; native SQL not executed"
