# Vorschlag: Deterministisches Date Shifting (`TC-2026-042`)

## Status

`TC-2026-042` bleibt Research. Dieses Dokument baut auf der vorbereiteten
deterministischen Range-Grundlage auf und autorisiert keine Transformation,
kein SQL-Objekt und keine Verarbeitung realer Daten.

## Empfohlener V1-Schnitt

V1 verschiebt einen `datetime2`-Wert um eine ganzzahlige Anzahl Kalendertage,
die für denselben binär kanonischen Entitätsschlüssel und dieselbe
MappingVersion stabil aus einem symmetrischen Bereich abgeleitet wird. Alle
Zeitpunkte einer Entität erhalten damit exakt denselben Offset und behalten
ihre zeitlichen Abstände.

`date`, `datetime`, `smalldatetime`, `datetimeoffset`, Zeitzonen, DST-
Umrechnung, Monats-/Jahresoffsets, Zeilen-spezifische Offsets und
Intervallerhaltung über mehrere Entitäten sind getrennte Slices. Diese
Begrenzung verhindert stillschweigende Precision-, Offset- oder
Zeitzonenänderungen.

## Vertragsvorschlag

| Aspekt | Vorschlag |
|---|---|
| Eingabe | `datetime2`, nicht leerer Entitätsschlüssel, MappingVersion und nichtnegative maximale Anzahl Tage. |
| SQL `NULL` | SQL-`NULL` im Zeitwert oder Schlüssel ergibt SQL-`NULL`; eine `NULL`-MappingVersion oder `NULL`-Grenze ist Fehler. |
| Offset | Inklusiv aus `[-MaxDays, +MaxDays]` und deterministisch aus Schlüssel plus MappingVersion abgeleitet. |
| Identität | `MaxDays = 0` ergibt den unveränderten Zeitpunkt. |
| Präzision | Der `datetime2`-Wert bleibt in seiner vorhandenen Zeitskala erhalten; nur der Kalendertag wird verschoben. |
| Overflow | Ein Wert außerhalb des `datetime2`-Bereichs erzeugt einen stabilen Fehler, niemals Clamp oder Wraparound. |
| Security | Kein Seed, Secret, Schlüssel, Offset oder Originalwert wird protokolliert oder als Anonymisierung ausgegeben. |

Der Offset ist kein kryptografischer Schutz und verhindert keine Rückschlüsse
aus bekannten Ereignissen oder kombinierten Attributen. Ein Date Shift bleibt
pseudonymisierend beziehungsweise testdatenorientiert und darf nicht als
Anonymisierungsgarantie bezeichnet werden.

## Technologie und Tests

Die V1-Funktion kann nach Freigabe mit portablem T-SQL umgesetzt werden,
sobald der Range-Vertrag existiert. Sie benötigt keine Zeitzonendaten oder
externen Provider. Tests verwenden ausschließlich synthetische Schlüssel und
Zeitwerte und prüfen Stabilität, verschiedene MappingVersionen, Grenzwerte,
`NULL`, negative/positive Offsets, Schaltjahre, Präzision, Overflow,
Intervallerhalt, Wiederholungsdeployment, Lifecycle sowie die lokalen
SQL_Server_Lab-Ziele für 2019, 2022 und 2025 auf Windows und Linux.

## Entscheidungspunkt

Vor einer Implementierungsfreigabe wird der V1-Schnitt bestätigt oder
geändert: `datetime2`, pro Entität konstanter Tagesoffset, symmetrischer
Bereich und keine Zeitzonensemantik. Danach werden Signatur, maximaler
Tagebereich, Fehlerbereich, Abhängigkeit zum Range-Primitive und synthetische
Testvektoren als konkrete Funktion besprochen und freigegeben.

## Quellen

- [Microsoft: DATEADD](https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver17)
- [Pseudonymisierungsgrundlage](./PSEUDONYMIZATION_FOUNDATION_PROPOSAL.md)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-042-deterministisches-date-shifting)
