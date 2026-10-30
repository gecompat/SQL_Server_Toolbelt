# Execute installed public procedures, never extracted Help-only stand-ins.
param([Parameter(Mandatory)]$Connection,[Parameter(Mandatory)][string]$Fixture,
      [Parameter(Mandatory)][ValidateSet('Windows','Portable')][string]$Platform,
      [Parameter(Mandatory)][ValidateSet('local','central')][string]$Mode,
      [Parameter(Mandatory)][datetime]$Deadline)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$cases=@(Get-Content -LiteralPath $Fixture -Raw | ConvertFrom-Json | Where-Object {
    -not ($Platform -ceq 'Portable' -and $_.windows_only) -and -not ($Mode -ceq 'central' -and $_.local_only)
})
$expectedNames=@('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql')
$messages=[Collections.Generic.List[string]]::new()
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$eventArgs) $messages.Add('MESSAGE')}
$Connection.add_InfoMessage($handler)
$assertions=0;$parameterCount=0
try {
    foreach($case in $cases){
        foreach($sql in $case.commands){
            $remaining=($Deadline-[datetime]::UtcNow).TotalSeconds
            if($remaining -lt 1){throw 'PARAMETER_HELP_CASE_DEADLINE'}
            $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=[int][Math]::Min(30,[Math]::Floor($remaining))
            # Help must preserve a healthy caller transaction and caller temp data.
            $cmd.CommandText="BEGIN TRANSACTION; CREATE TABLE #ParameterHelpWitness(Value int NOT NULL); INSERT #ParameterHelpWitness VALUES(17); "+$sql
            $reader=$null
            try {
                $reader=$cmd.ExecuteReader()
                if($reader.FieldCount -ne 12){throw 'PARAMETER_HELP_SHAPE'}
                for($i=0;$i -lt 12;$i++){if($reader.GetName($i) -cne $expectedNames[$i]){throw 'PARAMETER_HELP_COLUMN_ORDER'}}
                $rows=[Collections.Generic.List[object]]::new()
                while($reader.Read()){
                    if([datetime]::UtcNow -ge $Deadline){throw 'PARAMETER_HELP_READ_DEADLINE'}
                    $row=[ordered]@{}
                    foreach($name in $expectedNames){$value=$reader[$name];$row[$name]=if($value -is [DBNull]){$null}else{$value}}
                    $rows.Add([pscustomobject]$row)
                }
                if($reader.NextResult()){throw 'PARAMETER_HELP_EXTRA_RESULTSET'}
                $reader.Dispose();$reader=$null
                $parts=$case.name.Split('.')
                if(@($rows|Where-Object {$_.HelpContractVersion -cne '1.0' -or $_.SchemaName -cne $parts[0] -or $_.ObjectName -cne $parts[1]}).Count){throw 'PARAMETER_HELP_IDENTITY'}
                $actual=@($rows|Where-Object Section -ceq 'PARAMETER'|Sort-Object Ordinal)
                if($actual.Count -ne $case.parameters.Count){throw 'PARAMETER_HELP_COUNT'}
                for($i=0;$i -lt $actual.Count;$i++){
                    $a=$actual[$i];$e=$case.parameters[$i]
                    if($a.Ordinal -ne $i+1 -or $a.ItemName -cne $e.name -or $a.SqlDataType -cne $e.type -or
                       $a.IsRequired -ne $e.required -or $a.IsNullable -ne $e.nullable -or
                       $a.DefaultValue -cne $e.default -or $a.Description -cne $e.description){throw ('PARAMETER_HELP_VALUE '+$case.name+' '+$e.name)}
                    $assertions+=7
                }
                foreach($section in @('DESCRIPTION','RESULT_COLUMN','EXAMPLE')){
                    if(-not @($rows|Where-Object Section -ceq $section).Count){throw 'PARAMETER_HELP_SECTION'}
                }
                if(@($rows|Where-Object {$_.Section -ceq 'EXAMPLE' -and $_.ExampleSql}).Count -lt 1){throw 'PARAMETER_HELP_EXAMPLE'}
                $cmd.CommandText="IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR (SELECT COUNT(*) FROM #ParameterHelpWitness WHERE Value=17)<>1 THROW 52097,N'Help changed caller state.',1; DROP TABLE #ParameterHelpWitness; ROLLBACK;"
                [void]$cmd.ExecuteNonQuery()
                if($messages.Count){throw 'PARAMETER_HELP_MESSAGE'}
                $assertions+=18
            } finally {if($reader){$reader.Dispose()};$cmd.Dispose()}
        }
        $parameterCount+=$case.parameters.Count
    }
    $internal=@($cases|Where-Object internal).Count
    [pscustomobject]@{procedures=$cases.Count-$internal;parameters=$parameterCount-38*$internal;internalProcedures=$internal;internalParameters=38*$internal;calls=2*$cases.Count;assertions=$assertions}
} finally {
    $Connection.remove_InfoMessage($handler)
    $cleanup=$Connection.CreateCommand();$cleanup.CommandTimeout=15
    try{$cleanup.CommandText='IF @@TRANCOUNT>0 ROLLBACK; IF OBJECT_ID(N''tempdb..#ParameterHelpWitness'') IS NOT NULL DROP TABLE #ParameterHelpWitness;';[void]$cleanup.ExecuteNonQuery()}finally{$cleanup.Dispose()}
}
