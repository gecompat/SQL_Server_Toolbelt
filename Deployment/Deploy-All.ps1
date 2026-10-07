[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('local', 'central')]
    [string]$DeploymentMode,

    [string]$ServerInstance,
    [string]$Database,

    [ValidateSet('Windows', 'Sql')]
    [string]$Authentication = 'Windows',

    [string]$SqlUsername = 'sa',

    [string[]]$ModuleId = @(),

    [System.Collections.IDictionary]$ModuleVariables = @{},

    [switch]$CreateDatabaseIfMissing,

    [switch]$PlanOnly,

    [string]$OutputSqlFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$DeploymentMode = $DeploymentMode.ToLowerInvariant()

# Export und Ausführung sind getrennte Modi. Explizite Verbindungsoptionen
# werden beim Export nicht stillschweigend ignoriert oder in SQL übernommen.
$exportSql = $PSBoundParameters.ContainsKey('OutputSqlFile')
if ($exportSql) {
    if ([string]::IsNullOrWhiteSpace($OutputSqlFile)) {
        throw '-OutputSqlFile muss eine nichtleere SQL-Datei benennen.'
    }
    foreach ($executionParameter in @('PlanOnly', 'ServerInstance', 'Database', 'Authentication', 'SqlUsername', 'CreateDatabaseIfMissing')) {
        if ($PSBoundParameters.ContainsKey($executionParameter)) {
            throw "-OutputSqlFile kann nicht mit -$executionParameter kombiniert werden."
        }
    }
}

function Get-ManifestDependencies {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $dependencies = [System.Collections.Generic.List[string]]::new()
    $inDependencies = $false
    $dependencyEntries = 0
    $dependencyIndent = $null

    foreach ($line in $Lines) {
        if (-not $inDependencies) {
            if ($line -match '^dependencies:\s*(?<inline>.*)$') {
                $inline = $Matches.inline.Trim()
                if (-not $inline -or $inline -eq '[]') {
                    $inDependencies = -not $inline
                    continue
                }

                $inlineMatches = [regex]::Matches(
                        $inline,
                        'module_id:\s*["'']?(?<id>[^"''},\s]+)'
                    )
                if ($inlineMatches.Count -eq 0) {
                    throw 'Nicht unterstützte dependencies-Struktur im Modulmanifest.'
                }
                foreach ($match in $inlineMatches) {
                    $dependencies.Add($match.Groups['id'].Value)
                }
            }
            continue
        }

        if ($line -match '^\S' -and $line -notmatch '^-\s') {
            break
        }
        if ($line -match '^(?<indent> *)-(?:\s|$)') {
            $indent = $Matches.indent.Length
            if ($null -eq $dependencyIndent) { $dependencyIndent = $indent }
            if ($indent -gt $dependencyIndent) { continue }
            if ($indent -lt $dependencyIndent) {
                throw 'Inkonsistente Einrückung der Manifest-Abhängigkeiten.'
            }
            $dependencyEntries++
            $entry = $line.TrimStart().Substring(1).TrimStart()
            foreach ($match in [regex]::Matches($entry, '(?:^|[,{]\s*)module_id:\s*["'']?(?<id>[^"''},\s]+)')) {
                $dependencies.Add($match.Groups['id'].Value)
            }
        }
        elseif ($line -match '^(?<indent> *)module_id:\s*["'']?(?<id>[^"''\s]+)' -and
            $null -ne $dependencyIndent -and $Matches.indent.Length -eq ($dependencyIndent + 2)) {
            $dependencies.Add($Matches.id)
        }
    }

    if ($inDependencies -and $dependencyEntries -ne $dependencies.Count) {
        throw 'Jede Manifest-Abhängigkeit muss genau eine module_id besitzen.'
    }

    return @($dependencies | Sort-Object -Unique)
}

