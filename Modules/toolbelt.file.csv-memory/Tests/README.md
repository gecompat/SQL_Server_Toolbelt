# CSV-Prüfungen und Evidenz

Stand 2026-10-21: Version1.0.0 ist implementiert, `partially validated` und
unveröffentlicht. CI und native Labnachweise besitzen getrennte Bindungen;
andere SAFE-Assemblies qualifizieren diese CSV-Bytes nicht.

## Tatsächliche Gesamtzelldecke 2026-10-21

Der getrennte Scope `-TestScope cell-ceilings` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
im ersten Versuch local/central: acht gezählte Fälle je Modus, 16 je Ziel.
Parser und Writer akzeptieren genau1000000 Zellen im Raster1000×1000,
ohne sowie mit Header. Das gültige Rechteck9901×101 enthält genau1000001
Zellen und wird von beiden mit SQL55303/state1 abgewiesen, vier Abweisungen
je Modus und acht je Ziel. Zeilen-/Spalten-/Textbudgets bleiben dabei unter
ihren Grenzen; Headerzellen zählen zur Gesamtzelldecke.

Primärschlüssel und vollständige Bereichs-/Anzahl-/Wertbyteorakel belegen das
Raster. Die Writer-Übergrenzquelle entsteht unabhängig vom Parser. Exakte
Ausgabebytes, DataRows/ColumnCount, unveränderte Writerquelle und vorheriger
Zielinhalt nach Abweisung sind geprüft. Acht getrennte SQLphasen liefern erst
nach allen Assertions einen typisierten Abschlusswitness; der Adapter zählt
keine Guard-/Lifecyclefälle als Funktionsfälle. Je Phase maximal300 Sekunden,
weiterhin begrenzt durch die unveränderte Arbeits-/Gesamtdeadline und Cleanupreserve.

Beide Läufe Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres
Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash
abwesend. Konfiguration/Rechte und eingefrorene ausführbare Eingaben unverändert.
559 Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.
Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert;
vorhandenes Paket an manifestierte Quellen/exakte Binarybytes gebunden,
kein neuer lokaler Build-/Frameworklauf. Keine neue Default-/Clientabnahme,
Textvollgrenze, Heap-, Minimalrechte-, Gesamtmatrix-, authentifizierte TLS-
oder Releasequalifikation. Status `partially validated`, `unreleased`.

## Korrigierter Writer an tatsächlichen Formgrenzen 2026-10-21

Nach der ausdrücklich freigegebenen begrenzten Erweiterung wurde der eigene
Writeraufruf gezielt beobachtet. Der dritte Diagnoselauf ordnete den verbleibenden
Aufwand dem kanonischen Fragment-/Maßabgleich zu. Die beiden ersten Diagnoseläufe
waren durch den Beobachter unzureichend: der Planabruf überschritt sein eigenes
Zeitlimit. Alle drei Läufe sind getrennte Diagnose, keine Funktionsabnahme;
je Exit1/vollständige Kanäle/leeres Stderr, frischer Audit eine eigene DB/ein
eigener Trusthash abwesend, Konfiguration/Rechte/Eingaben unverändert. Private
Statements, Messwerte und Pläne werden nicht als öffentliche Evidenz gespeichert.
Ein bestimmter Plan oder eine quadratische Laufzeit wird nicht behauptet.

`USP_WriteCsv` besitzt jetzt auf beiden internen Maß-/Fragmenttabellen unbenannte
Clustered-Primärschlüssel auf RowOrdinal/ColumnOrdinal. Das Zellraster wird
bereits vorher auf Eindeutigkeit geprüft; öffentlicher Vertrag, Messung vor
Fragmentallokation und Fehler-/Transaktionsrouting bleiben erhalten. CLR,
Parser-/Deployment-/gemeinsame Snapshotquellen und Workflow sind unverändert.
Das neu aus den aktuellen SQLquellen gepackte Paket enthält exakt dieselben
CLR-Bytes; kein neuer lokaler Build-/Frameworklauf wird behauptet.

Der korrigierte Kandidat bestand auf Windows2025/base CL170 mit erlaubtem
bereitem CU-Äquivalent im ersten Kandidatenlauf local/central:
`-TestScope shape-ceilings-and-default` führte genau acht Formgrenzfälle pro
Modus aus, insgesamt16, darunter acht erwartete SQL55303/state1-Abweisungen.
Erfolge genau bei100000 DATA-Records und1024 Spalten, echte +1-Fehler,
Wert-/Ordinal-/Textbytes und unveränderter Quell-/Zielinhalt sind geprüft.
Der typisierte Abschluss zählt ausschließlich vollständig geprüfte Phasen.
Im selben Installationsscope bestanden zusätzlich alle drei bestehenden
Default-SQLfixtures, Clientmetadaten, 29 Caller-/SET-/Lock-/Rollback-/Confirm0-
Lifecyclefälle, frischer SC-/UTF8-Consumer, Clean/Repeat und Uninstall/Repeat.
Exit0/vollständige Kanäle/leeres Stderr, frischer separater Audit drei eigene
DBs/ein eigener Trusthash abwesend; Konfiguration/Rechte/Inputs unverändert.

Die Kombination erhält den gesamten Defaultumfang bei einem nativen Aufruf;
sie ersetzt keine ausgelassene Prüfung. Die vier freigegebenen Zusatzaufrufe
sind mit drei Diagnoseaufrufen und diesem kombinierten Abschlusslauf verbraucht,
ohne Budgetreset. 535 Offlinekontrollen einschließlich typisiertem Abschluss,
Deadline/Cleanupreserve und falschen Funktions-/Guard-/Lifecyclezählern in
local/central/einzelnen Modi bestanden. SQL150: acht Formfixturephasen sowie
äußerer und expandierter Writerbody, AST/Static bestanden.

Nach zusätzlicher ausdrücklicher Freigabe bestand derselbe korrigierte Kandidat
auch auf Linux2019/latest CL150 local/central im kombinierten Scope:
16 Formgrenzfälle einschließlich acht SQL55303/state1-Abweisungen sowie alle
drei Default-SQLfixtures, Clientmetadaten, 29 Lifecyclefälle, frischer SC-/UTF8-
Consumer, Clean/Repeat und Uninstall/Repeat PASS. Exit0/vollständige Kanäle/
leeres Stderr; frischer separater Audit drei eigene DBs/ein eigener Trusthash
abwesend, Konfiguration/Rechte und eingefrorene Eingaben unverändert.
Der zusätzliche Aufruf bleibt vollständig im gemeinsamen Ledger gezählt.
Die finalen Windows-/Linuxpins erlauben ausschließlich nachgepflegte gekoppelte
Evidenz-/Manifest-/Dokumentationsdateien, keine ausführbare Drift.
Unabhängiger Abschlussreview ohne semantische Findings; einziges Finding zum
generierten API-Katalogfingerprint durch Generatornachtrag und Validator geschlossen.
Die ältere Defaultregression unten betrifft den Stand vor der Indexkorrektur;
die früheren vier Grenzfehlläufe bleiben FAILED und werden nicht umgedeutet.
Die neuen Windows-/Linux-PASSes qualifizieren nicht die tatsächlichen vollen
Zell-/Textdecken, Heap, Minimalrechte, die Gesamtmatrix, authentifiziertes TLS
oder Release. Status weiterhin `partially validated`, `unreleased`.
## Native tatsächliche Zeilen-/Spaltendecken 2026-10-21

Der neue getrennte Scope `-TestScope shape-ceilings` enthält acht serverseitige
Fälle je Modus: Parser/Writer genau an 100000 DATA-Records beziehungsweise
1024 Spalten sowie jeweils ein tatsächliches Element darüber mit SQL55303/state1,
exakten Wert-/Ordinal-/Textbytes und unverändertem Quell-/Zielinhalt. Ein
getrennter typisierter Abschlusswitness zählt nur alle acht abgeschlossenen
Fälle; dieser Funktionszähler ist kein Lifecycle-Guardzähler.

Die native Abnahme dieses Scopes ist **offen**. Vier Versuche sind FAILED,
nicht als PASS oder Ceilingqualifikation zu lesen:

- Linux2019/latest CL150 Versuch1: zusammengefasster Batch am60-Sekunden-
  Kommandolimit abgebrochen; keine einzelne Grenzphase daraus qualifiziert.
- Nach Aufteilung in acht Phasen Linux2019/latest CL150 Versuch2 und
  Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent Versuch1:
  lokale Parserphase100000 bestanden, anschließende lokale Writerphase100000
  am120-Sekunden-Kommandolimit abgebrochen.
- Windows Versuch2: gleicher Parserbefund, Writerphase100000 auch bei
  maximal300 Sekunden abgebrochen. Die übrigen Phasen und central wurden
  in diesen drei phasengetrennten Läufen nicht erreicht.

Alle vier Fehlläufe Exit1/vollständig erfasste Kanäle/leeres Stderr und
FAILED_CLEANED; je frischer separater Audit eine eigene DB/ein eigener Trusthash
abwesend, Konfiguration/Rechte und eingefrorene Eingaben unverändert.
Die Zeitlimits stammen aus dem Adapter; der Timeout belegt weder einen
bestimmten Engpass noch eine Verletzung eines öffentlichen Laufzeitvertrags.
Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen bleiben unverändert.

