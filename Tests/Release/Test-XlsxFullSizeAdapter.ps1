# Gegenproben der echten Zeilenorakel ohne Verbindung und ohne SQL.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
class XlsxBoundaryReader {
    [int]$FieldCount=12
    [int]$Rows=1
    [int]$ReadCount=0
    [bool]$Disposed=$false
    [string[]]$Names=@('RowOrdinal','ColumnOrdinal','StoredType','ValuePresent','RawValue','TextValue','FormulaPresent','FormulaText','FormulaKind','SharedFormulaIndex','CachePresent','CacheValue')
    [string[]]$Types=@('int','int','nvarchar','bit','nvarchar','nvarchar','bit','nvarchar','nvarchar','int','bit','nvarchar')
    [object[]]$Values=@(1,1,'n',$true,'42',[DBNull]::Value,$false,[DBNull]::Value,[DBNull]::Value,[DBNull]::Value,$false,[DBNull]::Value)
    [bool]Read(){return (++$this.ReadCount -le $this.Rows)}
    [bool]NextResult(){return $false}
    [string]GetName([int]$index){return $this.Names[$index]}
    [string]GetDataTypeName([int]$index){return $this.Types[$index]}
    [object]GetValue([int]$index){return $this.Values[$index]}
    [bool]IsDBNull([int]$index){return $this.Values[$index] -is [DBNull]}
    [void]Dispose(){$this.Disposed=$true}
}
class XlsxBoundaryCommand {
    [bool]$Disposed=$false
    [void]Dispose(){$this.Disposed=$true}
}
$path=Join-Path $PSScriptRoot 'Invoke-XlsxFullSizeLab.ps1'
$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
if($errors){throw 'ADAPTER_PARSE'}
$nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-XlsxFullSizePositive'},$true))
if($nodes.Count -ne 1){throw 'ORACLE_AMBIGUOUS'}
. ([scriptblock]::Create($nodes[0].Extent.Text))
function Get-ReleaseTimeout {return 45}
function Invoke-XlsxFullSizeQuery {return [pscustomobject]@{Reader=$script:reader;Command=$script:command}}
foreach($mode in @('good','wrong-value','duplicate-row','wrong-schema','missing-row')){
    $script:reader=[XlsxBoundaryReader]::new();$script:command=[XlsxBoundaryCommand]::new()
    switch($mode){
        'wrong-value' {$script:reader.Values[4]='43'}
        'duplicate-row' {$script:reader.Rows=2}
        'wrong-schema' {$script:reader.Types[4]='varchar'}
        'missing-row' {$script:reader.Rows=0}
    }
    $caught=$null
    try{Assert-XlsxFullSizePositive $null ([byte[]]@(1))}catch{$caught=$_}
    if(($mode -ceq 'good' -and $caught) -or ($mode -cne 'good' -and -not $caught)){throw ('ORACLE_FALSE_RESULT_'+$mode)}
    if(-not $script:reader.Disposed -or -not $script:command.Disposed){throw 'ORACLE_READER_NOT_DISPOSED'}
}
'PASS XLSX_FULL_SIZE 5 SQL-free oracle/disposal counterexamples'
