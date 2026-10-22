# CSV-Prüfungen und Evidenz

Diese Anleitung richtet sich an Entwickler, die einen ausdrücklich gewählten
CSV-Testumfang prüfen. Modulstatus und Unterstützung bestimmen das
[Modulmanifest](../module.yaml), die [Modulbeschreibung](../README.md) und die
[Matrix](CSV_TEST_MATRIX.md). Historische Nachweise qualifizieren ausschließlich
ihren genannten Stand; eine neue Welle übernimmt daraus keinen Gesamt-PASS.

## Testumfang auswählen

1. Bestimme den betroffenen Vertrag und den festen Kandidaten. Die öffentliche
   Syntax des [Labdrivers](../../../Tests/CI/run-csv-memory-lab.ps1) ist maßgeblich:
   `TestScope` ist eine geschlossene, case-sensitive Auswahl. Seine Zuordnung
   nennt die konkrete Runtime-Fixture; die Matrix erläutert deren Grenzen.
2. Beginne mit den betroffenen Offlineprüfungen. Vom Repository-Root aus:

   ```powershell
   python Modules/toolbelt.file.csv-memory/Tests/Static/validate_contract.py
   pwsh -NoProfile -File Modules/toolbelt.file.csv-memory/Tests/Framework/Test-LifecycleGuardControls.ps1
   ```

   Erwartet werden erfolgreicher Exitcode und die jeweiligen begrenzten
   Kontrollzähler. Diese Prüfungen verwenden kein Lab und belegen keine
   native SQL-, Framework-Binary- oder Heapqualifikation.
3. Für Binary-/Frameworktests das exakt gebaute und gepackte Releaseartefakt
   verwenden. [Modulbeschreibung](../README.md) und
   [Frameworkrunner](Framework/run-framework-csv.ps1) beschreiben Hashbindung,
   unabhängige Orakel und Grenzen. Ein fremdes SAFE-Binary genügt nicht.
4. Für native Tests zuerst die [Lab- und Sicherheitsregeln](../../../AGENTS.md)
   prüfen: schema-validierter Vertrag, ausdrücklich ausgewählte bereite Ziele,
   bestehende Rechte sowie separat autorisierte Konfigurations-/Truständerungen.
   Der Driver benötigt `ReleaseDirectory`, einen privaten `JournalManifestPath`,
   `ExpectedPromptSHA256`, `ExpectedDriverSHA256` und `ExpectedAssemblySHA512`.
   Diese Werte werden vor dem Lauf am gewählten Input ermittelt und gebunden;
   Zugangsdaten, konkrete Endpoints und private Journale bleiben lokal.
5. `Platform`, `Version`, `Patch`, `CompatibilityLevel`, `DeploymentModes` und
   `TestScope` ausdrücklich zum gewählten Scope setzen. `default` prüft den
   registrierten Standardumfang; ein gezielter Scope ersetzt diesen nicht.
   Fehler-/Erhaltungswellen bestehen aus acht SQLphasen je Installationsmodus.
   Nur der abschließende typisierte Witness zählt; vorzeitige oder unvollständige
   Resultsets sind Fehler. Der tatsächliche Driver und die Matrix bestimmen
   auch die jeweils getrennten Funktions-/Lifecyclezähler.

## Ergebnis und Bereinigung prüfen

Ein PASS-Text allein ist kein Erfolg. Prüfe Exitcode, vollständige stdout-/
stderr-Erfassung, erwartete Modi und Zähler, unveränderte eingefrorene Inputs
und den ursprünglichen Transaktionszustand. Ein externer Watchdog begrenzt
nur den eigenen Prozess; Arbeitsdeadline und Cleanupreserve bleiben getrennt.
Nach Prozessende weist ein frischer separater Audit den eigenen Datenbank-/
Trustcleanup nach. Vorgefundene oder inzwischen fremd verwendete Einträge
werden nicht adoptiert oder gelöscht; Drift und unklare Ownership blockieren
nur die entsprechende Änderung/Bereinigung.

Bei Abweichungen den ursprünglichen Fehler und den privaten Journalzustand
lokal sichern, gegen Fixture und Fehlervertrag prüfen und gezielt korrigieren.
Ein Fehllauf bleibt ein Fehllauf; keine blinden Wiederholungen und kein
Umschalten von Trust-/Transportwerten. Für Argument- und Formfehler verlangt
die jeweilige Fixture ausdrücklich den genannten Fehlercode und State.
Die [Matrix](CSV_TEST_MATRIX.md) trennt ausgeführte Teilprüfungen von offenen
Scopes; die [CI](../../../.github/workflows/csv-memory-qualification.yml)
qualifiziert ihren eigenen exakten Head. Lokale Nativevidenz und CI werden
getrennt gebunden. Rohdaten und Wiederherstellungsjournale gehören nicht ins
Repository oder in den PR.

## Datierte Qualifikationsnachweise

Die folgenden unveränderten früheren Abschnitte dokumentieren ihre damaligen
Kandidaten, Fehlversuche und Einschränkungen. Ihre bisherigen Überschriften
und Linkanker bleiben erhalten. Neue Wellen ergänzen ausschließlich diesen
Evidenzbereich; Anleitung und Auswahl stehen davor.

<!-- CSV_WAVE_EVIDENCE:BEGIN -->
### Ungewöhnliche Caller-Tempnamen mit korrektem Replace und Append 2026-10-22

'-TestScope quoted-temp-name-preservation': Acht erfolgreiche Fälle je Modus: Parserziele mit Punkt/Klammer beziehungsweise Leerzeichen/Klammer, Writerquelle mit Punkt/Klammer und Writerziel mit Leerzeichen/Klammer, jeweils KeepData=0/1. Direkte SQL-Bezeichner werden korrekt geklammert, APIargumente behalten ihren unveränderten Raw-Namen; Objekt-IDs werden über den qualifizierten geklammerten Namen aufgelöst. Unabhängige DATA-Quelle16777160Bytes und vollständiger CRLF-Input/Output16777164Bytes liegen unter16MiB. Je Fall eigener16MiB-Altzielwert: Replace entfernt, Append erhält ihn samt alten Schlüsseln und Metadaten vollständig. Quelle bleibt read-only; beide IDs und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue allgemeine Namens-, Alias- oder Bytegrenzqualifikation.

