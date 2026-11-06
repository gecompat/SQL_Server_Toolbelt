# Reine Auswahlprädikate für Producer und unabhängigen Dispositionsaudit.
# Kein Labimport, Dateischreiben oder SQL-Zugriff; der Caller pinnt diese Datei.
function Test-JsonSchemaTargetScope([string]$Platform,[string]$Version,[string]$Patch,
 [int]$CompatibilityLevel,[string]$QualificationScope){
 $levels=switch -CaseSensitive($Version){'2019'{@(150)};'2022'{@(150,160)};'2025'{@(150,160,170)};default{@()}}
 if($CompatibilityLevel-notin$levels){return $false}
 $windows=$Platform-ceq'windows'-and$Patch-ceq@{'2019'='CU32';'2022'='CU26';'2025'='CU8'}[$Version]
 $linux=$Platform-ceq'linux'-and$Patch-ceq'latest'
 if($QualificationScope-ceq'core-schema'){return ($windows-or$linux)}
 if($QualificationScope-cnotin@('constructors','migration')){return $false}
 return (($linux-and$Version-ceq'2019')-or($windows-and$Version-ceq'2025')-or($QualificationScope-ceq'constructors'-and$windows))
}
