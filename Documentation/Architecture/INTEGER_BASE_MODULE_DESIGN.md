# Design: Integer Base Conversion

`toolbelt.conversion.integer-base` Version `1.1.0` implementiert den
freigegebenen Kandidaten `TC-2026-031` ohne Abhängigkeit zu Base64 oder einer
persistenten Lookup-Tabelle.

Die Basis ist die Länge eines expliziten Alphabets aus 2 bis 93 druckbaren
ASCII-Zeichen. Das erste Zeichen repräsentiert Null; jedes weitere Zeichen
entspricht seinem nullbasierten Index. Binäre Vergleiche sichern
Case-Sensitivität und Collation-Unabhängigkeit. `-` bleibt als Vorzeichen
reserviert.

Die inline TVFs `TVF_IntegerToBase` und `TVF_TryBaseToInteger` sind die
kanonischen relationalen Kerne. Die gleichnamigen `SVF_*`-Varianten bleiben
als Convenience-APIs und delegieren vollständig an diese Kerne. Die Wrapper
sind bewusst nicht schemagebunden, weil ihre Abhängigkeit andernfalls das
Ersetzen der TVF-Kerne bei Wiederholungs- und Upgrade-Deployments blockiert.

Encode verwendet Division und Modulo, Decode eine vor jeder
Multiplikation geprüfte Akkumulation. `decimal(38,0)` hält die Magnitude des
kleinsten `bigint` sicher, während explizite Grenzprüfungen einen Decode-
Overflow verhindern.

Die Textdarstellung ist kanonisch: kein `+`, kein Padding, keine Präfixe oder
Gruppierung, keine führenden Nullzeichen und kein `-0`. Version `1.1.0`
verarbeitet ausschließlich `bigint`; eine spätere `decimal(38,0)`-Oberfläche
ist ein eigener Vertrag.

Lokales und zentrales Deployment folgen dem allgemeinen Lifecycle-Vertrag.
Der Modulfehlerbereich ist `51090–51099`. SQL Server 2025 Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich; physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben offen.