Die separate Defaultregression auf Linux2019/latest CL150 bestand mit dem
finalen Adapter im ersten Versuch local/central: drei bestehende SQLfixtures,
Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, 29 Lifecyclefälle,
frischer SC-/UTF8-Consumer und Uninstall/Repeat. Exit0/vollständige Kanäle/
leeres Stderr; frischer Audit drei eigene DBs/ein eigener Trusthash abwesend,
Konfiguration/Rechte und Eingaben unverändert. Dieser PASS ersetzt die
fehlgeschlagene tatsächliche Grenzabnahme nicht.

509 synthetische Offlinekontrollen, SQL150-Grammatik aller acht Phasen,
AST2 und statische Verträge bestanden. Negative Abschlusskontrollen weisen
fehlende, zusätzliche, falsch typisierte und falsche Zähler-/Fixturedaten ab.
Der Defaulttimeout bleibt60 Sekunden; nur die Writer-Zeilendecke erhält
maximal300, andere Grenzphasen maximal120 Sekunden, stets gekürzt auf die
verbleibende unveränderte Arbeits-/Gesamtdeadline mit Cleanupreserve.
Vorhandenes Releasepaket an manifestierte Quellen/exakte Binarybytes gebunden;
kein neuer lokaler Build-/Frameworklauf oder Workflow-/Infrastrukturwechsel.

Unabhängiger Erstreview: keine semantischen Codefindings, native Grenzabnahme
weiterhin offen; die gezielte Timeoutanpassung folgt dieser Bewertung.
Tatsächliche Spalten-/Zell-/Textdecken, neue vollständige Grenzfehler-/
Centralabnahme, Heap, Minimalrechte, Gesamtmatrix, authentifiziertes TLS und
Release bleiben nicht ausgeführt. Status `partially validated`, `unreleased`.
## Interne CLR-Rückgabelängen 2026-10-21

Der getrennte Scope `-TestScope binding-return-lengths` bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils im ersten Versuch local/central. Zwei einzeln aus
kanonischen Quellen abgeleitete ALTER-Fixtures ändern die skalare
QuoteCell-Rückgabe von nvarchar(max) auf nvarchar(4000) beziehungsweise
die interne Parser-RowKind-Spalte von nvarchar(6) auf nvarchar(5).
Deploy und Uninstall lieferten SQL55324/state7: vier Abweisungen je Modus,
acht je Ziel. Die geänderten Funktionen wurden dabei nicht fachlich ausgeführt.

Ein konkreter Katalogwitness prüft die Rückgabe mit parameter_id 0 und
max_length 8000 beziehungsweise column_id 1 mit max_length 10 unmittelbar
vor/nach jeder Operation und vor Restore. Gleiche Objekt-/Erstellungsidentität,
CLR-Bindung und typisierte Ownership sowie erfasster Mutationszustand blieben
erhalten; kanonisches ALTER restaurierte exakt die Baseline.

Die separate Linuxregression `binding-drift` bestand local/central mit 32
Abweisungen. Alle drei Läufe Clean/Repeat, Uninstall/Repeat, Exit0/vollständige
Kanäle/leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener
Trusthash abwesend, Konfiguration/Runtimeinputs unverändert. 487 synthetische
Offlinekontrollen einschließlich ungültiger Deskriptoren und Identitäts-/
Witness-/Restaurierungsdrift bestanden; Drift vor der zweiten Operation
blockiert diese und das Restore. 72 expandierte SQL150-ALTER-/Identitäts-/
Witness-Batches aller vier Bindingfamilien und AST/Static PASS.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert.
Vorhandenes Releasepaket an manifestierte Quellen/exakte Binarybytes gebunden;
kein neuer lokaler Build-/Frameworklauf, keine fachliche Ausführung unter
abweichender Länge oder neue Default-Gesamtadapter-/API-/Client-/Vollmatrix-/
Minimalrechte-/Heap-/authentifizierte TLS-/Releaseabnahme.

## Falsche Schemamarkerwerte 2026-10-21

Der getrennte Scope `-TestScope schema-values` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
im ersten Versuch local/central. Vier einzelne Änderungen am eigenen
`toolbelt_file`-Schema: Managed-int von 1 auf 0 sowie die Kategorie `file`
auf `json`, `FILE` und `file ` mit abschließendem Leerzeichen. Deploy und
Uninstall lieferten SQL55324/state1: acht Abweisungen je Modus, 16 je Ziel.

Die neue geschlossene Markerfamilie verwendet den vorhandenen typisierten
Übergangsschutz auch für die Schemaklasse. Basistyp, deklarierte Bytelänge,
tatsächliche DATALENGTH und Wertbytes sind vor Mutation und Restaurierung
exakt gebunden. Mehrere Fälle derselben Property bleiben anhand ihres
geschlossenen Mutationswerts eindeutig. Erfasster Zustand und neutrale
Sitzung blieben nach jeder Abweisung erhalten; die Baseline wurde nach
jedem Fall exakt restauriert. Keine Schema-/Objektowneränderung.

Die separate Linuxregression `marker-values` bestand local/central mit
100 Abweisungen für bisherige Objekt-/Assembly-/Datenbankwerte. Alle drei
Läufe Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr;
je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend,
Konfiguration und eingefrorene Runtimeinputs unverändert. 451 synthetische
Offlinekontrollen einschließlich geschlossener Deskriptoren, inverser
Schemaübergänge und blockierter Restaurierung bei Drift bestanden. Alle
156 expandierten Änderungs-/Restaurierungsbatches der drei Markerfamilien
in beiden Modi SQL150-Grammatik sowie AST/Static PASS.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert;
vorhandenes Releasepaket an manifestierte Quellen/exakte Binarybytes gebunden.
Kein neuer lokaler Build-/Frameworklauf oder neuer Default-Gesamtadapter-/
API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierter TLS-/Releasenachweis.

## Fremde SQL-TVFs auf reservierten Namen 2026-10-21

Der getrennte Scope `-TestScope foreign-table-functions` bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils im ersten Versuch local/central. Jeder der fünf
reservierten CSV-Namen wird einzeln durch eine fremde Inline-TVF (`IF`)
und eine Multi-Statement-TVF (`TF`) belegt. Deploy und Uninstall müssen
SQL55324/state3 liefern: 20 Abweisungen je Modus, 40 je Ziel.

Geschlossene Deskriptoren unterscheiden die beiden FUNCTION-Arten über
ihren tatsächlichen Katalogtyp. Der gemeinsame Helper prüft den eigenen
typisierten Laufmarker, Objekt-/Erstellungsidentität, erfasste Definitionen
und Signaturen sowie das unabhängige synthetische Ergebnis einschließlich
trailing space. Ergebniswitnesses gelten unmittelbar vor/nach jeder
Abweisung und vor geschütztem Fixture-Drop; anschließend ist die saubere
Baseline exakt wiederhergestellt. Die zusätzliche Vorabprüfung gilt auch
für die bisherigen Familien. Deshalb bestanden separate Linuxregressionen
`foreign-kinds` und `foreign-aliases` mit jeweils 40 Abweisungen local/central.

Alle vier Läufe: Clean/Repeat, Redeploy, Uninstall/Repeat, Exit0, vollständige
Kanäle und leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein
eigener Trusthash abwesend, Konfiguration und eingefrorene Runtimeinputs
unverändert. 423 synthetische Offlinekontrollen einschließlich Witnessdrift
unmittelbar vor der zweiten Operation mit unterbundener Operation und
Fixtureentfernung PASS. SQL150-Grammatik aller 217 expandierten Erzeugungs-,
Lese-, Marker-, Identitäts- und Dropbatches aller drei Familien einschließlich
Aliastarget sowie PowerShell-AST/Static PASS.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert.
Das vorhandene Releasepaket bleibt an manifestierte Produktquellen und exakte
Binarybytes gebunden; kein neuer lokaler Build-/Frameworklauf. Keine neue
Default-Gesamtadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/
authentifizierte TLS-/Releaseabnahme; frühere Fehlläufe bleiben erhalten.

## Finale benannte SameDB-Verbraucher auf Linux 2026-10-21

Direkt nach Abschluss von PR351 begann die ausgewählte Folgewelle. Der
unveränderte öffentliche Adapter `-TestScope named-consumers` bestand auf
Linux2019/latest CL150 im ersten Versuch local/central. Fünf nacheinander
angelegte SQL-Verbraucher referenzieren die fünf reservierten CSV-Slots mit
explizitem Namen der eigenen Datenbank. Deploy und Uninstall lieferten je
SQL55325/state3: zehn Abweisungen pro Modus, 20 insgesamt.

