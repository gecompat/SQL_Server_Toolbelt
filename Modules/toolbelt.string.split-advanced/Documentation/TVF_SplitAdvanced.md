# TVF_SplitAdvanced

Öffentlicher S2-Vertrag, Implementierungsfreigabe vom 2026-10-01. Reine T-SQL-Multi-statement-TVF auf SQL Server 2019/2022/2025 unter Windows/Linux; Compatibility Level mindestens 150.

## Aufruf und Resultset

`toolbelt_string.TVF_SplitAdvanced(@Input nvarchar(max), @SeparatorsJson nvarchar(max), @Quote nvarchar(max)=N'"', @Escape nvarchar(max)=N'\', @KeepEmpty bit=1)`.

| Feld | Typ | Bedeutung |
|---|---|---|
| Value | nvarchar(max), NULL | unverändertes Originaltoken; NULL bei Fehler |
| Ordinal | bigint, NULL | nach Leerfilter lückenlos ab 1; NULL bei Fehler |
| IsValid | bit, NOT NULL | 1 Erfolg, 0 Geschäftsfehler |
| ErrorCode | varchar(64), NULL | stabiler symbolischer Fehlercode |
| ErrorPosition | bigint, NULL | ursprüngliche UTF-16-Position ab 1 bei Inputfehlern |

Reihenfolge nur mit `ORDER BY Ordinal`. Erfolgszeilen enthalten NULL-Fehlerfelder. Bei Geschäftsfehlern kommt genau eine Fehlerzeile und niemals ein Teilresultat. Echte Enginefehler bleiben Enginefehler.

## Semantik und Grenzen

NULL-Input ist frühzeitiger No-op ohne Konfigurationsprüfung. KeepEmpty NULL entspricht 1. Leerer Input liefert bei KeepEmpty=1 ein leeres Token, sonst keine Zeilen. Originaltext einschließlich Spaces, Quotes und Escapes bleibt erhalten; Unquoting und CSV-Normkonformität sind nicht enthalten.

JSON muss ein nichtleeres Array eindeutiger, nichtleerer Strings sein. Vergleiche erfolgen mit Latin1_General_100_BIN2; nachfolgende Spaces sind signifikant. Außerhalb von Quotes gewinnt am aktuellen Cursor der längste Separator. Quotes öffnen/schließen überall im Text; keine Verschachtelung. Escape schützt überall genau die nächste UTF-16-Codeeinheit und bleibt erhalten. Vor einem Supplementary-Paar wird nur dessen erste Codeeinheit übersprungen; die zweite wird im folgenden Schritt verarbeitet. Keine Scalar-/Graphemzusage.

Quote/Escape: leere Strings deaktivieren unabhängig; NULL ist ungültig. Aktive Werte bestehen aus genau einer Nicht-Surrogate-Codeeinheit, sind verschieden und dürfen nicht in Separatoren vorkommen. NUL ist in Konfiguration und Input unzulässig.

Ressourcenlimits, mit DATALENGTH/2 einschließlich trailing Spaces gemessen: Input 65536, JSON-Rohtext 16384 Codeeinheiten; höchstens 16 Separatoren mit je höchstens 64 Codeeinheiten. Dies sind Schutzgrenzen, keine Durchsatzgarantie.

## Fehlerpriorität

1. NULL-Input No-op; fehlende JSON-/Quote-/Escape-Konfiguration.
2. Inputlimit, JSONlimit, Quote-/Escapelänge.
3. JSON-Syntax/root Array, Anzahl.
4. Pro Separator in Arrayreihenfolge: Typ, leer, Länge, NUL, Duplikat.
5. Steuerzeichen-NUL, Surrogate, identische aktive Zeichen; anschließend Konflikte mit Separatoren.
6. Erstes Input-NUL vor dem Parser; dann erster Scanfehler. Terminaler Escape gewinnt vor der beim EOF offenen Quote.

| Code | Fälle | Position |
|---|---|---|
| INVALID_CONFIGURATION | fehlende Konfiguration, Steuerzeichenfehler/-konflikt, Nichtstring, leeres Array | NULL |
| INPUT_LIMIT_EXCEEDED | Input zu groß | NULL |
| JSON_LIMIT_EXCEEDED | JSON-Rohtext zu groß | NULL |
| INVALID_SEPARATOR_JSON | Syntax oder kein Array | NULL |
| SEPARATOR_LIMIT_EXCEEDED | Anzahl oder Separatorlänge | NULL |
| EMPTY_SEPARATOR | leerer Separator | NULL |
| DUPLICATE_SEPARATOR | bytegleiches Duplikat | NULL |
| NUL_NOT_ALLOWED | NUL | Inputposition, sonst NULL |
| DANGLING_ESCAPE | letzter Inputwert ist aktiver Escape | dessen Position |
| UNTERMINATED_QUOTE | beim EOF offene Quote | Position ihrer öffnenden Quote |

## Verwendung

```sql
SELECT Value, Ordinal
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d', N'[";"]', DEFAULT, DEFAULT, DEFAULT)
WHERE IsValid = 1
ORDER BY Ordinal;
```

Fehler bewusst vor fachlicher Verwendung prüfen; alleiniges Filtern auf IsValid=1 würde sie verwerfen. Bei APPLY muss der Verbraucher Fehler je Eingabe berücksichtigen.

SELECT auf der TVF genügt innerhalb des Installationskontexts. Zentraler
Cross-DB-Aufruf erfordert zusätzlich eine administrativ gültige
Authentifizierung und passende User-/SELECT-Rechte in der Ziel-Datenbank;
die Funktion aktiviert weder TRUSTWORTHY noch Ownership-Chaining und
erteilt selbst keine Rechte.

Siehe [Modul](../README.md), [Design](../../../Documentation/Architecture/SPLIT_ADVANCED_MODULE_DESIGN.md) und [Testmatrix](../Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md).
