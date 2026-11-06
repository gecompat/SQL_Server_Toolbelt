# Testevidenz

## Windows-Repeat vom 2026-11-06: elf abgegrenzte Kontexte

Der unveränderte bisherige `RepeatCurrent` bestand am Produkt-/Fixturestand
`4ed7aad3` auf Windows SQL2019/CU32 zentral bei CL150, SQL2022/CU26 lokal und
zentral bei CL150/160 sowie SQL2025/CU8 lokal und zentral bei CL150/160/170.
Das sind elf erfolgreiche Kontexte mit je zwei echten Deploys, insgesamt
22 Wiederholungen, und fünf erfolgreiche Gesamtkoordinatoren mit separaten
frischen Audits. Alle eigenen Datenbanken sind entfernt; fremde Konfiguration,
Trusts, Principals, Permissions und CLR-Verbraucher blieben unverändert.

Windows2019/CL150 lokal bleibt fehlgeschlagen: Der zusätzliche private
Cleanup-/Transaktionsguard verwarf den ersten Lauf mit54980/3. Die eigene DB
wurde regulär entfernt, der frische Audit bestätigte Abwesenheit und
unveränderte fremde Zustände. Einzelwerte des damaligen kombinierten
Prädikats wurden nicht erfasst; daraus wird keine nachträgliche Rootcause oder
ein bestandener Gesamtfall abgeleitet. Es gab keine Wiederholung dieses Falls.
Die Welle ist mit15 Ziel-/Auditaufrufen und sechs eigenen DBs geschlossen.

Eine lesende Gegenprobe im ohnehin vorgesehenen späteren Vorcheck zeigte
auf SQL2022 und SQL2025 einen abweisenden kombinierten Ausdruck trotz
neutraler Transaktionswerte außerhalb der Tabellenabfrage. Der korrigierte
private Adapter prüft Transaktionszustand und Tabelleninhalt in getrennten
Statements, behält beide verlangten Zustände und sämtliche ursprünglichen
Ownership-/Consumer-Gates bei. Nur zuvor unbegonnene Matrixfälle wurden
innerhalb derselben unveränderten Obergrenzen fortgesetzt; der Erstfehler
bleibt fehlgeschlagen. Originalquellen und Journale bleiben privat erhalten.

Diese Windows-Abnahme prüfte fünf historische Nutzdatenspalten und den
ausgewählten Katalog. Sie belegt nicht die Datenwerte der drei später
ergänzten Principalspalten. Deren neuer Nachweis folgt über den unten
beschriebenen erweiterten Test. Das Modul bleibt `partially validated` und
unveröffentlicht; Minimalrechte, nichtleere Benutzergrants, historische
Migrationen und harte Unterbrechungen bleiben eigenständige Nachweise.

## Aktueller Repeat mit vollständiger Principalbindung

Der aktuelle Test erweitert die Zeilensnapshots um `RequestedByPrincipalId`,
die exakten SIDbytes und die acht gespeicherten `datetime`-Bytes von
`RequestedByPrincipalCreatedAt`. Er umfasst damit alle acht Tabellenspalten.
Die eigene Fixture enthält eine vollständig NULL-belegte historische
Zuordnung und drei synthetische nichtleere Zuordnungen. Dafür werden weder
Principals angelegt noch SQL-Rechte erteilt; dies ist Datenbestandserhaltung,
keine zusätzliche Quoten-/Callerrechteabnahme.

Drei Gegenproben ändern jeweils eines dieser Felder in einer eigenen
Rollbacktransaktion. Das originale Capture-/Assert-Paar muss jeweils exakt
52743/State1 auslösen; ein übersehener Unterschied scheitert mit52747.
Die automatische Rowversionänderung wird ausschließlich im temporären
Gegenprobensnapshot auf den alten Wert kompensiert. Damit kann sie ein
fehlendes Principal-Feld im Snapshot nicht verdecken. Die persistente
Mutation und sämtliche Snapshotanpassungen werden zurückgerollt. Positive
Deployvergleiche verwenden diese Kompensation nicht.

Der vorhandene [Runtimeworkflow](../../../.github/workflows/w6d-execution-cancel-runtime.yml)
führt den erweiterten Test auf seinen ausgewiesenen Linux-Versionen/CLs
lokal und zentral aus. Ein Erfolg muss dem tatsächlich geprüften Head oder
Main-Run zugeordnet werden; die elf Windows-Altfälle werden durch diese
Teständerung nicht zu achtspaltigen oder vollständigen Matrixnachweisen.
Eine weitere native Windows-Ausführung ist in der geschlossenen Welle
nicht enthalten.

Der erste CI-Head der Erweiterung scheiterte auf allen drei Linux-Versionen
mit1934, weil die neue XML-Methode im frischen SQLCMD-Testprozess
`QUOTED_IDENTIFIER ON` benötigt. Der Test setzt diesen Parse-Time-Modus nun
vor einem eigenen Batchtrenner explizit. Alle drei eigenen CI-Zielbereinigungen
bestanden; der Erstlauf bleibt fehlgeschlagen und belegt keine Abnahme.

Die neuen Includes sind über den bestehenden Runtimeeinstieg und die
statische Artefaktprüfung erreichbar; das Modulmanifest, Exportpakete und
Produktversion werden nicht geändert. Ein zusätzlich angestoßener lokaler
Releasevorbereitungs-Vollcheck war nicht erfolgreich:274 Tests meldeten
zwölf Fehler und29 Ausführungsfehler, darunter nicht mehr aktuelle historische
Sourcepins. Diese Prüfung ist keine Releaseabnahme; alte Nachweise oder
Goldenwerte werden dafür nicht auf den heutigen Stand umgeschrieben. Der
Fehler bleibt von den tatsächlich ausgeführten Cancellation-Runtimefällen
und deren begrenztem Erfolg getrennt.

## Historische Funktionsnachweise

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
