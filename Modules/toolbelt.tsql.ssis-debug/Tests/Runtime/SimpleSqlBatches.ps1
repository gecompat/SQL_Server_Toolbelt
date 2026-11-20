# Offline parse first; GO inside literals/comments is never a separator.
function Get-SimpleSqlBatches([string]$Text,[string]$ScriptDomDllPath) {
    $expected='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
    if((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $expected){throw 'SIMPLE_BATCH_PARSER_PIN'}
    Add-Type -LiteralPath $ScriptDomDllPath
    $parser=[Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
    $errors=$null;$reader=[IO.StringReader]::new($Text)
    try{$script=$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
    if($errors.Count -ne 0){throw 'SIMPLE_BATCH_INVALID_SQL'}
    foreach($batch in $script.Batches){
        if($batch.Statements.Count -gt 0){$Text.Substring($batch.StartOffset,$batch.FragmentLength)}
    }
}