function Get-SqlcmdScriptTree {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string[]]$Stack = @(),
        [System.Collections.IDictionary]$Cache = @{}
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if ($Stack -contains $fullPath) {
        throw "Zyklisches SQLCMD-Include erkannt: $fullPath"
    }
    if ($Cache.Contains($fullPath)) {
        return $Cache[$fullPath]
    }

    $lines = [System.IO.File]::ReadAllLines($fullPath, [System.Text.Encoding]::UTF8)
    $children = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $lines.Length; $index++) {
        if ($lines[$index] -notmatch '^(?<indent>[ \t]*):r[ \t]+(?<path>.+?)[ \t]*$') {
            continue
        }

        $indent = $Matches.indent
        $includeName = $Matches.path.Trim().Trim('"').Trim("'")
        if ($includeName -match '\$\(') {
            throw "SQLCMD-Variablen in Include-Pfaden werden nicht unterstützt: '$includeName'."
        }
        $includePath = if ([System.IO.Path]::IsPathRooted($includeName)) {
            [System.IO.Path]::GetFullPath($includeName)
        }
        else {
            [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $fullPath) $includeName))
        }
        if (-not (Test-Path -LiteralPath $includePath -PathType Leaf)) {
            throw "SQLCMD-Include fehlt: $includeName (in '$fullPath')."
        }

        $child = Get-SqlcmdScriptTree -Path $includePath -Stack ($Stack + $fullPath) -Cache $Cache
        $children.Add($child)
        $lines[$index] = "$indent`:r `"$($child.Path)`""
    }

    $node = [pscustomobject]@{
        Path = $fullPath
        Text = $lines -join [System.Environment]::NewLine
        Children = @($children)
    }
    $Cache[$fullPath] = $node
    return $node
}

function Get-SqlcmdTreeVariables {
    param([Parameter(Mandatory)]$Node)

    $names = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($Node.Text, '\$\((?<name>[A-Za-z_][A-Za-z0-9_]*)\)')) {
        $names.Add($match.Groups['name'].Value)
    }
    foreach ($child in $Node.Children) {
        foreach ($name in Get-SqlcmdTreeVariables -Node $child) {
            $names.Add($name)
        }
    }
    return @($names | Sort-Object -Unique)
}

function Write-SqlcmdTreeToTemp {
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Values,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$TemporaryInputs
    )

    $text = $Node.Text
    foreach ($child in $Node.Children) {
        $childInput = Write-SqlcmdTreeToTemp -Node $child -Values $Values -TemporaryInputs $TemporaryInputs
        $text = $text.Replace(':r "' + $child.Path + '"', ':r "' + $childInput + '"')
    }
    $text = [regex]::Replace($text, '\$\((?<name>[A-Za-z_][A-Za-z0-9_]*)\)', {
        param($match)
        $name = $match.Groups['name'].Value
        if (-not $Values.Contains($name)) {
            throw "Nicht aufgelöste SQLCMD-Variable in '$($Node.Path)'."
        }
        return [string]$Values[$name]
    })

    $inputPath = Join-Path ([System.IO.Path]::GetTempPath()) (
        "toolbelt-deploy-{0}.sql" -f [guid]::NewGuid().ToString('N')
    )
    [System.IO.File]::WriteAllText($inputPath, $text, [System.Text.UTF8Encoding]::new($false))
    $TemporaryInputs.Add($inputPath)
    return $inputPath
}

function Get-DeploymentModules {
    param([Parameter(Mandatory)][string]$ModulesRoot)

    $modules = [System.Collections.Generic.List[object]]::new()

    foreach ($directory in Get-ChildItem -LiteralPath $ModulesRoot -Directory | Sort-Object Name) {
        $deployPath = Join-Path $directory.FullName 'Deployment/Deploy.sql'
        if (-not (Test-Path -LiteralPath $deployPath -PathType Leaf)) {
            continue
        }

        $manifestPath = Join-Path $directory.FullName 'module.yaml'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            throw "Deployment-Modul '$($directory.Name)' besitzt kein module.yaml."
        }

        $manifestLines = [System.IO.File]::ReadAllLines($manifestPath, [System.Text.Encoding]::UTF8)
        $moduleIdMatch = $manifestLines |
            Where-Object { $_ -match '^module_id:\s*["'']?(?<id>[^"''\s]+)' } |
            Select-Object -First 1
        if (-not $moduleIdMatch) {
            throw "module.yaml in '$($directory.Name)' enthält keine gültige module_id."
        }
        [void]($moduleIdMatch -match '^module_id:\s*["'']?(?<id>[^"''\s]+)')
        $moduleId = $Matches.id

        $dependencies = @(Get-ManifestDependencies -Lines $manifestLines)
        $scriptTree = Get-SqlcmdScriptTree -Path $deployPath -Cache @{}
        $deploymentDirectory = Split-Path -Parent $deployPath
        $variables = @(Get-SqlcmdTreeVariables -Node $scriptTree)

        $modules.Add([pscustomobject]@{
            ModuleId           = $moduleId
            Directory          = $directory.FullName
            DeploymentDirectory = $deploymentDirectory
            DeploymentPath     = $deployPath
            ScriptTree         = $scriptTree
            Dependencies       = $dependencies
            Variables          = $variables
        })
    }

    $knownModuleIds = @{}
    foreach ($module in $modules) {
        if ($knownModuleIds.ContainsKey($module.ModuleId)) {
            throw "Doppelte module_id '$($module.ModuleId)' in Modules/."
        }
        $knownModuleIds[$module.ModuleId] = $true
    }

    foreach ($module in $modules) {
        foreach ($dependency in $module.Dependencies) {
            if (-not $knownModuleIds.ContainsKey($dependency)) {
                throw "Modul '$($module.ModuleId)' benötigt nicht vorhandenes Modul '$dependency'."
            }
        }
    }

    $ordered = [System.Collections.Generic.List[object]]::new()
    $remaining = [System.Collections.Generic.List[object]]::new()
    foreach ($module in $modules) {
        $remaining.Add($module)
    }

    $deployedIds = @{}
    while ($remaining.Count -gt 0) {
        $ready = @(
            $remaining |
                Where-Object {
                    $candidate = $_
                    @($candidate.Dependencies | Where-Object { -not $deployedIds.ContainsKey($_) }).Count -eq 0
                } |
                Sort-Object ModuleId
        )

        if ($ready.Count -eq 0) {
            $cycleModules = @($remaining | ForEach-Object { $_.ModuleId }) -join ', '
            throw "Zyklische Modulabhängigkeiten erkannt: $cycleModules"
        }

        foreach ($module in $ready) {
            $ordered.Add($module)
            $deployedIds[$module.ModuleId] = $true
            [void]$remaining.Remove($module)
        }
    }

    return @($ordered)
}

function ConvertTo-StandaloneSql {
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Values,
        [Parameter(Mandatory)][string]$ModulesRoot
    )

    # Nur die kanonische Modulclosure einbetten. Absolute Checkoutpfade dienen
    # intern der Auflösung und dürfen weder als Include noch als Header austreten.
    $relativePath = [System.IO.Path]::GetRelativePath($ModulesRoot, $Node.Path)
    if ([System.IO.Path]::IsPathRooted($relativePath) -or
        $relativePath -eq '..' -or $relativePath.StartsWith('../') -or $relativePath.StartsWith('..\')) {
        throw 'SQL-Export unterstützt nur Includes innerhalb von Modules/.'
    }

    $text = $Node.Text
    foreach ($child in $Node.Children) {
        $childText = ConvertTo-StandaloneSql -Node $child -Values $Values -ModulesRoot $ModulesRoot
        $text = $text.Replace(':r "' + $child.Path + '"', $childText)
    }
    $text = [regex]::Replace($text, '\$\((?<name>[A-Za-z_][A-Za-z0-9_]*)\)', {
        param($match)
        $name = $match.Groups['name'].Value
        if (-not $Values.Contains($name)) {
            throw 'SQL-Export enthält eine nicht aufgelöste SQLCMD-Variable.'
        }
        return [string]$Values[$name]
    })

    if ($text.Contains('$(')) {
        throw 'SQL-Export enthält eine nicht unterstützte SQLCMD-Variablensyntax.'
    }

    # Die Datei bleibt SQLCMD-SQL mit explizitem Fehlerabbruch. Andere
    # Direktiven könnten erneut Dateien lesen, Verbindungen wechseln oder
    # Hostbefehle starten und sind im eigenständigen Export nicht unterstützt.
    foreach ($directive in [regex]::Matches($text, '(?m)^[ \t]*(?:[:!].*)$')) {
        if ($directive.Value.Trim() -notmatch '^:ON[ \t]+ERROR[ \t]+EXIT[ \t]*$') {
            throw 'SQL-Export enthält eine nicht unterstützte SQLCMD-Direktive.'
        }
    }
    return $text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Export-DeploymentSql {
    param(
        [Parameter(Mandatory)][object[]]$Modules,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Inputs,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$ModulesRoot,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $destination = [System.IO.Path]::GetFullPath($OutputPath)
    if ([System.IO.Path]::GetExtension($destination) -ine '.sql') {
        throw '-OutputSqlFile benötigt die Dateiendung .sql.'
    }
    $parentDirectory = [System.IO.Path]::GetDirectoryName($destination)
    if (-not [System.IO.Directory]::Exists($parentDirectory)) {
        throw 'Das Zielverzeichnis für -OutputSqlFile muss bereits existieren.'
    }
    if (Test-Path -LiteralPath $destination) {
        throw 'Die SQL-Exportdatei existiert bereits; sie wird nicht überschrieben.'
    }

    $guard = @'
IF @@TRANCOUNT <> 0 OR (2 & @@OPTIONS) <> 0
    THROW 50000, N'Toolbelt SQL-Export benötigt eine frische Sitzung ohne laufende oder implizite Transaktion.', 1;
GO
'@
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append("-- SQL Server Toolbelt: aus aktuellen Modulskripten erzeugtes Deployment.`n")
    [void]$builder.Append("-- SQLCMD-Modus und Fehlerabbruch erforderlich (sqlcmd -b -f 65001).`n")
    [void]$builder.Append("-- In frischer exklusiver Verbindung in der gewählten Zieldatenbank ausführen.`n")
    [void]$builder.Append("-- Keine Gesamttransaktion; frühere erfolgreiche Module bleiben bei Fehlern installiert.`n")
    [void]$builder.Append("-- Bestehende Versions-/Dependency-/Trust-/Migrationsgates bleiben wirksam.`n")
    [void]$builder.Append("-- DeploymentMode: $Mode`n:ON ERROR EXIT`nGO`n")
    foreach ($module in $Modules) {
        if ($module.ModuleId -notmatch '^[a-z0-9][a-z0-9.-]*$') {
            throw 'SQL-Export benötigt eine sichere module_id für die Modulmarkierung.'
        }
        $values = @{ DeploymentMode = $Mode }
        foreach ($key in $Inputs[$module.ModuleId].Keys) {
            $values[$key] = $Inputs[$module.ModuleId][$key]
        }
        $text = ConvertTo-StandaloneSql -Node $module.ScriptTree -Values $values -ModulesRoot $ModulesRoot
        [void]$builder.Append($guard.Replace("`r`n", "`n") + "`n")
        [void]$builder.Append("-- BEGIN MODULE $($module.ModuleId)`n")
        [void]$builder.Append($text + "`nGO`n-- END MODULE $($module.ModuleId)`n")
    }
    [void]$builder.Append($guard.Replace("`r`n", "`n") + "`n")

    # Erst vollständig prüfen/kompilieren, dann im Zielverzeichnis schreiben.
    # Move ohne Overwrite veröffentlicht nur die komplette Datei; ein konkur-
    # rierender Export darf eine mittlerweile vorhandene Datei nicht ersetzen.
    $temporaryPath = Join-Path $parentDirectory ('.toolbelt-export-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $ownsTemporary = $false
    try {
        $stream = [System.IO.FileStream]::new($temporaryPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $ownsTemporary = $true
        try {
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($builder.ToString())
            $stream.Write($bytes, 0, $bytes.Length)
        }
        finally { $stream.Dispose() }
        [System.IO.File]::Move($temporaryPath, $destination, $false)
    }
    finally {
        if ($ownsTemporary -and [System.IO.File]::Exists($temporaryPath)) {
            [System.IO.File]::Delete($temporaryPath)
        }
    }
    Write-Output "SQL-Export erzeugt: $($Modules.Count) Module; DeploymentMode: $Mode."
}

function Get-ProvidedModuleVariables {
    param(
        [Parameter(Mandatory)]$Module,
        [Parameter(Mandatory)][System.Collections.IDictionary]$AllModuleVariables
    )

    $provided = @{}
    if ($AllModuleVariables.Contains($Module.ModuleId)) {
        $moduleValues = $AllModuleVariables[$Module.ModuleId]
        if ($moduleValues -isnot [System.Collections.IDictionary]) {
            throw "Die Werte für '$($Module.ModuleId)' müssen als Hashtabelle übergeben werden."
        }

        foreach ($key in $moduleValues.Keys) {
            $name = [string]$key
            if ($name -eq 'DeploymentMode' -or $name -notin $Module.Variables) {
                throw "Unbekannte oder reservierte SQLCMD-Variable '$name' für '$($Module.ModuleId)'."
            }

            $value = $moduleValues[$key]
            if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value) -or
                $value.Contains("`r") -or $value.Contains("`n") -or $value.Contains([char]0)) {
                throw "SQLCMD-Variable '$name' für '$($Module.ModuleId)' muss eine nichtleere einzeilige Zeichenfolge sein."
            }

            if ($name -in @('AssemblyBits', 'ScriptDomAssemblyBits')) {
                if ($value -notmatch '^0x(?:[0-9A-Fa-f]{2})+$') {
                    throw "'$name' für '$($Module.ModuleId)' muss ein gerades 0x-präfigiertes Hex-Binary sein."
                }
                $value = '0x' + $value.Substring(2)
            }
            elseif ($name -eq 'ExpectedInstalledAssemblyHash') {
                if ($value -ne '0x' -and $value -notmatch '^0x[0-9A-Fa-f]{128}$') {
                    throw "'$name' für '$($Module.ModuleId)' muss 0x für erwartete Abwesenheit oder 0x gefolgt von einem SHA2-512-Hash aus 128 Hex-Zeichen sein."
                }
                $value = '0x' + $value.Substring(2)
            }
            elseif ($name -eq 'ExpectedComparisonAssemblyHash') {
                if ($value -notmatch '^0x[0-9A-Fa-f]{128}$') {
                    throw "'$name' für '$($Module.ModuleId)' muss 0x gefolgt von einem SHA2-512-Hash aus 128 Hex-Zeichen sein."
                }
                $value = '0x' + $value.Substring(2)
            }
            elseif ($value -notmatch '^[A-Za-z0-9_+.-]+$') {
                throw "SQLCMD-Variable '$name' für '$($Module.ModuleId)' enthält ungültige Zeichen."
            }

            $provided[$name] = $value
        }
    }

    return $provided
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$modulesRoot = Join-Path $repositoryRoot 'Modules'
$allModules = @(Get-DeploymentModules -ModulesRoot $modulesRoot)
if ($allModules.Count -eq 0) {
    throw "Keine Module mit Deployment/Deploy.sql unter '$modulesRoot' gefunden."
}

