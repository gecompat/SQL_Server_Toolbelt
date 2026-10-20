# Fehlende Marker ausschließlich im eigenen, installierten Lab-Fixturescope.
function Get-CsvMarkerAbsenceCases([ValidateSet('local','central')][string]$Mode){
 $properties=@(
  @('Toolbelt.Managed','CONVERT(bit,1)'),
  @('Toolbelt.ModuleId',"CONVERT(nvarchar(128),N'toolbelt.file.csv-memory')"),
  @('Toolbelt.ModuleVersion',"CONVERT(nvarchar(16),N'1.0.0')")
 )
 foreach($slot in @('USP_ParseCsv','USP_WriteCsv','TVF_InternalParseCsv','SVF_InternalMeasureCsvCell','SVF_InternalQuoteCsvCell')){
  foreach($property in $properties){[pscustomobject]@{Scope='OBJECT';Object=$slot;Property=$property[0];Original=$property[1];State=5}}
  $visibility=if($slot.StartsWith('USP_',[StringComparison]::Ordinal)){'public'}else{'internal'}
  [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.Visibility';Original="CONVERT(nvarchar(16),N'$visibility')";State=5}
 }
 foreach($property in $properties){[pscustomobject]@{Scope='ASSEMBLY';Object='Toolbelt_File_CsvMemory';Property=$property[0];Original=$property[1];State=4}}
 [pscustomobject]@{Scope='DATABASE';Object='';Property='Toolbelt.Module.toolbelt.file.csv-memory.Version';Original="CONVERT(nvarchar(16),N'1.0.0')";State=3}
 [pscustomobject]@{Scope='DATABASE';Object='';Property='Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode';Original="CONVERT(nvarchar(16),N'$Mode')";State=2}
 [pscustomobject]@{Scope='SCHEMA';Object='toolbelt_file';Property='Toolbelt.Managed';Original='CONVERT(int,1)';State=1}
 [pscustomobject]@{Scope='SCHEMA';Object='toolbelt_file';Property='Toolbelt.SchemaCategory';Original="CONVERT(nvarchar(4),N'file')";State=1}
}

function Get-CsvMarkerAbsenceLocation($Case){
 # Auch SQL-Wertausdrücke kommen ausschließlich aus der geschlossenen Fallliste.
 $known=@(foreach($mode in @('local','central')){Get-CsvMarkerAbsenceCases $mode})
 if(@($known|Where-Object {$_.Scope -ceq $Case.Scope -and $_.Object -ceq $Case.Object -and $_.Property -ceq $Case.Property -and $_.Original -ceq $Case.Original -and $_.State -eq $Case.State}).Count -lt 1){throw 'CSV_ABSENCE_CASE_INVALID'}
 $class=0;$major='0';$levels=''
 switch -CaseSensitive ($Case.Scope){
  'OBJECT' {
   $class=1;$major="OBJECT_ID(N'toolbelt_file.$($Case.Object)')"
   $kind=if($Case.Object.StartsWith('USP_',[StringComparison]::Ordinal)){'PROCEDURE'}else{'FUNCTION'}
   $levels=",@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'$kind',@level1name=N'$($Case.Object)'"
  }
  'ASSEMBLY' {$class=5;$major="(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory')";$levels=",@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_CsvMemory'"}
  'SCHEMA' {$class=3;$major="SCHEMA_ID(N'toolbelt_file')";$levels=",@level0type=N'SCHEMA',@level0name=N'toolbelt_file'"}
  'DATABASE' {}
  default {throw 'CSV_ABSENCE_SCOPE_INVALID'}
 }
 [pscustomobject]@{Class=$class;Major=$major;Levels=$levels}
}

function Set-CsvMarkerPresence($Connection,$Case,[ValidateSet('Remove','Restore',IgnoreCase=$false)][string]$Action){
 $location=Get-CsvMarkerAbsenceLocation $Case
 $class=$location.Class;$major=$location.Major;$levels=$location.Levels
 $check="SELECT COUNT(*) FROM sys.extended_properties WHERE class=$class AND major_id=$major AND minor_id=0 AND name=N'$($Case.Property)'"
 if($Action -ceq 'Remove'){
  Invoke-CsvSql $Connection @"
DECLARE @Expected sql_variant=$($Case.Original),@Actual sql_variant;
IF ($check)<>1 THROW 51597,N'Synthetic marker identity required.',1;
SELECT @Actual=value FROM sys.extended_properties WHERE class=$class AND major_id=$major AND minor_id=0 AND name=N'$($Case.Property)';
IF @Actual IS NULL OR SQL_VARIANT_PROPERTY(@Actual,N'BaseType')<>SQL_VARIANT_PROPERTY(@Expected,N'BaseType')
 OR SQL_VARIANT_PROPERTY(@Actual,N'MaxLength')<>SQL_VARIANT_PROPERTY(@Expected,N'MaxLength')
 OR DATALENGTH(@Actual)<>DATALENGTH(@Expected) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected)
 THROW 51597,N'Synthetic marker changed.',2;
EXEC sys.sp_dropextendedproperty @name=N'$($Case.Property)'$levels;
"@
 }else{
  Invoke-CsvSql $Connection @"
IF ($check)<>0 THROW 51597,N'Synthetic marker absence changed.',3;
DECLARE @Value sql_variant=$($Case.Original);
EXEC sys.sp_addextendedproperty @name=N'$($Case.Property)',@value=@Value$levels;
"@
 }
}

function Invoke-CsvMarkerAbsenceGuards($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('local','central')][string]$Mode){
 $cases=@(Get-CsvMarkerAbsenceCases $Mode)
 if($cases.Count -ne 27 -or @($cases|ForEach-Object {$_.Scope+'|'+$_.Object+'|'+$_.Property}|Sort-Object -Unique).Count -ne 27){throw 'CSV_ABSENCE_CASE_SET_INVALID'}
 $passed=0
 foreach($case in $cases){
  $script:stage='MARKER_ABSENCE_'+$Mode+'_'+$passed
  $baseline=Get-CsvSnapshot $Connection;$mutated=$null
  Set-CsvMarkerPresence $Connection $case 'Remove'
  try{
   $mutated=Get-CsvSnapshot $Connection
   if($mutated -ceq $baseline){throw 'CSV_ABSENCE_MUTATION_UNOBSERVED'}
   foreach($text in @($Deploy,$Uninstall)){Assert-CsvGuardRejected $Connection $text 55324 $case.State $mutated;$passed++}
  }finally{
   if($null -ne $mutated){
    if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_ABSENCE_RESTORE_DRIFT'}
    Set-CsvMarkerPresence $Connection $case 'Restore'
    if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_ABSENCE_RESTORE_MISMATCH'}
   }
  }
 }
 if($passed -ne 54){throw 'CSV_ABSENCE_CASE_COUNT'}
 return $passed
}
