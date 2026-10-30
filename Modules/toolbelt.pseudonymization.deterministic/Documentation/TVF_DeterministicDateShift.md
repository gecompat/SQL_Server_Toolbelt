# toolbelt_pseudonymization.TVF_DeterministicDateShift

Typ: echte Inline Table-valued Function. Individuell freigegeben am
2026-10-01 gemäß Reservewelle in `.ai/BACKLOG.md`. Implementiert;
tatsächlich ausgeführter und noch offener Scope: [Testnachweise](../Tests/README.md).

```sql
toolbelt_pseudonymization.TVF_DeterministicDateShift
    (@Value datetime2(7), @Key varbinary(max), @MappingVersion int,
     @Seed bigint = 0, @MaxDays int = 365)
```

Genau eine Zeile: `Value datetime2(7) NULL`, `ErrorCode int NOT NULL`.
Der Key und MappingVersion/Seed entsprechen exakt dem Range-Vertrag.
MaxDays ist nicht-NULL im Bereich 0..3652058. Der kanonische Range-Kern
wählt einen ganzzahligen Offset im geschlossenen Bereich
`[-MaxDays,+MaxDays]`; Domain und Kontext entsprechen der Range-Fassade.
Keine zweite Hash- oder Offsetberechnung. Gleicher Entity-Key und gleiche
Parameter ergeben bei allen Eingabedaten denselben Offset, sofern die
Datentypgrenzen den Shift zulassen. Uhrzeit und sieben Nachkommastellen
bleiben erhalten; dadurch bleiben Intervalle gleicher Entities erhalten.
MaxDays 0 ist Identity. Kein Offset wird als zusätzliche Spalte ausgegeben.

Fehlerpriorität, jeweils Value NULL: SQL-NULL-Value oder -Key zuerst
Erfolgscode 0; MappingVersion ungültig 1; Seed NULL 2; MaxDays ungültig 7;
Key ungültig 4; Sampling erschöpft 5; Datum außerhalb datetime2 8; sonst 0.
Date-Overflow wird vor DATEADD geprüft; der tatsächlich ausgewertete
DATEADD-Operand ist auch bei vorgezogener Optimizer-Auswertung geschützt.
Kein Clamping, Wrap oder stiller Fallback. Keine Zeitzonen-/DST-/Culture-
Konvertierung, keine Anonymisierungs- oder Re-Identifikationsschutz-Zusage.

```sql
SELECT Value, ErrorCode
FROM toolbelt_pseudonymization.TVF_DeterministicDateShift
    (CONVERT(datetime2(7), '2026-01-02T03:04:05.1234567'), 0x010203, 1, DEFAULT, DEFAULT);
```

SELECT auf der öffentlichen TVF; lokal und zentral vorgesehen ohne
Synonyme, I/O, Assembly oder Rechteausweitung. Metadaten, Minimalrechte,
Overflow/Underflow, Intervallerhalt, NULL-Priorität und Defaults werden
durch synthetische SQL-Oracles geprüft. Weitere Plattform-, Kapazitäts-
und Optimizer-Nachweise dürfen daraus nicht abgeleitet werden.

Primärquelle: [Microsoft DATEADD](https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver17).

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | `kein Default` | Input | datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@MaxDays` | `int` | `365` | Input | Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#deterministische-zuordnung).