$allModuleIds = @{}
foreach ($module in $allModules) {
    $allModuleIds[$module.ModuleId] = $true
}

$selectedIds = @{}
foreach ($requestedId in $ModuleId) {
    if (-not $allModuleIds.ContainsKey($requestedId)) {
        throw "Unbekanntes Deployment-Modul '$requestedId'."
    }
    $selectedIds[$requestedId] = $true
}

if ($selectedIds.Count -gt 0) {
    do {
        $dependencyAdded = $false
        foreach ($module in $allModules) {
            if (-not $selectedIds.ContainsKey($module.ModuleId)) {
                continue
            }

            foreach ($dependency in $module.Dependencies) {
                if (-not $selectedIds.ContainsKey($dependency)) {
                    $selectedIds[$dependency] = $true
                    $dependencyAdded = $true
                }
            }
        }
    } while ($dependencyAdded)

    $modules = @($allModules | Where-Object { $selectedIds.ContainsKey($_.ModuleId) })
}
else {
    $modules = $allModules
}

$selectedModuleIds = @{}
foreach ($module in $modules) {
    $selectedModuleIds[$module.ModuleId] = $true
}
foreach ($moduleId in $ModuleVariables.Keys) {
    if (-not $allModuleIds.ContainsKey([string]$moduleId)) {
        throw "SQLCMD-Variablen wurden für unbekanntes Modul '$moduleId' übergeben."
    }
    if (-not $selectedModuleIds.ContainsKey([string]$moduleId)) {
        throw "SQLCMD-Variablen wurden für nicht ausgewähltes Modul '$moduleId' übergeben."
    }
}

