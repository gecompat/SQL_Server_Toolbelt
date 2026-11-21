# TVF_DoubleMetaphone

Öffentliche inline TVF in toolbelt_string, Modul 1.0.0 unreleased.

@Text nvarchar(max) ohne Default; PrimaryCode und AlternateCode sind varchar(max) NULL mit
Latin1_General_100_BIN2, gefolgt von ErrorCode int logisch nicht NULL. Die
physische CLR-Metadaten-Nullbarkeit ist kein NOT-NULL-Versprechen. Genau eine
vollständig berechnete Zeile. Interne CLR-Codefelder sind nvarchar(max);
die IF-Fassade konvertiert validierte ASCII-Codes explizit nach varchar(max)
unter derselben BIN2-Collation. NULL, max-Länge und terminale Leerzeichen bleiben erhalten.

ASCII U+0000..007F sowie Ç/ç und Ñ/ñ. Java-Trim entfernt nur U+0000..0020 an den Rändern; ASCII und ç/ñ werden fest großgeschrieben.

NULL: NULL-Codes/0. Leer: leere Codes/0. Voller Scanner; keine Kürzung. Bei
Double Metaphone bleiben beide Codes auch bei Gleichheit erhalten und ein
terminales alternatives J-Leerzeichen bleibt unverändert.

Priorität: NULL, rohe Quote 4096 (2), vollständige UTF16-Prüfung (1), Alphabet
(3), Transformations-/Outputquote (2), Erfolg (0). Gültige Supplementary-Zeichen
sind nicht im Alphabet (3); isolierte Surrogate sind Fehler 1. Fehlercodes 1..3
liefern ausschließlich NULL-Codes; technische Fehler bleiben Exceptions.

[Vertrag](../../../Documentation/Architecture/PHONETIC_CONTRACT.md),
[Modul](../README.md), [Matrix](../Tests/PHONETIC_TEST_MATRIX.md).
Begrenzte Build-/Runtime-/Clientnachweise liegen vor; Minimalrechte, vollständige
Qualifikation und aktuelle Head-CI bleiben offen. Siehe [Testevidenz](../Tests/README.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Unicode-Rohtext mit höchstens 4096 UTF-16-Codeunits vor jeder eigenen Textkopie. NULL liefert NULL-Code(s) und ErrorCode=0, leerer Text ist gültig und liefert leere Codes. Ungültige Surrogatfolge ergibt Code 1, Größenquote Code 2, Zeichen außerhalb des geschlossenen Alphabets Code 3. Ein gültiges Supplementary-Paar bleibt dennoch außerhalb dieses Alphabets und ergibt Code 3. Zusätzlich zu ASCII U+0000..U+007F ausschließlich ÇçÑñ. ASCII a..z wird zu A..Z, ç/ñ zu Ç/Ñ. Vor dem Scanner werden äußere ASCII-Codeunits &lt;=U+0020 entfernt; innere Kontroll-/Satzzeichen bleiben im Kontext. Keine allgemeine Culture- oder Unicode-Normalisierung. Kein SQL-Default; Argument ausdrücklich übergeben. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'Contoso');
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#phonetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DoubleMetaphone.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