Die finalen Assertions prüfen den Fingerprint sämtlicher erfasster
Dependencyzeilen unmittelbar vor/nach jeder Operation und vor Fixture-Drop.
Exakte Zielnamen, zulässige lokale ID-/Namensbindung, typisierte Laufmarker
und Objekt-/Erstellungsidentitäten bestanden. Erfasster Mutationszustand
und Dependencywitness blieben erhalten; geschütztes Entfernen jeder eigenen
Fixture stellte die Baseline exakt wieder her.

Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle und leeres Stderr
bestanden. Der frische unabhängige Audit bestätigte zwei eigene DBs/einen
eigenen Trusthash abwesend; Konfiguration und eingefrorene Runtimeinputs
blieben unverändert. Das vorhandene Releasepaket wurde erneut an alle
manifestierten Produktquellen und seine exakten Binarybytes gebunden.

Dieser Lauf ergänzt den finalen Windowsnachweis nach PR348 um Linux mit
dem aktuellen Assertionstand. Frühere Linux-Teilnachweise und der erste
fehlgeschlagene Katalogwitness bleiben datiert erhalten. Keine isolierte
Abnahme des NULL-ID-Preflightzweigs, fachliche Consumerausführung oder neue
Default-Gesamtadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/
authentifizierte TLS-/Releaseabnahme. Kein neuer lokaler Build-/Frameworklauf.

## Finale CLR-Defaults auf Linux 2026-10-21

Der unveränderte öffentliche Adapter `-TestScope binding-defaults` bestand auf
Linux2019/latest CL150 im ersten Versuch local/central. Fünf einzelne
Parameterdefaults an den drei internen CLR-Funktionen führten je Deploy und
Uninstall zu SQL55324/state7: zehn Abweisungen pro Modus, 20 insgesamt.
Die finalen Assertions prüfen Basistyp, Wertbytes und beim Text DATALENGTH;
der NULL-Default besitzt einen eigenen Witness. Die unmittelbare Prüfung
vor/nach jeder Operation und vor Restaurierung, gleiche Objekt-/Erstellungs-
identität und unveränderter erfasster Mutationszustand bestanden. Die
kanonischen ALTER-Definitionen restaurierten jeweils exakt die Baseline.

Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle und leeres Stderr
bestanden. Der frische unabhängige Audit bestätigte zwei eigene DBs/einen
eigenen Trusthash abwesend; Konfiguration und eingefrorene Runtimeinputs
blieben unverändert. Das vorhandene Releasepaket wurde vor Verwendung erneut
an alle manifestierten Produktquellen und seine exakten Binarybytes gebunden;
kein neuer lokaler Build oder Frameworklauf wurde daraus abgeleitet.

Dieser Lauf ergänzt die bisherigen finalen Windowsnachweise um Linux mit
dem aktuellen Assertionstand nach PR350. Frühere engere Orakel und Fehlläufe
bleiben erhalten. Kein neuer Default-Gesamtadapter-, API-/Client-, Vollmatrix-,
Minimalrechte-, Heap-, authentifizierter TLS- oder Releasenachweis.

## CLR-Ausführungskontexte 2026-10-20/21

Der getrennte Scope `-TestScope binding-execution` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
im ersten Versuch local/central. Jede der drei internen Funktionen wird einzeln
mit `WITH EXECUTE AS OWNER` aus ihrer kanonischen Quelle verändert. Ein eigener
Katalogwitness verlangt den dokumentierten Metadatenwert-2;
[sys.assembly_modules](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-assembly-modules-transact-sql)
unterscheidet diesen Kontext vom standardmäßigen Caller mit NULL.
[CREATE FUNCTION](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql)
beschreibt die CLR-Funktionsoption. Die Funktionen werden im geänderten Kontext
nicht ausgeführt; dies qualifiziert keine Fachausführung unter OWNER.

Deploy und Uninstall müssen SQL55324/state5 liefern: sechs Abweisungen je Modus,
zwölf je Ziel. Der Witness wird unmittelbar vor/nach jeder Operation und vor
Restaurierung geprüft. Gleiche Objekt-/Erstellungsidentität, passende CLR-Bindung,
typisierte Ownership und unveränderter erfasster Mutationszustand bleiben
Voraussetzung. Die kanonische ALTER-Definition restauriert exakt die Caller-Baseline.
Keine Rechtevergabe oder Änderung von Objekt-/Schemaeigentümern.

Die neue unmittelbare Vorabprüfung gilt auch für die bisherigen Bindingfamilien.
Daher bestanden zusätzlich `binding-drift` auf Linux2019/latest CL150 mit 32
und `binding-defaults` auf Windows2025/base CL170 mit20 Abweisungen, jeweils
local/central. Alle vier Läufe: Clean/Repeat, Uninstall/Repeat, Exit0/vollständige
Kanäle/leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener
Trusthash abwesend, Konfiguration und Runtimeinputs unverändert.
384 Offlinekontrollen einschließlich Drift unmittelbar vor der zweiten
Operation mit unterbundener Ausführung/Restaurierung PASS. SQL150-Grammatik
aller64 expandierten ALTER-/Identitäts-/Witness-Batches der drei Familien,
PowerShell-AST und Static PASS.

Keine neue Helferdatei oder Workflow-/Job-/Filter-/Cancellation-/Buildgrenze.
Zwei gezielte Legacyregressionen decken die geänderten Helferkonsumenten ab;
keine grüne Vollmatrixwiederholung oder zusätzliche PASS-Logreviewkette.
Token-/Kostenwirkung unbekannt. Produkt-/Deployment-/CLR-/Snapshotquellen
unverändert; keine neue Default-/API-/Client-, Minimalrechte-, Heap-,
authentifizierte TLS-, vollständige Driftmatrix- oder Releaseabnahme.
Status bleibt `partially validated`, `unreleased`.

## Falsche Ownership-/Release-Markerwerte 2026-10-20

Der getrennte Scope `-TestScope marker-values` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
im ersten Versuch local/central. Die neue geschlossene Wertefamilie ergänzt
den vorhandenen Markerhelfer um25 Fälle: vier Marker je CSV-Objekt, drei an
der Assembly, zwei an der Datenbank. Managed wird bit0, Modul-ID, Version,
Sichtbarkeit und Modus werden synthetisch inkohärent. Deploy und Uninstall
müssen SQL55324/state2/4/5 liefern:50 Abweisungen pro Modus,100 pro Ziel.

Jeder Übergang prüft den bisherigen sql_variant-Basistyp, seine MaxLength,
DATALENGTH und Wertbytes. Falldeskriptor und beide Übergangsrichtungen sind
an die geschlossenen Familien gebunden; freie Erwartungs-/Zielausdrücke sind
unzulässig. Erfasster Mutationszustand und neutrale Sitzung müssen bei jeder
Abweisung erhalten bleiben. Restaurierung erfolgt nur bei unverändertem
erfasstem Zustand und exakt erwarteter Markermutation, danach exakte Baseline.
Die reine fehlende-Marker-Familie wird nicht verändert.

Wegen der Änderung am gemeinsamen Markerhelfer bestand zusätzlich die bisherige
`ownership-markers`-Familie auf Linux2019/latest CL150 local/central mit40
Abweisungen. Alle drei Läufe: Clean/Repeat, Uninstall/Repeat, Exit0/vollständige
Kanäle/leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener
Trusthash abwesend, Konfiguration und Runtimeinputs unverändert.
367 Offlinekontrollen einschließlich falscher Deskriptorfelder, unzulässiger
Übergänge ohne SQL-Aufruf, unveränderter Mutation und Restaurierungsdrift PASS.
SQL150-Grammatik aller140 expandierten Änderungs-/Restaurierungsbatches beider
Familien in beiden Modi sowie PowerShell-AST und Static PASS.

Keine neue Helferdatei oder Workflow-/Job-/Filter-/Cancellation-/Buildgrenze.
Eine gezielte Legacyregression deckt den geänderten Helferkonsumenten ab;
keine grüne Vollmatrixwiederholung oder zusätzliche PASS-Logreviewkette.
Token-/Kostenwirkung unbekannt. Produkt-/Deployment-/CLR- und gemeinsame
Snapshotquellen unverändert. Keine neue Default-/API-/Client-, Minimalrechte-,
Heap-, authentifizierte TLS-, vollständige Driftmatrix- oder Releaseabnahme.
Status bleibt `partially validated`, `unreleased`.

## Explizite SameDB-SQL-Verbraucher 2026-10-20

Der getrennte Scope `-TestScope named-consumers` bestand im finalen vierten
nativen Lauf auf Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent,
zweiter Versuch local/central. Ein eigener Consumer referenziert nacheinander
jeden der fünf CSV-Namen ausdrücklich mit der eigenen journalgebundenen DB.
Die Consumer werden nicht ausgeführt. Deploy und Uninstall liefern
SQL55325/state3: zehn Abweisungen pro Modus,20 je Ziel.

[sys.sql_expression_dependencies](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql)
unterscheidet lokale Bindung und nicht aufgelöste IDs. Die Fixture verlangt
genau ein referenziertes Objekt mit exaktem Schema-/Objektnamen und dessen
nativer ID oder NULL. Der Katalogdatenbankname darf NULL oder byte-/längengenau
die eigene DB sein; fremder Server und Callerabhängigkeit sind ausgeschlossen.
Damit wird ausdrücklich kein isolierter NULL-ID-Preflightzweig qualifiziert.
Der Fingerprint aller erfassten Dependencyzeilen bindet die tatsächlich
vorgefundene Katalogform unmittelbar vor/nach jeder Abweisung und vor Drop.

