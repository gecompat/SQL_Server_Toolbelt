#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConnectionStringEnvironmentVariable,
    [Parameter(Mandatory)][string[]]$WorkerEligibleWorkTypes,
    [string[]]$RetryEligibleWorkTypes = @(), [int[]]$TransientSqlNumbers = @(),
    [int]$Slots = 1, [int]$MaxRunSeconds = 300, [int]$MaxClaims = 1000,
    [int]$ControlTimeoutSeconds = 5, [int]$ConnectTimeoutSeconds = 5,
    [double]$PollSeconds = 1, [int]$GraceSeconds = 30, [string]$StopFile = '',
    [switch]$Managed,[guid]$WorkerId=[guid]::Empty,
    [int]$Capacity=1,[ValidateSet('BOUNDED','CONTINUOUS')][string]$RunMode='BOUNDED'
)
# Keine Connection Strings auf der Commandline oder in Beispieldateien.
try {
    $ErrorActionPreference = 'Stop'
    Import-Module (Join-Path $PSScriptRoot 'ExternalQueueWorker.psm1') -Force
    Start-ExternalQueueWorker @PSBoundParameters -InformationAction Continue
} catch {
    # Auch Constructor-/Importfehler erhalten ausschließlich einen festen Code.
    [Console]::Out.WriteLine('{"Status":"RUN_FAILED","Code":"WORKER.RUN_FAILED"}')
    exit 1
}
