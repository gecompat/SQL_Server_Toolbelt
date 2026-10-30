[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputsFile)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$inputSpec=Get-Content -LiteralPath $InputsFile -Raw | ConvertFrom-Json -AsHashtable
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'PARAMETER_HELP_EXPORT_PARSE'}
# Reuse exporter functions, without the CLI's unconditional dependency closure.
# TableClone's manifest explicitly makes ScriptDom a Windows IncludeTriggers=1
# runtime opt-in; it is not an installation requirement on portable profiles.
foreach($name in @('Get-ManifestDependencies','Get-SqlcmdScriptTree','Get-SqlcmdTreeVariables','Get-DeploymentModules','ConvertTo-StandaloneSql','Export-DeploymentSql','Get-ProvidedModuleVariables')){
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
    if($nodes.Count -ne 1){throw 'PARAMETER_HELP_EXPORT_FUNCTION'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$modulesRoot=Join-Path $repo 'Modules'
$all=@(Get-DeploymentModules -ModulesRoot $modulesRoot)
foreach($profile in $inputSpec.profiles){
    $selected=@($all | Where-Object ModuleId -CIn $profile.modules)
    if($selected.Count -ne $profile.modules.Count){throw 'PARAMETER_HELP_EXPORT_MODULE_SET'}
    $inputs=@{}
    foreach($module in $selected){
        foreach($dependency in $module.Dependencies){
            if($dependency -cnotin $profile.modules){
                if($profile.platform -cne 'Portable' -or $module.ModuleId -cne 'toolbelt.metadata.table-clone' -or $dependency -cne 'toolbelt.tsql.script-parser'){throw 'PARAMETER_HELP_EXPORT_MISSING_DEPENDENCY'}
                $manifest=Get-Content -LiteralPath (Join-Path $module.Directory 'module.yaml') -Raw
                if($manifest -notmatch 'required_when: "Runtime: IncludeTriggers = 1 auf Windows; IncludeTriggers = 0 und Moduldeployment benötigen den Parser nicht\."'){throw 'PARAMETER_HELP_OPTIONAL_DEPENDENCY_CHANGED'}
            }
        }
        $provided=Get-ProvidedModuleVariables -Module $module -AllModuleVariables $profile.variables
        if(@($module.Variables | Where-Object {$_ -cne 'DeploymentMode' -and -not $provided.ContainsKey($_)}).Count){throw 'PARAMETER_HELP_EXPORT_MISSING_INPUT'}
        $inputs[$module.ModuleId]=$provided
    }
    Export-DeploymentSql -Modules $selected -Inputs $inputs -Mode $profile.mode -ModulesRoot $modulesRoot -OutputPath $profile.output
}
