# Markerfreier Paketvertrag. Hashbindung ist Integrität, keine Herausgebersignatur.
function Get-ToolbeltSha256([byte[]]$Bytes) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Assert-ToolbeltRelativePath([string]$Path) {
    if ($Path -notmatch '\A[A-Za-z0-9][A-Za-z0-9._/-]*\z' -or
        $Path.Contains('//') -or @($Path.Split('/') | Where-Object { $_ -in '.', '..', '' }).Count) {
        throw 'Ungültiger relativer Paketpfad.'
    }
}

function Assert-ToolbeltProfile($Profile) {
    if ($Profile.platform -notin 'Windows','Portable' -or $Profile.mode -notin 'local','central') {
        throw 'Unbekanntes Installationsprofil.'
    }
    $modules = @($Profile.modules)
    if ($modules.Count -lt 1 -or $modules.Count -gt 512 -or
        @($modules | Sort-Object -Unique).Count -ne $modules.Count -or
        @($modules | Where-Object { $_ -cnotmatch '\Atoolbelt\.[a-z0-9.-]+\z' }).Count) {
        throw 'Ungültige oder doppelte Modulauswahl.'
    }
    $objects = @($Profile.objects)
    if ($objects.Count -gt 16384) { throw 'Zu viele Objektdeklarationen.' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($object in $objects) {
        if ($object.schema -cnotmatch '\Atoolbelt_[a-z]+\z' -or
            $object.name -cnotmatch '\A[A-Za-z][A-Za-z0-9_]*\z' -or
            $object.types -cnotmatch '\A(?:P|PC|IF|TF|FT|FN|FS|AF|V|U)(?:,(?:P|PC|IF|TF|FT|FN|FS|AF|V|U))*\z' -or
            -not $seen.Add($object.schema+'.'+$object.name)) { throw 'Ungültige oder doppelte Objektdeklaration.' }
    }
    foreach ($property in $Profile.assemblies.PSObject.Properties) {
        if ($property.Name -cnotmatch '\Atlblt[A-Za-z0-9_.]*\z' -or
            [string]$property.Value -notmatch '\A[0-9a-fA-F]{128}\z') { throw 'Ungültige Assemblydeklaration.' }
    }
}

function Get-ToolbeltPayload([string]$ArchivePath, [string]$ExpectedSha256 = '') {
    $path = (Resolve-Path -LiteralPath $ArchivePath).Path
    if ($ExpectedSha256 -and ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $ExpectedSha256)) {
        throw 'Paket stimmt nicht mit dem ausdrücklich erwarteten SHA256 überein.'
    }
    $archive = [IO.Compression.ZipFile]::OpenRead($path)
    try {
        $entries = @{}
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        [long]$total = 0
        if ($archive.Entries.Count -lt 2 -or $archive.Entries.Count -gt 256) { throw 'Ungültige Paketgröße.' }
        foreach ($entry in $archive.Entries) {
            Assert-ToolbeltRelativePath $entry.FullName
            if (-not $seen.Add($entry.FullName) -or $entry.Length -gt 268435456) { throw 'Doppelter oder zu großer Paketeintrag.' }
            $total += $entry.Length
            if ($total -gt 536870912) { throw 'Paket überschreitet 512 MiB entpackt.' }
            $stream = $entry.Open(); $memory = [IO.MemoryStream]::new()
            try {
                $buffer = [byte[]]::new(65536)
                while (($count = $stream.Read($buffer,0,$buffer.Length)) -gt 0) {
                    if ($memory.Length + $count -gt $entry.Length) { throw 'Paketlänge widerspricht dem Verzeichnis.' }
                    $memory.Write($buffer,0,$count)
                }
                if ($memory.Length -ne $entry.Length) { throw 'Unvollständiger Paketeintrag.' }
                $entries[$entry.FullName] = $memory.ToArray()
            } finally { $stream.Dispose(); $memory.Dispose() }
        }
        if (-not $entries.ContainsKey('PACKAGE.json')) { throw 'PACKAGE.json fehlt.' }
        if ($entries['PACKAGE.json'].Length -gt 4194304) { throw 'Paketmanifest überschreitet 4 MiB.' }
        $utf8 = [Text.UTF8Encoding]::new($false,$true)
        $manifest = $utf8.GetString($entries['PACKAGE.json']) | ConvertFrom-Json -Depth 64
        if ($manifest.schema -cne 'toolbelt-install-package/v2' -or
            $manifest.source_commit -cnotmatch '\A[0-9a-f]{40}\z' -or
            $manifest.release -cnotmatch '\Av[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?\z') { throw 'Unbekannter Paketvertrag.' }
        $files = @($manifest.files.PSObject.Properties)
        if ($files.Count -ne $entries.Count-1) { throw 'Paketinventar ist unvollständig.' }
        foreach ($file in $files) {
            Assert-ToolbeltRelativePath $file.Name
            if ($file.Name -ceq 'PACKAGE.json' -or [string]$file.Value -notmatch '\A[0-9a-f]{64}\z' -or
                -not $entries.ContainsKey($file.Name) -or (Get-ToolbeltSha256 $entries[$file.Name]) -cne $file.Value) {
                throw 'Paketeintrag fehlt oder seine Bytes sind abweichend.'
            }
        }
        $profiles = @($manifest.profiles)
        if ($profiles.Count -ne 4) { throw 'Die vier Plattform-/Modusprofile fehlen.' }
        $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($profile in $profiles) {
            Assert-ToolbeltProfile $profile
            $key = $profile.platform+'-'+$profile.mode
            if (-not $keys.Add($key) -or $profile.path -cne ('Sql/Install-'+$key+'.sql') -or
                -not $entries.ContainsKey($profile.path)) { throw 'Profilpfad oder Profilmenge ist abweichend.' }
            $sql = $utf8.GetString($entries[$profile.path]).TrimStart([char]0xfeff)
            if (-not $sql.StartsWith("USE [ContosoToolbelt];`n",[StringComparison]::Ordinal) -or
                ([regex]::Matches($sql,"(?m)^DECLARE @TrustMethod varchar\(24\)=N'auto';$")).Count -ne 1) {
                throw 'Kontrollierter Datenbank-/Trust-Einstieg fehlt.'
            }
        }
        return @{ Manifest=$manifest; Files=$entries }
    } finally { $archive.Dispose() }
}

