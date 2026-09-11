# Vorschlag: Grundlage für pseudonymisierte Testdaten (`TC-2026-039` bis `043`)

## Status und Sicherheitsgrenze

Die Kandidaten `TC-2026-039` bis `TC-2026-043` bleiben Research. Dieses
Dokument bereitet die spätere Funktionsbesprechung vor, autorisiert aber keine
Transformation, kein SQL-Objekt und keine Verarbeitung realer Daten.

Alle fünf Kandidaten erzeugen bestenfalls pseudonymisierte oder synthetische
Werte. Sie dürfen nie als Anonymisierung, Re-Identifikationsschutz oder
datenschutzrechtliche Eignungszusage bezeichnet werden. Ein deterministisches
Mapping erhält gerade die Verknüpfbarkeit gleicher Eingaben und kann damit
zusätzliche Risiken erzeugen.

## Empfohlene Reihenfolge

Eine erste Welle sollte ausschließlich aus zwei datentypneutralen Primitiven
bestehen:

1. **Kanonischer Schlüssel und deterministischer Range-Wert** aus
   `TC-2026-040`, ohne Secret-Speicherung und ohne Kryptografiebehauptung.
2. **Deterministischer Lookup** aus `TC-2026-039`, der eine bereits
   freigegebene, synthetische Lookup-Menge über diesen Wert auswählt.

Date Shifting (`TC-2026-042`) baut darauf auf und ist erst nach dem Range-
Vertrag sinnvoll. Zeichenübersetzung (`TC-2026-041`) und Geo-Jittering
(`TC-2026-043`) bleiben getrennt, weil sie Format-, Reversibilitäts-,
Unicode- beziehungsweise Raum-/Gebietsentscheidungen enthalten, die ein
allgemeines Primitive nicht sicher vorwegnehmen kann.

## Gemeinsamer V1-Vertrag

| Aspekt | Vorschlag |
|---|---|
| Zweck | Reproduzierbare Auswahl synthetischer Ersatzwerte für Tests; keine Aussage über Anonymisierung. |
| Schlüssel | Ein nicht leerer, binär kanonisierter Textschlüssel und eine explizite `MappingVersion`. Kein stiller Collation- oder Culture-Einfluss. |
| Seed und Secret | Ein öffentlicher Seed bestimmt nur eine Variante. Ein Secret ist kein Parameter von V1 und wird weder gespeichert noch geloggt. |
| SQL `NULL` | Ein SQL-`NULL`-Schlüssel ergibt SQL-`NULL`; `NULL` wird nicht in eine reguläre Ersatzwertklasse umgedeutet. |
| Range | Geschlossene, ganzzahlige Grenzen; ungültige Reihenfolge und Overflow erzeugen stabile Fehler. Der resultierende Wert liegt immer innerhalb der Grenzen. |
| Auswahl | Lookup-Zeilen brauchen eine stabile, explizite positive Ordnungsnummer ohne Lückenanforderung. Die Lookup-Version ist Teil der Eingabe. |
| Änderungen | Eine geänderte Lookup-Menge oder MappingVersion erzeugt eine neue Abbildung. Bestehende Mappings werden nicht als unverändert behauptet. |
| Logging | Kein Originalschlüssel, Ersatzwert, Seed oder Hash wird durch Funktionen, Tests oder Diagnoseausgaben protokolliert. |

Ein unkeyed Hash darf als deterministische Mischfunktion dienen, schützt jedoch
kleine oder bekannte Eingaberäume nicht vor Raten. Modulo auf Hashbytes ohne
Rejection-Sampling darf nicht verwendet werden, weil es Verteilungsbias
einführt. Der erste Vertrag soll deshalb die erwartete Gleichverteilung nicht
als Sicherheits- oder Privacy-Eigenschaft vermarkten.

## Grenzen späterer Slices

`TC-2026-042` muss Offsetgranularität (Entität, Gruppe oder Zeile),
Zeitzonen-/DST-Semantik, Datentypgrenzen und Intervallerhalt separat
entscheiden. `TC-2026-041` braucht eine explizite Entscheidung zu Alphabet,
Normalisierung, Case, Formatlecks und Reversibilität. `TC-2026-043` braucht
Geometrietyp, SRID, Distanzmodell, Verteilung, zulässige Gebiete und eine
Bewertung der verbleibenden Offenlegung. Keiner dieser Punkte wird durch den
Range- oder Lookup-Slice entschieden.

## Technologie und Prüfungen

Der begrenzte V1-Vertrag ist mit portablem T-SQL für SQL Server 2019, 2022 und
2025 auf Windows und Linux möglich. `HASHBYTES` ist dabei nur ein Primitive;
Algorithmus, Bytekodierung und Ergebnisinterpretation werden im konkreten
Funktionsvertrag fixiert. Ein externer oder CLR-Provider ist nicht Teil der
ersten Welle und benötigt bei späterem Bedarf eine eigene Secret-, Trust- und
Deploymentbesprechung.

Tests verwenden ausschließlich synthetische Werte. Sie prüfen stabile
Abbildung, `NULL`, binäre Schlüsselunterscheidung, Grenzwerte, negative
Bereiche, Overflow, Lookup-Lücken, Mapping- und Lookup-Versionwechsel sowie
Windows-/Linux-Runtime auf lokalen SQL_Server_Lab-Zielen. CUs werden nur bei
patchabhängigen Tests gezielt ausgewählt. Eine Testmatrix kann keine
Anonymisierungswirkung nachweisen.

## Entscheidungspunkt

Vor der ersten Implementierungswelle wird der V1-Schnitt bestätigt oder
geändert: T-SQL-Primitive für einen binär kanonischen Schlüssel,
deterministischen Range-Wert und versionierte Lookup-Auswahl, ohne
Secretspeicherung und ohne Anonymisierungsbehauptung. Danach werden Signatur,
Hash-/Bytekodierung, Grenzwerte, Fehlerbereich und synthetische Testvektoren
als konkrete Funktionsverträge besprochen und freigegeben.

## Quellen

- [Microsoft: HASHBYTES](https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17)
- [Microsoft: CRYPT_GEN_RANDOM](https://learn.microsoft.com/en-us/sql/t-sql/functions/crypt-gen-random-transact-sql?view=sql-server-ver17)
- [bestehende Candidates](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-039-deterministischer-hash-lookup-fur-synthetische-ersatzwerte)