Acht positive Phasen: vier konkrete ungewöhnliche lokale Namensformen jeweils Replace/Append. Return0, vollständige neue/alte Zeilen und Bytewerte, Metadaten, Quelle/IDs/Kataloge, getrennte Neutralität und eigener Fallcleanup; nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1806 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle mit ungewöhnlichen Caller-Tempnamen und korrektem Replace/Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Abschließende leere CSV-Felder mit korrektem Replace und Append 2026-10-22

'-TestScope trailing-empty-field-preservation': Acht erfolgreiche Fälle je Modus: Parser mit leerem letztem Feld am EOF beziehungsweise vor CRLF und Writer mit einem beziehungsweise zwei abschließenden leeren Feldern, jeweils KeepData=0/1. Eine unabhängig gesetzte große erste DATA-Zelle bleibt vollständig enthalten, Quelle und Text liegen unter16MiB. Leere Felder bleiben ausdrücklich nicht-NULL-leer; EOF und finaler Recordabschluss erzeugen keinen zusätzlichen Record. Writer liefert exakt die abschließenden Separatoren und CRLF mit DataRows1 und ColumnCount2 beziehungsweise3. Vor jeder Operation eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig. Quelleninhalt, Identitäten und bidirektionale Katalogsnapshots bleiben erhalten. Keine neue Bytegrenzabnahme.

Acht positive SQLphasen: vier EOF-/Record-/Writerformen jeweils Replace/Append. Return0, vollständige große Zellbytes, ausdrückliche Nicht-NULL-Leerwerte, exakte Zeilenzahl/Ordinals/Outputbytes/Metadaten, getrennte Neutralität und Fallcleanup; nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1766 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu Abschließende leere CSV-Felder mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### NullToken-Text und SQL-NULL mit korrektem Replace und Append 2026-10-22

'-TestScope null-token-value-preservation': Acht erfolgreiche Fälle je Modus: Parser und Writer mit aktivem Tokenwort „NULL“ beziehungsweise „NULL “ mit abschließendem Leerzeichen, jeweils KeepData=0/1. Unquoted Token wird SQL-NULL, quoted Token bleibt vollständiger Text; beim gepaddeten Token bleibt ungepaddetes NULL ebenfalls Text. Eine unabhängig gesetzte große zusätzliche DATA-Zelle ist vollständig enthalten, Quelle und Text bleiben unter16MiB. Writer liefert exakt kanonisches Quoting und CRLF sowie DataRows1 und die vollständige Breite3 beziehungsweise4. Vor jeder Operation eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig. Quelleninhalt, Identitäten und bidirektionale Katalogsnapshots bleiben erhalten. Keine neue Bytegrenzabnahme.

Acht positive SQLphasen: beide APIs und zwei Tokenformen, jeweils Replace/Append. Return0, NULL-Prädikate getrennt von vollständigen Textbyte-/Längenprüfungen, alle neuen/alten Zeilen und Metadaten, neutrale Transaktion und Fallcleanup; nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1726 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu NullToken-Text und SQL-NULL mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### HEADER ohne DATA mit korrektem Replace und Append 2026-10-22

'-TestScope header-only-preservation': Acht erfolgreiche Fälle je Modus: Parser und Writer mit einem beziehungsweise zwei HEADER-Feldern ohne DATA, jeweils KeepData=0/1. Ein unabhängig gesetzter großer Headerwert bleibt vollständig erhalten, die Quellencharge liegt unter16MiB. Parser liefert nur HEADER-Zellen mit RowOrdinal0 und vollständigen Spaltenordinals; Writer liefert genau eine vollständige CRLF-Ausgabe mit DataRows0 und ColumnCount1 beziehungsweise2. Vor jeder Operation steht ein eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn samt alten Schlüsseln und Metadaten. Quelleninhalt und beide kanonischen Schemata bleiben unverändert. Keine neue Bytegrenzabnahme.

Acht positive SQLphasen: beide APIs, eine oder zwei Headerspalten, jeweils Replace/Append. Returncode0, alle vollständigen neuen und gegebenenfalls alten Zeilen, binäre Texte und Längen, Metadaten, Identitäten/Kataloge, getrennte Neutralität und Fallcleanup; nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1686 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu HEADER ohne DATA mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Reservierte Temppräfixe mit vollem Callerwerterhalt 2026-10-22

'-TestScope reserved-temp-prefix-preservation': Vier bestehende Präfixabweisungen jeweils KeepData=0/1: reserviertes Parserziel, reserviertes Writerziel, reservierte Writerquelle und Writerquelle mit gemischtem #TbX_-Präfix. Acht ausschließlich SQL55304/state1-Abweisungen je Modus. Der jeweilige16MiB-Altzielwert und die unabhängig gesetzte gültige synthetische Callerquelle unter16MiB bleiben bytegenau erhalten. Parseraufrufe erhalten separat gesetzten16MiB-Text. Beide Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert; eigener Fallaufbau und Cleanup vor dem nächsten Fall. Keine gesamte Namespace- oder neue Bytegrenzabnahme.

Acht Phasen: vier konkrete Präfixformen jeweils Replace/Append. Exakte55304/state1-Signatur, volle Quell-/Altzielwerte, getrennte neutrale Transaktion und Fallcleanup vor Fortschritt. Nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1646 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Writer-Quellnamenabweisung mit vollem Callerwerterhalt 2026-10-22

