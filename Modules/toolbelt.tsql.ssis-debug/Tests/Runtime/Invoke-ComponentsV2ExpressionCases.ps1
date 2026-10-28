# Fixed scalar oracles on the existing synthetic flow; no SSIS package execution.
$expressionCases=@(
    @{name='TERNARY_NULL_CONDITION';expression='NULL(DT_BOOL)?1:2';expected=$null},
    @{name='TERNARY_UNSELECTED_FALSE_ARM';expression='TRUE?7:(DT_I4)"bad"';expected=7},
    @{name='TERNARY_UNSELECTED_TRUE_ARM';expression='FALSE?(DT_I4)"bad":2';expected=2},
    @{name='INNER_DT_STR_KEEPS_UNICODE';expression='((DT_STR,1,1252)"雪" == "雪") ? 7 : 8';expected=7},
    @{name='INTEGER_REFERENCE_TO_WSTR';expression='((DT_STR,50,1252)[Amount] == "100") ? 1 : 0';expectedByAmount=$true},
    @{name='ROOT_DT_STR_CODEPAGE_BEFORE_BYTES';expression='(DT_STR,2,1252)"éé"';expected='éé';ssisType='str';length='2';codePage='1252'},
    @{name='BOOLEAN_INTEGER_MINUS_ONE';expression='(DT_I4)TRUE';expected=-1},
    @{name='LEN_COUNTS_TRAILING_SPACES';expression='LEN("x  ")';expected=3},
    @{name='REPLACE_EMPTY_REPLACEMENT';expression='LEN(REPLACE("abca","a",""))';expected=2},
    @{name='SUBSTRING_PAST_END';expression='LEN(SUBSTRING("abc",2,10))';expected=2},
    @{name='TYPED_NULL_NUMERIC_ZERO_SCALE';expression='ISNULL(NULL(DT_NUMERIC,10,0))?1:0';expected=1}
)
$expressionOrdinal=0
foreach($case in $expressionCases){
    [xml]$packageXml=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
    foreach($component in $packageXml.SelectNodes('//component[@name="Derived" or @name="Split"]')){
        $component.RemoveAttribute('version')
        $input=$component.SelectSingleNode('inputs/input').GetAttribute('refId')
        foreach($port in $component.SelectNodes('outputs/output')){$port.SetAttribute('synchronousInputId',$input)}
    }
    $expressionNode=$packageXml.SelectSingleNode('//component[@name="Derived"]/outputs/output/outputColumns/outputColumn[@name="Adjusted"]/properties/property[@name="Expression"]')
    if(-not $expressionNode){throw 'SSIS_V2_EXPRESSION_FIXTURE_STRUCTURE'}
    $expressionNode.InnerText=$case.expression
    if($case.ContainsKey('ssisType')){
        $column=$expressionNode.ParentNode.ParentNode
        $column.SetAttribute('dataType',$case.ssisType);$column.SetAttribute('length',$case.length);$column.SetAttribute('codePage',$case.codePage)
    }
    $caseBytes=[Text.Encoding]::UTF8.GetBytes($packageXml.OuterXml)
    $index=Invoke-V2Explain -Bytes $caseBytes -Operation 'explain' -Catalog $catalog -Collation 'Latin1_General_100_BIN2'
    if($expressionOrdinal -eq 0){
        $workflowRow=@($index.Rows|Where-Object {$_.ArtifactKind -ceq 'Workflow' -and -not $_.IsNull('ComponentId')})[0]
        $workflow=([string]$workflowRow.Content)|ConvertFrom-Json -Depth 32
        $derived=@($workflow.components|Where-Object id -CEQ 'Package\Flow\Derived')[0]
        Assert-V2 ($derived.version -eq 0 -and $derived.versionPresent -eq $false -and $derived.versionOrigin -ceq 'schema-default-0') 'MISSING_VERSION_NATIVE_SCHEMA_DEFAULT_ZERO'
    }
    $stage=@($index.Rows|Where-Object {$_.ArtifactKind -ceq 'StageIndex' -and $_.ComponentId -ceq 'Package\Flow\Derived'})[0]
    $analysis=Invoke-V2Explain -Bytes $caseBytes -Operation 'explain' -Catalog $catalog -Target ([string]$stage.TargetFlowId) -Stage ([string]$stage.StageId) -Collation 'Latin1_General_100_BIN2'
    $projection=@($analysis.Rows|Where-Object {$_.ArtifactKind -ceq 'StageSql' -and $_.StageId -ceq $stage.StageId})[0]
    Assert-V2 ($projection.IsExecutable -eq $true -and $projection.IsComplete -eq $true) ($case.name+'_COMPLETE')
    $caseParts=Get-V2PlanParts $analysis $projection
    Invoke-V2Units $caseParts
    try{
        $rows=Invoke-V2Sql ([string]$projection.Content)
        Assert-V2 ($rows.Rows.Count -eq 5) ($case.name+'_ROWS')
        foreach($row in $rows.Rows){
            if($case.ContainsKey('expectedByAmount')){Assert-V2 ($row.Adjusted -eq $(if($row.Amount -eq 100){1}else{0}) -and $row.Adjusted -is [int]) $case.name}
            elseif($null -eq $case.expected){Assert-V2 ($row.IsNull('Adjusted')) $case.name}
            elseif($case.ContainsKey('ssisType')){Assert-V2 ($row.Adjusted -ceq $case.expected -and $row.Adjusted -is [string]) $case.name}
            else{Assert-V2 ($row.Adjusted -eq $case.expected -and $row.Adjusted -is [int]) $case.name}
        }
    }finally{Clear-V2Plan $caseParts}
    $expressionOrdinal++
}
"SSIS_V2_NATIVE_EXPRESSION_PASS $script:v2Checks cumulative assertions; fixed scalar oracles"
