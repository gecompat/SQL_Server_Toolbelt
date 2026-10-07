# Testevidenz

Die Runtime-Suite deckt den lokalen Vertrag, Idempotenz, Context-Auflösung,
Transaktionsschutz, Parallelität, Lifecycle und Central Deployment ab. Die
physische SQL_Server_Lab-Matrix ist für SQL Server 2019, 2022 und 2025 unter
Linux und Windows erfolgreich; das Modul ist `validated`.

## Befüllter versionsgleicher Repeat

[RepeatCurrent.Contract.sql](Runtime/RepeatCurrent.Contract.sql) ergänzt die
historische Lifecycle-Suite um zwei echte Deploys des installierten 1.0.0.
Vier synthetische Cancellation-Zeilen enthalten feste UTC-Auditwerte mit
100-ns-Anteilen, synthetische anfordernde Identitäten sowie NULL-, Leerstring-,
Unicode- und Trailing-Space-Gründe. Zwischen Baseline und beiden Deploys
findet keine DML an der persistenten Tabelle statt.

Das gemeinsame [Capture](Runtime/RepeatCurrent.Capture.sql) erfasst alle fünf
Spalten einschließlich der exakten Rowversionbytes. Der
[Assert](Runtime/RepeatCurrent.Assert.sql) vergleicht Zeilen und ausgewählte
Katalogmetadaten in beide Richtungen: vier Modulobjekte und ihre IDs,
Tabellenform, PK, Default, Indizes, vorhandene Constraints/FKs/Trigger,
Schemaowner, Modulmarker, vorhandene Permissions und Tabellen-/Spaltenannotation.
Nichtleere synthetische `MS_Description`-Werte an Tabelle und Reason-Spalte
müssen erhalten bleiben; dieser Installer erneuert sie nicht kanonisch.
Veränderliche DDL-Zeitstempel sind kein Orakel. Vorhandene Permissions werden
nur gelesen; die Fixture erzeugt keine Benutzergrants. Eine leere Grantmenge
ist kein Nachweis für nichtleere Benutzergrants oder tatsächliche Minimalrechte.

Der Aufruf erfolgt in einer eigenen leeren Installationsdatenbank und einer
frischen Session aus `Deployment/`, jeweils mit `DeploymentMode=local` oder
`central`. Nach beiden Repeats werden die Status-TVF und SVF read-only geprüft,
die vier eigenen Zeilen und Annotationen einschließlich eigener Beschreibungen
entfernt und der erfolgreiche
Abschluss mit einem festen Marker bestätigt. Ein Fehler bricht SQLCMD ab;
der aufrufende Adapter muss dann die eigene Testdatenbank beziehungsweise
seinen eigenen flüchtigen Testscope bereinigen. Eine Wiederaufnahme auf
teilweise verbliebener Fixture ist ausgeschlossen.

Der neue Repeat-Scope bestand am Commit
`fac18e590f854a26364e5f498c6a2b5d330a95c2` lokal/zentral auf Linux2019/150,
2022/160 und 2025/170. Historische Windows-/Linux-Evidenz oben ersetzt keine
weitere Repeat-Qualifikation. Neue Windows-, weitere Compatibility-Level-,
nichtleere Benutzergrant-, Minimalrechte- und historische Migrationsprüfungen
bleiben `not executed`; konkrete Evidenz steht nachfolgend getrennt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199`
- Scope: Commit fac18e590f854a26364e5f498c6a2b5d330a95c2: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf SQL Server 2019/150, 2022/160, 2025/170 Linux; alle fünf Spalten mit Rowversionbytes, synthetische Audit-/NULL-/Textwerte, ausgewählter Katalog und eigene typisierte Annotationen inklusive MS_Description erhalten. Vorhandene API-, Concurrency-, Consumer- und Uninstallfälle sowie eigene CI-Bereinigung bestanden. Keine neuen Windows-Repeats, weiteren Repeat-CLs, nichtleeren Benutzergrants, echten Minimalrechte oder historischen Schemaübergänge qualifiziert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