'-TestScope writer-local-source-name-preservation': Vier bestehende ungültige oder fehlende Writerquellen jeweils KeepData=0/1: NULL, globaler Tempname, Name ohne lokalen Praefix und fehlende lokale Quelle. Acht ausschließlich SQL55304/state1-Abweisungen je Modus. Vollständiger16MiB-Altoutput und eine unabhängig vorhandene gültige synthetische Callerquelle unter16MiB bleiben bytegenau erhalten, einschließlich Objektidentitäten und bidirektionaler Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots. Die ungültig benannten Quellen werden weder angelegt noch als gültige Eingaben qualifiziert; erwartete Abwesenheit bleibt erhalten. Keine neue Bytegrenzabnahme.

Acht SQLphasen: vier Quellnamensformen jeweils Replace/Append. Exakte55304/state1-Signatur, vollständiger Callerquell-/Altzielerhalt, getrennte Transaktionsneutralität, ausdrückliche Abwesenheitszeugen für fehlende lokale/globale Namen und nur ein finaler typisierter8er-Abschluss.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1606 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Reservierte Writer-Tempnamen mit vollem Callerwerterhalt 2026-10-22

'-TestScope reserved-temp-namespace-preservation': Vier einzeln belegte private Writerslots Input, Measure, Fragments und Result, jeweils KeepData=0/1. Acht ausschließlich SQL55304/state1-Abweisungen je Modus vor der Workbatch. Die synthetische Callerprobe besitzt absichtlich fremdes Schema und einen unabhängig gesetzten16MiB-Wert; dieser sowie gültige DATA-Quelle unter16MiB und vollständiger16MiB-Altoutput bleiben bytegenau erhalten. Alle drei Objektidentitäten und bidirektionalen Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Jede eigene Probe wird vor dem nächsten Fall entfernt. Kein vollständiger Namespace-, Parser- oder neuer Bytegrenzumfang.

Acht SQLphasen: vier konkrete reservierte Writer-Slots jeweils Replace/Append. Exakte Fehlernummer/State, volle Probe-/Quell-/Zielwerte und getrennte neutrale Transaktion vor und nach jeder Abweisung. Fortschritt erst nach allen Orakeln und eigener Probeentfernung; nur finaler typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1566 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Leere CSV-Ergebnisse mit korrektem Replace und Append 2026-10-22

'-TestScope empty-result-preservation': Acht erfolgreiche Leerresultatfälle je Modus: Parser mit leerem Text beziehungsweise quotierter leerer Zelle sowie Writer mit leerer Quelle beziehungsweise einer nicht-NULL-leeren DATA-Zelle, jeweils KeepData=0/1. Parser liefert keine Zeile beziehungsweise eine nicht-NULL-leere Zelle; Writer liefert immer eine Outputzeile mit leerem Text und Metadaten0/0 beziehungsweise CRLF mit Metadaten1/1. Vor jeder Operation wird ein vollständiger16MiB-Altwert unabhängig gesetzt. Replace entfernt diesen vertragsgemäß, Append erhält ihn vollständig samt ursprünglichen Metadaten. Beide Zielschemas und die Quelle behalten Objektidentität sowie bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots. Keine beabsichtigte SQL-Abweisung oder neue Bytegrenzabnahme.

Acht positive SQLphasen je Modus. Jeder Aufruf muss Returncode0 liefern; unabhängige Orakel prüfen vollständige alte Werte nur bei Append, korrekte Ersetzung bei Replace, leere Strings getrennt von SQL-NULL, alle Ergebniszeilen und Metadaten. Transaktionsneutralität isoliert, Quelleninhalt unverändert, beide Zielschemas erhalten. Nur abschließender typisierter8er-Witness.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1526 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich16 positiver Leerresultat-/Replace-/Appendfälle; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Writer-Headerabweisung mit vollem Datenerhalt 2026-10-22

'-TestScope writer-header-preservation': Vier bestehende ungültige HEADER-Formen jeweils mit KeepData=0/1: HEADER bei HasHeader=0, fehlender HEADER bei HasHeader=1, falscher HEADER-RowOrdinal und HEADER-Spaltenlücke. Acht ausschließlich SQL55306/state1-Abweisungen je Modus. Alle unabhängig gesetzten Quellzeilen einschließlich vollständigem großem Wert unter16MiB sowie vorheriger16MiB-Altoutput bleiben erhalten. Beide Objektidentitäten und bidirektionale Quellen-/Zielspalten-, Index-, Indexspalten- und Checkconstraint-Snapshots unverändert. Keine neue Bytegrenzabnahme.

Acht SQLphasen je Modus: vier HEADER-Formen jeweils Replace/Append. Jede Quellzeile vollständig mit Multiplizität geprüft, genaue Fehlernummer und State, Transaktionsneutralität und nur ein finaler typisierter8er-Abschluss.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1486 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55306/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Writer-Argumentabweisung mit vollem Datenerhalt 2026-10-22

'-TestScope writer-argument-preservation': Vier bestehende Writer-Argumentfehler jeweils mit KeepData=0/1: HasHeader=NULL, LineEnding=NULL, kleingeschriebenes lf und zweistelliger Separator. Acht ausschließlich SQL55300/state1-Abweisungen je Modus. Unabhängig gesetzte gültige DATA-Quelle unter16MiB und vollständiger16MiB-Altoutput bleiben bytegenau erhalten. Beide Objektidentitäten und bidirektionale Quellen-/Zielspalten-, Index-, Indexspalten- und Checkconstraint-Snapshots bleiben unverändert. Keine neue Bytegrenzabnahme.

Acht SQLphasen je Modus: vier Argumentformen jeweils Replace/Append. Vollständige unabhängig gesetzte Quelle und alter Output, getrennte Neutralität, genaue Fehlernummer/State und ein typisierter8er-Abschluss.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1446 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55300/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Parser-Argumentabweisung mit vollem Zielerhalt 2026-10-22

