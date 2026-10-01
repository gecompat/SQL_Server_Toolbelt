[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
try {
 Import-Module (Join-Path $PSScriptRoot '../../ExternalQueueWorker.psm1') -Force
 $options=$env:TBX_EXTERNAL_QUEUE_TEST_OPTIONS | ConvertFrom-Json -AsHashtable
 # Private Verbindungen werden ausschließlich aus der geerbten Prozessumgebung gelesen.
 $events=@()
 $summary=Start-ExternalQueueWorker @options -InformationVariable events
 [pscustomobject]@{Summary=$summary;Events=@($events | ForEach-Object {$_.MessageData})} | ConvertTo-Json -Depth 8 -Compress
} catch {
 [Console]::Error.WriteLine('Synthetic worker child failed; private diagnostics suppressed.')
 exit 1
}
