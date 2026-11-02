# Ein eigener sichtbarer Einstieg; historische Methoden werden nicht verändert.
$prior=Join-Path $PSScriptRoot 'AutonomousSsmsHook.ps1'
if((Get-FileHash $prior).Hash-cne '53BB49D816C91B5A2130FD5104153C3EE8CA6AD7A089980774C53D1EFD456379'){throw 'VISIBLE_SSMS_PRIOR_HOOK_CHANGED'}
. $prior
$preflight=(Get-Command Invoke-SsmsTargetPreflight).Definition
$preflight=Replace-SsmsHookOnce $preflight " foreach(`$a in @('-S',`$builder.DataSource,'-d','master','-N','Mandatory','-dn','SSIS-LAB-QUALIFICATION','-nosplash')){`$start.ArgumentList.Add(`$a)}" @'
 # Kein Verbindungsdialog darf das Hauptfenster vor dem Maximieren blockieren.
 $start.ArgumentList.Add('-nosplash')
'@
$preflight=Replace-SsmsHookOnce $preflight " if(`$builder.TrustServerCertificate){`$start.ArgumentList.Add('-C')}" @'
 # Der Operator setzt die ausgewählten TLS-Werte beim anschließenden Verbinden.
 # Das ist kein Trust-Fallback; der SQL-Vorcheck verlangt weiterhin Verschlüsselung.
'@
$preflight=Replace-SsmsHookOnce $preflight "displayName='SSIS-LAB-QUALIFICATION';database='master';databaseNotCreated=`$true" @'
displayName='Microsoft SQL Server Management Studio';database='master';databaseNotCreated=$true;targetDataSource=$builder.DataSource;encrypt='Mandatory';trustServerCertificate=[bool]$builder.TrustServerCertificate;manualConnectionRequired=$true;connectionArgumentsPassed=$false;ssmsStartedUtc=$script:ssmsTargetStarted
'@
. ([scriptblock]::Create('function Invoke-SsmsTargetPreflight {'+$preflight+'}'))