'-TestScope parser-argument-preservation': Vier bestehende Parser-Argumentfehler jeweils mit KeepData=0/1: Text=NULL, HasHeader=NULL, zweistelliger Separator und leerer NullToken. Acht ausschließlich SQL55300/state1-Abweisungen je Modus. Vorheriger synthetischer Zellwert genau16777216 UTF16-Bytes bleibt vollständig samt Zeilenzahl, Schlüsseln, Objektidentität und bidirektionalen Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots erhalten. Die drei Fälle mit vorhandenem Text verwenden unabhängig gesetzten16MiB-Input; der fehlende Text bleibt ausdrücklich NULL. Keine neue allgemeine Bytegrenzabnahme.

Acht SQLphasen je Modus: vier Argumentformen jeweils Replace/Append. Exakte Fehlernummer und State, voller Altzielwert und neutrale Transaktion werden getrennt geprüft. Ein typisierter8er-Abschluss, keine vorzeitigen Resultsets. Der Testlesepfad steht vor den unverändert datierten Nachweisen; bisherige Linkanker und generierte Evidenz bleiben erhalten.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1406 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55300/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.


Stand 2026-10-21: Version1.0.0 ist implementiert, `partially validated` und
unveröffentlicht. CI und native Labnachweise besitzen getrennte Bindungen;
andere SAFE-Assemblies qualifizieren diese CSV-Bytes nicht.

### Writer-Quellmetadatenabweisung mit vollem Datenerhalt 2026-10-22

'-TestScope source-metadata-preservation': Acht unabhängig gesetzte nicht unterstützte Writer-Quellmetadaten: fünfte Spalte, umbenannte Value-Spalte, RowKind als nvarchar beziehungsweise varchar(7), RowOrdinal als int, ColumnOrdinal als bigint, Value als nvarchar(4000) beziehungsweise varchar(max). Vier KeepData=0- und vier KeepData=1-Fälle. Ausschließlich SQL55305/state1. Vollständiger16MiB-Altoutput und alle Quellwerte werden in ihren tatsächlichen Datentypen bytegenau erhalten; für nvarchar(4000) bewusst4000 Zeichen, andere Value-Fixtures8388580 ASCII-Zeichen. Beide Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots von Quelle und Ziel unverändert. Keine einheitliche16MiB-Quellencharge oder neue Bytegrenzabnahme behauptet.

Acht SQLphasen je Modus, ausschließlich55305/state1. Jede Quelle hat genau eine ausgewählte Metadatenabweichung und einen vollständig geprüften synthetischen Payload. Typgerechte Längen-/Binärorakel vermeiden implizite UTF16-/varchar-Verwechslung. Vier Replace-/vier Appendfälle, voller16MiB-Altoutput, beide Metadatensnapshots, isolierte Neutralität und genau ein typisierter Abschluss.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1366 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55305/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### NULL-Darstellungsabweisung mit vollem Datenerhalt 2026-10-22

'-TestScope null-representation-preservation': SQL-NULL in DATA ohne NullToken und SQL-NULL im HEADER trotz aktiviertem NullToken, jeweils in ein- und zweispaltigen beziehungsweise ein- und zweizeiligen gültigen Zellrastern. Vier Formen jeweils mit KeepData=0/1, acht Fälle je Modus. Ausschließlich SQL55307/state1; vollständiger16MiB-Altoutput und alle unabhängig gesetzten Quellwerte einschließlich tatsächlicher SQL-NULLs bleiben erhalten. Quellencharge unter16MiB, Quell-/Zielidentitäten und bidirektionale Zielspalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue Bytegrenz- oder allgemeine Clientabnahme.

Acht SQLphasen je Modus: vier NULL-Darstellungsfehler jeweils Replace/Append. Alle ausschließlich55307/state1. Vollständige Quellzeilen, SQL-NULL getrennt von Text, vollständiger16MiB-Altoutput und Zielmetadaten vor/nach geprüft. Transaktionsneutralität isoliert; nur abschließender typisierter Witness als Resultset.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1326 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55307/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### CSV-Constraintfehler mit vollem Ziel- und Callerarbeitserhalt 2026-10-22

'-TestScope target-constraint-preservation': Fehlschlagende CHECK-Zielinserts der bestehenden Parser-/Writerprozeduren bei vollständigem16MiB-Parserinput beziehungsweise vollständigem16MiB-Writeroutput. Je API KeepData=0/1 und eigene beziehungsweise committable Callertransaktion mit XACT_ABORT OFF: acht Fälle je Modus, ausschließlich ursprünglicher Enginefehler SQL547 ohne Behauptung eines festen ERROR_STATE. Vollständiger16MiB-Altzielwert und unabhängige Writerquelle bleiben erhalten; Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Caller-Sentinel und eigene Commit-/Rollbackentscheidung werden geprüft, ursprüngliches XACT_ABORT wiederhergestellt.

Acht SQLphasen je Modus: Parser/Writer jeweils KeepData0/1 mit und ohne Callertransaktion. CHECK-Insert muss ausschließlich547 werfen; Schema ist passend. Vollständiger Ziel-/Quellerhalt und unabhängige Callerarbeit werden nach dem Prozedurfehler und nach eigenem Callerabschluss geprüft. Zustandswitnesses isoliert, XACT_ABORT wiederhergestellt. Kein fester Fehlerstate und keine doomed-Transaktionsmatrix behauptet.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1286 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL547-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Writer-Zellabweisung mit vollem Quell- und Zielerhalt 2026-10-22

'-TestScope writer-cell-preservation': Acht unabhängig gesetzte ungültige Writer-Zellformen: falscher RowKind, RowOrdinal0/negativ, ColumnOrdinal0/negativ, doppelter Zellschlüssel, Lücke in Zeilenordinals und Lücke in Spaltenordinals. Vier Fälle mit KeepData=0 und vier mit1. Quellencharge jeweils unter16MiB, vorheriger vollständiger Writeroutput genau16777216 UTF16-Bytes. Ausschließlich SQL55306/state1; alle Quellzeilen mit vollständigen Werten und Multiplizität sowie alter Output bleiben erhalten. Quellen-/Zielidentität und bidirektionale Zielspalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue Bytegrenzabnahme.