Zusätzlich gelten eigener typisierter Datenbank-/Fixturemarker, journalgebundene
DB-ID/Erstellungsidentität, gleiche Consumer-ID/Erstellungsidentität und
unveränderter erfasster Gesamtsnapshot. Nach geschütztem Drop muss die Baseline
stimmen. Ohne initialen Dependencywitness übernimmt ausschließlich OwnDB-Cleanup.

Der erste Linux2019/latest CL150 Versuch bleibt FAILED am neuen Witness mit
pauschaler NULL-ID- und expliziter DB-Feldannahme, vor dem ersten Guardfall.
Exit1/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit eine eigene
DB/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert.
Nach Korrektur bestanden zweiter Linuxlauf und erster Windowslauf je20
Abweisungen local/central. Der unabhängige Review verlangte danach zusätzlich
die unmittelbare Dependencyprüfung vor jeder Lifecycleoperation, weil der
Gesamtsnapshot diese Katalogzeilen nicht erfasst. Diese beiden früheren
Erfolge bleiben enger; der letzte Windowslauf qualifiziert die Korrektur
repräsentativ, ohne erneute Zielvollmatrix.

Alle drei erfolgreichen Läufe bestanden Clean/Repeat, Uninstall/Repeat,
Exit0/vollständige Kanäle/leeres Stderr und je einen frischen unabhängigen Audit:
zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert.
301 Offlinekontrollen einschließlich Drift ausschließlich vor der zweiten
Operation mit unterbundener Ausführung/Fixtureentfernung, PowerShell-AST und
SQL150-Grammatik aller40 expandierten CREATE-/Owner-/Identitäts-/Witness-/
Drop-Batches PASS. Inkrementeller Docvalidator samt16Impactselftests PASS.

Ein funktionsreiner Helper und AST-Eintrag im bestehenden CI-Schritt; keine
neuen Jobs, Filter, Cancellation- oder Build-/Frameworkgrenzen. Token-/Kostenwirkung
unbekannt, kein grüner Vollmatrixreplay oder zusätzlicher PASS-Logreview.
Produkt-/Deployment-/CLR- und gemeinsame Helper unverändert. Keine Consumer-API-
ausführung, neue Default-/API-/Client-, Minimalrechte-, authentifizierte TLS-,
Heap-, Vollmatrix- oder Releaseabnahme. Status `partially validated`, `unreleased`.

## Gezielte CLR-Parameterdefaults 2026-10-20

Der getrennte Scope `-TestScope binding-defaults` ergänzt die bestehende
Binding-Fallliste um fünf geschlossene Parameterdefaults: Separatortext und
Headerbit beim Messen, NULL-Token und Ausgabelimit beim Quoten, Zeilenlimit
beim Parser. Die kanonischen Quellen liefern ALTER- und Restaurierungsdefinition.
[CREATE FUNCTION](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql)
beschreibt CLR-Parameterdefaults; [sys.parameters](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-parameters-transact-sql)
führt deren Flag und Wert für CLR-Objekte.

Der ausdrücklich freigegebene sechste und letzte native Lauf bestand auf
Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent im dritten
Defaultsversuch local/central. Deploy und Uninstall liefern SQL55324/state7:
zehn Abweisungen pro Modus,20 pro Ziel. Der erfasste Snapshot schützt das Flag;
ein separates Orakel prüft Basistyp, Wertbytes und beim Text die Bytelänge
beziehungsweise NULL exakt vor/nach jeder Abweisung und vor der Restaurierung.
Konvertierbare oder mit Nullbytes verlängerte abweichende Text-/Zahlenwerte
bestehen dieses Orakel nicht. Fremde Wertdrift blockiert das restaurierende
ALTER auch bei unverändertem Snapshot. Objekt-/Erstellungsidentität,
CLR-Bindung und typisierte Ownership bleiben Restaurierungsvoraussetzungen;
anschließend muss die exakte Baseline stimmen.

Der unabhängige Review korrigierte zunächst numerische Konversionsmehrdeutigkeit,
danach die fehlende Textlängenbindung. Die finalen Assertions wurden vor dem
sechsten Lauf unabhängig ohne weitere Quellbefunde geprüft; seine neuen
Laufmetriken anschließend deterministisch. Der Lauf qualifiziert die letzte
Assertion repräsentativ auf Windows; keine abweichende Plattformlogik im Helfer.

Frühere Nachweise bleiben enger: Linux2019/latest CL150 zweiter und Windows
erster Defaultsversuch mit konvertierenden numerischen Probes; erster Linuxlauf
ohne wiederholten Wertwitness; zweiter Windowslauf vor der DATALENGTH-Korrektur.
Alle bestanden20 Abweisungen in ihrem damaligen Umfang. Zusätzlich bestand eine
Linux2019/latest CL150 `binding-drift`-Regression local/central mit 32 Abweisungen
vor den letzten ausschließlich defaultspezifischen Probekorrekturen.
Alle sechs Läufe: Exit0/vollständige Kanäle/leeres Stderr; je frischer unabhängiger
Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert.
255 Offlinekontrollen einschließlich Wertdrift bei unverändertem synthetischem
Snapshot, PowerShell-AST und SQL150-Grammatik aller52 expandierten Batches PASS.

Keine neue Helferdatei, Workflow-, Job-, Filter-, Cancellation- oder
Build-/Frameworkgrenze. Gezielte Legacyregression und begrenzte Abnahme der
Reviewkorrekturen; keine grüne Zielvollmatrix oder PASS-Logreviewkette.
Token-/Kostenwirkung unbekannt. Produkt-, Deployment-, CLR-Quellen und gemeinsame
Snapshot-/Abweisungshelper unverändert; kein neuer Defaultadapter-/API-/Client-/
Minimalrechte-/Heap-/authentifizierter TLS-/Release- oder Driftvollmatrixnachweis.
Status bleibt `partially validated`, `unreleased`.

## Gezielte interne CLR-Bindingdrift 2026-10-20

Der getrennte Scope `-TestScope binding-drift` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
local/central im ersten nativen Versuch. Acht einzelne Änderungen betreffen
die drei bereits installierten internen CLR-Funktionen: zwei NULL-Aufrufoptionen,
vier Parameter-/Resultattextlängen und je einen Parameter-/Resultatspaltennamen.
Die geschlossene Fallliste erzeugt `ALTER FUNCTION` aus den kanonischen Quellen;
die CLR-Assembly und die öffentlichen API-Verträge werden nicht geändert.

Ein eigener Katalogwitness belegt jeweils die konkrete Änderung. Deploy und
Uninstall müssen SQL55324/state5 für die NULL-Optionen beziehungsweise state7
für die Signaturen liefern: 16 Abweisungen pro Modus, 32 je Ziel. Der gesamte
erfasste Mutationszustand und der neutrale Sitzungszustand müssen erhalten
bleiben. Restaurierung verlangt weiterhin dieselbe Objekt-ID/Erstellungsidentität,
passende CLR-Bindung, typisierte Ownershipmarker und den unveränderten erfassten
Mutationszustand. Die kanonische ALTER-Definition muss anschließend exakt die
Baseline wiederherstellen. Bei unklarer Identität oder fremder Drift unterbleibt
die Restaurierung; der äußere journalgebundene OwnDB-Cleanup bleibt zuständig.

Je Lauf bestanden Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle
und leeres Stderr. Frische unabhängige Audits bestätigen je zwei eigene DBs
und einen eigenen Trusthash abwesend; Konfiguration und Runtimeinputs unverändert.
235 synthetische Offlinekontrollen einschließlich ungültiger Falldeskriptoren,
fehlender/mehrdeutiger Quellnaht, falscher Witnessform, unbeobachteter Mutation,
Identitätsdrift und blockierter Restaurierung bestanden. PowerShell-AST und
SQL150-Grammatik aller 32 expandierten ALTER-/Identitäts-/Witness-Batches PASS.

Der neue funktionsreine Helper wird nur im gewählten nativen Scope importiert.
Der bestehende CI-Schritt ergänzt seine AST und die Offlinekontrollen; Jobs,
Filter, Cancellation und Build-/Frameworkgrenzen bleiben unverändert.
Keine erneute grüne Zielvollmatrix oder zusätzliche PASS-Logreviewkette;
Token-/Kostenwirkung unbekannt. Produkt-, Deployment-, CLR-Quellen und gemeinsame
Snapshot-/Abweisungshelper unverändert. Kein neuer Default-/API-/Client-,
Minimalrechte-, Heap-, authentifizierter TLS-, Release- oder vollständiger
Binding-/Driftmatrixnachweis. Modulstatus bleibt `partially validated`, `unreleased`.

## Fremde Synonyme und SQL-Funktionen 2026-10-20