$moduleInputs = @{}
$planRows = [System.Collections.Generic.List[object]]::new()
foreach ($module in $modules) {
    $provided = Get-ProvidedModuleVariables -Module $module -AllModuleVariables $ModuleVariables
    $required = @($module.Variables | Where-Object { $_ -ne 'DeploymentMode' })
    $missing = @($required | Where-Object { -not $provided.ContainsKey($_) })
    $moduleInputs[$module.ModuleId] = $provided
    $planRows.Add([pscustomobject]@{
        ModuleId = $module.ModuleId
        RequiredVariables = $required
        MissingVariables = $missing
    })
}

if ($PlanOnly) {
    Write-Output "DeploymentMode: $DeploymentMode"
    $selectionText = if ($ModuleId.Count -gt 0) { $ModuleId -join ', ' } else { 'alle Module' }
    Write-Output "Auswahl: $selectionText (inklusive deklarierter Abhängigkeiten)"
    Write-Output "Module: $($modules.Count)"
    for ($index = 0; $index -lt $modules.Count; $index++) {
        $module = $modules[$index]
        $row = $planRows[$index]
        $requiredText = if ($row.RequiredVariables.Count) { $row.RequiredVariables -join ', ' } else { '-' }
        $missingText = if ($row.MissingVariables.Count) { $row.MissingVariables -join ', ' } else { '-' }
        Write-Output ('{0,2}. {1} | Eingaben: {2} | fehlen: {3}' -f ($index + 1), $module.ModuleId, $requiredText, $missingText)
    }
    return
}