Acht SQLphasen je Modus, ausschließlich55306/state1. Ungültige Quellen werden unabhängig vom Parser gesetzt; vollständige Quellwerte einschließlich der doppelten Schlüssel und ihre Anzahl vor/nach verglichen. Vier Replace-/vier Appendfälle mit vollständigem16MiB-Altoutput und unveränderten Zielmetadaten. Isolierter Neutralitätswitness, nur abschließender typisierter Witness als Resultset.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1246 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55306/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Spaete CSV-Rechteckabweisung mit vollem Zielerhalt 2026-10-22

'-TestScope late-parser-rectangular': Vier syntaktisch gültige Inputs mit abweichender Spaltenzahl erst im letzten Record bei exakt16777216 UTF16-Inputbytes: zusätzliche beziehungsweise fehlende Schluss-Spalte nach LF oder CRLF. Jeweils KeepData=0 und1, insgesamt acht Fälle je Modus. Ausschließlich SQL55302/state1; vorheriger vollständiger16MiB-Callerwert, Objektidentität und bidirektional verglichene Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Transaktionsneutralität separat geprüft, keine partielle Zielmutation.

Acht SQLphasen je Modus: vier gültig gescannte, am Schluss nicht rechteckige Inputs jeweils mit Replace- und Append-Einstellung. Alle acht ausschließlich55302/state1. Vollständige16MiB-Input-/Zielbytes sowie Zielinhalt und Zielmetadaten vor/nach geprüft; isolierter Neutralitätswitness und genau ein typisierter Abschluss.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1206 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55302/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Spaete CSV-Syntaxabweisung mit vollem Zielerhalt 2026-10-22

'-TestScope late-parser-syntax': Vier späte Quote-Syntaxfehler im letzten Record bei exakt16777216 UTF16-Inputbytes: offenes Quote am EOF, Text nach geschlossenem Quote, Quote im unquotierten Feld und Text nach Quote hinter CRLF. Jeweils KeepData=0 und1, insgesamt acht Fälle je Modus. Ausschließlich SQL55301/state1; vorheriger vollständiger16MiB-Callerwert, Objektidentität und bidirektional verglichene Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Transaktionsneutralität separat geprüft, keine partielle Zielmutation.

Acht SQLphasen je Modus, ausschließlich55301/state1-Abweisungen. Vier gültig begonnene Inputs mit Syntaxfehler im letzten Record jeweils mit Replace- und Append-Einstellung. Vollständige16MiB-Input-/Zielbytes, Zielinhalt und Zielmetadaten werden vor/nach dem Aufruf geprüft; Transaktionsneutralität separat, nur abschließender typisierter Witness als Resultset.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1166 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55301/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Schemaabweisung mit vollständigem Caller-Datenerhalt 2026-10-21

'-TestScope schema-target-preservation': Acht belegte synthetische Caller-ResultTables mit je einem vollständigen16777216-Byte-Wert: für Parser und Writer jeweils genau eine Abweichung in Spaltenname, Integerbreite, NULLbarkeit oder Collation. Gültiger Parserinput beziehungsweise unabhängig gesetzte Writerquelle mit vollständigem Output an16777216 Bytes. KeepData=1 muss ausschließlich SQL51025/state1 liefern. Vollständige Zielwerte und Writerquelle bleiben bytegenau erhalten; Callerobjektidentität sowie bidirektional verglichene Spalten-, Index- und Indexspaltensnapshots bleiben gleich. Getrennte Transaktionsneutralität und typisierter Abschluss. Kein Schemaumbau und keine neue Funktion.

Acht SQLphasen je Modus, alle acht ausschließlich mit51025/state1: vier voneinander getrennte Schemaabweichungen für Parser und Writer. Vollständige16MiB-Zielwerte, unabhängig gesetzte Writerquelle, Objektidentitäten und bidirektionale Spalten-/Index-/Indexspaltensnapshots werden vor beziehungsweise nach der Abweisung geprüft. Transaktionsneutralität steht in eigenen IFs; nur der abschließende typisierte Witness darf als Resultset erscheinen.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1126 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Initialer unabhängiger Review fand die unpassende generische Plus-zwei-Abschlussmeldung. Vor nativen Läufen korrigiert und zwölf Kontrollen des tatsächlichen Summary-AST ergänzt; gezielter unabhängiger Folgeauftrag am korrigierten festen Kandidaten ohne offene Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL51025/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Callertransaktionen mit vollständigen CSV-Zielwerten 2026-10-21

'-TestScope caller-transaction-preservation': Bestehende öffentliche Parser-/Writeraufrufe in einer committable Callertransaktion mit XACT_ABORT OFF. Vier Erfolge genau an16777216 UTF16-Bytes und vier SQL55303/state1-Abweisungen bei16777218 Bytes je Modus. Caller-Sentinel, @@TRANCOUNT und XACT_STATE werden vor und nach Aufruf sowie nach eigenem COMMIT oder ROLLBACK getrennt geprüft. Vollständige Parserziele/Writeroutputs und unabhängig gesetzte Writerquellen werden bytegenau verglichen; Calleridentität und Schlüssel bleiben erhalten. Ursprüngliches XACT_ABORT wird wiederhergestellt. Keine Abnahme von doomed Transaktionen oder einer vollständigen SET-Optionsmatrix. Nach den nativen PASS wurde genau eine ueberzaehlige EOF-Leerzeile der neuen Fixture entfernt; alle vorherigen SQLbytes sind gegen den unabhaengigen Reviewstand und beide nativen Eingabepins exakt identisch belegt.

