# toolbelt.conversion.integer-base

Kanonische Konvertierung des vollständigen `bigint`-Bereichs mit einem frei
definierbaren druckbaren ASCII-Alphabet.

Status: `implemented`, `not executed`, `unreleased`.

Öffentliche Objekte:

- `SVF_IntegerToBase` – codiert einen `bigint` als `varchar(65)`;
- `SVF_TryBaseToInteger` – decodiert eine kanonische Darstellung oder liefert
  `NULL`.

Die Basis ergibt sich aus der Alphabetlänge von 2 bis 93. Das erste Zeichen
steht für Null; `-` ist ausschließlich als Vorzeichen reserviert. Alphabet und
Ziffern werden binär geprüft, daher bleiben Groß- und Kleinschreibung
verschieden. Führende Nullzeichen, `+`, `-0`, Whitespace, unbekannte Zeichen
und Overflow werden abgelehnt.

Das Modul hat keine Abhängigkeit zu Base64 oder anderen Toolbelt-Modulen.
Zwischenarithmetik mit `decimal(38,0)` deckt auch
`-9223372036854775808` sicher ab.

Aktuelle Evidenz:
[Integer-Base Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/integer-base-runtime.yml)
ist `not executed`.

Siehe [Design](../../Documentation/Architecture/INTEGER_BASE_MODULE_DESIGN.md)
und [Testmatrix](./Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md).
