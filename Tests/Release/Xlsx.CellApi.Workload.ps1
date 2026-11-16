# Der neue Scope verwendet ausschließlich vier unveränderte öffentliche Fixtures.
# Der bestehende Paket-/Ownership-/Cleanup-Adapter bleibt gemeinsamer Kern.
function Assert-XlsxCellApiWorkload($Runset, [int]$Index, [string]$Repository) {
    if ($Runset.qualification_scope -ceq 'cell-api-rest') {
        if ($Index -notin @(1,2,3,4,5,6,7,8)) { throw 'XLSX_CELL_ALREADY_QUALIFIED_CONTEXT' }
        $names = @('Types.Contract.sql','Types.Safety.sql','Display.Contract.sql','Display.Safety.sql')
    } elseif ($Runset.qualification_scope -ceq 'cell-display-rest') {
        if ($Index -notin @(9,10,11)) { throw 'XLSX_CELL_ALREADY_QUALIFIED_CONTEXT' }
        $names = @('Display.Contract.sql','Display.Safety.sql')
    } else { throw 'XLSX_CELL_SCOPE_INVALID' }
    if ($Runset.workbooks.Count -ne $names.Count -or ($Runset.workbooks.name -join '|') -cne ($names -join '|')) {
        throw 'XLSX_CELL_FIXTURE_SET'
    }
    foreach ($book in $Runset.workbooks) {
        $source = Join-Path $Repository ('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/' + $book.name)
        $expected = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        if ($book.expected_error -cne 'NONE' -or $expected.ToLowerInvariant() -cne $book.sha256 -or
            (Get-FileHash -LiteralPath $book.path -Algorithm SHA256).Hash -cne $expected) {
            throw 'XLSX_CELL_ORIGINAL_FIXTURE_DRIFT'
        }
        foreach ($path in @($source,$book.path,(Join-Path $Repository 'Tests/Release/Xlsx.CellApi.Workload.ps1'),
                            (Join-Path $Repository 'Tests/Release/Prepare-XlsxCellApiRunset.ps1'))) {
            $pin = @($Runset.pins | Where-Object path -CEQ $path)
            if ($pin.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pin[0].sha256) {
                throw 'XLSX_CELL_REQUIRED_PIN'
            }
        }
    }
}
