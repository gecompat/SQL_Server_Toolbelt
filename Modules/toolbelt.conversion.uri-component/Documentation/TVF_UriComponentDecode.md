# TVF_UriComponentDecode

`toolbelt_conversion.TVF_UriComponentDecode(@Value nvarchar(max))` liefert `DecodedValue`, `IsValid` und `ValidationCode`. Codes: `0` gültig, `10` Nicht-ASCII-Input, `11` ungültiges Prozent-Triplet, `12` ungültige UTF-8-Sequenz, `13` dekodiertes NUL. `NULL` bleibt in allen drei Spalten `NULL`.

Die Funktion führt genau eine Runde aus: `%252F` wird zu `%2F`, nicht zu `/`.
