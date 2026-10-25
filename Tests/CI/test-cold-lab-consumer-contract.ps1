# Tatsächliche Importfamilien isolieren; keine mutierenden Treiber-Top-Levels ausführen.
[CmdletBinding()]
param([switch]$IsolatedChild)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(-not $IsolatedChild){
    $start=[Diagnostics.ProcessStartInfo]::new([Environment]::ProcessPath)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($argument in @('-NoProfile','-NonInteractive','-File',$PSCommandPath,'-IsolatedChild')){$start.ArgumentList.Add($argument)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$start;$started=$false
    try{
        $started=$process.Start();$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit(120000)){$process.Kill($true);$process.WaitForExit();throw 'COLD_LAB_CONSUMER_TIMEOUT'}
        $output=$stdout.GetAwaiter().GetResult();$errorOutput=$stderr.GetAwaiter().GetResult()
        if($process.ExitCode -ne 0){throw ('COLD_LAB_CONSUMER_CHILD_FAILED: '+$errorOutput)}
        Write-Output $output.TrimEnd()
    }finally{if($started -and -not $process.HasExited){$process.Kill($true);$process.WaitForExit()};$process.Dispose()}
    return
}
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$shared=Join-Path $PSScriptRoot 'LabQualifiedContract.ps1';$runner=Join-Path $PSScriptRoot 'run-lab-local.ps1'
function Read-ColdAst([string]$Path){$errors=$null;$a=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors);if($errors.Count){throw 'COLD_LAB_SOURCE_PARSE'};return $a}
$runnerAst=Read-ColdAst $runner
$consumers=@();$tracked=@(git -C $root ls-files -- '*.ps1');if($LASTEXITCODE){throw 'COLD_LAB_TRACKED_SOURCE_DISCOVERY'}
foreach($relative in $tracked){
    if($relative -notmatch '^(Tests/|Modules/|Spikes/XlsxMemory/)'){continue};$path=Join-Path $root $relative
    if([IO.Path]::GetFullPath($path) -ieq [IO.Path]::GetFullPath($PSCommandPath)){continue}
    $text=[IO.File]::ReadAllText($path);if($text -notmatch 'Resolve-LabContract' -or $text -notmatch 'run-lab-local.ps1' -or $text -notmatch 'FunctionDefinitionAst'){continue}
    $a=Read-ColdAst $path
    if(@($a.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Resolve-LabContract'},$false)).Count){continue}
    $dots=@($a.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.InvocationOperator -eq [Management.Automation.Language.TokenKind]::Dot -and $n.Extent.Text -match 'LabQualifiedContract\.ps1'},$true))
    if($dots.Count -ne 1){throw ('COLD_LAB_EXPLICIT_READER_DEPENDENCY_REQUIRED: '+$relative)}
    $literal=@($dots[0].FindAll({param($n)$n -is [Management.Automation.Language.StringConstantExpressionAst] -and $n.Value -match 'LabQualifiedContract\.ps1$'},$true))
    if($literal.Count -ne 1){throw 'COLD_LAB_DEPENDENCY_PATH_LITERAL'}
    $base=if($dots[0].Extent.Text -match '\$PSScriptRoot'){[IO.Path]::GetDirectoryName($path)}elseif($dots[0].Extent.Text -match '\$(repo|repoRoot)\b'){$root}else{throw 'COLD_LAB_DEPENDENCY_BASE_UNKNOWN'}
    if(-not [string]::Equals([IO.Path]::GetFullPath((Join-Path $base $literal[0].Value)),[IO.Path]::GetFullPath($shared),[StringComparison]::OrdinalIgnoreCase)){throw 'COLD_LAB_DEPENDENCY_WRONG_FILE'}
    $consumers+=@{Path=$path;Relative=$relative;Ast=$a;Dot=$dots[0]}
}
if($consumers.Count -lt 38 -or $consumers.Count -gt 128){throw 'COLD_LAB_CONSUMER_INVENTORY_BOUND'}

