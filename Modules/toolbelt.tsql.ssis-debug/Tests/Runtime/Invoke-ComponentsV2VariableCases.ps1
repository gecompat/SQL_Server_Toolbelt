# Bound nullable string/integer references; optional long plan uses the same
# rounded synthetic form as the offline benchmark, without whitespace padding.
[void](Invoke-V2Sql @'
CREATE TABLE dbo.SyntheticV2TextA(KeyA nvarchar(10) NULL,KeyB int NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticV2TextB(KeyA nvarchar(10) NULL,KeyB int NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticV2TextLookup(KeyA nvarchar(10) NULL,KeyB int NULL,Score int NULL);
INSERT dbo.SyntheticV2TextA VALUES(N'5',7,100),(N'5',8,200),(NULL,7,300),(N'雪',7,400);
INSERT dbo.SyntheticV2TextB VALUES(NULL,8,500),(N'5',NULL,600);
INSERT dbo.SyntheticV2TextLookup VALUES(N'5',7,10);
'@)
try{
    [xml]$variable=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Tests/Fixtures/components-v2-variable-string.dtsx'))
    foreach($sql in $variable.SelectNodes('//property[@name="SqlCommand"]')){
        $sql.InnerText=$sql.InnerText.Replace('dbo.SyntheticSourceA','dbo.SyntheticV2TextA').Replace('dbo.SyntheticSourceB','dbo.SyntheticV2TextB').Replace('dbo.SyntheticLookup','dbo.SyntheticV2TextLookup')
    }
    $expression=$variable.SelectSingleNode('//component[@name="Derived"]/outputs/output/outputColumns/outputColumn[@name="Adjusted"]/properties/property[@name="Expression"]')
    $expression.InnerText='((DT_STR,10,1252)[KeyA] == "5") ? 1 : 0'
    $variants=@(@{name='VARIABLE_TEXT_NULL_UNICODE';expression=$expression.InnerText;long=$false})
    if($ExtendedExpressions){
        $left='((DT_STR,10,1252)[KeyA] == (DT_STR,10,1252)"5") ? TRUE : FALSE'
        $right='((DT_STR,10,1252)[KeyB] == (DT_STR,10,1252)"7") ? TRUE : FALSE'
        $group='(('+ $left +') && ('+$right+'))'
        $variants+=@{name='LONG_TYPED_TERNARY_PLAN';expression='('+((@($group)*256)-join ' || ')+') ? 1 : 0';long=$true}
    }
    $shortStage=$null
    foreach($variant in $variants){
        Write-Output ('SSIS_V2_NATIVE_VARIABLE_CASE '+$variant.name)
        $expression.InnerText=$variant.expression
        $variableBytes=[Text.Encoding]::UTF8.GetBytes($variable.OuterXml)
        $context=if($variant.long){'{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}'}else{'{"schemaVersion":2}'}
        if($variant.long){
            if(-not $shortStage){throw 'SSIS_V2_VARIABLE_SHORT_STAGE_IDENTITY_MISSING'}
            $stage=$shortStage
        }else{
            $index=Invoke-V2Explain -Bytes $variableBytes -Operation 'explain' -Context $context -Catalog $catalog -Collation 'Latin1_General_100_BIN2'
            $stage=@($index.Rows|Where-Object {$_.ArtifactKind -ceq 'StageIndex' -and $_.ComponentId -ceq 'Package\Flow\Derived'})[0]
            if(-not $stage){throw 'SSIS_V2_VARIABLE_SHORT_STAGE_IDENTITY_UNRESOLVED'}
            $shortStage=[pscustomobject]@{TargetFlowId=[string]$stage.TargetFlowId;StageId=[string]$stage.StageId}
        }
        Write-Output ('SSIS_V2_NATIVE_VARIABLE_SELECTED_STAGE '+$variant.name)
        $artifacts=Invoke-V2Explain -Bytes $variableBytes -Operation 'explain' -Context $context -Catalog $catalog -Target ([string]$stage.TargetFlowId) -Stage ([string]$stage.StageId) -Collation 'Latin1_General_100_BIN2'
        $readRows=@($artifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'StageSql' -and $_.StageId -ceq $stage.StageId -and $_.ComponentId -ceq 'Package\Flow\Derived'})
        Assert-V2 ($readRows.Count -eq 1) ($variant.name+'_DERIVED_STAGE_IDENTITY')
        $read=$readRows[0]
        $parts=Get-V2PlanParts $artifacts $read
        if($variant.long){Assert-V2 ($parts.Units.Count -gt 16) 'LONG_TYPED_PLAN_REQUIRES_MULTIPLE_UNITS'}
        Invoke-V2Units $parts
        try{
            $rows=Invoke-V2Sql ([string]$read.Content)
            Assert-V2 ($rows.Rows.Count -eq 6) ($variant.name+'_ROWS')
            foreach($row in $rows.Rows){
                $leftNull=$row.IsNull('KeyA');$rightNull=$row.IsNull('KeyB')
                $leftTrue=-not $leftNull -and $row.KeyA -ceq '5'
                $rightTrue=-not $rightNull -and $row.KeyB -eq 7
                if(-not $variant.long){$unknown=$leftNull;$expected=if($leftTrue){1}else{0}}
                else{
                    $falseTerm=(-not $leftNull -and -not $leftTrue) -or (-not $rightNull -and -not $rightTrue)
                    $unknown=-not $falseTerm -and ($leftNull -or $rightNull)
                    $expected=if($leftTrue -and $rightTrue){1}else{0}
                }
                Assert-V2 $(if($unknown){$row.IsNull('Adjusted')}else{-not $row.IsNull('Adjusted') -and $row.Adjusted -eq $expected}) $variant.name
            }
        }finally{Clear-V2Plan $parts}
    }
}finally{[void](Invoke-V2Sql 'DROP TABLE dbo.SyntheticV2TextA,dbo.SyntheticV2TextB,dbo.SyntheticV2TextLookup;')}