Acht SQLphasen je Modus: Parsererfolg, Parserabweisung, Writererfolg und Writerabweisung jeweils mit anschließendem Callerrollback sowie Callercommit. Budgetfehler ausschließlich55303/state1. Caller-Sentinel beweist den Erhalt unabhängiger Callerarbeit; Transaktionszustand steht in eigenen IFs. Vollständige Ziel-/Quellwerte, Calleridentitäten und PKs sowie wiederhergestelltes XACT_ABORT werden geprüft.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1075 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Direkte Unicode-/NULL-Resultsets an vollständigen Textdecken 2026-10-21

'-TestScope select-unicode-null': Direkte öffentliche SELECT-Ausgaben ohne ResultTable über System.Data.SqlClient. Erste Familie:4194303 gültige UTF16-Surrogatpaare mit CRLF. Zweite Familie: unquotierter NullToken als SQL-NULL, quotierter identischer Token als literaler Text und großer BMP-Wert in drei Spalten. Vollständiger Input/Output genau16777216 Bytes, kleinstes Darüber16777218 Bytes. Client prüft vollständige ordinale Strings, DBNull getrennt vom literalen NULL-Text, Zeilen-/Spaltenreihenfolge, Feldnamen und SQL-/CLR-Typen; Writerwerte separat gesetzt und globale Wertcharge unter16MiB. Vier Übergrenzfälle je Modus ausschließlich SQL55303/state1 ohne vorherige Resultsetmetadaten oder Zeilen; vollständiger Quellerhalt. Keine Aussage über ungepaarte Surrogate oder andere Clients.

Acht bestätigte Readerphasen je Modus: vier vollständige Unicode-/NULL-Resultsets und vier55303/state1-Abweisungen ohne partielle Ausgabe. Ein- und Dreizell-Parserresultate, DBNull/literaler Token, vollständige ordinale Werte, SQL-/CLR-Typen und numerische Metadaten werden geprüft. Writerquellen unabhängig gesetzt, vollständiger Quellerhalt, innere Helperpins sowie bisherige ASCII-/Drift-/Timeout-/Disposekontrollen bleiben erhalten.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 1036 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur System.Data.SqlClient im bestehenden PowerShell-Labadapter und die expliziten synthetischen Fälle: keine SMO-/ODBC-/JDBC-/sonstige Clientmatrix, neue Default-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme oder unabhängig erfolgreiche MaxValueBytes-Vollgrenze. Status weiterhin partially validated, unreleased.

### Direkte SELECT-/TDS-Ausgabe an vollständigen Textdecken 2026-10-21

'-TestScope select-output-ceilings': Bestehende öffentliche Parser-/Writeraufrufe mit ResultTable=NULL liefern direkt über System.Data.SqlClient. Unquotierter ASCII-Text mit CRLF und separatorbedingt quotierter ASCII-Text: Input/Output genau16777216 UTF16-Bytes sowie16777218 Bytes. Client prüft genau ein Resultset je Erfolg, Feldnamen/Reihenfolge, SQL-/CLR-Typen, vollständige Strings ordinal und numerische Typen/Werte. Vier Übergrenzfälle je Modus verlangen SQL55303/state1 ohne vorherige Resultsetmetadaten oder Zeilen. Writerquellen separat gesetzt, vollständiger Quellerhalt und Wertcharge strikt unter16MiB; kein INSERT EXEC. Acht bestätigte Readerphasen werden erst danach als typisierter Abschluss gezählt.

Acht Readerphasen je Modus: vier vollständige direkte Resultsets und vier erwartete55303/state1-Abweisungen ohne partielle Ausgabe. Der Adapter prüft Feldnamen, Reihenfolge, SQL-/CLR-Typen und vollständige Inhalte; Writerquellen werden unabhängig gesetzt und vollständig erhalten. Jede Phase bestätigt exakt einen Erfolgspunkt; typisierter Abschluss erst nach allen acht Punkten.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 983 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Erstreview mit zwei Adapterbefunden zur Helper-Pinbindung und Command-Freigabe. Beide vor nativen Läufen korrigiert, mit synthetischen Drift-/Timeout-/Disposefällen geprüft und gezielt unabhängig nachgeprüft; keine offenen Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur System.Data.SqlClient im bestehenden PowerShell-Labadapter und die expliziten synthetischen Fälle: keine SMO-/ODBC-/JDBC-/sonstige Clientmatrix, neue Default-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme oder unabhängig erfolgreiche MaxValueBytes-Vollgrenze. Status weiterhin partially validated, unreleased.

### Budgetparameter-Abweisung mit vollständigem Datenerhalt 2026-10-21

'-TestScope budget-parameter-preservation': Acht ausgewählte feste Budgetobergrenzen jeweils um1 überschritten: Parser MaxInputBytes, MaxRows, MaxColumns, MaxCells; Writer MaxValueBytes, MaxOutputBytes, MaxRows, MaxCells. Alle übrigen Argumente gültig, KeepData=0. Vorbefüllte passende Parser-/Writerziele enthalten je genau16777216 synthetische UTF16-Bytes; die getrennt gesetzte Writerquelle enthält16777212 Bytes und wäre mit CRLF regulär ausgabefähig. Vor und nach jeder SQL55303/state1-Abweisung vollständige bytegenaue Ziel-/Quellorakel samt Zeilenzahl und Metadaten; Calleridentitäten, Spaltenzahlen, drei Primärschlüssel und neutraler Transaktionszustand erhalten. Ergänzt vorhandene kleine NULL/0/Obergrenzenprüfungen; keine neue Funktion oder vollständige Budgetparametermatrix behauptet.

Acht gezählte Abweisungsphasen je Modus, jede exakt SQL55303/state1. Vollständige vorbefüllte16MiB-Zielwerte, getrennt gesetzte gültige Writerquelle, DataRows/ColumnCount, Calleridentitäten und vorhandene Schlüssel werden vor und nach jeder Abweisung geprüft.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 903 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Erstreview ohne Befunde. Der erste Linuxlauf scheiterte anschließend im zusammengesetzten Fixturewitness mit SQL55396/state3 und wurde vollständig bereinigt. Danach Katalog- und Neutralitätsprüfung ohne Verlust von Bedingungen getrennt und gezielt nachgeprüft; keine offenen Source-/Orakelbefunde. Die ursprüngliche Teilursache bleibt unbelegt; der korrigierte Kandidat besteht beide Ziele. Alle Fehlläufe/Folgeaufträge zählen weiter. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 im zweiten Versuch und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent im ersten Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### KeepData und Datenerhalt an vollständigen Textdecken 2026-10-21

