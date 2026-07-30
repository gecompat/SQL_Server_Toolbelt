# Design: Integer Base Conversion

`toolbelt.conversion.integer-base` Version `1.0.0` implementiert den
freigegebenen Kandidaten `TC-2026-031` ohne Abhängigkeit zu Base64 oder einer
persistenten Lookup-Tabelle.

Die Basis ist die Länge eines expliziten Alphabets aus 2 bis 93 druckbaren
ASCII-Zeichen. Das erste Zeichen repräsentiert Null; jedes weitere Zeichen
entspricht seinem nullbasierten Index. Binäre Vergleiche sichern
Case-Sensitivität und Collation-Unabhängigkeit. `-` bleibt als Vorzeichen
reserviert.

Encode verwendet Division und Modulo, Decode eine vor jeder
Multiplikation geprüfte Akkumulation. `decimal(38,0)` hält die Magnitude des
kleinsten `bigint` sicher, während explizite Grenzprüfungen einen Decode-
Overflow verhindern.

Die Textdarstellung ist kanonisch: kein `+`, kein Padding, keine Präfixe oder
Gruppierung, keine führenden Nullzeichen und kein `-0`. Version `1.0.0`
verarbeitet ausschließlich `bigint`; eine spätere `decimal(38,0)`-Oberfläche
ist ein eigener Vertrag.

Lokales und zentrales Deployment folgen dem allgemeinen Lifecycle-Vertrag.
Der Modulfehlerbereich ist `51090–51099`. Runtime-Evidenz ist bis zur
tatsächlichen Workflow-Ausführung `not executed`.
