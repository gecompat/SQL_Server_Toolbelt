# toolbelt.conversion.integer-base

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

Kanonische Konvertierung des vollständigen `bigint`-Bereichs mit einem frei
definierbaren druckbaren ASCII-Alphabet.

Status: `implemented`, `partially validated`, `unreleased`.

Öffentliche Objekte:

- `TVF_IntegerToBase` – kanonischer relationaler Encode-Kern;
- `TVF_TryBaseToInteger` – kanonischer relationaler Decode-Kern;
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

Modulversion `1.1.0` ergänzt die inline-TVF-APIs. Die vorhandenen SVFs
delegieren an diese Kerne. Für mengenorientierte Aufrufe sind die TVFs mit
`CROSS APPLY` oder `OUTER APPLY` zu bevorzugen. Die SVF-Wrapper sind bewusst
nicht schemagebunden, damit Wiederholungs- und Upgrade-Deployments die
kanonischen TVF-Kerne ersetzen können.

Aktuelle Evidenz:
[Integer-Base Runtime Run 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Der vollständige Adapter ist am 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Windows-Läufe
bleiben offen.

Siehe [Design](../../Documentation/Architecture/INTEGER_BASE_MODULE_DESIGN.md)
und [Testmatrix](./Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md).