'-TestScope keepdata-ceilings': Passende vorbefüllte caller-lokale Parser-/Writerziele mit KeepData=1 und KeepData=0. Parserinput und Writerausgabe je genau16777216 UTF16-Bytes; +2 Bytes werden ausschließlich mit SQL55303/state1 abgewiesen. Erfolgreiches Append erhält synthetische Altzeilen, Replace entfernt diese; fehlgeschlagene Aufrufe erhalten die vollständigen bisherigen Zielwerte. Separat gesetzte Writerquellen bleiben vollständig bytegenau erhalten und ihre Wertcharge strikt unter16MiB. Ziel-/Quellidentität, Spaltenzahlen und beide Caller-Primärschlüssel bleiben erhalten; keine Gesamt-Heapgrenze abgeleitet.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 864 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach Evidenzdokumentation nachgepflegt und ausschließlich eine überzählige EOF-Leerzeile der Fixture entfernt; SQL-Inhalt und Ausführung unverändert.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Kontrollcodeeinheiten an vollständigen UTF16-Textdecken 2026-10-21

'-TestScope control-text-ceilings': Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes: feste synthetische UTF16-Einheiten aus NUL, getrenntem High-/Low-Surrogat, ASCII und BOM. Zweite Familie enthält führenden BOM und separatorbedingt quotierte Werte mit CRLF. Vollständige Bytevergleiche prüfen den Erhalt sämtlicher Codeeinheiten einschließlich führendem BOM als gewöhnlichem Text; Quotehüllen/CRLF vollständig mitgezählt, globale Writerwertcharge auch beim Übergrenzfall strikt unter16MiB.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 825 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Der unabhängige Erstreview fand eine fehlende Abdeckung des BOM an Inputposition0. Die erste Familie wurde vor nativen Läufen korrigiert und gezielt nachgeprüft; abschließend keine offenen Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Unicode an vollständigen UTF16-Textdecken 2026-10-21

'-TestScope unicode-text-ceilings': Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes:4194303 gültige Surrogatpaare mit CRLF sowie separatorbedingt quotierter BMP-Text mit CRLF. Synthetische Codeeinheiten werden aus festen UTF16-Binärliteralen aufgebaut und vollständig bytegenau verglichen. Kein UTF8-/Unicode-Scalar-Zähler; Quotehüllen/CRLF vollständig mitgezählt, globale Writerwertcharge auch beim Übergrenzfall strikt unter16MiB.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 786 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Header an vollständigen Textdecken 2026-10-21

'-TestScope header-text-ceilings': Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes mit vollständigem Header und einem DATArecord. Unquotierter128-Zeichen-Header mit LF sowie separatorhaltiger quotierter Header und DATAwert mit CRLF; Headerwerte, Quotehüllen und sämtliche Recordabschlüsse zählen. Globale Writerwertcharge aus HEADER und DATA strikt unter16MiB, übrige Budgets nicht bindend; vollständige HEADER=0/DATA=1-Wert- und Outputmetadatenorakel.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 747 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### NullTokenexpansion an vollständigen Textdecken 2026-10-21

'-TestScope null-token-ceilings': Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes mit128-Zeichen-NullToken. Zwei Spalten prüfen die SQL-NULL-Expansion; drei Spalten unterscheiden quotiertes Tokenliteral, unquotiertes SQL-NULL und großen Textwert. Tokenbytes, Quotehüllen, Separatoren und LF zählen vollständig, globale Writerwertcharge strikt unter16MiB; übrige Budgets nicht bindend.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 708 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### CRLF an vollständigen Textdecken 2026-10-21

'-TestScope crlf-ceilings': Parserinput/Writerausgabe an exakt16777216 UTF16-Bytes und kleinstem tatsächlichem Darüber16777218 Bytes, unquotierter und wegen Separator quotierter Record mit CRLF. Beide Recordabschlusszeichen und Quotehüllen zählen vollständig; die globale Writerwertcharge bleibt strikt unter16MiB, übrige Budgets nicht bindend.

Acht gezählte Phasen je Modus; SQL55303/state1 ausschließlich für vier
Übergrenzfälle je Modus. Vollständige Werte/Outputbytes, DataRows/ColumnCount,
unabhängig gesetzte Writer-Übergrenzquellen und Quell-/vorheriger Zielerhalt.
Typisierter Abschluss, getrennte Funktionszähler und bestehende Deadline/
Cleanupreserve bleiben erhalten. 669 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden.

Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Quoteverdopplung an vollständigen Textdecken 2026-10-21

`-TestScope quote-expansion` enthält acht gezählte Phasen je Modus: Parser
und Writer an16777216 UTF16-Bytes sowie dem kleinsten tatsächlichen Darüber
16777218 Bytes, jeweils für eine und zwei quotehaltige Zellen. Die unabhängigen
Textorakel konstruieren die verdoppelten Quotes direkt aus synthetischen
Wiederholungen; kein Aufruf des Produktquoters erzeugt die Erwartung. Quotehüllen,
Separator und abschließendes LF zählen vollständig. Die Zweizellfälle prüfen
die globale Summe, während jede einzelne serialisierte Zelle unter16MiB liegt.

