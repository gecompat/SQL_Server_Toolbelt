param(
    [Parameter(Mandatory)][string]$InputFile,
    [Parameter(Mandatory)][string]$OutputFile,
    [Parameter(Mandatory)][string]$ScriptDomDllPath
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
# Ausschließlich SQL-Syntaxanalyse im Buildprozess; keine Verbindung oder Ausführung.
$pin='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
if((Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $pin){throw 'MARKERLESS_SOURCE_PARSER_PIN'}
if(Test-Path -LiteralPath $OutputFile){throw 'MARKERLESS_SOURCE_NEW_OUTPUT_REQUIRED'}
Add-Type -LiteralPath $ScriptDomDllPath
$parser=[Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser]::new($true)
$sources=Get-Content -LiteralPath $InputFile -Raw -Encoding utf8|ConvertFrom-Json
$result=@(foreach($source in $sources){
    $errors=$null;$reader=[IO.StringReader]::new([string]$source.sql)
    try{$script=$parser.Parse($reader,[ref]$errors)}finally{$reader.Dispose()}
    if($errors.Count -ne 0){throw ('MARKERLESS_SOURCE_SYNTAX: '+$source.path)}
    $statements=@(foreach($batch in $script.Batches){foreach($statement in $batch.Statements){
        $kind=$statement.GetType().Name
        $name=$null
        switch -Regex ($kind){
            '^Create(?:OrAlter)?ProcedureStatement$' {$name=$statement.ProcedureReference.Name;break}
            '^Create(?:OrAlter)?FunctionStatement$' {$name=$statement.Name;break}
            '^Create(?:OrAlter)?ViewStatement$' {$name=$statement.SchemaObjectName;break}
        }
        $qualified=$null
        if($name){
            if($name.Identifiers.Count -ne 2){throw 'MARKERLESS_SOURCE_QUALIFIED_NAME_REQUIRED'}
            $qualified=($name.Identifiers|ForEach-Object {$_.Value}) -join '.'
            if($qualified -cnotmatch '^toolbelt_[a-z]+\.[A-Za-z][A-Za-z0-9_]*$'){throw 'MARKERLESS_SOURCE_OBJECT_NAME'}
        }
        [pscustomobject]@{kind=$kind;name=$qualified;sql=([string]$source.sql).Substring($statement.StartOffset,$statement.FragmentLength)}
    }})
    [pscustomobject]@{path=$source.path;statements=$statements}
})
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputFile),($result|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