# Jede Familie behält ihren echten Block und dessen Auswahl, auch zwei/vier/sieben Definitionen.
$families=@(
    @{File='Tests/CI/test-lab-qualified-contract.ps1';Mode='direct';Count=2},
    @{File='Tests/Release/Invoke-ApiQualificationMatrix.ps1';Mode='release';Count=4},
    @{File='Tests/CI/run-json-schema-lab.ps1';Mode='direct';Count=5},
    @{File='Tests/CI/run-regex-captures-lab.ps1';Mode='direct';Count=6},
    @{File='Tests/CI/run-console-clients-lab.ps1';Mode='direct';Count=7},
    @{File='Tests/CI/run-json-groups-lab.ps1';Mode='collect';Count=6},
    @{File='Tests/CI/run-filesystem-security-lab.ps1';Mode='nested';Count=5},
    @{File='Tests/CI/run-table-clone-wave1-lab.ps1';Mode='snapshot';Count=5},
    @{File='Tests/Research/characterize-next-wave-json.ps1';Mode='collection';Count=5}
)
$releaseAst=Read-ColdAst (Join-Path $root 'Tests/Release/Invoke-ApiQualificationLab.ps1')
$releaseImport=@($releaseAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Import-ClrFunctions'},$false))
if($releaseImport.Count -ne 1){throw 'COLD_LAB_RELEASE_IMPORTER'}
function Get-ColdFunctionScope($Node){$p=$Node.Parent;while($null -ne $p){if($p -is [Management.Automation.Language.FunctionDefinitionAst]){return $p.Extent.StartOffset};$p=$p.Parent};return -1}
$plans=@()
foreach($family in $families){
    $source=@($consumers|Where-Object Relative -CEQ $family.File);if($source.Count -ne 1){throw 'COLD_LAB_FAMILY_SOURCE'};$a=$source[0].Ast
    $vars=@{};$post='';$support=@();$names=@();$block=''
    if($family.Mode -in @('direct','release')){
        $loops=@($a.FindAll({param($n)$n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -match 'Resolve-LabContract'},$true))
        if($loops.Count -ne 1){throw 'COLD_LAB_DIRECT_BLOCK_AMBIGUOUS'};$loop=$loops[0];$block=$loop.Extent.Text;$importAst=$loop;$importEnd=$loop.Extent.EndOffset
        if($family.Mode -ceq 'direct'){$names=@($loop.Condition.SafeGetValue())}
        else{
            $arrays=@($loop.Condition.FindAll({param($n)$n -is [Management.Automation.Language.ArrayExpressionAst] -and $n.Extent.Text -match 'Resolve-LabContract'},$true))
            if($arrays.Count -ne 1){throw 'COLD_LAB_RELEASE_NAMES'};$names=@($arrays[0].SafeGetValue());$support+= $releaseImport[0].Extent.Text
        }
    }elseif($family.Mode -ceq 'collection'){
        $assignments=@($a.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -ceq '$names' -and $n.Right.Extent.Text -match 'Resolve-LabContract'},$true))
        if($assignments.Count -ne 1){throw 'COLD_LAB_COLLECTION_NAMES'};$assignment=$assignments[0]
        $arrays=@($assignment.Right.FindAll({param($n)$n -is [Management.Automation.Language.ArrayExpressionAst]},$true))
        if($arrays.Count -ne 1){throw 'COLD_LAB_COLLECTION_LITERAL_NAMES'};$names=@($arrays[0].SafeGetValue());$container=$assignment.Parent
        while($null -ne $container -and $null -eq $container.PSObject.Properties['Statements']){$container=$container.Parent}
        if($null -eq $container){throw 'COLD_LAB_COLLECTION_CONTAINER'}
        $last=@($container.Statements|Where-Object {$_ -is [Management.Automation.Language.ForEachStatementAst] -and $_.Body.Extent.Text -match 'Invoke-Expression.*Extent.Text'})
        if($last.Count -ne 1){throw 'COLD_LAB_COLLECTION_APPLY'}
        $text=[IO.File]::ReadAllText($source[0].Path);$block=$text.Substring($assignment.Extent.StartOffset,$last[0].Extent.EndOffset-$assignment.Extent.StartOffset);$importAst=$assignment;$importEnd=$last[0].Extent.EndOffset
    }else{
        $outer=@($a.FindAll({param($n)$n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -match "File='run-lab-local.ps1'"},$true))
        if($outer.Count -ne 1){throw 'COLD_LAB_NESTED_SOURCE'}
        $items=@($outer[0].Condition.SafeGetValue());$selection=@($items|Where-Object File -CEQ 'run-lab-local.ps1');if($selection.Count -ne 1){throw 'COLD_LAB_NESTED_SELECTION'}
        $names=@($selection[0].Names);$vars[$outer[0].Variable.VariablePath.UserPath]=$selection[0]
        $inner=@($outer[0].Body.FindAll({param($n)$n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -match '\.Names$' -and $n.Body.Extent.Text -match 'FunctionDefinitionAst'},$true))
        if($inner.Count -ne 1){throw 'COLD_LAB_NESTED_BLOCK'};$block=$inner[0].Extent.Text;$importAst=$inner[0];$importEnd=$inner[0].Extent.EndOffset
        if($family.Mode -ceq 'collect'){
            $apply=@($a.FindAll({param($n)$n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Condition.Extent.Text -ceq '$definitions' -and $n.Body.Extent.Text -match 'scriptblock.*Create' -and $n.Body.Extent.Text -notmatch 'FunctionDefinitionAst'},$true))
            if($apply.Count -ne 1){throw 'COLD_LAB_COLLECT_APPLY'};$post=$apply[0].Extent.Text;$importEnd=$apply[0].Extent.EndOffset
        }
        if($family.Mode -ceq 'snapshot'){
            foreach($name in @('Get-InputBytes','Get-InputText','Get-InputLines')){$node=@($a.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true));if($node.Count -gt 1){throw 'COLD_LAB_SNAPSHOT_HELPER'};if($node.Count){$support+= $node[0].Extent.Text}}
        }
    }
    if($names.Count -ne $family.Count -or 'Resolve-LabContract' -cnotin $names){throw 'COLD_LAB_ACTUAL_SELECTION_CHANGED'}
    $blockAst=[Management.Automation.Language.Parser]::ParseInput($block,[ref]$null,[ref]$null)
    $findCalls=@($blockAst.FindAll({param($n)$n -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Member.Extent.Text -ceq 'FindAll' -and $n.Expression -is [Management.Automation.Language.VariableExpressionAst]},$true))
    $astVariables=@($findCalls|ForEach-Object {$_.Expression.VariablePath.UserPath}|Sort-Object -Unique)
    if($source[0].Dot.Extent.EndOffset -ge $importAst.Extent.StartOffset){throw 'COLD_LAB_DEPENDENCY_AFTER_IMPORT'}
    $scope=Get-ColdFunctionScope $importAst
    foreach($use in @($a.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -ceq 'Resolve-LabContract'},$true))){if((Get-ColdFunctionScope $use) -eq $scope -and $use.Extent.StartOffset -le $importEnd){throw 'COLD_LAB_IMPORT_AFTER_USE'}}
    $plans+=@{File=$family.File;Mode=$family.Mode;Names=$names;Dot=$source[0].Dot.Extent.Text;Block=$block;Post=$post;Variables=$vars;AstVariables=$astVariables;Support=$support;Directory=[IO.Path]::GetDirectoryName($source[0].Path)}
}