Der getrennte Scope `-TestScope foreign-aliases` erweitert den bestehenden
Fremdarten-Helfer um eine geschlossene zweite Fallfamilie. Jeder der fünf
reservierten CSV-Namen wird einzeln als Synonym und SQL-Skalarfunktion belegt.
Die Synonyme zeigen ausschließlich auf eine eigene synthetische Tabelle in
derselben Testdatenbank. Deploy und Uninstall müssen SQL55324/state3 liefern:
20 Abweisungen je Modus, 40 je Ziel. Neben erfassten Definitionen, Parametern,
Spalten und Ergebniswerten wird das Synonymziel bytegenau geprüft.
[`sys.synonyms.base_object_name`](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-synonyms-transact-sql)
liefert einen vollständig quotierten Namen; der Sollwert enthält deshalb die
Klammerung. Falsches Ziel, Padding, unquotierte Darstellung, falscher Datentyp
und leere/mehrdeutige Witnesses bestehen die Offlinekontrollen nicht.

Linux2019/latest CL150 bestand im zweiten, Windows2025/base CL170 mit erlaubtem
bereitem CU-Äquivalent im ersten Aliasversuch jeweils local/central. Der erste
Linuxversuch bleibt FAILED: Der Target-Cleanup verdeckte einen Fixturefehler,
und der neue Sollwert erwartete fälschlich einen unquotierten Zielnamen.
Nach einem Fixtureabbruch übernimmt jetzt der äußere journalgebundene OwnDB-
Cleanup; eine nachfolgende Targetaktion darf die ursprüngliche Diagnose nicht
überdecken. Die streng geprüfte Targetentfernung im erfolgreichen Pfad bleibt
erhalten. Der Fehllauf ist frisch bereinigt: eine eigene DB/ein eigener Trusthash
abwesend, Konfiguration und Inputs unverändert.

Wegen der Änderung am bestehenden Helfer bestand zusätzlich ein separater
Linux2019/latest CL150 View-/Prozedur-Regressionslauf local/central mit 40
Abweisungen. Jeder erfolgreiche Lauf bestand Clean/Repeat, eigene typisierte
Fixtureentfernung mit Objekt-ID/Erstellungsidentität und Zustandserhalt, saubere
Baseline, Redeploy und Uninstall/Repeat; Exit0, vollständige Kanäle und leeres
Stderr. Je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash
abwesend, Konfiguration und Runtimeinputs unverändert.

194 Offlinekontrollen einschließlich Diagnoseerhalt bei Aliasabbruch und die
SQL150-Grammatik aller 173 expandierten Fixture-Batches bestanden. Die letzte
Diagnosekontrolle wurde nach dem Windowslauf ergänzt; sie verändert keine
native Runtimequelle und wird vom Labadapter nicht ausgeführt. Keine zusätzliche
Helferdatei, Workflow-/Job-/Filter-/Cancellationänderung oder erneute Zielvollmatrix;
ein gezielter Legacy-Regressionslauf deckt den geänderten Helferkonsumenten ab.
Produkt, Deployment, CLR und gemeinsame Snapshot-/Abweisungshelper unverändert.
Token-/Kostenwirkung unbekannt. Keine neue Default-/API-/Client-/Binding-/
Minimalrechte-/Heap-/authentifizierte TLS-/Release- oder vollständige Driftmatrixabnahme.

## Fremde Views und Prozeduren 2026-10-20

Der getrennte Scope `-TestScope foreign-kinds` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
local/central im ersten nativen Versuch. Nach echtem Uninstall wird jeder der
fünf reservierten CSV-Zielnamen einzeln als fremde View und SQL-Prozedur
angelegt. Beide Lifecycleoperationen müssen SQL55324/state3 liefern: zehn
Fixtures und 20 Abweisungen je Modus, 40 je Ziel. Der erfasste Katalogzustand
einschließlich Definitionen, Parametern und Spalten bleibt unverändert; ein
gesondertes Ergebnisorakel prüft genau eine Zeile mit zwei geordneten Spalten,
Int32-Wert und ordinalem Text einschließlich Padding. Die Entfernung verlangt
zusätzlich unveränderten erfassten Zustand, eigene typisierte Laufmarkierung,
Objekt-ID und Erstellungsidentität. Danach muss die saubere Baseline stimmen.

Je Ziel bestanden Clean/Repeat, erneutes Deploy nach den Fremdfixtures,
Uninstall/Repeat, Exit0, vollständige Kanäle und leeres Stderr. Frische
unabhängige Audits bestätigen je zwei eigene DBs/einen eigenen Trusthash
abwesend sowie unveränderte Konfiguration und Runtimeinputs.
163 synthetische Offlinekontrollen einschließlich ungültiger Fallfelder,
abweichender Ergebnisform/-werte, verlorenen Paddings, Identitätsdrift und
blockierter Fixtureentfernung bestanden. SQL150-Grammatik aller 60 expandierten
DDL-/Read-/Ownership-/Drop-Batches und Helper-/Adapter-AST ebenfalls bestanden.

Produkt, Deployment, CLR und gemeinsame Snapshot-/Abweisungshelper sind
unverändert. Der neue Helper wird nur im Fremdarten-Scope geladen; der
vorhandene Fremdslothelper liefert dort ausschließlich die bekannte Namensliste.
Der bestehende CI-Schritt ergänzt nur die neue AST und erweiterten
Offlinekontrollen. Filter, Jobs, Cancellation und Build-/Frameworkgrenzen
bleiben unverändert; keine erneute Zielvollmatrix oder PASS-Logreviewkette.
Token-/Kostenwirkung unbekannt. Weitere Objektarten, Synonyme, zusätzliche
Verbraucher-/Binding-/Owner-/Rechte-/Driftvarianten, Heap, authentifiziertes TLS
und Release bleiben offen; kein neuer Default-/API-/Clientnachweis.

## Fehlende Ownershipmarker 2026-10-20

Der getrennte Scope `-TestScope marker-absence` bestand auf Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
local/central im ersten nativen Versuch. Pro Modus wurden 27 Marker einzeln
entfernt: vier je CSV-Zielobjekt, drei an der Assembly, zwei datenbankweite
Release-/Modusmarker und zwei Schemamarker. Die ursprünglichen typisierten
Werte und ihre Bytes werden vor dem Entfernen geprüft. Deploy und Uninstall
müssen jeweils SQL55324/state1/2/3/4/5 liefern: 54 Abweisungen pro Modus,
108 pro Ziel. Fehlender Versionsmarker führt dabei zum unvollständigen Zustand
state3; der ursprüngliche Wert wird erst bei unverändertem erfasstem
Mutationszustand und weiterhin fehlendem Marker restauriert. Anschließend muss
der vollständige erfasste Snapshot wieder der Baseline entsprechen.

Je Ziel bestanden Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle
und leeres Stderr. Frische unabhängige Audits bestätigen zwei eigene DBs/einen
eigenen Trusthash abwesend, Konfiguration und Runtimeinputs unverändert.
121 synthetische Offlinekontrollen einschließlich ungültiger Fallfelder,
unbeobachteter Mutation und Restaurierungsdrift sowie SQL150-Grammatikprüfung
aller 108 expandierten Remove-/Restore-Batches bestanden.

Der neue Helper wird nur im gewählten Scope geladen. Der gemeinsame
Snapshothelper, Produkt-, Deployment- und CLR-Quellen sind unverändert; kein
zusätzlicher Default-/API-/Client-/Heap-/TLS-Nachweis. Der bestehende CI-Schritt
ergänzt nur die Helper-AST und nutzt die erweiterten Offlinekontrollen;
Filter, Jobs, Cancellation und Build-/Frameworkgrenzen bleiben unverändert.
Keine erneute Zielvollmatrix; Review am stabilen getesteten Kandidaten statt
einer gesonderten PASS-Logreviewkette. Token-/Kostenwirkung unbekannt.
Weitere Wert-/Typ-/Binding-/Owner-/Rechte-/Driftvarianten und Release bleiben offen.

## Begrenzte Fremdslot-/Verbraucher-Guards 2026-10-20

Der getrennte Testscope `-TestScope foreign-slots` ist für Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils
local/central bestanden: pro Ziel 28 Abweisungen und vier inverse Kontrollen.
Linux bestand im zweiten, Windows im ersten nativen Versuch. Je Clean/Repeat,
Uninstall/Repeat, Exit0, vollständige Kanäle und leeres Stderr; frischer
unabhängiger Audit bestätigt zwei eigene DBs/einen eigenen Trusthash abwesend
und unveränderte Inputpins. Konfiguration und Rechte blieben unverändert.

Nach echtem Uninstall belegt die eigene Fixture jeden der fünf CSV-Zielnamen
einzeln mit einer fremden Tabelle einschließlich zwei synthetischer Zeilen,
NULL/Padding, Primärschlüssel und Zusatzindex. Deploy und Uninstall müssen
jeweils mit SQL55324/state3 abbrechen. Der erfasste Katalogzustand und ein
separater Index-/Constraint-/Wertbytes-Snapshot müssen identisch bleiben.
Zwei inverse Kontrollen pro Modus ändern vorher NULL in leer und entfernen
den Zusatzindex; der Witness muss beides erkennen und exakt restaurierbar sein.

