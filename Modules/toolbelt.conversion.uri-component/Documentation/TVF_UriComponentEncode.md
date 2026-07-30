# TVF_UriComponentEncode

`toolbelt_conversion.TVF_UriComponentEncode(@Value nvarchar(max))` liefert genau eine Zeile `EncodedValue nvarchar(max)`. RFC-3986-unreserved ASCII-Zeichen (`A-Z`, `a-z`, `0-9`, `-`, `.`, `_`, `~`) bleiben unverändert; alle anderen UTF-8-Octets werden mit großem `%HH` codiert. Bereits codierter Text wird erneut als Text behandelt, also `%` zu `%25`.