$missingInputs = [System.Collections.Generic.List[string]]::new()
for ($index = 0; $index -lt $modules.Count; $index++) {
    $missing = $planRows[$index].MissingVariables
    if ($missing.Count -gt 0) {
        $missingInputs.Add("$($modules[$index].ModuleId): $($missing -join ', ')")
    }
}
if ($missingInputs.Count -gt 0) {
    throw ("Fehlende SQLCMD-Eingaben; vor dem Deployment bereitstellen:`n- " + ($missingInputs -join "`n- "))
}

if ($exportSql) {
    Export-DeploymentSql -Modules $modules -Inputs $moduleInputs -Mode $DeploymentMode -ModulesRoot $modulesRoot -OutputPath $OutputSqlFile
    return
}

if ([string]::IsNullOrWhiteSpace($ServerInstance)) {
    throw 'Für die Ausführung ist -ServerInstance erforderlich.'
}
if ([string]::IsNullOrWhiteSpace($Database)) {
    throw 'Für die Ausführung ist -Database erforderlich.'
}

$sqlcmd = Get-Command sqlcmd -ErrorAction Stop
$securePassword = $null
$sqlPassword = $null
if ($Authentication -eq 'Sql') {
    if ([string]::IsNullOrWhiteSpace($SqlUsername)) {
        throw 'Für SQL Authentication ist ein -SqlUsername erforderlich.'
    }
    $securePassword = Read-Host -Prompt "SQL-Passwort für '$SqlUsername'" -AsSecureString
    $sqlPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
    if ([string]::IsNullOrEmpty($sqlPassword)) {
        $securePassword.Dispose()
        throw 'Das SQL-Passwort darf nicht leer sein.'
    }
}