Parserwerte, vollständige Outputbytes, Metadaten und Quell-/vorheriger
Zielinhalt sind bytegenau geprüft; die Writer-Übergrenzquellen werden unabhängig
vom Parser gesetzt und bleiben mit ihrer globalen Wertcharge strikt unter16MiB.
SQL55303/state1 wird ausschließlich für die vier Übergrenzfälle je Modus erwartet.
Der typisierte Abschluss verlangt alle acht Phasen; getrennte Funktionszähler,
geschlossene Scope-/Fixturezuordnung und die bestehende Deadline/Cleanupreserve
bleiben erhalten. 630 synthetische Offlinekontrollen, acht SQL150-Phasen,
AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen
ohne Findings. Gleicher ausführbarer Kandidat auf Linux2019/latest CL150 und
Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster
Versuch local/central PASS:16 Fälle je Ziel, darunter acht SQL55303/state1.
Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr;
je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend,
Konfiguration/Rechte/Inputs unverändert. Danach ausschließlich gekoppelte
Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt, keine ausführbare Drift.

Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert;
vorhandenes quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer
lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-
Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/
authentifizierte TLS- oder Releaseabnahme. `partially validated`, `unreleased`.

### Tatsächliche Input-/Outputtextdecken 2026-10-21

Der getrennte Scope `-TestScope text-ceilings` enthält acht gezählte Phasen
je Modus: Parserinput und Writerausgabe jeweils genau16777216 UTF16-Bytes
(16MiB) und das kleinste darstellbare Darüber16777218 Bytes. Unquotierte und
quotierte Texte werden getrennt geprüft; Quotes und alle LF gehören zum
jeweiligen Budget. Die unquotierte Writerausgabe umfasst zwei Records, damit
auch beim Übergrenzfall die globale Quellwertcharge strikt unter16MiB bleibt.
Die quotierte Writerquelle beginnt mit einem Separator und benötigt daher
zwei Quotes; ihre Wertcharge bleibt ebenfalls strikt unter der Wertdecke.

Alle übrigen Budgets sind nicht bindend. Vollständige Wert-/Outputbytes,
DataRows/ColumnCount und Quell-/vorheriger Zielinhalt werden geprüft.
Übergrenzfälle erwarten ausschließlich SQL55303/state1. Acht getrennte
SQLphasen geben erst nach allen Assertions einen typisierten Abschluss aus;
der Adapter verlangt acht Fälle je Modus und null fremde Funktions-/Guard-/
Lifecyclezähler. Pro Phase maximal300 Sekunden innerhalb der unveränderten
Arbeits-/Gesamtdeadline und Cleanupreserve. 591 synthetische Offlinekontrollen,
acht SQL150-Fixturephasen, AST/Static bestanden.

Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent bestanden jeweils im ersten Versuch local/central:16 Fälle je
Ziel einschließlich acht SQL55303/state1-Abweisungen, Clean/Repeat und
Uninstall/Repeat. Je Exit0/vollständige Kanäle/leeres Stderr; frischer separater
Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Rechte und
eingefrorene Eingaben unverändert. Unabhängiger Quell-/Orakelreview vor den
nativen Läufen ohne Findings; gleicher ausführbarer Kandidat. Nachgepflegt
werden ausschließlich gekoppelte Manifest-/Evidenz-/Dokumentationsdateien.
Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert.
Vorhandenes quellengebundenes Paket
mit gleichen CLR-Bytes; kein neuer lokaler Build-/Frameworklauf. Der Scope
belegt keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze: Wert-/Output-
budgets sind gekoppelt. Neue Default-/Clientabnahme, Heap, Minimalrechte,
Gesamtmatrix, authentifiziertes TLS und Release bleiben nicht ausgeführt.

### Tatsächliche Gesamtzelldecke 2026-10-21

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

### Korrigierter Writer an tatsächlichen Formgrenzen 2026-10-21

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
### Native tatsächliche Zeilen-/Spaltendecken 2026-10-21

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
### Interne CLR-Rückgabelängen 2026-10-21

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

### Falsche Schemamarkerwerte 2026-10-21

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

### Fremde SQL-TVFs auf reservierten Namen 2026-10-21

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

### Finale benannte SameDB-Verbraucher auf Linux 2026-10-21

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

### Finale CLR-Defaults auf Linux 2026-10-21

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

### CLR-Ausführungskontexte 2026-10-20/21

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

### Falsche Ownership-/Release-Markerwerte 2026-10-20

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

### Explizite SameDB-SQL-Verbraucher 2026-10-20

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

### Gezielte CLR-Parameterdefaults 2026-10-20

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

### Gezielte interne CLR-Bindingdrift 2026-10-20

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

### Fremde Synonyme und SQL-Funktionen 2026-10-20

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

### Fremde Views und Prozeduren 2026-10-20

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

### Fehlende Ownershipmarker 2026-10-20

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

### Begrenzte Fremdslot-/Verbraucher-Guards 2026-10-20

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

### Begrenzte Marker-Guards 2026-10-20

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

### Zusätzliche Compatibility Levels 2026-10-20

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

### Standard-CL-Bindung 2026-10-20

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

### Vorherige ergänzende native Zielwelle 2026-10-20

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

### Historische Nachweise

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

<!-- CSV_WAVE_EVIDENCE:END -->

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-22`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1 -TestScope trailing-empty-field-preservation`
- Scope: Acht erfolgreiche Fälle je Modus: Parser mit leerem letztem Feld am EOF beziehungsweise vor CRLF und Writer mit einem beziehungsweise zwei abschließenden leeren Feldern, jeweils KeepData=0/1. Eine unabhängig gesetzte große erste DATA-Zelle bleibt vollständig enthalten, Quelle und Text liegen unter16MiB. Leere Felder bleiben ausdrücklich nicht-NULL-leer; EOF und finaler Recordabschluss erzeugen keinen zusätzlichen Record. Writer liefert exakt die abschließenden Separatoren und CRLF mit DataRows1 und ColumnCount2 beziehungsweise3. Vor jeder Operation eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig. Quelleninhalt, Identitäten und bidirektionale Katalogsnapshots bleiben erhalten. Keine neue Bytegrenzabnahme. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu Abschließende leere CSV-Felder mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt. 1766 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