Nach erneuter Installation prüft je ein zusätzlicher SQL- und CLR-Verbraucher
die Schutzpfade SQL55325/state3 beziehungsweise state2, ebenfalls gegen beide
Lifecycleoperationen. Das ergibt 14 Abweisungen und zwei inverse Kontrollen
pro Modus, 28 beziehungsweise vier pro Ziel; getrennt von Marker- und
Defaultzählern. Fixtureentfernung verlangt den unveränderten erfassten Zustand,
Objekt-ID, Erstellungsidentität und den eigenen typisierten Laufmarker.
Uninstall/Repeat und frischer OwnDB-/Trustaudit bleiben Abschlussgates.

Der erste Linux-Guardversuch bleibt `FAILED`: vor dem ersten Guardfall war der
Snapshot nach Uninstall ungültig. Die lesende Diagnose isolierte einen leeren
`FOR JSON`-Skalar als NULL; die Verkettung verlor damit den Gesamtsnapshot.
Der gemeinsame Helper bildet leere Katalogteile jetzt als `[]` ab, behält alle
erfassten Felder und die strenge Vierhash-Prüfung bei. Die SQL150-Grammatik und
die lesende Leerkatalogprobe bestanden. Der frische Audit des Fehllaufs
bestätigt eine eigene DB/einen eigenen Trusthash abwesend, keine Konfigurations-
oder Rechteänderung. Die korrigierten erfolgreichen Guardläufe stehen getrennt.

Wegen der Änderung am gemeinsamen Helper wurde der reservierte Default-
Regressionslauf auf Linux2019/latest CL150 local/central ausgeführt: drei
SQLfixtures, Clientmetadaten, 29 gezielte Lifecyclefälle, frischer SC-/UTF8-
Consumer und Uninstall/Repeat PASS; Exit0, vollständige Kanäle, leeres Stderr
und frischer unabhängiger Audit drei eigene DBs/ein eigener Trusthash abwesend,
Inputpins und Konfiguration unverändert. Keine neue Zwölfzielabnahme.

50 Offline-Fail-closed-Kontrollen und die Grammatikprüfung von elf synthetisch
expandierten SQLstrings mit TSql150Parser bestanden. Die bisherigen Kontrollen
gegen fehlende/falsche Fehler, Session-/Metadatendrift und Restaurierungsdrift
bleiben enthalten; neue Kontrollen prüfen Scopewerte, Fixture-Namensgrenzen und
ungültige/leere/abweichende Witnesses. Der unabhängige Review fand eine leere
Modusliste als möglichen Nullfälle-PASS; der Adapter verlangt jetzt ein oder
zwei Modi und weist leere/null Eingaben vor SQL-Zugriff ab. Sieben zusätzliche
Parameterkontrollen sichern die Korrektur. Der bestehende CSV-Workflow ergänzt nur
die neue Helper-AST im bisherigen Schritt. Filter, Jobs, Cancellation und
Build-/Frameworkgrenzen bleiben erhalten; keine neue Reviewkette oder
Zwölfzielwiederholung. Token-/Kostenwirkung unbekannt.

Produkt, Deployment und CLR sind unverändert. Der neue Fremdslothelper wird nur
im Fremdslotscope geladen. Der gemeinsame Snapshothelper wurde korrigiert;
Default- und Markerpfade behalten ihren bisherigen Teilumfang. Frühere Nachweise
behalten ihre ursprünglichen Ausführungsbindungen und sind keine erneute
Abnahme dieses Helpers. Weitere
Fremdobjektarten, Verbraucher-/Driftvarianten, Minimalrechte, zusätzliche
Collations, Heap, authentifiziertes TLS und Release bleiben offen.

## Begrenzte Marker-Guards 2026-10-20

`Tests/CI/run-csv-memory-lab.ps1 -TestScope ownership-markers` wählt einen
getrennten Prüfscope. Nach unverändertem Clean/Repeat mit exakter SAFE-Assembly
ändert die eigene Fixture zehn Marker gezielt: `Toolbelt.Managed` als `int`
statt `bit` auf allen fünf Slots, ModuleId als `varchar` statt `nvarchar`,
Version mit trailing space, Visibility in anderer Großschreibung,
Assembly-Managed mit falschem Basistyp und DeploymentMode mit trailing space.
Deploy und Uninstall müssen jeden Fall mit SQL55324/state2, 4 oder 5 passend
zum Marker abweisen. Das ergibt 20 Abweisungen pro Modus und 40 je Ziel;
diese Fälle werden nicht zu den bisherigen 29 Lifecyclefällen addiert.

Die Fixture prüft vor der Änderung die erwartete Markeridentität einschließlich
Basistyp, MaxLength und Wertbytes. Der erfasste Objekt-/Assembly-/Schema-/
Release-Metadatenzustand muss nach jeder Abweisung identisch bleiben; beide
Transaktionszustände müssen null sein. Die erlaubten Lifecycle-Optionen
NOCOUNT und XACT_ABORT werden vor dem Abweisungstest vorbereitet und danach
exakt verglichen. Restaurierung erfolgt ausschließlich bei unveränderter
eigener Mutation und muss die erfasste Baseline exakt wiederherstellen.
Das ist keine vollständige Rechte-, Marker- oder Fremdslotmatrix.

| Ausführung | Ergebnis und Grenze |
|---|---|
| Linux2019/latest CL150, Guardversuch1 | FAILED vor dem ersten Abweisungsorakel an der kombinierten Sitzungsabfrage; frischer Audit eigene DB/eigener Trusthash abwesend |
| Linux2019/latest CL150, Default-Regressionslauf | PASS local/central, drei SQLfixtures, Client/Consumer, 29 gezielte Lifecyclefälle, Exit0/vollständige Kanäle/leeres Stderr; frischer Audit drei eigene DBs/ein eigener Trusthash abwesend |
| Linux2019/latest CL150, Guardversuch2 | FAILED an der Optionsgleichheit der neutralen Fixture; keine vollständige Guardabnahme, frischer Audit eigene DB/eigener Trusthash abwesend |
| Linux2019/latest CL150, ausdrücklich freigegebener Guardversuch3 | PASS local/central mit 40 erwarteten Abweisungen, exakter Markerrestaurierung, Clean/Repeat und Uninstall/Repeat; Exit0/vollständige Kanäle/leeres Stderr, frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend |
| Windows2025/base mit bereitem erlaubtem CU-Äquivalent CL170, Guardversuch1 | PASS local/central, 40 erwartete Abweisungen und exakte Markerrestaurierung, Clean/Repeat und Uninstall/Repeat; Exit0/vollständige Kanäle/leeres Stderr, frischer Audit zwei eigene DBs/ein eigener Trusthash abwesend |

Ein lesender synthetischer Diagnosevergleich auf Linux zeigte: XACT_STATE
allein und zusammen mit TRANCOUNT war null, im gemeinsamen SELECT mit
OPTIONS abweichend; die getrennten Nullzustandsprüfungen bestanden. Die
Korrektur verwendet diese getrennten Prüfungen. Zusätzlich bereitet die
neutrale Fixture die vom Produktpreflight ausdrücklich gesetzten Optionen
vor. Das ursprüngliche Caller-Transaktions-/SET-Orakel im Defaultscope bleibt
unverändert. Die beiden Linux-Fehlläufe bleiben FAILED. Nach ausdrücklicher
Benutzerfreigabe bestand der dritte Linux-Guardlauf am korrigierten Stand;
er war der fünfte und letzte native Lauf dieser Welle. Beide ausgewählten
Ziele sind damit im begrenzten Markerscope local/central bestanden.

`Tests/Framework/Test-LifecycleGuardControls.ps1` bestand 27 synthetische
Offlinekontrollen: direkte TestScope-Parameterprüfung einschließlich abgewiesener
Großschreibungsvarianten, fehlende/falsche/mehrfache Fehler, Metadaten-/Sessiondrift,
fehlende Mutationsbeobachtung und fremde Drift vor Restaurierung werden
abgewiesen. Der vorhandene CSV-Workflow führt diese Kontrollen und die neue
Helper-AST-Prüfung im bestehenden statischen Schritt aus. Positive/negative
Pfadfilter, Jobs, Build-/Frameworkgrenzen und Cancellation bleiben unverändert;
kein Labzugriff aus CI. Die zusätzlichen Kontrollen haben einen eigenen
Fail-closed-Zweck; keine erneute lokale Zwölfzielmatrix oder neue Reviewkette.
Verarbeitungs-/Tokenkosten sind unbekannt, es wird keine Ersparnis behauptet.

Produkt, Deployment und CLR-Bytes bleiben unverändert. Der Default-Regressionslauf
erfolgte vor der letzten ausschließlich guardbezogenen Fixturekorrektur; der
Defaultpfad importiert den Guardhelper nicht. Frühere Defaultnachweise bleiben
an ihre ursprünglichen Ausführungen gebunden. Build-/Frameworknachweise werden
nach geprüfter Paket-/Quell-/Toolbindung wiederverwendet, nicht frisch behauptet.
Im Guardscope werden API-/Client-/CrossDB-Consumer-Tests ausdrücklich nicht
ausgeführt. Keine Konfigurations-/Rechte-/Owner-/Infrastrukturänderungen;
Functional-Transport, authentifiziertes TLS und Release weiterhin offen.