$completedModules = [System.Collections.Generic.List[string]]::new()
try {
    if ($CreateDatabaseIfMissing) {
        $databaseNameLiteral = $Database.Replace("'", "''")
        $databaseIdentifier = '[' + $Database.Replace(']', ']]') + ']'
        $databaseIdentifierLiteral = $databaseIdentifier.Replace("'", "''")
        $databaseQuery = @"
IF DB_ID(N'$databaseNameLiteral') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE $databaseIdentifierLiteral;');
    SELECT N'DATABASE_CREATED' AS [DatabaseStatus];
END
ELSE
BEGIN
    SELECT N'DATABASE_EXISTS' AS [DatabaseStatus];
END;
"@

        $databaseProcessInfo = [System.Diagnostics.ProcessStartInfo]::new($sqlcmd.Source)
        $databaseProcessInfo.UseShellExecute = $false
        $databaseProcessInfo.RedirectStandardOutput = $true
        $databaseProcessInfo.RedirectStandardError = $true
        $databaseProcessInfo.CreateNoWindow = $true

        foreach ($argument in @(
            '-S', $ServerInstance,
            '-d', 'master',
            '-b',
            '-r', '1',
            '-l', '15',
            '-Q', $databaseQuery
            )) {
            [void]$databaseProcessInfo.ArgumentList.Add($argument)
        }

        if ($Authentication -eq 'Windows') {
            [void]$databaseProcessInfo.ArgumentList.Add('-E')
            [void]$databaseProcessInfo.Environment.Remove('SQLCMDPASSWORD')
        }
        else {
            [void]$databaseProcessInfo.ArgumentList.Add('-U')
            [void]$databaseProcessInfo.ArgumentList.Add($SqlUsername)
            $databaseProcessInfo.Environment['SQLCMDPASSWORD'] = $sqlPassword
        }

        $databaseProcess = [System.Diagnostics.Process]::new()
        try {
            $databaseProcess.StartInfo = $databaseProcessInfo
            [void]$databaseProcess.Start()
            $databaseStdoutTask = $databaseProcess.StandardOutput.ReadToEndAsync()
            $databaseStderrTask = $databaseProcess.StandardError.ReadToEndAsync()
            $databaseProcess.WaitForExit()
            $databaseStdout = $databaseStdoutTask.GetAwaiter().GetResult()
            $databaseStderr = $databaseStderrTask.GetAwaiter().GetResult()

            if ($databaseStdout) {
                [Console]::Out.Write($databaseStdout)
            }
            if ($databaseStderr) {
                [Console]::Error.Write($databaseStderr)
            }
            if ($databaseProcess.ExitCode -ne 0) {
                throw "Datenbankprüfung/-anlage für '$Database' fehlgeschlagen (sqlcmd Exitcode $($databaseProcess.ExitCode))."
            }
        }
        finally {
            $databaseProcessInfo.Environment.Remove('SQLCMDPASSWORD') | Out-Null
            $databaseProcess.Dispose()
        }
    }

    for ($index = 0; $index -lt $modules.Count; $index++) {
        $module = $modules[$index]
        Write-Host ("[{0}/{1}] Deployment: {2}" -f ($index + 1), $modules.Count, $module.ModuleId)

        $values = @{}
        $values['DeploymentMode'] = $DeploymentMode
        foreach ($name in $moduleInputs[$module.ModuleId].Keys) {
            $values[$name] = $moduleInputs[$module.ModuleId][$name]
        }

        $temporaryInputs = [System.Collections.Generic.List[string]]::new()
        $processInfo = $null
        $process = $null
        try {
            foreach ($name in $module.Variables) {
                if (-not $values.ContainsKey($name)) {
                    throw "SQLCMD-Variable '$name' für '$($module.ModuleId)' fehlt."
                }
            }
            $inputPath = Write-SqlcmdTreeToTemp `
                -Node $module.ScriptTree `
                -Values $values `
                -TemporaryInputs $temporaryInputs

            $processInfo = [System.Diagnostics.ProcessStartInfo]::new($sqlcmd.Source)
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.CreateNoWindow = $true
            $processInfo.WorkingDirectory = $module.DeploymentDirectory

            foreach ($argument in @(
                '-S', $ServerInstance,
                '-d', $Database,
                '-b',
                '-r', '1',
                '-l', '15',
                '-i', $inputPath
                )) {
                [void]$processInfo.ArgumentList.Add($argument)
            }

            if ($Authentication -eq 'Windows') {
                [void]$processInfo.ArgumentList.Add('-E')
                [void]$processInfo.Environment.Remove('SQLCMDPASSWORD')
            }
            else {
                [void]$processInfo.ArgumentList.Add('-U')
                [void]$processInfo.ArgumentList.Add($SqlUsername)
                $processInfo.Environment['SQLCMDPASSWORD'] = $sqlPassword
            }

            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $processInfo
            [void]$process.Start()
            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
            $stderrTask = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $stdout = $stdoutTask.GetAwaiter().GetResult()
            $stderr = $stderrTask.GetAwaiter().GetResult()

            if ($stdout) {
                [Console]::Out.Write($stdout)
            }
            if ($stderr) {
                [Console]::Error.Write($stderr)
            }
            if ($process.ExitCode -ne 0) {
                $prior = if ($completedModules.Count -gt 0) {
                    " Bereits erfolgreich deployed: $($completedModules -join ', ')."
                }
                else {
                    ''
                }
                throw "sqlcmd meldete Exitcode $($process.ExitCode) für '$($module.ModuleId)'.$prior Bereits installierte Module werden nicht automatisch zurückgerollt."
            }
        }
        finally {
            if ($null -ne $processInfo) {
                $processInfo.Environment.Remove('SQLCMDPASSWORD') | Out-Null
            }
            if ($null -ne $process) {
            $process.Dispose()
            }
            foreach ($temporaryInput in $temporaryInputs) {
                if (Test-Path -LiteralPath $temporaryInput -PathType Leaf) {
                    Remove-Item -LiteralPath $temporaryInput -Force
                }
            }
        }

        $completedModules.Add($module.ModuleId)
    }
}
finally {
    $sqlPassword = $null
    if ($null -ne $securePassword) {
        $securePassword.Dispose()
    }
}

Write-Host "Deployment abgeschlossen: $($completedModules.Count) Module."
