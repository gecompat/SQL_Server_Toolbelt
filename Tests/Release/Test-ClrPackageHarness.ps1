Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
foreach($file in @('Invoke-ClrPackageLab.ps1','Invoke-ClrPackageMatrix.ps1')){
 $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'CLR_HARNESS_PARSE'}
 if($file -ceq 'Invoke-ClrPackageMatrix.ps1'){
  # Reale Budgetausdrücke gegen JSON-Roundtrip und beide Datumskulturen prüfen;
  # keine Verbindungs-, Dateischreib- oder Prozessstartblöcke ausführen.
  $expressions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq 'elapsed'},$true))
  if($expressions.Count -ne 2){throw 'CLR_BUDGET_EXPRESSIONS_MISSING'}
  $original=[Globalization.CultureInfo]::CurrentCulture
  try{
   foreach($culture in @('de-AT','en-US')){
    [Globalization.CultureInfo]::CurrentCulture=[Globalization.CultureInfo]::new($culture)
    $started=[DateTime]::UtcNow.AddSeconds(-300).ToString('o')
    $parsed=('{"startedUtc":"'+$started+'"}')|ConvertFrom-Json -AsHashtable
    foreach($representation in @($started,$parsed.startedUtc)){
     $budget=@{startedUtc=$representation}
     foreach($expression in $expressions){
      $elapsed=& ([scriptblock]::Create($expression.Right.Extent.Text))
      if($elapsed -lt 295 -or $elapsed -gt 310){throw 'CLR_SHARED_BUDGET_RESET_OR_CULTURE_DRIFT'}
     }
    }
   }
  }finally{[Globalization.CultureInfo]::CurrentCulture=$original}
 }
}
'PASS CLR_HARNESS syntax and original shared budget after JSON roundtrip, two cultures; no SQL'
