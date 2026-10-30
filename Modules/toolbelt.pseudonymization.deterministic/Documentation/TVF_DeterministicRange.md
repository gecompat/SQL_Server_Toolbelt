# toolbelt_pseudonymization.TVF_DeterministicRange

Typ: echte Inline Table-valued Function. Status: implementiert,
im ausgewählten Linux2019-Local-/Central-Scope geprüft. Individuelle Freigabe:
erster Reservewellen-Abschnitt in `.ai/BACKLOG.md` vom 2026-10-01.

## Zweck und Signatur

Reproduzierbarer Ersatzwert für synthetische Testdaten, keine Anonymisierung,
keine Eindeutigkeit, kein Re-Identifikationsschutz und keine kryptografische
Eignungszusage. Der öffentliche Seed ist kein Secret.

```sql
toolbelt_pseudonymization.TVF_DeterministicRange
    (@Key varbinary(max), @MappingVersion int, @Seed bigint = 0,
     @Min bigint, @Max bigint)
```

`@Key` enthält vom Caller kanonisierte Bytes; keine Textnormalisierung,
Case-/Collation-/Culture-Behandlung. Nicht-NULL: 1 bis 8000 Byte.
`@MappingVersion` ist eine positive int-Kontextversion (nicht nur Version 1).
`@Seed` ist jeder nicht-NULL bigint; `DEFAULT` verwendet 0. Die Grenzen sind
nicht-NULL, geschlossen und geordnet. Auch der vollständige bigint-Bereich
ist zulässig. Gleiche Eingaben ergeben gleiche Werte; geänderte Eingaben
dürfen denselben Wert ergeben.

Genau eine Zeile: `Value bigint NULL`, `ErrorCode int NOT NULL`. Kein Help,
Debug, ResultTable, THROW, persistenter Zustand oder Logging.

## Fehlerpriorität

Erste zutreffende Bedingung gewinnt; kein Teilwert bei Fehlern:

| Reihenfolge | Bedingung | ErrorCode | Value |
|---:|---|---:|---|
| 1 | Key ist SQL NULL (auch bei ungültiger Konfiguration) | 0 | NULL |
| 2 | MappingVersion NULL oder <= 0 | 1 | NULL |
| 3 | Seed NULL | 2 | NULL |
| 4 | Min/Max NULL oder Min > Max | 3 | NULL |
| 5 | Key leer oder länger als 8000 Byte | 4 | NULL |
| 6 | Alle 128 Kandidaten verworfen | 5 | NULL |
| 7 | Erfolg | 0 | Bereichswert |

Interner Code 6 bezeichnet einen ungültigen Domain-/Kontextaufruf; die
öffentliche Fassade übergibt ausschließlich feste gültige interne Werte.

## Unveränderliches Byteformat V1

Alle Zahlen sind big-endian, feste Breite; vorzeichenbehaftete Eingaben
werden als Zweierkomplement kodiert. Kein SQL-Text oder Separator wird
gehasht. Der Frame ist die Verkettung folgender Felder:

| Feld | Byteanzahl | Range-Inhalt |
|---|---:|---|
| Domain/Format | 8 | ASCII `TBXDRNG1` = `54425844524E4731` |
| Kontext | 8 | bigint 0 |
| MappingVersion | 4 | int |
| Seed | 8 | bigint |
| Min | 8 | bigint |
| Max | 8 | bigint |
| Key-Länge | 4 | nichtnegative Byteanzahl |
| Key | variabel | exakte Key-Bytes |
| Versuch | 4 | 0 bis 127 |

Domain und feste Kontextposition erlauben Lookup-Versionen im selben
internen Kern ohne den 8000-Byte-Key zu verkürzen oder vorzuhashen. Der
interne Kern ist kein zusätzlicher öffentlicher Funktionsvertrag.

`SHA2_256` hasht den gesamten Frame. Die ersten acht Digestbytes werden
big-endian als unsigned 64-bit-Kandidat gelesen. Mit exakter decimal(38,0)-
Arithmetik gilt `U = 18446744073709551616`, `Span = Max - Min + 1` und
`Limit = U - (U % Span)`. Der erste Kandidat `< Limit` ergibt
`Min + (Kandidat % Span)`. Alle anderen Kandidaten werden verworfen.
Keine gerundete Division, keine Modulo-Bias-Auswahl, maximal 128 Versuche.
Für volle bigint-Grenzen ist Span genau U; kein Kandidat wird verworfen.
128 Fehlversuche ergeben ausdrücklich Fehler 5, keinen Fallback.

Operandenschutz verhindert selbst bei vorgezogener Optimizer-Auswertung
Division durch NULL/0 oder einen ungültigen bigint-Cast. Eine limitierte
synthetische Referenzprüfung ist kein Nachweis für Planqualität oder SQL-
Laufzeit; SQL-Binärkodierung/Metadaten müssen separat empirisch stimmen.

## Verwendung und Rechte

```sql
SELECT Value, ErrorCode
FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203, 1, DEFAULT, -10, 10);
```

SELECT auf der öffentlichen Inline-TVF. Internes Objekt wird nicht als
öffentliche API beworben. Lokaler und dreiteiliger zentraler Aufruf sind
vorgesehen; keine Synonyme, Assembly, Privilegienausweitung oder I/O.
Windows/Linux2019/2022/2025 sind Zielscope; nur tatsächlich ausgeführte
Kombinationen gelten als belegt, siehe [Testnachweise](../Tests/README.md).

## Prüfungen und Einschränkungen

Unabhängig kodierte synthetische Hashvektoren, SQL-Laufzeit, SELECT-Metadaten,
direkte Minimalrechte, APPLY, lokale CS-/zentrale BIN2-Collation sowie
Lifecycle/Deployment sind auf SQL2019 Linux geprüft. Breitere Optimizer-,
Produktionskapazitäts-, CrossDB-Minimalrechte- und Plattformnachweise bleiben
offen. Die erzwungene128-Reject-Exhaustion ist nur in der Referenz geprüft,
kein tatsächlicher SQL-Live-Exhaustion-Nachweis.
Die MappingVersion darf nicht als Version einer geheimen oder historischen
Lookup-Menge missverstanden werden. Kein persistiertes Mapping wird überwacht.

Primärquellen: [Microsoft HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17),
[Microsoft binary und varbinary](https://learn.microsoft.com/en-us/sql/t-sql/data-types/binary-and-varbinary-transact-sql?view=sql-server-ver17),
[Microsoft decimal](https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17).

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@Min` | `bigint` | `kein Default` | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und &lt;=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
| `@Max` | `bigint` | `kein Default` | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und &gt;=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#deterministische-zuordnung).