function Get-ToolbeltInstallSql($Package, $Profile, [string]$Database, [string]$TrustMethod) {
    if ($TrustMethod -notin 'auto','hash','trustworthy-checked','trustworthy') { throw 'Ungültiger Trustweg.' }
    if ([string]::IsNullOrWhiteSpace($Database) -or $Database.Length -gt 128 -or
        $Database.Contains('$(') -or @($Database.ToCharArray() | Where-Object { [char]::IsControl($_) }).Count) {
        throw 'Ungültiger Datenbankname oder nicht unterstütztes Client-Steuerzeichen.'
    }
    $sql = [Text.UTF8Encoding]::new($false,$true).GetString($Package.Files[$Profile.path]).TrimStart([char]0xfeff)
    $prefix = "USE [ContosoToolbelt];`n"
    if (-not $sql.StartsWith($prefix,[StringComparison]::Ordinal)) { throw 'Datenbank-Einstieg ist abweichend.' }
    $sql = 'USE ['+$Database.Replace(']',']]')+"];`n"+$sql.Substring($prefix.Length)
    $declaredTrust=if($Profile.PSObject.Properties['trust']){[string]$Profile.trust}else{'auto'}
    if($declaredTrust -notin 'auto','hash','trustworthy-checked','trustworthy' -or
        ([regex]::Matches($sql,[regex]::Escape("DECLARE @TrustMethod varchar(24)=N'$declaredTrust';"))).Count -ne 1) {
        throw 'Kontrollierter Trust-Einstieg ist abweichend.'
    }
    $sql.Replace("DECLARE @TrustMethod varchar(24)=N'$declaredTrust';","DECLARE @TrustMethod varchar(24)=N'$TrustMethod';")
}

function Get-ToolbeltSqlPayload([string]$SqlFile, [string]$ExpectedSha256 = '') {
    $path=(Resolve-Path -LiteralPath $SqlFile).Path
    $record=Get-Content -LiteralPath ($path+'.manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json -Depth 64
    $bytes=[IO.File]::ReadAllBytes($path)
    if($record.schema -cne 'toolbelt-markerless-install/v1' -or
        (Get-ToolbeltSha256 $bytes) -cne $record.sql_sha256 -or
        ($ExpectedSha256 -and $record.sql_sha256 -ine $ExpectedSha256)) { throw 'SQL-Datei oder Buildmanifest ist abweichend.' }
    $profile=[pscustomobject]@{platform=$record.platform;mode=$record.mode;trust=$record.trust;path='custom.sql';
        modules=@($record.modules);objects=@($record.objects);assemblies=$record.binary_sha512}
    Assert-ToolbeltProfile $profile
    $package=@{Manifest=[pscustomobject]@{release='source-build';profiles=@($profile)};Files=@{'custom.sql'=$bytes}}
    [void](Get-ToolbeltInstallSql $package $profile 'ContosoToolbelt' $record.trust)
    $package
}

function Get-ToolbeltReceiptSql($Profile, [string]$Database) {
    Assert-ToolbeltProfile $Profile
    $sql = "USE ["+$Database.Replace(']',']]')+"];`nSET NOCOUNT ON;`n"
    $sql += 'DECLARE @expected TABLE(s sysname,n sysname,t varchar(32));'+"`n"
    $rows = @($Profile.objects | ForEach-Object { "(N'"+$_.schema+"',N'"+$_.name+"','"+$_.types+"')" })
    for ($offset=0; $offset -lt $rows.Count; $offset+=500) {
        $last=[Math]::Min($offset+499,$rows.Count-1)
        $sql += 'INSERT @expected VALUES '+($rows[$offset..$last] -join ',')+";`n"
    }
    $sql += @'
IF EXISTS(SELECT 1 FROM @expected e WHERE NOT EXISTS(
 SELECT 1 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name=e.s AND o.name=e.n
   AND CHARINDEX((','+RTRIM(o.type)+',') COLLATE Latin1_General_100_BIN2,
                 (','+e.t+',') COLLATE Latin1_General_100_BIN2)>0))
 THROW 51000,N'TBX_RECEIPT: Erwartete Schnittstelle fehlt oder hat einen anderen Objekttyp.',1;
'@
    foreach ($assembly in $Profile.assemblies.PSObject.Properties) {
        $sql += "`nIF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'"+$assembly.Name+"') THROW 51000,N'TBX_RECEIPT: Erwartete Assembly fehlt.',1;"
    }
    $sql += "`nSELECT N'TBX_INSTALL_OK|"+@($Profile.modules).Count+"';`n"
    $sql
}
