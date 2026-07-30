# TVF_TrimDirectionalVarchar

`toolbelt_string.TVF_TrimDirectionalVarchar(@Value, @Characters = ' ', @Direction = 'BOTH')` liefert genau eine `varchar(max)`-Spalte `Value`. Der Vertrag entspricht der Unicode-Variante; ein `varchar`-Zeichen wird bytepositionsbasiert verarbeitet. UTF-8-`varchar` ist deshalb kein Unicode-Codepoint-Vertrag und wird separat bewertet.