## Zusätzliche Compatibility Levels 2026-10-20

Nach Abschluss der Standard-CL-Ergänzung in
[PR339](https://github.com/gecompat/SQL_Server_Toolbelt/pull/339) bestanden
sechs weitere native Gesamtadapterläufe, jeweils im ersten Versuch:

| Plattformen | SQL Server / Lab-Auswahl | Zusätzlich geprüfte CL | Modi |
|---|---|---|---|
| Windows, Linux | 2022 / Windows base mit erlaubtem bereitem CU-Äquivalent, Linux latest | 150 | local, central |
| Windows, Linux | 2025 / Windows base mit erlaubtem bereitem CU-Äquivalent, Linux latest | 150, 160 | local, central |

Der unveränderte öffentliche Labadapter setzte die eigene Testdatenbank pro
Modus auf den ausgewählten CL. Je Lauf bestanden die drei SQLfixtures,
Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, dieselben 29 gezielten
Caller-/SET-/Lock-/Rollback-/Confirm0-Fälle, frischer SC-/UTF8-Consumer und
Uninstall/Repeat. Je äußerer Watchdog, Exit0, vollständige Kanäle und leeres
Stderr sowie frischer unabhängiger Audit mit drei eigenen DBs/einem eigenen
Trusthash abwesend und unveränderten Inputpins bestanden.

Auf den beiden ausgewählten SQL2022-Zielen war eine autorisierte temporäre
CLR-Aktivierung nötig. Vorzustand und vorgemerkter Scope wurden privat erfasst;
nach jedem betroffenen Verbraucher wurde der vollständige Ausgangszustand
unter Driftprüfung restauriert. Die vier SQL2025-Läufe benötigten keine
Konfigurationsänderung. Keine Rechte-, Owner- oder Infrastrukturänderungen;
`clr strict security` blieb aktiv.

Paket und ursprüngliche Build-/Frameworknachweise aus der ersten Welle vom
2026-10-20 wurden nach erneuter Source-/Binary-/Runner-/Harness-/Helper-/Compiler-/
Frameworkreferenzbindung wiederverwendet; kein neuer lokaler Build oder
Frameworklauf. Die Standard-CL-Nachweise wurden ebenfalls nach aktueller
Inputprüfung weiterverwendet und nicht erneut ausgeführt.

Damit ist der begrenzte Gesamtadapter am aktuellen Quellen-/Abhängigkeitsstand
auf allen zwölf zulässigen Kombinationen bestanden: Windows und Linux jeweils
SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170, lokal und zentral.
Die je 29 gezielten Lifecyclefälle bleiben derselbe Teilumfang; Minimalrechte,
Fremdslot-/Driftvollmatrix, weitere Collations, Heap, authentifiziertes TLS und
Release bleiben offen. `partially validated`, `unreleased` bleiben unverändert;
aktuelle Head-/Main-CI ist ein eigener Integrationsgate.

## Standard-CL-Bindung 2026-10-20

Nach [PR338](https://github.com/gecompat/SQL_Server_Toolbelt/pull/338) bestanden
zwei zusätzliche native Läufe mit den aktuellen ResultTable-Abhängigkeiten:
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent, jeweils local/central im ersten nativen Versuch. Beide Läufe
verwenden das unveränderte Paket aus der vorherigen Vierzielwelle. Dessen
Source-/Binarybindungen sowie Frameworkrunner, Harness, Prozesshelfer,
Compiler und .NET48-Referenzen wurden vor Wiederverwendung geprüft;
Build und Framework wurden hier nicht erneut ausgeführt.

Je Ziel bestanden drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf
Slots/drei Bindings, dieselben 29 gezielten Lifecyclefälle, frischer
SC-/UTF8-Consumer und Uninstall/Repeat. Äußerer Watchdog, Exit0, vollständige
Kanäle und leeres Stderr bestanden; je frische unabhängige Verbindung bestätigt
drei eigene DBs/einen eigenen Trusthash abwesend und unveränderte Inputpins.
Keine Konfigurations-, Rechte-, Owner- oder Infrastrukturänderungen.

Zusammen mit den vier Läufen aus PR338 ist damit der begrenzte Gesamtadapter
auf allen sechs physischen Windows-/Linux-/SQL2019/2022/2025-Kombinationen
mit deren Standard-CL150/160/170 am aktuellen Quellen-/Abhängigkeitsstand
bestanden. Die früheren Läufe vom 2026-10-05 bleiben historische Evidenz.
Die zusätzlichen CL-Nachweise stehen in der getrennten Folgewelle oben.
Minimalrechte, Fremdslot-/Driftvollmatrix, weitere Collations, Heap und Release
bleiben offen. Functional-Transport qualifiziert kein
authentifiziertes TLS; aktuelle Head-/Main-CI bleibt ein separater Gate.

## Vorherige ergänzende native Zielwelle 2026-10-20

Der unveränderte öffentliche Adapter `Tests/CI/run-csv-memory-lab.ps1` bestand
auf vier zusätzlich ausgewählten physischen Labzielen, jeweils im ersten
nativen Versuch:

| Lab-Auswahl | Compatibility Level | Modi | Ergebnis |
|---|---|---|---|
| Windows / SQL2019 / base mit erlaubtem bereitem CU-Äquivalent | 150 | local, central | bestanden |
| Windows / SQL2022 / base mit erlaubtem bereitem CU-Äquivalent | 160 | local, central | bestanden |
| Linux / SQL2022 / latest | 160 | local, central | bestanden |
| Linux / SQL2025 / latest | 170 | local, central | bestanden |

Vertrag und Schema wurden vor Auswahl validiert, die tatsächliche Plattform
und SQL-Hauptversion vor jedem Lauf geprüft. Windows-base verwendet die
projektspezifisch erlaubte deterministische Auswahl bereiter base-/CU-Ziele.
Alle vier Läufe konsumierten dasselbe neue Releasepaket: zwei vollständige
.NET48-Builds am selben lokalen Buildort lieferten identische SHA2-512-Bytes.
`Scripts/New-ClrReleaseArtifacts.ps1` band das erste Binary an aktuelle Quellen;
`Tests/Framework/run-framework-csv.ps1` bestand mit diesen gepackten Bytes in
en-US, de-DE und tr-TR einschließlich IL-/NoIO-Orakeln und harter Grenzphase
in en-US. Statische Verträge und Adapter-AST bestanden ebenfalls.

Je Ziel bestanden beide Modi mit `Contract.Tests.sql`, `Safety.Tests.sql`,
`Lifecycle.Tests.sql`, Clientmetadaten, Clean/Repeat, fünf Slots/drei CLR-Bindings,
29 gezielten Caller-/SET-/Lock-/Rollback-/Confirm0-Fällen, frischem
SC-/UTF8-Consumer und Uninstall/Repeat. Die 29 Fälle zählen je Lauf dieselben
gezielten Prüfungen und keine vollständige Fremdslot-/Driftmatrix.
Der äußere Watchdog begrenzte jeden tatsächlich gestarteten eigenen Prozess;
Exit0, vollständig konsumierte Ausgabekanäle und leeres Stderr bestanden.
Nach Prozessende bestätigte je eine frische unabhängige Verbindung drei eigene
Datenbanken und einen eigenen Trusthash abwesend sowie unveränderte Inputpins.

Die notwendige temporäre CLR-Testkonfiguration auf drei ausgewählten Zielen
erfolgte unter der bestehenden Benutzerfreigabe. Vorzustand und zuvor
vorgemerkter Konfigurationsscope blieben ausschließlich im privaten Journal;
nach Abschluss aller eigenen Verbraucher wurde der vollständige Ausgangszustand
unter Driftprüfung wiederhergestellt. `clr strict security` blieb aktiv;
keine Rechte-, Owner- oder Lab-Infrastrukturänderungen.
Der vierte Lauf benötigte keine Konfigurationsänderung.
Die äußeren Vorprüfungen auf Windows2019 und Windows2022 hatten zuvor wegen
der fehlenden CLR-Voraussetzung gestoppt, jeweils vor Aufruf des nativen
Adapters und ohne Testressourcen anzulegen.

Diese Welle ändert keine Produkt-, Deployment-, CLR-, Adapter- oder
Testorakelquellen. In dieser Vierzielwelle wurden die historischen Läufe auf
Linux2019/CL150 und Windows2025/CL170 nicht neu ausgeführt; ihr damaliger
ResultTable-Stand wird erst durch die getrennte Standard-CL-Ergänzung oben
aktuell qualifiziert. Zusätzliche CLs,
Minimalrechte, Fremdslot-/Driftvollmatrix, weitere Collations, Heap und Release
bleiben offen. Transport war `Functional`; authentifiziertes TLS ist
`not executed`. Aktuelle Head-/Main-CI ist ein gesonderter Integrationsgate.

## Historische Nachweise

Testwartung 2026-10-09 – Quellenstand: Der Frameworkrunner kopiert die gepinnte
DLL mit festem 64-KiB-Puffer, `Int64`-Längenbindung und exakter EOF-Prüfung statt
eines vollständigen DLL-Bytearrays. Bestehende Kopie-/Endpins, Harnessorakel,
Kulturen und Prozessbudgets bleiben erhalten. Fokussierte Prüfung des neuen Kopierblocks: sechs synthetische Fälle **PASS**
(0, 1, 65536 und 65537 Bytes, vorhandenes Ziel abgewiesen und erhalten,
falscher Hash abgewiesen). Exakte neue Head-CI **NOT_EXECUTED**; kein neuer
Framework-, SQL-, Heap- oder Cleanup-PASS. Die folgenden historischen Abnahmen behalten
unverändert ihren damaligen Scope; Modulstatus und Produkt/API unverändert.

Die statischen Verträge bestanden. `Tests/Framework/run-framework-csv.ps1`
qualifizierte das exakt gepackte aktuelle .NET48-Binary in en-US, de-DE und
tr-TR mit unabhängigen Orakeln sowie IL-/NoIO-Prüfungen; die harte Grenzphase
lief in en-US. Das ist ein CLR-Nachweis ohne SQL-/Client-/Lifecycle- oder
Heapqualifikation.
Der CSV-Qualifikationsworkflow baut das Produkt auf demselben Runner zweimal
vollständig neu und vergleicht die SHA2-512-Trustbytes des zweiten Builds
mit dem unveränderten ersten Releasepaket. Das belegt bei Erfolg nur
Build-Reproduzierbarkeit innerhalb dieses Runnerlaufs, nicht zwischen Hosts
oder eine native SQL-Qualifikation.

Der achte öffentliche Lauf von `Tests/CI/run-csv-memory-lab.ps1` bestand am
2026-10-05 auf SQL Server 2019 Linux/latest CL150 lokal und zentral mit dem
finalen gepackten Produktstand und identischen CLR-Bytes. Alle drei SQLfixtures,
Clientmetadaten, Clean/Repeat, fünf Slots/drei CLR-Bindings, Caller-/SET-/AppLock-/
Rollbackfälle, zentraler Confirm0-Schutz, Uninstall/Repeat und Nutzung aus frischer
SC-/UTF8-Consumerdatenbank bestanden. Der Lifecycle-Zähler29 bezeichnet die
konkreten Caller-/Lock-/Rollback-/Confirm0-Prüfungen, keine vollständige Fremdslot-
oder Driftmatrix. Der Prozess endete mit Exit0, vollständiger Kanalerfassung und
leerem Stderr. Eigener Cleanup im Lauf bestand; der frische unabhängige Audit
dieses achten Laufs war zunächst ausstehend. Der anschließende frische Linuxaudit
bestätigt drei eigene Datenbanken und einen eigenen Trusthash abwesend; keine
Konfigurations-/Rechteänderungen.

Der gleiche finale öffentliche Adapter und dasselbe Produkt-/Binarypaar bestanden
auch auf Windows2025/exakt CU8 CL170 local/central einschließlich aller drei
SQLfixtures, Client, SC-/UTF8-Consumer, Clean/Repeat, fünf Slots/drei Bindings,
29 gezielten Lifecycleprüfungen und Uninstall/Repeat. Exit0, vollständige Kanäle,
leeres Stderr und Cleanup im Lauf bestanden. Der frische unabhängige Windowsaudit
bestand anschließend: drei eigene DBs/ein eigener Trusthash abwesend, keine
Konfigurations-/Rechteänderungen. Weitere Ziele, Minimalrechte, Fremdslot-/Driftvollmatrix und Heap
bleiben offen.

Historische native Versuche bleiben FAILED: zunächst Syntax, danach LF-Padding
und im fünften Gesamtlauf eine generische Assertion in `Metadata.Tests.ps1`.
Der fünfte Lauf belegte lediglich lokale Clean/Repeat-/Binding- und SQLfixture-
Teilresultate. Die Produktkorrekturen betreffen das NCHAR-CASE-Padding des LF-
Writers und drei deklarierte NOT-NULL-Spalten im Help-first-Pfad. Erst der achte
Lauf liefert den genannten Gesamtadapter-PASS. Zum damaligen Stand blieben
SQL Server 2022, übrige Windows-/Linux-Ziele und Compatibility Levels sowie
weitere Collations offen; die Ergänzung vom 2026-10-20 steht oben getrennt.

Zusätzlicher begrenzter Marker-Nachweis am 2026-10-05: ein mechanisch vom
öffentlichen Labadapter abgeleiteter, hashgebundener Adapter prüfte ausschließlich
zwei synthetische Typdriftfälle auf Linux2019/latest CL150 lokal. Deploy und
Uninstall wiesen `Toolbelt.Managed` als `int` statt des ursprünglichen `bit`
auf `USP_ParseCsv` jeweils mit SQL55324/state5 ab; vollständige Metadaten blieben
unverändert und der Transaktionszustand neutral. Der eigene Marker wurde unter
exakter Identitäts-/Driftprüfung restauriert. Exit0, vollständige Kanäle und
leeres Stderr sowie der frische unabhängige Audit bestanden: eine eigene DB und
ein eigener Trusthash abwesend, keine Konfigurations-/Rechteänderungen.
Diese zwei Fälle sind ein separater Teilnachweis; sie erweitern weder den
29-Fall-Zähler noch die API-/Client-/Central-/Windows- oder vollständige
Fremdslot-/Driftmatrixqualifikation.

[PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169) wurde am
exakten Head `89f36f848ab68a1a72898ddd5f081fc47740f119` mit fünf erfolgreichen
Checks gemergt: CSV Memory Qualification, Documentation Incremental sowie
ZIP Static contract, .NET48 build und Linux SQL2022 runtime. Der CSV-Workflow
qualifiziert seinen registrierten Framework-/statischen Scope; der ZIP-Runtime-
Check ist kein CSV-SQL2022-Nachweis. Die unveränderten kanonischen CSV-Quellen
binden diese historische Head-CI an denselben Source-Stand; lokale Produktbytes
wurden getrennt qualifiziert. Neue PR-Heads benötigen
ihre eigenen Checks.

Reproduzierbare Prüfpunkte:

- `python Modules/toolbelt.file.csv-memory/Tests/Static/validate_contract.py`
- `Clr/Toolbelt.File.CsvMemory.csproj`: eigener begrenzter .NET48-Build;
  `Scripts/New-ClrReleaseArtifacts.ps1` konsumiert dessen exakte Bytes.
- `Tests/Framework/run-framework-csv.ps1`: exakt gepacktes Binary mit Hashbindung,
  begrenzte unabhängige Orakel und IL-/NoIO-Qualifikation.
- `Tests/CI/run-csv-memory-lab.ps1`: schema-validierte explizite Labziele,
  eigener DB-/Trustscope, private Wiederherstellungsjournale, begrenzte SQL- und
  Clientprüfungen und eigenes Cleanup. Externer Root-Watchdog muss den tatsächlich
  gestarteten eigenen Prozess zeitlich begrenzen und beide Kanäle vollständig
  konsumieren; ein PASS-Text allein ist kein Erfolg.
- `.github/workflows/csv-memory-qualification.yml`: separater Nachweis am exakten PR-Head.

Keine Konfiguration, Rechte, Owner oder Lab-Infrastruktur automatisch ändern.
Ein bestehender Trusteintrag bleibt vollständig unverändert; eigene Einträge
werden nur bei gleicher Identität und ohne Verbraucher entfernt. Keine Adoption
fremder Journale oder Ressourcen. Frische unabhängige Prüfung nach dem Prozessende
belegt den eigenen Cleanup, ohne reale Laufzeitdaten in das Repository zu übernehmen.

Weitere Versionen, Plattformen, Minimalrechte, Ceiling- und Heapfälle bleiben
sichtbar offen bis zu einer tatsächlich erfolgreichen begrenzten Qualifikation.
Die [Matrix](CSV_TEST_MATRIX.md) trennt erfolgreiche Teilprüfungen und offene
Pflichtscopes. Manifest-Evidenz enthält keine privaten Journale, Pfade oder Logs.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-21`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope cell-ceilings`
- Scope: Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS: acht gezählte Fälle je Modus,16 je Ziel, darunter je acht SQL55303/state1-Abweisungen. Parser/Writer genau1000000 Zellen im Raster1000x1000 sowie gültiges Rechteck9901x101 mit genau1000001 Zellen, ohne/mit Header; übrige Budgets nicht bindend. Vollständige Raster-/Wert-/Textbyteorakel und unabhängige Writer-Übergrenzquelle, exakte Ausgabemetadaten und Quell-/Zielerhalt. Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Rechte/Runtimeinputs unverändert. 559 Offlinekontrollen, acht SQL150-Fixturephasen und AST/Static PASS. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; vorhandenes Paket an manifestierte Quellen/exakte Binarybytes gebunden, kein neuer lokaler Build-/Frameworklauf. Keine neue Default-/Clientabnahme, Textvollgrenze, Heap-, Minimalrechte-, Gesamtmatrix-, authentifizierte TLS- oder Releasequalifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
