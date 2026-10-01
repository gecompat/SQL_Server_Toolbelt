# Wiederverwendbare SQLClient-Probe; keine eigene Verbindung oder Credentials.
# Connection und synthetisches Fixture kommen ausschließlich vom Testadapter.
function Test-XlsxMetadata {
 param([Data.SqlClient.SqlConnection]$Connection,[byte[]]$Fixture,[string]$ToolbeltDatabase)
 $prefix=if($ToolbeltDatabase){'['+$ToolbeltDatabase.Replace(']',']]')+'].'}else{''}
 $specs=@(
  @{Name='USP_ListXlsxWorksheets';Count=1;Params=16;Columns=@('SheetOrdinal','SheetName','Visibility','Date1904');Types=@('Int32','String','String','Boolean');Nullable=@($false,$false,$false,$false);Max=@(1)},
  @{Name='USP_ReadXlsxWorksheetCells';Count=9;Params=17;Columns=@('RowOrdinal','ColumnOrdinal','StoredType','ValuePresent','RawValue','TextValue','FormulaPresent','FormulaText','FormulaKind','SharedFormulaIndex','CachePresent','CacheValue');Types=@('Int32','Int32','String','Boolean','String','String','Boolean','String','String','Int32','Boolean','String');Nullable=@($false,$false,$false,$false,$true,$true,$false,$true,$true,$true,$false,$true);Max=@(4,5,7,11)}
 )
 $helpColumns=@('HelpContractVersion','SchemaName','ObjectName','Section','Ordinal','ItemName','SqlDataType','IsRequired','IsNullable','DefaultValue','Description','ExampleSql')
 foreach($s in $specs){
  $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=60
  $cmd.CommandText='EXEC '+$prefix+'toolbelt_file.'+$s.Name+' @XlsxBinary=@Binary'+$(if($s.Name-like'*Cells'){',@SheetOrdinal=1'}else{''})+';'
  [void]$cmd.Parameters.Add('@Binary',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@Binary'].Value=$Fixture
  try{
   $reader=$cmd.ExecuteReader()
   try{
    $schema=$reader.GetSchemaTable()
    if($reader.FieldCount-ne$s.Columns.Count){throw 'SELECT-Spaltenzahl falsch.'}
    for($i=0;$i-lt$reader.FieldCount;$i++){
     if($reader.GetName($i)-cne$s.Columns[$i] -or $reader.GetFieldType($i).Name-cne$s.Types[$i] -or
        [bool]$schema.Rows[$i].AllowDBNull-ne$s.Nullable[$i]){throw 'SELECT-Metadatenvertrag falsch.'}
     if($i-in$s.Max -and [int]$schema.Rows[$i].ColumnSize-ne2147483647){throw 'nvarchar(max)-Metadatenvertrag falsch.'}
    }
    $count=0;while($reader.Read()){$count++}
    if($count-ne$s.Count -or $reader.NextResult()){throw 'SELECT-Zeilen-/Resultsetvertrag falsch.'}
   }finally{$reader.Dispose()}
   $cmd.Parameters['@Binary'].Value=[DBNull]::Value
   $reader=$cmd.ExecuteReader()
   try {
    $schema=$reader.GetSchemaTable()
    if($reader.FieldCount-ne$s.Columns.Count){throw 'NULL-SELECT-Spaltenzahl falsch.'}
    for($i=0;$i-lt$reader.FieldCount;$i++){
     if($reader.GetName($i)-cne$s.Columns[$i]-or$reader.GetFieldType($i).Name-cne$s.Types[$i]-or
        [bool]$schema.Rows[$i].AllowDBNull-ne$s.Nullable[$i]){throw 'NULL-SELECT-Metadatenvertrag falsch.'}
     if($i-in$s.Max-and[int]$schema.Rows[$i].ColumnSize-ne2147483647){throw 'NULL-SELECT-max-Typ falsch.'}
    }
    if($reader.Read()-or$reader.NextResult()){throw 'NULL-SELECT-Zeilen-/Resultsetvertrag falsch.'}
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
  # Hilfe ignoriert absichtlich ungültige Fachparameter und Debug. Keine
  # zusätzlichen Resultsets oder INFO-Messages; keine Abhängigkeit wird aufgerufen.
  $messages=[Collections.Generic.List[string]]::new()
  $handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$args)$messages.Add('message')}
  $Connection.add_InfoMessage($handler)
  $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=60
  $cmd.CommandText='EXEC '+$prefix+'toolbelt_file.'+$s.Name+' @Hilfe=1,@Debug=255,@XlsxBinary=0x010203,@MaxParts=0,@ResultTable=N''not a temp table'';'
  try{
   $reader=$cmd.ExecuteReader()
   try{
    if($reader.FieldCount-ne12){throw 'Help-Spaltenzahl falsch.'}
    for($i=0;$i-lt12;$i++){if($reader.GetName($i)-cne$helpColumns[$i]){throw 'Help-Spaltenname falsch.'}}
    $sections=[Collections.Generic.Dictionary[string,int]]::new()
    while($reader.Read()){
     if($reader.IsDBNull(0)-or$reader.GetString(0)-cne'1.0'-or$reader.GetString(1)-cne'toolbelt_file'-or$reader.GetString(2)-cne$s.Name-or$reader.IsDBNull(10)){throw 'Help-Pflichtwert fehlt.'}
     $section=$reader.GetString(3);if(-not$sections.ContainsKey($section)){$sections.Add($section,0)};$sections[$section]++
    }
    if($reader.NextResult()){throw 'Zusätzliches Help-Resultset.'}
    foreach($required in @('DESCRIPTION','PARAMETER','RESULT_COLUMN','EXAMPLE')){if(-not$sections.ContainsKey($required)){throw 'Help-Pflichtsection fehlt.'}}
    if($sections['PARAMETER']-ne$s.Params-or$sections['RESULT_COLUMN']-ne$s.Columns.Count){throw 'Help-Parameter-/Spaltenvertrag falsch.'}
   }finally{$reader.Dispose()}
   if($messages.Count){throw 'Help-Debugmessage unerlaubt.'}
  }finally{$cmd.Dispose();$Connection.remove_InfoMessage($handler)}
 }
 foreach($mode in @(0,1)){
  $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=60
  $cmd.CommandText='EXEC '+$prefix+'toolbelt_file.USP_InternalXlsxRead @ReadCells='+$mode+',@Hilfe=1,@Debug=255,@MaxParts=0;'
  try{
   $reader=$cmd.ExecuteReader()
   try{
    $schema=$reader.GetSchemaTable()
    if($reader.FieldCount-ne12){throw 'Interne Help-Spaltenzahl falsch.'}
    $count=0;$params=0
    for($i=0;$i-lt12;$i++){
     if($reader.GetName($i)-cne$helpColumns[$i]-or[bool]$schema.Rows[$i].AllowDBNull-ne($i-notin@(0,1,2,3,4,10))){throw 'Interne Help-Nullability oder Spaltenname falsch.'}
    }
    while($reader.Read()){
     if($reader.GetString(2)-cne'USP_InternalXlsxRead'){throw 'Interne Help-Objektidentität falsch.'}
     if($reader.GetString(3)-ceq'RESULT_COLUMN'){$count++}
     if($reader.GetString(3)-ceq'PARAMETER'){$params++}
     if($mode-eq0-and-not$reader.IsDBNull(5)-and$reader.GetString(5)-ceq'@SheetOrdinal'-and($reader.GetBoolean(7)-or-not$reader.GetBoolean(8))){throw 'Interne Modus-0-Hilfe verlangt SheetOrdinal.'}
    }
    if($params-ne18-or$count-ne$(if($mode-eq0){4}else{12})-or$reader.NextResult()){throw 'Interne Help-Modusshape falsch.'}
   }finally{$reader.Dispose()}
  }finally{$cmd.Dispose()}
 }
 'PASS: XLSX SQLClient SELECT field order/types/nullability/max, actual omitted defaults, public/internal Help modes and no extra resultsets/messages.'
}

