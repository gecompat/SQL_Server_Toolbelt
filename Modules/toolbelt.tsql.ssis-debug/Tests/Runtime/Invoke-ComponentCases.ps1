# Zusätzliche endliche V1-Profile, einmal pro eigenem Datenbanklauf. Die
# Grundtabellen/Helper stammen aus Invoke-CoreContract, keine Paketexecution.
function XmlBytes([xml]$Document){return ,[Text.Encoding]::UTF8.GetBytes($Document.OuterXml)}
$selected=@($result.Select("ArtifactKind='StageSql'")|Where-Object ComponentId -eq 'Package\Flow\SourceA')[0]
$single=Explain -Bytes $bytes -Bindings $bindings -Catalog $catalog -Target $selected.TargetFlowId -Stage $selected.StageId
Check (@($single.Select("ArtifactKind='StageSql'")).Count -eq 1) 'EXACT_STAGE_SELECTION'
Check ((Sql ([string]$single.Select("ArtifactKind='StageSql'")[0].Content)).Rows.Count -eq 3) 'EXACT_STAGE_STANDALONE'
[xml]$doc=[Text.Encoding]::UTF8.GetString($bytes)
$derived=$doc.SelectSingleNode('//*[local-name()="component"][@name="Derived"]');$derived.SetAttribute('componentClassID','Synthetic.Unsupported')
$partial=Explain -Bytes (XmlBytes $doc) -Catalog $catalog -Stage 'all'
$known=@($partial.Select("ArtifactKind='StageSql' AND IsExecutable=true")|Where-Object ComponentId -eq 'Package\Flow\SourceA')
Check ($known.Count -gt 0 -and @($partial.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0) 'KNOWN_PREDECESSOR_OF_UNKNOWN_COMPONENT'
Check ((Sql ([string]$known[0].Content)).Rows.Count -eq 3) 'KNOWN_PREDECESSOR_EXECUTES'
# Eine echte Data-Conversion-Stufe statt der Berechnung: Adjusted=Amount.
[xml]$doc=[Text.Encoding]::UTF8.GetString($bytes)
$derived=$doc.SelectSingleNode('//*[local-name()="component"][@name="Derived"]');$derived.SetAttribute('componentClassID','Microsoft.DataConvert')
$output=$derived.SelectSingleNode('outputs/output/outputColumns/outputColumn[@name="Adjusted"]')
$output.SelectSingleNode('properties/property[@name="Expression"]').InnerText=''
$p=$doc.CreateElement('property');$p.SetAttribute('name','SourceInputColumnLineageID');$p.InnerText=$doc.SelectSingleNode('//*[local-name()="component"][@name="Union"]/outputs/output/outputColumns/outputColumn[@name="Amount"]').GetAttribute('lineageId');[void]$output.SelectSingleNode('properties').AppendChild($p)
$converted=Explain -Bytes (XmlBytes $doc) -Catalog $catalog
Check (@($converted.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'DATA_CONVERSION_TARGETS'
$convertedRows=Sql ([string]$converted.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content)
Check ($convertedRows.Rows.Count -eq 1 -and $convertedRows.Rows[0].Adjusted -eq 200) 'DATA_CONVERSION_EXECUTES'
CleanupArtifacts $converted
# Überschreiben und neue Spalte lesen denselben ursprünglichen Eingangsstand.
[xml]$doc=[Text.Encoding]::UTF8.GetString($bytes)
$derived=$doc.SelectSingleNode('//*[local-name()="component"][@name="Derived"]')
$input=$doc.CreateElement('inputColumn');$input.SetAttribute('refId','SyntheticOverwriteAmount');$input.SetAttribute('name','Amount');$input.SetAttribute('dataType','i4');$input.SetAttribute('lineageId',$doc.SelectSingleNode('//*[local-name()="component"][@name="Union"]/outputs/output/outputColumns/outputColumn[@name="Amount"]').GetAttribute('lineageId'))
$ps=$doc.CreateElement('properties');$p=$doc.CreateElement('property');$p.SetAttribute('name','Expression');$p.InnerText='[Amount] + 10';[void]$ps.AppendChild($p);[void]$input.AppendChild($ps);[void]$derived.SelectSingleNode('inputs/input/inputColumns').AppendChild($input)
$overwrite=Explain -Bytes (XmlBytes $doc) -Catalog $catalog -Stage 'all'
$stage=@($overwrite.Select("ArtifactKind='StageSql'")|Where-Object ComponentId -eq 'Package\Flow\Derived')[0]
$rows=Sql ([string]$stage.Content)
Check ($rows.Rows.Count -eq 5 -and @($rows.Rows|Where-Object{$_.Adjusted -ne $_.Amount-9}).Count -eq 0) 'OVERWRITE_COMMON_INPUT_VERSION'
CleanupArtifacts $overwrite
# Scope-Shadowing über einen lokalen Flow-Wert; kein Generatoraufruf muss
# eine gleichnamige Paketvariable in den näheren Scope hineinüberschreiben.
[xml]$doc=[Text.Encoding]::UTF8.GetString($bytes);$ns='www.microsoft.com/SqlServer/Dts'
$flow=$doc.SelectSingleNode('//*[local-name()="Executable"][@*[local-name()="ObjectName"]="Synthetic Flow"]')
$vars=$doc.CreateElement('DTS','Variables',$ns);$variable=$doc.CreateElement('DTS','Variable',$ns);[void]$variable.SetAttribute('Namespace',$ns,'User');[void]$variable.SetAttribute('ObjectName',$ns,'Threshold');[void]$variable.SetAttribute('DTSID',$ns,'{22222222-2222-2222-2222-222222222222}')
$value=$doc.CreateElement('DTS','VariableValue',$ns);[void]$value.SetAttribute('DataType',$ns,'3');$value.InnerText='1000';[void]$variable.AppendChild($value);[void]$vars.AppendChild($variable);[void]$flow.AppendChild($vars)
$shadow=Explain -Bytes (XmlBytes $doc) -Catalog $catalog
Check (@($shadow.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'SCOPED_VARIABLE_BOUND'
Check ((Sql ([string]$shadow.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content)).Rows.Count -eq 0) 'NEAREST_SCOPE_VALUE_EXECUTES'
CleanupArtifacts $shadow
# Tatsächlich ausgewählte Computed-Spalte und ihre native Berechnung.
[void](Sql 'ALTER TABLE dbo.SyntheticSourceA ADD DebugAmount AS Amount+1;')
try{
 $computed=Explain -Bytes (ChangedPackage -SourceSql 'SELECT KeyA,KeyB,DebugAmount AS Amount FROM dbo.SyntheticSourceA WHERE DebugAmount>=?') -Catalog $catalog
 if(@($computed.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -ne 2){
  $diagnoses=@($computed.Select("ArtifactKind='Diagnostic'")|ForEach-Object {[string]$_.DiagnosticCode+':'+[string]$_.Content})
  throw ('SSIS_COMPUTED_DIAG '+($diagnoses -join ' | '))
 }
 Check (@($computed.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'COMPUTED_COLUMN_BOUND'
 $rows=Sql ([string]$computed.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content)
 Check (@($rows.Select('KeyA=1 AND KeyB=10'))[0].Adjusted -eq 102) 'COMPUTED_COLUMN_EXECUTES'
 CleanupArtifacts $computed
 'SSIS_NATIVE_COMPUTED_COLUMN_PASS'
}finally{[void](Sql 'ALTER TABLE dbo.SyntheticSourceA DROP COLUMN DebugAmount;')}
[void](Sql 'CREATE FUNCTION dbo.SyntheticComputedFn(@v int) RETURNS int AS BEGIN DECLARE @r int=@v;RETURN @r;END;')
[void](Sql 'ALTER TABLE dbo.SyntheticSourceA ADD DebugUnsafe AS dbo.SyntheticComputedFn(Amount);')
try{
 $unsafeComputed=Explain -Bytes (ChangedPackage -SourceSql 'SELECT KeyA,KeyB,DebugUnsafe AS Amount FROM dbo.SyntheticSourceA WHERE DebugUnsafe>=?') -Catalog $catalog
 Check (@($unsafeComputed.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 0 -and @($unsafeComputed.Select("ArtifactKind='Diagnostic' AND DiagnosticCode='unsupported_component'")).Count -gt 0) 'PROCEDURAL_COMPUTED_DEPENDENCY_STILL_BLOCKED'
 'SSIS_NATIVE_COMPUTED_UDF_REJECTION_PASS'
}finally{[void](Sql 'ALTER TABLE dbo.SyntheticSourceA DROP COLUMN DebugUnsafe;DROP FUNCTION dbo.SyntheticComputedFn;')}
# Unicode-Lookup bei voneinander abweichenden Source-/Referenz-/Debug- und
# TempDB-Collations. Die Vereinheitlichung muss im generierten SQL stehen.
[void](Sql @'
CREATE TABLE dbo.SyntheticTextA(KeyA nvarchar(10) COLLATE Latin1_General_100_BIN2 NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticTextB(KeyA nvarchar(10) COLLATE Latin1_General_100_BIN2 NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticTextLookup(KeyA nvarchar(10) COLLATE Latin1_General_100_CS_AS NOT NULL,KeyB int NOT NULL,Score int NULL);
INSERT dbo.SyntheticTextA VALUES(N'a',10,100),(N'ä',20,20),(N'b',10,200);
INSERT dbo.SyntheticTextB VALUES(N'A',10,80),(N'z',30,30);
INSERT dbo.SyntheticTextLookup VALUES(N'a',10,7),(N'A',10,9),(N'ä',20,NULL),(N'b',10,2);
'@)
try{
 [xml]$doc=[Text.Encoding]::UTF8.GetString($bytes)
 foreach($node in $doc.SelectNodes('//*[@name="KeyA"]')){if($node.LocalName -in @('inputColumn','outputColumn','externalMetadataColumn')){$node.SetAttribute('dataType','wstr');$node.SetAttribute('cachedDataType','wstr');$node.SetAttribute('length','10');$node.SetAttribute('cachedLength','10')}}
 foreach($p in $doc.SelectNodes('//property[@name="SqlCommand"]')){$p.InnerText=$p.InnerText.Replace('SyntheticSourceA','SyntheticTextA').Replace('SyntheticSourceB','SyntheticTextB').Replace('SyntheticLookup','SyntheticTextLookup')}
 $text=Explain -Bytes (XmlBytes $doc) -Catalog $catalog
 Check (@($text.Select("ArtifactKind='TargetSql' AND IsExecutable=true")).Count -eq 2) 'UNICODE_LOOKUP_COLLATIONS_BOUND'
 $hi=Sql ([string]$text.Select("ArtifactKind='TargetSql'",'Ordinal')[0].Content);$lo=Sql ([string]$text.Select("ArtifactKind='TargetSql'",'Ordinal')[1].Content)
 Check ($hi.Rows.Count -eq 2 -and $lo.Rows.Count -eq 3) 'UNICODE_LOOKUP_COLLATIONS_EXECUTE'
 $collation=[string](Sql "SELECT CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),N'Collation')) AS C;").Rows[0].C
 if($collation -like '*_CI_*'){Check (@($hi.Rows|Where-Object{$_.KeyA -ceq 'a'})[0].Score -eq @($lo.Rows|Where-Object{$_.KeyA -ceq 'A'})[0].Score) 'EXPLICIT_CASE_INSENSITIVE_LOOKUP'}
 else{Check (@($hi.Rows|Where-Object{$_.KeyA -ceq 'a'})[0].Score -eq 7 -and @($lo.Rows|Where-Object{$_.KeyA -ceq 'A'})[0].Score -eq 9) 'EXPLICIT_CASE_SENSITIVE_LOOKUP'}
 CleanupArtifacts $text
}finally{[void](Sql 'DROP TABLE dbo.SyntheticTextA,dbo.SyntheticTextB,dbo.SyntheticTextLookup;')}
"SSIS_NATIVE_COMPONENT_PASS finite conversion/overwrite/scope/partial/computed profiles"
