# Native Geoqualifikation verwendet seit dem vorhandenen Geo-/Translateadapter
# ExecuteNonQuery und 120 Sekunden pro SQL-Batch. Keine Laufzeitzusage.
function Invoke-GeoCanonicalBatches($Connection,[string]$Sql) {
    $ordinal=0
    foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')) {
        if([string]::IsNullOrWhiteSpace($batch)){continue}
        $remaining=300000-$script:clock.ElapsedMilliseconds
        if($remaining -lt 1000){throw 'RELEASE_DEADLINE'}
        $command=$Connection.CreateCommand()
        try {
            $command.CommandTimeout=[int][Math]::Min(120,[Math]::Floor($remaining/1000))
            $command.CommandText=$batch
            $ordinal++
            Write-Output ('GEO_CANONICAL_BATCH '+$ordinal)
            [void]$command.ExecuteNonQuery()
        } finally {$command.Dispose()}
    }
}
