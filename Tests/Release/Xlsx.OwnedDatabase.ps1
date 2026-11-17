# Gemeinsame bisherige Create/Identity/Owner/CL-Sequenz; kein Rechte- oder Lab-Setup.
function New-XlsxFullSizeOwnedDatabase($Control,
    [ValidateSet('l','c','u')][string]$Suffix,
    [ValidateSet('Latin1_General_100_CI_AS_SC','Latin1_General_100_CS_AS')][string]$Collation,
    [ValidateSet(150,160,170)][int]$CompatibilityLevel){
    $consumerScope=$script:runset.PSObject.Properties['qualification_scope'] -and
        $script:runset.qualification_scope -ceq 'composition-consumer-rest'
    $maximum=if($consumerScope){3}else{2}
    if($script:ledger.owner -cnotmatch '\A[a-f0-9]{32}\z' -or
       $script:ledger.databases.Count -ge $maximum -or
       @($script:ledger.databases|Where-Object suffix -CEQ $Suffix).Count -or
       ($Suffix -ceq 'u' -and (-not $consumerScope -or $Collation -cne 'Latin1_General_100_CS_AS')) -or
       ($Suffix -cne 'u' -and $Collation -cne 'Latin1_General_100_CI_AS_SC')){
        throw 'XLSX_OWN_DATABASE_ADMISSION'
    }
    $name='Toolbelt_Release_'+$script:ledger.owner+'_'+$Suffix
    $entry=[ordered]@{name=$name;suffix=$Suffix;id=$null;created=$null;state='CREATING'}
    $script:ledger.databases+=@($entry);Save-ReleaseJournal
    Invoke-ReleaseSql $Control "IF DB_ID(N'$name') IS NOT NULL THROW 52096,N'Database collision.',12; CREATE DATABASE [$name] COLLATE $Collation;"
    $identity=@(Invoke-ReleaseSql $Control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$name} -Rows)
    if($identity.Count -ne 1){throw 'XLSX_FULL_SIZE_DATABASE_IDENTITY'}
    $entry.id=$identity[0].Id;$entry.created=$identity[0].Created;$entry.state='CREATED';Save-ReleaseJournal
    $db=Open-ReleaseConnection $name
    try{
        Invoke-ReleaseSql $db 'DECLARE @O nvarchar(32)=@Owner; EXEC sys.sp_addextendedproperty @name=N''Test.Release.Owner'',@value=@O;' @{'@Owner'=$script:ledger.owner}
        $entry.state='OWNED';Save-ReleaseJournal
        Invoke-ReleaseSql $Control "ALTER DATABASE [$name] SET COMPATIBILITY_LEVEL=$CompatibilityLevel;"
        return ,$db
    }catch{$db.Dispose();throw}
}
