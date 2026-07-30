# Test- und Validierungsrichtlinie

## Grundsatz

Plan, Dokumentation, Manifest und vorhandener Testcode sind kein Runtime-Nachweis. Nur tatsächlich ausgeführte und erfolgreiche Prüfungen dürfen als `validated` oder bestanden bezeichnet werden.

## Validierungsstatus

Der `validation_status` ist von Implementierungs- und Release-Status getrennt.

| Wert | Bedeutung |
|---|---|
| `validated` | tatsächlich ausgeführt und erfolgreich |
| `partially validated` | dokumentierter Teil des Pflichtscopes erfolgreich; weitere Pflichtkombinationen offen |
| `not executed` | vorgesehen, aber nicht ausgeführt |
| `not applicable` | im konkreten Scope fachlich nicht anwendbar und begründet |
| `failed` | ausgeführt und fehlgeschlagen; Blocker dokumentiert |

## Evidenz für ausgeführte Prüfungen

Mindestens dokumentieren:

- Befehl, Tool oder Workflow;
- geprüften Scope;
- SQL-Server-Version, Plattform und Provider;
- Ergebnis;
- Ausführungsdatum;
- bekannte Einschränkungen.

Ein agenteninterner Review ohne reproduzierbare Ausgabe ist kein CI- oder Runtime-Nachweis.

## API- und Contract-Tests

Für alle öffentlichen Objekte:

- Name, Schema, Typ und Sichtbarkeit;
- Parameter, Datentypen, Reihenfolge und Defaults;
- Resultset-Spalten, Datentypen, Nullability und Collation;
- Fehler- und Berechtigungsvertrag;
- Beispiele gegen den tatsächlichen Vertrag.

Für USPs zusätzlich:

- `@Hilfe = 1` einschließlich Help-Resultset;
- `@Debug` ausschließlich als Messages;
- `@ResultTable IS NULL` mit genau einem fachlichen Resultset;
- `@ResultTable` ohne fachliches `SELECT`;
- beliebiger Dummyspaltenname und -typ;
- alle vier `@KeepData`-Konstellationen;
- passendes Schema mit zusätzlichen Indizes;
- blockierende Dependencies vor der ersten Mutation;
- verschachtelte Aufrufe ohne generisches `INSERT ... EXEC`;
- kein Seiteneffekt im Help-Modus.

## Lifecycle-Tests

- Erstinstallation auf sauberem Zustand;
- kontrollierte Wiederholung beziehungsweise Idempotenz;
- Upgrade von jeder unterstützten Vorgängerversion;
- Uninstall und Dependency-Schutz;
- fehlerhafter Preflight ohne Teilmutation;
- Recovery und Cleanup nach begonnenem Setup.

## Versions- und Plattformmatrix

Jede tatsächlich unterstützte Kombination wird separat bewertet:

- SQL Server 2019, 2022 und 2025;
- Windows und Linux;
- lokale und zentrale Installation;
- jeder alternative Provider;
- Cross-database-Aufruf, wenn unterstützt.

Ein erfolgreicher Test auf einer Version, Plattform oder einem Provider beweist keine andere Kombination. `not applicable` setzt eine dokumentierte Capability-Entscheidung voraus.

## Collation- und Datentests

- abweichende Server-, Toolbelt-, Zieldatenbank- und TempDB-Collations;
- mindestens case-insensitive, case-sensitive und BIN2; UTF-8, soweit fachlich relevant;
- deterministische synthetische Daten;
- Randwerte, Fehlerwerte und leere Eingaben;
- keine Produktionsdaten.

## Performance-Messungen

- vergleichbare Abfrage, Parameter, Daten- und Cache-Zustände;
- Messumgebung und Datenmenge dokumentieren;
- Warm-up-, Parallelitäts- und Hardwareeffekte nennen;
- Einzellauf nicht als allgemeingültigen Benchmark darstellen;
- Ergebnisse als empirisch kennzeichnen.

## CI

CI bleibt schlank und pfadbezogen. Der Dokumentationsvalidator bestimmt seinen
Scope aus dem Git-Diff, der Modulregistry und den expliziten Impact-Paketen.
Dokumentationsänderungen lösen keine unnötige Runtime-Vollmatrix aus. Ein
vollständiger Audit läuft nur bei Governance- oder Kopplungsänderungen, vor
einem Release, beim manuellen Aufruf oder auf ausdrücklichen Auftrag. Teure
oder spezielle Plattformtests dürfen manuell oder capability-spezifisch
ausgeführt werden; fehlende Runner ergeben keinen grünen Nachweis.

## Aktueller Stand

`toolbelt.core.result-table` hat `implementation_status: implemented`,
`validation_status: partially validated` und `release_status: unreleased`. Die
GitHub-hosted Linux-Läufe vom 2026-07-29 sind für SQL Server 2019, 2022 und
2025 erfolgreich; Windows und die noch nicht automatisierten Matrixfälle
bleiben `not executed`.

`toolbelt.conversion.base64` hat `implementation_status: implemented`,
`validation_status: partially validated` und `release_status: unreleased`. SQL
Server 2025 unter Linux ist mit Compatibility Levels 150, 160 und 170
einschließlich RFC-4648-, Fehler-, Größen-, Deployment- und
Lifecycle-Contracts erfolgreich. Physische SQL-Server-2019-/2022- und
Windows-Läufe bleiben `not executed`.

`toolbelt.core.generate-series` hat `implementation_status: implemented`,
`validation_status: partially validated` und `release_status: unreleased`.
SQL Server 2025 unter Linux ist mit Compatibility Levels 150, 160 und 170
einschließlich Semantik, Grenzen, Größe, Join, `CROSS APPLY`, Deployment und
Lifecycle erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe
bleiben `not executed`.

`toolbelt.metadata.identifier` hat `implementation_status: implemented`,
`validation_status: not executed` und `release_status: unreleased`. Statische,
Runtime- und Lifecycle-Contract-Artefakte sind vorhanden; eine tatsächliche
SQL-Server-Ausführung steht aus.
