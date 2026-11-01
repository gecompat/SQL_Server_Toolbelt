# Clientprofil: tatsächliche öffentliche Erst-/Wiederholungsinstallation und
# sichtbarer SSMS-Transport. Keine Zugangsdaten werden gelesen oder gespeichert.
function New-ClientTrustWitnessCommand($Connection,[string]$Hash,[datetime]$Started){
 # SYSDATETIME besitzt sieben Nachkommastellen. Keine localeabhängige
 # Zeichenfolge und keine Konvertierung zum engeren SQL-datetime-Typ.
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=30
 $cmd.CommandText='SELECT description,CASE WHEN created_by=SUSER_SNAME() AND create_date>=@started THEN 1 ELSE 0 END AS Own FROM sys.trusted_assemblies WHERE hash=@hash;'
 [void]$cmd.Parameters.Add('@started',[Data.SqlDbType]::DateTime2);$cmd.Parameters['@started'].Scale=7;$cmd.Parameters['@started'].Value=$Started
 [void]$cmd.Parameters.Add('@hash',[Data.SqlDbType]::VarBinary,64);$cmd.Parameters['@hash'].Value=[Convert]::FromHexString($Hash)
 return $cmd
}
function Invoke-ClientInstallation {
 $auth=Query-Client $master "SELECT CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) AS A,IS_SRVROLEMEMBER(N'sysadmin') AS S;"
 Check ($auth.Rows[0].A-cin @('NTLM','KERBEROS') -and $auth.Rows[0].S-eq 1) 'EXISTING_WINDOWS_SYSADMIN_CLIENT'
 $journal.authentication='Windows';$journal.authScheme=[string]$auth.Rows[0].A
 $hashes=@((Get-FileHash (Join-Path $plan.ssis 'Toolbelt.Tsql.SsisDebug.dll') -Algorithm SHA512).Hash,
  (Get-FileHash (Join-Path $plan.parser 'Toolbelt.Tsql.ScriptParser.dll') -Algorithm SHA512).Hash,
  (Get-FileHash (Join-Path $plan.parser 'Microsoft.SqlServer.TransactSql.ScriptDom.dll') -Algorithm SHA512).Hash)
 foreach($hash in $hashes){
  $exists=Query-Client $master ('SELECT COUNT_BIG(*) AS N FROM sys.trusted_assemblies WHERE hash=0x'+$hash+';')
  if($exists.Rows[0].N-eq 0){
   $consumers=Get-RecoveryConsumers $master $hash;if($consumers.Count){throw 'SSIS_CLIENT_UNTRUSTED_EXISTING_CONSUMER'}
   $journal.ownedTrust+=@{hash=$hash;description='PENDING_PUBLIC_INSTALLER_WITNESS'}
  }
 }
 $journal.state='PUBLIC_INSTALLER_DISPATCHED';Save
 $started=[datetime](Query-Client $master "SELECT DATEADD(second,-1,SYSDATETIME()) AS T;").Rows[0].T
 $journal.installerWitnessStarted=$started.ToString('O',[Globalization.CultureInfo]::InvariantCulture);Save
 $installer=Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Examples/Installation/Install-Local.ps1'
 try{
  & $installer -Server $builder.DataSource -Database $db -RepositoryRoot $repoRoot -ParserReleaseDirectory $plan.parser -SsisReleaseDirectory $plan.ssis -SqlcmdPath $plan.sqlcmd -TrustServerCertificate ([bool]$builder.TrustServerCertificate)
 }finally{
  # Der öffentliche Installationsvertrag verwendet feste Descriptortexte.
  # Nur vorher fehlende Hashes mit frischem eigenem Actor/Datum werden gebunden.
  foreach($entry in $journal.ownedTrust){
   $cmd=New-ClientTrustWitnessCommand $master $entry.hash $started
   try{$r=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{$r.Load($reader)}finally{$reader.Dispose()}}finally{$cmd.Dispose()}
   if($r.Rows.Count-eq 1 -and $r.Rows[0].Own-eq 1){$entry.description=[string]$r.Rows[0].description}
  }
  Save
 }
 $after=Get-RecoveryTrust $master
 & $installer -Server $builder.DataSource -Database $db -RepositoryRoot $repoRoot -ParserReleaseDirectory $plan.parser -SsisReleaseDirectory $plan.ssis -SqlcmdPath $plan.sqlcmd -TrustServerCertificate ([bool]$builder.TrustServerCertificate)
 Check (Same-Client (Get-RecoveryTrust $master) $after) 'PUBLIC_INSTALLER_REPEAT_PRESERVES_TRUST'
 $journal.publicInstallerPasses=2;Save
 # Der Adapter ersetzt auch die kanonische manuelle Deploymentverbindung.
 # Daher nach den öffentlichen Phasen genau einen eigenen Verbraucher öffnen.
 $script:connection=Open-ClientSql $target $db -Windows
}
function Get-ClientGuiPackage {
 [xml]$doc=[Text.Encoding]::UTF8.GetString((Get-RecoveryPackage))
 $commands=@($doc.SelectNodes('//*[local-name()="property" and @name="SqlCommand"]')|Where-Object {$_.InnerText.Contains('FROM dbo.SyntheticSourceA')})
 if($commands.Count-ne 1){throw 'SSIS_CLIENT_UNICODE_FIXTURE_ANCHOR'}
 $commands[0].InnerText += " AND N'Grüße Ω' = N'Grüße Ω'"
 return ,[Text.Encoding]::UTF8.GetBytes($doc.OuterXml)
}
function Invoke-ClientGui {
 $receipt='SyntheticSsisGuiReceipt'
 Exec-Client $connection ('CREATE TABLE dbo.'+$receipt+'(Token varchar(32) NOT NULL,Phase int NOT NULL,ExpectedHash varbinary(32) NULL,Auth nvarchar(40) NULL,Application nvarchar(128) NULL);INSERT dbo.'+$receipt+"(Token,Phase) VALUES('"+$token+"',0);")
 $catalogSql="N'"+$catalog.Replace("'","''")+"'"
 $guard="IF CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')) NOT IN(N'NTLM',N'KERBEROS') THROW 51000,N'WINDOWS_CLIENT_AUTH_REQUIRED',1;`nIF NOT EXISTS(SELECT 1 FROM sys.dm_exec_connections WHERE session_id=@@SPID AND encrypt_option=N'TRUE') THROW 51000,N'ENCRYPTED_CONNECTION_REQUIRED',1;`nIF APP_NAME() NOT LIKE N'Microsoft SQL Server Management Studio%' THROW 51000,N'SSMS_APPLICATION_REQUIRED',1;`n"
 $analysis="-- SSIS-Qualifikation: Windows-Anmeldung, aktuelle API und vollständiger Scripttransport.`nUSE ["+$db+"];`n"+$guard
 $analysis+="DECLARE @bytes varbinary(max)=0x"+[Convert]::ToHexString($bytes)+",@catalog nvarchar(max)="+$catalogSql+",@bindings nvarchar(max);`nCREATE TABLE #GuiArtifacts(Dummy bit NULL);`nEXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@bytes,@Operation=N'bindings-template',@ResultTable=N'#GuiArtifacts';`nSELECT @bindings=Content FROM #GuiArtifacts WHERE ArtifactKind=N'BindingsTemplate';`nEXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@bytes,@Operation=N'explain',@Bindings=@bindings,@CatalogBindings=@catalog,@TSqlVersion=150,@ResultTable=N'#GuiArtifacts';`nDECLARE @script nvarchar(max)=(SELECT Content FROM #GuiArtifacts WHERE ArtifactKind=N'DebugScript' AND ComponentId=N'Package\Flow\DestinationHigh' AND IsComplete=1 AND IsExecutable=1);`nIF @script IS NULL OR CHARINDEX(N'Grüße Ω',@script)=0 THROW 51000,N'COMPLETE_UNICODE_SCRIPT_REQUIRED',1;`nUPDATE dbo."+$receipt+" SET Phase=1,ExpectedHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),REPLACE(@script,CHAR(13)+CHAR(10),CHAR(10)))),Auth=CONVERT(nvarchar(40),CONNECTIONPROPERTY('auth_scheme')),Application=APP_NAME() WHERE Token='"+$token+"';`nSELECT @script AS Content;`nDROP TABLE #GuiArtifacts;`n"
 $analysisPath=$JournalPath+'.01-Windows-API.sql';[IO.File]::WriteAllText($analysisPath,$analysis,[Text.UTF8Encoding]::new($true))
 $completePath=$JournalPath+'.03-Client-Receipt.sql'
 $complete="USE ["+$db+"];`n"+$guard+"UPDATE dbo."+$receipt+" SET Phase=2 WHERE Token='"+$token+"' AND Phase=1 AND Auth IN(N'NTLM',N'KERBEROS');`nSELECT N'SSIS_WINDOWS_CLIENT_GUI_PASS' AS Result,N'Grüße Ω' AS UnicodeWitness;`nUSE master;`n"
 [IO.File]::WriteAllText($completePath,$complete,[Text.UTF8Encoding]::new($true))
 $ssmsPath=[string]$plan.ssms
 if((Get-FileHash $ssmsPath).Hash-cne $plan.ssmsSha256){throw 'SSIS_CLIENT_SSMS_EXECUTABLE_CHANGED'}
 $start=[Diagnostics.ProcessStartInfo]::new($ssmsPath);$start.UseShellExecute=$false
 foreach($a in @($analysisPath,'-S',$builder.DataSource,'-d',$db,'-nosplash')){$start.ArgumentList.Add($a)}
 if($builder.TrustServerCertificate){$start.ArgumentList.Add('-C')}
 $app=[Diagnostics.Process]::Start($start)
 $appStarted=$app.StartTime.ToUniversalTime().ToString('o')
 Save-ClientPrivate ($JournalPath+'.gui-ready.json') @{state='GUI_READY';ssmsPid=$app.Id;analysisPath=$analysisPath;completionPath=$completePath;copiedPath=($JournalPath+'.02-Copied-DebugScript.sql');visualPath=($JournalPath+'.visual.json');deadlineSeconds=900}
 $journal.state='WAITING_FOR_VISIBLE_GUI';Save
 $clock=[Diagnostics.Stopwatch]::StartNew();$produced=$false;$passed=$false
 try{while($clock.Elapsed.TotalSeconds-lt 900){
  if([datetimeoffset]::UtcNow-ge [datetimeoffset]::Parse((Get-Content $BudgetPath -Raw|ConvertFrom-Json -DateKind String).ceilingUtc)){break}
  $r=Query-Client $connection ('SELECT Phase,CONVERT(varchar(64),ExpectedHash,2) AS H,Auth,Application FROM dbo.'+$receipt+" WHERE Token='"+$token+"';")
  if($r.Rows[0].Phase-ge 1 -and -not $produced){
   Save-ClientPrivate ($JournalPath+'.gui-produced.json') @{expectedUtf16LfSha256=[string]$r.Rows[0].H;auth=[string]$r.Rows[0].Auth;application=[string]$r.Rows[0].Application};$produced=$true
  }
  if($r.Rows[0].Phase-eq 2 -and $app.HasExited -and (Test-Path ($JournalPath+'.visual.json'))){
   $visual=Get-Content ($JournalPath+'.visual.json') -Raw|ConvertFrom-Json -DateKind String
   $copy=[IO.File]::ReadAllText($JournalPath+'.02-Copied-DebugScript.sql').Replace("`r`n","`n")
   $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::Unicode.GetBytes($copy)))
   Check ($visual.result-ceq 'PASS' -and $visual.targetRows-eq 2 -and $visual.messagesErrors-eq 0 -and $visual.scriptUtf16LfSha256-ceq $hash) 'SEPARATE_VISUAL_RESULTS_AND_SCRIPT_BINDING'
   Check ($hash-ceq [string]$r.Rows[0].H -and $copy.Contains('Grüße Ω')) 'COMPLETE_GUI_COPY_UNICODE_TRANSPORT'
   Check ($r.Rows[0].Auth-cin @('NTLM','KERBEROS') -and $r.Rows[0].Application-like 'Microsoft SQL Server Management Studio*') 'ACTUAL_SSMS_WINDOWS_LOGIN'
   $passed=$true;break
  }
  Start-Sleep -Milliseconds 500
 }}finally{
  if(-not $passed -and -not $app.HasExited){
   # Ausschließlich die neu gestartete eigene Instanz, nie bestehende Tabs.
   if($app.StartTime.ToUniversalTime().ToString('o')-cne $appStarted){throw 'SSIS_CLIENT_SSMS_PROCESS_OWNERSHIP_DRIFT'}
   $app.Kill();if(-not $app.WaitForExit(10000)){throw 'SSIS_CLIENT_OWN_SSMS_CLOSE_FAILED'}
  }
 }
 if(-not $passed){throw 'SSIS_CLIENT_GUI_NOT_COMPLETED_IN_BOUND'}
 $journal.cases=@(@{name='windows-public-installer-and-ssms-full-transport';result='PASS';publicInstallerPasses=2;guiCopyHashMatched=$true;unicodePreserved=$true;targetRows=2;ownSsmsClosed=$true});$journal.state='QUALIFICATION_COMPLETE';Save
}
