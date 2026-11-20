# Gemeinsamer reproduzierbarer Buildadapter. Keine SQL-/Infrastrukturaktionen.
function Resolve-ToolbeltScriptDom {
    param([Parameter(Mandatory)][string]$Path)
    $originalHash='459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7'
    $privateHash='634EBA3C4D7AB7EBEA4B59C68C3B0C78081686F54359595B8206EADE989BFC51D02A91DAB4CA23065854C1624E93A2B4C2216AB6AA7DF9CA191541BF0F795813'
    $hash=(Get-FileHash -LiteralPath $Path -Algorithm SHA512).Hash
    if($hash -ceq $privateHash){
        if([Reflection.AssemblyName]::GetAssemblyName($Path).Name -cne 'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom'){throw 'PRIVATE_SCRIPTDOM_IDENTITY'}
        return [IO.Path]::GetFullPath($Path)
    }
    if($hash -cne $originalHash){throw 'PRIVATE_SCRIPTDOM_ORIGINAL_PIN'}
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'PRIVATE_SCRIPTDOM_WINDOWS_BUILD_REQUIRED'}
    $repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    . (Join-Path $repo 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
    $cache=Join-Path $repo '.runtime/private-scriptdom-634eba3c4d7ab7eb'
    [IO.Directory]::CreateDirectory($cache)|Out-Null
    if(((Get-Item -LiteralPath $cache -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)-ne 0){throw 'PRIVATE_SCRIPTDOM_CACHE_REPARSE'}
    $output=Join-Path $cache 'tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    if(Test-Path -LiteralPath $output){
        if((Get-FileHash -LiteralPath $output -Algorithm SHA512).Hash -cne $privateHash){throw 'PRIVATE_SCRIPTDOM_EXISTING_OUTPUT_DRIFT'}
        return $output
    }
    $package=Join-Path $cache 'mono.cecil.0.11.6.nupkg'
    $packageHash='1C5932246B23C9F317690A25CE3E1416D168D885871063D2F604CF997ED9E99D41BCCDD0E22D4BE6E4A5EA729D06BD92CC543686DBBD75AB0199DB60E0912FB4'
    if(-not(Test-Path -LiteralPath $package)){
        Invoke-WebRequest -Uri 'https://api.nuget.org/v3-flatcontainer/mono.cecil/0.11.6/mono.cecil.0.11.6.nupkg' -OutFile $package -TimeoutSec 60
    }
    if((Get-FileHash -LiteralPath $package -Algorithm SHA512).Hash -cne $packageHash){throw 'PRIVATE_SCRIPTDOM_CECIL_PACKAGE_PIN'}
    $cecil=Join-Path $cache 'Mono.Cecil.dll'
    if(-not(Test-Path -LiteralPath $cecil)){
        Add-Type -AssemblyName System.IO.Compression
        $zip=[IO.Compression.ZipFile]::OpenRead($package)
        try{
            $entry=$zip.GetEntry('lib/net40/Mono.Cecil.dll');if(-not $entry){throw 'PRIVATE_SCRIPTDOM_CECIL_ENTRY'}
            $entryInput=$entry.Open();$destination=[IO.File]::Open($cecil,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try{$entryInput.CopyTo($destination)}finally{$destination.Dispose();$entryInput.Dispose()}
        }finally{$zip.Dispose()}
    }
    $toolHash='9F54B9E85EF70AFCB36569885DE73BBA704A8901C8DDBB5A35DE6A1921D4D42F88026AEA41ED77EC7A8041EE8A04EFEF817DEDA7DEA0F29A716DAB7A6EA7FD9E'
    if((Get-FileHash -LiteralPath $cecil -Algorithm SHA512).Hash -cne $toolHash){throw 'PRIVATE_SCRIPTDOM_CECIL_BINARY_PIN'}
    $source=Join-Path $PSScriptRoot 'PrivateScriptDom.cs'
    $exe=Join-Path $cache ('PrivateScriptDom-'+(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.Substring(0,16)+'.exe')
    $compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
    $compile=Invoke-OwnedProcess -FileName $compiler -Arguments @('/nologo','/target:exe','/optimize+',"/reference:$cecil","/out:$exe",$source) -TimeoutMilliseconds 60000
    if($compile.ExitCode -ne 0){throw 'PRIVATE_SCRIPTDOM_TOOL_BUILD'}
    $built=Invoke-OwnedProcess -FileName $exe -Arguments @([IO.Path]::GetFullPath($Path),$output) -TimeoutMilliseconds 60000
    if($built.ExitCode -ne 0 -or (Get-FileHash -LiteralPath $output -Algorithm SHA512).Hash -cne $privateHash){throw 'PRIVATE_SCRIPTDOM_TRANSFORM_PIN'}
    $second=Join-Path $cache ('reproduction-'+[guid]::NewGuid().ToString('N')+'.dll')
    $reproduced=Invoke-OwnedProcess -FileName $exe -Arguments @([IO.Path]::GetFullPath($Path),$second) -TimeoutMilliseconds 60000
    if($reproduced.ExitCode -ne 0 -or (Get-FileHash -LiteralPath $second -Algorithm SHA512).Hash -cne $privateHash){throw 'PRIVATE_SCRIPTDOM_REPRODUCTION'}
    Remove-Item -LiteralPath $second -Force
    $provenance=@{schemaVersion=1;originalSha512=$originalHash;privateSha512=$privateHash;privateIdentity='tlblt.Microsoft.SqlServer.TransactSql.ScriptDom, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null';cecilVersion='0.11.6';cecilPackageSha512=$packageHash;cecilToolSha512=$toolHash;transformSourceSha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash;reproduced=$true;originalModified=$false}
    [IO.File]::WriteAllText(($output+'.provenance.json'),($provenance|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
    return $output
}
