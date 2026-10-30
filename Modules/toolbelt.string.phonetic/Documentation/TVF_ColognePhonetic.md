# TVF_ColognePhonetic

Öffentliche inline TVF in toolbelt_string, Modul 1.0.0 unreleased.

@Text nvarchar(max) ohne Default; PhoneticCode sind varchar(max) NULL mit
Latin1_General_100_BIN2, gefolgt von ErrorCode int logisch nicht NULL. Die
physische CLR-Metadaten-Nullbarkeit ist kein NOT-NULL-Versprechen. Genau eine
vollständig berechnete Zeile. Interne CLR-Codefelder sind nvarchar(max);
die IF-Fassade konvertiert validierte ASCII-Codes explizit nach varchar(max)
unter derselben BIN2-Collation. NULL, max-Länge und terminale Leerzeichen bleiben erhalten.

ASCII U+0000..007F sowie Ä/Ö/Ü/ä/ö/ü/ß. Feste Großschreibung, Umlautersetzung A/O/U und ß→SS; kein Trim und kein optionales Akzent-Folding.

NULL: NULL-Code/0. Leer: leerer Code/0. Voller Scanner; keine Kürzung.

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
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Rohtext mit höchstens 4096 UTF-16-Einheiten; gültige Surrogatpaare werden geprüft, ein nicht unterstützter Skalar wird nicht still entfernt. ASCII-Zeichen sind zulässig. NULL ergibt NULL-Code(s)/ErrorCode 0; leer ist gültig. Längen-/Arbeitsgrenze ergibt Code 2, ungepaarte Surrogate Code 1 und nicht unterstützte Zeichen Code 3. Keine frei wählbare Sprache/Transliteration. Zusätzlich zu ASCII sind ÄÖÜäöüß erlaubt; Umlaute werden A/O/U und ß wird SS. Kein allgemeiner Unicode-Phonetikdienst. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#phonetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_ColognePhonetic.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