$fixture=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-cold-reader-'+[guid]::NewGuid().ToString('N'))
$path=Join-Path $fixture 'contract.json';$schema=Join-Path $fixture 'schema.json';$created=$false;$cases=0
try{
    $null=New-Item -ItemType Directory -Path $fixture -ErrorAction Stop;$created=$true
    [IO.File]::WriteAllText($schema,'{"type":"object","required":["contractVersion","groupStatus","environments"]}')
    foreach($plan in $plans){
        if(Get-Command Read-LabContractStreamBytes -ErrorAction SilentlyContinue){throw 'COLD_LAB_PARENT_SCOPE_POLLUTED'}
        $module=New-Module -ScriptBlock {}
        try{
            $result=& $module {
                param($Plan,$RunnerAst,$RunnerPath,$Repo,$Path,$Schema)
                if(Get-Command Read-LabContractStreamBytes -ErrorAction SilentlyContinue){throw 'COLD_LAB_MODULE_NOT_COLD'}
                $PSScriptRoot=$Plan.Directory;$repoRoot=$Repo;$repositoryRoot=$Repo;$helper=$RunnerPath;$driver=$RunnerPath;$runnerPath=$RunnerPath
                foreach($name in $Plan.Variables.Keys){Set-Variable -Name $name -Value $Plan.Variables[$name] -Scope Local}
                foreach($name in $Plan.AstVariables){Set-Variable -Name $name -Value $RunnerAst -Scope Local}
                foreach($definition in $Plan.Support){. ([scriptblock]::Create($definition))}
                if($Plan.Mode -ceq 'collect'){$definitions=[Collections.Generic.List[string]]::new()}
                # Die Dateiherkunft ist ein definierter Testinput des isolierten Blocks.
                $prefix='$PSScriptRoot=$Plan.Directory; '
                $null=. ([scriptblock]::Create($prefix+$Plan.Dot))
                if(-not (Get-Command Read-LabContractStreamBytes -ErrorAction SilentlyContinue)){throw 'COLD_LAB_READER_DEPENDENCY_MISSING'}
                $null=. ([scriptblock]::Create($prefix+$Plan.Block))
                if($Plan.Post){$null=. ([scriptblock]::Create($prefix+$Plan.Post))}
                foreach($name in $Plan.Names){if(-not (Get-Command $name -CommandType Function -ErrorAction SilentlyContinue)){throw 'COLD_LAB_REQUIRED_FUNCTION_MISSING'}}
                $script:ColdPath=$Path;$script:ColdSchema=$Schema
                $script:snapshots=[Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::OrdinalIgnoreCase)
                function Get-EnvironmentVariableValue {param([string]$Name);switch -CaseSensitive ($Name){'SQL_SERVER_LAB_TEST_ENV_FILE'{$script:ColdPath};'SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE'{$script:ColdSchema};default{$null}}}
                function Write-ColdDocument($Document){[IO.File]::WriteAllText($script:ColdPath,($Document|ConvertTo-Json -Depth 8));$script:snapshots[[IO.Path]::GetFullPath($script:ColdPath)]=[IO.File]::ReadAllBytes($script:ColdPath);$script:snapshots[[IO.Path]::GetFullPath($script:ColdSchema)]=[IO.File]::ReadAllBytes($script:ColdSchema)}
                function Reject-Cold([scriptblock]$Action,[string]$Expected){try{$null=& $Action;return $false}catch{return $_.Exception.Message -ceq $Expected}}
                $count=0;$document=[ordered]@{contractVersion='SqlServerLab.TestEnvironment/1.0';groupStatus='READY';environments=@(@{key='SYNTHETIC';encrypt=$true;trustServerCertificate=$true})}
                Write-ColdDocument $document;$resolved=Resolve-LabContract
                if($resolved.Contract.contractVersion -cne 'SqlServerLab.TestEnvironment/1.0' -or $null -ne $resolved.Snapshot){throw 'COLD_LAB_V1_READER_FAILED'};$count++
                if($Plan.Mode -ceq 'snapshot'){
                    $key=[IO.Path]::GetFullPath($Path);$captured=$script:snapshots[$key];$schemaBytes=[IO.File]::ReadAllBytes($Schema)
                    [IO.File]::WriteAllText($Path,'{"replaced":true}');[IO.File]::WriteAllText($Schema,'false')
                    $pinned=Resolve-LabContract
                    if($pinned.Contract.contractVersion -cne 'SqlServerLab.TestEnvironment/1.0'){throw 'COLD_LAB_SNAPSHOT_REREAD'};$count++
                    $copy=Get-InputBytes $Path;$original=$captured[0];$copy[0]=$copy[0] -bxor 1
                    if($script:snapshots[$key][0] -ne $original){throw 'COLD_LAB_SNAPSHOT_ALIAS'};$count++
                    foreach($size in @(0,4194305)){
                        $script:snapshots[$key]=[byte[]]::new($size)
                        if(-not (Reject-Cold {Get-InputBytes $Path} 'LAB_CONTRACT_SIZE_INVALID')){throw 'COLD_LAB_SNAPSHOT_BOUND_LOST'};$count++
                    }
                    $script:snapshots[$key]=$captured;[IO.File]::WriteAllBytes($Schema,$schemaBytes);Write-ColdDocument $document
                }
                if(-not (Reject-Cold {Resolve-LabContract -TestPurpose AuthenticatedTls} 'LAB_QUALIFIED_V2_REQUIRED')){throw 'COLD_LAB_V1_AUTHENTICATED_ACCEPTED'};$count++
                $document.contractVersion='SqlServerLab.TestEnvironment/99.0';Write-ColdDocument $document
                if(-not (Reject-Cold {Resolve-LabContract} 'LAB_CONTRACT_VERSION_UNSUPPORTED')){throw 'COLD_LAB_UNKNOWN_VERSION_ACCEPTED'};$count++
                $document.contractVersion='SqlServerLab.TestEnvironment/2.0';Write-ColdDocument $document
                if(-not (Reject-Cold {Resolve-LabContract} 'LAB_QUALIFIED_CONTEXT_REQUIRED')){throw 'COLD_LAB_CONTEXTLESS_V2_ACCEPTED'};$count++
                return $count
            } $plan $runnerAst $runner $root $path $schema
            $expected=if($plan.Mode -ceq 'snapshot'){8}else{4}
            if($result -ne $expected){throw 'COLD_LAB_CASE_COUNT'};$cases+=$result
        }catch{throw ('COLD_LAB_FAMILY_FAILED: '+$plan.File+' / '+$_.Exception.Message)}finally{Remove-Module $module -ErrorAction SilentlyContinue}
    }
}finally{if($created){foreach($file in @($path,$schema)){if([IO.File]::Exists($file)){[IO.File]::Delete($file)}};[IO.Directory]::Delete($fixture,$false)}}
Write-Output "COLD_LAB_IMPORT_FAMILIES_PASS static_consumers=$($consumers.Count) families=$($plans.Count) cases=$cases; actual bounded import blocks; no SQL/provider actions"
