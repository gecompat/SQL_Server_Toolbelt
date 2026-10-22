# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

45 Module sind implementiert. 21 sind `validated`, 24 sind `partially validated`; 0 sind `not executed`.

## Releasevorbereitung v1.0.0 — 2026-10-22

Ausdrücklicher unmittelbarer Benutzerauftrag: Gesamtpaket v1.0.0 mit
Freigabematrix und klarer Trennung stabil/Preview vorbereiten und einen PR
erstellen; noch nicht veröffentlichen. Die autonome Weiterentwicklung bleibt
pausiert. Die aktuelle Foundation 1.25.0 ist bereits integriert und mit dem
aktuellen Foundation-Upstreamcommit abgeglichen; kein zusätzlicher Upgrade.

Die [Vorbereitung](../Releases/1.0.0/README.md) friert alle 45 Module ein.
19 stabile und 26 Preview-Kandidaten berücksichtigen transitive Dependencies;
Second Session und Event Log bleiben wegen Work Type vorläufig Preview.
Keine Modulstatusaufwertung, API- oder Produktänderung. Das Gesamt-ZIP ist
ein Quellpaket mit zusätzlichen stabilen SQL-Exports und dem bestehenden
SSIS-Installationssatz; weitere vorgebaute CLR-Pakete bleiben ein sichtbares
Liefergate. Konkrete Supportkombinationen, fachlicher Release-Review und
Veröffentlichungsfreigabe sind weiterhin ausstehend. Kein Tag oder Release.

Anschließender ausdrücklicher Benutzerauftrag vom 2026-10-22: ohne weitere
Entscheidungen ausführbare Release-/Paketierungsgates abarbeiten und dafür
einen PR erstellen; nicht veröffentlichen und die Entwicklungspause erhalten.
Der [Gatebericht](../Releases/1.0.0/RELEASE-GATES.md) belegt zwölf native
stabile Paketfälle einschließlich eigenem Cleanup und die zweimal isolierten,
bytegleichen Builds aller zwölf CLR-Projekte. Der bereinigte Marker-Erstfehler
bleibt fehlgeschlagen. Neue CLR-Binaries werden nicht unqualifiziert ins
Quellpaket übernommen; Supportabnahme, deren fehlende Pflichtnachweise,
vollständiger CLR-Installationssatz und Veröffentlichung bleiben getrennt offen.
Keine Änderung an fachlichen SQL-Objekten, Modulversionen oder Prüfstatuswerten.

Ergänzung desselben Benutzerauftrags: leicht auffindbare, auch für unerfahrene
Anwender verständliche Installationsanleitung. [INSTALL.md](../INSTALL.md)
führt vom ZIP über SSMS zu Installation, erwarteten Ergebnissen und
Fehlerklärung; README, Dokumentationsübersicht und Paketstart verlinken sie.
Paketpflege mit vollständiger Quellprüfung und der Endanwenderweg mit
verpflichtendem Prüfsummenvergleich bleiben klar unterschieden.

## Vorgebaute CLR-Installation v1.0.0 — 2026-10-22

Ausdrücklicher unmittelbarer Benutzerauftrag: fertige DLLs mitliefern, den
Quellcode beibehalten und eine schnelle Installation ohne eigenen Build
ermöglichen. Ein abgegrenztes Paketierungsarbeitspaket/ein PR, keine neue
fachliche API und keine Änderung der Stable-/Preview-Einstufung. Allgemeine
autonome Weiterentwicklung und Veröffentlichung bleiben pausiert.

Der vorhandene reproduzierbare Doppelbuild ist an identische Produktquellen
gebunden. SSIS-/Parser-/ScriptDom-Binaries werden aus dem bestehenden
qualifizierten Satz übernommen; andere Provider bleiben exakt an ihre
Buildbytes gebunden. Vier explizite Installationsprofile erhalten Windows-,
SAFE-/UNSAFE- und lokale/zentralen Grenzen sowie kanonische Hash-/Lifecycle-
Guards. Fertige SQL-Dateien enthalten die Assemblybytes; DLLs, Quellcode,
Trustwerte und Attributionen werden zusätzlich ausgeliefert. Offline- und
native Paketprüfung stehen vor der tatsächlichen Übernahme des Pakets an.
Alle vorhandenen fachlichen Releasegates bleiben sichtbar.

## Dokumentationspflege aus Foundation 1.25 — 2026-10-22

Der ausdrücklich beauftragte [Foundation-Upgrade](../Documentation/Architecture/FOUNDATION_1_25_INTEGRATION.md)
übernimmt die Dokumentationsrichtlinie und verbessert den zentralen menschlichen
sowie den getrennten KI-Einstieg. Folgende sichtbare Altlasten bleiben konkret
geplant; daraus folgt keine vollständige Dokumentationskonformität oder neue
Funktionsfreigabe:

| Scope | Verantwortliche Rolle | Auslöser und Abnahme |
|---|---|---|
| Root-README: umfangreiche narrative Modul-/Testhistorie nach dem frühen Einstieg | Dokumentationsverantwortlicher des nächsten betroffenen Produktüberblicks | 2026-10-22 erledigt im ausdrücklichen Installationsauftrag: früher direkter Installationseinstieg; bisherige Prosa und Abschnittslinks unter Documentation/History erhalten; aktuelle Modulwerte und Orientierung bleiben bei den kanonischen Quellen |
| CSV-Memory-Tests/README: vorangestellte Qualifikationschronologie | Implementierungsverantwortlicher der nächsten CSV-Memory-Welle, vor deren Review | Testanleitung und aktuelle Auswahl zuerst erklären; datierte Wellenbelege in einer eindeutig bezeichneten Evidenzstrecke erhalten, erforderliche Links und Validator-/Manifestkopplungen gemeinsam prüfen |
| Weitere Modul-/Testanleitungen mit vorangestellten historischen Security-/Abnahmeabschnitten | Verantwortlicher des jeweils materiell geänderten Moduls | Bei der nächsten betroffenen Anleitung Einführung, Voraussetzungen, Anwendung und Fehlerklärung vor historische Belege stellen; bestehende IDs und Evidenzgrenzen erhalten |

2026-10-22: Der CSV-Testlesepfad wird mit der Parser-Argumentwelle bereinigt:
Auswahl, Voraussetzungen, Ausführung, Ergebnisdeutung und Fehlerklärung stehen
vor den datierten Nachweisen. Die bisherigen Abschnitte und Linkanker sowie
die generierte Manifest-Evidenz bleiben im selben Dokument erhalten. Weitere
Legacy-Scopes der Tabelle bleiben an ihre eigenen Auslöser gebunden.

Keine pauschale Dateiverschiebung, neue Registry oder zusätzliche Reviewkette.
Unveränderte unabhängige Dokumente bleiben außerhalb des jeweiligen Änderungsumfangs.

## Research-Vormerkung: SQL-Dialekt-Transformation — 2026-10-16

**Abschluss des beauftragten Researchscopes, 2026-10-18:** Machbarkeit,
Regelspike, native SQL-Server-/Spark-Semantik und begrenzte Performance-/
Planprüfung sind dokumentiert. Databricks und die nicht stabilen Zeitvergleiche
bleiben offen; keine Produkt-V1- oder Releasefreigabe. Der folgende Verlauf
hält die jeweils damaligen Nachweise fest; maßgeblich ist der jüngste Stand.

Benutzerauftrag zur Recherche und Backlogplanung von T-SQL ↔ Databricks SQL
in beiden Richtungen, Erweiterungen um Spark SQL/weitere Dialekte und
Python-/weitere Sprachausgabe. Die [Machbarkeitsanalyse](../Documentation/Research/SQL_DIALECT_TRANSFORMATION_FEASIBILITY.md)
enthält eine gerichtete SQL-Quellen-Ziel-Matrix, eine Sprach-/API-Matrix,
Provideralternativen, semantische Grenzen, OUTER-APPLY-/Top-N-Regeln und
Performance-/Qualifikationsplanung. Empfohlen ist zunächst ein begrenzter
lesender SQL-Kern; Routinen, schreibende Profile und DataFrame-Generatoren
bleiben getrennte spätere Funktionen.

Die [benannte Vormerkung](../Backlog/TOOLBELT_CANDIDATES.md#sql-dialekt-transformation--vormerkung-ohne-finale-tc-referenz)
ist `researched`; keine Implementierungsfreigabe, kein aktives AP und keine
Prioritätsänderung. Finale TC-/AP-Vergabe gemäß `DEC-2026-028` noch offen.
Konvertierungs-, Engine- und Performanceversuche `not executed`; keine
Dependencyinstallation, Lab-/Cloudänderung oder Ausführung von Quelltext.

Benutzerauftrag zur Konkretisierung vom 2026-10-16:
Der [erste V1-Vertragsvorschlag](../Documentation/Research/TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md)
definiert eine lesende Abfrage mit CTEs, einer APPLY-/LATERAL-Stufe,
begrenzt automatischer Top-N-/Voraggregationsumschreibung und einer expliziten
Positivliste. Kontextabhängige Fälle, manuelle Grenzen, Zähl-/Rankingtypen,
NULL-/Duplikat-/Zeit-/Collationverträge und messbare Performanceabnahme sind
getrennt beschrieben. Weiterhin `researched`, keine Implementierungsfreigabe.

Anschließend ausdrücklich beauftragter Provider-Spike vom 2026-10-16:
[SQLGlot 30.23.0](../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_SPIKE.md)
wurde isoliert lokal mit 32 synthetischen Eingaben und 34 bestandenen
Beobachtungsassertions geprüft. 26 Generator-/Reparse-Ergebnisse, fünf
LATERAL-Generatorablehnungen und eine Zielparserablehnung nach Command-Fallback;
die Generatorergebnisse enthalten ausdrücklich problematische Fälle und sind
keine semantischen PASSes. Zwei feste AST-Rückrichtungsversuche zeigen einen
möglichen eigenen LATERAL→APPLY-Adapter. Typen, Parameter, Hints und Limitoptionen
benötigen eigene Regeln. Dies ersetzt ausschließlich den vorherigen
`not executed`-Stand der lokalen Providerexperimente: keine native Engine-,
Ergebnis- oder Performancequalifikation, weiterhin keine V1-Implementierungsfreigabe.
Die SQLGlot-Testdependency wurde ausschließlich isoliert lokal installiert;
keine Projekt-Runtimedependency, Lab-/Cloudänderung oder SQL-Ausführung.

Weitere ausdrückliche Beauftragung vom 2026-10-16:
Der [Spikekern mit eigenen AST-Regeln](../Documentation/Research/SQLGLOT_TSQL_DATABRICKS_RULE_SPIKE.md)
ist ausschließlich unter `Tests/Research/SqlDialect` ergänzt. 100 feste
Regelfälle mit 476 Assertions bestanden: 30 positive Umschreibungen und
70 negative Fälle ohne Teil-SQL, davon 13 mit fehlendem Kontext. Geprüft sind
beide Richtungen für begrenzte LATERAL/APPLY-, Parameter-, Cast-/COUNT-/
ROW_NUMBER- und Limitregeln. Providerbaseline unverändert erneut bestanden.
Kein allgemeiner Binder, keine native Ergebnis-/Performancequalifikation,
weiterhin `researched` und keine automatische V1-Implementierungsfreigabe.

Anschließend ausdrücklich beauftragte native Labprüfung mit synthetischen
Daten und Prüfung geeigneter Lab-Bereitstellungswege vom 2026-10-16:
[57 native T-SQL-Fälle vorbereitet](../Documentation/Research/SQLGLOT_NATIVE_TSQL_LAB_PROBE.md),
Wert-/NULL-/Multimengen- und Clienttyporakel ergänzt. Lokale Korpus-/
Vergleicherprüfungen bestanden. Sechs ausgewählte Ziele vor SQL-Anmeldung
wegen TLS-Vertragsabweichung abgewiesen; **keine native Abfrage ausgeführt**.
Lab-1.0-Exporter und Schema erfordern Trust-Override; eine neue
Standardumgebung liefert denselben Vertrag. Authentifizierte Bereitstellung
und Consumer-Cutover hängen am offenen Lab-Stream TLS-001. Drei weitere
COUNT-/ROW_NUMBER-Roundtrips scheitern am eigenen Cast-Gate. Native
SQL-Server-, Databricks- und Performancequalifikation bleiben getrennt offen;
keine Infrastruktur-/Truständerung oder allgemeine V1-Freigabe.

**Aktualisierung nach Benutzerklarstellung vom 2026-10-16:** Unabhängige
fachliche Tests verwenden den schema-validierten Labtransport; die TLS-
Qualifikation bleibt gesondert. Der [native Researchlauf](../Documentation/Research/SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
bestand nach zwei Harnesskorrekturen mit 57 Fällen auf allen sechs Zielen,
insgesamt 342 erfolgreichen Fallausführungen. Ergebnisse, NULL-/Duplikat-
Verhalten und deklarierte Clienttypen bestätigt. Die frühere TLS-Sperre oben
ist damit für diese Fachtests überholt; Databricks, Performance und drei am
Cast-Gate abgewiesene Roundtrips bleiben offen. Keine allgemeine V1-Freigabe.

**Benutzerauftrag und Abschluss vom 2026-10-17:** Die drei offenen
COUNT-/ROW_NUMBER-Roundtrips sind im Researchkern behoben. Ausschließlich
begrenzte INT-/BIGINT-Ergebnis-Casts werden zusätzlich erkannt; Gruppen-/
Partitionsgrenzen und eindeutige Rankingordnung bleiben erforderlich.
140 feste AST-Eingaben und 42 Roundtrips bestanden mit 852 Assertions.
Der [erweiterte native Korpus](../Documentation/Research/SQLGLOT_NATIVE_TSQL_LAB_PROBE.md)
bestand mit 81 Fällen auf sechs Labzielen, insgesamt 486 Fallausführungen.
COUNT bleibt INT, ROW_NUMBER BIGINT; NULL-/Leerfälle und Clientmetadaten der
betroffenen T-SQL-Enden stimmen überein. Kein Roundtrip des nativen Korpus
mehr abgewiesen. Databricks, Performance und allgemeine Ausdruckstypbindung
bleiben offen; keine allgemeine V1-Implementierungsfreigabe.

**Databricks-Prüfstand und Benutzerklarstellung vom 2026-10-17:** Der Spike
bleibt SQL_Server_Toolbelt zugeordnet. Aktuell ist kein Databricks-Zugang
vorhanden. Die [nativen Databricks-Tests](../Documentation/Research/SQLGLOT_NATIVE_DATABRICKS_PROBE.md)
bleiben auf ausdrücklichen Benutzerauftrag offen (`not executed`), ohne
zusätzliche Infrastruktur einzurichten. 57 SELECTs für dieselben synthetischen
Daten sind den 81 T-SQL-Fällen zugeordnet; lokale Harnesskontrollen bestanden,
aber keine Databricks-Abfrage wurde ausgeführt. Native LATERAL-/Top-N-,
COUNT-/ROW_NUMBER-, Ergebnis-/NULL-/Typ- und Performancenachweise bleiben
offen. Fortsetzung erst mit einem später verfügbaren ausgewählten Zugang und
festgelegtem Profil; keine weiteren nativen Versuche bis dahin. Die 486
bestandenen SQL-Server-Fallausführungen behalten ihren getrennten Scope.
Keine allgemeine V1-Implementierungsfreigabe.

**Anschließender Benutzerauftrag zur Testlösung vom 2026-10-17:** Ein
[nativer lokaler Spark-SQL-Lauf](../Documentation/Research/SQLGLOT_NATIVE_SPARK_PROBE.md)
ermöglicht die tatsächliche Ausführung ohne Databricks-Zugang. Auf Apache
Spark 4.0.2 bestanden alle 57 positiven SELECTs und neun Negativfälle. Die
Werte der 57 Abfragen stimmen mit allen zugeordneten 81 T-SQL-Fällen der
gebundenen sechs Labziele überein. LATERAL mit korreliertem LIMIT/Cutoff,
Top-N, COUNT/ROW_NUMBER, NULL-/Leerfälle und vereinbarte SQL-Typen bestätigt;
abweichende Clienttypen und Nullability getrennt dokumentiert. Ein anfänglicher
Parameter-Harnessfehler wurde vor dem grünen Gesamtlauf behoben. Portable
Testdependencies nur unter `.runtime/`, keine Systeminstallation, Cloud-,
Container- oder Labbereitstellung. Native Databricks-, typisierte NULL-
Parameter- und Performanceabnahmen bleiben offen. Weiterhin `researched`,
keine V1-Implementierungsfreigabe.

**Benutzerauftrag zur Performanceprüfung vom 2026-10-17:** Die
[native APPLY-/LATERAL-/Top-N-Welle](../Documentation/Research/SQL_DIALECT_PERFORMANCE_PROBE.md)
verwendet 100.000 und 1.000.000 synthetische Events sowie 2.000 linke Zeilen.
34 SQL-Server-2025-/Windows- und 20 Spark-4.0.2-Fälle bestanden Ergebnis-
und Planprüfung; vier native Kontrollen erkennen den unzulässigen Cutoff
nach globaler Rangbildung. 11 SQL- und sieben Spark-Zeitserien bestehen
das feste Stabilitäts-/Bestätigungsgate, 36 Zeitvergleiche bleiben mangels
Stabilität `not executed`. Performance insgesamt `partially validated`.
Index-/Selektivitäts-, Window-, Korrelations-/Cutoff- und Planregeln sind
begrenzt dokumentiert. Rohpläne und Messwerte nur unter `.runtime/`; keine
Engine-übergreifende Geschwindigkeitsrangliste, keine Server-/Labänderung,
keine native Databricks-Abnahme und kein produktiver Optimierer.

## Research-Vormerkung: SSIS-/DTSX-Debug-SELECT — 2026-10-16

**Funktionsbezogene Implementierungsfreigabe vom 2026-10-16:** Nach Besprechung
des [V1-Vertrags](../Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md)
hat der Benutzer die Umsetzung einschließlich UNSAFE-Assembly, begrenztem
Parserzugang und gekoppelten Dependency-/Pinanpassungen ausdrücklich beauftragt,
mit den vereinbarten Tests. Neue Produktquellen und reproduzierbarer Build
liegen vor: [SSIS-Debug-Modul](../Modules/toolbelt.tsql.ssis-debug/README.md).
21 isolierte Framework-Kindprozesse sowie unveränderte Parserregression 245/Guard60 bestanden;
unabhängige Coreprüfung nach Korrekturen und einem Folgeauftrag bestanden,
zwölf isolierte SQL-Syntaxprüfungen bestanden. Stand 2026-10-17: Native
Fachverträge auf Windows SQL Server 2019/2022/2025 in lokalem und zentralem
Deploymentmodus bestanden, je 181 Kern-, 61 API- und 15 Lifecycleassertionen
(1.542 insgesamt). Alle CTE-Stufen einzeln, direkte DECLARE-/Cacheinvalidierung,
Parallel-DML/Sch-M, Cross-DB, Analyse ohne Quell-SELECT und atomarer Fremdobjekt-/
Consumer-/Lock-Schutz bestanden. Echte Parser-2.0.0→2.0.1-/TableClone-4.1.0→4.1.1-
Upgrades mit Triggerregression, Deployment/Repeat/Uninstall/Repeat und frische
Cleanup-Audits bestanden. WHERE-Erhalt, reine TVF ohne Alias, doomed Caller-TX,
lokale Computed-Spaltenkanten und COLLATE-Rendering korrigiert.
`Functional` übernimmt den expliziten Trustwert bei
erforderlicher Verschlüsselung; authentifizierte TLS-Abnahme bleibt separat
`not executed`. Aktuelle Head-/Integrations-CI und Release bleiben getrennt
offen; siehe [aktuelle Prüfmatrix](../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Frühere Aussagen „keine Implementierungsfreigabe“ im folgenden
Rechercheverlauf dokumentieren den damaligen Stand und sind damit abgelöst.
Keine finale TC-/AP-Sequenz wird geraten; die damalige Freigabe war keine Veröffentlichungserlaubnis.

**Integrationsstand vom 2026-10-19:** SSIS-Debug einschließlich Beispielen,
Installationsanleitung und pfadbereinigtem ZIP ist über PR #324 bis #327
in `main` integriert. Der begrenzte Offline-/Table-Clone-/Dokumentationsscope
bestand am exakten PR-327-Mergecommit; direkte Runverweise stehen in der
[SSIS-Prüfmatrix](../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Frühere offene CI-/Mergeangaben bezeichnen ihren damaligen Stand.
Vollständige Produktqualifikation, authentifizierte TLS-Abnahme und
Veröffentlichung bleiben davon getrennt.

Benutzerauftrag ausschließlich zur Analyse und Planung einer Toolbelt-Funktion:
DTSX-Workflow erklären und pro tatsächlichem Zielfluss lesbares Microsoft-T-SQL
erzeugen. Die Präzisierung des Benutzers macht benannte CTE-Zwischenstufen und
einzeln ausführbare Prüfblöcke zum Kernumfang, um schrittweise Fehler einzugrenzen.
Keine Paket-/SQL-Ausführung beim Einlesen; generiertes SQL ohne persistente
Änderungen, nur eigene lokale Temp-Tabellen bei Bedarf. Alle Lookups erhalten
ROW_NUMBER-Deduplizierung über den vollständigen Schlüssel; beliebige Auswahl
ist sichtbar und wird bei Wiederverwendung innerhalb des Laufs festgehalten.

Ergänzter Benutzervorschlag desselben Tages: aus DTSX und optionalem Projektkontext
eine JSON-Vorlage der erkannten Eingaben erzeugen, Werte darin bearbeiten und
dieselbe Struktur als `@Bindings` zurückgeben. Scope-/Typ-/Paketbindung,
Default-/Expressionherkunft und fehlenden Runtimekontext erhalten; eigene
skalare Deklarationen je Prüfblock und Cacheinvalidierung bei Wertänderung.
Die [JSON-Rundreise](../Documentation/Research/SSIS_DTSX_DEBUG_SELECT_FEASIBILITY.md#json-vorlage-aus-dem-paket-und-rückgabe-bearbeiteter-werte)
bleibt Schnittstellenentwurf, keine Implementierung.

Benutzerbestätigung vom 2026-10-16 zur Darstellung: bearbeitbare Werte stehen
als typisierte `DECLARE`s am Anfang des generierten T-SQL. Direkte Änderungen
im Skript erlauben CTE-Stufentests ohne erneuten JSON-/Generatoraufruf;
jeder Prüfblock enthält seine Deklarationen und WITH-Kette im selben Batch.
Auch direkt geänderte Initialwerte erfordern den Neuaufbau davon abhängiger
eigener Temp-Caches. Diese Bestätigung ist keine Implementierungsfreigabe.

V1-Besprechung vom 2026-10-16: Der Benutzer wählt direkten T-SQL-/SSMS-Aufruf,
den vorgeschlagenen ersten Komponentenumfang und pragmatische SQL-Vergleiche;
rein lesende Katalogprüfung ist erlaubt. Herkunft der Pakete: Visual Studio
2012 bis 2026. Zusätzlich verlangt er NOLOCK an allen unterstützten lesenden
Objektreferenzen, auch für paralleles Debuggen eines laufenden Pakets.
Der [konkrete V1-Vertrag zur Freigabe](../Documentation/Architecture/SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md)
definiert zwei DTSX2-Formatprofile, die Windows-SQL-CLR-Fassade, JSON-/DECLARE-/
CTE-/Cache-Verträge, explizite Same-instance-Katalogbindings, Hintgrenzen,
AST-Schreibschutz, Ressourcen und Abnahme. Status `proposed contract`;
Auftrag ist die Vertragsausarbeitung, noch keine Implementierungsfreigabe.

Lokaler Offlinebefund: Das synthetische SQL-Beispiel mit NOLOCK ist syntaktisch
gültig, überschreitet aber den vorhandenen Quellen-Vorfilter bei Atom 513.
Der Vorschlag enthält deshalb ausdrücklich einen getrennt qualifizierten
begrenzten ScriptDom-Einstieg in einer neuen Windows-/UNSAFE-Assembly sowie
einen kanonischen gemeinsamen Vorfilter als Parserpatch 2.0.1. Die bisherigen
öffentlichen Parsergrenzen bleiben erhalten. Wegen exakter Binarybindung gehört
ein reiner Dependency-/Pin-/Regressionspatch für Table Clone, vorgeschlagen
4.1.1, zum Freigabegegenstand; keine Erweiterung seiner Fachfunktion.

Die [Machbarkeitsanalyse](../Documentation/Research/SSIS_DTSX_DEBUG_SELECT_FEASIBILITY.md)
enthält Iststand, Architekturvarianten einschließlich optionaler CLR-Fassade,
Komponenten-/Herkunftsmodell, Unterstützungsmatrix, synthetisches Stufenbeispiel,
Schnittstellenentwurf und die geplante Prüfung der Schreibgrenze.
Die [drei getrennten Toolbelt-Vormerkungen](../Backlog/TOOLBELT_CANDIDATES.md#ssis-dtsx-debug-select--vormerkung-ohne-finale-tc-referenz)
betreffen (1) Debug-SELECT, (2) spätere parametrisierte USP-Kapselung mit einem
Aufruf und (3) die weitergehende SSIS-gleiche USP mit eigenem Schreib-/Runtime-
Vertrag und belegtem Teilumfang. Die beiden USP-Erweiterungen sind keine
Schreib- oder Laufzeiterweiterung der Debugfunktion.

Dies aktiviert kein AP und ändert keine Entwicklungspriorität. Keine finale
TC-/AP-Sequenz wird ohne sichere Vergabe geraten (`DEC-2026-028`); die benannten
Vormerkungen bleiben bis dahin auffindbar. Historischer Researchstand vor der oben dokumentierten Einzelfreigabe:
Debugfunktion damals `researched`, spätere USP-Funktionen `proposed`;
Implementierungsfreigaben und Runtime-Nachweise waren zu diesem Zeitpunkt
noch offen. Die implementierte Debugfunktion und ihre späteren Nachweise
stehen am Anfang dieses Abschnitts. Die USP-Folgescopes bleiben unfreigegeben.

## Integrierte Security-Härtung — 2026-10-16

Der Benutzer hat nach konkreter Besprechung alle 25 noch offenen Punkte
freigegeben, ausdrücklich einschließlich UNSAFE bei SC-023, Cancellationquoten
und NULL-/Leermengenverhalten. Autor: Codex. Der verbindliche
[Umsetzungsvertrag](../Documentation/Architecture/SECURITY_HARDENING_2026_10.md)
nennt alle 25 Verträge, Grenzwerte, Migrationen und die vier geordneten Wellen.
Alle vier Wellen sind über [PR #322](https://github.com/gecompat/SQL_Server_Toolbelt/pull/322)
am 2026-10-16 in `main` integriert. Gezielte native SQL-, Framework- und
Offlineprüfungen sowie die unten gebundene Head-CI sind erfolgt.
Der Source-/Teststand und seine Grenzen stehen im
verlinkten Umsetzungsvertrag. Die 25 Punkte sind entwicklungsreif und freigegeben;
kein weiterer fachlicher Entscheidungsbedarf. Frühere D/proposed-Angaben unten
sind der historische Entscheidungsstand vor dieser ausdrücklichen Freigabe.
Kein neuer Cloudabschluss und keine neue Runtimequalifikation allein durch
Freigabe, Sourceänderung oder Merge. **SC-045 bleibt P1 und offen bis zur
erfolgreichen authentifizierten TLS-Lab-Abnahme.** `TestPurpose=AuthenticatedTls`
verweigert Trust-Override bereits vor dem Verbindungsaufbau; der Livebeleg für
Zertifikatskette und Servernamen mit SQLClient und `sqlcmd` auf ausgewählten,
schema-validierten Labzielen bleibt offen. Gemäß Benutzerklarstellung vom
2026-10-16 dürfen unabhängige Fachtests den schema-validierten Labtransport
mit explizitem Trustwert verwenden. Dies ist kein TLS-Nachweis. SC-018 bleibt
bei untrusted Legacydirektzugriff offen.

**Integrationsnachweis:** [Merge `985b9d8`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/985b9d8a9df1dad9b1c13e868b7eac0a7758bd6f).
Am geprüften [PR-Head `8772e9d`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8772e9d6a1d538e6fcb22da3f0bd03c83a28e88a)
sind 93 CI-Prüfungen erfolgreich, keine fehlgeschlagen oder ausstehend
(Statusabfrage mit `gh pr view 322` am 2026-10-16). Nur die ausdrücklich
manuelle JSON-Pointer-Lastprüfung ist `SKIPPED`, kein PASS. Die vormals
ausstehende [Deterministic-Mapping-Matrix](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38709629603)
bestand alle sechs Linux-Kombinationen für SQL Server 2019/2022/2025.
Der Merge enthält denselben vollständigen Dateistand wie der geprüfte PR-Head;
dies behauptet keine neuen CI-Ergebnisse am Mergecommit oder vollständige
Windows-/Minimalrechte-/Heap-/Releasequalifikation. Kein Cloudstatus wurde
mit diesem Integrationsauftrag geändert; Modulvalidierungsstatus bleibt separat.

### Aktueller Entwicklungsstand der 25 freigegebenen Punkte

14 P1 und 11 P2; alle fachlichen Entscheidungen sind freigegeben. Die folgende
Tabelle beschreibt den integrierten Stand. Der Cloudabschluss bleibt eine
getrennte Abnahme; insbesondere ist SC-045 weiterhin offen.

| Gruppe | Inhalt | Priorität | Aktueller Stand |
|---|---|---|---|
| `SC-2026-002` | RegexCount/RegexInstr: kumulatives Aufrufbudget | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-004` | ZIP-Extraktion: Speichergrenze für Binary- und Dateifassade | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-005` | Windows Directory Listing: feste Speicher-/Entrygrenze | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-009` | Windows Filesystem: getrennte ServiceAccount-Autorisierung | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-010` | Foundation-Handles: Pfadwechsel zwischen Prüfung und I/O | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-011` | Regex-Gruppenreplacement: vorzeitige Tokenallokation | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-016` | Queue-Barrier: Schedulerlock in Caller-Transaktion | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-017` | ResultTable-Deployment: Vertrauen in vorbestehenden Schemaowner | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-023` | Windows Filesystem: Reparse-/Rename-Race bei I/O | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-026` | Queue Claim: Handlerausführung versus Metadatensicht | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-027` | Second Session: ursprünglicher Caller versus Remote-Principal | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-040` | File-Content-Textread: Größe und Inhalt aus verschiedenen Reads | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-045` | Persistente Labverbindungen: Serverzertifikat nicht authentifiziert | P1 | offen (P1); Code integriert; Head-CI bestanden; authentifizierte TLS-Lab-Abnahme ausstehend; unabhängige Fachtests gemäß Benutzerklarstellung erlaubt |
| `SC-2026-046` | Queue Enqueue: Producerautorität je Work Type | P1 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-006` | JSON Pointer: kumulative Fragmentarbeit | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-013` | Unquoting: wiederholte LOB-Kopien bei dichten Quotes | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-015` | Cancellation: persistente Wachstums-/Retentiongrenze | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-018` | Zahlenreihen: maximaler angeforderter Umfang | P2 | implementiert; in main integriert; Head-CI bestanden; Legacygrants betreiberseitig beschränken |
| `SC-2026-019` | Base64: LOB-/Zwischenspeicherbudget | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-020` | Einfacher Split: Zeilen-/Inputexpansion | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-021` | URI-Konvertierung: Byte-/Zeilenexpansion | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-022` | JSON Path Exists: Frontier-/Arbeitsbudget | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-024` | EventLog: Retention bei maximalem Caller-Zeitstempel | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-038` | Console-Ausgabe: Gesamtmessage-/Framebudget | P2 | implementiert; in main integriert; Head-CI bestanden |
| `SC-2026-041` | Second Session: Payloadlimit vor ISJSON und RPC | P2 | implementiert; in main integriert; Head-CI bestanden |

## Security-Cloud-Abgleich — integrierter Stand 2026-10-15

### Bestätigter Cloudabschluss — 2026-10-15

Benutzerauftrag: nachweislich behobene Meldungen mit integrierten Fixes und
Testbelegen schließen und den Backlog nachziehen. Autor: Codex. Geprüfter
[Produktstand `97c6243`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/97c6243a1031b19ecde70e2db8cff7f777d39916),
mit unverändertem integriertem Produktcode aus PR #319.

**25 Commit-Scan-Einträge wurden tatsächlich als `fixed` geschlossen:** alle
16 Meldungen der 13 freigegebenen Korrekturen sowie neun weitere Meldungen
aus SC-001, SC-003, SC-025 und SC-036. Jede Meldung wurde zuvor einzeln gelesen;
der Abschluss verwendet ihre aktuelle Version und eine eigene Ursachen-,
Fix- und Testbegründung. Die Cloud speichert dabei öffentliche Commit-/Test-/CI-
Verweise und die jeweilige Nachweisgrenze. Die Duplikatgruppen bleiben im Backlog nachvollziehbar.

Die anschließende vollständige Cloudabfrage bestätigt **64 Einträge ohne
Folgeseite, 26 fixed / 38 new**. Alle 25 angeforderten Statuswechsel sind
bestätigt; keine andere Meldung änderte ihren Status. Die bereits geschlossene
SC-033 und die widerlegte Annahme SC-031 wurden nicht verändert.

| Bestätigter Cloudstatus | Einträge | Bedeutung |
|---|---:|---|
| fixed | 26 | 25 jetzt geschlossen; einer zuvor fixed |
| new — fachlich offen | 33 | 25 Designgruppen: 14 P1, 11 P2, alle Reife D/proposed |
| new — Source korrigiert, Cloudabschluss ausstehend | 4 | Repository-Scan-Meldungen zu SC-001, SC-003, SC-007 und SC-008 |
| new — Annahme widerlegt | 1 | SC-031; False-positive-Disposition ausstehend |
| Gesamt | 64 | unverändert 46 deduplizierte Ursachengruppen |

**Verbleibende Cloud-Metadatenarbeit:** Der verfügbare Abschlussconnector
unterstützt ausschließlich Commit-Scan-Meldungen. Die geöffnete Cloud-App
stellte in dieser Sitzung keinen steuerbaren App-Tab bereit. Deshalb bleiben
die vier Repository-Scan-Originale `csf_e2f99398dcd060693934facd` (SC-001),
`csf_129016cfee45980d62c7b93c` (SC-003), `csf_f07978ae04c2e64ac4908c27`
(SC-007) und `csf_e2f164b021a66f1aa6e787e6` (SC-008) ausdrücklich `new`.
Ihre Sourcefixes und Testbelege sind bestätigt; die Statuspflege ist kein
weiteres Implementierungspaket. SC-031 benötigt gegebenenfalls eine passende
False-positive-Disposition; der verfügbare Fixabschluss wird dafür nicht benutzt.

Scope: eine endliche Status-/Dokumentationswelle, ein Verantwortlicher, keine
neue Entwicklung, kein neuer Scan und keine Rechteänderung. Zusätzliche lokale
Prüfung am 2026-10-15: die statischen Contracts von File Content, Script Parser
und Integer Base jeweils erfolgreich. Für SC-036 bleibt neue SQL-Runtime-
qualifikation ausdrücklich NOT_EXECUTED; der Sourcefix und positive Testorakel
sind keine nachträglich behauptete Runtimeausführung. Die begrenzten
Framework-/SQL-/CI-Belege und ihre Grenzen stehen je Gruppe und im
[Umsetzungsnachweis](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md).

### Historischer Integrationsabgleich vor dem Cloudabschluss — 2026-10-15

Benutzerauftrag: PR #319 mergen, Backlog aktualisieren und sämtliche vorhandenen
Security-Cloud-Einträge erneut gegen den integrierten Code prüfen. Autor: Codex.
[PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) ist gemergt;
integrierter [Code `3d4f55f`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204).
Sein vollständiger Git-Tree ist identisch mit dem geprüften PR-Head
`7cc4650da381801536ecbfe77224703a81675efd`: 13 erfolgreiche Workflows,
45 erfolgreiche Checks und ein erwartungsgemäß übersprungener manueller Workload.
Der Arbeitsbranch von PR #319 wurde nach dem Merge gelöscht.

Die vollständige Cloudabfrage vor dem anschließenden Abschluss lieferte **64 Einträge ohne
Folgeseite**. Ihre IDs sind exakt einmal den vorhandenen **46 Gruppen**
zugeordnet; keine zusätzliche oder verlorene Meldung. Cloudstatus damals
**63 new / 1 fixed**. Dieser reine Abgleich änderte keine Cloudstatuswerte und war ein
Sourceabgleich vorhandener Meldungen, kein neuer Repositoryscan.

| Aktuelle Source-Disposition | Gruppen | Cloud-Einträge |
|---|---:|---:|
| Durch PR #319 korrigiert und integriert | 13 | 16 |
| Schon vor PR #319 im Source korrigiert, erneut bestätigt | 6 | 13 |
| Tatsächlich offen, Design/Vertragsentscheidung erforderlich | 25 | 33 |
| Bereits in Cloud fixed | 1 | 1 |
| Meldungsannahme widerlegt | 1 | 1 |
| Gesamt | 46 | 64 |

**Aktueller offener Security-Arbeitsvorrat:** 25 Gruppen, davon **14 P1 und
11 P2**, alle Reife **D** und Status `proposed`. Kein verbleibender offener
T-Punkt aus dieser Security-Triage; keine zusätzliche Implementierung freigegeben.
Die 13 freigegebenen Korrekturen sind `implemented` und integriert; ihre
16 Commit-Scan-Meldungen sind inzwischen geschlossen (aktueller Stand oben).
Neuer Scan und vollständige Release-/Windowsqualifikation sind davon getrennt.
Der [Umsetzungsnachweis](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md)
beschreibt die tatsächlich ausgeführten Tests und ihre Grenzen.

#### Abgeschlossene Korrekturwelle

| Gruppe | Inhalt | Priorität | Aktueller Entwicklungsstatus |
|---|---|---|---|
| `SC-2026-012` | JSON-Konstruktoren: Escapingbudget vor Materialisierung | P1 | implemented; mit PR #319 integriert |
| `SC-2026-014` | Regex: Größenprüfung vor CLR-LOB-Materialisierung | P1 | implemented; mit PR #319 integriert |
| `SC-2026-028` | ZIP-Listing: fehlerhafte sichere Pfadklassifikation | P1 | implemented; mit PR #319 integriert |
| `SC-2026-029` | Queue-Legacyupgrade: aktiver Claim nach Preflight | P1 | implemented; mit PR #319 integriert |
| `SC-2026-030` | Foundation-Budget: exakte Dezimalgrenze | P2 | implemented; mit PR #319 integriert |
| `SC-2026-032` | Barrier-Test: vorzeitigen Barrierclaim ausdrücklich verwerfen | P2 | implemented; mit PR #319 integriert |
| `SC-2026-034` | Foundation-HTTP: Remoteautorität vor Inputread | P1 | implemented; mit PR #319 integriert |
| `SC-2026-035` | Git-Dateigrößenhelper: escaped Logpfad | P2 | implemented; mit PR #319 integriert |
| `SC-2026-037` | Inline-TVF-Audit: Identifierparser ist MSTVF | P3 | implemented; mit PR #319 integriert |
| `SC-2026-039` | Error Envelope: direkte Ausgabe bei doomed Caller | P1 | implemented; mit PR #319 integriert |
| `SC-2026-042` | Persistenter Labadapter: catch-all privilegiertes Loopbackmapping | P1 | implemented; mit PR #319 integriert |
| `SC-2026-043` | Dokumentationsgenerator: Zielpfade vor --write validieren | P1 | implemented; mit PR #319 integriert |
| `SC-2026-044` | Windows-Smoke-Test: SQLCMD-Variablen werden überschrieben | P3 | implemented; mit PR #319 integriert |

Recheck-Methode: Alle 64 Referenzen wurden vollständig mit der Cloudliste
abgeglichen. Die zuvor geprüften Quellen wurden gegen `4903c25` gebunden.
Unveränderte fachliche Quellen behalten ihre belegten Befunde; geänderte
Verbraucher für SC-002/004/010/011/045 wurden gesondert gelesen und bleiben
offen. Die 13 integrierten Abwehren wurden am aktuellen Source geprüft.
Erneut ausgeführt am 2026-10-15: `test_security_maintenance.py` (3 Methoden),
`test_foundation_http_response.py` (10 Methoden/111 Szenarien) und
`test_foundation_redirects.py` (8 Methoden/204 Szenarien/105 Provenienzdateien),
jeweils erfolgreich. Kein neuer SQL-/Last-/Race-/Exploitnachweis allein aus
diesem Dokumentationsauftrag. Frühere gültige Runtime-/CI-Nachweise bleiben
an ihre ursprünglichen Ausführungen und den identischen Produktstand gebunden.

### Historischer Ausgangsabgleich — 2026-10-14

**Auftrag:** Benutzerauftrag vom 2026-10-14: sämtliche Security-Cloud-Einträge mit aktuellem Code abgleichen, Duplikate zusammenführen und tatsächlich offene Punkte mit Priorität und Entwicklungsreife festhalten. Autor: Codex. Reine Analyse-/Backlogpflege; keine Runtime-Implementierung, Cloud-Schließung, Rechteänderung oder Veröffentlichung.

**Quellbindung:** [Repositorystand `4903c25cc9f286bf5183954d16f09079b68221a9`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/4903c25cc9f286bf5183954d16f09079b68221a9), vollständige aktuelle Findingabfrage für `https://github.com/gecompat/SQL_Server_Toolbelt` mit 64 Ergebnissen und ohne Folgeseite. 54 Commit-Scan- und 10 Repository-Scan-Einträge; Cloudstatus 63 `new`, 1 `fixed`. Der Repositoryscan bezieht sich auf [`1694a016cdb5a8d611d0689431fbe1e07342513d`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d), nicht auf den aktuellen Code. Cloudschwere: 1 High, 39 Medium, 5 Low, 19 Informational.

**Abgleich:** Jeder der 64 Einträge ist genau einer der folgenden 46 Ursachen-/Vertragsgruppen zugeordnet; 18 Mehrfachmeldungen erzeugen kein eigenes Arbeitspaket. Verschiedene Actors, Sinks und fehlende Grenzen bleiben getrennt, auch wenn sie dieselbe Moduldatei betreffen. Insbesondere Queue-Producerautorität und Worker-Claimautorität sind keine Duplikate. Es gibt 38 offene Gruppen (49 Cloud-Einträge), 6 im Source korrigierte Gruppen (13 Einträge), 1 bereits in Cloud geschlossene Gruppe und 1 widerlegte Meldung. `new` ist kein Beweis eines aktuellen Exploits; ein Sourcefix ist keine vollständige Runtime-/Releasequalifikation.

### Historischer priorisierter Arbeitsvorrat vom 2026-10-14

Die folgenden D-/T-Einstufungen und offenen Zahlen dokumentieren den Stand
vor der Einzelfreigabe und Integration vom 2026-10-16. Aktuell gilt der
Abschnitt [Integrierte Security-Härtung](#integrierte-security-härtung--2026-10-16):
alle 25 Punkte sind freigegeben und ihr Code integriert; SC-045 bleibt bis
zur authentifizierten TLS-Abnahme offen, SC-018 bei untrusted Legacygrants.
Cloud-Metadatenstatus und tatsächliche Laufzeitnachweise bleiben getrennt.

#### Implementierungsfreigabe 2026-10-14 — Security-Korrekturwelle

Nach Besprechung von Zweck, konkreter Korrektur, Priorität, Alternativen,
Vertragsgrenzen und Akzeptanzprüfung hat der Benutzer ausdrücklich alle
13 technisch vorbereiteten Punkte freigegeben: SC-2026-012, -014, -028,
-029, -030, -032, -034, -035, -037, -039, -042, -043 und -044.
Auftrag: autonome Umsetzung mit Tests und Dokumentation, beginnend mit
SC-2026-034, SC-2026-042 und SC-2026-043. SC-039 umfasst die read-only
Direktausgabe bei uncommittable Caller und die gezielte Abweisung von
ResultTable-Mutation in diesem Zustand. SC-042 umfasst ausschließlich
vorhandene Testloginrechte und fail-closed Abweisung unsicherer persistenter
Mappings; keine Loginanlage oder Rechtevergabe.

Die 13 freigegebenen Korrekturen sind gezielt getestet und mit PR #319 in main
integriert (`implemented`; erfolgreiche PR-Head-CI). Reihenfolge: zuerst
SC-034, SC-042 und SC-043. Die übrigen 25 Designpunkte bleiben `proposed`.
Der [Umsetzungsnachweis](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md)
beschreibt alle 13 Änderungen, Prioritäten, ausgeführten Prüfungen und Grenzen. Das nachfolgende
Detailinventar erhält den historischen Ausgangsabgleich und ergänzt pro Gruppe den Recheck des integrierten Codes.
Gemeinsame endliche Arbeitsgrenze: genau diese 13 Korrekturen und deren
gekoppelte Artefakte/Prüfungen, ein Implementierungsverantwortlicher,
höchstens ein erforderlicher unabhängiger Reviewer; keine zusätzliche
Funktionswelle. Token-/Kostenverbrauch ist nicht zuverlässig gemessen.
Source-, Offline-, SQL- und CI-Nachweise bleiben getrennt; weder Freigabe
noch fertiger Code gelten als Runtime- oder Releasequalifikation.

Die folgenden Prioritäten wurden für diesen abgeglichenen Arbeitsvorrat gesetzt: **P1** für Autoritäts-, Daten-/Dateiintegritäts- und unmittelbare Ressourcen-/Fehlergrenzen; **P2** für weitere Kapazitätsverträge und begrenzte Qualitätskorrekturen; **P3** für Dokumentations-/manuelle Aufrufkorrekturen. Ein P0-Fall wurde durch diesen begrenzten Abgleich nicht nachgewiesen. Cloudseverity und Arbeitspriorität sind getrennt.

**Entwicklungsreife:** **D** = nicht entwicklungsreif, weil ein öffentlicher Vertrag, eine Sicherheits-/Delegationsgrenze, ein Ceiling oder ein Provider-/Labentscheid noch festzulegen ist. Die nachfolgende offene Liste enthält ausschließlich diese 25 D-Punkte. **T** bezeichnet in den historischen Details die technische Vorbereitung vor der ausdrücklichen Freigabe; die 13 betreffenden Korrekturen sind inzwischen integriert. Dieser Folgeauftrag autorisiert Merge und Status-/Backlogpflege, keine Umsetzung der verbleibenden D-Punkte.

| Gruppe | Inhalt | Priorität | Entwicklungsreife |
|---|---|---|---|
| `SC-2026-002` | RegexCount/RegexInstr: kumulatives Aufrufbudget | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-004` | ZIP-Extraktion: Speichergrenze für Binary- und Dateifassade | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-005` | Windows Directory Listing: feste Speicher-/Entrygrenze | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-009` | Windows Filesystem: getrennte ServiceAccount-Autorisierung | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-010` | Foundation-Handles: Pfadwechsel zwischen Prüfung und I/O | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-011` | Regex-Gruppenreplacement: vorzeitige Tokenallokation | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-016` | Queue-Barrier: Schedulerlock in Caller-Transaktion | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-017` | ResultTable-Deployment: Vertrauen in vorbestehenden Schemaowner | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-023` | Windows Filesystem: Reparse-/Rename-Race bei I/O | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-026` | Queue Claim: Handlerausführung versus Metadatensicht | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-027` | Second Session: ursprünglicher Caller versus Remote-Principal | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-040` | File-Content-Textread: Größe und Inhalt aus verschiedenen Reads | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-045` | Persistente Labverbindungen: Serverzertifikat nicht authentifiziert | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-046` | Queue Enqueue: Producerautorität je Work Type | P1 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-006` | JSON Pointer: kumulative Fragmentarbeit | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-013` | Unquoting: wiederholte LOB-Kopien bei dichten Quotes | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-015` | Cancellation: persistente Wachstums-/Retentiongrenze | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-018` | Zahlenreihen: maximaler angeforderter Umfang | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-019` | Base64: LOB-/Zwischenspeicherbudget | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-020` | Einfacher Split: Zeilen-/Inputexpansion | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-021` | URI-Konvertierung: Byte-/Zeilenexpansion | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-022` | JSON Path Exists: Frontier-/Arbeitsbudget | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-024` | EventLog: Retention bei maximalem Caller-Zeitstempel | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-038` | Console-Ausgabe: Gesamtmessage-/Framebudget | P2 | D — Entscheidung/Vertragsarbeit offen |
| `SC-2026-041` | Second Session: Payloadlimit vor ISJSON und RPC | P2 | D — Entscheidung/Vertragsarbeit offen |

Aktuell offen sind **14 P1- und 11 P2-Gruppen**, alle **25 D**. Die historischen **13 T** (8 P1, 3 P2, 2 P3) sind in der abgeschlossenen Korrekturwelle oben ausgewiesen. Vorrangige Autoritäts-/Integritätsfragen sind Remoteautorität, persistente Labmappings, Queue-/Second-Session-Delegation, Schemaownership und Schreibzielcontainment. Bereits korrigierte Präfix-/Tiefen-/Vorwächterfehler werden nicht erneut implementiert.

### Prüfmethode und Evidenzgrenzen

- Aktuelle Cloudtitel/-zusammenfassungen mit den tatsächlichen Sourcepfaden, gekoppelten Contracts und vorhandenen datierten Nachweisen abgeglichen. Historische Cloudzeilennummern wurden nicht als aktuelle Sourcepositionen übernommen. Die vollständige Zuordnung steht pro Gruppe unter „Cloudreferenzen“.
- Keine Original-Cloudberichte, privaten Endpoints, Secrets, freien Logs, Hashes von Labassemblies oder realen Runner-/Labwerte übernommen. Befundtexte sind eigenständig auf den zulässigen Code-/Vertragsscope verdichtet.
- Ausgeführt am 2026-10-14: `python -X utf8 -B Tests/Documentation/test_foundation_redirects.py` (8 Tests/204 synthetische Transportfälle, bestanden) und `python -X utf8 -B Tests/Documentation/test_foundation_http_response.py` (9 Methoden/87 synthetische Fälle, bestanden). Kein Netzwerk-/Provider-/SQLkontakt.
- Rein lesende Parametermetadatenprüfung mit Windows PowerShell 5.1: `(Get-Command Add-Type).Parameters.ContainsKey('LiteralPath')`; die Behauptung des fehlenden Parameters ist widerlegt. Bestätigt durch die [offizielle Microsoft-PowerShell-5.1-Referenz](https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/5.1/Microsoft.PowerShell.Utility/Add-Type.md). Kein Assemblyload, kein Writer-Gesamt-PASS.
- Zwei begrenzte Inlineproben mit `python -X utf8 -B -c`: `budget_decision` erlaubt bei neun synthetischen gemessenen Einträgen von je 0.01, nächster Reservation 0.01 und Hardlimit 0.1 weiterhin neue Arbeit; `OpenAICompatibleAdapter._invoke_common` erreicht bei `REMOTE` und `remote_authorized=False` den ausschließlich speicherinternen Fake-Read-/Send-Sink. Beide Restbefunde reproduziert. Keine echten Dateien gelesen/geschrieben, kein HTTP-/Modellaufruf.
- Übrige offene Codepfade wurden statisch abgeglichen; kein neuer SQL-, Last-, Race-, NTFS-, Identitäts- oder vollständiger Exploitnachweis wird behauptet. Die genannten Akzeptanzprüfungen sind nächste Arbeit, kein ausgeführter PASS.
- Die gezielte Backlogprüfung mit den vorhandenen Funktionen `validate_markdown_links` und `validate_unique_planning_ids` sowie einem endlichen Zuordnungscheck bestätigt 46 eindeutige Gruppen, 64 eindeutige Originalreferenzen, 38 offene Zeilen und die Prioritäts-/Reifezählung. `git diff --check` besteht. Vorhandener Backlogtext bleibt außerhalb der Einfügung identisch.
- Der bereits vor diesem Auftrag rote Dokumentationsgate wegen veralteter generierter Windows-Filesystem-Evidenz bleibt eine getrennte Wartungslücke. Dieser Analyseauftrag verändert weder Modulstatus noch fremde Evidenz.

### Vollständige Ursachen- und Quellenzuordnung

`SC-2026-` bezeichnet ausschließlich die hier neu vergebenen lokalen Triagegruppen, keine neuen fachlichen SQL-Funktionskandidaten. Die Cloudreferenzen verwenden die unveränderten ursprünglichen Finding-IDs; Art, Severity, historischer Cloudstatus des Ausgangsabgleichs und beobachteter Quellstand sind pro Originaleintrag erhalten. Der aktuelle bestätigte Abschluss steht bei den betroffenen Gruppen zusätzlich unter „Cloudabschluss 2026-10-15“.

#### SC-2026-001: File-Content: literale Root-Grenzen

- **Disposition:** im aktuellen Source korrigiert; Commit-Scan-Duplikate fixed, Repository-Scan-Abschluss ausstehend.
- **Cloudreferenzen:** `a7fa61e21f008191befcf814c0e32db8` (commit_scan, high, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/f7338a28471e4381a7a5b14268852fdd8f35f4e7)); `5dc3a494839481919d0d8c172431416d` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/b640d74458ab452699beccbda4065b0ee8a287f3)); `0f31af13aac881919d98828d639576af` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/80aa52f5e2a918f31ace67147ed6d0fd47f92b73)); `c980ddd1a99c81918de88889e59f6c9a` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a72cfe51d64763ccc59e025484bc1af96aa608d2)); `e9040a767a388191942fbb325f2fe1ee` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/ffb086865de228575c7330ad6adea53fc1bcf09b)); `csf_e2f99398dcd060693934facd` (repository_scan, low, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql](../Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql), [Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql](../Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql), [Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql](../Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql), [Modules/toolbelt.file.content/Tests/Runtime/RootBoundary.Contract.sql](../Modules/toolbelt.file.content/Tests/Runtime/RootBoundary.Contract.sql).
- **Abgleich:** Beide Fassaden verwenden jetzt dasselbe Queryfragment mit exakter Gleichheit oder einem literalen DirectoryPrefix einschließlich Separator und Bytelängen. Der frühere LIKE-Präfixfehler einschließlich Metazeichen ist entfernt. Das ist eine lexikalische Grenze, kein Symlink-/Race-Nachweis.
- **Nächster Schritt / Akzeptanz:** Keine erneute Implementierung des alten Präfixfixes; Cloud-Abschluss separat anhand des aktuellen Fixes und RootBoundary-Vertrags prüfen. Der getrennte Textread-Race bleibt SC-2026-040.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** 5 Commit-Scan-Meldungen bestätigt fixed; ein Repository-Scan-Original weiterhin new (fehlende verfügbare Abschlussfunktion). [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/6808b8273272b0ff579d0d54b379071b32448850), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.file.content/Tests/Runtime/RootBoundary.Contract.sql), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-002: RegexCount/RegexInstr: kumulatives Aufrufbudget

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_acbc515e6fd3aa84023f24d8` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)); `1c7bac4ff69c8191b981d5d506b79d18` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3e961410316a2d020a0e0e1601eed4ec67a3f927)); `bfb8af87629481919eb98c3c2fae8571` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/f216701dd641ec87aa1e951293b3560fa599eb5a)).
- **Aktuelle Bindung:** [Modules/toolbelt.string.regex/Clr/RegexProvider.cs](../Modules/toolbelt.string.regex/Clr/RegexProvider.cs), [Modules/toolbelt.string.regex/README.md](../Modules/toolbelt.string.regex/README.md).
- **Abgleich:** Die Match-/NextMatch-Schleifen verwenden weiterhin nur den MatchTimeout des einzelnen Regex-Vorgangs; es gibt in diesen R1b-Pfaden weder Gesamtdeadline noch kumulativen Iterationszähler. Die aktuelle README beschreibt ausdrücklich 250 ms je Engine-Suchschritt. Ein Gesamtbudget wäre daher eine zusätzliche Annahme-/Fehlergrenze; die TransformationContext-Grenze späterer APIs gilt hier nicht.
- **Nächster Schritt / Akzeptanz:** Kumulatives R1b-Budget, Match-/Iterationsgrenze und Fehlerpriorität besprechen; die heutige per-Suchschritt-Zusage nicht als bereits vorhandenen Gesamtvertrag ausgeben. Viele erfolgreiche/Empty-Matches und späte Treffer begrenzt qualifizieren; keine harte Echtzeitgarantie behaupten.
- **Recheck 2026-10-15:** Die neuen SqlChars-Einstiege delegieren Count/Instr weiterhin an den R1b-Kern mit 250-ms-Matchtimeout und wiederholtem NextMatch; ein kumulatives Count-/Instr-Budget wurde nicht eingeführt. Priorität, Reife D und proposed bleiben unverändert.

#### SC-2026-003: Windows Directory-Delete: Tiefe und Einträge

- **Disposition:** im aktuellen Source korrigiert; Commit-Scan-Duplikate fixed, Repository-Scan-Abschluss ausstehend.
- **Cloudreferenzen:** `csf_129016cfee45980d62c7b93c` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)); `54f47484e0f08191b032510be5c0a6b5` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/7515010865fc1427536aac9b13295e73546b3c6a)).
- **Aktuelle Bindung:** [Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs](../Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs), [Modules/toolbelt.filesystem.windows/Tests/README.md](../Modules/toolbelt.filesystem.windows/Tests/README.md).
- **Abgleich:** RemoveDirectoryBounded plant vollständig vor der Mutation, weist zu tiefe Kinder und zu viele Einträge ab und verwendet ausschließlich nichtrekursive Directory.Delete-Aufrufe. Die alte unkontrollierte rekursive Löschung ist entfernt. Der Windows-Abschluss vom 2026-10-13 qualifiziert nur seinen benannten Teilscope.
- **Nächster Schritt / Akzeptanz:** Altbefund nicht erneut als fehlender Tiefenfix planen. Die unabhängigen Race- und Speichergrenzen bleiben SC-2026-023 und SC-2026-005.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** Eine Commit-Scan-Meldung bestätigt fixed; ein Repository-Scan-Original weiterhin new (fehlende verfügbare Abschlussfunktion). [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/a16c22ce53f91779b803893f34d17f69bbabc20f), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.filesystem.windows/Tests/Framework/NoOverwriteHarness.cs), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644471688). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-004: ZIP-Extraktion: Speichergrenze für Binary- und Dateifassade

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_da1743e38c405a64696499c8` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)); `e3b086bd0c2081919d2c129b5b2f18cb` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3774ad3c02502157712888de0b288e18af91ec64)); `e6882df7e80c81919dcb91bd76478274` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/7a448ebf00437062901e2f1092bd8efd3cd8fccd)).
- **Aktuelle Bindung:** [Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs](../Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs), [Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql](../Modules/toolbelt.archive.zip-memory/Source/USP_ExtractZipEntryFromBinary.sql), [Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipEntryToFile.sql](../Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipEntryToFile.sql).
- **Abgleich:** MaxEntryBytes kann weiterhin bis int.MaxValue reichen. ReadPayload schreibt in einen MemoryStream und erzeugt anschließend mit ToArray eine weitere vollständige Kopie; die Dateifassade konsumiert diesen Binarypfad. Verhältnisprüfung ersetzt keine feste Heapgrenze.
- **Nächster Schritt / Akzeptanz:** Hard Ceiling, Profile und Verhalten bisher zulässiger großer Inputs besprechen; alternativ begrenzten Streamingpfad abgrenzen. Beide Fassaden, hohe Kompression, tatsächliche Bytes und Parallelaufrufe testen.
- **Recheck 2026-10-15:** Die Änderung an GetPathStatus betrifft nur Listingpfade. Der Extraktionspfad erlaubt weiterhin callerabhängige Limits bis Int32.MaxValue und materialisiert Payloads; ein neues Speicherceiling wurde nicht festgelegt. Priorität, Reife D und proposed bleiben unverändert.

#### SC-2026-005: Windows Directory Listing: feste Speicher-/Entrygrenze

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_acb1b696267d7ff4fc370f07` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)); `47b219f8ff908191a7975231879bf68c` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/24dd1fdf3a497d0bf1280b11593df9d39aac3429)); `a524201126408191a3f702aea3d04ecc` (commit_scan, low, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/96c65cd695d85640131e8a4619b79b0706bcd8c1)).
- **Aktuelle Bindung:** [Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs](../Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs), [Modules/toolbelt.filesystem.windows/Source/Procedures.sql](../Modules/toolbelt.filesystem.windows/Source/Procedures.sql).
- **Abgleich:** ListDirectory prüft nur maxEntries >= 1, übernimmt den callerwählbaren int und materialisiert ListedEntry-Objekte einschließlich Pfadstrings vollständig vor der Ausgabe. Eine feste obere Entry-/Bytegrenze fehlt.
- **Nächster Schritt / Akzeptanz:** Operativen Hard Ceiling beziehungsweise begrenzte Ausgabestrategie einschließlich Impersonation und Atomik festlegen. Große Bäume, lange Pfade und Überschreitung vor übermäßiger Allokation qualifizieren.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-006: JSON Pointer: kumulative Fragmentarbeit

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_b988f59961929cb71f34cee4` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql](../Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql), [Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md).
- **Abgleich:** 16-MiB-Input und Tiefe 128 sind unveränderliche Obergrenzen. Trotzdem parst OPENJSON je Pointersegment das aktuelle, möglicherweise fast gleich große Fragment erneut. Vorhandene synthetische Maximalläufe schließen keinen Heap-/Parallelitäts- oder kumulativen Arbeitsvertrag.
- **Nächster Schritt / Akzeptanz:** Kumulativen Aufwand und Parallelität begrenzt qualifizieren; danach Budgetstatus oder alternative Navigation unter Erhalt byteexakter Values entscheiden. Keine bereits bestandenen Maximalgrößenfälle als ungetestet führen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-007: Foundation-Provisioning: Redirect-Origin

- **Disposition:** im aktuellen Source korrigiert; Repository-Scan-Abschluss technisch ausstehend.
- **Cloudreferenzen:** `csf_f07978ae04c2e64ac4908c27` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [.ai/foundation/ai_provisioning/host_preparation.py](../.ai/foundation/ai_provisioning/host_preparation.py), [Tests/Documentation/test_foundation_redirects.py](../Tests/Documentation/test_foundation_redirects.py), [Documentation/Architecture/FOUNDATION_1_19_INTEGRATION.md](../Documentation/Architecture/FOUNDATION_1_19_INTEGRATION.md).
- **Abgleich:** _OriginBoundRedirectHandler prüft jeden Redirect vor Folgekontakt gegen den geplanten HTTPS-Origin; Download und Cost-Evidence verwenden _open_planned_https. Die gekoppelte synthetische Regression und der Targetoverride sind dokumentiert.
- **Nächster Schritt / Akzeptanz:** Cloud-Altstand gegen diesen Override reconciliieren. Kein reales DNS-/Netzwerk- oder Provisionierungs-PASS aus der Offlineprüfung ableiten.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** Repository-Scan-Original weiterhin new; Sourcefix bestätigt, Cloudabschluss wegen fehlender verfügbarer Abschlussfunktion ausstehend. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_foundation_redirects.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-008: Foundation-HttpAdapter: begrenzter Responsebody

- **Disposition:** im aktuellen Source korrigiert; Repository-Scan-Abschluss technisch ausstehend.
- **Cloudreferenzen:** `csf_e2f164b021a66f1aa6e787e6` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [.ai/foundation/ai_runtime_adapters/reference_adapters.py](../.ai/foundation/ai_runtime_adapters/reference_adapters.py), [Tests/Documentation/test_foundation_http_response.py](../Tests/Documentation/test_foundation_http_response.py), [Documentation/Architecture/FOUNDATION_1_19_INTEGRATION.md](../Documentation/Architecture/FOUNDATION_1_19_INTEGRATION.md).
- **Abgleich:** _read_http_body begrenzt den Read vor JSON-Parsing auf 16 MiB, behandelt kurze Reads, unvollständige Antworten und Cleanup separat. _request nutzt diesen Reader. Der historische unbounded-read-Befund trifft auf diesen Pfad nicht mehr zu.
- **Nächster Schritt / Akzeptanz:** Nur den konkreten Bodyread-Fix zum Cloud-Abschluss vorlegen; JSON-Tiefe, Gesamtzeit und reale Endpointqualifikation dadurch nicht schließen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** Repository-Scan-Original weiterhin new; Sourcefix bestätigt, Cloudabschluss wegen fehlender verfügbarer Abschlussfunktion ausstehend. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_foundation_http_response.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-009: Windows Filesystem: getrennte ServiceAccount-Autorisierung

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_f96db3c40b4a0e8a75158b17` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs](../Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs), [Modules/toolbelt.filesystem.windows/Source/Procedures.sql](../Modules/toolbelt.filesystem.windows/Source/Procedures.sql), [Modules/toolbelt.filesystem.windows/README.md](../Modules/toolbelt.filesystem.windows/README.md).
- **Abgleich:** ServiceAccount bleibt callerwählbar. CaptureCallerIdentity liefert dafür null, RunAs führt unter Dienstidentität aus; eine getrennte Modusberechtigung oder per-Root-Identitypolicy fehlt. EXECUTE plus Konfigurations-SELECT ist derzeit die dokumentierte gemeinsame Grenze, deshalb keine automatische Umdeutung bestehender Grants.
- **Nächster Schritt / Akzeptanz:** Berechtigungsmodell für Caller gegenüber ServiceAccount ausdrücklich entscheiden; kein GRANT und keine RunAs-Erweiterung ableiten. Positiv-/Negativfälle mit tatsächlich getrennten vorhandenen Rechten prüfen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-010: Foundation-Handles: Pfadwechsel zwischen Prüfung und I/O

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `csf_fb60517522ef41042bd26859` (repository_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1694a016cdb5a8d611d0689431fbe1e07342513d)).
- **Aktuelle Bindung:** [.ai/foundation/ai_runtime_adapters/reference_adapters.py](../.ai/foundation/ai_runtime_adapters/reference_adapters.py).
- **Abgleich:** safe_path prüft Path.resolve; spätere read_text/open/os.replace verwenden wieder Pfadnamen. Verzeichniswechsel nach der Prüfung bleiben möglich, falls ein anderer Actor den freigegebenen Root verändern darf.
- **Nächster Schritt / Akzeptanz:** Threatmodel und plattformfähige Handle-/NoFollow-Grenze für HTTP- und Commandadapter entscheiden; sichere Ownership-Voraussetzungen nur explizit festlegen. Synthetische Rename-/Symlink-Rendezvousfälle ohne fremde Dateien verwenden.
- **Recheck 2026-10-15:** Der neue Remoteautoritätscheck schützt die Invocationfreigabe. Handleprüfung über Path.resolve und späterer Dateizugriff bleiben getrennte Operationen; die Austausch-Race ist nicht dadurch geschlossen. Priorität, Reife D und proposed bleiben unverändert.

#### SC-2026-011: Regex-Gruppenreplacement: vorzeitige Tokenallokation

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `61c2b3af7f748191a050c987b02c8d5b` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8dcb7474accda118c8fbd5a19f64c43cebb17af8)).
- **Aktuelle Bindung:** [Modules/toolbelt.string.regex/Clr/RegexCaptures.cs](../Modules/toolbelt.string.regex/Clr/RegexCaptures.cs).
- **Abgleich:** ParseReplacement erstellt weiter eine List<ReplacementPart> mit Literalstrings pro Segment/Referenz. Das erste context.Remaining nach dem Parser kommt zu spät; eine Tokenobergrenze oder kompakte Darstellung fehlt.
- **Nächster Schritt / Akzeptanz:** Kompakten Parser mit periodischer bestehender Budgetprüfung ausarbeiten; eine neue Token-Hardgrenze benötigt Vertragsentscheidung. Dichte gültige Referenzen und Fehlerprioritäten prüfen.
- **Recheck 2026-10-15:** Die gemeinsame R2-Deadline und der begrenzte Intake ändern ParseReplacement nicht: Replacementteile werden weiterhin vor dem nachfolgenden Remaining-Check aufgebaut. Token-/Allokationsbudget bleibt offen. Priorität, Reife D und proposed bleiben unverändert.

#### SC-2026-012: JSON-Konstruktoren: Escapingbudget vor Materialisierung

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `ee96a665e6948191bf552080c57373e8` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/952b6a670d5affed18793e5c19c855468012b6fe)).
- **Aktuelle Bindung:** [Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql](../Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql), [Modules/toolbelt.json.constructors/Clr/JsonEntryEvaluateBridge.cs](../Modules/toolbelt.json.constructors/Clr/JsonEntryEvaluateBridge.cs), [Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs](../Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs).
- **Historischer Abgleich vor PR #319:** Der alte STRING_ESCAPE-/T-SQL-Unicode-Loop ist ersetzt, aber Stage0 liefert noch keine exakte Fragmentgröße. Stage1 fordert Evaluate(..., true) an; der gemeinsame Kern berechnet EscapedUnits und materialisiert Escape trotzdem. Das globale MaxResultBytes-Gate folgt erst nach Sammlung der Fragmente. Die Speicherexpansion bleibt als Restbefund.
- **Akzeptanzplanung vor PR #319:** Bestehendes globales Ergebnisbudget mit exakter Escapingkostenermittlung vor Fragmentallokation durchsetzen, ohne zweiten JSON-Kern. Dichte Kontrollzeichen, Keys, gruppierte Inputs und bisherige Fehlerpriorität testen; alte CPU-Loop-Meldung nicht unverändert wiederholen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Der SQL-Kern berechnet exakte Escapingkosten aller Einträge über begrenzte Spans desselben CLR-Kerns und prüft das Ergebnisbudget vor vollständigen Stringfragmenten. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.json.constructors/Tests/Runtime/JsonConstructors.Contract.sql), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472511). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-013: Unquoting: wiederholte LOB-Kopien bei dichten Quotes

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `6dbf312a39848191962b1c3a25fcb14f` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/f00626a0ee3519da9c7198ed028c55e146af5fdd)).
- **Aktuelle Bindung:** [Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql](../Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql).
- **Abgleich:** Der auf 65.536 Codeeinheiten begrenzte Parser hängt bei jedem verdoppelten Quote weiter an nvarchar(max) an. Die Grenze begrenzt Input, nicht kumulative Kopierarbeit; vorhandene Korrektheitsfälle sind keine Performancequalifikation.
- **Nächster Schritt / Akzeptanz:** Span-/Einmalaufbau unter unveränderter Unquotingsemantik entwerfen; alternativ neue Arbeitsgrenze besprechen. Dichte Quotes und APPLY-Workloads begrenzt messen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-014: Regex: Größenprüfung vor CLR-LOB-Materialisierung

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `b5774651954c8191a2f8874ba4f482ab` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1b0f16c767b1c8a12c7fa0b3014108e6e120c23e)).
- **Aktuelle Bindung:** [Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs](../Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs), [Modules/toolbelt.string.regex/Source/RegexFunctions.sql](../Modules/toolbelt.string.regex/Source/RegexFunctions.sql), [Modules/toolbelt.string.regex/Clr/RegexTransformations.cs](../Modules/toolbelt.string.regex/Clr/RegexTransformations.cs), [Modules/toolbelt.string.regex/Clr/RegexCaptures.cs](../Modules/toolbelt.string.regex/Clr/RegexCaptures.cs).
- **Historischer Abgleich vor PR #319:** Öffentliche max-Fassaden leiten Eingaben an CLR weiter; SqlString.Value materialisiert vor CheckSize. Auch Pattern, Flags und Profile sind betroffen. Größenlimits bestehen, greifen aber spät.
- **Akzeptanzplanung vor PR #319:** Vorhandene Profil-/Pattern-/Flaggrenzen vor vollständigen managed Kopien anwenden, beispielsweise mittels längenprüfender SqlChars-Intake oder sicherer Fassade. NULL-/Fehlerpriorität und keine Abschneidung erhalten; alle öffentlichen CLR-Pfade erfassen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Alle neun SQL-Einstiege binden SqlChars-basierte Bounded-Methoden. Length wird vor Read/Stringkopie geprüft; R2 verwendet dieselbe Deadline für Intake und Fachkern. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472010). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-015: Cancellation: persistente Wachstums-/Retentiongrenze

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `5d9e80c1737c819189bf75a6140bbeb7` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/be1839780e7213da6bba785ebaaeaf6d2a9510ac)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql](../Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql), [Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql](../Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql).
- **Abgleich:** Jede neue gültige ExecutionId darf eine dauerhafte Cancellationzeile erzeugen. Es existiert kein Executionregister-Abgleich, Quotavertrag oder unterstützter Purge; Irreversibilität ist derzeit ausdrücklich Teil des Vertrags.
- **Nächster Schritt / Akzeptanz:** Retention, zugelassene IDs oder administrative Quoten besprechen. Keine heimliche Löschung und kein Abschwächen der irreversiblen Cancellation.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-016: Queue-Barrier: Schedulerlock in Caller-Transaktion

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `7c85ea21678c8191857dba5eeed8f8ed` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/0ce9e962cf4ab6a8a7476c300aa8f7aed403a572)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql](../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql), [Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql](../Modules/toolbelt.core.work-queue/Source/USP_EnqueueBarrierWork.sql), [Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql](../Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql).
- **Abgleich:** Der Policy-Enqueue verwendet bei aktiver Caller-TX einen Savepoint. DRAIN_BARRIER hält UPDLOCK/HOLDLOCK auf der globalen Schedulerzeile bis zum äußeren Commit; Claims benötigen dieselbe Zeile. Eine gruppenlokale Barrier kann so globale Claims blockieren.
- **Nächster Schritt / Akzeptanz:** Barrier-spezifische TX-Ablehnung oder alternative Mutexlebensdauer besprechen, weil Enqueue-Caller-TX aktuell erlaubt sind. Zwei Sessions und unabhängige Gruppen mit begrenztem Rendezvous prüfen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-017: ResultTable-Deployment: Vertrauen in vorbestehenden Schemaowner

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `8384333831ac81919df287cf3616ff4e` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3fbecb532a13b72fc3ce38effe7e0d4899837c89)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.result-table/Deployment/Deploy.sql](../Modules/toolbelt.core.result-table/Deployment/Deploy.sql).
- **Abgleich:** Bestehendes toolbelt_core wird anhand ALTER-Recht akzeptiert; eine Schemaowner-/effektive CONTROL-Policy fehlt. Objektmarker und Locking schließen spätere Manipulation durch einen untrusted Schemaowner nicht aus.
- **Nächster Schritt / Akzeptanz:** Kompatible Trustpolicy für bestehende gemeinsam genutzte Schemas beschließen. Fremdes leeres Schema, Owner und indirekte Kontrollrechte negativ testen; kein automatischer Ownertransfer oder Rechteentzug.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-018: Zahlenreihen: maximaler angeforderter Umfang

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `6b48cd8901cc8191958fe318335aa453` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/997e93af2ab0f86904c2461f0ca127a0cf55873c)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql](../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql), [Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql](../Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesInt.sql).
- **Abgleich:** RequestedRows steuert TOP über E64; es gibt keinen operativen Ceiling unterhalb des mathematischen bigint-Bereichs. Äußere TOP-Rowgoals schützen nicht Aggregation oder INSERT aller angeforderten Zeilen. Der breite Wertebereich ist gewollter Bestandvertrag.
- **Nächster Schritt / Akzeptanz:** Vertrauensgrenze, begrenzte neue Oberfläche oder Hard Ceiling entscheiden. Keine riesige Reihe erzeugen und keinen mathematischen Kompatibilitätsvertrag stillschweigend verkleinern.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-019: Base64: LOB-/Zwischenspeicherbudget

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `7bbee6623ae88191821d6292c99dc1d5` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/074e98e00e3e59d872ebf25b09fa8772f3b03c54)).
- **Aktuelle Bindung:** [Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql](../Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql), [Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql](../Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql).
- **Abgleich:** Die SVFs delegieren inzwischen an TVFs; XML-Materialisierung und volle REPLACE-Kopien im kanonischen Kern besitzen weiter keinen operativen LOB-Ceiling. Die Wrapperumstellung allein schließt die Ressourcenfrage nicht.
- **Nächster Schritt / Akzeptanz:** Größenprofile und Oversize-Semantik einschließlich kompatibler bestehender Aufrufe besprechen. Eingabe, Expansion und Parallelität vor XML-Arbeit begrenzen/qualifizieren.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-020: Einfacher Split: Zeilen-/Inputexpansion

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `d742ef1db0f48191962a40788db9cc67` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/b9416f8297b069e6a681e593f376c09d50bc9169)).
- **Aktuelle Bindung:** [Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql](../Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql).
- **Abgleich:** InputLength aus nvarchar(max) fließt in GenerateSeries; LEAD/ROW_NUMBER über Separatorgrenzen und KeepEmpty können sehr große Rowsets erzeugen. Es gibt keinen operativen Input-/Token-Ceiling.
- **Nächster Schritt / Akzeptanz:** Kompatible Input-/Token-/Separatorarbeitsgrenze entscheiden; Separator-only und APPLY-Fälle mit begrenzten synthetischen Inputs testen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-021: URI-Konvertierung: Byte-/Zeilenexpansion

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `2a008add79d0819196ca6b3459eb226b` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/38af40811d1f06a8c3647170015e14aa80aed1ef)).
- **Aktuelle Bindung:** [Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql](../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql), [Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql](../Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql).
- **Abgleich:** Die kanonischen TVFs materialisieren UTF-8-/Hexdarstellungen und GenerateSeries pro Byte beziehungsweise Codeeinheit. SVF-Wrapper haben kein vorgeschaltetes Ressourcenbudget.
- **Nächster Schritt / Akzeptanz:** Input-/Output-/Arbeitsprofile und Fehlervertrag besprechen. Grenzen müssen vor GenerateSeries/STRING_AGG greifen; Unicode- und Wrapperparität erhalten.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-022: JSON Path Exists: Frontier-/Arbeitsbudget

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `cc75398d6d588191a8ff40725dca0c7e` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8f18a58401178f1efe7469b85eac1f53fc35c186)); `48877b4426288191b1a1f8da7014da7a` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/13be436fa31541d15c213edc500b7827e28b3809)).
- **Aktuelle Bindung:** [Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql](../Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql).
- **Abgleich:** Nur der Pfad ist auf 4.000 Codeeinheiten begrenzt. Json ist max; Frontiers materialisieren verschachtelte Fragmente, Wildcards vervielfachen sie, OPENJSON läuft pro Segment. Byte-/Frontier-/kumulative Budgets fehlen.
- **Nächster Schritt / Akzeptanz:** Budgets und deren Darstellung im bisherigen 0/NULL-Vertrag besprechen. Tiefe große Fragmente und Wildcardfrontiers begrenzt qualifizieren; keine neue Statussemantik ohne Freigabe.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-023: Windows Filesystem: Reparse-/Rename-Race bei I/O

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `b4f06ce6b2f48191b42232c0dd5a19fe` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/6afebf2314d2da512ba01fd1dbeae17ed91ac380)).
- **Aktuelle Bindung:** [Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs](../Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs), [Modules/toolbelt.filesystem.windows/Tests/Manual_Windows_Runtime_Testplan.md](../Modules/toolbelt.filesystem.windows/Tests/Manual_Windows_Runtime_Testplan.md).
- **Abgleich:** AssertNoReparsePoint prüft Pfadkomponenten, spätere FileStream/Move/Replace/Delete öffnen wieder nach Namen. Frische Delete-Prüfungen und der bestandene begrenzte Racekorpus sind keine atomare Handlebindung für sämtliche Lese-/Schreib-/Transcodingpfade.
- **Nächster Schritt / Akzeptanz:** Handlegebundene Traversierung/I/O oder explizit eingeschränkte Root-Ownership entscheiden. Alle betroffenen APIs und beide Identitäten prüfen; vorhandenen Sentinel-Teilerfolg getrennt erhalten.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-024: EventLog: Retention bei maximalem Caller-Zeitstempel

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `a1daef31e0188191a1c3dfe773de15f6` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/6b0834752c33544f5310dc679df4f45ae3b6e094)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql](../Modules/toolbelt.core.event-log/Source/USP_WriteEvent.sql), [Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql](../Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql), [Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql](../Modules/toolbelt.core.event-log/Source/USP_DeleteEventsBefore.sql).
- **Abgleich:** OccurredAtUtc ist callerbestimmt; Retention verwendet strikt OccurredAtUtc < cutoff. Das maximale datetime2(7) ist durch keinen zulässigen späteren cutoff erfassbar. RecordedAtUtc steuert diese Retention nicht.
- **Nächster Schritt / Akzeptanz:** RecordedAt-basierte Retention, Zeitfenster oder zusätzliche Grenzbereinigung besprechen. Keine bestehende Retention heimlich von Ereigniszeit auf Erfassungszeit umstellen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-025: ScriptDom: vorgeschalteter nichtrekursiver Wächter

- **Disposition:** im aktuellen Source korrigiert und alle zugeordneten Cloudmeldungen fixed.
- **Cloudreferenzen:** `d26299210ac481918c7d9f7677b911f4` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/50ae2351abac173f7fbdba24c74c716d3afc44df)); `efbaa6546ec0819190d43fdb6263bda9` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d77e572da03212bfba98c7c82ffd18d6cf63d4db)).
- **Aktuelle Bindung:** [Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs](../Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs), [Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs](../Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs), [Modules/toolbelt.tsql.script-parser/Tests/README.md](../Modules/toolbelt.tsql.script-parser/Tests/README.md).
- **Abgleich:** PreparseGuard.Guard läuft jetzt vor parser.Parse, mit festen Input-/Strukturgrenzen. Die aktuelle Windows-2025-/CL150/160/170-Qualifikation des neuen Pins ist seit 2026-10-11 dokumentiert. Historische Meldungen beschreiben den früheren Parser.
- **Nächster Schritt / Akzeptanz:** Altbefunde auf den Wächterfix abgleichen. Allgemeine Stackgarantie, Windows 2019/2022 und tatsächliche Ausgabeceilings bleiben bestehende Qualifikationsgrenzen, kein Nachweis eines weiterhin fehlenden Vorwächters.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** Alle 2 zugeordneten Commit-Scan-Meldungen bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/fc0b2e2a11ad63912e2f0fa421e664683aff9941), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.tsql.script-parser/Tests/README.md). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-026: Queue Claim: Handlerausführung versus Metadatensicht

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `ceab6a1c8cf08191b58a4fd37f52063f` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/e7a9dcf235a30f9c64b36252d2de6de14345e61d)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql](../Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql).
- **Abgleich:** Die Claimkandidaten joinen weiter sys.procedures, ohne effektives Handler-EXECUTE oder explizite Work-Type-Workerzuordnung zu prüfen. Lease/Recovery verhindern nicht die ursprüngliche unberechtigte Payload-/Claimausgabe.
- **Nächster Schritt / Akzeptanz:** Worker-Autorisierungsmodell für direkten und Managedclaim festlegen; tatsächlich sichtbarer, aber nicht ausführbarer Handler als Negativfall. Keine automatische grantbasierte Erweiterung.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-027: Second Session: ursprünglicher Caller versus Remote-Principal

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `3ef2d67e50648191aa4959c7cbcdc590` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d3f1ac13f740702aefb38763e59f1e0814b11b33)); `0fb8c445332481919ceac7a8a6b4e926` (commit_scan, medium, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/843c2bffd373022fa2df78787bf8605e7b78c680)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql](../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql), [Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql](../Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql), [Documentation/Architecture/SECOND_SESSION_MODULE_DESIGN.md](../Documentation/Architecture/SECOND_SESSION_MODULE_DESIGN.md).
- **Abgleich:** Die lokale Procedure prüft Work-Type-/Payloadstatus; nur der Dispatcher prüft EXECUTE unter dem gemappten Remote-Principal. Ein fixes privilegiertes Mapping kann dadurch Originalcallerrechte überbrücken. Der dokumentierte Bestandvertrag beschreibt ausdrücklich die Remoteprüfung.
- **Nächster Schritt / Akzeptanz:** Delegations-/Callerautorität entscheiden und getrennte Principals qualifizieren. Ein bloßer lokaler HAS_PERMS-Check darf legitime bewusst delegierte Work Types nicht ohne Vertragsentscheidung umdefinieren.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-028: ZIP-Listing: fehlerhafte sichere Pfadklassifikation

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `33c43ab2ab7c8191a278b044f5e98dda` (commit_scan, low, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/82bb907ac2f9ec2e6315dec8c7db8ca5a07be42d)); `02aeb70dbd0481918a23825495e77cfd` (commit_scan, low, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/235a83d1bc9530128c91277c3157960c10f96d1a)); `4b0f632d4dc08191bbb0ccda83f16be8` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/05e13b1ff97f69f922e0f6287678d48bfa84d7a7)); `c8e2a2bee4a08191b168d72e2cd72f1b` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/07052905a008c29ce3e3e021fbe097e1996d952a)).
- **Aktuelle Bindung:** [Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs](../Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs), [Documentation/Architecture/ZIP_METADATA_MODULE_DESIGN.md](../Documentation/Architecture/ZIP_METADATA_MODULE_DESIGN.md).
- **Historischer Abgleich vor PR #319:** GetPathStatus erkennt Laufwerkprefix nur mit anschließendem Slash/Backslash. C:child und der exakte Name .. erreichen weiterhin PathSafe. Dies ist ein Metadatenvertragsfehler; das Listing schreibt selbst keine Dateien.
- **Akzeptanzplanung vor PR #319:** Bestehende relative-kanonische Pfadzusage für Drive-relative und Dotsegmente durchsetzen. Listing-/Writerregressionen koppeln; IsPathSafe weiterhin nicht als OS-Containmentautorität darstellen.
- **Recheck 2026-10-15 vor Cloudabschluss:** GetPathStatus weist jeden Laufwerksprefix, alleinstehendes .. sowie nicht kanonische Dotsegmente ab. Listingvektoren und native Reader-/Writer-Verträge bestanden. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Alle 4 zugeordneten Commit-Scan-Meldungen bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644471958). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-029: Queue-Legacyupgrade: aktiver Claim nach Preflight

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `411ece02a76081919c530b7b14ec5a87` (commit_scan, low, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/8ca1b953546894c33e8bf7d18e2612cf51a7f682)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.work-queue/Deployment/Deploy.sql](../Modules/toolbelt.core.work-queue/Deployment/Deploy.sql), [Modules/toolbelt.core.work-queue/Source/WorkItem.sql](../Modules/toolbelt.core.work-queue/Source/WorkItem.sql).
- **Historischer Abgleich vor PR #319:** Der aktive Legacyclaimcheck steht vor Deployment-TX/AppLock. Unter dem Lock wird Version/Managedhold geprüft, nicht derselbe Legacyclaimzustand unter claimverhindernder Sperre. Der Backfill kann später hinzugekommene Claims in eine abgeleitete Lease überführen.
- **Akzeptanzplanung vor PR #319:** Bestehende Zusage 'kein Upgrade aktiver Legacyclaims' atomar bis zur Migration sichern. Zwei Sessions und genuine 1.0/1.1 mit claimendem Consumer deterministisch testen; historische Repeat-PASS ersetzen diesen Racefall nicht.
- **Recheck 2026-10-15 vor Cloudabschluss:** Aktive Legacyclaims werden in der Deploymenttransaktion unter TABLOCKX/HOLDLOCK erneut geprüft; die Sperre bleibt bis Transaktionsende. Zwei synchronisierte native Sessions belegen Abweisung und Sperrwirkung. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/CI/run-security-contracts-lab.ps1), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644471853). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-030: Foundation-Budget: exakte Dezimalgrenze

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P2**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `f0766873158881918ff88979771ee74b` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/cdae623bd9e9c33f8cfd4bdf0f260ada4327d418)).
- **Aktuelle Bindung:** [.ai/foundation/runtime/processing_efficiency.py](../.ai/foundation/runtime/processing_efficiency.py), [.ai/foundation/schemas/processing-budget-request.schema.json](../.ai/foundation/schemas/processing-budget-request.schema.json).
- **Historischer Abgleich vor PR #319:** _amount erlaubt floats; measured/estimated/reserved werden mit normaler Addition summiert und projected >= hard verglichen. Exakte Dezimalgrenzen können binär unterrepräsentiert werden. Das optionale Hilfsmodul ist ohnehin keine Provider-Spending-Enforcement.
- **Akzeptanzplanung vor PR #319:** Exakte Dezimal-/Fixed-scale-Abrechnung innerhalb des vorhandenen Schemas festlegen und Grenzregressionen ausführen; Foundation-Provenienz als Targetoverride erhalten, nicht direkt als Upstreamfix ausgeben.
- **Recheck 2026-10-15 vor Cloudabschluss:** Budgetaddition und Vergleiche verwenden Fraction aus validierten Dezimaldarstellungen; der numerische JSON-Vertrag bleibt erhalten. Exakte Grenz- und Dedupfälle bestanden. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_security_maintenance.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-031: ZIP-Writertest: behauptetes Add-Type-LiteralPath-Problem

- **Disposition:** Meldungsannahme widerlegt; kein Reparaturpaket.
- **Cloudreferenzen:** `201ede93ad108191b432b0e49b85a2da` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d487b832e51fcecb842eb95684be9effe15cdf7e)).
- **Aktuelle Bindung:** [Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1](../Modules/toolbelt.archive.zip-memory/Tests/Runtime/Writer.Framework.ps1), [.github/workflows/zip-memory-runtime.yml](../.github/workflows/zip-memory-runtime.yml).
- **Abgleich:** Die zugrunde liegende Behauptung ist widerlegt: Microsofts PowerShell-5.1-Referenz führt das FromLiteralPath-Parameterset auf. Eine rein lesende Parameterprüfung mit Windows PowerShell 5.1 bestätigte LiteralPath. Das qualifiziert nicht den gesamten Writerlauf.
- **Nächster Schritt / Akzeptanz:** Kein kompatibilitätsbedingter Rückbau von LiteralPath. Falls eine konkrete CI künftig fehlschlägt, deren tatsächlichen Fehler getrennt diagnostizieren.
- **Recheck 2026-10-15:** Die LiteralPath-Aufnahme bleibt vorhanden; der ZIP-Framework-/Buildworkflow bestand am integrierten Produktstand. Die widerlegte Annahme wird nicht als offener Reparaturpunkt geführt.

#### SC-2026-032: Barrier-Test: vorzeitigen Barrierclaim ausdrücklich verwerfen

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P2**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `c80fe30a8a6c81918004aa1125fe6b89` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/fdb220bbc09e50f6ddd02949634fd1e003215276)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.work-queue/Tests/Runtime/WorkQueue.Contract.sql](../Modules/toolbelt.core.work-queue/Tests/Runtime/WorkQueue.Contract.sql), [Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql](../Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql).
- **Historischer Abgleich vor PR #319:** Die Fixture verwirft nur neue SHARED-Claims; ein zu früh CLAIMED gesetztes Barrieritem würde vor Blockercompletion nicht ausdrücklich abgewiesen. Der Produktkern besitzt derzeit die unresolved-Blocker-Abwehr; dies ist ein Testorakelfehler, kein daraus bewiesener Produktfehler.
- **Akzeptanzplanung vor PR #319:** BARRIER_WAIT beziehungsweise Nichtclaim der konkreten Barrier vor Completion assertieren. Begrenzte negative Injektion muss den fehlerhaften Zustand zuverlässig verwerfen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Der Contract verlangt vor Blockerabschluss BARRIER_WAIT und keinen Barrierclaim im Resultset. Zwei negative Injektionen des tatsächlichen Assertblocks bestanden. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/CI/run-security-contracts-lab.ps1), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644471853). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-033: Historische Restgate-Anzahl

- **Disposition:** bereits in Cloud fixed.
- **Cloudreferenzen:** `d348a67e091c81918ad6ee47cd1d5318` (commit_scan, informational, fixed; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9cfce71bd349d63bbfa2bc052cad499e741f27cc)).
- **Aktuelle Bindung:** [.ai/BACKLOG.md](../.ai/BACKLOG.md), [Modules/README.md](../Modules/README.md).
- **Abgleich:** Dieser einzige Cloud-Eintrag ist bereits fixed. Aktuelle Manifestzählung trennt 44 Module mit 18 validated/26 partially validated von den historischen sieben V0-Kategorien; aus verschiedenem Scope folgt keine neue identische Acht-versus-sieben-Meldung.
- **Nächster Schritt / Akzeptanz:** Keine neue Reparatur dieses geschlossenen historischen Befunds. Bei späterer Releaseplanung konkrete offene Kriterien je Modul fortschreiben statt Kategorien mit Modulanzahlen gleichzusetzen.
- **Recheck 2026-10-15:** Cloudstatus weiterhin fixed; die aktuellen 44 Modulmanifeste und die historische Restgate-Kategorie bleiben getrennte Zählungen.

#### SC-2026-034: Foundation-HTTP: Remoteautorität vor Inputread

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `0b2660106eb08191b1a3231609256915` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/85aaf452f20203123d3603bc2c9689d413d715ea)).
- **Aktuelle Bindung:** [.ai/foundation/ai_runtime_adapters/reference_adapters.py](../.ai/foundation/ai_runtime_adapters/reference_adapters.py), [.ai/foundation/ai_runtime_adapters/runtime_mcp.py](../.ai/foundation/ai_runtime_adapters/runtime_mcp.py), [.ai/foundation/ai_orchestrator/ai_orchestrator.py](../.ai/foundation/ai_orchestrator/ai_orchestrator.py).
- **Historischer Abgleich vor PR #319:** _invoke_common prüft erlaubte Datenklassen, aber fordert remote_authorized nicht für LOCAL_NETWORK/REMOTE/UNKNOWN. Nur Ollama-Cloudtags haben einen speziellen Check. OpenAI-compatible und gewöhnliche Ollama-Modellnamen können weiterhin vor expliziter Einzelautorität Input lesen und versenden.
- **Akzeptanzplanung vor PR #319:** Bestehende Remoteautoritätsgrenze gemeinsam vor Inputread/Netzwerksink durchsetzen. Fake-Sinks müssen false/fehlend für alle Provider und Remotegrenzen ohne Read/Send verwerfen; keine echten Dateien übertragen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die gemeinsame HTTP-Invocation fordert bei LOCAL_NETWORK/REMOTE/UNKNOWN exakt remote_authorized=True vor Handleauflösung, Inputread und Transport. Beide Provider sind durch Fake-Sinks geprüft. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_foundation_http_response.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-035: Git-Dateigrößenhelper: escaped Logpfad

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P2**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `b3c47ecc325481919702e2139f055373` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/bffca3a923b0bdbded5b6cc5e380a54233969d13)).
- **Aktuelle Bindung:** [CheckLargeGitFilesPush.ps1](../CheckLargeGitFilesPush.ps1).
- **Historischer Abgleich vor PR #319:** LogFileName wird nur auf IsPathRooted geprüft; Join-Path plus Out-File erlaubt relative ..-Ausbrüche, sobald eine große Datei gefunden wird. Keine vorhandene Workflowintegration erhöht den Scope; dies ist ein lokaler Toolingfehler.
- **Akzeptanzplanung vor PR #319:** Dokumentierte Repositoryrelativität vor Directoryanlage/Write kanonisch durchsetzen und Reparse-/Gitmetadaten schützen. Nur eigene synthetische Tempverzeichnisse für Negativfälle nutzen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Das Logziel wird kanonisch innerhalb des Repositorys, außerhalb Gitmetadaten, ADS, Windows-Aliaspfaden und vorhandenen Reparsekomponenten gehalten; erneute Prüfung vor Write und LiteralPath-Ausgabe. Synthetische Negativfälle bestanden. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_security_maintenance.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-036: Integer Base: Plus als Alphabetziffer

- **Disposition:** im aktuellen Source korrigiert und alle zugeordneten Cloudmeldungen fixed.
- **Cloudreferenzen:** `2e440c30453c8191b11709c9acdc8f33` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d9fb7f842ee4b855c1cbd31611cc5ec782d920db)).
- **Aktuelle Bindung:** [Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql](../Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql), [Modules/toolbelt.conversion.integer-base/Source/SVF_TryBaseToInteger.sql](../Modules/toolbelt.conversion.integer-base/Source/SVF_TryBaseToInteger.sql), [Modules/toolbelt.conversion.integer-base/Tests/Runtime/IntegerBase.Contract.sql](../Modules/toolbelt.conversion.integer-base/Tests/Runtime/IntegerBase.Contract.sql).
- **Abgleich:** Die SVF verwendet den kanonischen Decoder; nur '-' wird als Vorzeichen erkannt, '+' wird über das Alphabet geprüft. Positive Fälle mit 0+1 und negative Fälle ohne erlaubte Plusziffer sind vorhanden. Die Korrektur wurde mit PR308 integriert.
- **Nächster Schritt / Akzeptanz:** Altbefund anhand des aktuellen relationalen Fixes reconciliieren; keine Alphabetverkleinerung auf Basis der historischen Meldung.
- **Recheck 2026-10-15 vor Cloudabschluss:** Die bestehende Sourcekorrektur bleibt im integrierten Code erhalten. Keine Rücknahme durch PR #319; Cloudstatus weiterhin separat new.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1fb13198ec767fc4373ab9ebaadd4aeb29f7b557), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.conversion.integer-base/Tests/README.md). Source und statischer Contract geprüft; neue SQL-Runtimequalifikation für diesen Fix NOT_EXECUTED.

#### SC-2026-037: Inline-TVF-Audit: Identifierparser ist MSTVF

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P3**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `a884492147cc819199b2a71850d9c8e8` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/d3ba7c6112560589be4678a1907b497a53409769)).
- **Aktuelle Bindung:** [Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md](../Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md), [Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql](../Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql).
- **Historischer Abgleich vor PR #319:** Die Auditzeile nennt die QuoteMultipartName-Anforderung erfüllt, der Parser besitzt RETURNS @Result TABLE und BEGIN. Die Inlineeigenschaft ist damit nicht belegt. Das ist eine Architektur-/Dokumentationsinkonsistenz ohne neuen Security-Exploit.
- **Akzeptanzplanung vor PR #319:** Auditwahrheit korrigieren und relationale Alternative oder begründete Ausnahme als getrennte Designfrage erfassen. Kein neues Parserobjekt aus diesem Dokumentationsfix ableiten.
- **Recheck 2026-10-15 vor Cloudabschluss:** Der Audit benennt den Identifierparser ausdrücklich als MSTVF und die Inlineeigenschaft als nicht nachgewiesen. Alternative/Ausnahme bleibt getrennte Designarbeit; kein neues Parserobjekt wurde implementiert. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-038: Console-Ausgabe: Gesamtmessage-/Framebudget

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `21b0c8a6c5fc8191988f8346172debb7` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9ce5614d217dc53b214c470714f98284dd736644)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql](../Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql).
- **Abgleich:** PRINT/NOWAIT begrenzen nur einzelne Frames. Die gesamte nvarchar(max)-Message wird vollständig in einer Schleife versendet, ohne Gesamtbyte-/Frameceiling.
- **Nächster Schritt / Akzeptanz:** Gesamtbudget und Ablehnung statt heimlicher Trunkierung besprechen. Client-/Treiberfälle und Parallelaufrufe getrennt von Framekorrektheit prüfen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-039: Error Envelope: direkte Ausgabe bei doomed Caller

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `bfd8c09a76448191afe80996f6a1a6ab` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9dd8d2fc86509b3769d7ee78e29064dc300cfb70)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql](../Modules/toolbelt.core.error-envelope/Source/USP_CaptureErrorEnvelope.sql), [Modules/toolbelt.core.error-envelope/Examples/ErrorEnvelope.sql](../Modules/toolbelt.core.error-envelope/Examples/ErrorEnvelope.sql).
- **Historischer Abgleich vor PR #319:** Beide Temp-Tabellen und der INSERT werden weiter vor der @ResultTable-NULL-Verzweigung ausgeführt. Im uncommittable Caller kann die Envelope-Erzeugung den ursprünglichen Fehler durch eigene schreibende Arbeit verdecken.
- **Akzeptanzplanung vor PR #319:** Die dokumentierte CATCH/THROW-Verwendung mit einem tatsächlich read-only direkten Pfad schützen. ResultTable-Mutation bei doomed Caller explizit abgrenzen; Originalfehler und Transaktionszustand im Enginefall testen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Direkte Ausgabe läuft vor Temp-DDL/INSERT, auch bei XACT_STATE()=-1. ResultTable wird dann mit 51406 vor Mutation abgewiesen. Original-Rethrow, Callerzustand, 14 Clientspalten und Debugmeldung wurden geprüft. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/CI/run-security-contracts-lab.ps1), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472232). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-040: File-Content-Textread: Größe und Inhalt aus verschiedenen Reads

- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `83cbb105b7e08191a4e7b1f089b2d965` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/f35a168cb2a839091aa7990369d8d673ff1ab8a6)).
- **Aktuelle Bindung:** [Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql](../Modules/toolbelt.file.content/Source/USP_LoadTextFile.sql).
- **Abgleich:** SINGLE_BLOB erfasst Header/BytesRead, danach öffnet SINGLE_CLOB/SINGLE_NCLOB denselben Pfad erneut. Der zweite Contentread wird erfolgreich ausgegeben, ohne eine gekoppelte Größen-/Identitätsprüfung; atomarer Dateiaustausch kann das erste MaxBytes-Gate entwerten.
- **Nächster Schritt / Akzeptanz:** Gekoppelten Byte-/Text-/BOM-/Codepagevertrag und sicheren Readpfad entscheiden; mindestens zweite Größenprüfung reicht nicht als allgemeiner Identitätsnachweis. Synthetischen Austauschfall getrennt von Root-Präfixfix testen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-041: Second Session: Payloadlimit vor ISJSON und RPC

- **Disposition:** in_progress; Welle 1. Priorität **P2**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `d65d0b6e037c819181f21f579fb0b6b1` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/9ae522f020acd13e8c0e4c8c283d40c4466fd480)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql](../Modules/toolbelt.core.second-session/Source/USP_ExecuteWorkTypeInNewSession.sql), [Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql](../Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql).
- **Abgleich:** Beide Pfade akzeptieren nvarchar(max), führen ISJSON/LTRIM aus und transportieren die Payload ohne DATALENGTH-Ceiling. Der separate Queue-64-KiB-Vertrag gilt nicht automatisch für synchrone Second Session.
- **Nächster Schritt / Akzeptanz:** Eigenes kompatibles Payloadprofil entscheiden, dann vor erster JSONprüfung/RPC kontrollieren. Kein stiller Transfer des Queuelimits; Caller/Remote, NULL und NONE getrennt testen.
- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

#### SC-2026-042: Persistenter Labadapter: catch-all privilegiertes Loopbackmapping

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `43f7fba403c8819183e4e19d8fbf7cbf` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/b1f637d0fabc86d36d38b139f5fff16bb0fc0638)).
- **Aktuelle Bindung:** [Tests/CI/run-lab-target.sh](../Tests/CI/run-lab-target.sh), [Tests/CI/run-lab-local.ps1](../Tests/CI/run-lab-local.ps1), [Tests/CI/run-w5a-second-session-linux.sh](../Tests/CI/run-w5a-second-session-linux.sh), [Tests/CI/run-w5b-event-log-linux.sh](../Tests/CI/run-w5b-event-log-linux.sh).
- **Historischer Abgleich vor PR #319:** Die W5-Skripte setzen @locallogin=NULL mit einem privilegierten Remote-Login. run-lab-target ersetzt die synthetische Passwordvariable mit dem ausgewählten Labcredential. Auf persistenten Zielen entsteht zeitweise ein Mapping für alle lokalen Logins, Cleanup begrenzt das Privilegfenster nicht.
- **Akzeptanzplanung vor PR #319:** Persistenten Adapter ohne catch-all Mapping für fremde Logins ausführen oder diese Suites vor jeder Servermutation fail closed sperren. Bereits vorhandene Testloginrechte nutzen, keine Logins/Grants anlegen; Cleanup/Interrupt-Fälle qualifizieren.
- **Recheck 2026-10-15 vor Cloudabschluss:** Beide W5-Runner entfernen das Defaultmapping und mappen nur ORIGINAL_LOGIN auf denselben vorhandenen Testlogin. Katalogassertionen verlangen exakt dieses Mapping; keine Loginanlage oder Grants durch die Mappingkorrektur. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/CI/README.md), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472225), [W5b-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472224). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-043: Dokumentationsgenerator: Zielpfade vor --write validieren

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P1**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `1339b86a49ec819184d1d9d5f34a24d3` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/1301ea97d1dd77085c57fe3111053444b1ad06e2)).
- **Aktuelle Bindung:** [Tests/Documentation/validate_documentation.py](../Tests/Documentation/validate_documentation.py).
- **Historischer Abgleich vor PR #319:** evidence_documents löst Manifestpfade auf; main ruft validate_generated_module_evidence vor validate_manifests auf. write_text kann vor dem späteren Containmentcheck schreiben; .git ist nicht separat als verbotenes Ziel ausgeschlossen.
- **Akzeptanzplanung vor PR #319:** Alle Schreibziele vor dem ersten Write gegen Repositorygrenze, Gitmetadaten und zulässige Markdownartefakte validieren. Absolute/../Symlink/.git-Inputs in eigenem synthetischem Checkout prüfen, keine echte Gitkonfiguration beschädigen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Alle registrierten Evidence-Ziele sämtlicher Module werden vor dem ersten Write auf vorhandenes Markdown innerhalb des Repositorys und Ausschluss von Gitmetadaten/ADS/Aliaspfaden geprüft. Ein später ungültiges Ziel verhindert auch frühere Writes. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Tests/Documentation/test_security_maintenance.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644472209). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-044: Windows-Smoke-Test: SQLCMD-Variablen werden überschrieben

- **Disposition:** implemented; mit [PR #319](https://github.com/gecompat/SQL_Server_Toolbelt/pull/319) integriert. Priorität **P3**, ursprüngliche Reife **T**; kein offenes Implementierungspaket.
- **Cloudreferenzen:** `46ca2a9d3ee481918e953ca9e818644b` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/4e43776c8c4ede8f096ea7e7ac599bfb31d7f911)).
- **Aktuelle Bindung:** [Modules/toolbelt.filesystem.windows/Tests/Runtime/WindowsCallerListDirectory.Manual.sql](../Modules/toolbelt.filesystem.windows/Tests/Runtime/WindowsCallerListDirectory.Manual.sql).
- **Historischer Abgleich vor PR #319:** Der dokumentierte -v-Aufruf kollidiert weiter mit :setvar RootAlias '__REQUIRED__'; die In-Datei-Definition gewinnt. Der Guard stoppt den Test vor der API. Fail-closed Testartefaktfehler, kein produktiver Rootbypass.
- **Akzeptanzplanung vor PR #319:** Betreiberinput und Beispieldefaults so trennen, dass der dokumentierte Aufruf den Guard passieren kann. Keine realen Roots eintragen; SQLCMD-Variablenauflösung mit synthetischem Input prüfen.
- **Recheck 2026-10-15 vor Cloudabschluss:** Überschreibende setvar-Defaults sind entfernt; RootAlias/RelativePath stammen vom Betreiber. Leere/Platzhalteraliase werden abgewiesen; der korrigierte Staticvertrag und Windows-Build bestanden. Produktstand `3d4f55f` ist bytegleich zum grünen PR-Head; [Testumfang und Grenzen](../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md). Cloudmeldung bleibt bis zu einem gesonderten Cloudabschluss unverändert.
- **Cloudabschluss 2026-10-15:** Die zugeordnete Commit-Scan-Meldung ist bestätigt fixed. [Integrierter Fix](https://github.com/gecompat/SQL_Server_Toolbelt/commit/3d4f55f9bbce0be7ddad2f106dff50b31d435204), [Testbeleg](https://github.com/gecompat/SQL_Server_Toolbelt/blob/97c6243a1031b19ecde70e2db8cff7f777d39916/Modules/toolbelt.filesystem.windows/Tests/Static/validate_contract.py), [erfolgreiche CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/38644471688). Grenzen wie im verlinkten Testbeleg; keine vollständige neue Releasequalifikation.

#### SC-2026-045: Persistente Labverbindungen: Serverzertifikat nicht authentifiziert

- **Aktualisierung 2026-10-16:** Der Benutzer hebt die pauschale TLS-Sperre für unabhängige Fachtests auf. `Functional` übernimmt den schema-validierten Trustwert; `AuthenticatedTls` verlangt False. Kein automatischer Fallback, keine Zertifikats-/Truststoreänderung und kein TLS-PASS aus fachlicher Evidenz. [Aktueller Vertrag und Verarbeitungsaufwand](../Documentation/Architecture/SECURITY_HARDENING_2026_10.md#klarstellung-sc-045-vom-2026-10-16). Die nachfolgenden früheren Sperr-/Entscheidungsstände bleiben Historie.
- **Disposition:** approved; spätere freigegebene Welle. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `27ec5c43064881918bd95a37876d02da` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/30be188d22aed636c57cf35fc112b24ae9b25704)).
- **Aktuelle Bindung:** [Tests/CI/run-lab-local.ps1](../Tests/CI/run-lab-local.ps1), [Tests/CI/run-lab-target.sh](../Tests/CI/run-lab-target.sh).
- **Abgleich:** Encrypt=True wird mit TrustServerCertificate=True beziehungsweise sqlcmd -C kombiniert. TLS verschlüsselt, authentifiziert so aber das Zielzertifikat nicht. Dies ist auch ein ausgewählter externer Labvertragswert, keine allein lokal frei änderbare Vorgabe.
- **Nächster Schritt / Akzeptanz:** Mit SQL_Server_Lab Zertifikats-/Hostname-/Pinningvertrag und Migration abstimmen. Disposable synthetische Credentials von persistenten Labcredentials trennen; keinen Providerfallback oder Zertifikatimport ohne Scopeentscheidung.
- **Recheck 2026-10-15:** Die Modulworkdir-Korrektur des Adapters ändert den TLS-Vertrag nicht. TrustServerCertificate beziehungsweise sqlcmd -C bleiben vorhanden; CA-/Pinningentscheidung ist weiter offen. Priorität, Reife D und proposed bleiben unverändert.

#### SC-2026-046: Queue Enqueue: Producerautorität je Work Type

- **Disposition:** in_progress; Welle 1. Priorität **P1**, Reife **T** nach Vertragsfreigabe vom 2026-10-15.
- **Cloudreferenzen:** `1b336f85bd48819193bdd96274b39e8f` (commit_scan, informational, new; [Quellstand](https://github.com/gecompat/SQL_Server_Toolbelt/commit/e5443172d86eceeb563b7e74c1a515473792839f)).
- **Aktuelle Bindung:** [Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql](../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql), [Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql](../Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql).
- **Abgleich:** Enqueue prüft Enabled/Handlerexistenz/ParameterMode; weder Producer-Handler-EXECUTE noch eine explizite Work-Type-Enqueuepolicy wird verlangt. Ein privilegierter Worker kann dadurch einen Auftrag eines nicht direkt ausführungsberechtigten Producers ausführen.
- **Nächster Schritt / Akzeptanz:** Producerdelegation ausdrücklich entscheiden und für einfachen/Policy-/Barrier-Enqueue einheitlich anwenden. Das ist dieselbe Authentifizierungsfamilie wie SC-2026-026, aber ein anderer Actor/Sink und deshalb kein identischer Befund.

- **Recheck 2026-10-15:** Die gebundenen fachlichen Quellen sind gegenüber dem Ausgangsabgleich unverändert. Die beschriebene Ursache und die offene Vertrags-/Designentscheidung bestehen fort; Priorität, Reife D und proposed unverändert.

Die folgenden älteren Entwicklungs-/Evidenzabschnitte bleiben als Historie unverändert erhalten. Für die oben zugeordneten Securitymeldungen gilt dieser datierte aktuelle Abgleich.

### Queue1.1: ein Dateirepeat unmittelbar nach der Migration – 2026-10-08

Die bestehende Freigabe zur daten- und metadatenwahrenden Deploymentwartung vom
2026-10-07 trägt diese begrenzte Testfortsetzung. [PR298](https://github.com/gecompat/SQL_Server_Toolbelt/pull/298)
ist nach Main `b329b71d321ebbef78d19d6e6a2d4329b2d4f249` gemergt;
exakte Head- und Mainnachweise für Linux SQL Server 2019/CL150 local/central
sowie eigene Exportbereinigungen und separater Containercleanup sind bestanden
([Main-Worker](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37811779553),
[Main-Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37811779647)).
Private Originale sind gesichert und eigene Arbeitsrefs entfernt. Die folgenden
früheren FAILED-/PENDING-Angaben bleiben Historie ihrer jeweiligen Quellenstände;
der spätere Erfolg erklärt keine historische Fehlerursache.

Im vorhandenen `Queue11Upgrade`-Fall folgt nach dem unveränderten unmittelbaren
genuine1.1→2.1-Vergleich genau ein Repeat derselben hashgebundenen Neun-Modul-Datei
je Modus. Ohne weitere persistente DML oder Consumer vergleicht ein aktueller Snapshot
alle 14 Tabellen/156 Felder einschließlich Rowversions und 17 Katalogdomänen.
Produkt, API, Testziele, Rechte, Timeouts und Cleanupverträge bleiben erhalten.
Sourceimplementierung vorhanden; neue native Folge und eigener Cleanup
**NOT_EXECUTED**, exakte Head-/Merge-/Mainqualifikation **PENDING**.
Quellenbedingte Metadatengrenzen stehen in den [Deploymenttests](../Deployment/Tests/README.md).

### Queue1.1: explizites NULL im anonymen CHECK-Witness – 2026-10-08

Neunter Prüfstand26dc: [Worker-CI FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37803232821), [Dokumentations-CI PASS](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37803232680). Geschlossene Abweisung `local-upgrade / UNCLASSIFIED / SQL515/2`; konkrete Tabelle, Spalte und Ursache bleiben UNMEASURED. Die Phase umfasst Export und nachfolgende Assertions, sie belegt keine AFTER-Reachability. Drei bisherige Exportbereinigungen und Containercleanup bestanden; neue Exportbereinigung DEFERRED/RETAINED_UNPROVEN, kein vierter OwnCleanup- oder Queue1.1-End-PASS.

Konkreter Quellenbefund: `#ExpectedChecks.ConstraintName` ist als `sysname` ohne explizites NULL deklariert, während der absichtlich anonyme SchedulerCHECK-Witness NULL einfügt. Die enge Testkorrektur ergänzt ausschließlich NULL an dieser Deklaration; der Caller bindet den neuen Assert-Dateipin. Schedulerbindung, systemnamed-Prüfung, übrige CHECK-Orakel, sechzehn Definitions-Erwartungen, States und Produkt-/API-/Besitz-/Zeit-/Cleanupverträge bleiben erhalten. Dies behebt den Quellenwiderspruch, ohne den beobachteten SQL515 kausal zu erklären. Alle bisherigen Historiestände und die Aufhebung der pauschalen SQLpause bleiben unverändert. Neue gekoppelte Prüfung und exakte Head-CI, befüllte Migration, Merge/Main sowie vollständige Retention/Refbereinigung bleiben offen; Queue1.1 NOT_QUALIFIED.

### Queue1.1: quellengebundene gespeicherte Definitionsform – 2026-10-08

Der achte Prüfstand f2a6 bleibt FAILED: `local-seed / UNCLASSIFIED / SQL55012/100` lokalisiert den Hashleaf der festen Quellbindung `VW_WorkQueue`, ungleich damaligem Golden und Verbatim. Das misst keine gespeicherten Definitionbytes und keine historische Ursache. Drei bisherige eigene Exportbereinigungen und Containercleanup bestanden; der neue Dateicleanup bleibt DEFERRED/RETAINED_UNPROVEN, kein vierter Cleanup- oder Queue1.1-End-PASS. Alle acht fehlgeschlagenen Prüfstände und ihre bisherigen Cleanupgrenzen bleiben historische Evidenz.

Zwei anschließend genau einmal ausgeführte kleine lokale Metadatenproben auf dem ausgewählten SQL2019-/Linux-Ziel bestanden die private Erfassung der acht Definitionen und eigene Datenbankbereinigung: saubere Original1.1-Installation sowie danach einmaliger aktueller Neunmodul-Export, jeweils ohne Fixture-Seed, Claim, Worker oder Repeat. Der ganze Command-/Stored-Vergleich belegt feste Headerabweichungen in diesen beiden Pfaden. Die Testkorrektur berechnet deshalb sechzehn vollständige UTF16LE-Definitionserwartungen aus gepinnten Quellen und festen, objektspezifischen Headerabbildungen; sie kopiert keine Runtimehashes. Strict-IF, alle fünf Modulflagprädikate, States, Verbatimdiagnosen und übrige Assertions bleiben unverändert. Kein allgemeiner Normalizer, weiterer Akzeptanzhash, öffentlicher API- oder Produktwechsel.

Die vorherigen Aussagen zu unveränderten sechzehn Goldenhashes beschreiben ausdrücklich die damaligen Diagnose-Quellenstände. Die Proben qualifizieren weder befüllte Queue1.1-Migration noch Fixture-/Head-CI, zentralen Modus, Windows, weitere Versionen, Minimalrechte, Matrix oder Release. Die gekoppelte Sourceprüfung und der einmalige SQL150-Grammatiknachweis des geänderten Assertinputs bestanden mit einem Batch und null Parserfehlern. Befüllte Fixture- und exakte Headnachweise, Merge/Main sowie vollständige private Retention/Refbereinigung bleiben getrennte offene Gates; Queue1.1 bleibt NOT_QUALIFIED. Private Definitionen, tatsächliche Hashes, Flags und Zielwerte sind keine öffentliche Evidenz.

### Queue1.1: erster verletzter Definitionsleaf, weiterhin Abweisung – 2026-10-08

Siebter Prüfstand a318: [Worker-CI FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37767139964), [Dokumentations-CI PASS](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37767140150). Nur Queue1.1 scheiterte mit `local-seed / UNCLASSIFIED / SQL55012/6`; State19 wurde nicht beobachtet. Managed, Admission, fokussierter Upgrade und drei bisherige Exportfälle bestanden. Drei eigene Exportbereinigungen und Containercleanup sind belegt; neuer Dateicleanup DEFERRED/RETAINED_UNPROVEN, Queue1.1-Endmarker null. Leaf, gespeicherte Definitionbytes und Ursache bleiben UNMEASURED.

Der ausgewählte Folgevertrag lokalisiert nur im bereits fehlgeschlagenen BEFORE-Zweig, nach unverändertem State19 und vor State6, den ersten verletzten ursprünglichen Leaf nach fester Komponente und Sourceordinal0..7. Fester Quelltoken `EXPORT_QUEUE11_BEFORE_DEFINITION_LEAF`, SQL55012/State20 beziehungsweise endliche Klassen30..117; jede Klasse bleibt eine Abweisung. Strict-IF, sechzehn Goldenhashes, State19/6, AFTER und Akzeptanz bleiben bytegleich. Keine Hashkorrektur, Normalisierung oder Ausgabe tatsächlicher Werte; Caller ändert nur seinen einen zentralen Assert-Dateipin.

Ein neuer vollständiger SQL150-Input/ein Batch bestand die begrenzte Grammatikprüfung; das ist keine native Bindungs- oder Ursachenprüfung. Unabhängiger Source-/Privacyreview, exakte neue Head-CI, Merge/Main und vollständige private Retention/Refbereinigung sind getrennte Gates. Nur ein neuer CI-Lauf mit diesem Diagnoseimpact ist vorgesehen; aus weiter ungelösten Hashformen folgt keine spekulative Goldenänderung oder CI-Wiederholungsschleife. Queue1.1 bleibt NOT_QUALIFIED.

Der unmittelbar folgende State19-only-Abschnitt dokumentiert den historischen Quellenvertrag des a318-Prüfstands; seine Aussage „jeder andere Fall bleibt State6“ beschreibt diesen früheren Stand.

### Queue1.1: Zusatzdiagnose nach strikter Definitionen-Abweisung – 2026-10-08

Der sechste Prüfstand c3f7 bleibt [FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37761644789), seine [Dokumentations-CI bestand](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37761644838). Managed und die drei bisherigen Exportfälle bestanden; Queue1.1 scheiterte mit `local-seed / UNCLASSIFIED / SQL55012/6`. Drei bisherige eigene Exportbereinigungen und separater Containercleanup sind belegt; neue Dateibereinigung bleibt DEFERRED/RETAINED_UNPROVEN, Queue1.1-Endmarker null. Tatsächlicher Operand und Ursache bleiben ungemessen.

Der quellengebundene Diagnosekandidat erhält das ursprüngliche Strictgate, alle sechzehn Goldenhashes, Modulflags und den State6-Fallback. Nur im bereits fehlgeschlagenen BEFORE-Zweig führt die gemeinsame positive Bindung aller acht vorhandenen Definitionen an ihre festen Verbatim-Commandhashes und bisherigen Flags zu weiterhin `THROW 55012` mit festem Quelltoken `EXPORT_QUEUE11_BEFORE_VERBATIM_DEFINITIONS` und State19; jeder andere Fall bleibt State6. Kein Erfolgsfallback, keine Normalisierung, Goldenänderung oder AFTER-Instrumentierung. Der Caller aktualisiert ausschließlich seinen einen zentralen Assert-Dateipin. Neue native Diagnose-/Headqualifikation, Merge/Main und vollständige private Retention/Refbereinigung bleiben offen; keine State19-Messung oder historische Ursache vorweggenommen.

### Queue1.1-Quellenbezug: Hidden-Store-Read und geschlossene Diagnosen – 2026-10-08

Der fünfte Quellenhead `6e8cf4fe4c539d862c2084a094c20b496254ae41` bestand den Managed-Vertrag, die drei bisherigen Exportfälle und die Dokumentations-CI; der neue Queue1.1-Fall scheiterte in `queue11-acquire / UNCLASSIFIED / SQL0/0` ([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37757210239), [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37757210026)). Drei eigene Exportbereinigungen und Containercleanup bestanden, der neue Dateicleanup bleibt `DEFERRED / RETAINED_UNPROVEN`. Tatsächlicher Operand und Ursache bleiben ungemessen; dieser Lauf erklärt auch keine frühere Fehlerursache.

Unter der bestehenden Test-/Deploymentwartungsfreigabe liest der Erwerbshelper den vorgesehenen Required-Store mit `Get-Item -Force`: Unix-Dotnamen wie `.git` werden als Hidden behandelt. DirectoryExists, NoReparse, Storeindirection, CI-Scope, Quellenpins und Budgets bleiben unverändert. Der Caller bildet ausschließlich die zwanzig festen Acquisition- und sieben festen OwnedProcess-Fehlertexte im Erwerbsphase-Scope auf eine ausdrückliche geschlossene Allowlist ab. Keine freien Exceptiontexte, Git-Stderr, Pfade, Runtimewerte, Acquisition-Statewerte oder neue Fallbacks gelangen in die Ausgabe. Das sind getrennte Quellenkorrekturen, kein kausaler Nachweis zum fünften Fehlhead.

Neue exakte Head-CI, Queue1.1-Migration, normaler Merge, Main-CI und vollständige private Retention/Refbereinigung bleiben offen. Kein unveränderter Retry, keine neue öffentliche SQL-Funktion, Rechte-, Provider- oder Zielausweitung. Alle bisherigen Fehlerhistorien bleiben erhalten.

## Aktive Arbeitspakete

### Genuine Queue1.1 als weitere Deploymentwartung

**Abgleich und begrenzter Abschluss vom 2026-10-20:** Der menschliche
Fortsetzungsauftrag vom 2026-10-20 hebt die frühere allgemeine
Entwicklungspause auf. Die Bestandsprüfung fand keine offenen PRs oder
unübernommenen Branches. Die folgende Queue1.1-Historie wird durch einen
bereits ausgeführten späteren Nachweis ergänzt, nicht rückwirkend geändert.

Der [Main-Worker-Lauf vom 2026-10-19](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/39272472951)
am Commit `bea86dd361c7e27f7ae66bd12ac02ddb4c22c44e` bestand alle drei Jobs.
Die tatsächlichen Checkout-Commitzeilen, API-Schrittstatus und abgegrenzten
Ergebnisse des Queue1.1-Schritts wurden am 2026-10-20 lesend geprüft:
genuine1.1→2.1, unmittelbarer Daten-/Katalogvergleich und anschließender
Repeat derselben Exportdatei bestanden auf SQL Server 2019 Linux/CL150
lokal und zentral. Eigene Datenbank-/Dateibereinigung dieses Falls sowie
der getrennte Containercleanup sind belegt. Die relevanten Produkt-,
Export-, Fixture-, Helper-, Worker- und Workflowquellen sind gegenüber
`64cc498c81a51ac4419ac6d4f6e7e728986d3163` unverändert. Das ist ein gebundener
Nachtrag zum Lauf vom 19.10., kein neuer SQL-Lauf oder aktueller Head-CI-Ersatz.

Damit ist die begrenzte Queue1.1-Deploymentwartung einschließlich des
Dateirepeats integriert und nativ nachgewiesen. Historische FAILED-/SKIPPED-
Läufe, ungemessene Ursachen und damals fehlende Cleanupnachweise bleiben
erhalten. Die Bereinigung des erfolgreichen Laufs belegt keine nachträgliche
Bereinigung oder vollständige private Retention früherer Versuche.
Weitere Plattformen/CLs, nichtleere Benutzergrants, echte Minimalrechte,
allgemeiner Gesamtdeployment-Lifecycle und Release bleiben getrennt offen.
Der Windows-`FileSystemRoot`-Repeat bleibt der nächste noch offene Eintrag
der untenstehenden Wartungsreihenfolge; er benötigt seine eigenen
Windows-/Assembly-/Trustvoraussetzungen. Details und Grenzen stehen im
[aktuellen Deploymentabgleich](../Deployment/Tests/README.md#queue11-abgleich-des-späteren-main-nachweises-2026-10-20).

Die folgenden offenen Angaben beschreiben die jeweiligen historischen
Quellenstände vor diesem späteren erfolgreichen Nachweis.

Vierter exakter Head `0437beadf435173baafe9e9f27223f2fe0c8f7be`:
[Worker-CI FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37751627937),
[Dokumentations-CI PASS](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37751627892).
Der bestehende Managed-SQL-Test verwirft `MANAGED.RELEASE_OTHER_WORKER` nach dem
Completion-Wait. Alle vier Exportfälle einschließlich Queue1.1 sind SKIPPED;
ihre Erfolg-/OwnCleanupmarker null, Containercleanup separat bestätigt. Tatsächliche
Prädikatwerte, Actor-SQL und Ursache bleiben ungemessen.

Der Worker bestätigt den WorkItem-Commit vor dem separaten Reservation-Endrecord.
Die Testfixture wartet deshalb innerhalb desselben Budgets gemeinsam auf den
eigenen aktuellen WorkItem-/Reservation-/Claimgeneration-Bezug, COMPLETED,
COMMITTED und IsOccupied0. Die nachfolgende Assertion bleibt unverändert.
Keine zusätzlichen Delays, Rechte, Produkt-, API-, Provider- oder Cleanupänderungen.
Neue exakte Headprüfung, Queue1.1-/Toolqualifikation, Merge/Main und vollständige
private Retention/Refbereinigung bleiben offen; historische Ursachen ungeklärt.

Dritter exakter Head `836357d02a42e2e490e657a003c745da6756e526`:
[Worker-CI FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37747434151),
[Dokumentations-CI PASS](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37747434156).
Die gemeinsame Toolabweisung `QUEUE11_DIRECTORY_TOOL` liefert keinen konkreten
Operand oder Ursachenbeweis. Drei bisherige Exportcleanups und Containercleanup
sind belegt, kein neuer Deferredmarker; kein vierter Cleanup-/Queue1.1-PASS.
Die bestehende Application-Auswahl wird mit `-TotalCount 1` ausdrücklich auf den
ersten Treffer begrenzt. Alle Prüfungen dieses gewählten Programms bleiben erhalten;
kein Ausweichen auf einen zweiten unsicheren Treffer. Neue native Prüfung,
Merge/Main und Retention bleiben offen. Historische Ursachen bleiben ungemessen.

Der zweite exakte Head `611fa3fceee0dddc84ddce71fb33d7a7f42b0ba8` hat
[Worker-CI FAILED](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37741968376)
und [Dokumentations-CI PASS](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37741968349).
Die feste Abweisung `QUEUE11_ROOT_PARENT_CREATED_TICKS` benennt die verworfene
Parent-Zeitgleichheit; tatsächliche Werte, Plattformfallback und Ursache bleiben
**UNMEASURED**. Der erste e9fc-Operand wird dadurch nicht rückwirkend gemessen.
Die folgende Quellenkorrektur bindet ausschließlich Parent und Root über private
Geräte-/Inode-/Mode-Tupel im bestehenden Linux-CI-Fall. Alle übrigen Ownership-,
Datei-, Journal- und Cleanupgrenzen bleiben erhalten. Neue native Qualifikation,
Merge und Main sind **PENDING**; Queue1.1 bleibt **NOT_QUALIFIED**.

Erster exakter Head `e9fc95ea5192ac35697a2d87e11c8f94c1938d2b`:
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37738796909)
**FAILED**, [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37738797015)
**PASS**. Der neue Fall wurde im Preflight abgewiesen; einzelne Bedingung und
Ursache sind **UNMEASURED**, Migration bleibt **NOT_QUALIFIED**. Die bisherigen
drei Exportfälle bestanden mit drei eigenen Bereinigungen; neuer Dateicleanup
**DEFERRED**, separater Containercleanup bestätigt. Eine eng begrenzte
Diagnoseänderung unterscheidet die dreizehn vorhandenen Root-Prädikate mit
festen Codes, ohne die Schutzbedingungen zu lockern oder Runtimewerte auszugeben.
Diese Änderung ist noch nicht nativ geprüft; aktueller Merge/Main bleiben offen.
Die vorherigen PENDING-Angaben beschreiben die ursprüngliche Vorbereitung.

Unter der bestehenden Freigabe zum datenwahrenden Gesamtdeployment wird der
saubere originale Queue1.1-Installer mit genau einem aktuellen Neun-Modul-Export
je local/central geprüft. Dies ist Testwartung vorhandener öffentlicher Objekte.
Die Originalquellen sind an Commit `7c6cb157db39a948e14f3db1f4973f80579a5832`
gebunden; der Quellenbezug erfolgt einmal im eigenen exklusiven Linux-CI-Checkout,
vollständige Elf-Blob-/Expansionsprüfung vor jeder eigenen DB-Anlage.
Sechs alte Tabellen/83 Felder, erwartete keyed RowVersion-Wechsel der drei
WorkItems sowie neue Defaults und Katalogformen werden getrennt geprüft.
Keine zusätzliche DML nach dem unmittelbaren Migrationsvergleich, kein Repeat,
neuer Claimconsumer, öffentliche API, Rechte-/Provider-/Zielausweitung.
Native neue Migration und eigener Cleanup: **NOT_EXECUTED**; neue exakte
Head-/Merge-/Mainqualifikation: **PENDING**. Details und Grenzen stehen in den
[Deploymenttests](../Deployment/Tests/README.md).

Abschluss der vorausgehenden Wartungswelle, 2026-10-08: [PR297](https://github.com/gecompat/SQL_Server_Toolbelt/pull/297)
ist nach `main` `fdd01df40a4cb495bff126bfe1db8db9b2156bed` gemergt.
Der letzte Head `a61ae213b969b2fa5df84b493ed2a369781d1c13` bestand
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37731699578)
und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37731699498).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37732809028)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37732809105): **PASS**.
Je vier tatsächliche Checkout-Commits wurden über ihren Tree an den geprüften
Sourcebaum gebunden. Die genuine2.0→2.1→Completion→Dateirepeat-Folge bestand
für Linux SQL Server 2019/CL150 local/central; drei eigene Exportbereinigungen
und der separate Containercleanup sind belegt. Eigene Arbeitsrefs sind entfernt,
private Originale vollständig und unabhängig auf Bytes/Hash/Länge gesichert.
Die folgenden früheren **PENDING**-/**NOT_EXECUTED**-Vorbereitungsangaben gelten
für ihre damaligen Quellenstände. Beide historischen fehlgeschlagenen Headläufe
bleiben **FAILED** mit Ursache **UNMEASURED**; der spätere Erfolg erklärt sie nicht.
Dieser begrenzte Abschluss qualifiziert den neuen Queue1.1-Fall noch nicht.

Weitere Statusfortschreibung 2026-10-08: Auch der zweite native Headlauf
`6abf635a26c314744fa3bba27d2eb289e9f4445d` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37729131172));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37729131184)
bestand. Vier tatsächliche Checkouts sind über ihren Tree an diesen Head gebunden.
Die geschlossene lokale Upgrade-Diagnose SQL54998/State90 lokalisiert
`PARENT_COLUMN`, Sourceindex0: Das bisherige Prädikat
`c.parent_column_id <> 0` war wahr. Konkrete ID, Spaltenname, Mirrorzustand
und Ursache sind dadurch **UNMEASURED**. Der ursprüngliche 109-Feldervergleich
wurde davor erreicht; neue Completion, vollständiger Nach-Completion-Snapshot
und identischer Dateirepeat bleiben **NOT_EXECUTED**, die Folge **NOT_QUALIFIED**.
DefaultRepeat bestand, Parameterexport wurde übersprungen. Containercleanup
bestand separat; der einzelne Exportcleanup-Erfolgsmarker gehört zum
DefaultRepeat und belegt keinen eigenen Migrationcleanup.

Die neue Testassertion vergleicht zunächst die
Table-/Columnklassifikation mit dem Compiler-Mirror. Positive Columnbindungen
werden je eigenem Parentobjekt anhand acht fester Source-Spaltennamen und ihrer
Typform geprüft; der mehrspaltige Limits-CHECK verlangt beide Tablebindings0.
Absolute ColumnIDs werden nicht objektübergreifend gleichgesetzt. Derselbe
Invalid-Term gilt im Gesamtgate und in der endlichen State90-Diagnose;
Count-, Namen-, Definitionbytes-, Trust-/Flaggates und State12-Fallback bleiben.
Genau ein neuer vollständiger SQL150-Input/ein Batch bestand die reine
Offline-Grammatikprüfung. Ein unabhängiger Source-/Inverse-/Privacyreview
bestand ohne Blocker; er führte weder Parser noch SQL aus. Root hat den
Sourceentwurf vollständig gelesen. Diese Fortschreibung begleitet die
Übernahme der Testassertion. Native Parent-/Compilerqualifikation, neue
exakte Head-/Merge-/Mainqualifikation und eigener Cleanup bleiben **PENDING**.
Keine native Parent-/Compilerqualifikation oder Ursachenbehebung wird behauptet.

Statusfortschreibung 2026-10-08: Der erste native Lauf dieser Upgrade→Repeat-Welle
in [PR297](https://github.com/gecompat/SQL_Server_Toolbelt/pull/297) am Head
`913a3d6c42f4962a22c11656977bdf458d1bd15c` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37726736364));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37726736429)
bestand. Die kombinierte Neun-CHECK-Assertion weist im lokalen Upgrade mit
SQL54998/State12 ab. Welche Unterbedingung und Sourcebindung verletzt ist,
bleibt **UNMEASURED**; ein Produktfehler oder eine Ursachenbehebung ist nicht belegt.
Der bisherige Immediatevergleich wurde davor erreicht. Die neue Completion
und der anschließende identische Dateirepeat sind **NOT_EXECUTED**, die neue
Folge ist **NOT_QUALIFIED**. Der separate DefaultRepeat bestand; der
Parameterexport wurde übersprungen. Containercleanup bestand separat;
der beobachtete eigene Exportcleanup-Erfolgsmarker gehört zum DefaultRepeat,
kein eigener Migrationcleanup-PASS wird daraus abgeleitet.

Die im Branch übernommene Diagnose ergänzt nur den bereits fehlgeschlagenen CHECK-
Zweig: höchstens drei lesende Queries, feste Komponenten und Sourceordinal0..8,
numerische States höchstens108 sowie der unveränderte State12-Fallback.
Originalgate und Erfolgsweg bleiben erhalten; keine tatsächlichen Katalognamen,
Definitionen oder Werte werden veröffentlicht. Ein neuer SQL150-Input/ein Batch
bestand die Offline-Syntaxprüfung. Native Diagnose, CHECK-Engineäquivalenz,
vollständige neue Folge und eigener Cleanup bleiben offen; neue exakte
Head-/Merge-/Mainqualifikation **PENDING**.
Bisherige Vorbereitungsangaben und alle Parentnachweise bleiben historische
Evidenz ihrer Quellenstände; keine Guards, Timeouts, Produkte, APIs oder Rechte ändern sich.

Weitere Deploymentwartung, im Branch übernommen 2026-10-08: Der bestehende
`Queue20Upgrade`-Fall prüft nach genuine Queue2.0→2.1 und erstmaligem Control1.0
auch einen Repeat derselben Neun-Modul-Datei, jeweils local/central.
Der ursprüngliche Immediatevergleich aller acht Legacytabellen/109 Felder
bleibt unverändert vor weiterer persistenter DML. Erst danach wird genau ein
eigener Legacyclaim über die bestehende `USP_CompleteWork` abgeschlossen;
nur Status, CompletedAtUtc, CompletedBy und RowVersion dieses WorkItems dürfen
sich ändern. Vollständige private Snapshots erfassen danach 14 Tabellen/156
Felder einschließlich fünf leerer Tabellen und ein positives neues
Constraintinventar. Ein identischer Dateirepeat vergleicht alles ohne
First-Ausnahmen oder Versionsnormalisierung. Bestehende Gates, Timeouts,
Ownership und Cleanup bleiben erhalten; keine neue API oder zusätzliche
Scenario-/DB-/Export-/Rechte-/Ziel-/Provider-/Configfreigabe.
Autor-Syntaxnachweis: fünf neue SQL150-Inputs/35 Batches und Adapter-AST ohne
Fehler; CHECK-Engineäquivalenz, neue native Folge und eigener Cleanup sind
**NOT_EXECUTED**. Unabhängiger Source-/Client-/Privacyreview der eingefrorenen
Payloads bestanden; eigene Headprüfung, Merge und Mainqualifikation sind
**PENDING**. Historische
Fehler- und Qualifikationsnachweise bleiben erhalten; Details künftig in den
[Deploymenttests](../Deployment/Tests/README.md).

View-Mainvoraussetzung erfüllt, Stand 2026-10-08: [PR296](https://github.com/gecompat/SQL_Server_Toolbelt/pull/296)
ist nach `main` `c1dc014d94f6ce827bd52ef542722faea5bb267b` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945915)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945917): **PASS**.
Der Nachweis ist auf Linux SQL Server 2019/CL150 local/central und den bisherigen
View-Spalten-/Exportscope begrenzt; er qualifiziert diese neue Upgrade→Repeat-Folge nicht.

### View-Spaltenannotation im bestehenden Exportrepeat

View-Spaltenwartung, Stand 2026-10-08: zwei eigene class-1-Properties auf
der vorhandenen View-Spalte `toolbelt_core.VW_WorkQueue.RowVersion`.
Setup und Assert verwenden die nach Namen ermittelte tatsächliche column_id;
Capture und beide Repeatfenster bleiben erhalten. [Deploymenttests](../Deployment/Tests/README.md)
beschreiben Count2 und den vollständigen typisierten Erhaltungsnachweis.
Native View-Spaltenprüfung und eigener Cleanup: **NOT_EXECUTED**; eigene exakte
Head-CI sowie Merge-/Mainqualifikation einschließlich Cleanup: **PENDING**.

Class1-Voraussetzung erfüllt: PR295, Main `a585803de0d1d94be595dbf7b3153e582fbff9d2` (2026-10-08).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226636) und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226645): **PASS**.
Der begrenzte Nachweis gilt für Linux SQL2019/CL150 local/central; sechs Objektzeugen, drei eigene Exportbereinigungen und Containercleanup sind belegt. Er qualifiziert keine neuen View-Spaltenzeugen und erklärt keine historische Fehlerursache.

### Deploymentwartung 2026-10-07 – datenwahrender Queue-/Control-Repeat

Der ausdrücklich besprochene Auftrag zum aktuellen Gesamtdeployment umfasst
Anlegen beziehungsweise Altern bestehender Objekte unter Erhalt persistenter
Daten und die gewählte zusätzliche eigenständige SQL-Datei. PR282 liefert
den Export; PR283 korrigiert den Queue2.1-Repeat mit allen sieben Zuständen.
Diese Folgekorrektur begrenzt den installierten Controlconsumer auf den
bekannten vollständigen Queue2.1-/Control1.0-Verbund mit deaktiviertem Gate
und ohne Claims, Holds oder offene Reservations. Sie implementiert keine
neue öffentliche SQL-Funktion und erweitert weder Testziele noch Rechte.

Der [bestehende Controlvertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
beschreibt Formprüfung, gemeinsame Lifecyclelockreihenfolge und begrenztes
Schreibfencing. Kein Disable, Uninstall oder Token-/Historiereset dient als
Hilfsmigration. Der ergänzte externe Upgradeadapter bestand am 2026-10-07 auf
SQL Server 2019 Linux am Commit `91507c65ac24051890a1775cc4264c8c119f549f`
einschließlich befüllter Verbundrepeats, Negativfälle und eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548)).
Allgemeiner Gesamt-Refresh, unbekannte Migrationsformen,
Windows-/weitere Versionsmatrix und reale Minimalrechte bleiben getrennt.

#### Fortsetzung und Pausenauftrag

Der Benutzer verlangt am 2026-10-07 nach Abschluss dieser Entwicklungsrunde
einschließlich [PR284](https://github.com/gecompat/SQL_Server_Toolbelt/pull/284)
und Merge nach `origin/main` eine Entwicklungspause. Mit diesem Merge tritt
die Pause in Kraft; weitere Wartungswellen beginnen erst nach ausdrücklichem
Fortsetzungsauftrag. Der native Verbundnachweis oben ist bestanden. Finale
Head-CI und tatsächlicher Merge sind im PR nachvollziehbar; ein noch laufender
oder fehlgeschlagener Check ist keine Integrationsevidenz.

Datierter Fortsetzungsauftrag 2026-10-07: Der Benutzer hebt die Pause mit
„Fortsetzen. Lies aber Regelwerk neu“ auf. Native Regelkette, Foundation und
relevante Projektregeln wurden neu gelesen; `main` einschließlich PR285 und
die Modulquellen wurden abgeglichen. Die nächste Wartungswelle ergänzt den
befüllten File-Content-Repeat ausschließlich als Test-/Evidenzscope unter
der vorhandenen Deploymentfreigabe. Neue öffentliche SQL-Funktionen bleiben
einzeln freigabepflichtig. Die damalige lokale SQL-/Dockerpause wurde durch
die unten dokumentierte Benutzerfreigabe vom 2026-10-08 aufgehoben.

File-Content-Wartung: Der befüllte 1.0.0-Repeat bestand am Commit
`8effcee91106cb4b8924c7a839928d550c0653b6` auf SQL Server 2019/150,
2022/160 und 2025/170 Linux jeweils lokal/zentral mit zwei echten Deploys
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814)).
Vier synthetische Zeilen, verbrauchte Identitywerte und ausgewählte
Katalogmetadaten einschließlich vorhandener Permissions blieben erhalten;
Tabellen-/Spaltenannotation blieb gleich, Tabellen-`MS_Description` wurde
kanonisch erneuert. Keine Benutzergrants wurden erzeugt. Der erste offene
Tabellenscope ist jetzt `ExecutionCancellation`; Windows, weitere Repeat-CLs,
nichtleere Benutzergrants, echte Minimalrechte und historische Übergänge
bleiben separat. Finale Head-CI/Merge werden über
[PR286](https://github.com/gecompat/SQL_Server_Toolbelt/pull/286) geprüft.

Arbeitsmodus konkretisiert 2026-10-07: Der Benutzer verlangt unmittelbare
autonome Fortsetzung und Delegation mit Abschlussmeldungen; die geplanten
20-Minuten-Stupser sind ausschließlich ein Sicherheitsnetz. Nach jedem
abgeschlossenen Arbeitspaket wird die nächste konkrete freigegebene Arbeit
direkt vorbereitet beziehungsweise umgesetzt. Agentenberichte werden vor
Integration abgewartet und gegen Quellen sowie tatsächliche Tests geprüft.
Cancellation-Wartung: Zwei befüllte 1.0.0-Repeats bestanden am Commit
`fac18e590f854a26364e5f498c6a2b5d330a95c2` auf SQL Server 2019/150,
2022/160 und 2025/170 Linux jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199)).
Alle fünf Spalten einschließlich Rowversion, Audit- und Textbytes sowie
ausgewählter Katalog und eigene Tabellen-/Spaltenbeschreibungen blieben
erhalten; vorhandene API-/Parallelitäts-/Consumer-/Uninstallfälle und eigene
CI-Bereinigung bestanden. Finale Head-CI und Merge sind in
[PR287](https://github.com/gecompat/SQL_Server_Toolbelt/pull/287) abzugleichen.
Der nächste konkrete Wartungsscope ist jetzt `EventLog`: dessen bestehende
WorkType-Reaktivierung zuerst prüfen, anschließend den unveränderten aktiven
Repeat. Keine neue öffentliche Funktion oder Änderung dieser Semantik.

EventLog-Wartung: Der befüllte Repeat bestand am Commit
`6f51078cfa1f13ace32212f07d46de8d55d39ef0` auf Linux2019/150,2022/160,
2025/170 jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37692309192)).
Alle 24 Eventspalten und verbrauchte Identitywerte bleiben über zwei echte
1.0.0-Deploys erhalten. Der erste reaktiviert die über Register/Disable
abweichend deaktivierte eigene WorkType-Registrierung kanonisch; der zweite
erhält die vollständige aktive Zeile einschließlich Rowversion. Andere
Registrierungen, ausgewählter Katalog und eigene Beschreibungen bleiben gleich.
Bestehende API-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle sowie eigene
CI-Bereinigung bestanden. Finale Head-CI/Merge sind in
[PR288](https://github.com/gecompat/SQL_Server_Toolbelt/pull/288) abzugleichen.
Keine Source-/Deploy-/Provider-/Rechteänderung. Der nächste konkrete
tabellenreine Wartungsscope ist jetzt `SecondSessionProvider`; neue Windows-,
weitere Repeat-CL-, Benutzergrant-, Minimalrechte- und historische Nachweise
bleiben getrennt.

SecondSessionProvider-Wartung: Zwei echte befüllte 1.1.0-Repeats bestanden
am 2026-10-08 am Commit `32ee260e413b8de7f9b2046ffdc11618b0afd69b` auf
Linux2019/150,2022/160,2025/170 jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37693379887)).
Genau ein deaktivierter synthetischer `loopback`-Eintrag blieb mit allen acht
Spalten einschließlich Audit-/Unicode-/Padding-/Rowversionbytes sowie
ausgewähltem Katalog und eigenen Beschreibungen erhalten. Keine RPC- oder
Configure-USP-Aufrufe im neuen Tabellenrepeat. Bestehende API-/Provider-/
Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung
bestanden; abhängige W5b-Suite37693379826 ebenfalls am selben Head SUCCESS.
Finale Head-CI/Merge sind in
[PR289](https://github.com/gecompat/SQL_Server_Toolbelt/pull/289) abzugleichen.
Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische
Übergänge bleiben offen. FileSystemRoot besitzt neun Spalten ohne Identity,
Auditfelder oder Rowversion; sein nativer Repeat benötigt zusätzlich die
bestehenden Windows-/Assembly-/Trustvoraussetzungen. Der vorhandene Buildworkflow
ersetzt keine SQL-Runtime. Unabhängig ist der gemeinsame exportierte Repeat
von neun CLR-freien Modulen mit 14 der 15 Tabellen als nächster Testscope
vorbereitet; Windows-FileSystemRoot und vollständiger 44-Modul-Export bleiben
getrennt. Keine neue Funktions-, Rechte-, Provider- oder Trustfreigabe.

Gemeinsamer Exportrepeat, vorbereitet 2026-10-08: Der neue Testadapter
konsumiert die echten hashgebundenen `-OutputSqlFile`-Exporte der neun
CLR-freien Module lokal/zentral in frischen Sitzungen. Alle 14 Tabellen werden
synthetisch befüllt und über zwei Repeats vollständig verglichen; erwartete
File-Content-Beschreibungsnormalisierung und EventLog-WorkType-Reaktivierung
sind separat abgegrenzt. Er nutzt ausschließlich das bestehende externe
Linux2019/CL150-CI-Ziel. Offlineexport und unabhängige Reviews sind bestanden;
Der erste gemeinsame native Lauf am Commit `e5b51d14500203947fd45d6ad0533e40b1302c8a`
ist im neuen Test FAILED, zunächst ohne abgegrenzte Primärursache
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37696018416)).
Vorherige Worker-/Upgradefälle und eigene Containerbereinigung bestanden.
Der Diagnoselauf `947da95d61ae617f88e42847ae453dd27e132197` ist ebenfalls
FAILED im Verbindungs-Preflight
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697052700)).
Die Builder-Dotzuweisungen `InitialCatalog`/`ConnectTimeout` scheitern ohne
Serververbindung reproduzierbar; sie werden durch die bestehenden gültigen
Indexer ersetzt. Der separate Adaptercleanup-Pfadseparatorfehler ist korrigiert.
Beide FAILED-Läufe bleiben historische Evidenz und gelten nicht als Runtime-PASS.
Der korrigierte Builder-Head `6989d8ac43033e8cd45c2f8fb88f59239429c64a`
besteht den Preflight, ist aber beim eigenen Datenbank-/Sitzungsgate FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697908672)).
Vorherige Runtimefälle und Containerbereinigung bestanden. Der Diagnoselauf
`e79bf5a4c1d0db3760b6fbc29a8d1714b8fc7368` bleibt FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37699250549)):
Zwölf Einzelbedingungen bestehen, das kombinierte Gate wirft State 13.
Die Korrektur prüft die neutrale Sitzung getrennt vor und nach dem gemeinsam
gebundenen Besitzgate. Kein Besitzprädikat entfällt; Autocommit während der
Katalogauswertung ist eine Hypothese, keine nativ gemessene Primärursache.
Der Korrekturlauf `52526f7836b0d4c113991fc972608b1eff276283` besteht das
Besitzgate und die Erstinstallation, bleibt beim initialen Fixture-Sitzungsgate
FAILED/SQL54980/State1
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37700707745)).
Die gleichen kombinierten Sitzungsprüfungen in den vier Testfixtures werden
ebenfalls ohne Prädikatverlust in einzelne IFs getrennt. Vorherige Workerfälle
und Containerbereinigung bestehen. Der korrigierte Head
`a836b87778fbe4c498b4b1ce05f06c58373ea03c` besteht den gemeinsamen Exporttest
auf Linux2019/CL150 lokal und zentral: alle 14 Tabellen über zwei befüllte
Repeats, eigene DB-/Dateibereinigung sowie vorhandene Worker-/Upgradefälle
und Containerbereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352)).
Die Dokumentations-CI desselben Heads besteht ebenfalls. Die historischen
FAILED-Läufe bleiben getrennt; dies qualifiziert ausschließlich diese
Neun-Modul-Folge im genannten Zielscope.
Details und offene Grenzen stehen in
[Deploymenttests](../Deployment/Tests/README.md). Windows-FileSystemRoot und
vollständiger 44-Modul-Export bleiben getrennte Nachweise; Source, Deploy und
öffentliche SQL-API werden nicht geändert.

Exportmigration, vorbereitet 2026-10-08: Unter derselben engen
Deploymentwartungsfreigabe ergänzt `Queue20Upgrade` ausschließlich die echte
Migration von gepinnter Queue2.0 nach Queue2.1 mit erstmaliger Control1.0-
Installation. Sieben aktuelle Bootstrapmodule und anschließend der vollständige
aktuelle Neun-Modul-Export werden lokal/zentral in frischen Sitzungen konsumiert.
Acht Legacytabellen mit 109 Feldern, darunter alle 43 WorkItem-Felder und ein
aktiver Originalclaim, werden vor weiterer persistenter DML binär verglichen;
die leere Barrier-Tabelle besitzt einen ausdrücklichen Countzeugen. Drei
neutrale Managedfelder, sechs neue Tabellen mit bekannten Spaltenformen und
neutralen Gate-/Controlzuständen werden rein lesend geprüft. Keine neue
Callback-/SQL-API, Post-Migration-Completion, Admission oder zusätzliche
14-Tabellen-Repeatfolge. Source, Deploy und die bisherigen vier Repeatfixtures
bleiben unverändert; vorhandene Rechte werden nur beobachtet. Offlineprüfungen
und unabhängiger Domainreview bestanden, native Migration ausdrücklich
`NOT_EXECUTED`. Parent [PR290](https://github.com/gecompat/SQL_Server_Toolbelt/pull/290)
bestand am Qualifikationshead `a836b87778fbe4c498b4b1ce05f06c58373ea03c`
den begrenzten nativen Exportrepeat einschließlich eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352));
Dokumentations-CI desselben Heads bestand ebenfalls. Frühere FAILED-Läufe
bleiben historische Evidenz. Finale Parent-Head-CI am Stand
`bdc2ba9f001190d9d63cc97e040f1e693fb4dafd`
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37702891518))
bestand; PR290 ist nach `origin/main` integriert, Mainstand
`acba925419973d9dfb2b7b8e481d67f0a75789e3` mit identischem Parentbaum.
Main-Dokumentations-CI bestand; Main-Worker-CI
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37703434018))
bestand einschließlich eigener Bereinigung. Eigene native Migrationsqualifikation
bleibt bis tatsächlicher eigener Head-CI offen. Keine neue Funktions-, Rechte-,
Provider-, Trust-, Ziel- oder allgemeine Migrationsfreigabe wird daraus
abgeleitet. Details und Grenzen stehen in den
[Deploymenttests](../Deployment/Tests/README.md).

Statusfortschreibung 2026-10-08: Der erste native Migrationslauf in
[PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) am Head
`1d4f9cbdde094c2c59c22eb01b5c5ee261df73b0` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019236));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019277)
bestand. Die Setupfixture verwendete `#tbx_ExportUpgradeStatus` und
`#tbx_ExportUpgradeClaim` als öffentliche ResultTable-Ziele. Der bestehende
Vertrag von `USP_PrepareResultTable` reserviert `#tbx_` und weist diese Namen
mit Fehler `51020`/State `1` ab. Die vorbereitete Korrektur benennt nur diese
beiden eigenen Fixtureziele in `#ExportUpgradeStatus` und
`#ExportUpgradeClaim` um; Source, Deployment, Guards und Datenorakel bleiben
unverändert. Die korrigierte native Migration ist **NOT_EXECUTED**.
Der erfolgreiche Wholejob-Cleanup wurde getrennt verifiziert. Auf dem
Fehlerpfad erschien kein Erfolgsmarker der eigenen Migration-DB-/Datei-
Bereinigung; daraus wird kein eigener Cleanup-PASS abgeleitet.

Die bisherigen SQL150-Offlinenachweise mit 865 Export-Inputs und 28
Fixture-/Wrapper-Inputs sowie die unabhängigen Reviews bleiben an ihren
ursprünglichen Quellenständen gültig. Sie belegen Syntax beziehungsweise
Reviewumfang und erkennen diese Laufzeitverletzung des ResultTable-
Namensvertrags nicht. Die oben genannten NOT_EXECUTED-Angaben dokumentieren
den Vorbereitungsstand; dieser fehlgeschlagene Lauf qualifiziert weder die
Migration noch deren eigenen nativen Cleanup. Parentnachweise bleiben
unverändert erhalten. Keine API-, Rechte-, Ziel- oder Vertragsausweitung.


Statusfortschreibung 2026-10-08: Der zweite Lauf am korrigierten Head
`2735ad3167174d8986857e2f16ec92c3c6942beb` ist bereits in den unveränderten
Managed-Worker-SQL-Contracts **FAILED**
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094651));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094720)
bestand. Das feste Oracle `MANAGED.UNEXPECTED_UNKNOWN` meldet ein unbekanntes
Workerende im Fall `budget-two`, nach `LIVE_BUDGET_TWO_REDUCED_WITHOUT_CANCEL`.
Beide Export-Schritte wurden **SKIPPED**; die korrigierte native Migration
bleibt **NOT_EXECUTED**. Always-Containercleanup bestand. Die zugrunde liegende
Actor-/Guardianursache ist nicht gemessen; SQL0 der generischen Waitexception
belegt keinen Actor-SQL-Code. Eine begrenzte Diagnoseergänzung an der Testfixture
soll bereits vorhandene Actor-/Guardianfelder ausschließlich als feste
Sourcecodes, typisierte numerische SQL-Codes und Statusflags sichtbar machen.
Workerprodukt, SQL, Orakel, Timing, Ressourcen und Cleanup bleiben unverändert;
kein unveränderter Retry oder gelockerter UNKNOWN-Guard qualifiziert den Test.

Statusfortschreibung 2026-10-08: Der begrenzte native Export-Migrationsfall
in [PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) besteht
am Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` (**PASS**;
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910466),
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910490)).
Auf SQL Server 2019 Linux/CL150 bestand lokal und zentral die tatsächliche
Exportfolge: sieben aktuelle Bootstrapmodule (124 Batches), die gepinnte
Original-Queue2.0 (46 Batches) und der vollständige aktuelle Neun-Modul-Export
(261 Batches), jeweils in frischen ungepoolten Sitzungen. Acht Legacytabellen
mit allen 109 Feldern einschließlich der 43 WorkItem-Felder und des aktiven
Legacyclaims bleiben vor weiterer persistenter DML bytegenau erhalten;
Rowversions, Tokens, NULLs, Audit-/Textbytes, verbrauchte Identitywerte und
ausgewählte Katalogmetadaten sind eingeschlossen. Nur die dokumentierten
Queue-Versions-/Check-ID-Normalisierungen sind ausgenommen. Die drei neutralen
Managedfelder und die bekannten Spaltenformen/neutralen Zustände der sechs
neuen Gate-/Controltabellen bestehen die lesenden Assertions. Eigene
Migration-DB-/Dateibereinigung und separate Containerbereinigung bestanden.
Auch der vorhandene gemeinsame befüllte Exportrepeat bestand separat; die
Migration erhält keine Post-Migration-Completion, Admission, neue Callback-/
SQL-API oder zusätzliche Repeatfolge. Keine Rechte-, Provider-, Trust-,
Konfigurations- oder Zielausweitung; weitere Plattformen/CLs, Minimalrechte,
nichtleere Grants und allgemeiner 44-Modul-Lifecycle bleiben offen.

Frühere Vorbereitungs-/NOT_EXECUTED-Angaben und beide FAILED-Läufe einschließlich
der SKIPPED-Exportschritte bleiben historische Evidenz ihrer Quellenstände.
Der Erfolg schreibt keine früheren Fehler oder fehlenden Cleanupnachweise um.
Die Actor-/Guardianursache des früheren Managed-UNKNOWN bleibt **UNMEASURED**;
im erfolgreichen Lauf erschien kein UNKNOWN-Diagnosedescriptor. Die begrenzte
Beobachterabbildung ist offline validiert; ihre UNKNOWN-Ausgabestrecke wurde
hier nicht ausgelöst. Der UNKNOWN-Guard bleibt unverändert; daraus wird kein
Workerprodukt- oder Ursachenfix abgeleitet. Parentnachweise bleiben erhalten.
Finale Head-CI nach dieser Evidenzfortschreibung, PR291-Merge und anschließende
Main-CI einschließlich Maincleanup sind noch offen.

Statusfortschreibung 2026-10-08 nach PR291-Merge: Die vorstehende offene
Abschlussangabe beschreibt den damaligen Stand. Der erfolgreiche
Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` bleibt erhalten;
auch der finale Head `6a28ba484760d181ce2b37833b339780084a457d` bestand
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411383)
und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411388).
PR291 wurde nach `main` `f8b9b407ad30fc560015b8b475005b4505617689` gemergt.
Die [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938821)
bestand; die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938890)
ist **FAILED** im bestehenden Schritt „Execute genuine Queue 2.0 to 2.1
upgrade“. Die vorherigen realen Linux-Worker-, Managed- und Admissionprüfungen
bestanden. Beide neuen Export-Schritte sind **SKIPPED / NOT_EXECUTED**.
Die separate eigene Containerbereinigung bestand mit genau einem tatsächlichen
festen Cleanupmarker; daraus folgt kein eigener Export- oder Fixturecleanup-PASS.
Die beiden früheren FAILED-Läufe bleiben unverändert historische Evidenz.

Der geschlossene Fehlerbefund nennt die Sourcephase
`control-repeat-post-source-rollback`, SQL1222, die äußere Source-Skriptzeile141
und Orakel `UNSPECIFIED`; der bestehende Sourcefall erwartet SQL54969/State1.
Ein numerischer Enginefehlerdescriptor wurde nicht ausgegeben. Enginezeile,
tatsächlicher State, erster fehlgeschlagener Batch und Blockerursache bleiben
**UNMEASURED**. Weder ein
Timingproblem noch ein Produktfehler ist damit ursächlich belegt; die frühere
Managed-UNKNOWN-Ursache bleibt ebenfalls offen. Kein Main-PASS wird abgeleitet.

Die begrenzte Diagnosewartung liegt als privater, eingefrorener
Testfixturekandidat vor. Ausschließlich `Invoke-ControlRepeatExpectedFailure`
erfasst vor dem unveränderten Weiterwerfen der ersten unerwarteten SQL-Abweisung
den Batch und höchstens vier numerische Enginefehler im vorhandenen
`fixtureSqlFailure`-Pfad; Texte sind auf fünf vorhandene Source-Guardmeldungen
oder leer beschränkt. Die bestehende geschlossene Descriptorabbildung gibt
keine freien Fehlertexte aus. Offlineprüfungen und unabhängiger Client-/Privacy-
Review bestanden: erste begrenzte Erfassung ohne Überschreiben, erwartete
Abweisungen und State-Wildcard unverändert, unbekannte Meldungen ausgeschlossen
und ursprüngliche Exception auch bei fehlgeschlagener Erfassung erhalten.
Syntax sowie vollständige Byteerhaltung außerhalb dieser Diagnosefunktion
wurden offline geprüft. Die native Ausführung des Kandidaten ist
**NOT_EXECUTED**; Ursache und Mainqualifikation bleiben offen. Erwartete
Abweisungen, Orakel, Timing, Transaktions-/Ownership-Guards, Produktquellen,
Ziele und Cleanup bleiben unverändert; kein unveränderter Retry ersetzt diesen
Nachweis. Kanonische Main-Adoption von ParameterMetadata und class3-
Schemaannotation bleibt bis zur Mainqualifikation gesperrt; private Vorbereitung
kann innerhalb der bestehenden Grenzen fortgesetzt werden.



Export-Parametermetadaten, vorbereitet 2026-10-08: Die vorhandene
Deploymentwartungsfreigabe umfasst als nächsten begrenzten Testscope die
bestehenden `USP_PrepareResultTable` und `USP_EnqueueWork` mit insgesamt elf
Parametern. Der vorbereitete Fall `ParameterMetadata` konsumiert die echten
Exporte von result-table, work-type und work-queue lokal/zentral einmal zur
Installation und einmal zum Repeat in jeweils frischen Sitzungen. Vier eigene
class-2-Annotationszeugen prüfen typisierte Werte und `MS_Description` auf
zwei ausgewählten Parametern. Parameterkatalog, ausgewählte Objekt-/Modul-
metadaten, Definitionbytes und alle vorhandenen class-2-Properties dieser
beiden Procedures werden privat binär verglichen; vorhandene Permissions
werden nur beobachtet, auch eine leere Menge wird ausdrücklich gezählt.
T-SQL-`has_default_value = 0` ist kein Nachweis der Parameterdefaults;
deren Definitionbytes bleiben Teil des Erhaltungsorakels.

Offline bestanden: drei Fixtures und ihre quellengebundenen Parameterkarten,
unabhängige Reviews sowie die beiden aktuellen Dreimodul-Exporte mit jeweils
90 Batches, drei Endmarkern und vier Guards; 180 exportierte Batches wurden
mit SQL150 ohne Fehler geparst, die Adapter-PowerShell-AST ist fehlerfrei.
Die native Parameterprüfung einschließlich eigener Bereinigung ist
`NOT_EXECUTED`; Integration und exakte Head-CI stehen aus. Produktquellen,
öffentliche API und Deployment-DDL bleiben unverändert, ebenso Rechte und
Testziele. Bestehende Repeat- und Queue20Upgrade-Zweige bleiben erhalten.
Keine API-Ausführung, neue Tabelle, Benutzergrants, Windows-/weitere CL-
Qualifikation oder vollständige 44-Modul-Erhaltungsbehauptung.

Voraussetzung für die Parameterintegration, Stand 2026-10-08: PR292 wurde
nach `main` `c73f67959185c7a7846455b89c067854dc7d87f6` gemergt.
Die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277392)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277427)
bestanden am exakten Mainstand. Alle drei Workerjobs sowie beide bestehenden
Exportfälle bestanden; die tatsächlichen Festmarker bezeugen beide Export-PASS,
zweimal eigenen Exportcleanup und einmal eigene Containerbereinigung.
Auch die bestehende Control-Repeat- und Ablehnungsabnahme bestand.
Der neue unerwartete SQL-Diagnosezweig wurde dabei **NOT_TRIGGERED**;
seine Offline-Negativprüfung bleibt ein getrennter Nachweis. Der frühere
Mainfehler auf `f8b9b407ad30fc560015b8b475005b4505617689` und seine
weiterhin **UNMEASURED** Ursache bleiben unveränderte Historie; der erfolgreiche
Lauf belegt keine Ursachenbehebung.
Die native Parameterprüfung einschließlich eigener Bereinigung bleibt
**NOT_EXECUTED**. Der Mainnachweis wurde unabhängig geprüft; der Parameter-
branch enthält Adapter, Fixtures und CI-Schritt für die eigene Headprüfung.
Sämtliche bisherigen
Migrations-/Fehler-/Parentnachweise bleiben vollständig erhalten.
Details stehen in [Deploymenttests](../Deployment/Tests/README.md).


Schemaannotation beim bestehenden Exportrepeat, Stand 2026-10-08:
Der nächste begrenzte Maintenance-Test ergänzt genau fünf class-3-Zeugen auf
`toolbelt_core` und `toolbelt_file` samt vollständigem typisiertem Erhaltungsorakel.
Die bestehenden 14 Tabellen mit 156 Spalten, beide Repeatfenster, Identityzeugen
und eigene Bereinigung bleiben erhalten. Der Branch ergänzt drei bestehende
Populated-Fixtures; native class3-Prüfung und ihr eigener Cleanup
sind **NOT_EXECUTED**. Keine neue SQL-Funktion, Rechte- oder Zieländerung.

Voraussetzung, Stand 2026-10-08: PR293 ist nach `main`
`2ad2c018da18768c05f05e0fd7cf4c333fd6b090` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148163)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148155)
bestanden am exakten Mainstand; Parameterrepeat, beide bestehenden Exportfälle,
drei eigene Exportbereinigungen und Containercleanup sind separat bezeugt.
Die Parameter-Mainvoraussetzung ist erfüllt. Native class3-Prüfung und
eigener Cleanup sind **NOT_EXECUTED**; die eigene exakte Head-/Main-CI
einschließlich Bereinigung bleibt **PENDING**.

Objektannotation im bestehenden Exportrepeat, Stand 2026-10-08:
Der Branch ergänzt Setup und Assert um sechs eigene class-1/minor0-Zeugen auf
drei vorhandenen P/FN/V-Objekten. Capture und beide Repeatfenster bleiben erhalten.
[Deploymenttests](../Deployment/Tests/README.md) beschreiben das volle typisierte Orakel.
Native class1-Prüfung und eigener Cleanup: **NOT_EXECUTED**; exakte class1-Head-/Main-CI **PENDING**.

Class3-Voraussetzung erfüllt: PR294, Main `91e13af689334407527fddfdc8d22285933f4225` (2026-10-08).
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103755) und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103790): **PASS**.

Runner und eigenständiger SQL-Export sind über PR282 integriert; PR283 erhält
den Queue2.1-Repeat ohne Control mit allen sieben Queuezuständen. Der enge
Verbundrepeat dieser Runde ist kein allgemeiner Schema-Refresh. Der offene
Gesamtscope umfasst 15 persistente Tabellen in acht Modulen; der neue
Verbundnachweis umfasst zehn Tabellen einschließlich WorkType.

Bei Fortsetzung zunächst die native AGENTS-Kette, Foundation und relevanten
Projektregeln neu ermitteln beziehungsweise einen regelkonform validierten
Analysecache verwenden. Danach den Merge- und CI-Stand aus Git/GitHub sowie
die aktuellen Modulquellen reconciliieren. Private Laufzeitjournale und
Chatverlauf ersetzen diese Repositoryquellen nicht.

| Reihenfolge | Nächster Wartungsscope | Noch fehlender Nachweis oder Entscheidung |
|---|---|---|
| 1 (gezielt bestanden) | `toolbelt.file.content` / `FileContentRootAllowlist` | Befüllter Repeat lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Windows, weitere Repeat-CLs, nichtleere Benutzergrants und echte Minimalrechte bleiben offen. Dieser Tabellenrepeat benötigt weder Datei-I/O noch Konfigurations- oder CLR-Änderungen. |
| 2 (gezielt bestanden) | `toolbelt.core.execution-cancel` / `ExecutionCancellation` | Befüllte Repeats mit exakten Zeilen-, Rowversion- und ausgewählten Katalogvergleichen lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, nichtleere Benutzergrants, Minimalrechte und historische Übergänge bleiben offen. |
| 3 (gezielt bestanden) | `toolbelt.core.event-log` / `EventLog` | Daten-/Identity-/ausgewählter Katalogerhalt und vertragsgemäße WorkType-Reaktivierung mit anschließend unverändertem aktivem Repeat lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische Übergänge bleiben offen. |
| 4 (gezielt bestanden) | `toolbelt.core.second-session` / `SecondSessionProvider` | Deaktivierter Einzelprovider einschließlich acht Spalten, Audit-/Rowversionbytes und ausgewähltem Katalog lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische Übergänge offen; keine Provider- oder Rechteausweitung. |
| 5 (gezielt bestanden) | `toolbelt.filesystem.windows` / `FileSystemRoot` | Windows SQL2025/CL170 lokal: vier Rootzeilen mit allen zehn aktuellen Spalten, zwei befüllte Repeats, zwölf Daten-/Katalogkategorien und zwei inverse Kontrollen bestanden. Weitere Windowsversionen/CLs, nichtleere Grants, Minimalrechte und Datei-I/O bleiben getrennt; zentrale Installation ist nicht unterstützt. |

Wiederaufnahme dieses fünften Scopes durch ausdrücklichen Benutzerauftrag
vom 2026-10-20: Der aktuelle Rootkatalog hat einschließlich der zuvor
integrierten ServiceAccount-Securityspalte zehn Spalten. Ein neuer
[begrenzter Adapter mit Fixture](../Modules/toolbelt.filesystem.windows/Tests/README.md#befüllter-filesystemroot-repeat-2026-10-20)
bereitet den lokalen Vierzeilen-/Zwei-Repeat-Nachweis und zwölf ausgewählte
Daten-/Katalogkategorien vor. Vier synthetische Pfadwerte werden nicht als
Dateisystemzugriff verwendet; zentrale Installation ist für dieses Modul
nicht unterstützt. Reproduzierbarer doppelter Releasebuild und Offline-
Grammatikprüfung bestanden. Zwei native Windows-SQL2025-/CL170-Versuche
bleiben FAILED: zuerst Sessionguard SQL52970/State1, danach ein lokaler
Fixture-/Adapterfehler SQL0/0. Jeweils eigener Cleanup und frische lesende
DB-/Trust-Abwesenheitsprüfung bestanden. Kein Repeat-PASS oder Modulstatus-
Upgrade; die Ursache des zweiten Fehlers ist ungemessen. Diagnosekorrektur,
unabhängiger Review und aktuelle CI bleiben getrennte Nachweise. Das
ursprünglich endliche Limit von zwei vollständigen Versuchen ist verbraucht;
ein weiterer nativer Versuch benötigt eine ausdrückliche neue Begrenzung.

Anschließende ausdrückliche Benutzerfreigabe vom 2026-10-20: höchstens zwei
zusätzliche native Läufe und ein gezielter Abschlussreview. Versuch3 bleibt
FAILED im ersten Capture mit privater InvalidCast-/Quellzeilendiagnose;
eigener Cleanup und frische Abwesenheitsprüfung bestanden. Eine rein lesende
synthetische Probe bestätigte SQL NULL/DBNull beim leeren XML-Binarycast.
Der Capture unterscheidet nun ausdrücklich das leere Permissionset von
leeren Bytes, bewahrt alle übrigen Pflichtkategorien und verwirft falsche
Typen/Kategorien. Fünf synthetische Payloadkontrollen bestanden.
Versuch4 bestand den vollständigen begrenzten Adapter: beide Repeats und
beide inversen Kontrollen, Exit0, vollständige Kanäle, leeres Stderr, eigene
DB-/Trustbereinigung und frischer lesender Input-/Abwesenheitsaudit. Drei
historische FAILs bleiben erhalten; Produktquellen und Releasebytes sind
unverändert. Die zunächst offenen Wiederholungsangaben oben sind damit
für diesen ausgewählten Windows-SQL2025-/CL170-/Local-Scope abgelöst.
Weitere Ziel-/Rechte-/I/O-/TLS- und Releasequalifikation bleiben getrennt;
kein neuer öffentlicher Funktionsvertrag oder Modulstatus-Upgrade.

Danach die exportierte gemeinsame Modulfolge mit befüllten Tabellen prüfen.
Gesamtdeployment bleibt nicht atomar; Objekt-/Berechtigungserhaltung, lokale
und zentrale Modi, weitere Plattformen und echte Minimalrechte benötigen
eigene Qualifikation. Nichtleere Benutzergrants sind im Queue-/Control-Verbundrepeat
und File-Content-Repeat nicht nachgewiesen. Die fünf zusätzlichen Tabellenquellen erstellen
fehlende Tabellen, liefern aber keinen allgemeinen Schemaabgleich.
Unbekannte/partielle Installationen und historische Schemaübergänge benötigen
gesondert beschriebene versionierte Migrationspfade. Q1 V1 bleibt zustandslos.
Dieser Checkpoint erteilt keine neue Funktions-, API- oder generische
Copy-/Swap-Migrationsfreigabe.

Datierte Benutzerfreigabe 2026-10-08: Auf die Erläuterung der pauschalen
lokalen SQL-/Dockerpause antwortet der Benutzer: „man kann diese Sperre
überhaupt wieder entfernen“. Die pauschale Pause ist damit aufgehoben;
bereits freigegebene Entwicklungs- und Testscopes dürfen wieder lokale
SQL-Läufe verwenden. Schema-validierte, ausdrücklich ausgewählte bereite
Labziele, vorhandene Rechte, begrenzte Testscopes und eigene
Wiederherstellungs-/Cleanupjournale bleiben Voraussetzung. Diese Freigabe
erweitert weder Infrastrukturverwaltung noch Rechte, Provider, öffentliche
Funktionen oder bisher nicht freigegebene Lasttests. Sie ist kein
Ursachennachweis für das vorherige Stabilitätsproblem.

Die native Windows-CLR-Qualifikation des neuen
ScriptDom-Pins und seines Table-Clone-Consumers bleibt ein getrennter offener
Nachweis; Syntaxparser und historische Security-Cloud-Ergebnisse ersetzen
keine frische Runtime- oder Security-Qualifikation. Fehlgeschlagene frühere
CI-Läufe behalten ihren Status.

### RI-2026-041: JSON Pointer – einzeln freigegeben 2026-10-05

Aktualisierung 2026-10-19: Zwölf aktuelle vollständige Pointer-Labadapter
bestanden auf Windows und Linux: SQL2019 CL150, SQL2022 CL150/160 und
SQL2025 CL150/160/170, jeweils local/central/Consumer. Je 3072 feste
Contract-/Safety-Oracles, 15 Clientreader und 42 Lifecyclefälle; frische
read-only Audits bestätigten Input-/Fixturepins und 36 eigene DBs abwesend.
Der seit den alten Läufen ergänzte SC-006-Source ist gebunden; die separate
Securityfixture und neue Lastfälle waren nicht Teil dieser Labwelle.
Die physischen Ziel-/CL-Lücken des full-Adapters sind damit geschlossen.
Minimalrechte, Heap/Parallelität, harte Runner-/Host-Recovery, authentifizierte
TLS-Abnahme und Release bleiben separat; teilweise validiert, unveröffentlicht.
[Qualifikationsbericht](../Modules/toolbelt.json.pointer/Tests/QUALIFICATION_2026-10-19.md).

Die folgenden älteren Nachweise behalten Datum und ursprünglichen Scope.

Nach konkreter Besprechung und Design-/Enginevorprüfung in
[PR173](https://github.com/gecompat/SQL_Server_Toolbelt/pull/173) antwortete der
Benutzer ausdrücklich „Diese Pointer-Funktion freigegeben“. Genau eine lesende
T-SQL-MSTVF `toolbelt_json.TVF_ResolveJsonPointer`: Json/Pointer nvarchar(max),
MaxInputBytes bigint=16777216, MaxDepth int=128; positiv und nur absenkbar,
Pointer höchstens4000 UTF16-Einheiten. Genau eine Status/JsonType/Value/ErrorCode-
Zeile mit FOUND/MISSING/JSON_NULL/SQL_NULL/INVALID und besprochener Priorität.
Exakte Keys, passende Duplicatekeys ungültig, vollständige Unicode-/Tiefenprüfung,
native ISJSON/OPENJSON-Grammatik plus Policywalker; keine CLR-Änderung.
Fragmentkosten und API-/Lifecyclequalifikation sind ausdrücklich eingeschlossen.
Der [kanonische Vertrag](../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
begrenzt die autonome Umsetzung einschließlich Review, begrenzter Tests,
exakter Head-CI, PR/Merge und eigenem Branch-Cleanup. Keine Schema-, Patch-,
Providerwechsel- oder Veröffentlichungsgenehmigung. Status: aktive Umsetzung;
keine öffentliche API-Runtimequalifikation allein aus der Freigabe abgeleitet.
Ältere offene Pointer-Sourcegate-Aussagen bleiben Historie; diese datierte
Einzelzustimmung ersetzt ausschließlich deren Freigabegrenze.

Native Vertragsgrenze 2026-10-05: SQL2019-ISJSON wirft bei129 offenen
Containern SQL13606/state1, sowohl für gültiges als auch fehlerhaftes JSON.
Zwei begrenzte Adapter scheiterten in Safety; der zweite isolierte Fall41.
Je FAILED_CLEANED, eigene DB über neue Verbindung abwesend und Inputpins
unverändert; kein vollständiger Sicherheits-/Client-/Lifecycle-PASS.
Der [konkrete Änderungsvorschlag](../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
führt einen vorgelagerten festen128er-Guard mit DEPTH_LIMIT vor JSON_SYNTAX
nur jenseits dieser nativen Grenze ein. Zustimmung zu dieser neuen Priorität
steht aus; die bestehende Funktionsfreigabe bleibt gültig. Unabhängige
Lifecycle-/Dokumentationsarbeit darf fortgesetzt werden.
Separater Lifecycle-Scope auf Linux2019/latest CL150 und Windows2025/exaktCU8
CL170 anschließend bestanden: je local/central/Consumer,15 direkte Clientreader,
42 gezielte Lifecyclefälle, Exit0 und vollständige Kanäle mit leeremStderr.
Frische unabhängige Audits bestätigen je drei eigeneDBs abwesend, je zwei
Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit zwei Abweisungen
und sämtlicheInputpins unverändert; Nullscope Konfiguration/Rechte/Trust.
Contract/Safety-Fixtures in diesem Scope ausdrücklich nicht ausgeführt;
die notwendige Prioritätszustimmung bleibt offen.

Anschließende konkrete Zustimmung 2026-10-05: Der Benutzer antwortete
„Diese Prioritätsänderung freigegeben“. Damit ist genau der vorgelagerte
nonnegative128er-Strukturguard mit DEPTH_LIMIT auch vor fehlerhafter Syntax
jenseits128 und der geschützte Scalarwrapper freigegeben. Bis128 bleibt
JSON_SYNTAX vor caller-seitig abgesenktem MaxDepth; sonstige Oberfläche und
Semantik unverändert. Sourcekorrektur und neue vollständige Qualifikation
werden autonom fortgesetzt. Die vorherigen offenen Aussagen dokumentieren
den Stand vor dieser ausdrücklichen Antwort, die Fehlläufe bleiben Historie.
Finaler freigegebener Guard-/Wrapperstand auf Linux2019/latest CL150 und
Windows2025/exaktCU8 CL170 vollständig im begrenzten local/central/Consumer-
Scope bestanden: je3072 feste Contract-/Safety-APPLY-Oracles,15 direkte
Clientreader,42 Lifecyclefälle und Erst-/Repeat-/Uninstall-/Repeat. Je Exit0,
vollständige Kanäle und leeresStderr. Frische Audits bestätigen COMPLETE42,
je drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures
exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert.
Nullscope Konfiguration/Rechte/Trust. Beide finalen Zieladapter verwenden
identische eingefrorene Repository-Inputs. Weitere Ziele, Minimalrechte,
16MiB-Maximalworkload/Heap und exakteHead-CI separat offen; teilweise validiert,
unveröffentlicht. Frühere Fehlläufe bleiben fehlgeschlagen.

Zusätzliche Qualifikation 2026-10-06: Auf demselben zuvor ausgewählten,
schema-validierten Windows2025/exaktCU8-Ziel bestanden die vollständigen
Pointer-Adapter mit CL150 und CL160, jeweils local/central/Consumer,
Contract/Safety, direkte Clientmetadaten und42 Lifecyclefälle. Zwei frische
unabhängige Audits bestätigen je eigene DB-Bereinigung, exakte Wiederherstellung
der Marker-/Fremdslot-/Dependencyfixtures und unveränderte Inputpins; keine
Konfigurations-, Rechte- oder Truständerung. Die früheren CL170-/Linuxnachweise
bleiben getrennt. Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/
Heap und vollständige Runtime-Head-CI bleiben offen.

CI-Fortschritt 2026-10-06: [PR187](https://github.com/gecompat/SQL_Server_Toolbelt/pull/187)
bestand am exakten Head `57dbc5e319b8229a68cf87d0a1140dec687ae4d2` die
[Dokumentationsprüfung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031663)
und den [Pointer-Runtime-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031731)
mit erfolgreichen Linux-2019/2022/2025-Jobs. Auf `main` bestanden danach
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199690)
und [Pointer-Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199703)
erneut. Der CI-Scope umfasst synthetische Contract-/Safetyfixtures, echte
Clientmetadaten und installierte Baseline mit local/central/Consumer, Repeat
und Uninstall. Die 42 gezielten Lifecyclefälle sind bislang nur in den oben
genannten physischen Labadaptern belegt. Ihre vollständige Head-CI, weitere
physische Ziele, Minimalrechte, Hard-Interrupt-Recovery, 16-MiB-Maximalworkload
und Heap bleiben offen; `partially validated`,
`unreleased`.

Eng begrenzte Lastqualifikation 2026-10-06: Nach
[PR201](https://github.com/gecompat/SQL_Server_Toolbelt/pull/201) bestanden
auf flüchtigem Linux-SQL2019-CL150-Container acht einzeln manuell ausgelöste
Größen-/Formstufen: Root und `/k` bei 64KiB,1MiB,4MiB und exakt16MiB
Originalbytes mit serverseitigem Einzeilen-/Längen-/SHA2-256-Orakel und
bestätigter eigener Bereinigung. Die [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md)
verlinkt jeden Run. Die zuvor offenen 16-MiB-Aussagen beschrieben den Stand
vor diesen gezielten Läufen. SQL2022/2025-Maximallast, weitere Plattformen,
Tiefe128 bei Maximalgröße, Heap, Parallelität, tatsächliche Minimalrechte,
Hard-Interrupt-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

Weitere eng begrenzte Tiefenqualifikation 2026-10-06: Nach
[PR203](https://github.com/gecompat/SQL_Server_Toolbelt/pull/203) bestanden
auf flüchtigem Linux-SQL2019-CL150-Container zehn manuelle Einzeljobs:
64KiB mit Tiefe2,4,8,16,32,64,128 und anschließend Tiefe128 mit1MiB,4MiB
und exakt16MiB. Je eigenes serverseitiges Oracle, testdefinierte 3-GiB-
Containergrenze und bestätigte Bereinigung. Die [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md)
verlinkt alle Runs. Die zuvor offene Tiefe128/Maximalgröße ist damit nur für
diese synthetische Kombination geschlossen. SQL2022/2025-Maximallast,
weitere JSON-Formen/Plattformen, Heap, Parallelität, Minimalrechte,
Hard-Interrupt-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

Zusätzliche lokale Lastqualifikation 2026-10-06: derselbe unveränderte
Einzelfalladapter bestand auf flüchtigem Linux-SQL2022-CL160 und SQL2025-
CL170 je Root und `/k` bei64KiB,1MiB,4MiB und exakt16MiB. Alle16 Fälle
lieferten das exakte serverseitige Einzeilen-/Längen-/SHA2-256-Oracle und
bestätigten eigene Bereinigung; frische Docker-Owner-Abfragen fanden keinen
eigenen Lastcontainer. Kein neuer GitHub-Dispatch oder Labzieltest. Frühere
offene Aussagen beschreiben ihren damaligen Stand. Tiefe128 bei Maximalgröße
auf SQL2022/2025, weitere JSON-Formen/Plattformen, reale Heap-/Parallel-
kapazität, Minimalrechte, Runner-/Host-Recovery und Release bleiben offen.

Weitere lokale Tiefenqualifikation 2026-10-06: Auf denselben flüchtigen
Linux-SQL2022-CL160-/SQL2025-CL170-Images bestanden je sieben Einzelprozesse
bei64KiB/Tiefe2,4,8,16,32,64,128 und je drei bei Tiefe128/1MiB,4MiB,
exakt16MiB. Alle20 lieferten das serverseitige Einzeilen-/Längen-/Hashoracle,
meldeten eigene Bereinigung und bestanden je Version den frischen
Owner-Label-Abwesenheitsaudit. [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md).
Die vorherige offene Tiefe128/Maximalgröße war zeitgebunden. Andere JSON-
Formen/Plattformen, tatsächlicher Heap, Parallelität, Minimalrechte,
Runner-/Host-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

### RI-2026-076: sechs Safe-Cast-TVFs – einzeln freigegeben 2026-10-05

**Nachqualifikation 2026-10-19:** Der Benutzer beauftragte nach der getrennten
Statusbereinigung die autonom ausführbaren Safe-Cast-Labfälle und einen
eigenen PR. Zwölf aktuelle Adapter bestanden auf physischen Windows-/Linux-
Zielen: 2019 CL150, 2022 CL150/160, 2025 CL150/160/170, je local/central/
Consumer und 38 Lifecyclefälle. Frische read-only Audits bestätigten alle
Inputs vor dem Evidenznachtrag, exakte Fixturewiederherstellung und 36 eigene
DBs abwesend. Zwei echte source-extrahierte ADO.NET-Setupfehler bestanden ohne
SQL; keine Produkt-, Konfigurations-, Rechte- oder Truständerung. Physische
Ziel-/CL-Lücken sind für diesen aktuellen Scope geschlossen. Minimalrechte,
harte Runner-/Host-Recovery, Kapazität, Head-CI und Release bleiben separat;
`partially validated`, `unreleased`.
[Bericht und Reproduktion](../Modules/toolbelt.conversion.safe-cast/Tests/QUALIFICATION_2026-10-19.md).
Die folgenden älteren Zielnachweise behalten Datum und ursprünglichen Scope.

Nach der Vertragsbesprechung in [PR170](https://github.com/gecompat/SQL_Server_Toolbelt/pull/170)
und der konkreten anschließenden Frage antwortete der Benutzer ausdrücklich:
„Diese sechs Funktionen freigegeben“. Damit sind genau `TVF_TryCastBigInt`,
`TVF_TryCastDecimal`, `TVF_TryCastDate`, `TVF_TryCastDateTime2`, `TVF_TryCastBit`
und `TVF_TryCastUniqueIdentifier` zur autonomen Umsetzung freigegeben.
Reine Inline-T-SQL-TVFs, je Value/Status/ErrorCode, strikte ASCII-/ISO-Lexik,
decimal(38,18), datetime2(7), maximal8192 Inputbytes, keine stille Rundung;
die explizite Zustimmung umfasst exakte Bereichsprüfung vor LOSSY und
INVALID_ARGUMENT/PARAMETER bei ungültigen Budgets. Zweck, native Alternative,
Optimizer-, Locale-, Trunkierungs- und Rundungsrisiken wurden besprochen.

Der [kanonische Vertrag](../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
konkretisiert die Umsetzung. Status: implementiert, `partially validated`,
`unreleased`. Finale lokale Adapter auf Linux2019/latest CL150 und Windows2025/
exaktCU8 CL170 bestanden local/central und mit separatem Consumer: je13104
API-Oracles,54 Clientreader und38 gezielte Lifecyclefälle sowie Uninstall/Repeat.
Je Exit0, vollständige Kanäle und leeres Stderr; frische unabhängige Audits
bestätigen alle Inputpins, zwei Marker-/zwei Fremdslotfixtures exakt restauriert
und drei eigene Datenbanken abwesend. Keine Konfigurations-, Rechte- oder
Truständerungen. Drei frühere Gesamtfehlläufe bleiben getrennt fehlgeschlagen.
Weitere physische Ziele, Minimalrechte, Heap und exakte Head-CI separat offen.
Zusätzliche Qualifikation 2026-10-06: Auf demselben bereits ausgewählten,
schema-validierten Windows2025/exaktCU8-Ziel bestanden die vollständigen
Safe-Cast-Adapter mit CL150 und CL160, je local/central/Consumer mit 13104
API-Oracles, 54 Clientreadern und 38 Lifecyclefällen. Zwei unabhängige frische
Audits bestätigten je drei eigene DBs abwesend, exakte Marker-/Fremdslot-
Wiederherstellung und unveränderte Input-/Sourcepins. Keine Konfigurations-,
Rechte- oder Truständerung; übrige physische Ziele, Minimalrechte, Heap und
vollständige Runtime-Head-CI bleiben offen.

CI-Fortschritt 2026-10-06: [PR186](https://github.com/gecompat/SQL_Server_Toolbelt/pull/186)
bestand am exakten Head `64f4ab9dbd48a8eefd838f9fb95f3ab13e507513` die
[Dokumentationsprüfung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402202963)
und den [Safe-Cast-Runtime-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402203046)
mit erfolgreichen Linux-2019/2022/2025-Jobs. Auf `main` bestanden danach
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837670)
und [Safe-Cast-Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837558)
erneut. Der CI-Scope umfasst synthetische API-Fixtures, echte Clientmetadaten
und installierte Baseline mit local/central/Consumer, Repeat und Uninstall.
Die 38 gezielten Lifecyclefälle sind bislang nur in den oben genannten
physischen Labadaptern belegt. Ihre vollständige Head-CI, weitere physische
Ziele, Minimalrechte, Hard-Interrupt-Recovery und Heap bleiben offene
Nachweise; `partially validated`, `unreleased`.

Unabhängiger Review, begrenzte relevante Tests, exakte Head-CI, PR/Merge und
eigener Branch-Cleanup gehören zur bereits beauftragten Fortsetzung.
Keine neue Pointer-/Schema-/CLR-/Veröffentlichungsfreigabe. Ältere Aussagen
über offene Safe-Cast-Details dokumentieren den damaligen Vorschlagsstand;
diese datierte Einzelzustimmung ersetzt ausschließlich dessen Freigabegrenze.

### RI-2026-109: CSV-Memory – konkretisierte Umsetzung freigegeben 2026-10-05

Die unmittelbar vor der Fortsetzungsanweisung vorgelegte konkrete Welle umfasst
`USP_ParseCsv` und `USP_WriteCsv` mit eigener portabler SAFE-CLR-Assembly,
100000 Datenzeilen, 1024 Spalten, 1000000 Zellen und 16 MiB UTF16-Textbudget;
die Limits sind ausschließlich absenkbar. Zweck, öffentlicher Vertrag,
NULL-Token, T-SQL-Alternative, Trust-/Deploymentaufwand und Risiken wurden
besprochen. Darauf beauftragte der Benutzer autonome Weiterentwicklung bis
zu seinem Stopp oder einer tatsächlich notwendigen Eingabe und verwies
ausdrücklich auf die abgeschlossene Besprechung. Diese Antwort auf den
konkreten CSV-Vorschlag ist die funktionsbezogene Implementierungsfreigabe;
die zuvor engere Bewertung als offenes CSV-Sourcegate ist damit korrigiert.

Scope: genau diese beiden öffentlichen USPs, In-memory ohne Datei-/Netzwerkzugriff,
kanonischer ResultTable-Vertrag, unabhängiger Review, begrenzte aussagekräftige
Tests, exakte grüne Head-CI, PR/Merge und eigener Branch-Cleanup. Keine
Veröffentlichung; JSON Pointer, Safe Cast und JSON Schema erhalten daraus
keine Sourcefreigabe. Der [CSV-Vertrag](../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
konkretisiert die bereits besprochenen Grenzen. Version1.0.0 ist `implemented`,
`partially validated`, `unreleased`. Am 2026-10-05 bestanden statische Verträge
und das exakt gepackte CLR-Binary unter .NET48 in drei Kulturen einschließlich
harter Grenzfälle und IL-/NoIO-Prüfungen. Der achte öffentliche native
Gesamtadapter bestand auf Linux2019/latest CL150 local/central mit finalem
gepacktem Produkt und gleichen CLR-Bytes: drei SQLfixtures, Clientmetadaten,
Clean/Repeat, fünf Slots/drei Bindings, 29 konkrete Caller-/SET-/Lock-/Rollback-/
Confirm0-Prüfungen, frischer SC-/UTF8-Consumer und Uninstall/Repeat. Exit0,
vollständige Kanäle, leeres Stderr und eigener Cleanup im Lauf bestanden;
Der frische unabhängige Audit dieses Laufs bestand anschließend.
Derselbe finale Adapter und dasselbe Produkt-/Binarypaar bestanden zusätzlich
auf Windows2025/exaktCU8 CL170 local/central mit identischem Fixture-/Client-/
Consumer-/29-Lifecycle-Scope, Exit0, vollständigen Kanälen, leerem Stderr und
Cleanup im Lauf. Der frische Linuxaudit bestätigt drei eigene DBs/einen eigenen
Trusthash abwesend; der frische Windowsaudit bestätigt ebenfalls drei eigene
DBs/einen eigenen Trusthash abwesend. Historische Syntax-/
LF-Padding-Fehlläufe und der fünfte Metadata-Fehllauf bleiben FAILED. Die
Produktkorrekturen betreffen LF-Padding und drei Help-first-NOT-NULL-Spalten.
Keine Konfigurations-/Rechteänderungen. Weitere Ziele, Fremdslot-/
Driftvollmatrix, Minimalrechte und Heap bleiben offen.
Abschluss: [PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169)
ist mit fünf erfolgreichen Checks am exakten Head gemergt. Main/origin-main
und eigener Branch-Cleanup geprüft. Modulstatus bleibt teilweise validiert
und unveröffentlicht; keine Übertragung der Freigabe auf Folgefunktionen.

Ergänzende begrenzte Zielwelle 2026-10-20 nach dem ausdrücklich beauftragten
FileSystemRoot-Abschluss und autonomen Start der nächsten Welle: vier weitere
physische Kombinationen bestanden jeweils im ersten nativen Gesamtadapterlauf:
Windows2019/base CL150 und Windows2022/base CL160 mit erlaubten bereiten
CU-Äquivalenten sowie Linux2022/latest CL160 und Linux2025/latest CL170.
Dasselbe neue reproduzierbar gebaute Releasepaket bestand vorher den
Framework-/IL-/NoIO-Scope in drei Kulturen. Je Ziel bestanden local/central,
drei SQLfixtures, Client, Clean/Repeat, fünf Slots/drei Bindings, 29 gezielte
Lifecyclefälle, frischer SC-/UTF8-Consumer und Uninstall/Repeat. Je Exit0,
vollständige Kanäle/leeres Stderr und frischer unabhängiger OwnDB-/Trustaudit
bestanden. Autorisierte temporäre CLR-Testkonfiguration auf drei Zielen samt
vorgemerktem Scope privat erfasst und vollständig in den Ausgangszustand
restauriert; keine Rechte-/Infrastrukturänderungen. Historische Läufe bleiben
an ihr Datum und ihre damaligen Abhängigkeiten gebunden; keine neue Ausführung
auf Linux2019 oder Windows2025. Weitere CLs, Minimalrechte, Fremdslot-/
Driftvollmatrix, Heap, authentifiziertes TLS und Release bleiben offen.
Status weiterhin `partially validated`, `unreleased`;
[Testnachweis](../Modules/toolbelt.file.csv-memory/Tests/README.md) und
[Matrix](../Modules/toolbelt.file.csv-memory/Tests/CSV_TEST_MATRIX.md).

Nachfolgende begrenzte Standard-CL-Ergänzung 2026-10-20: Die zuvor nur historisch
qualifizierten Ziele Linux2019/latest CL150 und Windows2025/base CL170 mit
erlaubtem bereitem CU-Äquivalent bestanden mit aktuellen ResultTable-Abhängigkeiten
jeweils local/central im ersten nativen Versuch. Je gleicher SQL-/Client-/
29-Lifecycle-/Consumer-/Uninstall-Scope, Exit0, vollständige Kanäle, leeres
Stderr und frischer unabhängiger Cleanup-Audit bestanden; keine Konfigurations-,
Rechte-, Owner- oder Infrastrukturänderungen. Paket und ursprüngliche
Build-/Frameworknachweise vom selben Tag wurden nach Inputprüfung wiederverwendet,
nicht neu ausgeführt. Mit PR338 sind damit alle sechs physischen Kombinationen
am aktuellen Quellen-/Abhängigkeitsstand mit Standard-CL150/160/170 im begrenzten
Adapter bestanden. Zusätzliche CLs und die übrigen oben genannten Grenzen bleiben
offen; `partially validated`, `unreleased` bleiben unverändert.

Anschließende getrennte CL-Welle 2026-10-20 nach PR339: sechs zusätzliche
Kombinationen Windows/Linux jeweils SQL2022 CL150 sowie SQL2025 CL150 und CL160
bestanden je im ersten nativen Versuch mit beiden Modi und demselben begrenzten
SQL-/Client-/29-Lifecycle-/Consumer-/Uninstall-Scope. Exit0, vollständige Kanäle,
leeres Stderr und je frischer unabhängiger OwnDB-/Trustaudit bestanden.
Zwei autorisierte temporäre CLR-Konfigurationen auf SQL2022 vollständig
restauriert; keine Rechte-/Owner-/Infrastrukturänderungen. Paket, ursprüngliche
Build-/Frameworknachweise und die sechs Standard-CL-Läufe wurden nach erneuter
Inputprüfung wiederverwendet, nicht erneut ausgeführt. Am aktuellen Quellen-/
Abhängigkeitsstand sind damit alle zwölf zulässigen Plattform-/Engine-/CL-
Kombinationen im begrenzten Gesamtadapter bestanden. Minimalrechte,
Fremdslot-/Driftvollmatrix, weitere Collations, Heap, authentifiziertes TLS und
Release bleiben offen; `partially validated`, `unreleased` bleiben unverändert.

Nächste begrenzte Lifecyclewelle 2026-10-20: getrennt wählbarer Marker-Guardscope
mit zehn eigenen Markeränderungen, je Deploy-/Uninstallabweisung und exakter
Restaurierung. Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170
bestand local/central mit 40 Abweisungen und frischem OwnDB-/Trustaudit. Zwei
Linux2019-Guardversuche scheiterten an neuen Fixture-Sitzungsprüfungen und
bleiben FAILED, beide frisch bereinigt. Ein separater Linux-Defaultlauf mit
29 Lifecyclefällen und vollständigem API-/Client-/Consumer-Scope bestand;
der ausdrücklich freigegebene dritte Linux-Guardlauf bestand anschließend
local/central mit 40 Abweisungen, exakter Markerrestaurierung und frischem
OwnDB-/Trustaudit als fünfter und letzter nativer Lauf dieser Welle. 27 synthetische
Fail-closed-Kontrollen bestanden. Keine Produkt-, Konfigurations-, Rechte-,
Owner- oder Infrastrukturänderung; teilweise validiert und unveröffentlicht.

Die nach PR341 beauftragte getrennte Fremdslot-/Verbraucherwelle bestand auf
Linux2019/latest CL150 im zweiten und Windows2025/base CL170 mit erlaubtem
CU-Äquivalent im ersten nativen Versuch jeweils local/central: fünf
tabellenbelegte CSV-Zielslots sowie je ein SQL-/CLR-Verbraucher gegen Deploy und
Uninstall, je Ziel 28 Abweisungen und vier NULL-/Leer-/Index-Witnesskontrollen.
Je Exit0, vollständige Kanäle, leeres Stderr und frischer unabhängiger Audit
zwei eigene DBs/ein eigener Trusthash abwesend. Erster Linuxversuch bleibt
FAILED am Leerkatalogsnapshot, frisch bereinigt; leerer FOR-JSON-Skalar jetzt
als [] im gemeinsamen Snapshothelper, strenges Zustandsorakel erhalten.
Separater Linux-Defaultregressionslauf local/central mit SQLfixtures, Client,
29 Lifecyclefällen und SC-/UTF8-Consumer PASS, frischer Audit drei eigene
DBs/ein eigener Trusthash abwesend. Inputpins und Konfiguration unverändert.
50 Offlinekontrollen einschließlich der im Review gefundenen leeren Modusliste
und SQL150-Grammatikprüfungen der elf Fixture-Batches und des korrigierten
Snapshots bestanden. Keine Produkt-, Deployment-, CLR-, Rechte-/Owner-/
Infrastrukturänderung oder Statusaufwertung; keine neue Zwölfzielabnahme.

Nach PR342 bestand die begrenzte Welle fehlender Ownershipmarker 2026-10-20:
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem CU-Äquivalent
jeweils local/central im ersten Versuch. Je Modus 27 einzelne Entfernungen
(20 Objekt-, drei Assembly-, zwei Datenbank-, zwei Schemamarker), beide
Lifecycleoperationen mit SQL55324/state1/2/3/4/5 abgewiesen; je Ziel 108
Abweisungen, unveränderter erfasster Mutationszustand und exakte typisierte
Restaurierung. Je Exit0, vollständige Kanäle, leeres Stderr und frischer
unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend; Inputs und
Konfiguration unverändert. 121 Offlinekontrollen und SQL150-Grammatik aller
108 expandierten Fixture-Batches bestanden. Keine Produkt-/Deployment-/CLR-/
Rechte-/Owner-/Infrastrukturänderung oder Statusaufwertung. Die anschließend
beauftragte getrennte Folgewelle prüft fremde Views/Prozeduren auf Zielslots;
deren native Ausführung war zu diesem Zeitpunkt noch not executed.

Anschließender Nachweis nach PR343, 2026-10-20: Getrennter Scope foreign-kinds
bestand auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem
CU-Äquivalent jeweils local/central im ersten Versuch. Fünf reservierte Namen
je als fremde View und SQL-Prozedur, je Deploy/Uninstall SQL55324/state3;
40 Abweisungen pro Ziel, erfasste Definitionen/Signaturen und synthetische
Ergebnisse einschließlich Padding unverändert, geschützte eigene
Fixtureentfernung und saubere Baseline. Je Exit0, vollständige Kanäle, leeres
Stderr und frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash
abwesend, Konfiguration und Runtimeinputs unverändert. 163 Offlinekontrollen
und SQL150-Grammatik aller 60 expandierten Fixture-Batches bestanden. Keine
Produkt-/Deployment-/CLR-/Rechte-/Owner-/Infrastrukturänderung oder
Statusaufwertung; weitere Fremdarten, Synonyme, Verbraucher-/Binding-/
Driftvollmatrix, Minimalrechte, Heap, authentifiziertes TLS und Release offen.

Nach PR344, 2026-10-20: Der getrennte Alias-Guardscope bestand auf
Linux2019/latest CL150 im zweiten und Windows2025/base CL170 mit erlaubtem
CU-Äquivalent im ersten Versuch jeweils local/central. Fünf reservierte Namen
je als fremdes Synonym und SQL-Skalarfunktion, je Deploy/Uninstall SQL55324/state3,
40 Abweisungen pro Ziel; bytegenau vollständig quotiertes Synonymziel auf eigene
sameDB-Fixture, erfasster Zustand und Ergebniswerte unverändert. Separater
Linux-View-/Prozedur-Regressionslauf mit 40 Abweisungen bestanden. Je erfolgreichem
Lauf Exit0, vollständige Kanäle, leeres Stderr, frischer unabhängiger Audit zwei
eigene DBs/ein eigener Trusthash abwesend; Konfiguration und Runtimeinputs
unverändert. Erster Linuxversuch bleibt FAILED am zusätzlichen Target-Cleanup,
frisch bereinigt; falsches unquotiertes Sollformat und Diagnoseüberdeckung
korrigiert. 194 Offlinekontrollen und SQL150-Grammatik aller 173 expandierten
Fixture-Batches bestanden. Keine Produkt-/Deployment-/CLR-/Rechte-/Owner-/
Infrastrukturänderung oder Statusaufwertung. Die anschließend beauftragte
getrennte Folgewelle betrifft gezielte interne CLR-Bindingdrift.

Nach PR345, 2026-10-20: Der getrennte Binding-Guardscope bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem CU-Äquivalent
jeweils local/central im ersten nativen Versuch. Acht einzelne Änderungen an
den drei internen CLR-Funktionen: zwei NULL-Aufrufoptionen, vier Textlängen,
ein Parametername und ein Resultatspaltenname. Je Deploy/Uninstall SQL55324/state5/7,
32 Abweisungen pro Ziel mit konkretem Katalogwitness, unverändertem erfasstem
Mutationszustand und exakter Restaurierung bei unveränderter Objektidentität.
Clean/Repeat, Uninstall/Repeat, Exit0, vollständige Kanäle, leeres Stderr;
je frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend,
Konfiguration und Runtimeinputs unverändert. 235 Offlinekontrollen,
Helper-/Adapter-AST und SQL150-Grammatik aller 32 expandierten Batches bestanden.
Produkt-/Deployment-/CLR-Quellen und gemeinsame Snapshot-/Abweisungshelper
unverändert. Keine Statusaufwertung oder neue Default-/API-/Client-/Minimalrechte-/
Heap-/authentifizierte TLS-/Release- oder vollständige Binding-/Driftmatrixabnahme.

Nach PR346, 2026-10-20: Neuer Zwei-Wellen-Auftrag CLR-Parameterdefaults, danach
benannte SameDB-SQL-Verbraucher. Ausdrücklich freigegebener sechster und letzter nativer Lauf dieser Welle: Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 im dritten Defaultsversuch local/central PASS. Fünf Parameterdefaults, je Deploy/Uninstall SQL55324/state7:20 Abweisungen; exakte Basistyp-/Wertbytesprüfung mit DATALENGTH beim Text und separatem NULL-Witness vor/nach Abweisung sowie vor Restaurierung, danach exakte Baseline. Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Dieser repräsentative Windowslauf qualifiziert den finalen korrigierten Assertionstand. Alle fünf vorangehenden Läufe bleiben mit engeren Orakeln bzw. als frühere Linux-Bindingregression32 datiert und frisch bereinigt; keine nachträgliche Aufwertung. 255Offlinekontrollen,52SQL150-Batches,AST,Static und Docvalidator PASS. Unabhängiger Quell-/Orakelreview der finalen Assertions PASS vor diesem Abschlusslauf; neue Laufmetriken deterministisch geprüft. Produkt-/Deployment-/CLR-Quellen und gemeinsame Snapshot-/Abweisungshelper unverändert. Kein neuer Defaultadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierter TLS-/Release-Nachweis.

Nach PR347, 2026-10-20: Die ausgewählte zweite Welle prüft benannte SameDB-SQL-Verbraucher. Finaler vierter nativer Lauf dieser Welle Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 im zweiten Versuch local/central PASS: fünf nacheinander angelegte Consumer mit explizitem eigenem SameDB-Namen, je Deploy/Uninstall SQL55325/state3,20 Abweisungen. Exakte Zielnamen/eigene DB, zulässige lokale ID- oder Namensbindung und Fingerprint sämtlicher erfasster Dependencyzeilen; Erhalt unmittelbar vor/nach jeder Abweisung und vor geschütztem Fixture-Drop, Gesamtsnapshot und Baseline erhalten. Typisierte OwnDB-/Fixturemarker und Objekt-/Erstellungsidentitäten geprüft. Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. Vorheriger zweiter Linuxlauf und erster Windowslauf bestanden je20 Abweisungen ohne zusätzliche unmittelbare Vorabprüfung der zweiten Operation; enger datiert. Erster Linuxfehllauf bleibt FAILED und bereinigt. 301Offlinekontrollen einschließlich Dependencydrift ausschließlich vor der zweiten Operation,40SQL150-Batches,AST/Static und Docvalidator samt16Impactselftests PASS. Produkt-/Deployment-/CLR-/gemeinsame Helper unverändert. Kein isolierter NULL-ID-Preflightzweig, Consumer-APIausführung oder neuer Default-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/TLS-/Release-Nachweis.

Nach PR348, 2026-10-20: Der neue ausdrückliche Zwei-Wellen-Auftrag umfasst
falsche Markerwerte und danach CLR-Ausführungskontexte. Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils im ersten marker-values-Versuch local/central PASS. 25 einzelne falsche Markerwerte:20 Objektmarker an fünf Slots, drei Assemblymarker und zwei Datenbankmarker; je Deploy/Uninstall SQL55324/state2/4/5,50 Abweisungen je Modus und100 je Ziel. Typisierte Werte mit exakter Bytelänge/Wertbytes vor Mutation und Restaurierung geprüft, erfasster Mutationszustand und neutrale Sitzung erhalten, exakte Baseline restauriert. Geschlossene Falldeskriptoren und ausschließlich inverse zulässige Übergänge; keine freien SQL-Wertausdrücke. Separate Linux-Regression bisheriger ownership-markers-Familie local/central40 Abweisungen PASS. Je erfolgreichem Lauf Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. 367Offlinekontrollen,140SQL150-Änderungs-/Restaurierungsbatches beider Familien und AST/Static PASS. Produkt-/Deployment-/CLR-/gemeinsame Snapshothelper unverändert; keine neue Default-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierte TLS-/Releaseabnahme.

Nach PR349, 2026-10-21: Die ausgewählte zweite Welle prüft CLR-Ausführungskontexte. Ausführung am2026-10-20/21: Linux2019/latest CL150 und Windows2025/base mit erlaubtem bereitem CU-Äquivalent CL170 jeweils erster binding-execution-Versuch local/central PASS. Drei interne CLR-Funktionen einzeln mit EXECUTE AS OWNER als Fixturemetadatum; konkreter execute_as_principal_id=-2-Witness, je Deploy/Uninstall SQL55324/state5, sechs Abweisungen pro Modus und zwölf je Ziel. Witness unmittelbar vor/nach jeder Operation und vor Restaurierung, gleiche Objekt-/Erstellungsidentität, typisierte Ownership und CLR-Bindung, erfasster Zustand erhalten und Caller-Baseline exakt restauriert. Funktionen im geänderten Kontext nicht ausgeführt. Separate Regressionen bisheriger Metadatenfamilie Linux32 und Defaultfamilie Windows20 Abweisungen local/central PASS. Alle vier Läufe Clean/Repeat, Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; frischer unabhängiger Audit je zwei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Inputs unverändert. 384Offlinekontrollen einschließlich Witnessdrift vor zweiter Operation,64SQL150-Batches aller drei Familien und AST/Static PASS. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen unverändert; keine Rechtevergabe oder Objektowneränderung, keine neue Default-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/authentifizierte TLS-/Releaseabnahme.

Nach PR350, 2026-10-21: Der erneute ausdrückliche Benutzerauftrag verlangt
die nächste begrenzte Welle samt vollständigem Abschluss und anschließend
den direkten autonomen Start der Folgewelle. Ausgewählt sind finale
CLR-Defaults auf Linux, danach finale benannte SameDB-Verbraucher auf Linux.
Der unveränderte `binding-defaults`-Adapter bestand auf Linux2019/latest CL150
im ersten Versuch local/central: fünf Defaults, je Deploy/Uninstall
SQL55324/state7, 20 Abweisungen. Finale Typ-/Wertbytes-/Textlängen-/NULL-Witnesses
unmittelbar vor/nach Operation und vor Restore, unveränderte Identität und
erfasster Zustand sowie exakte Baseline bestanden. Clean/Repeat, Uninstall/Repeat,
Exit0, vollständige Kanäle/leeres Stderr und frischer unabhängiger Audit zwei
eigene DBs/ein eigener Trusthash abwesend PASS; Konfiguration und Runtimeinputs
unverändert. Vorhandenes Releasepaket erneut an alle manifestierten Quellen
und exakten Binarybytes gebunden, kein neuer lokaler Build-/Frameworknachweis.
Historische engere/fehlgeschlagene Läufe bleiben erhalten; `partially validated`,
`unreleased`. Keine Produkt-/Test-/Deployment-/CLR-Quelländerung oder neue
Default-Gesamtadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/TLS-Abnahme.

Nach PR351, 2026-10-21: Nach grünem Review, exakter Head-/tatsächlicher
Main-Push-CI und eigenem Branchcleanup wurde die freigegebene Folgewelle
direkt begonnen. Der unveränderte `named-consumers`-Adapter bestand auf
Linux2019/latest CL150 im ersten Versuch local/central mit finalem
Assertionstand: fünf benannte SameDB-Verbraucher, je Deploy/Uninstall
SQL55325/state3, 20 Abweisungen. Dependencyfingerprint unmittelbar vor/nach
jeder Operation und vor geschütztem Fixture-Drop, exakte Zielnamen,
zulässige lokale ID-/Namensbindung, typisierte Laufmarker und Objekt-/
Erstellungsidentitäten sowie Baseline erhalten. Clean/Repeat,
Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr und frischer
unabhängiger Audit zwei eigene DBs/ein eigener Trusthash abwesend PASS;
Konfiguration und eingefrorene Runtimeinputs unverändert. Vorhandenes
Releasepaket erneut an alle manifestierten Quellen/exakten Binarybytes
gebunden. Frühere engere/fehlgeschlagene Läufe bleiben erhalten;
`partially validated`, `unreleased`. Keine Produkt-/Test-/Deployment-/CLR-/
Workflowänderung, isolierte NULL-ID-Preflightabnahme, Consumerausführung
oder neue Default-Gesamtadapter-/API-/Client-/Vollmatrix-/Minimalrechte-/
Heap-/authentifizierte TLS-/Releaseabnahme; kein neuer lokaler Build-/Frameworklauf.

Fortlaufender Benutzerauftrag nach PR352, 2026-10-21: Der Benutzer hat den
30-Minuten-Heartbeat erneut aktiviert und ausdrücklich den autonomen Start
jeweils weiterer begrenzter CSV-Memory-Wellen beauftragt. Die nächste
Fremdslotwelle prüft Inline-/Multi-Statement-TVFs auf allen fünf reservierten
Namen. Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils erster Versuch local/central PASS: je 40 Abweisungen
SQL55324/state3, erfasste Metadaten und synthetische Ergebniswerte einschließlich
Padding unverändert, geschützte Fixtureentfernung und exakte Baseline.
Gemeinsamer Helper prüft den Ergebniswitness jetzt unmittelbar vor jeder
Operation; separate Linux-View-/Prozedur- und Synonym-/Skalarfunktionsregressionen
mit je 40 Abweisungen bestanden. Alle vier Läufe Exit0/vollständige Kanäle/
leeres Stderr, je frischer unabhängiger Audit zwei eigene DBs/ein eigener
Trusthash abwesend; Konfiguration und Runtimeinputs unverändert.
423 Offlinekontrollen, 217 expandierte SQL150-Batches sowie AST/Static PASS.
Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert;
keine neue API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/TLS-/Releaseabnahme.
`partially validated`, `unreleased`; historische Fehlläufe bleiben erhalten.
Die nachfolgende ausgewählte Welle betrifft falsche Schemamarkerwerte.

Nach PR353, 2026-10-21: Die direkt gestartete Schemamarkerwelle bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils im ersten Versuch local/central. Vier einzelne
Änderungen am eigenen Schema: Managed-int 1→0 sowie Kategorie file→json,
FILE und file mit abschließendem Leerzeichen; je Deploy/Uninstall
SQL55324/state1, 16 Abweisungen je Ziel. Geschlossene Mutationdeskriptoren,
exakte Basistyp-/MaxLength-/DATALENGTH-/Wertbytes vor Mutation/Restaurierung,
erfasster Zustand und neutrale Sitzung erhalten, Baseline exakt restauriert.
Separate Linuxregression bisheriger Objekt-/Assembly-/Datenbankmarkerwerte
local/central mit 100 Abweisungen PASS. Alle drei Läufe Clean/Repeat,
Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr und frischer
unabhängiger Audit je zwei eigene DBs/ein eigener Trusthash abwesend;
Konfiguration/Runtimeinputs unverändert. 451 Offlinekontrollen, 156
expandierte SQL150-Übergänge und AST/Static PASS. Produkt-/Deployment-/CLR-/
Snapshotquellen und Workflow unverändert; keine Rechte-/Owneränderung oder
neue Gesamt-/Vollmatrix-/Minimalrechte-/Heap-/TLS-/Releaseabnahme.
`partially validated`, `unreleased`. Anschließend sind skalare Rückgabelängen
und die noch offene Parser-RowKind-Länge als nächste begrenzte Welle ausgewählt.

Nach PR354, 2026-10-21: Die direkt gestartete Rückgabelängenwelle bestand auf
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils im ersten Versuch local/central. Zwei einzelne interne
CLR-Metadatenänderungen: QuoteCell-Rückgabe nvarchar(max)→nvarchar(4000) und
Parser-RowKind nvarchar(6)→nvarchar(5), je Deploy/Uninstall SQL55324/state7,
acht Abweisungen je Ziel. Konkrete Rückgabe-/Spaltenlängenwitnesses unmittelbar
vor/nach Operation und vor Restore, gleiche Identität/CLR-Bindung/Ownership
und erfasster Zustand erhalten, Baseline exakt restauriert. Keine fachliche
Ausführung unter abweichender Länge. Separate Linux-Bindingregression mit 32
Abweisungen local/central PASS. Alle drei Läufe Clean/Repeat, Uninstall/Repeat,
Exit0/vollständige Kanäle/leeres Stderr und frischer unabhängiger Audit je zwei
eigene DBs/ein eigener Trusthash abwesend; Konfiguration/Inputs unverändert.
487 Offlinekontrollen, 72 expandierte SQL150-Batches aller vier Bindingfamilien
sowie AST/Static PASS. Produkt-/Deployment-/CLR-/Snapshotquellen und Workflow
unverändert; keine neue API-/Client-/Vollmatrix-/Minimalrechte-/Heap-/TLS-/
Releaseabnahme, kein neuer lokaler Build-/Frameworklauf. Weiterhin
`partially validated`, `unreleased`.

Testwartung 2026-10-09 – Quellenstand: Der bestehende CSV-Frameworkrunner ersetzt
das ganze DLL-Bytearray durch einen festen 64-KiB-Kopierpuffer mit `Int64`-
Längenbindung, exakter EOF-Prüfung und unveränderten Kopie-/Endpins. Fokussierte
Kopierprüfung: sechs synthetische Fälle **PASS**; exakte neue Head-CI
**NOT_EXECUTED**. Keine gemessene OOM-
Ursache, neue DLLcap, API-, Produkt-, Workflow- oder Statusänderung; historische
PR169-/Native-/Marker-Nachweise bleiben unverändert, keine Heap-/Releaseclosure.

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

Fortlaufende begrenzte CSV-Welle nach vollständig abgeschlossenem PR355,
2026-10-21: `shape-ceilings` ergänzt acht gezählte tatsächliche Zeilen-/
Spalten-Grenz-/+1-Fälle je Modus. Native Grenzabnahme offen: vier Versuche
FAILED_CLEANED, Linux erster Gesamtbatchtimeout60; danach Linux2019/latest
CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent lokale
Parserphase100000 bestanden, anschließender Writer100000 Timeout120,
Windows zweiter Versuch auch bei300. Je frischer Audit eine eigene DB/ein
eigener Trusthash abwesend, Konfiguration/Rechte/Eingaben unverändert.
Keine konkrete Engpassursache oder öffentliche Laufzeitverletzung belegt;
Produktquellen unverändert. Separate finale Linux-Defaultregression im ersten
Versuch local/central mit drei SQLfixtures/Client/Consumer/29 Lifecyclefällen
und frischem Audit drei eigene DBs/ein eigener Trusthash abwesend PASS.
509 Offlinekontrollen, acht SQL150-Phasen und AST/Static PASS. Unabhängiger
Erstreview ohne semantische Codefindings; native Grenzabnahme bleibt offen.
Keine neue Funktion, Rechte-/Infrastruktur-/Releasefreigabe, keine Heap- oder
Ceilingqualifikation; `partially validated`, `unreleased`. Fortlaufender
Benutzerauftrag und gemeinsames endliches Ledger bleiben gültig, kein Reset.

Ausdrücklich freigegebene Erweiterung derselben PR356-Welle 2026-10-21:
drei separate Windows-Diagnoseaufrufe frisch bereinigt; die ersten beiden
Beobachterzeitlimits bleiben unzureichende Diagnose, der dritte ordnet den
Aufwand dem kanonischen Fragment-/Maßabgleich zu. Keine konkrete Plan-/
Komplexitätsbehauptung. Unbenannte Clustered-Primärschlüssel auf bereits vorher
geprüften eindeutigen Zellordinals beider interner Maß-/Fragmenttabellen,
öffentlicher Vertrag/CLR/Deployment/Snapshot/Workflow unverändert. Neu gepackte
SQLquellen mit gleichen CLR-Bytes. Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent korrigierter Kandidat local/central im kombinierten Scope
shape-ceilings-and-default PASS:16 Formgrenzfälle, darunter acht SQL55303/state1,
alle drei Defaultfixtures/Client/Consumer/29 Lifecyclefälle und frischer Audit
drei eigene DBs/ein eigener Trusthash abwesend, Konfiguration/Rechte/Inputs
unverändert. 535 Offlinekontrollen und SQL150/AST/Static PASS. Dieselben vier
Zusatzaufrufe vollständig gezählt, kein Reset; abschließender Linuxkandidat
noch offen. Frühere vier Grenz-FAILs bleiben erhalten, kein Gesamt-PASS,
keine Heap-/Zell-/Textvollgrenze oder Veröffentlichung.

Nach zusätzlicher ausdrücklicher Freigabe abschließender gleicher korrigierter
Kandidat auf Linux2019/latest CL150 im kombinierten Scope local/central PASS:
16 Formgrenzfälle einschließlich acht SQL55303/state1-Abweisungen, alle drei
Defaultfixtures/Client/Consumer/29 Lifecyclefälle/CleanRepeat/UninstallRepeat.
Exit0/vollständige Kanäle/leeres Stderr, frischer Audit drei eigene DBs/ein
eigener Trusthash abwesend, Konfiguration/Rechte/Runtimeinputs unverändert.
Damit beide ausgewählten korrigierten Ziele geprüft; frühere FAILED-/
Diagnoseaufrufe bleiben getrennt. Unabhängiger Abschlussreview ohne semantische
Findings; generierter Katalogfingerprint als einziges Finding durch exakten
Generatornachtrag/Validator geschlossen. Keine neue Funktion, Heap-/Zell-/
Textvollgrenze, vollständige Matrix, Minimalrechte, authentifiziertes TLS oder
Veröffentlichung. Gemeinsames Ledger ohne Reset fortgesetzt.

2026-10-21: Die ausdrücklich autorisierte fortlaufende CSV-Memory-Qualifikation
wurde nach Abschluss der Formgrenzen mit `cell-ceilings` tatsächlich fortgesetzt.
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils erster Versuch local/central PASS: je16 Fälle, genau1000000
Zellen sowie gültiges Rechteck mit1000001 Zellen, Parser/Writer ohne/mit Header;
je acht erwartete SQL55303/state1-Abweisungen, vollständige Raster-/Wert-/
Textbytes und Quell-/Zielerhalt. Je frischer Audit zwei eigene DBs/ein eigener
Trusthash abwesend, Konfiguration/Rechte/Inputs unverändert. 559 Offlinekontrollen,
acht SQL150-Phasen/AST/Static bestanden. Produkt/CLR/Deployment/Snapshots/Workflow
unverändert; keine neue Funktion, Textvollgrenze, Default-/Client-/Heap-/
Minimalrechte-/Gesamtmatrix-/authentifizierte TLS- oder Releaseabnahme.
Gemeinsamer endlicher Kampagnenscope ohne Budgetreset fortgesetzt.

2026-10-21: Nach vollständig abgeschlossenem PR357 wurde die nächste begrenzte
Welle `text-ceilings` tatsächlich begonnen. Acht synthetische Phasen prüfen
Parserinput/Writerausgabe an16MiB und kleinstem tatsächlichem Darüber+2 UTF16-
Bytes, unquotiert/quotiert einschließlich LF/Quotes; Writerquellwerte bleiben
strikt unter ihrer eigenen Decke. Vollständige Byte-/Metadaten-/Quell-/Zielorakel
und typisierter Abschluss;591 Offlinekontrollen/acht SQL150-Phasen/AST/Static PASS.
Unabhängiger Quell-/Orakelreview ohne Findings; anschließend gleicher Kandidat
auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel,
darunter acht SQL55303/state1-Abweisungen. Je frischer Audit zwei eigene DBs/ein
eigener Trusthash abwesend, Konfiguration/Rechte/Inputs unverändert; Clean/Repeat
und Uninstall/Repeat. Keine Funktionserweiterung oder Budgetreset.
Keine unabhängige MaxValueBytes-Vollgrenze, neue Default-/Client-/
Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS- oder Releaseabnahme.

2026-10-21: Nach vollständigem Abschluss von PR358 und ausdrücklicher Erweiterung
des gemeinsamen endlichen Rahmens wurde `quote-expansion` tatsächlich begonnen.
Parser/Writer genau16MiB und kleinstes tatsächliches Darüber+2 UTF16-Bytes,
je eine/zwei quotehaltige Zellen: vollständige unabhängig konstruierte Quote-/
Textbytes einschließlich Separator/LF, globale Summe bei einzeln kleineren
Fragmenten, Writerwertcharge unter eigener Decke und Quell-/Zielerhalt.
630 Offlinekontrollen/acht SQL150-Phasen/AST/Static bestanden. Unabhängiger
Quell-/Orakelreview ohne Findings; gleicher Kandidat auf Linux2019/latest CL150
und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster
Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1,
Clean/Repeat und Uninstall/Repeat; je frischer Audit zwei eigene DBs/ein eigener
Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert.
Keine Funktionserweiterung oder Budgetreset;
Produkt/CLR/Deployment/Snapshots/Workflow unverändert, keine neue Default-/
Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'crlf-ceilings' fortgesetzt.
Parserinput/Writerausgabe an exakt16777216 UTF16-Bytes und kleinstem tatsächlichem Darüber16777218 Bytes, unquotierter und wegen Separator quotierter Record mit CRLF. Beide Recordabschlusszeichen und Quotehüllen zählen vollständig; die globale Writerwertcharge bleibt strikt unter16MiB, übrige Budgets nicht bindend.
669 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'null-token-ceilings' fortgesetzt.
Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes mit128-Zeichen-NullToken. Zwei Spalten prüfen die SQL-NULL-Expansion; drei Spalten unterscheiden quotiertes Tokenliteral, unquotiertes SQL-NULL und großen Textwert. Tokenbytes, Quotehüllen, Separatoren und LF zählen vollständig, globale Writerwertcharge strikt unter16MiB; übrige Budgets nicht bindend.
708 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'header-text-ceilings' fortgesetzt.
Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes mit vollständigem Header und einem DATArecord. Unquotierter128-Zeichen-Header mit LF sowie separatorhaltiger quotierter Header und DATAwert mit CRLF; Headerwerte, Quotehüllen und sämtliche Recordabschlüsse zählen. Globale Writerwertcharge aus HEADER und DATA strikt unter16MiB, übrige Budgets nicht bindend; vollständige HEADER=0/DATA=1-Wert- und Outputmetadatenorakel.
747 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'unicode-text-ceilings' fortgesetzt.
Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes:4194303 gültige Surrogatpaare mit CRLF sowie separatorbedingt quotierter BMP-Text mit CRLF. Synthetische Codeeinheiten werden aus festen UTF16-Binärliteralen aufgebaut und vollständig bytegenau verglichen. Kein UTF8-/Unicode-Scalar-Zähler; Quotehüllen/CRLF vollständig mitgezählt, globale Writerwertcharge auch beim Übergrenzfall strikt unter16MiB.
786 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'control-text-ceilings' fortgesetzt.
Parserinput/Writerausgabe genau16777216 UTF16-Bytes und kleinstes tatsächliches Darüber16777218 Bytes: feste synthetische UTF16-Einheiten aus NUL, getrenntem High-/Low-Surrogat, ASCII und BOM. Zweite Familie enthält führenden BOM und separatorbedingt quotierte Werte mit CRLF. Vollständige Bytevergleiche prüfen den Erhalt sämtlicher Codeeinheiten einschließlich führendem BOM als gewöhnlichem Text; Quotehüllen/CRLF vollständig mitgezählt, globale Writerwertcharge auch beim Übergrenzfall strikt unter16MiB.
825 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Der unabhängige Erstreview fand eine fehlende Abdeckung des BOM an Inputposition0. Die erste Familie wurde vor nativen Läufen korrigiert und gezielt nachgeprüft; abschließend keine offenen Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'keepdata-ceilings' fortgesetzt.
Passende vorbefüllte caller-lokale Parser-/Writerziele mit KeepData=1 und KeepData=0. Parserinput und Writerausgabe je genau16777216 UTF16-Bytes; +2 Bytes werden ausschließlich mit SQL55303/state1 abgewiesen. Erfolgreiches Append erhält synthetische Altzeilen, Replace entfernt diese; fehlgeschlagene Aufrufe erhalten die vollständigen bisherigen Zielwerte. Separat gesetzte Writerquellen bleiben vollständig bytegenau erhalten und ihre Wertcharge strikt unter16MiB. Ziel-/Quellidentität, Spaltenzahlen und beide Caller-Primärschlüssel bleiben erhalten; keine Gesamt-Heapgrenze abgeleitet.
864 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich acht SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach Evidenzdokumentation nachgepflegt und ausschließlich eine überzählige EOF-Leerzeile der Fixture entfernt; SQL-Inhalt und Ausführung unverändert.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'budget-parameter-preservation' fortgesetzt.
Acht ausgewählte feste Budgetobergrenzen jeweils um1 überschritten: Parser MaxInputBytes, MaxRows, MaxColumns, MaxCells; Writer MaxValueBytes, MaxOutputBytes, MaxRows, MaxCells. Alle übrigen Argumente gültig, KeepData=0. Vorbefüllte passende Parser-/Writerziele enthalten je genau16777216 synthetische UTF16-Bytes; die getrennt gesetzte Writerquelle enthält16777212 Bytes und wäre mit CRLF regulär ausgabefähig. Vor und nach jeder SQL55303/state1-Abweisung vollständige bytegenaue Ziel-/Quellorakel samt Zeilenzahl und Metadaten; Calleridentitäten, Spaltenzahlen, drei Primärschlüssel und neutraler Transaktionszustand erhalten. Ergänzt vorhandene kleine NULL/0/Obergrenzenprüfungen; keine neue Funktion oder vollständige Budgetparametermatrix behauptet.
903 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Erstreview ohne Befunde. Der erste Linuxlauf scheiterte anschließend im zusammengesetzten Fixturewitness mit SQL55396/state3 und wurde vollständig bereinigt. Danach Katalog- und Neutralitätsprüfung ohne Verlust von Bedingungen getrennt und gezielt nachgeprüft; keine offenen Source-/Orakelbefunde. Die ursprüngliche Teilursache bleibt unbelegt; der korrigierte Kandidat besteht beide Ziele. Alle Fehlläufe/Folgeaufträge zählen weiter. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 im zweiten Versuch und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent im ersten Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'select-output-ceilings' fortgesetzt.
Bestehende öffentliche Parser-/Writeraufrufe mit ResultTable=NULL liefern direkt über System.Data.SqlClient. Unquotierter ASCII-Text mit CRLF und separatorbedingt quotierter ASCII-Text: Input/Output genau16777216 UTF16-Bytes sowie16777218 Bytes. Client prüft genau ein Resultset je Erfolg, Feldnamen/Reihenfolge, SQL-/CLR-Typen, vollständige Strings ordinal und numerische Typen/Werte. Vier Übergrenzfälle je Modus verlangen SQL55303/state1 ohne vorherige Resultsetmetadaten oder Zeilen. Writerquellen separat gesetzt, vollständiger Quellerhalt und Wertcharge strikt unter16MiB; kein INSERT EXEC. Acht bestätigte Readerphasen werden erst danach als typisierter Abschluss gezählt.
983 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Erstreview mit zwei Adapterbefunden zur Helper-Pinbindung und Command-Freigabe. Beide vor nativen Läufen korrigiert, mit synthetischen Drift-/Timeout-/Disposefällen geprüft und gezielt unabhängig nachgeprüft; keine offenen Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur System.Data.SqlClient im bestehenden PowerShell-Labadapter und die expliziten synthetischen Fälle: keine SMO-/ODBC-/JDBC-/sonstige Clientmatrix, neue Default-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme oder unabhängig erfolgreiche MaxValueBytes-Vollgrenze. Status weiterhin partially validated, unreleased.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'select-unicode-null' fortgesetzt.
Direkte öffentliche SELECT-Ausgaben ohne ResultTable über System.Data.SqlClient. Erste Familie:4194303 gültige UTF16-Surrogatpaare mit CRLF. Zweite Familie: unquotierter NullToken als SQL-NULL, quotierter identischer Token als literaler Text und großer BMP-Wert in drei Spalten. Vollständiger Input/Output genau16777216 Bytes, kleinstes Darüber16777218 Bytes. Client prüft vollständige ordinale Strings, DBNull getrennt vom literalen NULL-Text, Zeilen-/Spaltenreihenfolge, Feldnamen und SQL-/CLR-Typen; Writerwerte separat gesetzt und globale Wertcharge unter16MiB. Vier Übergrenzfälle je Modus ausschließlich SQL55303/state1 ohne vorherige Resultsetmetadaten oder Zeilen; vollständiger Quellerhalt. Keine Aussage über ungepaarte Surrogate oder andere Clients.
1036 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur System.Data.SqlClient im bestehenden PowerShell-Labadapter und die expliziten synthetischen Fälle: keine SMO-/ODBC-/JDBC-/sonstige Clientmatrix, neue Default-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme oder unabhängig erfolgreiche MaxValueBytes-Vollgrenze. Status weiterhin partially validated, unreleased.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'caller-transaction-preservation' fortgesetzt.
Bestehende öffentliche Parser-/Writeraufrufe in einer committable Callertransaktion mit XACT_ABORT OFF. Vier Erfolge genau an16777216 UTF16-Bytes und vier SQL55303/state1-Abweisungen bei16777218 Bytes je Modus. Caller-Sentinel, @@TRANCOUNT und XACT_STATE werden vor und nach Aufruf sowie nach eigenem COMMIT oder ROLLBACK getrennt geprüft. Vollständige Parserziele/Writeroutputs und unabhängig gesetzte Writerquellen werden bytegenau verglichen; Calleridentität und Schlüssel bleiben erhalten. Ursprüngliches XACT_ABORT wird wiederhergestellt. Keine Abnahme von doomed Transaktionen oder einer vollständigen SET-Optionsmatrix. Nach den nativen PASS wurde genau eine ueberzaehlige EOF-Leerzeile der neuen Fixture entfernt; alle vorherigen SQLbytes sind gegen den unabhaengigen Reviewstand und beide nativen Eingabepins exakt identisch belegt.
1075 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-21: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'schema-target-preservation' fortgesetzt.
Acht belegte synthetische Caller-ResultTables mit je einem vollständigen16777216-Byte-Wert: für Parser und Writer jeweils genau eine Abweichung in Spaltenname, Integerbreite, NULLbarkeit oder Collation. Gültiger Parserinput beziehungsweise unabhängig gesetzte Writerquelle mit vollständigem Output an16777216 Bytes. KeepData=1 muss ausschließlich SQL51025/state1 liefern. Vollständige Zielwerte und Writerquelle bleiben bytegenau erhalten; Callerobjektidentität sowie bidirektional verglichene Spalten-, Index- und Indexspaltensnapshots bleiben gleich. Getrennte Transaktionsneutralität und typisierter Abschluss. Kein Schemaumbau und keine neue Funktion.
1126 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Initialer unabhängiger Review fand die unpassende generische Plus-zwei-Abschlussmeldung. Vor nativen Läufen korrigiert und zwölf Kontrollen des tatsächlichen Summary-AST ergänzt; gezielter unabhängiger Folgeauftrag am korrigierten festen Kandidaten ohne offene Befunde. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL51025/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'late-parser-syntax' fortgesetzt.
Vier späte Quote-Syntaxfehler im letzten Record bei exakt16777216 UTF16-Inputbytes: offenes Quote am EOF, Text nach geschlossenem Quote, Quote im unquotierten Feld und Text nach Quote hinter CRLF. Jeweils KeepData=0 und1, insgesamt acht Fälle je Modus. Ausschließlich SQL55301/state1; vorheriger vollständiger16MiB-Callerwert, Objektidentität und bidirektional verglichene Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Transaktionsneutralität separat geprüft, keine partielle Zielmutation.
1166 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55301/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'late-parser-rectangular' fortgesetzt.
Vier syntaktisch gültige Inputs mit abweichender Spaltenzahl erst im letzten Record bei exakt16777216 UTF16-Inputbytes: zusätzliche beziehungsweise fehlende Schluss-Spalte nach LF oder CRLF. Jeweils KeepData=0 und1, insgesamt acht Fälle je Modus. Ausschließlich SQL55302/state1; vorheriger vollständiger16MiB-Callerwert, Objektidentität und bidirektional verglichene Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Transaktionsneutralität separat geprüft, keine partielle Zielmutation.
1206 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55302/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'writer-cell-preservation' fortgesetzt.
Acht unabhängig gesetzte ungültige Writer-Zellformen: falscher RowKind, RowOrdinal0/negativ, ColumnOrdinal0/negativ, doppelter Zellschlüssel, Lücke in Zeilenordinals und Lücke in Spaltenordinals. Vier Fälle mit KeepData=0 und vier mit1. Quellencharge jeweils unter16MiB, vorheriger vollständiger Writeroutput genau16777216 UTF16-Bytes. Ausschließlich SQL55306/state1; alle Quellzeilen mit vollständigen Werten und Multiplizität sowie alter Output bleiben erhalten. Quellen-/Zielidentität und bidirektionale Zielspalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue Bytegrenzabnahme.
1246 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55306/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'target-constraint-preservation' fortgesetzt.
Fehlschlagende CHECK-Zielinserts der bestehenden Parser-/Writerprozeduren bei vollständigem16MiB-Parserinput beziehungsweise vollständigem16MiB-Writeroutput. Je API KeepData=0/1 und eigene beziehungsweise committable Callertransaktion mit XACT_ABORT OFF: acht Fälle je Modus, ausschließlich ursprünglicher Enginefehler SQL547 ohne Behauptung eines festen ERROR_STATE. Vollständiger16MiB-Altzielwert und unabhängige Writerquelle bleiben erhalten; Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Caller-Sentinel und eigene Commit-/Rollbackentscheidung werden geprüft, ursprüngliches XACT_ABORT wiederhergestellt.
1286 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL547-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'null-representation-preservation' fortgesetzt.
SQL-NULL in DATA ohne NullToken und SQL-NULL im HEADER trotz aktiviertem NullToken, jeweils in ein- und zweispaltigen beziehungsweise ein- und zweizeiligen gültigen Zellrastern. Vier Formen jeweils mit KeepData=0/1, acht Fälle je Modus. Ausschließlich SQL55307/state1; vollständiger16MiB-Altoutput und alle unabhängig gesetzten Quellwerte einschließlich tatsächlicher SQL-NULLs bleiben erhalten. Quellencharge unter16MiB, Quell-/Zielidentitäten und bidirektionale Zielspalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue Bytegrenz- oder allgemeine Clientabnahme.
1326 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55307/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'source-metadata-preservation' fortgesetzt.
Acht unabhängig gesetzte nicht unterstützte Writer-Quellmetadaten: fünfte Spalte, umbenannte Value-Spalte, RowKind als nvarchar beziehungsweise varchar(7), RowOrdinal als int, ColumnOrdinal als bigint, Value als nvarchar(4000) beziehungsweise varchar(max). Vier KeepData=0- und vier KeepData=1-Fälle. Ausschließlich SQL55305/state1. Vollständiger16MiB-Altoutput und alle Quellwerte werden in ihren tatsächlichen Datentypen bytegenau erhalten; für nvarchar(4000) bewusst4000 Zeichen, andere Value-Fixtures8388580 ASCII-Zeichen. Beide Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots von Quelle und Ziel unverändert. Keine einheitliche16MiB-Quellencharge oder neue Bytegrenzabnahme behauptet.
1366 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55305/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'parser-argument-preservation' fortgesetzt.
Vier bestehende Parser-Argumentfehler jeweils mit KeepData=0/1: Text=NULL, HasHeader=NULL, zweistelliger Separator und leerer NullToken. Acht ausschließlich SQL55300/state1-Abweisungen je Modus. Vorheriger synthetischer Zellwert genau16777216 UTF16-Bytes bleibt vollständig samt Zeilenzahl, Schlüsseln, Objektidentität und bidirektionalen Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots erhalten. Die drei Fälle mit vorhandenem Text verwenden unabhängig gesetzten16MiB-Input; der fehlende Text bleibt ausdrücklich NULL. Keine neue allgemeine Bytegrenzabnahme.
1406 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55300/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'writer-argument-preservation' fortgesetzt.
Vier bestehende Writer-Argumentfehler jeweils mit KeepData=0/1: HasHeader=NULL, LineEnding=NULL, kleingeschriebenes lf und zweistelliger Separator. Acht ausschließlich SQL55300/state1-Abweisungen je Modus. Unabhängig gesetzte gültige DATA-Quelle unter16MiB und vollständiger16MiB-Altoutput bleiben bytegenau erhalten. Beide Objektidentitäten und bidirektionale Quellen-/Zielspalten-, Index-, Indexspalten- und Checkconstraint-Snapshots bleiben unverändert. Keine neue Bytegrenzabnahme.
1446 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55300/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'writer-header-preservation' fortgesetzt.
Vier bestehende ungültige HEADER-Formen jeweils mit KeepData=0/1: HEADER bei HasHeader=0, fehlender HEADER bei HasHeader=1, falscher HEADER-RowOrdinal und HEADER-Spaltenlücke. Acht ausschließlich SQL55306/state1-Abweisungen je Modus. Alle unabhängig gesetzten Quellzeilen einschließlich vollständigem großem Wert unter16MiB sowie vorheriger16MiB-Altoutput bleiben erhalten. Beide Objektidentitäten und bidirektionale Quellen-/Zielspalten-, Index-, Indexspalten- und Checkconstraint-Snapshots unverändert. Keine neue Bytegrenzabnahme.
1486 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55306/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'empty-result-preservation' fortgesetzt.
Acht erfolgreiche Leerresultatfälle je Modus: Parser mit leerem Text beziehungsweise quotierter leerer Zelle sowie Writer mit leerer Quelle beziehungsweise einer nicht-NULL-leeren DATA-Zelle, jeweils KeepData=0/1. Parser liefert keine Zeile beziehungsweise eine nicht-NULL-leere Zelle; Writer liefert immer eine Outputzeile mit leerem Text und Metadaten0/0 beziehungsweise CRLF mit Metadaten1/1. Vor jeder Operation wird ein vollständiger16MiB-Altwert unabhängig gesetzt. Replace entfernt diesen vertragsgemäß, Append erhält ihn vollständig samt ursprünglichen Metadaten. Beide Zielschemas und die Quelle behalten Objektidentität sowie bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots. Keine beabsichtigte SQL-Abweisung oder neue Bytegrenzabnahme.
1526 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich16 positiver Leerresultat-/Replace-/Appendfälle; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'reserved-temp-namespace-preservation' fortgesetzt.
Vier einzeln belegte private Writerslots Input, Measure, Fragments und Result, jeweils KeepData=0/1. Acht ausschließlich SQL55304/state1-Abweisungen je Modus vor der Workbatch. Die synthetische Callerprobe besitzt absichtlich fremdes Schema und einen unabhängig gesetzten16MiB-Wert; dieser sowie gültige DATA-Quelle unter16MiB und vollständiger16MiB-Altoutput bleiben bytegenau erhalten. Alle drei Objektidentitäten und bidirektionalen Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert. Jede eigene Probe wird vor dem nächsten Fall entfernt. Kein vollständiger Namespace-, Parser- oder neuer Bytegrenzumfang.
1566 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'writer-local-source-name-preservation' fortgesetzt.
Vier bestehende ungültige oder fehlende Writerquellen jeweils KeepData=0/1: NULL, globaler Tempname, Name ohne lokalen Praefix und fehlende lokale Quelle. Acht ausschließlich SQL55304/state1-Abweisungen je Modus. Vollständiger16MiB-Altoutput und eine unabhängig vorhandene gültige synthetische Callerquelle unter16MiB bleiben bytegenau erhalten, einschließlich Objektidentitäten und bidirektionaler Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots. Die ungültig benannten Quellen werden weder angelegt noch als gültige Eingaben qualifiziert; erwartete Abwesenheit bleibt erhalten. Keine neue Bytegrenzabnahme.
1606 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'reserved-temp-prefix-preservation' fortgesetzt.
Vier bestehende Präfixabweisungen jeweils KeepData=0/1: reserviertes Parserziel, reserviertes Writerziel, reservierte Writerquelle und Writerquelle mit gemischtem #TbX_-Präfix. Acht ausschließlich SQL55304/state1-Abweisungen je Modus. Der jeweilige16MiB-Altzielwert und die unabhängig gesetzte gültige synthetische Callerquelle unter16MiB bleiben bytegenau erhalten. Parseraufrufe erhalten separat gesetzten16MiB-Text. Beide Objektidentitäten und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben unverändert; eigener Fallaufbau und Cleanup vor dem nächsten Fall. Keine gesamte Namespace- oder neue Bytegrenzabnahme.
1646 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55304/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'header-only-preservation' fortgesetzt.
Acht erfolgreiche Fälle je Modus: Parser und Writer mit einem beziehungsweise zwei HEADER-Feldern ohne DATA, jeweils KeepData=0/1. Ein unabhängig gesetzter großer Headerwert bleibt vollständig erhalten, die Quellencharge liegt unter16MiB. Parser liefert nur HEADER-Zellen mit RowOrdinal0 und vollständigen Spaltenordinals; Writer liefert genau eine vollständige CRLF-Ausgabe mit DataRows0 und ColumnCount1 beziehungsweise2. Vor jeder Operation steht ein eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn samt alten Schlüsseln und Metadaten. Quelleninhalt und beide kanonischen Schemata bleiben unverändert. Keine neue Bytegrenzabnahme.
1686 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu HEADER ohne DATA mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'null-token-value-preservation' fortgesetzt.
Acht erfolgreiche Fälle je Modus: Parser und Writer mit aktivem Tokenwort „NULL“ beziehungsweise „NULL “ mit abschließendem Leerzeichen, jeweils KeepData=0/1. Unquoted Token wird SQL-NULL, quoted Token bleibt vollständiger Text; beim gepaddeten Token bleibt ungepaddetes NULL ebenfalls Text. Eine unabhängig gesetzte große zusätzliche DATA-Zelle ist vollständig enthalten, Quelle und Text bleiben unter16MiB. Writer liefert exakt kanonisches Quoting und CRLF sowie DataRows1 und die vollständige Breite3 beziehungsweise4. Vor jeder Operation eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig. Quelleninhalt, Identitäten und bidirektionale Katalogsnapshots bleiben erhalten. Keine neue Bytegrenzabnahme.
1726 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu NullToken-Text und SQL-NULL mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'trailing-empty-field-preservation' fortgesetzt.
Acht erfolgreiche Fälle je Modus: Parser mit leerem letztem Feld am EOF beziehungsweise vor CRLF und Writer mit einem beziehungsweise zwei abschließenden leeren Feldern, jeweils KeepData=0/1. Eine unabhängig gesetzte große erste DATA-Zelle bleibt vollständig enthalten, Quelle und Text liegen unter16MiB. Leere Felder bleiben ausdrücklich nicht-NULL-leer; EOF und finaler Recordabschluss erzeugen keinen zusätzlichen Record. Writer liefert exakt die abschließenden Separatoren und CRLF mit DataRows1 und ColumnCount2 beziehungsweise3. Vor jeder Operation eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig. Quelleninhalt, Identitäten und bidirektionale Katalogsnapshots bleiben erhalten. Keine neue Bytegrenzabnahme.
1766 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle zu Abschließende leere CSV-Felder mit korrektem Replace und Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'quoted-temp-name-preservation' fortgesetzt.
Acht erfolgreiche Fälle je Modus: Parserziele mit Punkt/Klammer beziehungsweise Leerzeichen/Klammer, Writerquelle mit Punkt/Klammer und Writerziel mit Leerzeichen/Klammer, jeweils KeepData=0/1. Direkte SQL-Bezeichner werden korrekt geklammert, APIargumente behalten ihren unveränderten Raw-Namen; Objekt-IDs werden über den qualifizierten geklammerten Namen aufgelöst. Unabhängige DATA-Quelle16777160Bytes und vollständiger CRLF-Input/Output16777164Bytes liegen unter16MiB. Je Fall eigener16MiB-Altzielwert: Replace entfernt, Append erhält ihn samt alten Schlüsseln und Metadaten vollständig. Quelle bleibt read-only; beide IDs und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots unverändert. Keine neue allgemeine Namens-, Alias- oder Bytegrenzqualifikation.
1806 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Fälle mit ungewöhnlichen Caller-Tempnamen und korrektem Replace/Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'source-target-alias-preservation' fortgesetzt.
Acht ausschließlich SQL55308/state1-Abweisungen je Modus: identische Quelle und ResultTable mit normalem beziehungsweise Punkt/Klammer-Namen, jeweils DATA/HasHeader0 oder HEADER/HasHeader1 und KeepData=0/1. Die einzelne physische kanonische Callertabelle enthält unabhängig gesetzte genau16777216UTF16-Bytes. Vollständige Zeile, Kind/Ordinals, Multiplizität, Objekt-ID und bidirektionale Spalten-/Index-/Indexspalten-/Checkconstraint-Snapshots bleiben erhalten. Identische Raw-Argumente lösen dasselbe tatsächliche Objekt auf. Abweisung vor Snapshot-/Outputcharge, Transaktionsbeginn oder Zielanpassung; keine erfolgreiche Writer-/Bytegrenz- oder andere Namensaliasqualifikation.
1846 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 SQL55308/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Keine unabhängig erfolgreiche MaxValueBytes-Vollgrenze, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'lower-value-budget-preservation' fortgesetzt.
Acht Writerfälle je Modus: eine beziehungsweise zwei DATA-Zellen mit globaler Wertcharge genau1048576 oder1048578UTF16-Bytes, jeweils KeepData=0/1 und MaxValueBytes1048576. Vier Erfolge und vier SQL55303/state1-Abweisungen je Modus. Bei zwei Zellen bleibt jede einzelne unter der Grenze; die Summe entscheidet. Die unabhängig gesetzte vollständige CRLF-Ausgabe bleibt unter dem separaten Defaultoutputbudget16MiB und kann den Wertguard nicht verdecken. Je Fall eigener16MiB-Altzielwert: Erfolg ersetzt beziehungsweise ergänzt ihn exakt, Abweisung erhält ihn vollständig. Alle Quellwerte, Multiplizitäten, Metadaten, Objekt-IDs und bidirektionalen Katalogsnapshots bleiben erhalten. Qualifiziert wird ausschließlich das abgesenkte1MiB-Wertbudget.
1886 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'lower-output-budget-preservation' fortgesetzt.
Acht Writerfälle je Modus: unquotierte Einzelle beziehungsweise quotierte Zweizellenform mit unabhängig gesetzter vollständiger CRLF-Ausgabe genau1048576 oder1048578UTF16-Bytes, jeweils KeepData=0/1 und MaxOutputBytes1048576. Vier Erfolge und vier SQL55303/state1-Abweisungen je Modus. Die Rohwertsumme bleibt jeweils unter1MiB und somit unter dem unveränderten Defaultwertbudget16MiB; auch die einzelnen quotierten Fragmente liegen unter1MiB. Der globale Outputguard entscheidet einschließlich Quoting, Separator und CRLF. Je Fall eigener16MiB-Altzielwert: Erfolg ersetzt beziehungsweise ergänzt ihn exakt, Abweisung erhält ihn vollständig. Alle Quellwerte, Multiplizitäten, Metadaten, Objekt-IDs und bidirektionalen Katalogsnapshots bleiben erhalten. Qualifiziert wird ausschließlich das abgesenkte1MiB-Outputbudget.
1926 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'header-row-budget-preservation' fortgesetzt.
Acht Fälle je Modus: Parser und Writer mit HEADER und einer beziehungsweise zwei DATA-Zeilen, jeweils HasHeader1, MaxRows1 und KeepData=0/1. Vier Erfolge mit einer DATA-Zeile und vier SQL55303/state1-Abweisungen mit zwei DATA-Zeilen je Modus. Der unabhängig gesetzte Header umfasst1048520UTF16-Bytes; alle anderen Budgets bleiben unter ihren Grenzen. HEADER wird nicht als DATA-Zeile gezählt. Erfolgreicher Parser liefert vollständige HEADER-/DATA-Zellen und Ordinals, erfolgreicher Writer exakte CRLF-Ausgabe mit DataRows1/ColumnCount1. Je Fall eigener16MiB-Altzielwert: Erfolg ersetzt beziehungsweise ergänzt ihn exakt, Abweisung erhält ihn vollständig. Alle Quellwerte, Multiplizitäten, Objekt-IDs und bidirektionalen Katalogsnapshots bleiben erhalten.
1966 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'alternate-separator-preservation' fortgesetzt.
Acht erfolgreiche Fälle je Modus: Parser und Writer mit Semikolon beziehungsweise Tab als Separator, jeweils KeepData=0/1. Die zweite DATA-Zelle enthält den gewählten Separator und bleibt als eine vollständig quotierte Zelle erhalten. Unabhängige Rohwertsumme16777106Bytes und vollständige CRLF-Ausgabe16777116Bytes liegen unter16MiB. Parser liefert exakt zwei DATA-Zellen, Writer kanonisches Quoting mit DataRows1/ColumnCount2. Je Fall eigener16MiB-Altzielwert: Replace entfernt ihn, Append erhält ihn vollständig mit alten Schlüsseln und Metadaten. Quelle, Multiplizitäten, beide Objekt-IDs und bidirektionale Katalogsnapshots bleiben unverändert. Keine beabsichtigte SQL-Abweisung und keine neue Bytegrenzabnahme.
2006 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 16 positiver Semikolon-/Tabfälle mit korrektem Replace/Append; keine beabsichtigte SQL-Abweisung. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'lower-input-budget-preservation' fortgesetzt.
Acht Parserfälle je Modus: unabhängig gesetzter vollständiger Input genau1048576 beziehungsweise1048578UTF16-Bytes, ohne beziehungsweise mit HEADER, jeweils MaxInputBytes1048576 und KeepData=0/1. Vier Return0-Erfolge und vier SQL55303/state1-Abweisungen je Modus. Die DATA-Zelle enthält Separator und Quote; Input enthält Quotehüllen, Quoteverdoppelung und CRLF sowie gegebenenfalls den Headerrecord. Die dekodierte Rohwertsumme bleibt auch bei Abweisung unter1MiB, damit ausschließlich das ganze Inputbudget entscheidet. Erfolgreiche Ergebnisse enthalten alle vollständigen HEADER-/DATA-Zellen und Ordinals. Je Fall eigener16MiB-Altzielwert: Erfolg ersetzt beziehungsweise ergänzt ihn exakt, Abweisung erhält ihn vollständig. Unabhängige Callerquelle, vollständige Bytewerte, Multiplizitäten, Objekt-IDs und bidirektionale Katalogsnapshots bleiben erhalten. Qualifiziert wird ausschließlich das abgesenkte1MiB-Inputbudget.
2046 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

2026-10-22: Nach vollständigem Abschluss der vorigen Welle tatsächlich mit 'header-cell-budget-preservation' fortgesetzt.
Acht Fälle je Modus: Parser und Writer mit HEADER plus einer beziehungsweise zwei DATA-Zeilen, jeweils HasHeader1, MaxCells2 und KeepData=0/1. Vier Return0-Erfolge bei insgesamt zwei Zellen und vier SQL55303/state1-Abweisungen bei insgesamt drei Zellen je Modus. HEADER zählt im globalen Zellbudget mit; die einspaltige Recordbreite und DATA-Zeilen bleiben unter ihren separaten Defaultgrenzen. Der unabhängig gesetzte Header umfasst1048520UTF16-Bytes; alle Bytebudgets bleiben unter ihren Grenzen. Erfolgreicher Parser liefert vollständige HEADER-/DATA-Zellen und Ordinals, erfolgreicher Writer exakte CRLF-Ausgabe mit DataRows1/ColumnCount1. Je Fall eigener16MiB-Altzielwert: Erfolg ersetzt beziehungsweise ergänzt ihn exakt, Abweisung erhält ihn vollständig. Alle Quellen, Multiplizitäten, Objekt-IDs und bidirektionalen Katalogsnapshots bleiben erhalten. Keine Default-Millionenzell-Vollgrenzabnahme.
2086 synthetische Offlinekontrollen, acht SQL150-Fixturephasen, AST/Static bestanden. Unabhängiger Quell-/Orakelreview vor den nativen Läufen ohne Findings. Identischer ausführbarer Kandidat auf Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem CU-Äquivalent jeweils erster Versuch local/central PASS:16 Fälle je Ziel einschließlich 8 SQL55303/state1-Abweisungen. Clean/Repeat und Uninstall/Repeat, Exit0/vollständige Kanäle/leeres Stderr; je frischer separater Audit zwei eigene DBs/ein eigener Trusteintrag abwesend, Konfiguration/Rechte/Inputs unverändert. Danach nur gekoppelte Manifest-/Evidenz-/Dokumentationsdateien nachgepflegt.
Keine Funktionserweiterung oder Budgetreset. Produkt-/Deployment-/CLR-/gemeinsame Snapshotquellen und Workflow unverändert; quellengebundenes Paket/exakte CLRbytes wiederverwendet, kein neuer lokaler Build-/Frameworklauf. Nur der ausdrücklich beschriebene Parameter-/Dialektumfang; keine unabhängig erfolgreiche Default-MaxValueBytes-Vollgrenze16MiB, neue Default-/Client-/Heap-/Minimalrechte-/Gesamtmatrix-/authentifizierte TLS-/Releaseabnahme. Status weiterhin 'partially validated', 'unreleased'.

### Queue-Worker 2 – autonome Umsetzung freigegeben 2026-10-04

Nach Besprechung von Zweck, Verträgen, Alternativen und Risiken beauftragte
der Benutzer ausdrücklich: „ok, machen wir es so, wie von dir vorgeschlagen;
starte autonome Verarbeitung wie besprochen“. Die Freigabe umfasst zentrale
SQL-Steuerung, getrennte Steuerungs-/Claim-APIs mit Versionsvergleich,
global und je Worker zur Laufzeit veränderbare Parallelität, konfigurierbare
Registrierungsintervalle mit Defaults 15/60 Sekunden sowie den kontrollierten
Übergang zwischen verwaltetem und bisherigem Betrieb. Intervalländerungen
gelten nur für neue Worker-Generationen. Keine automatische Deaktivierung.

Zusätzlich einzeln besprochen und bestätigt: Sofortstopp genau einer konkreten
Verarbeitung oder mehrerer/aller Worker. Persistenter Stop-/Hold-Auftrag muss
automatische Claims, Lease-Recovery und Retry vor dem Abbruch verhindern.
Erst nach nachgewiesenem Rollback/Ende darf der Slot freigegeben werden;
ungeklärte Ausgänge bleiben gesperrt. Bereits erfolgter atomarer Commit bleibt
erfolgreich. Ein gestoppter Auftrag bleibt erkennbar zurückgehalten bis zur
ausdrücklichen Wiederfreigabe; jeder geeignete Worker darf ihn dann übernehmen.
Korrektur im registrierten Handler, kein frei ausführbarer SQL-Text.
Ein einzelner Auftragsstopp lässt den Worker andere Arbeit ausführen;
mehrere/alle gestoppten Worker bleiben bis zur ausdrücklichen Reaktivierung
für neue Starts gesperrt. Historie bleibt erhalten.

Status: `implemented`, `partially validated`, `unreleased`. Der SQL-Vertrag mit
gezielten Negativfällen und sechs tatsächlichen Lifecycle-Abweisungen sowie
der echte Queue-Upgrade 2.0→2.1 bestanden am 2026-10-04 auf SQL Server 2019 Linux.
Die fokussierten Managedläufe mit Windows-Workerhost bestanden einschließlich
eigenem Cleanup am 2026-10-05 auf 2019 Linux und 2025 Windows/CU8. Zu diesem
Zeitpunkt blieb der Linux-Workerhost-Nachweis über exakte Head-CI offen. Der technische
[Worker-Control-Vertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
konkretisiert die Umsetzung einschließlich Bindung, Commit-/Rollbacknachweis
und unverändert gesperrter ungeklärter Ausgänge. Erst vorhandener externer Windows-/Linux-
Provider; SSIS/Agent/Broker bleiben spätere separat qualifizierte Provider.
Abbruchanforderung, tatsächliches Ende und Konsistenznachweis sind getrennt;
keine generische externe Rollback- oder Exactly-once-Zusage. Unabhängiger
Review, betroffene schema-validierte Lab-Tests, grüne exakte Head-CI, PR-Merge
nach origin/main und eigener Branch-/Worktree-Cleanup bleiben Pflicht.
Vorhandene Referenzen TC-2026-015/046; keine neue sequenzielle ID erfunden.

CI-Ergänzung 2026-10-06: Der begrenzte Linux-Workerhost-/SQL2019-Nachweis
bestand am exakten [PR197-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/197)
im [Worker-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37423892477)
mit Managed-Vertrag, echtem Queue2.0→2.1-Upgrade und separaten Windows-/Linux-
Faultverträgen. Der erste [main-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37425398209)
scheiterte im zeitabhängigen Controltimeout-Orakel; Cleanup bestand. Genau ein
Retry auf demselben Merge-Commit bestand alle Jobs. Der Erstfehler bleibt
fehlgeschlagen, seine Ursache unbekannt. Andere Host-/Zielkombinationen,
Minimalrechte, echter Committransportverlust und Release bleiben offen.

### Nächste Wellen – bestätigte Anforderungen und Entscheidungsvorbereitung 2026-10-04

Benutzerauftrag nach Merge/Cleanup: nächste Wellen besprechen und konkrete
Vorlagen ausarbeiten. Queue-Worker2 ist erster Schwerpunkt, CSV unabhängiger
zweiter Schwerpunkt; JSON Pointer, Safe Cast und JSON-Schema-Prüfung folgen.
Bestätigte Anforderungen und neue API-/Providerdetails stehen getrennt in der
[Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md).
Vorhandene Referenzen TC-2026-015/046 und RI-2026-109/041/076/048 werden
wiederverwendet. Status dieser Ausarbeitung: `proposed`; keine neue Runtime.

Einzeln bestätigt: externer Queueprovider jetzt, Agent/Broker später; gemeinsame
Steuerung, Registrierung, explizite Recovery, kontrollierter Neustart und bisherige
Handlergrenzen. Die anschließend bestätigte dynamische providerübergreifende
Parallelitätssteuerung ersetzt die vorgeschlagene feste Acht-Slot-Obergrenze:
Erhöhung/Reduktion im Betrieb, Budget0 als Admissionpause, laufende Arbeit
auslaufen lassen, separate Supervisor-Kapazitäten und kleine Lab-Budgets.
Keine privaten Kapazitäts-/Systemwerte in dieser Dokumentation.

Weitere Einzelfreigabe 2026-10-04: ausdrücklich aktivierter verwalteter Betrieb
darf direkte unverwaltete USP_ClaimWork-Aufrufe abweisen. Aktivierung nur bei
nachgewiesen claimfreiem Übergang; zuvor bleibt das bisherige Verhalten erhalten.
Antwort auf die konkrete Vertragsfrage: „ja, freigegeben“. Keine Wiederholung
dieser Freigabefrage; übrige neue API-/Recoverydetails bleiben getrennt.

Spätere Erweiterung auf ausdrücklichen Benutzerhinweis: SSIS-Workerpakete als
Provider für T-SQL sowie parametrierte Aufrufe anderer SSIS-Pakete berücksichtigen.
SSIS als Provider und SSIS-Pakete als Auftragstypen sind getrennte Folgegrenzen.
Ausdrücklich nicht Teil der aktuellen Welle; keine Paket-/Installationsfreigabe
und keine Übertragung der atomaren SQL-Abschlusszusage auf SSIS-Seiteneffekte.

CSV-Grundvorschlag wurde angenommen; die NULL-Nachfrage widerrief das nicht.
Optionales NULL-Token zusätzlich bestätigt: unquoted exakt ist SQL-NULL,
quoted Token ist Text; leeres Feld/quoted leer bleibt leerer Text. Ohne Token
weist der Writer SQL-NULL zurück. JSON Pointer read-only, sechs Safe-Cast-
Zieltypen/ISO-Datumsrichtung sowie explizite JSON-Schema-Prüfung ohne Netzwerk-
Referenzen oder Datenänderung wurden als Richtungen angenommen.

Neue konkrete APIs, zusätzliche Grenzen, genaue Recoverybeweise und CLR-/
Providerwahl benötigen die anschließende funktionsbezogene Freigabe. Bestehende
Zustimmungen bleiben erhalten; keine erneute pauschale Grundsatzabfrage.
Vorbereitungs-PR ist keine fachliche Source-/Providerfreigabe und aktiviert
keinen automatischen Dienst, Agentjob, Broker oder Heartbeat.

Fortsetzung 2026-10-05: Der Benutzer beauftragte ausdrücklich weitere autonome
Entwicklung und Analyse bis zu seinem Stopp oder bis ohne Input keine sinnvolle
autorisierte Arbeit möglich ist. Unabhängige Vorbereitung wird deshalb auch bei
einem noch offenen Sourcegate fortgesetzt. Die datierte technische Vorprüfung
in der obigen Entscheidungsvorlage ergänzt CSV-Transport/Atomik, Pointer-
Enginegrenzen, Safe-Cast-Lexik und den begrenzten Schema-Evaluationskern.

Fortschreibung nach CSV-Merge: Die Entscheidungsvorlage enthält konkrete
bevorzugte Pointer-Status-/Unicode-/Tiefenregeln, Safe-Cast-Fehlerpriorität und
exakte Decimal-Betragsgrenze sowie Schema-Referenz-/Unicode-/Arbeitsbudgets.
Sechs neue lesende Decimal-Engineproben bestanden auf Linux2019/latest CL150;
das ist kein Safe-Cast-Runtime-Nachweis. Reuse-Prüfung identifizierte den
vorhandenen Constructor1.2-Scanner und konkrete Policy-/Index-/Budgetlücken.
Providergrenze und funktionsbezogene Freigaben bleiben sichtbar getrennt;
keine neue SQL-Funktion oder Assembly durch diese Researchpflege.
Elf synthetische rein lesende Engine-Assertions bestanden auf dem schema-valide
ausgewählten SQL2019 Linux/latest CL150; kein öffentlicher API-Nachweis und keine
Labmutation. Bestehende konkrete Zustimmungen bleiben erhalten; neue Vorschläge
werden weder als Implementierungsfreigabe noch als Runtime-Capability dargestellt.

Weitere Designprüfung 2026-10-05 für `RI-2026-041/048`: Die
[Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md)
konkretisiert einen nativen Pointer-MSTVF-Pfad mit ISJSON als Grammatikautorität,
separatem Unicode-/Tiefenpolicywalker und vorgelagerten gültigen OPENJSON-
Operanden. Fragmentkopien bleiben ein begrenzter, unqualifizierter Kostenfaktor.
Für Schema sind exakte Mantissen-/Exponentziffernvergleiche ohne BigInteger-
Dependency und die unabhängigen Input-/Arbeitsceiling-Folgen ausgearbeitet:
16MiB Input garantieren keinen Abschluss unter einer Million Defaultschritten;
unvollständige Arbeit liefert LIMIT/IsValidNULL. Keine Defaultänderung,
Keyworderweiterung oder neue Source-/Providerfreigabe. Die Designprüfung enthält
keine Kernlaufzeitprüfung. Anschließend bestanden sechs neue synthetische lesende
Pointer-Engineproben mit eigenem120s-Watchdog, Exit0, vollständigen Kanälen und
leerem Stderr auf schema-validiertem Linux2019/latest CL150: NUL-Key-Identität,
zwei mixed-Surrogate-Fälle, zwei byteexakte Zahlenliterale und direkter Depth128-
Container. Keine Labmutation; ältere17 Proben nicht wiederholt. Kein öffentlicher
API-, Policywalker-, Maximalworkload- oder Gesamtproduktnachweis.
Safe Cast ist inzwischen separat
in PR171 umgesetzt; ältere Vorschlagsaussagen bleiben als Historie erhalten.

Fortsetzung 2026-10-05 nach Pointer-Merge: PR174 wurde nach vier erfolgreichen
Checks am exakten Head122910d gemergt; main/origin/main und eigener
Branchcleanup wurden verifiziert. Die Schema-Recherche konkretisiert jetzt
in der [Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md)
die physische Kerngrenze:
Constructor1.2 weist jede referenzierende Assembly mit53626 ab;
Source-Linking ist keine ausdrücklich genehmigte Ausnahme von einem
kanonischen Kern. Bevorzugter Besprechungsvorschlag ist eine eigene technische
Coreassembly mit separat qualifizierter Constructor1.3-Migration und darauf
aufbauender Schema-USP. Namen/Versionen und interne Bridge sind Vorschläge,
keine Registrierung oder neue Freigabe. Vergleichbare T-SQL- und integrierte
Constructor-Alternativen bleiben dokumentiert. Neue Binary-/Trust-/Owner-/
Dependency- und Abnahmegrenzen sind ausdrücklich getrennt; keine Runtime-
Implementierung oder neue SQL-/CLR-Prüfung durch diese Researchpflege.
Fehler-/Diagnosepriorität, MaxErrors0/Limitverhalten, abstrakte globale
Arbeitsabrechnung und eine synthetische Abnahmematrix sind konkret vorgeschlagen.
Keine neue Assertion als ausgeführter Nachweis dargestellt.


### JSON Schema / gemeinsamer Kern – ausdrücklich freigegeben2026-10-05

Nach konkreter Besprechung in PR175 antwortete der Benutzer:

> Diese Schema-/Kern-Welle freigegeben

Genau USP_ValidateJsonSchema im begrenzten Profil toolbelt-2020-12-v1,
zehn Ergebnisfelder, exakte Zahlen/Unicode, lokale nichtrekursive Referenzen,
globales Arbeitsbudget und vollständiges Urteil trotz gekürzter Diagnosen;
dazu gemeinsamer SAFE-JSON-Core und semantikerhaltende Constructor1.2→1.3-
Migration. Parameter, Fehlerpriorität, interne Bridge, Dependency-Lifecycle
und Abnahmematrix der besprochenen Vorlage sind eingeschlossen. Der
[kanonische Vor-Source-Vertrag](../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
hält die tatsächliche Einzelzustimmung und den Umfang fest.
Status: implemented, partially validated, unreleased. Gemeinsamer Source-
Frameworklauf, eigene vollständige IL, acht verbotene Negativfixtures, drei
kanonische bytegleiche Projektbuilds und sieben Paketierungsfälle bestanden.
Core-/Schema-Scope und genuine bekannte Constructor1.2→1.3 bestanden auf
Linux2019/latest CL150 und Windows2025/CU8 CL170 jeweils local/central,
einschließlich26 Schemafällen, Client/Safety, vier Constructor-Fixtures
mit16 MiB/100000 Einträgen, post-DROP-Rollback und zusätzlichen Annotationen.
Die Migration erhält fünf Procedureidentitäten/Rechte, ersetzt drei eigene
CLR-Slots/Assembly atomar und weist verlustgefährdete direkte Rechte/Owner/
Zusatzmetadaten vorher ab. Der verworfene ALTER-Versuch6282 bleibt fehlgeschlagen.
Frische hashgebundene Dispositionaudits beider aktueller Core-/Schema- und
Migrationsscopes bestanden; keine Konfigurations-/Rechte-/Owneränderung.
[Begrenzte native Evidenz](../Modules/toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).
Weitere Ziel-/Lifecyclematrix, CrossDB, Minimalrechte und aktuelle Head-CI offen.

CI-Statuskorrektur 2026-10-06: Die obige Head-CI-Aussage beschreibt den
früheren Stand. [PR176](https://github.com/gecompat/SQL_Server_Toolbelt/pull/176)
bestand am exakten Head `6dd4ef65ecac8d98d4d5c964a649d63c0d8692dc`
die [gekoppelte JSON-Constructors-Runtime-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37351670226).
Der spätere [PR179](https://github.com/gecompat/SQL_Server_Toolbelt/pull/179)
bestand am exakten Head `194c5ade272d38e2b2d6786694b74f7bbe082112`
[Documentation Consistency](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386445044)
und die [JSON-Constructors-Runtime-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386445377)
mit Known-Artifact-/Offline- und Linux-SQL2019/2022/2025-Jobs; der
[Runtime-Push-Lauf auf main](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37389210961)
bestand ebenfalls. Der CI-Adapter prüft Schema Contract/Safety lokal und
Core-/Constructor-Lifecycle in seinem begrenzten Scope. Die vollständige
physische Ziel-/Lifecyclematrix, CrossDB, tatsächliche Minimalrechte und
Releasequalifikation bleiben offen; `partially validated`, `unreleased`.

Neue Binaries werden separat qualifiziert; die anschließende ausdrückliche
Trustfreigabe autorisiert notwendige begrenzte Tests der laufenden Welle ohne
erneute Schemahashfragen. Keine erneute allgemeine Funktions-/Migrationsfreigabefrage;
keine Release-, Rechtegrant-, Infrastruktur- oder Produktionsfreigabe.
Historische Constructor1.2-Artefakte und Nachweise bleiben getrennt erhalten.

Wartungsfortschritt2026-10-06, Codex: Schema1.0.1 korrigiert den bestehenden
Vertrag für die Reihenfolge codierter Schema-/Refgraphorte. Früh erkannte
Schemaformen werden beim geordneten Ortbesuch geprüft; Graphkanten folgen
budgetiert codierten Zielpfaden. Decodierte Instanzmember, numerische
Instanzarrays, Profil, Signatur und zehn Ergebnisfelder bleiben gleich.
Kein neuer öffentlicher Funktionsscope. Ein expliziter Maintenancepfad für
bekannte1.0.0→1.0.1-Stände und der Uninstall beider bekannten Releases sind
implementiert. Historische Closure und Core-/Constructorframes bleiben
unverändert erhalten; ihre Gesamtqualifikation wird nicht neu behauptet.

Der begrenzte aktuelle Schema-Driver bestand15 Prozessphasen mit stabilen
Pins:169 Profilfälle/1275 Assertions,854 Zahlenfälle/6830 Assertions und120
Bridge-Assertions jeweils en-US/de-DE/tr-TR, eigene IL und bytegleicher
kanonischer Schema-Projektbuild. Sechs Patch- und sieben Releasepaketierungs-
orakel, ScriptDom14 Batches/42 Assertions, PowerShell-/Bashsyntax und18
synthetische CI-Cleanupfälle sowie33 Selector-/Bindungsfälle ohne Labzugriff
bestanden. Der historische Builder erzeugte die
echte1.0.0-DLL aus50 unveränderten Gitblobs des festen Vorgängercommits in53
erfolgreichen Prozessphasen; falscher Core und belegtes Ausgabeziel wurden
abgewiesen. [Aktuelle Offline-Evidenz](../Modules/toolbelt.json.schema/Tests/Framework/README.md)
und [getrennte Testmatrix](../Modules/toolbelt.json.schema/Tests/TEST_MATRIX.md).

Fortschreibung2026-10-06, Codex: Die vorstehenden erfolgreichen
`qual3`/`package3` mit sechs Patchorakeln belegen ihren früheren Scriptstand.
Nach Common-Härtung bestanden `qual4`/`package4` erneut15 Phasen und die
gleichen Harnesszahlen, jetzt acht Packagingfälle. Common bindet einen
einzigen strict-UTF8-Byteinput an den festen historischen Snapshot-SHA256;
gültig neu gerahmte Constructorframes werden in Generator und Driver mit
`SCHEMA_PATCH_BASELINE_PIN` vor Ausgabe abgewiesen. Der finale Kandidat
entspricht semantisch exakt der aktiven Registry und ihren Binaryhashes.

Der erste [native CI-Versuch](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37525258700)
am Head `58993f7012a0b458db377d7d4374b7bf162f0432` scheiterte auf SQL2019/2022
mit Msg515 in UpgradeCapture Permissions: leerer FOR-XML-Katalog als NULL.
Capture und Verify normalisieren dies nun symmetrisch auf `0x`;
unabhängiger Review und ScriptDom14 Batches/42 Assertions bestanden.
SQL2025 lief bei Erfassung noch; der Fehlversuch bleibt Historie.
Native1.0.1-API, echter SQL-Upgrade, exakte korrigierte Head-CI und die
ergänzte Windows-CI-Qualifikation bleiben PENDING.
Die vorhandenen nativen1.0.0-Nachweise bleiben historische
Wahrheit. Weitere physische Ziele, Minimalrechte und Ressourcenqualifikation
bleiben offen; keine lokale Docker-/SQL-Maximallastprobe. Status weiterhin
implemented, partially validated, unreleased. Die Registryfelder zu Trust
und nativer Qualifikation bleiben unveränderliche Offline-Freeze-Metadaten,
getrennt von der bestehenden Testautorität und aktueller Evidenz.

Native Fortschreibung2026-10-06, Codex: [Runtime37532174433](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37532174433)
und Docs37532174428 am exakten Head83164b539e637deeb1ad21b74a15cad99e0184c1
PASS. Schema Linux SQL2019/CL150,2022/CL160,2025/CL170 je local/central:
genuine1.0.0→1.0.1, Mode-Abweisung, post-ALTER55699-Rollback,
Uninstall alt/Reinstall/Upgrade/Repeat,40 Contractfälle je Modus, Safety,
CrossDB und Cleanup; je acht Upgrade-/zwei Safety-Witnesses ohne
UnexpectedSQL/CleanupUnverified. SQLCMD-Dateifaulttransport besteht im
tatsächlichen Testpfad, keine exakte Actual168-Ursachenbehauptung.
Historische failed/PENDING-Records bleiben erhalten. Jeder spätere Head
benötigt vor Integration eigene erfolgreiche Checks; übrige physische-/Minimalrechte-/Lifecycle-/
Kapazitätsmatrix und Release offen, weiterhin partially validated/unreleased.

### TC-2026-039 / TC-2026-040 / TC-2026-042: Deterministic-Familie implementiert

Stand 2026-10-02: Die am 2026-10-01 einzeln freigegebenen
`TVF_DeterministicRange`, `TVF_DeterministicDateShift` und
`USP_DeterministicLookup` sind als `toolbelt.pseudonymization.deterministic`
1.0.0 implementiert. Ein versionierter SHA256-/Byteframing-Kern mit höchstens
128 Rejection-Kandidaten; volle bigint-Grenzen, strikter Date-Overflow,
caller-lokaler versionierter Pool und atomare Standard-ResultTable-Ausgabe.
Identischer finaler Safetyfix-Adapter auf 2019 Linux/latest CL150 und
2025 Windows/CU8 CL150/160/170 erfolgreich: Fach-/Grenz-/Fehlerverträge,
Local/Central, direkte Minimalrechte, Clientmetadaten, alle vier privaten
Tempnamen/Help, nichtdoomende Installer-Callertransaction-Guards ON/OFF,
SQLCMD-nonzero, Wiederholung/Drift/Kollision/Dependency/Uninstall.
Weitere Zielkombinationen, CrossDB-Minimalrechte, reale SQL-Exhaustion und
Produktionskapazität bleiben offen; `partially validated`, `unreleased`.
Historische Vor-Safetyfix-Nachweise vom 2026-10-01 bleiben getrennt erhalten.
Die ursprüngliche Reservebesprechung unten bleibt unverändert; keine
Translate-/Geo-/Fuzzy- oder andere Folgefreigabe aus diesem Abschluss ableiten.

### TC-2026-045: Freigegebener XLSX-Raw-Reader abgeschlossen

Stand 2026-10-02: Die bedingt einzeln freigegebenen `USP_ListXlsxWorksheets` und `USP_ReadXlsxWorksheetCells` sind als `toolbelt.file.xlsx-memory` 1.0.0 implementiert. Vor den öffentlichen Bindings wurden begrenzte Framework-NoIO-/IL-Gates und tatsächliche SAFE-Aufrufe erfolgreich qualifiziert. Der begrenzte eigene XML-Kern verwendet die kanonische technische ZIP-Fassade aus Release 1.4.0 ohne Parserkopie, SDK, Datei-/Netzwerkzugriff oder Rechteausweitung.

Finale identische Adapter auf Linux 2019/latest und Windows 2025/CU8 erfolgreich: local/central/cross-database, sparse Raw/Text/Formula/Cache, NULL- und Help-Metadaten, 128-MiB-Outputcharge, atomare ResultTable-Fehler, Caller-Transaktionen, nichtdoomender XLSX-/ZIP-Lifecycle und echte ZIP-1.3→1.4-Upgradefixture. Framework und unabhängige ZIP-Writer-Regression erfolgreich. Weitere reale große Ceiling-Fixtures, minimale Rechte, sämtliche Zielkombinationen und Produktionskapazität bleiben gemäß [Testmatrix](../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md) offen; `partially validated`, `unreleased`.

Die bereits separat freigegebenen Typ-/Anzeige-Folgefunktionen bleiben `ready for development` für den Nachfolger; sie sind nicht Teil dieses Raw-Reader-Stands. Keine Veröffentlichung und keine neue Welle in dieser Abschlussphase.

### TC-2026-044: Script-only Tabellenklon V1 abgeschlossen

Stand 2026-10-01: Die einzeln freigegebene `USP_ScriptTableClone` ist als
`toolbelt.metadata.table-clone` 1.0.0 implementiert. Begrenzter SameDB-Scope:
Spalten, Defaults, Checks, PK/UQ, gewöhnliche Rowstore-Indizes und optionale
Identity-Eigenschaft; keine API-DDL-Ausführung oder Datenkopie.
Unsupported-Features werden atomar abgewiesen. Datenbankweite VIEW DEFINITION
ist für vollständige incoming-FK-/Kollisionssicht erforderlich; Lifecycle
lehnt aktive Caller-Transaktionen vor SET-/Temp-DDL nichtdoomend ab.
Vollständige finale Adapter auf 2019 Linux/latest CL150 und 2025 Windows/CU8
CL150/160/170 erfolgreich, einschließlich Runtime/ResultTable/Transaktionen,
Clientmetadaten, Rechte/hidden incoming FK, local/central, Typdrift,
Marker/Sourcehash, Kollisionen und Uninstall. Weitere Zielkombinationen,
GitHub-Runtime und niedrigprivilegiertes CrossDB waren zum Abschluss der
lokalen Qualifikation 2026-10-01 nicht ausgeführt; PR-CI ist ein separater
Nachweis und keine Aufwertung dieser lokalen Evidenz.
Status `partially validated`, `unreleased`; keine Ausbauwelle1/2 oder
Trigger-/Ausführungs-/Datenkopieimplementierung in diesem V1-Stand.

### Priorisierte Besprechung: Queue-Verarbeitung und Worker-Orchestrierung

Benutzerauftrag 2026-10-01: Queue-Verarbeitung steht weit oben in der
Wunschliste; als priorisiertes Thema aufnehmen und erforderliche Entscheidungen
jetzt besprechen. Konkretisiert den offenen Worker-Scope von TC-2026-015 und
die getrennten Provider von TC-2026-046; keine neue sequenzielle ID vergeben.

- Vorhandenen validierten Work-Queue-2.0-Kern mit Work-Type-Katalog, Leases,
  Retry/Dead Letter, Idempotency Keys und Drain-Barriers wiederverwenden.
  Keine zweite Queue oder kopierte Claim-/Retrylogik.
- Besprechungsziel: tatsächlich ausführender Worker mit begrenzter
  Parallelität, unabhängigem Lease-Heartbeat während langer Handler,
  kontrolliertem Shutdown, expliziter Recovery und nachvollziehbaren
  Fehler-/Retryentscheidungen. Keine Exactly-once-Zusage.
- Providerwahl, Betriebs-/Installationsgrenze, Handlertransaktionen,
  Ergebnis-/Statusvertrag, Limits und Abbruchverhalten vor Implementierung
  einzeln vereinbaren. SQL Server Agent, Service Broker und externer Worker
  sind Alternativen, nicht automatisch gemeinsam freigegebene Provider.
- Keine beliebige SQL-/Hostscript-Ausführung, Credentials im Repository,
  automatische Rechtevergabe, KILL oder produktive Dienst-/Jobinstallation.

#### Bestätigter Worker-Vertrag und Abschlussauftrag

Einzelfreigabe 2026-10-01: Der Benutzer bestätigte ausdrücklich die vier
besprochenen Queue-Punkte. Erster Provider: externer, manuell startbarer
Windows-/Linux-Worker mit getrennten Handler-/Steuerverbindungen; nur
registrierte NONE-/JSON_PAYLOAD-Handler, kein Raw SQL. SQL Server Agent und
Service Broker bleiben separat auszuarbeitende Folgeprovider, nicht bereits
freigegebene Implementierungen.

- Ein Supervisor, Default ein Slot, konfigurierbar bis acht; keine implizite
  Vervielfachung durch unabhängige Supervisoren. Lease zunächst 300 Sekunden,
  Heartbeat alle 60 Sekunden; Lauf nach Zeit/Auftragszahl oder bis Queue leer
  begrenzen. Kein automatischer Dienst-/Jobinstallationsauftrag.
- Retry nur für ausdrücklich klassifizierte transiente Fehler und dafür
  fachlich geeignete freigegebene Handler. Validierungs-/Rechte-/Unsupported-
  Fehler terminal. Unbekannter Commit-Ausgang sichtbar ungeklärt, niemals
  blind wiederholen. Recovery zuerst explizit, keine Exactly-once-Zusage.
- Geschützte WorkItem-/ClaimGeneration-/ExecutionId-Zuordnung, kooperative
  Handler-Checkpoints, kein KILL. Shutdown stoppt neue Claims, heartbeated
  laufende Arbeit bis zum kontrollierten Ende; nach Gracefrist noch aktiv/
  ungeklärt statt erfundenem Abbruch. Bestätigte Cancellation zunächst FAILED
  mit eindeutigem Fehlercode; keine zusätzliche Queuezustandsmaschine.
- Zunächst Status/Counts/Fehlercodes, keine beliebigen persistierten
  Handlerresultsets. Konkrete Worker-/SQL-Schnittstellen, kurze Control-
  Timeouts, Budgets, Authentifizierung und Testorakel innerhalb dieses Scopes
  vor Source schriftlich konkretisieren; neue fachliche Grenzen rückfragen.
- Dauerbetrieb, persistente Workerregistrierung, supervisorübergreifende
  Slotgrenze und kontrollierter Neustart als zweite Welle vorgesehen.
  Deren konkrete APIs und Dienst-/Jobinstallation separat konkretisieren;
  keine automatische Betriebsfreigabe aus dieser Reihenfolge ableiten.

Status erste Worker-Welle: `ready for development`, hohe Benutzerpriorität;
keine Runtime-Evidenz. Späterer Benutzerauftrag derselben Besprechung:
dieser Orchestrator finalisiert ausschließlich bereits laufende XLSX-Raw-,
Clone-V1- und Deterministic-Range/DateShift/Lookup-Wellen samt Reviews,
erforderlichen Fixes, Tests, PR-Merges und Branchcleanup. Keine neue
Entwicklungswelle hier starten. Danach sauberen Übergabestand in origin/main
herstellen und neuen Orchestrator-Chat mit unveränderten Projektregeln und
individuellen Freigaben zur autonomen Fortsetzung öffnen. Queue-Implementierung
und andere noch nicht gestartete Wellen gehen an diesen Nachfolger.

Nachfolgerstand 2026-10-02: Erste externe Worker-Welle implementiert;
finale PR-Qualifikation `active` im isolierten Branch.
Der [konkrete Providervertrag](../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
legt vor Source die bestehenden SQL-Schnittstellen, private Authentifizierung,
endliche Laufbudgets, Handlerzulassung, claimgebundene Checkpoints,
atomaren Complete-/Handlercommit und Testorakel fest. Keine neue öffentliche
SQL-API; unabhängiger Review und deterministische Fault-Orakel erfolgreich.
Windows-Workerhost auf SQL Server 2019 Linux/latest und 2025 Windows/CU8
qualifiziert, einschließlich echtem Heartbeat während langem Handler,
Retry/Dead Letter, kooperativer Cancellation, Contextdrift, Slots und Drain.
SQL-Readonly-Fehler 15664 zusätzlich auf beiden Zielen geprüft; finale
vollständige Scheduling-Wiederholung auf Windows 2025/CU8 erfolgreich.
Linux-Workerhost-PR-CI gegen eine eigene synthetische SQL-2019-Instanz
einschließlich langem Heartbeat und Cleanup erfolgreich; deterministische
Fault-Verträge auf Windows und Linux erfolgreich.
Runtime `partially validated`, `unreleased`; offene Grenzen stehen in der
[Worker-Testmatrix](../Workers/ExternalQueue/Tests/README.md).
Die vorangehende Abschlussgrenze beschreibt den Vorgänger und verhindert
keine bereits einzeln freigegebene Nachfolgerwelle.

### Individuell freigegebene weitere Wellen und Parser-Voraussetzung

Benutzerfreigabe 2026-10-01: Nach gemeinsamer Besprechung der folgenden
fünf konkreten Themen bestätigte der Benutzer jede zugehörige Entscheidung
einzeln mit „ja“. Die zusätzlich vorgeschlagene Parser-Härtung und
systematische Syntaxqualifikation vor Trigger-Rewriting bestätigte er mit
„ok, das machen wir so“. Keine pauschale Freigabe weiterer Objekte.

#### Parser-Härtung und Syntaxqualifikation

- Bestehenden ScriptDom-Parser härten und eine versionierte Testmatrix für
  DML, DDL, Prozeduren/Funktionen/Trigger, Transaktionen, Security-Statements
  und versionsabhängige Syntax aufbauen. Vor Trigger-Rewriting abschließen.
- Festgestellte Schwachstellen gezielt adressieren: stiller Versionsfallback,
  unbegrenzter NULL-Eingabebyteparameter, Tiefenprüfung erst nach Parser.Parse,
  partielle ASTs bei Syntaxfehlern und widersprüchliche Dokumentationsdefaults.
- Konkreten begrenzten Parameter-/Fehler-/Kompatibilitätsvertrag und
  wirksamen vorgeschalteten Ressourcenwächter vor Sourceänderung dokumentieren
  und qualifizieren. Keine vollständige Syntaxabdeckung nur aus Smoke-Tests
  oder AST-Vorhandensein ableiten.
- Parsen ist keine semantische Namens-/Aliasauflösung und keine sichere
  Umschreibungsfreigabe. Der bestehende UNSAFE-/Windows-only-Vertrag bleibt
  sichtbar; kein Linux-/Worker-/SDKfallback oder Trust-/Rechteausweitung.

Nachfolgerstand 2026-10-02: Die einzeln freigegebene Parser-Härtung ist
`active` im isolierten Branch. Vor Source wird der begrenzte gemeinsame
Vertrag der vier vorhandenen TVFs als Major-Folgeversion konkretisiert:
[begrenzter Hardening-Vertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md).
Der vorgeschaltete Ressourcenwächter wird zuerst in isolierten
Framework-Prozessen auf dem exakt vorhandenen ScriptDom-Binarystand
qualifiziert. Neue Grenzen und fehlende Nachweise bleiben ausdrücklich
sichtbar; Trigger-Rewriting gehört weiterhin zur getrennten Folgewelle.
Der eingefrorene Wächterkandidat bestand 82 isolierte Framework-Fälle;
der integrierte Provider anschließend 245 begrenzte Kindprozesse,
unabhängig wiederholt. Windows 2025/CU8 CL150/160/170 bestand lokale/zentrale
Nutzung, echten 1.0-Upgrade, Wiederholung, Grenzen/Syntax, Caller-TX/SET-Erhalt,
Kollisionsschutz und eigenes DB-/Trust-Cleanup. Windows 2019 bleibt vor
Mutation konfigurationsbedingt blockiert; eine fachfremde Pending-Konfiguration
wird nicht blind mitaktiviert. Windows 2022, minimale Rechte und tatsächliche
Ausgabeceilings bleiben offen; Helperquoten ersetzen diese Nachweise nicht.
Status der 2.0-Welle: `partially validated`, `unreleased`.

#### Trigger-Scriptklon

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich
`IncludeTriggers bit=0` an Position 9 mit Standardtail an Position 10..13
und Folgeversion 4.0.0. Triggernamen erhalten `TR_` plus den vollständigen
SHA256 über genau die drei längengerahmten UTF16LE-Komponenten Zielschema,
Zieltabelle und Originaltriggernamen, ohne zusätzlichen Marker im Hashinput.
`TR_` ist ausschließlich das Namenspräfix dieses Slices, keine globale
Triggernamenskonvention.
Die zuvor freigegebenen Parser-, Script-only- und Ablehnungsgrenzen bleiben
unverändert. Dies dokumentiert die Freigabe, keine Implementierung oder
Runtimequalifikation.

Vor-Source-Stand 2026-10-04, Codex: Der konkrete
[4.0-Triggervertrag](../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
legt die notwendige feste SET-/DDL-Kapselung, quellengetreue FIRST/LAST-
Anordnung und getrennte triggerfreie Executorgrenze fest. Der unveränderte
Hash-v1 bindet im neuen Modulstand 4.0.0 statt 3.1.0; Parameter und Framing
des Executors bleiben gleich. Source und zwei begrenzte Runtime-Fixtures
sind jetzt vorhanden; unabhängige Coreprüfung, statische Kopplung und offline
Syntaxprüfung bestanden. Am2026-10-04 bestand der begrenzte private Nativeadapter
auf Windows2025/exakt CU8 CL170 lokal: beide Trigger-Fixtures einmal Clean4,
Clean4/genuine3.1→4 mit frischer Upgradesession, Repeat, unabhängiger Clienthash,
typgenaue Ausgabe, vier resolved-Consumer-Ablehnungen sowie Uninstall/Repeat.
Zwei eigene DBs entfernt, temporärer exakter Parsertrust wiederhergestellt;
Prozess-/Journal-/Pin- und frischer Cleanupnachweis unabhängig physisch geprüft.
Keine Konfigurations-, Rechte- oder Owneränderung. Separater Linux2019/latest
CL150-Option0-/Lifecycle-PASS wiederverwendet, nachfolgende Coreänderungen
ausschließlich Option1 unabhängig geprüft. Weitere native Ziele/CL, zentrale4.0,
Minimalrechte und unsichtbare/mehrdeutige Kontexte offen; unresolved Consumer
nicht etabliert. Head-CI separat im PR; teilweise validiert, unveröffentlicht.
Historische Fehlerläufe sind kein Gesamt-PASS.

- Bestehenden Scriptplaner optional für gewöhnliche T-SQL-DML-Trigger auf
  gemappten diskbasierten Tabellen erweitern; weiterhin nur Scripttext.
  Ereignisse, AFTER/INSTEAD OF und enabled/disabled-Zustand erhalten.
- Name, Zielbindung und eindeutig auflösbare Tabellenverweise anhand des
  expliziten Klon-Mappings umschreiben. Bestehenden Parser wiederverwenden;
  Kommentare/Stringliterale unverändert, keine blinde Textersetzung.
- Dynamisches SQL, verschlüsselte/CLR-Trigger, EXECUTE AS, mehrdeutige oder
  externe Referenzen sichtbar ablehnen. Keine automatische Kopie referenzierter
  Funktionen/Prozeduren. Parserfehler müssen vor Umschreibung ausgeschlossen sein.
- Plattformgrenze des Parsers vererben, keine vorgetäuschte Linux-Fähigkeit.

#### USP_ExecuteTableClone

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich vorhandenes
Server-`VIEW ANY DEFINITION` und lesbare DB-/Server-DDL-Trigger- sowie
Eventnotification-Kataloge als Pflichtgate. Fehlende oder unklare Sicht und
relevante aktive DDL-Trigger/Eventnotifications blockieren vor eigener DDL;
keine Rechtevergabe oder Deaktivierung. Der konkrete additive 3.1-Vertrag,
das versionierte Hashlayout und die technische FK-Aufschuboption stehen in
[TABLE_CLONE_EXECUTE_CONTRACT](../Documentation/Architecture/TABLE_CLONE_EXECUTE_CONTRACT.md).
Implementierung und unabhängige Sourceprüfung sind abgeschlossen. Am
2026-10-04 bestanden die gezielten lokalen 3.1-Nachweise auf SQL Server
2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170: beide neuen
Fixtures, unabhängiger Client-Hash und Resultmetadata, genuine3→3.1,
Lifecycle und eigene Bereinigung. Head-CI wird separat im Pull Request nachgewiesen;
historische Planner-Nachweise bleiben getrennt. Serverweite negative
Trigger-/Eventnotification-Fixtures und tatsächliche Minimalrechte wurden
nicht ausgeführt; der Modulstatus bleibt teilweise validiert.

- Explizites Tabellen-Mapping/Planneroptionen und erwarteter Plan-Hash;
  kein frei übergebener SQL-Text. Kanonischen Plan unmittelbar neu erzeugen
  und vergleichen. Nur neue Ziele, kein DROP/Overwrite/Ändern vorhandener Ziele.
- Eigene begrenzte Transaktion, fremde aktive Caller-Transaktion ablehnen;
  Fehler rollen eigene SQL-Änderungen zurück. Keine Rechteausweitung.
- DDL-Trigger/nicht kontrollierbare externe Nebenwirkungen sind Scopeblocker.
  Toolbelt-Lock ist keine Driftgarantie gegen fremde DDL. Hash ist keine
  Berechtigungsfreigabe; aktuelle Quell-/Ziel-/Callerrechte weiter prüfen.

#### USP_CopyTableCloneData

Umsetzungsstand 2026-10-04, Codex: Der bereits einzeln freigegebene Copy-Scope
wird als Release4.1.0 konkret umgesetzt; [kanonischer Vertrag](../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md).
Neun öffentliche Parameter, fünf NOT-NULL-Ergebnisfelder; Map64,100000 globale
Zeilen und16MiB transportierte SQL-Nutzdaten, Caller nur absenkbar. Der bestehende
interne Core erhält ausschließlich einen PREVIEW/COPY_FK-Zweckparameter, keine
weitere öffentliche API. Vier Lifecycle-Slots13/14/14/9; die öffentliche
Planner13- und Executor14-Signatur bleiben erhalten. Vorhandene DB-/DML-Sicht
gilt immer; genehmigte Server-DDL-Vollsicht nur bei tatsächlich fehlenden FKs.
Gemeinsame FK-Herleitung, exakte Form-/RLS-/Seiteneffektgates, Identity- und
Rollbackgrenzen stehen im Vertrag. Keine automatische Konfiguration oder
Rechteerteilung. Besprochene Punkte vom Benutzer abschließend mit „alles
freigegeben“ bestätigt; Source, Runtime, unabhängige Prüfung und aktuelle
Head-CI bleiben eigene Nachweise. Normale fünf Copygruppen, Client und
Clean/genuine4.0→4.1-Lifecycle bestanden auf Linux2019 CL150 und Windows2025
exaktCU8 CL170; eigene Bereinigung unabhängig geprüft. Vier dynamische Identity-
Zustände und zwei gezielte SNAPSHOT-Konkurrenzfälle separat auf Linux2019
bestanden. Abgeschlossene Teilnachweise aus insgesamt fehlgeschlagenen
Adapterläufen werden bei unveränderten Produktbytes ausdrücklich getrennt
wiederverwendet; keine Wiederholung erfolgreicher Fälle. Head-CI gesondert
im PR, weiterhin teilweise validiert und unveröffentlicht. Historische4.0-
Zeugen werden nicht zur Copyqualifikation umgedeutet.

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich maximal
100000 Zeilen und 16 MiB Nutzdaten, durch Caller absenkbar, sowie die
Rollbackgrenze bei Identity-Zählerfortschritt ohne automatisches RESEED.
Kontrolliert nach Copy neu angelegte FKs übernehmen die bekannten
Quellzustände checked/trusted, enabled/untrusted oder disabled/untrusted;
bestehende Constraints werden nicht heimlich deaktiviert. Das eigene
Servervollsicht-/DDL-Seiteneffektgate für diese nachgelagerte Anlage wurde
ebenfalls ausdrücklich bestätigt, ohne Rechtevergabe. Dies dokumentiert die
zusätzliche Entscheidung innerhalb der Einzelfreigabe; genaue Signatur,
Implementierung und Qualifikation bleiben getrennte Folgeschritte.

- Explizites SameDB-Mapping, nur leere kompatible Ziele. Keine freien SQL-
  Filter, Merge/Upsert oder Überschreiben. Konsistenter Verbundsnapshot:
  vorhandenes SNAPSHOT oder ausdrücklich gewählter SERIALIZABLE-Sperrmodus;
  keine automatische Datenbankkonfiguration durch die öffentliche Funktion.
- Identity erhalten oder neu vergeben ausdrücklich wählen. Neuvergabe bei
  davon abhängigen Beziehungen ablehnen. Computed/rowversion nicht einfügen.
- Zieltrigger fehlen oder sind disabled. Zyklische FKs nur über kontrollierte
  Anlage nach Datenkopie, keine heimliche Constraint-Deaktivierung.
- Zeilen-/Datenbudgets begrenzen, Fehler rollback eigener Zielwrites;
  Ausgabe nur Counts/Status, keine Rohdatenlogs. Sessionzustand einschließlich
  IDENTITY_INSERT sauber behandeln, fremden Zustand nicht überschreiben.

#### TVF_DeterministicTranslate

- Fortschritt 2026-10-02: [kanonischer Vor-Source-Vertrag](../Documentation/Architecture/DETERMINISTIC_TRANSLATE_CONTRACT.md)
  konkretisiert den freigegebenen Slice additiv im bestehenden Modul als
  1.1.0. Unabhängig wiederholte private Referenzqualifikation: 5.540 Assertions;
  getrennte Read-only-Nativprimitive: 48 Assertions, Linux 2019/latest und
  Windows 2025/CU8. Unabhängiger Semantikreview erfolgreich. SQL-API,
  Lifecycle, Metadaten, Rechte und CI dadurch noch nicht qualifiziert.

- Integrierter Fortschritt 2026-10-02: Source/Lifecycle implementiert;
  statische Referenzsuite mit 1.746 Translateassertions und unabhängige
  Reviews erfolgreich. Vollständiger synthetischer Adapter auf Linux
  2019/latest CL150 local/central und Windows 2025/CU8 CL150/160/170 central
  bestanden: alle sieben Slots, Fehler-/Safety-/LOB-/Collationfälle,
  SQL-/Clientmetadaten, echtes 1.0-Upgrade, Wiederholung, Callertransaktionen,
  Kollisionen/Zukunftsslots, Uninstall und eigener Cleanup. Windows local:
  API-/Safetyfälle im früheren Gesamtfehllauf bestanden; separate korrigierte
  Metadaten-/Lifecycleprüfung erfolgreich. Kein Gesamt-PASS des Fehllaufs.
  Keine Serverkonfiguration/Grants; neue Minimalrechte, weitere physische
  Targets, Kapazität und aktuelle CI offen. `partially validated`,
  `unreleased`; kein Merge- oder Veröffentlichungsnachweis.

- Zweck ausdrücklich bestätigt: formaterhaltende Transformation synthetischer
  Kennungen. Rückführbarkeit und verbleibende Länge-/Muster-/Häufigkeits-
  offenlegung ausdrücklich akzeptiert; keine Anonymisierung/Verschlüsselung.
- MappingVersion/Seed, explizite Alphabete zunächst ASCII-Buchstaben/Ziffern;
  Groß-/Kleinschreibung und ausdrücklich erlaubte Trennzeichen erhalten.
  Unbekannte Zeichen standardmäßig Fehler. Begrenzte Langtextverarbeitung,
  kein Abschneiden. Erste Version nur Vorwärtstransformation, Abbildung
  grundsätzlich rückführbar; keine zusätzliche Decode-API ableiten.

#### TVF_DeterministicGeoJitter

- Fortschritt 2026-10-02: Der [begrenzte Vor-Source-Vertrag](../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md)
  konkretisiert die einzeln freigegebene Funktion additiv als Version 1.2.0.
  Unabhängig wiederholte Modellreferenz: 10.685 Assertions. Native Read-only-
  Qualifikation auf Linux 2019/latest und Windows 2025/CU8: je 1.458
  Modellfälle; korrigierte sichere Operandenkette mit 32 Variablen- und neun
  direkten Literalfixtures in jeweils drei Abfrageformen erfolgreich.
  Tatsächliche 128-Byte- und größere Non-Point-UDTs sind geprüft; ein exakt
  129-Byte-UDT wurde nicht beobachtet und wird nicht als PASS gewertet.
  Öffentliche API, Metadaten, Lifecycle und CI sind dadurch noch nicht geprüft.

- Historischer integrierter Zwischenstand 2026-10-02: Lokales echtes 1.0.0-Upgrade auf
  1.2.0 und Katalogmetadaten bestanden; der Geo-API-Aufruf auf Linux 2019
  scheitert mit SQL-Fehler 701. Auch der isolierte Einzelaufruf scheitert,
  einschließlich einer kleinen SafeKey-Entkopplung. Kein Geo-API-PASS und
  kein vollständiger Lifecycle-/CI-Nachweis. Eigene Testdatenbanken sind
  bereinigt; keine Konfigurations- oder Rechteänderungen. Die Ursache ist
  nicht nachgewiesen.

- Finaler Fortschritt 2026-10-02: Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

- Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

- Zweck ausdrücklich bestätigt: synthetische Testpunkte, SRID4326.
  Entitätsschlüssel/MappingVersion/Seed bestimmen reproduzierbare Verschiebung.
  Radius ausdrücklich in Metern, Default100m/Ceiling10km bestätigt.
- Dokumentierte flächenorientierte Verteilung, keine bevorzugte Richtung;
  Pole/Datumsgrenze/ungültige Koordinaten behandeln und Grenzen qualifizieren.
  Entfernung nach dokumentierter SQL-geography-Näherungssemantik prüfen.
- Kein Land-/Gebiets-Clipping; Wasser/außerhalb Verwaltungsgrenze akzeptiert.
  Verknüpfbarkeit wiederholter Beobachtungen bleibt möglich; keine
  Anonymisierungszusage, realen Geodaten oder zusätzlichen Spatial-APIs.

Status dieser Wellen: `ready for development`; keine Implementierungs-/
Runtime-Evidenz durch diesen Eintrag. Aktuelle V1-Wellen zuerst abschließen,
danach unabhängige freie Agent-Slots nutzen. Öffentliche Typen, genaue
Budgets, Fehler-/NULLsemantik und Dependencies innerhalb des besprochenen
Scopes vor Source schriftlich konkretisieren und qualifizieren; neue
fachliche Entscheidungen rückfragen. Unabhängiger Review, synthetische
Tests, scopebezogenes Lab, grüne CI, PR-Merge und Branchcleanup unverändert.
Die Freigabe erlaubt API-Implementierung und synthetische Qualifikation,
keine autonome Ausführung/Kopie gegen beliebige reale Benutzerdatenbanken.

### Folgewellen: Capture-Replace, XLSX-Interpretation und unscharfer Textvergleich

Benutzerentscheidungen 2026-10-01: Der Benutzer verlangt sämtliche
Capture-Wiederholungen statt nur der letzten Capture je Gruppe. Die separat
besprochene gruppenbezogene Replace-Erweiterung mit `$1`, `${Name}` und `$$`
wurde ausdrücklich mit „ja“ bestätigt. Bestehendes literal Replacement
bleibt davon getrennt und unverändert.

Für XLSX wurde die Reihenfolge bestätigt: Typinterpretation als eigene
Funktionen, danach Anzeigeformatierung. Der vorgeschlagene erste
Formatierungsumfang wurde mit „ja“ bestätigt: Zahlen, Prozent,
wissenschaftliche Schreibweise, Datum/Uhrzeit und Text, ausdrücklich
gewählte Culture; keine Farben, bedingte Formatierung, Layoutauswertung oder
Formelberechnung. Dies erweitert nicht stillschweigend die aktiven Raw-Reader.

Für unscharfen Textvergleich beauftragte der Benutzer Levenshtein,
Transposition und phonetischen Vergleich für Deutsch und Englisch.
Zuerst sind zwei getrennte Distanzfunktionen vorgesehen: Levenshtein und
eine exakt definierte Variante mit benachbarter Transposition. Hauptzweck
sind Namen und kurze Bezeichnungen; längere Texte müssen ebenfalls
berücksichtigt werden, gegebenenfalls über eine getrennte Variante.

#### Individuell freigegebener Textvergleichsvertrag

Implementierungsfreigabe 2026-10-01: Auf die ausdrückliche Frage
„Passt dieser Vertrag einschließlich Longtext-Verhalten und Phonetikverfahren
für die Implementierung?“ antwortete der Benutzer „ja“. Die vier getrennten
Funktionen sind damit einzeln freigegeben, zuerst die beiden Distanzen,
danach die beiden sprachbezogenen Phonetikverfahren:

- Levenshtein: Einfügen, Löschen und Ersetzen kosten jeweils 1.
- Optimal String Alignment (OSA): zusätzlich benachbarte Transposition
  für 1; eingeschränkte Variante, kein uneingeschränktes Damerau-Levenshtein.
- Unicode-Zeichen statt Bytes; Standard exakt und case-sensitive. Keine
  automatische Entfernung von Akzenten, Leerzeichen oder Satzzeichen.
  Optionale Normalisierung nur ausdrücklich gewählt und dokumentiert.
- Dieselben Distanzfunktionen mit Standard-/Large-Profil, ohne Abschneiden.
  Optionaler MaxDistance-Parameter: oberhalb der Schwelle ausdrücklich
  „größer als Grenze“, kein erfundener exakter Abstand. Rechenaufwand
  begrenzt; Ressourcenüberschreitung Fehler, keine stille Näherung.
  Konkrete Grenzen durch synthetische Tests qualifizieren und dokumentieren.
- Deutsch: Kölner Phonetik. Englisch: Double Metaphone mit primärem und
  alternativem Code. Verfahren/Sprache ausdrücklich wählen, keine
  automatische Spracherkennung; Phonetik getrennt von Editierdistanz.
- Öffentliche Namen, Parameter-/Ergebnistypen, NULL-/Fehlersemantik und
  technische Ressourcenprüfung innerhalb dieses Scopes vor Sourceumsetzung
  schriftlich konkretisieren. Keine zusätzliche fachliche API oder
  unbesprochene Normalisierungsoption ableiten; neue fachliche Entscheidung
  rückfragen. Standardprojektgates, unabhängiger Review, scopebezogene
  Lab-Tests, grüne CI und PR-Merge gelten unverändert.

Status Phonetik 2026-10-04: Die individuelle Provider-/TVF-/Alphabet-/Fullcode-/Grenzfreigabe vom 2026-10-03 wurde nach unabhängigem Referenz-/Lizenz-/Bindingreview in den kanonischen [Phonetikvertrag](../Documentation/Architecture/PHONETIC_CONTRACT.md) übernommen. Genau zwei öffentliche IF und zwei interne FT verwenden die eigene SAFE-Assembly in toolbelt.string.phonetic 1.0.0; kein Vierzeichen-Clamp, kein Aspell-Bulkimport und keine neue Normalisierungsoption. Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Java-Differential, vollständige Zielmatrix, Minimalrechte und aktuelle Head-CI bleiben offen; teilweise validiert und unveröffentlicht. Die [Testevidenz](../Modules/toolbelt.string.phonetic/Tests/README.md) trennt private Lab- und öffentliche Offline-CI-Scope. Die historischen Distanzfreigaben und deren Nachweise bleiben getrennt.

Historischer PR301-Quellenstand vor dem ersten Differentiallauf:

Ergänzung Phonetik 2026-10-08 – Codex: Für die bereits einzeln freigegebenen Funktionen werden sechs gekoppelte Offline-Differential-Testquellen einschließlich eines portablen Apache-Referenzmanifests ergänzt; kein neues öffentliches SQL-Objekt oder Produktprovider. Der [Differential-EntryPoint](../Modules/toolbelt.string.phonetic/Tests/README.md) vergleicht 32 synthetische Fälle mit vollständigen Codes und AJ-Endblank. Der ausgewählte Windows-/PowerShell-7.3+-Consumerpfad verlangt explizite Compiler-/Framework-/JDK-Inputs, belegte aktuelle Assembly-Sourceprovenienz und einen externen ReferenceDirectory mit elf exakt gebundenen Dateien. Keine automatische Beschaffung oder Ersatzwahl. Der Differentiallauf bleibt NOT_EXECUTED; bestehende Teilnachweise, offene Matrix-/Minimalrechte-/SAFE-/Releasegrenzen und historische Aussagen werden dadurch nicht aufgewertet.

Fortschreibung Phonetik 2026-10-08 – Codex: Der einmalige lokale Offline-Differentiallauf unter Windows/.NET Framework 4.8 mit ausdrücklich gewähltem JDK27 und unveränderten Apache-Commons-Codec-1.18.0-Referenzquellen bestand am aktuellen Phonetikquellstand. Die frisch gebaute Assembly und der vorhandene Runner mit explizitem `BindingPath`/`ExpectedBindingSHA256` liefern für 32 synthetische Fälle (16 Cologne, 16 Double Metaphone) bytegleiche vollständige Codes einschließlich des alternativen AJ-Endblanks. Unabhängige Read-only-Evidenzprüfung bestätigte Input-/Kopie-/Outputpins und Rohtransport ohne Rerun. Nur dieser endliche Vergleich ist geschlossen; SQL-/SAFE-, vollständige Scanner-/Zielmatrix-, Minimalrechte- und Releasequalifikation bleiben offen. Das Modul bleibt teilweise validiert und unveröffentlicht; Produktcode, API und Workflow unverändert. Private Dateien bleiben erhalten, kein Datei-Cleanup-PASS. Die vorstehenden NOT_EXECUTED-Aussagen bleiben als damaliger Quellenstand erhalten.

Testwartung Phonetik 2026-10-09 – Codex: Vier zusätzliche synthetische Cologne-Fälle `HCL`, `ACL`, `-CR` und `ACR` prüfen den C-Kontext bei leerem Ausgabepuffer gegenüber dem Kontext nach `A` sowie den Folgebuchstaben `L` oder `R`. Der einmalige lokale [Differentialvergleich](../Modules/toolbelt.string.phonetic/Tests/README.md) bestand mit allen 36 Fällen (20 Cologne, 16 Double Metaphone) unter Windows/.NET Framework 4.8, ausgewähltem JDK27 und unverändertem Apache Commons Codec 1.18.0. Die quellenabgeleiteten vier Sollcodes `45`, `085`, `47` und `087` stimmen tatsächlich; vollständige Codes und AJ-Endblank bleiben exakt. Wiederverwendet wurde die Assembly mit nachgewiesener Herkunft aus den fünf unveränderten aktuellen C#-Quellen, ohne neuen Produktbuild für diesen Lauf. Der frühere 32-Fälle-PASS und alle historischen Aussagen bleiben erhalten. Nur der endliche Corpusvergleich ist geschlossen; stderr ist ausschließlich als leerer decodierter Rückgabetext belegt, Dateien bleiben erhalten und kein Datei-Cleanup-PASS wird behauptet. Produkt/API, Workflow, Referenzmanifest, teilweise validierter/unveröffentlichter Modulstatus sowie offene SQL-/SAFE-, Scanner-/Zielmatrix-, Minimalrechte- und Releasequalifikation bleiben unverändert.

Ergänzende konkrete Providerfreigabe 2026-10-02: Auf die Frage nach dem
besprochenen dedizierten portablen SAFE-CLR-Provider für Levenshtein und OSA
antwortete der Benutzer „Lebenshtein/OSA assembly -> ja“. Dies autorisiert
nur diesen Provider und seinen Lifecycle für die beiden bereits einzeln
freigegebenen Distanzfunktionen. Jaro und Phonetik werden dadurch nicht in
diesen Provider aufgenommen. Der [Vor-Source-Vertrag für Editierdistanzen](../Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md)
konkretisiert Scalar-Semantik, Profile, Schwellen, Ergebnis- und Fehlerpriorität,
Metadaten sowie den separaten Deployment-/Trustvertrag. Root hat den vollständigen Vor-Source-Vertrag einschließlich nullable SQL-Metadaten bei logisch nicht-NULL ErrorCode am selben Tag geprüft und vor Runtime-Source geschlossen. Die Implementierung ist teilweise validiert und unveröffentlicht. Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Der erste Linux-Lauf SQL468/State9 im Metadaten-Fixture bleibt als vollständig bereinigter Fehlerlauf getrennt; der korrigierte neue Adapter bestand.
#### Individuell freigegebene Capture-/Replace-Welle

Implementierungsfreigabe 2026-10-01: Auf die ausdrückliche Frage
„Passt dieser konkrete Scope für beide Wellen zur Implementierung?“
antwortete der Benutzer „ja“. Dies bestätigt die folgende Capture-TVF und
die getrennte gruppenbezogene Replace-Funktion nach Einzelbesprechung:

- Alle Capture-Wiederholungen mit Match-, Gruppen- und Capture-Ordinal,
  Gruppenname, Position, Länge und Wert ausgeben.
- Nicht beteiligte Gruppen erkennbar mit Matched=0 und NULL für Position,
  Länge und Wert. Tatsächlich leerer Capture davon unterscheidbar.
- Replace unterstützt `$1`, `${Name}` und `$$`. Mehrfach erfasste Gruppe
  verwendet beim Replace ihre letzte Capture; die TVF liefert alle.
- Nicht beteiligte Gruppe ersetzt durch Leertext; unbekannte
  Gruppenreferenz ist ein Fehler.
- Bestehendes literales Replace unverändert. Keine Rückreferenzen im
  Suchpattern durch diese Erweiterung.
- Öffentliche Namen, genaue Typen, Zählweise, NULL-/Fehlerprioritäten und
  Profile innerhalb dieses Scopes vor Sourceumsetzung schriftlich
  konkretisieren; bestehende begrenzte SAFE-/LOB-Verträge weiterverwenden,
  keine Unlimited-, stille Truncation- oder Teilausgabeoption.

Status Capture/Replace: `ready for development`; keine Runtime-Evidenz.

Nachfolgerstand 2026-10-02: Vor-Source-Konkretisierung der bereits einzeln
freigegebenen zwei APIs ist `active` im isolierten Branch. Der
[Capture-/Replace-Vertragskandidat](../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md)
legt Signaturen, Gruppen-/Capture-Ordinals, Sentinelzeilen, Replacement-
Syntax und Fehlerpriorität fest. Ein zusätzliches konservatives
Capture-Historienprofil wird zunächst privat und synthetisch qualifiziert;
MaxRows/Textlimits allein schützen nicht vor bereits intern gespeicherten
Captures. Keine Sourceimplementierung oder SQL-Evidenz durch diesen Eintrag.
Die bisherigen sieben Regex-APIs und deren Nachweise bleiben unverändert.
Vor-Source-Gate anschließend erfolgreich: exakt präzisierter Strukturkandidat
bestand neun begrenzte Framework-Kinder mit 7608 Assertions, unabhängig
wiederholt; Semantikreview PASS. Die integrierte Source und SQL-SAFE-Runtime
bleiben separat zu qualifizieren; keine Heap-/Backtracking-Garantie.

Historischer API-only-Zwischenstand 2026-10-02: zwei freigegebene APIs im Branch umgesetzt,
integrierte Framework-Suite und unabhängiger Source-Review erfolgreich.
Begrenzte API-only-Labproben einschließlich SQLClient-Metadaten/Atomicity
lokal/zentral auf Windows2025 CU8 CL150/160/170 und Linux2019 latest CL150
erfolgreich; eigene Datenbanken/Trusthashes vollständig bereinigt. Lifecycle
ist blockiert: unsigned CLR-Katalogidentität belegt keine tatsächliche
Releaseversion. Vorgeschlagene zusätzliche erwartete Hashgrenze wartet auf
Benutzerentscheidung. Kein Upgrade-/Reinstall-/Uninstall-PASS, keine grüne
CI oder Mergebehauptung. Weitere Matrix, neue Mindestberechtigungsnachweise
und tatsächliche Large-Capture-Outputgrenze in SQL noch nicht ausgeführt.

Zusätzliche Einzelfreigabe 2026-10-02: Der Benutzer beantwortete die offene
technische Hashgrenze ausdrücklich mit „Ja, exakte Hashbindung freigeben“.
Deploy und Uninstall erhalten `ExpectedInstalledAssemblyHash`: den expliziten
SHA2_512-Hash der tatsächlich installierten, offline verifizierten Binarybytes
als `0x` plus 128 Hexzeichen. Bekannte installierte Releases 1.0 bis 1.3
erfordern den exakten Vergleich mit `sys.assembly_files.file_id = 1`, erneut
unter AppLock. Unbekannte Versionen, unbekannte oder abweichende Hashes bleiben
blockiert; keine Ableitung aus `clr_name`, Versionsannahme oder Hash-Fallback.
Nur vollständig geprüfte Modul-/Assembly-Abwesenheit erlaubt ausdrücklich
`0x`. Diese Freigabe erweitert weder APIs noch Trust, Konfiguration oder Rechte.
Der vorherige Blockierungsstand bleibt historische Evidenz; zum Zeitpunkt
dieser Freigabe standen neue Lifecycle- und CI-Nachweise weiterhin aus.

Finaler Nachweis 2026-10-02: Derselbe korrigierte Gesamtadapter bestand auf
Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal und
zentral. Umfasst die sieben alten und zwei neuen APIs, SQLClient-Metadaten,
atomare Fehler, echten 1.2-zu-1.3-Upgrade, Reinstall, explizite Binaryhashbindung,
Caller-Transaktionen/Optionserhalt, AppLock, post-DROP-Rollback, Versions-/
Marker-/Future-Slot-/Schema-Kollisionen, Dependencies, Uninstall und verifiziertes
eigenes Datenbank-/Trustcleanup. Frühere Gesamtadapterversuche scheiterten an
unverarbeiteter historischer SQLCMD-Direktive, einem optionsverändernden
Snapshot und der Credential-Quelle der zweiten Testverbindung; diese
Fixture-/Adapterfehler wurden behoben und bleiben historische Fehlernachweise.
Neue Capture-Minimalrechte, weitere Zielmatrix, tatsächliche große SQL-
Capture-Ausgabegrenze und SQL-100k-Durchsatz sind nicht ausgeführt. Die aktuelle CI wird separat als PR-Mergegate nachgewiesen; `partially validated`, `unreleased`, keine Mergebehauptung.

#### Individuell freigegebene XLSX-Typ-/Anzeige-Welle

Dieselbe ausdrückliche Benutzerantwort „ja“ vom 2026-10-01 bestätigt
separat die besprochene Typfunktion und Anzeigeformatierung:

- Separate Typfunktion liefert typisierte Werte samt Status, Rohwert bleibt
  erhalten. Zahlen nicht automatisch als Datum interpretieren: expliziter
  Zieltyp oder unterstützter Zellformatcode erforderlich.
- Datum, Uhrzeit und Dauer getrennt; Dauer darf über 24 Stunden liegen.
  Workbook-Datumssystem 1900/1904 beachten. Ungültiges Excel-Schalttagsdatum
  29.02.1900 liefert expliziten Sonderstatus, kein erfundenes SQL-Datum.
- Anzeigeformatierung liefert Text plus Status. Unterstützter erster Scope
  wie oben: Zahl, Prozent, wissenschaftlich, Datum/Uhrzeit und Text mit
  ausdrücklich gewählter Culture. Nicht unterstützte Formatcodes sichtbar
  melden, nicht stillschweigend annähern.
- Gespeicherte Formel-Ergebnisse dürfen verarbeitet werden, niemals neue
  Formelberechnung. Keine Farben, bedingte Formatierung oder Layoutauswertung.
- Nach qualifiziertem Raw-Reader implementieren; Typ-/Styletransport,
  unterstützte Formatgrammatik, SQL-Typ-/Überlauf-/NULLsemantik und begrenzte
  Ressourcen innerhalb dieses Scopes schriftlich konkretisieren. Keine
  Datei-/Netzwerk-, SDK-/Worker- oder Rechteausweitung ableiten.

Historischer Vorbereitungsstand der XLSX-Folgefunktionen: `ready for development`; damals keine Runtime-Evidenz. Der aktuelle Typstand folgt datiert unten; Anzeigeformatierung bleibt separat.
Am 2026-10-02 bestätigte der Benutzer zusätzlich die konkret besprochene
V3-Typentscheidung mit „Xlsx typeninterpretation -> freigegeben“: genau eine
`toolbelt_file.TVF_InterpretXlsxCell`, sieben Parameter / 14 Spalten,
exaktes SqlDecimal im sql_variant, enge ISO-/100-ns-/Serial60-Regeln und
atomarer Echoverzicht bei Ressourcenfehler 3 beziehungsweise NULL-Bindungs-
fallback 11. Der [kanonische Vor-Source-Vertrag](../Documentation/Architecture/XLSX_CELL_TYPE_CONTRACT.md)
hält die konkrete Semantik und getrennte private Framework-/technische
Hostevidenz fest. Root prüfte und schloss anschließend den konkreten
Vertragsfreeze; die Sourceumsetzung dieser V3-Welle ist freigegeben.
Die ausgewählte Modul-Runtimequalifikation ist erfolgreich; öffentlicher
Adapterport ist erfolgreich; aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Anzeigeformatierung
bleibt eine separate bereits freigegebene Welle.
Zusätzliche konkrete Freigabe 2026-10-02: Der Benutzer antwortete auf die
separate Lifecyclefrage „Ja, XLSX-Lifecycle-Sichtbarkeitsgate freigeben“.
Vorhandenes Datenbank-VIEW DEFINITION und SELECT auf
sys.sql_expression_dependencies werden vor Mutation und unter AppLock
verlangt; 0/NULL/unklar blockiert 51535/State 2. Keine Rechtevergabe.
Für beide Wellen gelten unabhängiger Review, synthetische Contract-/Grenztests,
scopebezogene Lab-Auswahl, erforderliche grüne CI und PR-Merge unverändert.
Neue fachliche Entscheidungen außerhalb dieses Scopes weiterhin rückfragen.
Der damalige Freigabeeintrag allein war kein Runtime-Nachweis. Der folgende
datierte Umsetzungsnachweis hält die tatsächlich geprüfte Typwelle getrennt
von Anzeigeformatierung und den anderen freigegebenen Wellen fest.

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

### Individuell freigegebene Ergänzungen: Jaro-Winkler, Paarvergleich und gruppiertes JSON
Konkrete zusätzliche Jaro-Providerfreigabe 2026-10-03: Nach Besprechung der
Scalar-Sourceownership, Varianten, Profile, Binary-/Versions- und vollständigen
Distanz-/Lifecycle-Regressionswirkung antwortete der Benutzer ausdrücklich
„Ja, bestehende Assembly auf 1.1.0 erweitern“. Dies autorisiert genau die
additive Jaro-TVF und den internen Transport im vorhandenen SAFE-Provider
`toolbelt.string.edit-distance` 1.1.0 (vier auf sechs Slots), gemeinsame interne
`UnicodeScalar`-Source und neuen exakten Releasehash. Levenshtein/OSA-Verträge
bleiben unverändert. Keine neue Assembly, SVF, Paar-/Phonetik-API. Der
[Jaro-Vertrag](../Documentation/Architecture/JARO_WINKLER_CONTRACT.md) ist vor
Source festgehalten. Neue 1.1-/genuine 1.0-Builds, vollständige Frameworkregression
und beide IL-Metadatengates bestanden separat. Die privaten 1.1-Gesamtadapter
bestanden am 2026-10-03 auf Linux 2019/latest CL150 und Windows 2025/CU8
CL150/160/170 lokal/zentral sowie mit SC-UTF8-Consumer: genuine Upgrades,
Runtime-/Client-/Lifecycle- und eigene DB-/Trustbereinigung samt frischem
unabhängigem Audit. Doomed-Guards qualifizieren den vollständigen originalen
Firstbatch in einer eigenen DB-Prozedur, keinen vollständigen SQLCMD-Lauf.
Keine Konfigurations-, Rechte-, Owner- oder Infrastrukturänderungen.
Minimalrechte, weitere Ziele und Heap bleiben offen; aktuelle CI separat am
PR-Head. Teilweise validiert, unveröffentlicht; historische 1.0-Evidenz getrennt.

Benutzerfreigabe 2026-10-01: Nach Besprechung der folgenden vier konkreten
Funktionen bestätigte der Benutzer die ausdrückliche Implementierungsfrage
mit „ja“. Diese vier APIs sind einzeln freigegeben, zusätzlich zu den oben
dokumentierten Wellen; keine pauschale Backlogfreigabe.

- `TVF_JaroWinklerSimilarity`: Wert 0 bis 1, identisch 1; festes Präfixgewicht
  0,1, höchstens vier Präfixzeichen, Bonus nur bei Jaro-Wert über 0,7.
  Gemeinsame Unicode-/Normalisierungsgrundlage der Distanzfunktionen;
  NULL-Eingabe ergibt NULL, zwei leere Texte 1. Begrenzte Standard-/Large-
  Profile, keine Abschneidung oder Näherung.
- `USP_CompareTextPairs`: caller-lokale #Temp mit eindeutiger PairOrdinal,
  LeftText und RightText. Expliziter Algorithmus Levenshtein, OSA oder
  Jaro-Winkler; Ausgabe PairOrdinal, Distanz beziehungsweise Ähnlichkeit
  und Status. Bestehende Vergleichskerne wiederverwenden, Standard-USP-
  Vertrag. Begrenzte Zeilen-/Text-/Arbeitsbudgets, vollständige Verarbeitung
  vor ResultTable-Mutation. Keine automatische Kreuzkombination, kein
  verstecktes Ranking oder automatisches Duplikatzusammenführen.
  Ergänzende Vor-Source-Freigabe 2026-10-03: Der Benutzer bestätigte die
  gesondert besprochene eigene Modul-/Hash-/Lifecycle-Sichtgrenze mit
  „das passt für mich so“. Die ausdrücklich wiederaufgenommene autonome
  Umsetzung bestätigt die fünf konkreten Zusatzentscheidungen. Der
  [kanonische Vertrag](../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md)
  legt elf Parameter, signed bigint Ordinals, fünf Ergebnisfelder, konservative
  globale Budgets und gleiche bekannte Dependencies fest. Keine neue Assembly.
  `toolbelt.string.text-pairs` 1.0.0 ist implementiert, teilweise validiert und
  unveröffentlicht. Fünf öffentliche SQL-Fixtures sowie Lifecycle-Wiederholungen
  bestanden auf Linux 2019/latest CL150 local und Windows 2025/CU8 CL170 local.
  Ein separater zentraler Windows-Lauf bestand InstalledMetadata, drei direkte
  Clientconsumer, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-
  Bestätigung mit Katalogerhalt und eigene Bereinigung; unabhängig physisch
  geprüft am 2026-10-04. Minimalrechte, weitere Lifecycle-Negativfälle, Ziele
  und aktuelle PR-Head-CI bleiben getrennt offen.
- `USP_JsonArraysByGroup` und `USP_JsonObjectsByGroup`: bestehender Entries-
  Vertrag plus positive GroupOrdinal; ein JSON-Ergebnis je vorhandener
  Gruppe, Entry-Ordinal bestimmt Reihenfolge. Duplicate Keys innerhalb
  einer Gruppe Fehler. Gemeinsame ValueKind-/Unicode-/Escapingkerne und
  Ressourcenverträge wiederverwenden; Gesamtbudget über alle Gruppen,
  keine Teilmutation bei Fehler. Kein dynamischer SQL-Eingabetext und keine
  Typinferenz. Gruppierte USPs, keine direkt in GROUP BY verwendbaren
  SQL-Aggregatobjekte.

Status: `ready for development`; keine Implementierungs-/Runtime-Evidenz.
Technische SQL-Typen, NULL-/Fehlerprioritäten, exakte Grenzen und Kopplung
innerhalb dieses Scopes vor Sourceumsetzung dokumentieren und qualifizieren.
Neue fachliche Entscheidungen rückfragen. Unabhängiger Review, scopebezogene
Lab-Tests, erforderliche grüne CI und PR-Merge gelten unverändert.

Vor-Source-Präzisierung 2026-10-02, Codex: Für ausschließlich die beiden
gruppierten JSON-USPs konkretisiert der
[kanonische Vertrag](../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md)
Signaturen, globale Budgets, Resultschemas, Fehlerpriorität und notwendige
gekoppelte Lifecycle-Grenzen. Vorbereitung `active`; technisches Vor-Source-Gate
nach unabhängigem Kandidatenreview und Rootreview abgeschlossen, Umsetzung offen.
Einzelfreigabe 2026-10-02: Der Benutzer bestätigte ausdrücklich, dass JSON-Uninstall fehlende Metadatensichtbarkeit mit `53622/1` blockieren und vorhandenes Datenbank-`VIEW DEFINITION` sowie `SELECT` auf `sys.sql_expression_dependencies` voraussetzen darf. Keine Berechtigungserteilung. Die neue Gateumsetzung wird vor Dependencyabfrage im Preflight und erneut unter AppLock geprüft; neue gekoppelte CI und tatsächliche Minimalrechte bleiben getrennte Nachweise.

Umsetzungsstand 2026-10-02, Codex: `toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt. Dies ändert nicht den Status der weiteren einzeln freigegebenen Funktionen dieses Abschnitts.

111 private Assertions betreffen ausschließlich Gruppen vorvalidierter
synthetischer Fragmente, keine SQL-/Escaping-/Lifecycle-Validierung.

Zusätzlicher Benutzerauftrag 2026-10-01: „berücksichtige aber auch
CLR-Aggregate zusätzlich!“ Deshalb portable SQL-CLR-JSON-Array-/Object-
Aggregate ergänzend zu den USPs ausarbeiten, nicht durch diese ersetzen.
Nach anschließender Einzelbesprechung bestätigte der Benutzer am 2026-10-01
ausdrücklich „ja, freigegeben“ zur Implementierung der beiden Aggregate
einschließlich Namenskonvention und gemeinsamer Kernumstellung:

- `AGF_JsonArray` und `AGF_JsonObject` sind echte, direkt in SELECT/GROUP BY
  verwendbare JSON-Aggregate; Namenskonvention `AGF_{CamelCase}` für diese
  Objektart ausdrücklich freigegeben und im Namingstandard zu verankern.
- Eingaben explizite Ordinal, ValueKind, Value; Object zusätzlich Key.
  Reihenfolge nur über Ordinal, niemals SQL-Verarbeitungsreihenfolge.
  Doppelte Ordinals Fehler. Bestehende JSON-Regeln: explizites JSON-null,
  doppelte Object-Keys Fehler. Ergebnis nvarchar(max), leere Aggregation
  [] beziehungsweise {}.
- Begrenzte Profile für Einträge, Ergebnis und serialisierten Zwischenzustand
  je Gruppe; kein Unlimited und keine globale Speicherzusage über alle Gruppen.
- SAFE, memory-only, keine Datei-/Netzwerkzugriffe. Windows-/Linux-
  Qualifikation einschließlich Merge und Serialisierung von Teilzuständen.
- Gemeinsamer kanonischer JSON-Kern für Aggregate und Konstruktoren;
  erforderliche interne Kernumstellung mit vollständigen Regressionstests,
  öffentliche USP-Verträge unverändert. Kein zweiter ungeprüfter Escapingkern.
- Konkrete Typen/Profile/NULL-/Fehlerprioritäten und serialisierte Zustands-
  kodierung vor Sourceumsetzung dokumentieren, Grenzen synthetisch qualifizieren.
  Kein SDK-/Workerfallback, keine Rechteausweitung oder Veröffentlichung.

Status CLR-Aggregate: `ready for development`; keine Runtime-Evidenz.
Die bestehenden freigegebenen Wellen laufen unabhängig weiter.

Fortsetzung 2026-10-03: Die drei zusätzlichen Lifecyclegrenzen (exakte
Assemblymarkertypen, geschlossenes unabhängig qualifiziertes Binaryregister
und kohärente vorhandene Eigentümer ohne Rechte-/Owneränderung) wurden
einzeln genehmigt. Der konkrete
[JSON-1.2-Vertrag](../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md)
und seine tatsächliche Registryzeile wurden vor Source unabhängig geprüft.
Der bekannte Produktbuild ist ausschließlich offline qualifiziert;
Sourceumsetzung und native Migration-/Caller-/Lifecyclequalifikation bleiben
getrennte Gates. Historische 1.0-/1.1-Nachweise bleiben unverändert.

### Individuell freigegebene Tabellenklon-Ausbauwellen 1 und 2

Benutzerfreigabe 2026-10-01: Nach Besprechung des begrenzten Script-only-V1
und der folgenden Ausbaustufen bestätigte der Benutzer die ausdrückliche
Empfehlung, Wellen 1 und 2 als Nächstes konkret freizugeben, mit
„ja, das passt so“. Keine Freigabe für Trigger, automatische Ausführung,
Datenkopie oder beliebige weitere Objektklassen.

- Welle 1: bestehende Script-only-Tabellenstruktur erweitern um berechnete
  Spalten einschließlich PERSISTED, gefilterte Rowstore-Indizes und optional
  Extended Properties. Nicht unterstützte Eigenschaften sichtbar ablehnen,
  niemals stillschweigend weglassen. Keine Scriptausführung durch die API.
- Welle 2: Foreign Keys und mehrere zusammengehörige Tabellen mit expliziter
  Quell-/Zieltabellenzuordnung. Beziehungen zwischen geklonten Tabellen und
  Selbstreferenzen zeigen auf neue Ziele. Referenzen auf nicht geklonte
  Tabellen bleiben nur bei ausdrücklich gewählter Regel bestehen. Erst
  Tabellen, dann Foreign Keys skripten, auch zyklische Beziehungen beachten.
- Vor Sourceumsetzung konkrete Parameter, Mappingtransport, Ergebnisordinals,
  Typ-/Index-/Propertygrenzen und FK-Regeln innerhalb dieses Scopes schriftlich
  konkretisieren; neue fachliche Entscheidungen rückfragen. Keine stillschweigende
  CrossDB-, Trigger-, Permissions-, Spezialtabellen- oder Mutationsausweitung.
- Bestehenden Klonkern wiederverwenden; V1 zuerst unabhängig prüfen und
  integrieren. Erweiterungen in getrennten überprüfbaren Wellen mit synthetischen
  Strukturoracles, scopebezogenen Lab-Tests und grünen PR-Merges integrieren.

Historischer W1-Stand: `implemented`, `partially validated`, `unreleased`; Welle2 war zu diesem Zeitpunkt getrennt und nicht implementiert. Der aktuelle W2-Stand folgt im datierten V3-Absatz.

Änderungsvermerk 2026-10-02 — Codex: Die zusätzliche Benutzerantwort
„Tabellenkopf Welle1 Ja“ bestätigt für Welle 1 `@IncludeExtendedProperties`
vor dem Standardtail (bisherige Positionen 6..9 werden 7..10) und sieben
einzelne `SESSION_OPTION`-Zeilen vor `TABLE`. Der
[Vor-Source-Reviewvertrag](../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md)
plant deshalb eine kohärente Modulversion 2.0.0 mit denselben zwei USP-Slots,
keinen neuen fachlichen APIs und unverändertem ScriptOnly-Scope.
Das Computed-only-Voraussetzungsgate für vorhandenes SELECT auf
`sys.sql_expression_dependencies` ist eine zusätzliche konkrete
Vertragsgrenze; die JSON-Uninstall-Freigabe wird nicht auf Clone übertragen.
Zusätzlich ist ausschließlich für EXTENDED_PROPERTY eine Zeile als
typisierter DECLARE+EXEC-Batch statt einer einzelnen Anweisung vorgeschlagen.
Nach gesonderter konkreter Besprechung bestätigte der Benutzer am 2026-10-02
„beides ja“ für das Computed-only-Gate mit 53901/3 und die begrenzte
EXTENDED_PROPERTY-Batchausnahme. Der vollständige Vertrag und die gekoppelten
Discovery-/Backlogänderungen wurden vor Source unabhängig durch Root geprüft;
das Sourcegate ist geschlossen. Der nachfolgende W1-Nachweis ist separat dokumentiert; Welle 2 bleibt
unverändert getrennt.

### TC-2026-034 / TC-2026-039 / TC-2026-040 / TC-2026-042 / TC-2026-044: Freigegebene Reservewellen

Benutzerfreigabe 2026-10-01: Nach der Einzelbesprechung der beiden
ZIP-Datei-USPs bestätigte der Benutzer „ZIP passt“ und nahm Range sowie Date
Shifting in die Planung auf. Anschließend wurden vier weitere APIs mit
konkreten Verträgen einschließlich Lookup und Script-only-Tabellenklon
besprochen. Auf die ausdrückliche Frage nach Implementierung, Prüfung und
PR-Merge aller vier sowie der beiden ZIP-Datei-USPs antwortete er:
„ja, ich gebe das alles frei“. Diese sechs Funktionen sind einzeln
freigegeben; keine pauschale Freigabe weiterer Backlogthemen.
Status: `ready for development`; noch keine Implementierungs-/Runtime-Evidenz.

#### ZIP-Datei-I/O: zwei Windows-Fassaden

Umsetzung 2026-10-04: [toolbelt.archive.zip-files 1.0.0](../Modules/toolbelt.archive.zip-files/README.md)
implementiert ausschließlich diese zwei freigegebenen T-SQL-Fassaden.
[Vertrag](../Documentation/Architecture/ZIP_FILES_CONTRACT.md), Signaturen,
ResultTable-Brücken und neue technische Fehler 54620–54624 sind gekoppelt.
Genau drei feste Brücken-Temps wurden für den bestehenden ResultTable-
Interoperabilitätskonflikt ausdrücklich genehmigt; keine Core-/Provideränderung.
Begrenzte native Teilnachweise auf Windows2025/CU8 CL170 local: elf frühere
erfolgreiche Fälle und zwei gezielt erfolgreiche AppLock-Aliasfälle mit identischen
Produktbytes; kein gemeinsamer 13-Fälle-Erfolgslauf. Eigene Bereinigung frisch geprüft.
Vollständige NTFS-/Rechte-/Race-/Zielmatrix- und aktuelle Head-CI-Qualifikation offen;
partially validated, unveröffentlicht.
Die übrigen Reservefunktionen in diesem Abschnitt bleiben getrennt.


- `USP_CreateZipFileFromEntries`: bestehender Entries-#Temp-/Writervertrag,
  dann kontrolliertes Schreiben des vollständigen Archiv-Binary.
- `USP_ExtractZipEntryToFile`: ZIP-Binary und genau ein benannter Entry,
  dann kontrolliertes Schreiben; keine vollständige/rekursive Entpackung.
- Bestehende kanonische ZIP-/Filesystemkerne wiederverwenden, kein zweiter
  ZIP-Algorithmus. Windows-only zunächst; kein impliziter Linux-/Workerfallback.
- Konfigurierter Root-Alias und relativer Dateipfad, Caller als Default,
  ServiceAccount nur ausdrücklich gewählt. Overwrite Default aus, vorhandene
  Datei Fehler. Zielverzeichnisse müssen bestehen; keine automatische Anlage.
- Erst vollständige temporäre Datei, dann kontrollierte Veröffentlichung;
  keine teilweise sichtbare Zieldatei. Fehler dürfen bestehende Zieldatei
  nicht beschädigen. Geforderte Atomarität tatsächlich nachweisen, sonst
  nur diesen Zweig blockieren, kein unsicherer Direct-Write-Fallback.
- Aktive Caller-SQL-Transaktionen zunächst ablehnen, weil Dateischreiben
  nicht durch SQL-Rollback rückgängig wird. Bestehende ZIP-Ressourcenlimits,
  kein Unlimited. Standard-USP-Vertrag; Ausgabe nur Metadaten wie BytesWritten,
  RootAlias, RelativePath, State, kein zusätzliches Archive-Binary.
- Konkrete öffentliche Schemas, Ressourcennamen und Fehlernummern sind
  technische Konkretisierung innerhalb dieses Scopes; keine neue Identitäts-,
  Pfad-, Trust- oder Infrastrukturfreigabe. Tests nur synthetische Fixtures
  in ausdrücklich zulässigen Testroots, keine Lab-Infrastrukturverwaltung.

#### TVF_DeterministicRange

- Eingaben Key varbinary(max), positive MappingVersion int, Seed bigint=0,
  Min bigint und Max bigint. Nicht leerer Key höchstens 8.000 Bytes; keine
  automatische Case-/Collation-/Unicode-Normalisierung. Caller kodiert Text.
- Grenzen geschlossen, negative Bereiche und vollständiger bigint-Bereich.
  Gleiche Eingaben liefern versionsstabil denselben Wert; Änderung von Seed,
  MappingVersion oder Grenzen kann die Zuordnung ändern, nicht garantiert.
- SHA-256, eindeutig gerahmte versionsgebundene Bytekodierung und
  Rejection-Sampling statt einfacher Modulo-Verzerrung. Höchstens 128 Versuche,
  danach expliziter Fehler; kein unbegrenztes Wiederholen.
- Eine Ergebniszeile Value bigint und ErrorCode. NULL-Key ergibt NULL-Wert
  ohne Fehler; ungültige Konfiguration Fehlercode und kein Wert. Technische
  Fehlerprioritäten, Byteformat und Testvektoren dauerhaft dokumentieren.
- Keine Secrets, persistierten Mappings, Eindeutigkeits-, Kryptografie- oder
  Anonymisierungsgarantie. Portabler T-SQL-Kern bevorzugt; keine neuen CLR-/
  externen Provider ohne gesonderte Autorisierung.

#### TVF_DeterministicDateShift

- datetime2(7), Entitätsschlüssel nach Rangevertrag, MappingVersion, Seed und
  MaxDays int=365. Bereich inklusiv [-MaxDays,+MaxDays]; MaxDays von 0 bis
  3.652.058. Ein kanonischer Range-Kern, keine zweite Hashimplementierung.
- Gleiche Entität bei identischen Parametern erhält denselben Tagesoffset;
  Uhrzeit/Präzision und zeitliche Abstände bleiben erhalten. MaxDays=0 identisch.
- Datentypüberlauf ist Fehler, kein Clamp/Wraparound. Keine Zeitzonen-/DST-
  Behandlung oder separate Offset-Diagnoseausgabe.
- Eine Ergebniszeile Value datetime2(7), ErrorCode. NULL-Zeitwert oder -Key
  ergibt NULL ohne Fehler; Konfiguration und Grenzen sonst strikt prüfen.

#### USP_DeterministicLookup

- Zwei caller-lokale #Temp-Tabellen: Eingaben Ordinal/Key, Pool Ordinal/Value.
  Ordinals positiv/eindeutig mit zulässigen Lücken; Auswahl aus nach Ordinal
  geordnetem Pool. Schlüssel nach Rangevertrag, Pooltext Unicode.
- MappingVersion, Seed und ausdrücklich gewählte LookupVersion gehören zum
  Mappingkontext. Unveränderter Pool/gleiche Eingaben liefern gleiche Auswahl.
  Pooländerung benötigt neue LookupVersion; kein Speichern/Überwachen früherer
  Pools. Keine Eins-zu-eins-Zusage; verschiedene Keys dürfen dasselbe erhalten.
- Ausgabe InputOrdinal, LookupOrdinal, Value, keine Originalkeys. Leerer Pool
  Fehler; NULL-Key erzeugt NULL-Zuordnung. Standard-USP-Vertrag, vollständige
  Prüfung vor ResultTable-Mutation; gemeinsame Range-Grundlage.
- Default je 10.000 Eingabe-/Poolzeilen, Ceiling je 100.000. Pooltext Default
  2 MiB/Ceiling 16 MiB; Ergebnistext höchstens 16 MiB. Keine Anonymisierungs-
  oder Re-Identifikationsschutzbehauptung, keine realen Daten als Testartefakte.

#### USP_ScriptTableClone

Stand2026-10-04, Codex: Die am2026-10-03 konkret bestätigte W2-Erweiterung umfasst Map-/FK-Planung, PositionsbruchV3 und failclosed FK-EP-/Stategrenzen. [Kanonischer V3-Vertrag](../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md). W2 implementiert, teilweise validiert und unveröffentlicht. Begrenzte lokale Linux2019/latest CL150-/Windows2025/exakt CU8 CL170-Lifecycle-/Upgrade-/resolved-Consumer-Nachweise samt frischer Bereinigung bestanden. Linux-Fixtures werden nur als Teilnachweis eines historischen insgesamt fehlgeschlagenen Laufs wiederverwendet; Windows vier Fixtures einmal im aktuellen Clean3. Unresolved NOT_ESTABLISHED, vollständige Qualifikation und aktuelle Head-CI offen. Die folgenden ursprünglichen V0-Grenzen bleiben historischer Ausgangsscope, keine neue W2-FK-Ablehnung.

- Script-only-Planer für explizite Quell-/Ziel-Schema-/Tabellennamen in
  derselben Datenbank, reguläre diskbasierte Tabellen. Keine DDL-Ausführung,
  Datenkopie, datenbankübergreifende Quelle oder automatische Recovery.
- Spalten, Nullability, Defaults, Checks, Primary-/Unique-Constraints und
  gewöhnliche Rowstore-Indizes. Identity optional übernehmen, keine Daten
  oder aktuellen Identity-Zähler.
- Keine Foreign Keys, Trigger, Rechte, Extended Properties, Computed-/Sparse-
  Spalten oder Temporal-/Ledger-/Graph-/Partitionierungsfeatures. Nicht
  unterstützte Eigenschaften sichtbar melden; kein stilles Weglassen mit
  behaupteter Vollständigkeit. Exakte Typ-/Indexgrenzen technisch dokumentieren.
- Geordnete Zeilen: Reihenfolge, Objektart, Zielname, DDL-Text.
  Deterministische kollisionsgeprüfte Namen, Identifierquoting und kein
  Überschreiben existierender Ziele. Standard-USP-Vertrag; komplette Vorschau
  vor Ausgabe. Plan ist eine Momentaufnahme, keine spätere Driftfreiheit.
- Tests erzeugen/führen ausschließlich synthetische Test-DDL aus und
  vergleichen Strukturen. Produktive API führt niemals den Scripttext aus.

#### Reihenfolge und Ausweicharbeit

Bereits aktive Regex-/JSON-/XLSX-Wellen zuerst unabhängig fortsetzen. Bei
freien Agent-Slots Range vor DateShift/Lookup; Scriptplaner unabhängig;
ZIP-Datei-I/O abhängig von qualifiziertem Filesystem-/Atomaritätsnachweis.
Blocker stoppen ausschließlich abhängige Zweige. Agents melden sofort,
Orchestrator prüft unabhängig und integriert grüne konsistente Stände über
PR nach origin/main samt Branchcleanup. Keine Veröffentlichung, zusätzlichen
fachlichen Funktionen oder Privilegien-/Lab-Infrastrukturänderungen.

### TC-2026-010 / TC-2026-009 / TC-2026-045: Freigegebene nächste Entwicklungswellen

Benutzerfreigabe 2026-10-01: Nach Besprechung von Zweck, öffentlichen
Verträgen, Alternativen, Risiken und Scope bestätigte der Benutzer zuerst
Regex ohne Captures, JSON über caller-lokale #Temp und einen eigenen begrenzten
SAFE-ZIP-/XML-Kern für XLSX mit „ja, das passt so“. Anschließend wurden die
folgenden sechs APIs und Detailverträge einzeln benannt; auf die ausdrückliche
Frage nach Implementierung, Prüfung und PR-Merge antwortete er „ok, passt so“.
Nur diese Funktionen sind damit freigegeben, keine weiteren fachlichen APIs,
Datei-I/O-, Capture-, SDK-/Worker-, Rechteausweitungs- oder Release-Slices.
Status: `active`; Regex R2b ist implementiert und im ausgewählten Lab-Scope
geprüft und über PR #127 integriert. JSON ist implementiert und im ausgewählten
Lab-Scope geprüft; XLSX bleibt eine getrennte aktive Welle.

#### Regex R2b: Gesamttreffer und Split

Stand 2026-10-01: Version 1.2.0 implementiert; vollständiger Adapter auf
SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 PASS.
Unabhängiger Source-/Contract-/Lifecycle-Review sowie reproduzierter
Framework-/Static-Vertrag erfolgreich; erforderliche PR-CI grün und über
[PR #127](https://github.com/gecompat/SQL_Server_Toolbelt/pull/127) integriert.
Weitere R2b-Ziele, Lowpriv-CrossDB und SQL-100k-Durchsatz bleiben offen.
Modulstatus `partially validated`, `unreleased`; keine Capture-Freigabe.

- `toolbelt_string.TVF_RegexMatches`: Input/Pattern `nvarchar(max)`, Start,
  bestehende Flags, Profil und MaxRows. Ergebnis `Ordinal bigint`,
  `StartPosition bigint`, `Length bigint`, `Value nvarchar(max)`.
  NULL-Input/Pattern oder kein Treffer: keine Zeilen. Leere Treffer gültig.
- `toolbelt_string.TVF_RegexSplit`: Input/Pattern, Flags, Profil und MaxRows;
  kein Startparameter, immer ganze Quelle. Gleiches Ergebnisschema; Treffer
  sind nicht ausgegebene Separatoren. Kein Treffer: gesamte Quelle als Token;
  leere Quelle ohne Separator-Treffer: ein leeres Token. Leere Rand-/
  Zwischentokens erhalten. NULL-Input/Pattern: keine Zeilen.
- Ordinals und Positionen 1-basiert, UTF-16-Codeeinheiten; keine Überlappung,
  Captures, Backreferences oder Entquotierung. Leere Separator-Treffer
  konsumieren kein Zeichen; Suche rückt eine Codeeinheit weiter.
- Bestehender Dialekt und R2a-Profile: Pattern 8.000 Codeeinheiten,
  standard 2 MiB/500 ms, large 16 MiB/2.000 ms. Ergebnistextsumme durch
  Profil begrenzt. MaxRows Default 10.000, Ceiling 100.000. Keine implizite
  Profilaufwertung, Truncation oder Unlimited-Option. Vollständige Prüfung/
  Materialisierung vor Zeilenausgabe; Vertragsfehler oder Timeout ohne
  verwertbare Teilmenge. Vorhandene R1b/R2a-Verträge unverändert.

#### JSON Slice B: getrennte Konstruktor-USPs

Stand 2026-10-01: `toolbelt.json.constructors` 1.0.0 implementiert.
Vollständiger finaler Adapter auf SQL Server 2019 Linux/latest und 2025
Windows/CU8 erfolgreich, einschließlich TF-Drift-Reparatur, reserviertem
Caller-Tempnamespace vor Core-Kompilierung, Help-Bypass und tatsächlichen
Client-LOB-Metadaten. Unabhängige Reviewbefunde korrigiert und in beiden
finalen Läufen geprüft. Modulstatus `partially validated`, `unreleased`;
weitere Ziele, gemappte CrossDB-Minimalrechte und Produktionskapazität offen.

- `toolbelt_json.USP_JsonArray` und `toolbelt_json.USP_JsonObject`:
  EntriesTable für caller-lokale #Temp, Ressourcenparameter und vollständiger
  Standard-USP-Vertrag. Dieser ausdrücklich gewählte Transport ersetzt
  prospektiv den bisherigen Table-Type-Vorschlag.
- Ordinal int positiv/eindeutig, Lücken erlaubt; ValueKind nvarchar(max)
  exakt string/number/boolean/null/json und Value nvarchar(max). Object
  zusätzlich Key nvarchar(max): nicht NULL/leer, höchstens 1.024 Codeeinheiten.
- string vollständig escapen; number strikte JSON-Literalgrammatik ohne
  Culturekonvertierung; boolean exakt true/false; null verlangt SQL-NULL und
  erzeugt JSON-null; json nur validiertes vollständiges Objekt/Array.
  Sonstige SQL-NULL-Werte und ungültige Unicode-Surrogatfolgen sind Fehler.
- Binär längensensitive unveränderte Keys, kein Trim/Normalisieren; doppelte
  Keys Fehler. Ordinalreihenfolge; leere Tabelle ergibt [] bzw. {}. Ergebnis
  genau eine Zeile/Spalte JsonValue nvarchar(max). Keine Typinferenz, Pretty
  Print, Ausführung, JSON-Patch oder Aggregate.
- Default 10.000 Einträge, jeweils 2 MiB Gesamtwert-/Ergebnistext; explizite
  Ceilings 100.000 und 16 MiB. Positive Grenzen, kein Unlimited. Vollständige
  Konstruktion vor ResultTable-Mutation, ein gemeinsamer Escaping-/Prüfkern.

#### XLSX: bedingt freigegebene Binary-Reader

- `toolbelt_file.USP_ListXlsxWorksheets`: Binary-Eingabe; SheetOrdinal,
  SheetName, Visibility, Date1904.
- `toolbelt_file.USP_ReadXlsxWorksheetCells`: Binary plus positiver
  SheetOrdinal; nur vorhandene Zellen, nach Zeile/Spalte geordnet. Ergebnis
  RowOrdinal, ColumnOrdinal, StoredType, ValuePresent, RawValue, TextValue,
  FormulaPresent, FormulaText, FormulaKind, SharedFormulaIndex, CachePresent,
  CacheValue. Fehlender SheetOrdinal ist Fehler; fehlende/leere Inhalte
  unterscheidbar. Keine Rechteckauffüllung, Shared-Formula-Expansion,
  Formelberechnung, Typinferenz, Styles-/Datums-/Anzeigeformatierung.
- NULL-Binary: keine Zeilen. Beschädigte/nicht unterstützte Inhalte: Fehler,
  keine stille Zellüberspringung. Standard-Hilfe/ResultTable; gewähltes
  Ergebnis vollständig vor Ausgabe. Sheetliste ist kein Vollnachweis aller
  nicht gelesenen Zellparts.
- Qualifizierungsgrenzen: 16 MiB Archiv, 64 MiB entpackt, 16 MiB je Part,
  256 Parts, 32 Sheets, 100.000 Zellen, 50.000 Shared Strings/8 MiB Text,
  XML-Tiefe 64, Ratio 200. Ressourcenparameter zunächst nur reduzierend;
  höhere Grenzen benötigen separate Qualifikation/Freigabe. Kooperatives
  Parserbudget 5 Sekunden, keine harte SQL-Wallclockzusage.
- Eigener begrenzter ZIP-/XML-Kern unter Wiederverwendung des kanonischen
  ZIP-Parsers. Vor öffentlichen APIs SAFE-/Memory-only-Qualifikation; keine
  DTDs, externen Beziehungen, Makros, Datei-/Netzwerkzugriffe, SDK-Beschaffung,
  externe Worker oder Hochprivilegierung. Bei gescheiterter Qualifikation
  wird nur XLSX blockiert, unabhängige freigegebene Wellen laufen weiter.
- XLSX-Schema/Modulzuordnung und noch nicht benannte technische Details sind
  Umsetzungsvorschläge, keine zusätzliche fachliche Scopeausweitung.

#### Ausführung und Nachweise

Agents melden Fertigstellung sofort an den Orchestrator. Je kohärenter Welle
unabhängiger Review, synthetische Contract-/Grenz-/Lifecycle-Tests,
risikobasierte SQL_Server_Lab-Auswahl (anfangs 2019 Linux/2025 Windows),
grüne erforderliche CI und PR-Merge nach origin/main; Branchcleanup.
Keine Lab-Infrastrukturverwaltung oder pauschale Matrix-/Kapazitätszusage.
Ein Blocker hält andere freigegebene unabhängige Wellen nicht an.
ZIP-Datei-I/O und weitere Reservefunktionen werden separat besprochen.

### Testkonfiguration für die freigegebenen Wellen

Benutzerfreigabe 2026-10-01: Zunächst wurden notwendige Parameteränderungen
am Testziel ausdrücklich beauftragt. Nach Besprechung eines Konflikts durch
ausstehende Serverkonfiguration bestätigte der Benutzer: „du kannst die
Testsysteme so konfigurieren, wie du willst verfüge frei darüber“.
Die kanonische Abgrenzung, Koordination, Sicherheits- und
Wiederherstellungsregeln stehen in [AGENTS.md](../AGENTS.md#autorisierte-sql-testparameter).
Dies ist eine Testkonfigurationsfreigabe, keine zusätzliche fachliche API,
Veröffentlichungsfreigabe oder Lab-Infrastrukturverwaltung. Dieser Eintrag
behauptet keinen ausgeführten Runtime-Test und keine erfolgte Konfigurationsänderung.

### TC-2026-032 / TC-2026-034: Freigegebene Unquoting-, Split-USP- und ZIP-Writer-Folgeslices

| Feld | Wert |
|---|---|
| Referenzen | Vorhandene Kandidaten `TC-2026-032` und `TC-2026-034`; keine neue sequenzielle `AP`-Referenz. |
| Benutzerfreigabe | Nach Besprechung von Zweck, konkreten Verträgen, Alternativen, Risiken und Scope hat der Benutzer am 2026-10-01 die Implementierung der drei einzeln benannten APIs `TVF_UnquoteToken`, `USP_SplitAdvanced` und `USP_CreateZipFromEntries` ausdrücklich freigegeben. Vertragsbasis ist [PR #121](https://github.com/gecompat/SQL_Server_Toolbelt/pull/121) mit `ADVANCED_STRING_SPLIT_PROPOSAL.md` und `ZIP_CREATION_PROPOSAL.md`. Die nachfolgend erhaltenen Vorfreigabebesprechungen sind historisch; dieser Nachtrag aktiviert ausschließlich diese drei Folgeslices. |
| Zweck und Scope | `toolbelt_string.TVF_UnquoteToken` entfernt nur ein gültiges äußeres Paar und dekodiert innere doubled closing Qualifier sowie ausdrücklich aktivierte begrenzte Backslash-Escapes. `toolbelt_string.USP_SplitAdvanced` ist die ResultTable-/Help-Fassade des vorhandenen TVF-Kerns ohne automatisches Unquoting. `toolbelt_archive.USP_CreateZipFromEntries` erzeugt ein begrenztes In-memory-ZIP aus caller-lokalen Entries über einen versionierten Binary-Envelope und einen reinen SAFE-CLR-Writer; Stored als Default, Deflate explizit. |
| Status | Alle drei APIs sind implementiert und im ausgewählten Lab-Scope geprüft. Split/Unquote 1.1.0 ist über [PR #122](https://github.com/gecompat/SQL_Server_Toolbelt/pull/122) integriert; ZIP 1.3.0 steht zum geprüften PR-Merge bereit. Beide Module bleiben `partially validated`, `unreleased`. |
| Dependencies und Grenzen | Kanonischer Split-Kern, bestehendes ZIP-Memory-Modul sowie ResultTable-Runtime für beide USPs; Dependency-Preflight vor Mutation. NULL-/Fehlerpriorität, UTF-16-/BIN2-Semantik, reservierter Außenrand, strikte Namenkodierung, begrenzte Ressourcen und atomare Ausgabe nach PR #121. Numerische Grenzen sind noch technisch zu qualifizieren; keine harte Echtzeit-, Streaming-, Parallelitäts- oder Deflate-Byteidentitätszusage. |
| Tests | Am 2026-10-01 besteht der erweiterte Split-/Unquote-Adapter auf SQL Server 2019 Linux/latest und 2025 Windows/CU8: synthetische Rand-, Fehlerprioritäts-, Grenz-, ResultTable-/Help-, Own-/Callertransaktions-, Local-/Central-, Kollisions- und Uninstall-Fälle sowie clientseitige Metadaten und lokale Minimalrechte. Der echte 1.0-zu-1.1-Upgrade verwendet den gepinnten historischen Installer und Originalsource. ZIP-SAFE-/Memory-/Interoperabilitätsnachweise bleiben getrennt. Kein pauschaler Cross-DB-Minimalrechte- oder vollständiger neuer Matrixnachweis. |
| Ausgeschlossen | XLSX-Reader, Datei-I/O, zusätzliche öffentliche APIs, Rechteausweitung und tatsächliche Veröffentlichung. Der separat freigegebene XLSX-Provider-Spike bleibt davon getrennt; verpflichtender späterer ZIP-Datei-I/O-Slice benötigt weiterhin seinen eigenen Sicherheitsvertrag und eine eigene Funktionsfreigabe. |
| ZIP-Evidenz | Am 2026-10-01: Framework-4.8-Build, unabhängiger ZipArchive-/CRC-/Headercheck und Staticvalidator erfolgreich; tatsächliche Framework-Grenzfixtures mit 32 MiB je Entry, 128 MiB Gesamtpayload, 1024 Entries und 2048 Namenscodeeinheiten. Vollständiger Lab-Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 erfolgreich: local/central, Metadaten, 16-MiB-Stored-/Deflate-Payloads, leere Payloads, Transaktionen, Fehleratomarität, echtes 1.2-Upgrade, Kollisionen und Uninstall. Keine Kapazitätszusage für Produktion, höhere SQL-Live-Grenzen oder beliebige Parallelität. |
| Nächster Schritt | ZIP-Writer nach unabhängigem Review und grüner CI über PR integrieren und gemergte Branches aufräumen. Danach ist diese Implementierungswelle abgeschlossen; weitere Funktionsslices bleiben getrennt. |

#### ZIP-Writer-Testintake: Wartungsnachtrag 2026-10-08 — Codex

Die Quellen des bestehenden Framework-Testadapters binden die ausgewählte DLL
über `ExpectedAssemblySHA512` aus dem vorhandenen Trustmanifest und ihre exakte
`ExpectedAssemblyLength`. Einmalige Aufnahme bis 4 MiB und eigene `CreateNew`-
Kopie koppeln Load und Compilerreferenz; der bestehende Workflow-Schritt und die
statische Vertragsprüfung werden entsprechend gepflegt. Keine neue öffentliche
API, Änderung der vorhandenen Freigabe oder zusätzliche synthetische Maxlast.
Die C#-Suite bleibt bytegleich. Dateien und Assembly werden behalten, nur eigene
Handles geschlossen. Neuer Intake/Frameworklauf **NOT_EXECUTED**; Modul weiter
`partially validated`, `unreleased`. Historische Evidenz und offene Matrix bleiben
erhalten; keine allgemeine Heap-, Laufzeit-, SAFE- oder Cleanupzusage.

### R2a: Regex-Substring und Regex-Replace mit LOB-Profilen

| Feld | Wert |
|---|---|
| ID | `R2a`; Slice zu `TC-2026-010`, keine neue sequenzielle Referenz |
| Zweck und Scope | `toolbelt_string.SVF_RegexSubstring` und `toolbelt_string.SVF_RegexReplace` nach dem konkretisierten Vertrag in `Documentation/Architecture/REGEX_EXTENSION_PROPOSAL.md`: Gesamttreffer, literal Replacement, keine Captures; gemeinsamer SAFE-CLR-Kern; Standard-/Large-Profil; Typ-/Codepage- und LOB-Grenzen. Bestehende R1b-Signaturen bleiben unverändert. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden am 2026-10-01 besprochen und in PR #114 konkretisiert. Auf die ausdrücklich benannte Freigabefrage für beide Regex-Funktionen und die Split-TVF antwortete der Benutzer: „ja, entwickle das und mach anschließenden PR-Merge“. Damit sind diese beiden Funktionen einschließlich scopebezogener Tests, gekoppelter Dokumentation und anschließendem geprüften PR-Merge freigegeben. |
| Status | `completed` für freigegebenen R2a-Scope; Version 1.1.0 `validated`, `unreleased` |
| Grenzen | 2-MiB-Standardprofil und 16-MiB-Large-Zielprofil, Pattern 8.000 UTF-16-Codeeinheiten; kooperative Budgets und Patternkomplexität müssen technisch qualifiziert werden. Keine harte Echtzeit-, Streaming-, Parallelitäts- oder Verarbeitung-bis-2-GB-Zusage. Verlustfreie Quellkonvertierung vor zentralem Aufruf; weitere Typwrapper nur bei belegtem Nutzen und abgestimmtem Vertrag. |
| Tests | R1b-Regression, neue NULL-/Start-/Occurrence-/Empty-Match-Semantik, Literal Replacement, Grenzwerte, Gesamtbudget, Ergebnisexpansion, Unicode/Codepages, konkurrierende LOB-Aufrufe, Trust, Upgrade, lokales/zentraltes Deployment und Uninstall. Lab-Matrix nach tatsächlichem Source-/Providerimpact. |
| Nächster Schritt | R2a implementiert und auf SQL Server 2019/2022/2025 Windows/Linux einschließlich echtem 1.0-zu-1.1-Upgrade, Standard-/Large-, Fehler-/Grenz-, Central-/Codepage-, Kollisions-/Rollback-, Parallelaufruf- und Lifecycle-Verträgen erfolgreich geprüft. T-SQL-Fassaden erhalten max-Defaults vor internen SAFE-CLR-Kernen; technischer SQL-CLR-Default-/Collation-Workaround dokumentiert. Keine automatische Freigabe für R2b, neue Captures oder Veröffentlichung. |

### S2: Erweiterter Split als verpflichtende TVF

| Feld | Wert |
|---|---|
| ID | `S2`; Slice zu `TC-2026-032`, keine neue sequenzielle Referenz |
| Zweck und Scope | `toolbelt_string.TVF_SplitAdvanced` nach `Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md`: mehrere Separatorstrings, Quote/Escape, Originaltokens, 1-basierte Ordinals und atomare Geschäftsfehlerzeile statt Teiltokens. |
| Benutzerfreigabe | Nach Vertragsbesprechung und Konkretisierung in PR #114 am 2026-10-01 ausdrücklich mit „ja, entwickle das und mach anschließenden PR-Merge“ freigegeben; die vorangehende Frage benannte `TVF_SplitAdvanced` einzeln neben den zwei Regex-Funktionen. |
| Status | `completed` für freigegebenen S2-Scope; Runtime `partially validated` |
| Grenzen | Pure-T-SQL-TVF; Inline-TVF-Alternative prüfen, MSTVF-Ausnahme technisch begründen. Input 65.536 UTF-16-Codeeinheiten, JSON-Rohtext 16.384, höchstens 16 Separatoren mit je 64 Codeeinheiten als zu validierende Grenzen. Fehlerpriorität, NULL-No-op, Originaltokens und fünf Resultspalten gemäß Vertrag. |
| Tests | Quote/Escape/Longest-Match, JSON-/Konfigurations- und Parserfehler, Fehlerpositionen/-priorität, keine Teiltokens, Ordinals, NULL/Empty/Trailing Spaces, Unicode/Collations, Grenzwerte, CROSS APPLY, lokales/zentraltes Deployment, Wiederholung, Kollision und Uninstall. |
| Nächster Schritt | TVF implementiert; vollständiger Adapter auf physischen SQL Server 2019 Linux und 2025 Linux/Windows erfolgreich. Weitere physische Zielkombinationen bleiben offen. Die GitHub-hosted Linux-Matrix SQL2019/2022/2025 bestand später auf [main](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386246931); sie ersetzt keine physische Zielprüfung. Risikobasierte Testauswahl; keine automatische Erweiterung der Testmatrix. Optionale USP, Unquoting, ZIP-Erzeugung, Datei-I/O und tatsächliche Veröffentlichung waren durch diese S2-Freigabe allein nicht autorisiert; spätere Einzelfreigaben stehen getrennt oben. |

### P1a: T-SQL Script Parser und AST-Provider

| Feld | Wert |
|---|---|
| ID | `P1a`; konkretisiert `TC-2026-047`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen deterministischen, rein lesenden In-Database-T-SQL-Parser auf Basis von Microsoft ScriptDom (.NET Framework 4.8) als SQL-CLR Table-Valued Functions (TVFs) für AST-Knoten, Knoteneigenschaften, Tokenstrom und Parse-Fehler bereitstellen. |
| Scope | Modul `toolbelt.tsql.script-parser` 1.0.0 mit `TVF_ParseScriptNodes`, `TVF_ParseScriptNodeProperties`, `TVF_TokenizeScript` und `TVF_ParseScriptErrors`. Schema `toolbelt_tsql`, Assembly `Toolbelt_Tsql_ScriptParser`. Keine automatische GUID-Ersetzung und keine semantische Namensauflösung im Kernmodul. |
| Provider | C# .NET Framework 4.8 Assembly mit ScriptDom-Integration, SHA2-512-Trust, kein Datenzugriff (`DataAccessKind.None`), harte Limits für Eingabegröße und Schachtelungstiefe. |
| Priorität | `P1` |
| Status | Historisch 1.0.0 `completed`/`validated`; die am 2026-10-01 separat freigegebene 2.0-Härtung ist `active`/`partially validated`, siehe [Nachfolgervertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). |
| Alternativen | Reiner T-SQL-Parser (nicht grammatikvollständig), reiner Tokenizer ohne AST, Stored Procedures mit Temp-Tabellen und externes Parsen außerhalb der Datenbank wurden verworfen. |
| Risiken und Grenzen | Windows-only/UNSAFE; iterativer Wächter vor ScriptDom und empirische Qualifikation sind keine universelle Stack-, Laufzeit- oder Heap-Garantie. Tokenize bleibt ausschließlich lexikalisch; AST-Funktionen parsen je Aufruf ohne veränderlichen Cache. |
| Benutzerfreigabe | Zweck, Signatur, Fehlervertrag, Risiken und Scope wurden am 2026-09-03 besprochen. Der Benutzer hat die Umsetzung anschließend mit „halte den Plan im Repository fest und starte im Anschluss mit der Implementierung“ ausdrücklich freigegeben. |
| Tests | Spike zu ScriptDom-Ladbarkeit, statische Vertragsprüfung, synthetische AST- und Token-Golden-Tests (SELECT, JOIN, CTE, MERGE, DDL, Kommentare, `GO`), Roundtrip-Tokens, Fehlerbehandlung, Lifecycle-, Deployment- und Kollisionstests. |
| Evidenz | `Documentation/Architecture/TSQL_SCRIPT_PARSER_MODULE_DESIGN.md`, `Documentation/Architecture/DECISIONS.md` (`DEC-2026-029`), `Backlog/TOOLBELT_CANDIDATES.md` (`TC-2026-047`). |
| Nächster Schritt | Die frühere 1.0-Abschlussgrenze gilt historisch. Nur die separat freigegebene 2.0-Härtung mit ehrlichen Qualifikationsgrenzen abschließen; weitere APIs benötigen jeweils Freigabe. |
| Nachtrag 2026-10-07 | Nach Besprechung des nicht mehr offiziell verfügbaren bisherigen ScriptDom-Binaries wählte der Benutzer ausdrücklich NuGet `Microsoft.SqlServer.TransactSql.ScriptDom` `180.117.0` zur Umsetzung und Qualifikation und beauftragte die Prüfung sowie Behandlung aller betroffenen CLR-Objekte. Der Scope umfasst den Parser, den gefundenen `toolbelt.metadata.table-clone`-Trigger-Opt-in-Consumer und die erneute Qualifikation; keine automatische Trustregistrierung oder Änderung von SQL-Server-Sicherheitskonfiguration. Siehe [Hardening-Vertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). |

### V0a/V0b/V0c: Releasevalidierung und erste Releasekohorte

| Feld | Wert |
|---|---|
| ID | `V0a`, `V0b`, `V0c`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die vorhandenen Module auf physischen Zielversionen und Windows validieren und daraus eine veröffentlichungsfertige erste Kohorte bilden, ohne Runtime- oder Release-Status vorwegzunehmen. |
| Scope | `V0a`: 24 portable beziehungsweise Linux-fähige Module auf SQL Server 2019/2022/2025 Linux. `V0b`: vollständige Windows-Matrix der V0c-Kohorte plus Hochrisikofälle für ResultTable, SQL CLR, Datei-I/O, Second Session und Event Log. `V0c`: 16 portable Module aus Kernfolge, W1, W2a, W2b-A und W2c. Keine neuen öffentlichen SQL-Objekte oder Signaturänderungen. |
| Dependencies | Ausdrückliche V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; schema-valider SQL_Server_Lab-Vertrag; entweder `groupStatus = READY` oder explizit ausgewählte Einzelziele mit `runtimeStatus = READY` und zulässigem Eintragsstatus; vorhandene Modul-, Lifecycle- und Testverträge. |
| Priorität | `P0` |
| Status | `active`; alle V0c-Pflichtgates abgeschlossen; tatsächliche Veröffentlichung benötigt eine ausdrückliche Entscheidung |
| Implementation Status | V0c: alle 16 Kohortenmodule `implemented`; der größere V0a-/V0b-Bestand ist ein separater Scope |
| Validation Status | V0c: alle 16 Module `validated`; die drei großen Lastfälle mit Ergebnisprüfung sind gemäß DEC-2026-036 erfolgreich, Laufzeitmessungen optional. Console Message ist für den bestehenden Enginevertrag einschließlich ADO.NET/ODBC geprüft. |
| Release Status | Alle 16 Kohortenmodule `unreleased`; keine tatsächliche Veröffentlichung autorisiert. |
| Akzeptanzkriterien | Linux- und Windows-Zielversionen tatsächlich geprüft; Dependency-Closure und versionierte Objektmanifeste konsistent; Erst-, Wiederholungs-, Upgrade-, Central- und Uninstall-Verträge für die Kohorte erfolgreich; modulspezifische Pflichtfälle ausgeführt; nicht verfügbare Kombinationen sichtbar; vollständiger Dokumentationsaudit erfolgreich. |
| Tests | `Tests/CI/run-lab-local.ps1` mit `TestSuite=full`; getrennte synthetische File-Content-Fixtures; vorhandene manuelle Windows-Pläne für ResultTable, Windows Filesystem und ZIP Memory; vollständiger Dokumentations- und Datenschutzcheck. |
| Blocker | Für V0c fehlt ausschließlich die ausdrückliche Veröffentlichungsentscheidung. Die optionalen Zeitmessungen sind keine Voraussetzung. Authentifizierte TLS-Abnahme bleibt separat und blockiert unabhängige Fachtests nicht. |
| Evidenz | V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; am 2026-09-01 bestanden alle automatisierten Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. W1-Collations/URI-Large-Input, W2a-Kollisionen/Bucket-Workload, W2b-Kollision, eingeschränkte Metadata Visibility sowie der korrigierte W5-Providervertrag sind eingeschlossen. Es werden keine Hosts, Credentials, konkreten Datenbanknamen, Laufzeiten oder vollständigen Logs übernommen. |
| Nächster Schritt | Über den tatsächlichen Releaseumfang und die Veröffentlichung entscheiden. Die drei Pflicht-Lastfälle bestanden auf dem vorhandenen SQL-2025-Linux-/CL170-Labziel; Zeitmessungen sind gemäß DEC-2026-036 optional. Details, Testbefehle und verbleibende Voraussetzungen stehen im [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md). |

Die V0c-Kohorte umfasst verbindlich:

`toolbelt.core.result-table`, `toolbelt.conversion.base64`,
`toolbelt.core.generate-series`, `toolbelt.metadata.identifier`,
`toolbelt.string.split-characters`, `toolbelt.validation.semantic-version`,
`toolbelt.conversion.integer-base`, `toolbelt.datetime.calendar-difference`,
`toolbelt.string.directional-trim`, `toolbelt.conversion.uri-component`,
`toolbelt.datetime.truncate`, `toolbelt.datetime.bucket`,
`toolbelt.binary.bit-operations`, `toolbelt.json.path-exists`,
`toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog`.

Nachtrag 2026-10-19: Der Benutzer beauftragte ausdrücklich die autonom ausführbaren Rest-Gates der ersten Releasekohorte einschließlich Fehlerbehebung und Dokumentation externer Voraussetzungen. Alle elf Kohortenadapter bestanden auf sechs physischen Zielkombinationen (66 Adapterläufe), zusätzlich sechs ADO.NET-, sechs Minimalrechte- und sechs zentrale Statusprüfungen. Die neuen Security-Verträge sowie die Integer-Base-/SemVer-/Base64-Orakelwartung sind eingeschlossen. Der historische größere V0a-/V0b-Snapshot und dessen File-/ZIP-/Filesystem-Spezialfälle werden dadurch nicht zu aktuellen V0c-Blockern. Kein neues fachliches Objekt und keine Veröffentlichung.

Nachtrag zum Abnahmevertrag 2026-10-19: Der Benutzer hat große Lastfälle mit Ergebnisprüfung als Pflicht und Laufzeitmessungen als optional ausdrücklich beauftragt. Die drei vollständigen Adapter bestanden auf dem vorhandenen bereiten SQL-2025-Linux-/CL170-Labziel einschließlich der neuen Pflichtfixtures und frischem Cleanupaudit. Alle 16 Kohortenmodule sind damit validiert; keine Veröffentlichung autorisiert. [Entscheidung](../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen).

### ADP-008: SQL_Server_Lab Project-Adapter-Pilot

| Feld | Wert |
|---|---|
| ID | `ADP-008`; externer Pilot aus dem kanonischen Backlog von `SQL_Server_Lab`, keine neue sequenzielle `AP`-Referenz |
| Ziel | Ein vorhandenes versioniertes Toolbelt-Modul über den Project-Adapter-Vertrag 0.1 auf einem isolierten SQL-Server-2025-Container-Lab installieren, aktualisieren, validieren und deinstallieren. |
| Scope | `toolbelt.core.console-message` 1.0.0; fünf reine T-SQL-Entrypoints; markergebundene synthetische Datenbank; deterministische Ableitung aus kanonischem Deploy, Source und Uninstall. Keine neue öffentliche SQL-API, keine Providerlogik und keine Verwaltung von Lab-Infrastruktur im Toolbelt-Repository. |
| Status | `completed` für den deklarierten Pilot-Scope |
| Alternativen | Ein neues Pilotmodul würde unnötig einen öffentlichen Vertrag erzeugen; kopierte, unabhängig gepflegte SQL-Dateien würden vom Moduldeployment abdriften; ein im Toolbelt gestarteter Lab-Run würde die Repository-Grenze verletzen. |
| Risiken und Grenzen | Das Update ist ein versionsgleiches idempotentes Redeployment, weil für Version 1.0.0 kein historischer Upgradepfad existiert. Der Pilot belegt nur SQL Server 2025 Linux unter Docker und Podman und ändert den Modulstatus nicht. |
| Benutzerfreigabe | Der Benutzer hat am 2026-08-30 den autonomen Abschluss der offenen Backlogpunkte, die Verwendung des vorhandenen Podman-Providers und das Überführen jedes konsistenten Blocks auf `origin/main` ausdrücklich beauftragt. |
| Tests | Statischer Modul-/Generatorvertrag und Schema-/Resolverprüfung durch `SQL_Server_Lab`; echte getrennte SQL-Server-2025-Linux-Läufe unter Docker und Podman jeweils mit Install, Update, Validate, Adapter-Cleanup und anschließendem scopegebundenem Infrastruktur-Cleanup erfolgreich. |
| Evidenz | `Modules/toolbelt.core.console-message/TestLab/ProjectAdapter/`; ausschließlich synthetische Daten und abstrahierte Ergebnisse, ohne Credentials, Ports, Run-IDs, Laufzeiten oder vollständige Runtime-Logs. |
| Nächster Schritt | Pilotvertrag 0.1 stabil halten. Weitere Module, historische Upgradepfade oder ein breiterer Plattformscope benötigen einen eigenen begründeten Slice. |

### Q1: Migration-Idempotency-Verifier V1

| Feld | Wert |
|---|---|
| ID | `Q1`; konkretisiert `RI-2026-142`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Wiederholungsdeployment und wiederholtes Uninstall anhand des effektiven SQL-Katalogzustands prüfen, ohne eine öffentliche Runtime-Capability zu installieren. |
| Scope | Repository-interner SQLCMD-Verifier für eine isolierte synthetische Datenbank und ein dependency-freies, zustandsloses T-SQL-Modul. V1 vergleicht Schemas, Objekte, Definitionen, Spalten, Parameter, Toolbelt-Properties und Berechtigungen; zwei unabhängige Uninstall-Sitzungen und eine Restzustandsprüfung schließen den Lauf ab. Referenzmodul ist `toolbelt.core.generate-series`. |
| Priorität | `P1`; als einzelner Qualitäts-Enabler parallel zu V0 zulässig |
| Status | `completed` für den deklarierten V1-Scope |
| Alternativen | Vorhandene Lifecycle-Tests allein erkennen keine stille Katalogdrift; Source-Hashes bilden nicht den gesamten effektiven Katalog ab; ein dauerhaft installiertes Verifier-Modul würde den Prüfzustand selbst verändern. |
| Risiken und Grenzen | V1 unterstützt keine Tabellen, Assemblies, persistente Zustandsdaten, Dependency-Installation, historischen Upgradepfade, Central-Consumer oder parallele Migrationen. Abweichende Database-/Catalog-Collations bleiben ein eigener Lifecycle-Scope. |
| Tests | Statischer Contract, vollständiger Dokumentationsaudit und tatsächliche Q1-Runtime am 2026-08-29 auf SQL Server 2019, 2022 und 2025 jeweils unter Linux und Windows erfolgreich. Jeder Zieltest bestand erst nach Wiederholungsdeployment ohne Katalogdrift, zweimaligem Uninstall, leerer Restzustandsprüfung und erfolgreichem Entfernen seiner synthetischen Testdatenbank. |
| Evidenz | `Documentation/Architecture/MIGRATION_IDEMPOTENCY_VERIFIER_DESIGN.md`, `Tests/Quality/MigrationIdempotency/`, `Tests/CI/run-q1-migration-idempotency.sh` und `.github/workflows/q1-migration-idempotency.yml`; lokale SQL_Server_Lab-Matrix mit ausschließlich abstrahierter Evidenz. Keine Hosts, Credentials, Datenbanknamen, konkreten Buildnummern, Laufzeiten oder vollständigen Logs übernommen. |
| Nächster Schritt | Q1 V1 stabil halten. Tabellen-/Zustands-, Upgrade-, Central- und Parallelitäts-Slices nur bei eigenem nachgewiesenem Bedarf erweitern; Golden Snapshots und Contract-Test-Generierung bleiben zurückgestellt. |

### D1: Date Spine V1

| Feld | Wert |
|---|---|
| ID | `D1`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen portablen relationalen Date-Spine-Vertrag als nächste neue Nutzerfunktion bereitstellen. `Q1` bleibt ein Qualitäts-Enabler und ist keine nutzerorientierte SQL-Capability. |
| Scope | Drei öffentliche Inline TVFs für Tag, ISO-Woche und Monat. Der Bereich ist `[RangeStart, RangeEndExclusive)`; geliefert werden alle geschnittenen Perioden mit `Ordinal int` und `PeriodStart date`. `NULL`, leere und umgekehrte Bereiche liefern keine Zeilen. Keine Feiertage, Arbeitstage, Zeitzonen, DST, Locale-Texte, Geschäfts- oder Fiskalkalender und keine persistente Kalenderdimension. |
| Dependencies | `RI-2026-079`; `toolbelt.core.generate-series` 1.0.0 und `toolbelt.datetime.truncate` 1.0.0 in derselben Datenbank. Datetime Bucket ist ausdrücklich keine künstliche Dependency. |
| Priorität | `P1` nach `V0a`/`V0b`/`V0c`; parallel höchstens ein `Q1`-Qualitäts-Enabler |
| Status | `implemented`; Runtime `validated`, Release `unreleased` |
| Alternativen | Eine öffentliche Grain-Parameterfunktion, eine USP, nur vollständig enthaltene Perioden und eine persistente Kalenderdimension wurden für V1 verworfen. Quartal, frei wählbarer Schritt, Periodenende und abgeleitete Kalenderattribute bleiben mögliche getrennte Erweiterungen. |
| Risiken und Grenzen | Ergebnisgröße wächst linear; ohne `ORDER BY` keine Reihenfolgegarantie; ISO-Woche ist bewusst Montag-basiert und `DATEFIRST`-unabhängig; der maximale Kalendertag kann mangels darstellbarer Exklusivgrenze nach `9999-12-31` nicht eingeschlossen werden. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich freigegeben. |
| Tests | Statischer Vertrag sowie die vollständigen lokalen, zentralen, Lifecycle-, Dependency-, Kollisions-, Grenz-, `DATEFIRST`- und Skalierungsadapter waren am 2026-09-01 auf physischen SQL-Server-2019-/2022-/2025-Zielen unter Windows base und Linux latest erfolgreich. Alle erzeugten synthetischen Datenbanken wurden entfernt, Lab-Systeme wurden nicht beendet. |
| Nächster Schritt | PR #61 ist gemergt; das Modul ist `validated`. `release_status` bleibt bis zu einer ausdrücklich autorisierten Veröffentlichung `unreleased`. |

### R1a: Regex-Semantik- und Provider-Spike

| Feld | Wert |
|---|---|
| ID | `R1a`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die native SQL-Server-2025-RE2-Semantik für einen möglichen ersten Slice aus `LIKE`, `INSTR` und `COUNT` gegen portable Provideroptionen prüfen, ohne eine Runtime-API zu implementieren. |
| Scope | Native 2025-Semantik und Compatibility-Level-Verfügbarkeit; .NET-Framework-4.8-Vergleich; RE2-/CLR-/Linux-, Lizenz-, Wartungs- und Dependency-Gates. Replace, Substring, Split, Matches, Fuzzy Matching und jedes öffentliche SQL-Objekt bleiben außerhalb. |
| Priorität | `P1` Research nach D1; blockiert keine fachlich unabhängige Welle |
| Status | `completed` für den Research-Scope; der getrennt freigegebene R1b-Slice ist inzwischen implementiert |
| Ergebnis | SQL Server 2025 ist die kanonische RE2-Referenz. `REGEXP_INSTR` und `REGEXP_COUNT` liefen unter Compatibility 150/160/170, `REGEXP_LIKE` nur unter 170. Der eingebaute .NET-Framework-Regexkern weicht semantisch ab und besitzt keine lineare Laufzeitgarantie. Native RE2-Wrapper benötigen plattformspezifischen nativen Code und sind mit `SAFE`/SQL Server Linux unvereinbar. Kein portabler Paritätsprovider wurde ausgewählt oder aufgenommen. |
| Alternativen | Exakter externer/native RE2-Provider; ausdrücklich engerer Toolbelt-Dialekt mit Parser, Transformationen und Timeout; reine SQL-Server-2025-Fassade. Reines T-SQL ist kein allgemeiner Regex-Provider. |
| Risiken und Grenzen | Eine bloße Pattern-Blacklist erzeugt keine RE2-Parität. Zeichenklassen, Anker, Flags, ungültige Konstrukte, Input-/Patternlimits, Timeoutfehler, ReDoS und Providerdeployment benötigen je nach Richtung einen neuen öffentlichen Vertrag. |
| Tests | Physischer SQL-Server-2025-Linux-Lauf mit Compatibility 150/160/170 und synthetischen Semantik-/Fehlervektoren am 2026-08-30 erfolgreich; .NET-Framework-4.8-Harness bestätigte die erwarteten Abweichungen. Die synthetische Datenbank und temporären Buildartefakte wurden entfernt; Windows-SQL-Runtime blieb `not executed`; Lab-Systeme wurden nicht beendet. |
| Evidenz | `Documentation/Research/REGEX_SEMANTICS_PROVIDER_SPIKE.md`, `Tests/Research/Regex/` und `.github/workflows/regex-provider-spike.yml`. Keine Drittanbieterbibliothek oder Binärdatei wurde heruntergeladen oder aufgenommen. |
| Nächster Schritt | R1b ist als eigener enger Toolbelt-Dialekt umgesetzt. Weitere Regex-APIs oder RE2-Parität benötigen neue Verträge und Freigaben. |

### R1b: Begrenzter Regex-Runtime-Slice

| Feld | Wert |
|---|---|
| ID | `R1b`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Portable Regex-Prüfung, Positionssuche und Zählung für SQL Server 2019, 2022 und 2025 mit bewusst kleiner, stabil dokumentierter Semantik. |
| Scope | `toolbelt.string.regex` 1.0.0 mit `SVF_RegexIsMatch`, `SVF_RegexInstr`, `SVF_RegexCount`; eigener Dialektparser, UTF-16-Positionen, ASCII-Kurzklassen, `\p{L}`, Flags `c/i/m/s`, 2-MiB-/8.000-Byte-/1.000-Quantifier-Grenzen und fixer 250-ms-Timeout. |
| Provider | Eine .NET-Framework-4.8-Assembly mit `SAFE`, direkten Referenzen nur auf System/System.Data und exaktem SHA2-512-Trust; keine Drittanbieter-/Native-Abhängigkeit, kein TRUSTWORTHY und keine automatische CLR-Konfiguration. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Exakter RE2-/Native-Provider, SQL-Server-2025-Fassade und reines T-SQL wurden für R1b verworfen. |
| Risiken und Grenzen | Keine RE2-Parität oder lineare Laufzeit, SARGability oder Parallelplanzusage. Backtracking bleibt trotz Parser und Timeout möglich. Replace, Substring, Captures, Split und Matches sind ausgeschlossen. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/REGEX_MODULE_DESIGN.md`, Modulvertrag und synthetischer Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest. |
| Nächster Schritt | PR #65 ist gemergt; den freigegebenen V1-Scope stabil halten. Weitere Regex-APIs und die tatsächliche Veröffentlichung bleiben unautorisiert. |

### E1a: Work Queue Claim/Complete/Fail

| Feld | Wert |
|---|---|
| ID | `E1a`; konkretisiert `TC-2026-015`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen persistenten Queue-Kern bereitstellen, der ausschließlich registrierte Work Types einreiht, atomar beansprucht und tokengebunden terminal abschließt. |
| Scope | `toolbelt.core.work-queue` 1.0.0 mit `USP_EnqueueWork`, `USP_ClaimWork`, `USP_CompleteWork`, `USP_FailWork`, `USP_GetWorkStatus` und `VW_WorkQueue`. Zustände `QUEUED -> CLAIMED -> COMPLETED|FAILED`; Payload nur NONE oder JSON-Objekt bis 64 KiB; Statusoberflächen ohne Payload und ClaimToken. |
| Dependencies | `toolbelt.core.result-table` 1.0.0 und `toolbelt.core.work-type` 1.1.0 in derselben Datenbank; persistente Namenskonvention aus `DEC-2026-025`. |
| Priorität | `P1` nach D1 und R1a, als eigenständiger vertikaler Slice |
| Status | `implemented`; Runtime `partially validated`, Release `unreleased` |
| Alternativen | Service Broker, SQL Server Agent und externe Worker wurden nicht an E1a gekoppelt. Raw SQL oder Handlernamen in Payloads, öffentliche Claim-Token in Statusoberflächen und ein gemeinsamer Lease-/Retry-/Cancellation-Vertrag wurden verworfen. |
| Risiken und Grenzen | Keine Lease, Recovery, Retry, Dead Letter, Idempotency Key, Cancellation, Resultpersistenz oder automatische Ausführung. Ein Worker-Abbruch nach Claim lässt das Item dauerhaft `CLAIMED`; keine Exactly-once- oder absolute Fairnesszusage. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich nach D1 und R1a freigegeben. |
| Tests | Statischer Vertrag sowie E1a-Semantik, Caller-Transaktionen, vier echte Claim-Sessions, ResultTable, Dependency-/Kollisionspreflight, Redeployment, Central, Datenverlustschutz, Uninstall und Cleanup waren am 2026-08-30 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Die drei Windows-Base-Ziele waren bereits beim SQL-Anmeldungs-Preflight nicht erreichbar; Windows blieb `not executed`. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, `Modules/toolbelt.core.work-queue/` und `.github/workflows/work-queue-runtime.yml`; ausschließlich synthetische Daten und abstrahierte Evidenz. |
| Nächster Schritt | E1b ist als Version 1.1.0 implementiert, validiert und über PR #64 gemergt. E1c Retry/Dead Letter/Idempotenz bleibt ohne eigene Freigabe offen. |

### E1b: Work Queue Lease/Heartbeat/Orphan Recovery

| Feld | Wert |
|---|---|
| ID | `E1b`; konkretisiert `TC-2026-015` und `TC-2026-021`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Dauerhaft blockierte Claims durch eine begrenzte Lease erkennbar machen und ausschließlich über eine explizite Recovery wieder freigeben. |
| Scope | `toolbelt.core.work-queue` 1.1.0; Claim-Lease 5 bis 86400 Sekunden, monotone ClaimGeneration, `USP_RenewWorkLease`, `USP_RecoverExpiredWork`, aktive-Lease-Prüfung in Complete/Fail sowie geschützte Lease-/Recovery-Statusfelder. |
| Migration | Unterstütztes Upgrade `1.0.0 → 1.1.0`; aktive E1a-Claims blockieren vor jeder Mutation. QUEUED- und terminale Daten bleiben erhalten. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Persistenter ORPHANED-Status, implizite Recovery im Claim, SessionId als Ownership, globale unbegrenzte Lease, automatische Supervisor-Ausführung und `KILL` wurden verworfen. |
| Risiken und Grenzen | Recovery kann bereits erfolgte fachliche Seiteneffekte wiederholen. Keine Exactly-once-Garantie, generische Idempotenz, Retry, Dead Letter, Cancellation, Attempt-Historie oder Worker-Orchestrierung. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, Modulvertrag und synthetischer Runtime-/Upgrade-Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest erfolgreich. |
| Nächster Schritt | PR #64 ist gemergt; den freigegebenen V1.1.0-Scope stabil halten. E1c Retry/Dead Letter/Idempotenz und die priorisierten Gruppen-Barriers aus `TC-2026-048` sind als Work Queue v2 umgesetzt. E1d bleibt eine getrennte W6d-Welle; die tatsächliche Veröffentlichung bleibt unautorisiert. |

### W6c: Work Queue v2 – Retry, Idempotenz und priorisierte Gruppen-Barriers

| Feld | Wert |
|---|---|
| ID | `W6c`; konkretisiert `TC-2026-020` und `TC-2026-048`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Work Queue 2.0.0 um expliziten Retry mit Backoff, Dead Letter, Idempotenz und priorisierte gruppenbezogene Drain-Barriers erweitern. |
| Scope | Neue Enqueue-Policy- und Barrier-USPs, Retry-/Dead-Letter-USPs, erweiterte Claim-/Statusoberflächen, persistente Retry- und Barrier-Metadaten, Upgrade von 1.0.0/1.1.0, Dokumentation und betroffene Tests. Keine Cancellation, Worker-Provider, Raw SQL, Systemzustandserkennung oder automatische Log-Shrink-Operation. |
| Priorität | `P1`; nach E1b, vor E1d und allen Host-Providern |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden am 2026-09-10 besprochen. Der Benutzer hat anschließend mit „freigabe“ und dem ausdrücklichen Implementierungsauftrag die Umsetzung freigegeben. |
| Kernvertrag | Priority `0..255`, Gruppe pro Auftrag, `DRAIN_BARRIER` mit exaktem Snapshot aktiver Claim-Generationen, parallele gleichpriorisierte Barriers, Retry ohne Jitter und `RETRY_WAIT`, Dead Letter sowie Idempotenz je Work Type und Key. |
| Risiken und Grenzen | Barriers können eine Gruppe bewusst anhalten; deshalb ist ihre Enqueue-Procedure getrennt berechtigt. Lease-Ablauf beendet keinen Snapshot-Blocker. Idempotenz garantiert keine fachliche Exactly-once-Ausführung. |
| Tests | Statischer Vertrag und GitHub Actions Work-Queue Runtime #34533724721 am 2026-09-10 erfolgreich auf synthetischen SQL Server 2019/2022/2025 Linux sowie lokaler SQL_Server_Lab-Adapter am 2026-09-11 erfolgreich auf bereiten Windows-2019-, 2022- und 2025-Zielen: öffentlicher Vertrag, Retry/Dead Letter, Idempotenz, Barriers, Parallelität, Upgrade und Lifecycle. CU ist für diesen nicht patchgebundenen Vertrag irrelevant. |
| Nächster Schritt | Den validierten W6c-Scope stabil halten. W6d ist als getrennte kooperative Cancellation-Welle freigegeben. |

### W6d: Kooperative Execution-Cancellation

| Feld | Wert |
|---|---|
| ID | `W6d`; konkretisiert `TC-2026-018` |
| Ziel | Eine irreversible, persistierte Cancellation-Anforderung pro `ExecutionId` bereitstellen, die Worker an eigenen Checkpoints auswerten können. |
| Scope | Neues Modul `toolbelt.core.execution-cancel` 1.0.0 mit interner Persistenz, Status-TVF, Skalurfunktion, Anforderungs-USP, Lifecycle, Central-Deployment und gezielten Contract-Tests. Die Anforderung akzeptiert keine aktive Caller-Transaktion. |
| Priorität | `P1`; nach W6c, vor Provider- oder Host-Abbrüchen |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden im Architekturdesign festgehalten. Der Benutzer hat am 2026-09-11 mit „do it“ die Implementierung ausdrücklich freigegeben. |
| Kernvertrag | Wiederholte Anforderung ist idempotent und behält die erste Auditzeit. Öffentlicher Status enthält nur ExecutionId, Flag und UTC-Zeit. Worker entscheiden über terminalen oder retryfähigen Ausgang selbst. |
| Risiken und Grenzen | Kein `KILL`, keine Sessionbeendigung, keine Transaktionsrücknahme, keine automatische Work-Queue-Mutation und keine Garantie für nicht kooperierende Provider. Die Checkpoint-Frequenz ist Work-Type-Vertrag. |
| Tests | Öffentlicher Vertrag, Idempotenz, Context-Auflösung, Caller-Transaktion, Parallelität, Lifecycle, Central und Uninstall sowie die betroffene lokale SQL_Server_Lab-Matrix. CU ist nicht patchgebunden. |
| Evidenz | Am 2026-09-11 erfolgreich: Statischer Vertrag sowie lokaler SQL_Server_Lab-Adapter für SQL Server 2019, 2022 und 2025 unter Linux und Windows mit öffentlichem Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall. CU ist für diesen nicht patchgebundenen Vertrag irrelevant. |
| Nächster Schritt | Den validierten W6d-Scope stabil halten; Queue-Mutation, `KILL` und Provider-Abbrüche bleiben getrennte Slices. |

### AP-2026-003: ResultTable-Kernmodul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-003` |
| Ziel | Das implementierungsreif spezifizierte Modul `toolbelt.core.result-table` vollständig implementieren, dokumentieren, installieren, deinstallieren und auf den verfügbaren Zielplattformen validieren. |
| Scope | `toolbelt.core.result-table`; Modulverzeichnis, `module.yaml`, `toolbelt_core.USP_PrepareResultTable`, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Runtime-, Collation-, Deployment- und Plattformtests. |
| Dependencies | `AP-2026-002`, `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017` und `DEC-2026-019`. |
| Priorität | `P0` |
| Status | `completed`; Fachmatrix und Pflicht-Lastfall erfolgreich; optionale Zeitmessung bleibt außerhalb des Validierungsgates |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Exakt ein persistentes SQL-Objekt in Version `1.0.0`; öffentliche Signatur und Help-Vertrag vollständig; `@LikeTable`-Schemaquelle, `@KeepData`-Matrix, Preflight, in-place-Umbau, Savepoint- und Fehlervertrag implementiert; lokale und zentrale Installation; kontrolliert wiederholbare Lifecycle-Skripte; keine nicht freigegebenen weiteren persistenten Objekttypen; Dokumentation und Manifest konsistent; alle verfügbaren Pflichtprüfungen ausgeführt und nicht verfügbare Prüfungen ehrlich ausgewiesen. |
| Tests | Statischer Vertrag und vollständige Windows-/Linux-Matrix auf SQL Server 2019, 2022 und 2025 einschließlich Collation-, 1024-Spalten-, Transaktions-, natürlichem Savepoint-Enginefehler 2705, Multi-Session-, Central-/Lifecycle- und synthetischem Performance-Workload erfolgreich. |
| Blocker | Keine offene Pflichtvalidierung; optionaler Performancevergleich und tatsächliche Veröffentlichung bleiben getrennt. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.core.result-table/`; [Basislauf 30447442638](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30447442638), [erweiterter Lauf 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934), [Multi-Session-Lauf 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) und [Savepoint-Enginefehler-Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) erfolgreich. |
| Nächster Schritt | Den validierten Funktionsstand stabil halten; optionale Zeitmessungen nur bei eigenem Auftrag. Veröffentlichung über die ausdrückliche V0c-Releaseentscheidung. |


### AP-2026-023: Windows Filesystem SQL CLR

| Feld | Wert |
|---|---|
| ID | AP-2026-023 |
| Ziel | Windows-only Dateisystemzugriff als kontrolliertes SQL-CLR-Modul für Text/Binary, Codepages, Transcoding, Directory-Verwaltung und begrenztes rekursives Löschen implementieren. |
| Scope | toolbelt.filesystem.windows, C#-.NET-Framework-4.8-Assembly, T-SQL-Fassade, Root-Alias-Konfiguration, Trust-/Deployment-Lifecycle, Dokumentation, Contract-Matrix und Windows-Build. |
| Dependencies | toolbelt.core.result-table; separate administrative SHA2-512-Trust-Freigabe; Windows SQL Server mit kontrolliertem synthetischem Testroot. |
| Priorität | P1 |
| Status | `completed`; die autorisierte Windows-Identitäts-/Reparse-Welle ist abgeschlossen. Breitere Releasequalifikation bleibt getrennt in `V0b`. |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Caller ist Default und wird bei SQL Authentication abgelehnt; ServiceAccount ist explizit; absolute Pfade und Reparse Points sind gesperrt; I/O arbeitet begrenzt/gestreamt; Write nutzt atomare Staging-Dateien; rekursives Delete besitzt Tiefe-/Eintragslimits; Linux ist korrekt not applicable. |
| Tests | Statischer Vertragscheck und GitHub-Windows-Build; manueller Windows-SQL-Server-/NTFS-Test für Deployment, beide Identitätsmodi, Codepages, Limits, Reparse Points, atomare Writes und rekursives Delete. |
| Blocker | Kein Blocker für die abgeschlossene autorisierte Welle. Direkte CLR-/RunAs-, weitere Codepage-/Limit-/Reparse-/Delete-Fälle sowie die vollständige Matrix- oder ZIP-Dateizugriffsqualifikation bleiben getrennte V0b-/Folgegates. |
| Evidenz | Benutzerfreigabe am 2026-07-31; Implementierung und Windows-Build-/Static-Contract-Artefakte auf `main`; Build-Nachweis im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Abschlusslauf vom 2026-10-13 als begrenzte Evidenz führen: Caller-/ServiceAccount-Textwrite, SQL-Authentication-Ablehnung, Junction-List/-Delete und 120 begrenzte parallele Deleteversuche gegen einen kontrolliert zwischen Directory und Junction wechselnden Root-Kindpfad; externes Sentinel blieb erhalten. Eigene Datenbank, Login, Trust und Testausgaben wurden bereinigt. Weitere Matrixfälle ausschließlich als getrennte V0b-/Folgearbeit prüfen. Private Runtimeausgaben bleiben außerhalb des Repositorys. |


Wartung 2026-10-07 (Codex), innerhalb des bestehenden `AP-2026-023`:
Der Security-Cloud-Befund zur nicht durchgesetzten Delete-Tiefengrenze wird
als Korrektur des vorhandenen Vertrags behandelt. Ein vollständiger
begrenzter Prüfplan geht jeder Löschung voraus; danach werden ausschließlich
geprüfte Einträge und Directories nichtrekursiv gelöscht. Keine neue SQL-
Funktion, Identität, Rechtevergabe, Trustregistrierung oder Labausweitung.
Der autonome Wartungsauftrag deckt die Vertragskorrektur ab. Neue begrenzte
Frameworkfälle werden erst nach tatsächlicher Ausführung als erfolgreich
geführt; Windows-SQL-, Caller-/NTFS-/Reparse-/Race- und Releasequalifikation
bleiben gesonderte Gates. Historische Nachweise gelten für ihren damaligen Source.

## Besprochene Folgescopes ohne Implementierungsfreigabe

Die Vorfreigabebesprechungen zu `TC-2026-032` und `TC-2026-034` bleiben
nachfolgend historisch sichtbar. Ihr damaliger Freigabestatus wird durch den
aktuellen aktiven Nachtrag vom 2026-10-01 oben ersetzt; die übrigen
Folgescopes sind dadurch nicht freigegeben.

### TC-2026-049: RunAs-Identitätsmodus für geeignete Dateisystemfunktionen

| Feld | Wert |
|---|---|
| ID | `TC-2026-049` |
| Ziel | Einen optionalen, explizit konfigurierten RunAs-Identitätsmodus für diejenigen Dateisystemfunktionen vorbereiten, deren Sicherheits- und Betriebsvertrag ihn tatsächlich rechtfertigt. |
| Scope | Vor-Source-Entscheidung zu Identitätsquelle, Credential-/Secret-Grenze, erlaubten Funktionen, SQL-/Windows- und NTFS-Rechten, Root-Alias-Bindung, Audit-/Fehlerverhalten, Deployment, Trust, Lifecycle, Minimalrechten sowie Windows-Testmatrix. Der vorhandene `Caller`- und `ServiceAccount`-Vertrag bleibt unverändert. |
| Nicht-Scope | Keine Implementierung, keine neue `@ExecutionIdentity`-Option, keine Credentials oder Secrets im Repository, keine Rechtevergabe, keine Testkontoerstellung durch das Projekt, kein allgemeiner Identity-Broker und keine implizite Ausweitung auf alle Toolbelt-Module. |
| Abgrenzung | SQL `EXECUTE AS` ist nicht automatisch ein Windows-Dateisystem-RunAs-Kontext. Eine spätere Richtung muss Windows-Identität, Secret-Verwaltung und reale NTFS-Wirkung getrennt nachweisen. |
| Dependencies | `AP-2026-023`, `toolbelt.filesystem.windows`, bestehender Root-Alias-/Reparse-/Caller-/ServiceAccount-Vertrag, bereitgestellte synthetische Windows-Testidentitäten und eine gesonderte funktionsbezogene Benutzerfreigabe. |
| Priorität | `P1` |
| Status | `proposed`; vom Benutzer am 2026-10-10 als eigene Entwicklungswelle angefordert, ohne Implementierungsfreigabe. |
| Akzeptanzkriterien | Für jede einbezogene Funktion sind Zweck, Alternativen, Credentialbesitz, minimale Rechte, erlaubte Roots, Fehler-/Auditsemantik, Cleanup, Windows-Identitätsnachweis und Testfälle vor Source verbindlich entschieden. Nicht geeignete Funktionen bleiben ausdrücklich ausgeschlossen. |
| Risiken | Persistente oder übertragbare Credentials, Servicekonto-Umgehung, `EXECUTE AS`-Fehlannahmen, Root-Escape über Reparse Points, unklare Cleanup-Ownership und unzureichend abgegrenzte Rechte. |
| Nächster Schritt | Designbesprechung: konkrete Zielidentität und Credential-Quelle, Funktionsinventar sowie Alternativen (Caller, ServiceAccount, SQL Agent/Proxy oder externer Worker) vergleichen; erst danach eine explizite Implementierungsfreigabe einholen. |

### TC-2026-032: Unquoting und optionale Split-USP

Am 2026-10-01 hat der Benutzer Unquoting auf einen äußerlich gequoteten Token
begrenzt und anschließend präzisiert: Das äußere Paar wird entfernt, innere
verdoppelte Quotes werden dekodiert; `"hallo""du"""` wird `hallo"du"`.
Die zuvor angenommene unveränderte Innenbehandlung wurde damit korrigiert.
Nachtrag 2026-10-01: Expliziter Qualifier verlangt passende Delimiter an
beiden Rändern, sonst Fehler; verschiedene öffnende/schließende Delimiter
sind zulässig. `[` oder `]` wählt `[]`. Automatische Erkennung lässt
unvollständige apparent Quotation wie `“Hallo` unverändert; verdoppelte
schließende Qualifier werden nur im vollständig außen gequoteten Inneren
aufgelöst. Keine globale Quoteentfernung/Normalisierung. Zu diesem
historischen Stand waren Auto-Kandidatenliste und malformed Innenbehandlung
noch offen; die nachfolgende Bestätigung ersetzt diese offenen Punkte.
Die Präzisierung ersetzt die zuvor offenen Randregeln.
Weitere Präzisierung 2026-10-01: Ein zusätzlicher Backslash-Escape-Modus
benötigt einen expliziten Opt-in-Parameter; ohne Opt-in bleibt Backslash
literal. Doubled closing Qualifier bleiben getrennte Quoting-Semantik,
kein impliziter globaler Escape-Modus. Die damals offene Dekodierung wird
nachfolgend konkretisiert; keine Implementierungsfreigabe oder S2-Änderung.
Weitere Nutzerbestätigung 2026-10-01 „so wie du vorschlägst!“: Auto-Paare
ASCII doppelt/einfach, `[]`, `“…”` (U+201C/U+201D), `„…“`
(U+201E/U+201C); nur vollständige äußere Paare entfernen, sonst unverändert,
nicht trimmen. Im Inneren doubled closing Delimiter dekodieren; einzelnes
unescaped closing Zeichen ist Fehler (`[a]]b]` → `a]b`,
`[a]b]` → Fehler). Opt-in-Backslash dekodiert nur Backslash vor aktivem
Quotezeichen und `\\`; kein `\n`/`\t`/Unicode-Escape, andere Folgen
bleiben unverändert. Ohne Opt-in Backslash literal. Öffentliche Signatur,
Parametername, Result-/Fehlervertrag und Inputlimits sind weiterhin
Vorschläge. Nachtrag 2026-10-01: Mit „do it“ hat der Benutzer die
Randempfehlungen und Vertragsausarbeitung bestätigt: Backslash schützt
opening und closing bei asymmetrischen Paaren; escaped letztes closing ist
kein Delimiter, daher Explicit Fehler und Auto unverändert. Frühere
offene Randpunkte sind ersetzt. Die bestätigte Semantik ist
keine ausdrückliche konkrete Funktionsimplementierungsfreigabe.
`USP_SplitAdvanced` soll ergänzend vorgesehen werden und führt kein
automatisches Unquoting aus. Die Split-TVF bleibt Pflicht.
Die [konkreten Folgeslice-Vorschläge](../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md#beschlossene-folgescope-grenzen-vom-2026-10-01)
halten Alternativen, Risiken, Dependencies, Testscope und noch offene
Signatur-/Fehler-/Randfallentscheidungen fest. Status: `proposed` für diese
Folgeslices, keine Implementierungsfreigabe; S2 ist davon getrennt `completed`.

Zur gebündelten Freigabe vorbereitet, nicht implementiert:
`TVF_UnquoteToken` mit Input/Qualifier/optionalem ClosingQualifier und
Backslash-Opt-in; NULL-Qualifier Auto, leer Disabled, generische einzelne
BMP-Paare in Explicit und klare typografische Defaultzuordnung vorgeschlagen.
Vier Resultspalten, atomare symbolische Fehler, Originalpositionen,
65.536-Codeunit-Zielgrenze und Prioritäten im
[TVF-Vertragsvorschlag](../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md#zur-gebündelten-freigabe-unquoting-tvf-vertragsvorschlag).
Die optionale `USP_SplitAdvanced` ist mit vollständiger USP-Signatur,
Value/Ordinal-Erfolgsschema, Kernprüfung vor ResultTable-Mutation, NULL-No-op,
ResultTable-Dependency und Transaktions-/Testvertrag vorbereitet.
API-/Fehler-/Grenzdetails sind Empfehlungen für die gemeinsame
Funktionsfreigabe, keine zusätzlichen erfundenen Nutzerbeschlüsse.
Tests erst nach Freigabe risikobasiert 2019 Linux/2025 Windows.

### TC-2026-034: In-memory-ZIP-Erzeugung

Richtungsbestätigung 2026-10-01: caller-lokale `#Temp` mit `Ordinal`,
`EntryName`, `Payload`; `Stored` als Default, `Deflate` explizit wählbar.
Konservative Default-Zielwerte aus dem
[Writer-Vorschlag](../Documentation/Architecture/ZIP_CREATION_PROPOSAL.md)
dürfen per Ressourcenparameter nach unten und oben innerhalb separat
qualifizierter harter Grenzen angepasst werden; kein `0 = unlimited`.
Hohe Writer-Ratio ist zulässig; notwendiges Readerlimit wird dokumentiert.
Dies ist keine öffentliche Implementierungsfreigabe. Signatur, interner
Transport, Fehler und technische Ceilings bleiben konkret zu besprechen;
Datei-I/O bleibt verpflichtender späterer Slice mit eigenem Sicherheitsvertrag.
Konkreter Writer-Vertragsvorschlag 2026-10-01 vorbereitet: caller-lokale
Entries, vollständige `USP_CreateZipFromEntries`-Signatur, eine Archive-/
Metadatenzeile, unabhängige Default-/Ceilinglimits, versionierter begrenzter
Binary-Envelope, strikte UTF-16-/UTF-8-Namenprüfung vor Konvertierung,
Fehlerpriorität und Finalisierung vor ResultTable-Mutation. Nur Vorschlag;
numerische Fehlerzuordnung, SAFE/Memory und Plattformscope sind
Umsetzungspflichten nach ausdrücklicher Funktionsfreigabe, keine
heutige Runtime-Evidenz. Keine Deflate-Byteidentitätszusage.

### TC-2026-045: Begrenzter XLSX-Reader und verpflichtende Erweiterung

Am 2026-10-01 hat der Benutzer Binaryinput und Raw-/Text-/Cache-Werte als
erste Readergrenze bestätigt. Text ist aufgelöster Shared-/Inline-Stringinhalt,
keine formatierte Excel-Anzeige. Provider, Signaturen, Limits und Fehler sind
noch offen; Status: `researched`, keine öffentliche Readerfreigabe.
Nachtrag 2026-10-01: Nur der begrenzte Provider-Spike ist freigegeben:
SDK-/Dependency-/Lizenzprüfung, Memory-only-/SAFE-/Plattformmachbarkeit mit
synthetischen Minimalworkbooks. Keine öffentliche SQL-Implementierung,
Hochprivilegierung, Datei-/Netzwerkzugriff des Workbook-Providers oder
automatischer externer Fallback; öffentliche Quellenrecherche bleibt zulässig.
Anzeigeformat, Styles, explizite Culture und Datumsbehandlung müssen später
als eigener Funktionsslice umgesetzt werden, sobald ihr Vertrag besprochen
und ausdrücklich freigegeben ist. Dazu gehören 1900-/1904-Modus,
1900-Schaltjahrsonderfall, Formatcodes sowie Datum/Zeit/Dauer-Abbildung.
Der [Reader-Vorschlag](../Documentation/Architecture/XLSX_READER_PROPOSAL.md)
führt Provider-Spike, ungemessene Zielgrenzen und die getrennte Folgestufe.
Quellenreview vom 2026-10-01 abgeschlossen, keine Installation oder
Runtime-/Labtests: SDK 3.5.1 mit Framework 3.5.1 bleibt Vergleichskandidat,
nicht SAFE-/Linux-Nachweis. Begrenzter eigener ZIP-/XML-Kern ist empfohlene
Qualifizierungsrichtung, keine endgültige Providerwahl. Nächster kleiner
Schritt: Prüfplan und exakte SDK-Dependency-/Lizenz-/Hashliste festhalten;
SAFE/Memory-only, Ressourcen und Plattformverhalten später in separat
begrenztem Runtime-Scope nachweisen. Keine öffentliche Readerfreigabe.
Praktischer Spikeplan im Proposal konkretisiert: synthetischer Non-SQL-
Harness, once-index/bounded Parts, positive/negative/Grenz-/Parallelfixtures,
beobachteter No-I/O-Nachweis oder INCONCLUSIVE, gepinnte Paket-/DLL-
Hashqualifizierung erst bei später begrenzter Beschaffung. Heute keine
Downloads, Hashes oder Runtimeprüfung und keine neue Harnesscodefreigabe.
Worksheetliste und Zellreader bleiben getrennte öffentliche Vorschläge.

## Abgeschlossene Arbeitspakete

### AP-2026-030: TC-2026-033 ZIP-Metadaten-Listing

| Feld | Wert |
|---|---|
| ID | `AP-2026-030` |
| Ziel | Ein vorhandenes In-memory-ZIP als strikt geprüftes, geordnetes Metadaten-Listing inventarisieren, ohne Payload zu extrahieren oder zu dekomprimieren. |
| Scope | `toolbelt.archive.zip-memory` Version `1.2.0`; neue öffentliche `toolbelt_archive.USP_ListZipEntriesFromBinary`; gemeinsamer SAFE-CLR-Parserkern; direkte Ausgabe sowie `@ResultTable`/`@KeepData`; klassische Single-Disk-ZIPs. |
| Dependencies | Bestehendes `toolbelt.archive.zip-memory` 1.1.0, `toolbelt.core.result-table` 1.0.0 und freigegebener Vertrag `Documentation/Architecture/ZIP_METADATA_MODULE_DESIGN.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Listing-only aus `varbinary(max)`; Central-Directory-Reihenfolge; deklarierte Größen/CRC; Directory-, Encryption-, Extraction-Support-, Duplicate- und Path-Safety-Status; UTF-8/CP437; strikte Strukturprüfung; harte Limits; ZIP64/Multi-Disk abgelehnt; unbekannte Methoden und verdächtige Entries werden gelistet statt verworfen. |
| Alternativen | Getrenntes Metadatenmodul, reine T-SQL-Implementierung und externer Worker wurden zugunsten der Erweiterung des vorhandenen SAFE-CLR-Moduls verworfen, damit der ZIP-Parserkern nur einmal existiert. |
| Risiken | Untrusted Central-Directory-Metadaten, Encoding-Abweichungen, große Entry-Mengen, irreführende deklarierte Größen/CRC und die klare Trennung zwischen Listing und Extraktionsfreigabe. |
| Tests | Statischer Vertrag; synthetische Struktur-/Encoding-/Pfad-/Duplicate-/Limitfälle; direkte Ausgabe und ResultTable; Local/Central; Upgrade 1.1.0→1.2.0; automatisierte SQL-Server-2019-/2022-/2025-Matrix unter Windows base und Linux latest erfolgreich. |
| Freigabe | Fachvertrag und Implementierung dieses konkreten V1-Slices am 2026-08-09 ausdrücklich durch den Benutzer freigegeben. |
| Evidenz | Modulartefakte unter `Modules/toolbelt.archive.zip-memory/`; statischer Vertragscheck, Windows-.NET-Framework-4.8-Build und die vollständige SQL-Server-2019-/2022-/2025-Linux-Matrix einschließlich Listing und Extraktion sind im [GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453) erfolgreich. |
| Nächster Schritt | Reale Archive, echte Extremgrößen, Interoperabilität und den vollständigen Upgradepfad aus einem realen 1.1.0-Stand als Releaseevidenz ergänzen. |

### AP-2026-029: TC-2026-014 Rollback-independent Event Log

| Feld | Wert |
|---|---|
| ID | `AP-2026-029` |
| Ziel | Strukturierte Events synchron in einer zweiten Session persistieren, sodass sie Caller-Rollback und uncommittable Caller überleben. |
| Scope | `toolbelt.core.event-log` Version `1.0.0`, EventLog-Tabelle, View, Writer, Retention, interner Work Type sowie Second Session `@SuppressResult`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Windows/Linux 2019/2022/2025 einschließlich Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall erfolgreich. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410 und `local: Tests/CI/run-lab-local.ps1` vom 2026-09-01 |
| Nächster Schritt | Keine autonome Validierung offen; tatsächliche Veröffentlichung bleibt unautorisiert. |

### AP-2026-027: TC-2026-022 Work-Type-Katalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-027` |
| Ziel | Einen persistenten sicheren Katalog für benannte Stored-Procedure-Work-Types bereitstellen, ohne eine Raw-SQL-Ausführungsschnittstelle zu schaffen. |
| Scope | `toolbelt.core.work-type` Version `1.0.0`, interne Tabelle `toolbelt_core.WorkType`, öffentliche Register-/Disable-/Resolve-USPs, `VW_WorkTypes`, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; Registrierung, Update/RowVersion, Disable/Reaktivierung, Resolve, ResultTable, vier parallele Sessions, Redeploy, Central und Data-Loss-Uninstall-Schutz. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; Second-Session-Provider bleibt eine getrennte W5-Capability. |

### AP-2026-026: TC-2026-019 Execution Context

| Feld | Wert |
|---|---|
| ID | `AP-2026-026` |
| Ziel | Sessiongebundene Execution- und Correlation-Information ohne persistente Tabelle bereitstellen. |
| Scope | `toolbelt.core.execution-context` Version `1.0.0`, Begin/Set/End, inline TVF, SVF-Wrapper, lokales und zentrales Deployment. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; vier parallele Sessions, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; persistenter Ausführungsstatus bleibt ein getrennter, nicht freigegebener Slice. |

### AP-2026-025: TC-2026-017 Error Envelope

| Feld | Wert |
|---|---|
| ID | `AP-2026-025` |
| Ziel | Explizit aus einem CATCH übergebene Fehlerdaten standardisieren, ohne den unveränderten Rethrow zu ersetzen. |
| Scope | `toolbelt.core.error-envelope` Version `1.0.0`, direkte und ResultTable-Ausgabe, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; Klassifikation, ResultTable, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; persistentes Logging bleibt ein getrennter, nicht freigegebener Slice. |

### AP-2026-024: TC-2026-037 File-Content-Slice 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-024` |
| Ziel | Den portablen Read-only-Slice für kontrolliertes Text- und Binary-Lesen über `OPENROWSET(BULK...)` implementieren, registrieren und mit ausführbarer Evidenz belegen. |
| Scope | `toolbelt.file.content` Version `1.0.0`, Root-Allowlist, `toolbelt_file.USP_LoadBinaryFile`, `toolbelt_file.USP_LoadTextFile`, lokales und zentrales Deployment, Dokumentation, statische sowie Runtime-/Lifecycle-Contracts. Keine Schreiboperationen und kein externer Worker. |
| Dependencies | Keine Runtime-Modulabhängigkeit; administrative Bulk-Read-Berechtigung beziehungsweise Ad-hoc-Distributed-Queries entsprechend Deploymentvertrag. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Absolute Pfade nur innerhalb freigegebener Roots; Traversal-Ablehnung; Text/Binary-Vertrag, BOM-/Encoding-Metadaten, Limits, Hilfe, Deployment und Uninstall vorhanden. |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; statischer Vertrag, synthetische UTF-8-/UTF-16-/ANSI-/Binary-Fixtures, Allowlist, Lifecycle und Uninstall. |
| Blocker | Kein Merge-Blocker. Windows, separat bereitgestellte serverseitige Fixtures und nicht-ASCII-spezifische Providergrenzen bleiben Releasevalidierung. |
| Evidenz | Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Serverseitige synthetische Fixtures extern bereitstellen und Windows sowie die nicht-ASCII-spezifischen Providergrenzen prüfen; Schreiboperationen werden durch den getrennten Windows-Provider abgedeckt. |

Wartung 2026-10-07 (Codex): Der Security-Cloud-Befund zum nicht maskierten
Präfixvergleich wird innerhalb des bestehenden Root-Allowlist-Vertrags
korrigiert. Beide vorhandenen Lader verwenden dieselbe literale
Verzeichnisgrenze mit unverändertem Fehlercode `51321`; keine neue öffentliche
Funktion, kein zusätzlicher Provider und keine Rechte- oder Labausweitung.
Der autonome Wartungsauftrag deckt diese Vertragskorrektur ab. Native Windows-,
Minimalrechte- und Dateisystemlink-Qualifikation bleiben offen; neue Tests
werden nur mit tatsächlich ausgeführter Evidenz als bestanden geführt.

### AP-2026-022: SQL CLR ZIP Build-/Deployment-Spike

| Feld | Wert |
|---|---|
| ID | `AP-2026-022` |
| Ziel | Den technisch kleinsten SQL-CLR-Providerpfad für ZIP Method 8 mit einer minimalen `SAFE`-Assembly kontrolliert bauen, deployen, ausführen und wieder entfernen. |
| Scope | C#-Projekt für .NET Framework 4.8; Raw-Deflate über `DeflateStream` aus der unterstützten `System.dll`; eigene CRC32-Prüfung; SHA2-512-Trust-Manifest; binäres `CREATE ASSEMBLY`; getrennte Trust-, Deploy-, Verify- und Uninstall-Skripte; positiver SQL-Server-2022-Linux-Runtime-Gate. Keine produktive ZIP-Funktion, keine öffentliche API und kein Modulmanifest. |
| Dependencies | `AP-2026-021`, `ZIP_CLR_PROVIDER_DESIGN.md`, `CLR_SECURITY_AND_PORTABILITY.md`, .NET-Framework-4.8-Targeting-Pack, MSBuild, SQLCMD und eine disposable SQL-Server-Testinstanz. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Keine direkte Referenz auf `System.IO.Compression.dll` oder `ZipArchive`; `DeflateStream` wird aus `System.dll` geladen; die Testassembly bleibt `SAFE`; der Trust-Hash entsteht aus dem konkreten Binary; Deployment benötigt keinen serverlokalen Buildpfad; tatsächlicher CLR-Aufruf prüft Payload und CRC32; kein Skript setzt `TRUSTWORTHY ON`, deaktiviert `clr strict security` oder verwendet `EXTERNAL_ACCESS`/`UNSAFE`; Uninstall berührt keinen Trust-Eintrag. |
| Tests | Statische Vertragsprüfung, Windows-GitHub-hosted .NET-Framework-Build und positiver SQL-Server-2022-Linux-Lauf mit Trust, `CREATE ASSEMBLY`, Deflate-/CRC32-Ausführung und Uninstall sind erfolgreich. SQL Server 2019, SQL Server 2025 und Windows-Runtime bleiben separate Pflichtläufe vor Produktfreigabe. |
| Blocker | Kein bekannter technischer Blocker für den korrigierten Deflate-/CRC32-Spike. Der frühere Fehler 10301 entstand durch den ungeeigneten `ZipArchive`-Pfad und die direkte Abhängigkeit von `System.IO.Compression.dll`. |
| Evidenz | `Spikes/sql-clr-zip-provider/README.md`, `Source/ZipClrProbe.cs`, `Tests/Static/validate_spike.py`, `.github/workflows/sql-clr-zip-spike.yml` und SQL CLR ZIP Spike Run 30608612435. |
| Nächster Schritt | Historische Spike-Evidenz beibehalten; die produktive Implementierung und weitere Plattformvalidierung werden in `AP-2026-020` geführt. |

### AP-2026-021: TC-2026-034 Verarbeitungswelle 3 (CLR-Provider Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-021` |
| Ziel | Den separaten CLR-Providervertrag für `TC-2026-034` abschließen und die Sicherheits-, Lifecycle- und Plattformgrenzen vor einer Implementierung verbindlich festlegen. |
| Scope | Keine Runtime-Implementierung. Der Vertrag begrenzt einen optionalen C#-SQL-CLR-Provider auf In-memory-Extraktion einzelner Entries mit ZIP Method 0 und 8, einschließlich Payload-CRC-Prüfung; Dateisystem, Verschlüsselungsentschlüsselung, Deflate64, ZIP-Erzeugung und weitere Formate bleiben ausgeschlossen. |
| Dependencies | `AP-2026-020`, `TC-2026-034`, `Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`, `Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md`, Datenschutz- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Klarer Provider-Schnitt mit explizitem Non-Goal gegen Dateisystem-Default, definiertem Methodensubset (0 und 8), expliziter Payload-CRC-Prüfung, dokumentiertem Sicherheitsweg ohne pauschales `TRUSTWORTHY ON` sowie definiertem Assembly-Lifecycle und Test-/Spike-Gates. |
| Tests | Vertrags- und Designkonsistenz sowie dokumentierte Build-/Trust- und Runtime-Matrix. Diese Welle behauptet keine Runtime-Evidenz. |
| Blocker | Keine. Der Vertrag wurde durch die produktive SAFE-SQL-CLR-Implementierung erfüllt. |
| Evidenz | Benutzerauftrag vom 2026-07-30; Architekturvertrag `ZIP_CLR_PROVIDER_DESIGN.md`; Spike-Quellartefakte in `Spikes/sql-clr-zip-provider/`. |
| Nächster Schritt | Keine weitere Vertragswelle erforderlich; reale Archive, Extremgrößen, historische Upgrades und Interoperabilität werden in `AP-2026-020` nachgeführt. |

### AP-2026-020: TC-2026-034 Verarbeitungswelle 2 (Implementierungswelle V1A)

| Feld | Wert |
|---|---|
| ID | `AP-2026-020` |
| Ziel | Den freigegebenen V1A-Slice von `TC-2026-034` als erstes lauffaehiges ZIP-Modul implementieren, dokumentieren und mit Runtime-Evidenz belegen. |
| Scope | `toolbelt.archive.zip-memory` Version `1.1.0` mit In-memory-Extraktion einzelner Eintraege aus `varbinary(max)`; kein Dateisystemzugriff, keine Archiv-Erzeugung, keine rekursive Entpackung, keine Passwortentschluesselung. |
| Dependencies | Abgeschlossene Vertragswelle `AP-2026-019`, Kandidaten `TC-2026-033` und `TC-2026-034`, Moduldesign `ZIP_ARCHIVE_MODULE_DESIGN.md`, USP-Vertrag, Modul- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Ein oeffentliches Objekt mit stabilem Help-/Fehler-/Resultset-Vertrag; Duplicate-Entry-Semantik als expliziter Fehler; harte Default-Limits (`@MaxEntryBytes = 104857600`, `@MaxCompressionRatio = 200.00`); verschluesselte Eintraege liefern bei `@FailIfEncrypted = 0` einen expliziten Status ohne Payload; lokale und zentrale Lifecycle-Artefakte sowie statische und Runtime-Tests vorhanden. |
| Tests | Windows-.NET-Framework-4.8-Build sowie SQL Server 2019, 2022 und 2025 unter Linux; auf SQL Server 2025 Compatibility Levels 150, 160 und 170. Trust, Stored, Deflate, Data Descriptor, Encoding, CRC32, Limits, ResultTable, Wiederholungsdeployment, Central und Uninstall erfolgreich. |
| Blocker | Kein Merge-Blocker. Reale Archive, echte Extremgrößen-/Ressourcenläufe, historische Upgrades und Interoperabilität bleiben offen. |
| Evidenz | Produktives Modul `toolbelt.archive.zip-memory` Version `1.1.0`; Workflow [30615544206](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206) erfolgreich. |
| Nächster Schritt | Reale Archive, echte Extremgrößen und historische Upgrade-/Interoperabilitätsevidenz ergänzen; ZIP-Erzeugung und vollständige Dateisystemextraktion bleiben getrennte spätere Slices. |

### AP-2026-019: TC-2026-034 Verarbeitungswelle 1 (Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-019` |
| Ziel | Die erste Verarbeitungswelle fuer `TC-2026-034` als belastbare V1-Vertragsbasis abschliessen und die anschliessende Implementierungsfreigabe vorbereiten. |
| Scope | Keine Runtime-Implementierung. V1A auf In-memory-Extraktion einzelner ZIP-Eintraege begrenzen, Dateisystempfade ausschliessen, Sicherheitsgrenzen und Ergebnisvertrag dokumentieren, Testmatrix und Lifecycle-Scope vorbereiten. |
| Dependencies | `TC-2026-034`, `TC-2026-033`, `TC-2026-037`, `TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md`, `WORKING_RULES.md`, `PROJECT_RULES.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | V1A-Vertrag ist dokumentiert, Nicht-Ziele sind explizit, Provider ist auf In-memory begrenzt, Sicherheits- und Testrahmen sind definiert. |
| Tests | Vertragskonsistenz und Dokumentationsvalidator erfolgreich; Runtime fuer diese Welle `not applicable`. |
| Blocker | Keine offenen Vertragsblocker nach Benutzerfreigabe. |
| Evidenz | `ZIP_ARCHIVE_MODULE_DESIGN.md`, aktualisierte Kandidaten- und Planartefakte, Benutzerentscheid am 2026-07-30. |
| Nächster Schritt | Implementierungswelle als `AP-2026-020` aktiv. |

### AP-2026-018: W2c Console Message und Capability Catalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-018` |
| Ziel | Die freigegebenen Kandidaten `TC-2026-016` und `TC-2026-023` als zwei unabhängige portable Module implementieren und prüfen. |
| Scope | `toolbelt.core.console-message` Version `1.0.0` mit `toolbelt_core.USP_WriteConsoleMessage`; `toolbelt.metadata.capability-catalog` Version `1.0.0` mit `toolbelt_metadata.VW_ModuleCapabilities`; lokale und zentrale Installation; keine Präfixe, Severity-Optionen, Registry, Filter-TVF oder `module.yaml`-Runtime-Abhängigkeit. |
| Dependencies | W2c-Hauptempfehlung und ausdrückliche Benutzerfreigabe vom 2026-07-30; USP-, Modul-, Lifecycle- und Metadata-Verträge; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | beide Module `implemented` |
| Validation Status | `toolbelt.core.console-message`: `validated`; `toolbelt.metadata.capability-catalog`: `validated` |
| Release Status | beide Module `unreleased` |
| Akzeptanzkriterien | Unicode-sichere vollständige Message-Chunks mit PRINT oder NOWAIT; NULL ohne Ausgabe; kein fachliches Resultset; read-only Projektion kanonischer Database-level Marker; `valid`/`incomplete`/`invalid`; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Verträge und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Capture-Markern, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich; vollständige Adapter am 2026-08-29 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. |
| Blocker | Keine autonomen Fachgates offen; die zusätzliche ADO.NET-/ODBC-Clientprüfung bestand am 2026-10-19. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `CONSOLE_MESSAGE_MODULE_DESIGN.md` und `CAPABILITY_CATALOG_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.core.console-message/` und `Modules/toolbelt.metadata.capability-catalog/`; [W2c Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975), [Documentation Consistency 30573136009](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573136009) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Beide Module sind für den bestehenden Vertrag validiert; keine allgemeine Clientlatenz-/Darstellungszusage. Veröffentlichung bleibt unautorisiert. |

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-017: W2b-A JSON Path Exists

| Feld | Wert |
|---|---|
| ID | `AP-2026-017` |
| Ziel | Den freigegebenen Pfadprüfungs-Slice von `TC-2026-009` als portables Modul für SQL Server 2019+ implementieren und prüfen. |
| Scope | `toolbelt.json.path-exists` Version `1.0.0`; öffentliche `toolbelt_json.TVF_JsonPathExists`; Root-, Property-, Quote-, Array-Index- und Wildcard-Pfade; SQL-NULL-Propagation; fehlerfreies `0` bei ungültigem JSON oder Pfad; lokales und zentrales Deployment. Keine JSON-Konstruktoren, Aggregate, SQL CLR, Scalar-Wrapper oder SQL-Server-2025-Preview-Ranges/-Listen/`last`. |
| Dependencies | Gemeinsame W2b-Vertragsrunde und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | `1`/`0`/SQL-`NULL` als `int`; JSON `null` zählt als vorhanden; case-sensitive BIN2-Keyvergleich; Pfad- und JSON-Fehler verlassen den Funktionsvertrag nicht; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Prüfung und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 mit nativer Parität, synthetischen Fehler-/Collation-Fällen, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesign `JSON_PATH_EXISTS_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.json.path-exists/`; [W2b JSON Path Runtime 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943), [Documentation Consistency 30568128932](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128932) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen; Konstruktoren und Aggregate bleiben ohne Einzelvertrag und Freigabe zurückgestellt. |

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-016: Portable W2a – Truncation, Bucketing und Bigint-Bitoperationen

| Feld | Wert |
|---|---|
| ID | `AP-2026-016` |
| Ziel | Die gemeinsam geplanten Kandidaten `TC-2026-004`, `TC-2026-005` und `TC-2026-007` als drei portable Compatibility-Module implementieren und prüfen. |
| Scope | `toolbelt.datetime.truncate`, `toolbelt.datetime.bucket` und `toolbelt.binary.bit-operations`; typgetrennte öffentliche Date/Time-Inline-TVFs, interner Bucket-Optimizer-Core, Bigint-Shift/Count/Get/Set, Lifecycle, Central Deployment, Dokumentation und synthetische Contract-Tests. Keine Scalar UDFs, keine `datetime`-/`smalldatetime`-/`time`-Familie und kein `binary(n)`-/`varbinary(n)`-Provider. |
| Dependencies | Funktionsbezogener W2a-Vorschlag im Implementierungsplan und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Typstabile relationale APIs; dokumentierte Dateparts, Scale-7-, `DATEFIRST`-, Origin-, negative Floor-, Shift-, Vorzeichen- und Validation-Code-Semantik; lokale und zentrale Installation; Wiederholungsdeployment und Uninstall; native Parität auf SQL Server 2022/2025; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Contracts und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Runtime, nativer Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix einschließlich Kollisionsschutz und Bucket-Workload ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `DATETIME_TRUNCATE_MODULE_DESIGN.md`, `DATETIME_BUCKET_MODULE_DESIGN.md` und `BIT_OPERATIONS_MODULE_DESIGN.md`; [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509), [Documentation Consistency 30561235177](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561235177) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Keine autonome Validierung offen; weitere Performancezusagen würden einen getrennten Scope benötigen. |

### AP-2026-015: Portable W1 – Calendar Difference, Directional TRIM und URI Component

| Feld | Wert |
|---|---|
| ID | `AP-2026-015` |
| Ziel | Die gemeinsam besprochenen Kandidaten `TC-2026-002`, `TC-2026-008` und `TC-2026-024` als drei unabhängige, portable Module implementieren. |
| Scope | `toolbelt.datetime.calendar-difference`, `toolbelt.string.directional-trim` und `toolbelt.conversion.uri-component`; öffentliche inline TVFs, optionale URI-Scalar-APIs, Lifecycle, Dokumentation und synthetische Contract-Tests. |
| Dependencies | Funktionsbezogene Besprechung und ausdrückliche Benutzerfreigabe vom 2026-07-30; für TRIM und URI `toolbelt.core.generate-series` Version `1.0.0`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Anniversary-Regel, gerichtetes und typstabiles Trim sowie RFC-3986-Komponentenencoding sind explizit dokumentiert; keine implizite IRI-, Form-Encoding- oder Double-Decoding-Semantik. |
| Tests | Statische Contracts und GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; Anniversary-, Grenzwert-, Unicode-/UTF-8-, Fehler-, Paritäts-, Wiederholungs-, lokaler, zentraler und Uninstall-Scope geprüft. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix einschließlich Collation-, ASCII-/Unicode-/Large-Input- und Kollisionsfällen ist erfolgreich. |
| Evidenz | Benutzerfreigabe 2026-07-30; [W1 Portable Runtime 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399), [Documentation Consistency 30553118014](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118014) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Keine autonome Validierung offen; zusätzliche fachliche Ausbaustufen benötigen Einzelvertrag und Freigabe. |


Securitystand 2026-10-15: URI Component ist teilweise validiert; die beiden anderen W1-Module bleiben validiert. Historische Matrixnachweise qualifizieren die neuen URI-Limits nicht vollständig.

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-014: Inline-TVF-Alternativen für bestehende SVFs

| Feld | Wert |
|---|---|
| ID | `AP-2026-014` |
| Ziel | Für alle fachlich geeigneten vorhandenen SVFs eine semantisch äquivalente inline-TVF-API bereitstellen und die inline TVF als kanonischen relationalen Kern verwenden. |
| Scope | `toolbelt.conversion.base64`, `toolbelt.conversion.integer-base` und `toolbelt.validation.semantic-version`; sechs neue inline TVFs gemäß `SVF_INLINE_TVF_AUDIT.md`; vorhandene SVFs bleiben als Convenience-API erhalten. |
| Dependencies | Benutzeranforderung vom 2026-07-30; `DEC-2026-022`; bestehende öffentliche Verträge der sechs SVFs. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Kein TVF-Wrapper ruft lediglich die SVF auf; Fachlogik besitzt genau einen kanonischen Kern; Parität, Objekttyp, `NULL`- und Fehlersemantik, lokale und zentrale Installation sowie Lifecycle sind getestet; Objekt- und Moduldokumentation zeigt `APPLY` als bevorzugte Mengenverwendung. |
| Tests | Statische Modulverträge und vollständiger Dokumentationsaudit erfolgreich; Runtime auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parität, `APPLY`, Upgrade, Wiederholung, Kollision, zentralem Deployment und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix ist erfolgreich. |
| Evidenz | `DEC-2026-022`, `Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md`; [Base64 Runtime 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837), [Integer-Base Runtime 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860), [Semantic-Version Runtime 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984), [Documentation Consistency 30535377863](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377863). |
| Nächster Schritt | Keine autonome Validierung offen; weitere Wrapper benötigen einen getrennten Vertrag. |

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-013: Frei definierbare Zahlensysteme implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-013` |
| Ziel | `TC-2026-031` als Integer-Encode-/Decode-Capability mit frei definierbarem Alphabet implementieren. |
| Scope | `toolbelt.conversion.integer-base` Version `1.0.0`; vollständiger `bigint`-Bereich; Alphabet mit 2 bis 93 druckbaren ASCII-Zeichen außer `-`; kanonische Encode-/Decode-Darstellung und Overflow-Vertrag. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Encode/Decode verwenden denselben kanonischen Alphabetvertrag; Zeichen sind binär eindeutig; ungültiges Alphabet, ungültige Ziffer, Vorzeichen, `bigint`-Minimum, Null und Overflow sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-031`; kanonische Artefakte unter `Modules/toolbelt.conversion.integer-base/`; erfolgreicher [Runtime-Lauf 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070); persönlicher Brainstorm als Herkunft. |
| Nächster Schritt | Plusziffer-/NULL-Orakel am 2026-10-19 auf allen sechs Zielen qualifiziert; Release bleibt unautorisiert. |

Wartungsstand 2026-10-09 unter der bestehenden Einzelfreigabe vom 2026-07-30:
`+` ist eine reguläre Ziffer des gewählten Alphabets, kein zusätzliches
positives Vorzeichen; Dezimal-`+1` bleibt ungültig. Quellenstand SOURCE_ONLY,
neue Runtimequalifikation NOT_EXECUTED. Die vorstehenden Tests und Evidenzen
beschreiben historische Quellstände; daraus folgt keine neue Vollmatrix-
qualifikation der geänderten Quelle. API, Alphabetumfang und Version `1.1.0`
bleiben erhalten; keine Veröffentlichung.

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-012: Semantic-Version Parser und Comparator implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-012` |
| Ziel | `TC-2026-030` als strikt SemVer-2.0.0-konformen Parser, Comparator und Sort Key implementieren. |
| Scope | `toolbelt.validation.semantic-version` Version `1.0.0`; ASCII `varchar(8000)`; Core, Pre-release, Build Metadata, Validierung, Präzedenzvergleich und binärer Sort Key; keine allgemeinen Produktversionsformate. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | SemVer-2.0.0-Grammatik und Präzedenz vollständig; Build Metadata beeinflusst Vergleich und Key nicht; beliebig lange numerische Komponenten ohne verlustbehaftete Konvertierung; offizielle und synthetische Vektoren, Lifecycle und Dokumentation vollständig. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-030`; kanonische Artefakte unter `Modules/toolbelt.validation.semantic-version/`; erfolgreicher [Runtime-Lauf 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373). |
| Nächster Schritt | Keine autonome Validierung offen; Release bleibt unautorisiert. |

### AP-2026-011: Multi-Separator-Split Version 1 implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-011` |
| Ziel | `TC-2026-001` als portablen Split-Vertrag für mehrere einzelne Trennzeichen implementieren. |
| Scope | `toolbelt.string.split-characters` Version `1.0.0`; `TVF_SplitByCharacters`; stabile Ordinals, definierte leere Tokens, einzelne Separatorzeichen, binärer Collation- und LOB-Vertrag; keine mehrzeichigen Separatoren, Quote- oder Escape-Semantik. |
| Dependencies | `toolbelt.core.generate-series` Version `1.0.0`; vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Literalvertrag bleibt von Regex getrennt; Token und Ordinal sind deterministisch; `NULL`, NUL, leerer Input, aufeinanderfolgende Separatoren, Separator am Rand, Collations und Größenklassen sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker; die vollständige Pflichtmatrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-001`; kanonische Artefakte unter `Modules/toolbelt.string.split-characters/`; [Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708) erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen. S2 zu `TC-2026-032` ist separat freigegeben und implementiert; USP/Unquoting bleiben offen. |

Nachqualifikation 2026-10-19: Der aktuelle Kohortenstand einschließlich der betroffenen Security-/Wartungsverträge ist in der vollständigen Sechs-Ziel-Matrix und den zusätzlichen Status-/Clientfällen geprüft; ältere datierte Einschränkungen beschreiben den damaligen Stand. Siehe [V0c-Gatebericht](../Tests/V0C_RELEASE_GATE_STATUS.md).

### AP-2026-010: Identifier- und Multipart-Name-Toolkit implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-010` |
| Ziel | Den aus `RI-2026-011` formalisierten und freigegebenen Vertrag `TC-2026-029` als portables Metadata-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.metadata.identifier` Version `1.0.0`; `TVF_ParseMultipartName` und `SVF_QuoteMultipartName`; ein- bis vierteilige Namen, `[...]`, `]]`, ausgelassene mittlere Teile, stabile Validation Codes, lokales und zentrales Deployment. Keine Objektauflösung, Berechtigungsprüfung, doppelten Anführungszeichen oder CLR. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe des Benutzers vom 2026-07-30; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zustandsbasierter kanonischer Parser; genau eine Ergebniszeile; rechtsbündige Teile; vollständige Escape-, Omission-, Längen-, Collation-, Wrapper-, Deployment- und Lifecycle-Contracts; Dokumentation und Change-Impact-Registry gekoppelt. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker; die vollständige Pflichtmatrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-029`; kanonische Artefakte unter `Modules/toolbelt.metadata.identifier/`; [Identifier Runtime Run 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834) erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen; Release bleibt unautorisiert. |

### AP-2026-009: Portable Ganzzahlreihen implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-009` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-006` als portables Core-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.core.generate-series` Version `1.0.0`; `TVF_GenerateSeriesInt` und `TVF_GenerateSeriesBigInt`; portable T-SQL Inline TVFs; lokales und zentrales Deployment; Richtungs-, Default-, NULL-, Fehler-, Grenz-, Größen-, Join-, `CROSS APPLY`-, native Paritäts- und Lifecycle-Tests. Keine Dezimaltypen, persistente Numbers-Tabelle oder SQL CLR. |
| Dependencies | Besprochener und am 2026-07-30 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu einem anderen Toolbelt-Modul. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Inline TVFs im Schema `toolbelt_core`; typstabile `int`-/`bigint`-Resultsets; gemeinsamer `bigint`-Kern; richtungsabhängiger Default; keine stille Kürzung; Enginefehler bei Schritt `0` und nicht darstellbarer Zeilenzahl; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine offene Pflichtvalidierung; Zehn-Millionen-Lastfall mit Ergebnisprüfung erfolgreich, Zeitmessung optional. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; kanonische Artefakte unter `Modules/toolbelt.core.generate-series/`; [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) erfolgreich. |
| Nächster Schritt | Den validierten Funktionsstand stabil halten; optionale Zeitmessungen nur bei eigenem Auftrag. Veröffentlichung über die ausdrückliche V0c-Releaseentscheidung. |

### AP-2026-008: Base64/Base64URL-Modul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-008` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-012` als portables Conversion-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.conversion.base64` Version `1.0.0`; `SVF_Base64Encode` und `SVF_Base64Decode`; T-SQL/XML-Provider; lokales und zentrales Deployment; RFC-4648-, native Paritäts-, Fehler-, Größen- und Lifecycle-Tests. Kein CLR, keine Zeichenkodierung und keine Datei-I/O. |
| Dependencies | Besprochener und am 2026-07-29 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu ResultTable. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Scalar UDFs im Schema `toolbelt_conversion`; Standard- und URL-safe-Ausgabe; Decode beider Alphabete, optionales Padding und definierter Whitespace; unveränderte Providerfehler; keine String-zu-Binär-Konvertierung; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine offene Pflichtvalidierung; 4-MiB-Lastfall mit Ergebnisprüfung erfolgreich, Zeitmessung optional. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.conversion.base64/`; [Base64 Runtime Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) erfolgreich. |
| Nächster Schritt | Den validierten Funktionsstand stabil halten; optionale Zeitmessungen nur bei eigenem Auftrag. Veröffentlichung über die ausdrückliche V0c-Releaseentscheidung. |

### AP-2026-007: Entscheidungsvorbereitung für das zweite Modul

| Feld | Wert |
|---|---|
| ID | `AP-2026-007` |
| Ziel | Die nächsten kleinen Compatibility-Kandidaten so vergleichen, dass die funktionsbezogene Benutzerbesprechung ohne verdeckte Typ-, Provider- oder Fehlerentscheidungen geführt werden kann. |
| Scope | Vertiefter Vergleich von `TC-2026-004` und `TC-2026-012`; dokumentierte Empfehlung, Vertragsfragen, Provideroptionen, Testdimensionen, Abhängigkeiten und Implementierungs-Gates. Keine SQL-Implementierung und kein Modulmanifest. |
| Dependencies | `AP-2026-003`, `AP-2026-005`, funktionsbezogenes Implementierungs-Gate und Phase-2-Abhängigkeit aus der Roadmap. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Bevorzugter Besprechungskandidat nachvollziehbar ausgewählt; Alternative mit konkretem Grund zurückgestellt; offene Benutzerentscheidungen und Pflichtprüfungen sichtbar; kein öffentlicher Funktionsvertrag oder Implementierungsrecht behauptet. |
| Tests | Primärquellenabgleich gegen Microsoft Learn und RFC 4648; Kandidaten-, Backlog-, Roadmap-, Link-, Datenschutz- und Change-Impact-Prüfung. Runtime-Tests sind für diese reine Entscheidungsvorbereitung `not applicable`. |
| Blocker | Keine. Der konkrete Vertrag wurde am 2026-07-29 besprochen und freigegeben; das pauschale Referenzmodul-Gate wurde durch `DEC-2026-021` scopebezogen präzisiert. |
| Evidenz | `Documentation/Research/SECOND_MODULE_SELECTION.md` und aktualisierte Kandidaten `TC-2026-004`/`TC-2026-012`; geprüft am 2026-07-29. |
| Nächster Schritt | Abgeschlossen; Umsetzung erfolgt in `AP-2026-008`. Die offenen ResultTable-Pflichtfälle bleiben ein eigenes Arbeitspaket. |

### AP-2026-006: Dokumentationsbaseline und inkrementeller Drift-Schutz

| Feld | Wert |
|---|---|
| ID | `AP-2026-006` |
| Ziel | Die vollständige Dokumentationsbaseline herstellen und nachfolgende Änderungen über explizite, diff-basierte Artefaktkopplungen synchron halten. |
| Scope | Statuskorrekturen, getrennte Modulstatusdimensionen, Modulregistry, gekoppelte Dokumentationspfade, generierte Statusabschnitte, inkrementeller Validator, pfadbezogene CI und Pull-Request-Checkliste. |
| Dependencies | aktueller `main`, implementiertes ResultTable-Modul und `DEC-2026-020`. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Einmaliger Vollaudit erfolgreich; bekannte Statusdrift beseitigt; Runtime-CI nicht mehr durch reine Dokumentationsänderungen ausgelöst; Folgeprüfungen diff-basiert; geschützte Lizenzinhalte unverändert. |
| Tests | Python-Standardbibliothek-Validator, modulspezifische statische Prüfung, Markdown-Linkprüfung, YAML-/Workflow-Strukturprüfung, Datenschutz-/Secret-Diffprüfung und GitHub Actions. |
| Blocker | Keine. |
| Evidenz | Lokaler vollständiger Baseline-Audit am 2026-07-29 erfolgreich; [Documentation Consistency Run 30453805254](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805254) und [ResultTable Runtime Run 30453805186](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805186) vollständig erfolgreich. |
| Nächster Schritt | Abgeschlossen; die laufende Dokumentationskonsistenz wird durch den inkrementellen Validator geschützt. |

### AP-2026-005: SQL-Server-Toolbelt-Landschaft und Prior Art

| Feld | Wert |
|---|---|
| ID | `AP-2026-005` |
| Ziel | Öffentliche SQL-Server-Toolbox-, Capability-, Test-, Diagnose-, Maintenance- und Parallelisierungsprojekte systematisch vergleichen, belastbare Prior Art für die bereits erfassten Execution-Themen dokumentieren und neue Toolbelt-Lücken ableiten. |
| Scope | Landschaftsdokument mit direkter Einordnung von 16 Projekten; vertiefter Vergleich der direkten Capability-Libraries; zweite Session, rollback-unabhängiges Logging, Parallelisierungsprovider, Console, Error Handling und Cancellation; Präzisierung von `TC-2026-012`; neue Kandidaten `TC-2026-023` bis `TC-2026-028`; quellenbasierte Vorprüfung des persönlichen Brainstorms einschließlich PowerShell, Python, REST/Web und KI/Chat. |
| Dependencies | `AP-2026-001`, `AP-2026-004`, Repository-Grenzen, Third-Party-/Source-Policy und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Projekte nach Rolle, Technik, Packaging, Lizenz-/Statushinweis und Repository-Ziel eingeordnet; direkte Analogien von bloßen Skriptkatalogen getrennt; Prior Art für zweite Session, Parallelisierung, Host-Automation, Python, REST und KI aus Primärquellen dokumentiert; übertragbare und zu vermeidende Muster benannt; neue Kandidaten vollständig und ohne Implementierungszusage erfasst. |
| Tests | Quellen- und Linkstrukturprüfung; Duplikatprüfung gegen kuratierte Kandidatenlisten, persönlichen Brainstorm und Architekturverträge; Third-Party-, Datenschutz- und Secret-Gate; ausschließlich Dokumentations- und Backlogänderungen. |
| Blocker | Keine für Research; Codeübernahme benötigt zusätzlich eine datei- und versionsbezogene Lizenzprüfung. Jede Funktion benötigt vor Implementierung weiterhin eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md`, präzisierter Kandidat `TC-2026-012`, aktualisierte Kandidaten `TC-2026-014`/`TC-2026-015` und neue Kandidaten `TC-2026-023` bis `TC-2026-028`; geprüft am 2026-07-29. |
| Nächster Schritt | Forschungsergebnis nach Abschluss der ResultTable-Validierungswelle mit dem Benutzer priorisieren; keine automatische Aktivierung eines weiteren Implementierungsarbeitspakets. |

### AP-2026-004: Backlog Research Wave 2 – Execution Infrastructure

| Feld | Wert |
|---|---|
| ID | `AP-2026-004` |
| Ziel | Die vom Benutzer angestoßenen Ideen zu zweiter Session, rollback-unabhängigem Logging, Parallelisierung, Error Handling, Console-Ausgabe und Gruppenabbruch quellenbasiert erfassen und um unmittelbar notwendige Supporting Capabilities ergänzen. |
| Scope | `TC-2026-014` bis `TC-2026-022`; Toolbelt-Kandidaten für autonome Ereignisprotokollierung, Work Queue, Console, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker Lease und sicheren Work-Type-Katalog. |
| Dependencies | Repository-Grundaufbau, Backlog-Curator-Regeln und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, vollständige Felder, Primärquellen, klare Trennung dokumentierter Engine-Semantik von offenen Architekturentscheidungen sowie einen nächsten Besprechungsschritt; kein Runtime-Objekt und keine Implementierungsfreigabe werden erzeugt. |
| Tests | Duplikatprüfung gegen alle drei Kandidatenlisten und bestehende Architekturverträge; Quellenprüfung gegen Microsoft Learn und den Microsoft SQL Server Blog; Datenschutz- und Secret-Gate. |
| Blocker | Keine für die Research-Erfassung; jede spätere Funktion benötigt eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Backlog/TOOLBELT_CANDIDATES.md`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Kandidaten einzeln nach Nutzen und Abhängigkeiten mit dem Benutzer besprechen; keine automatische Aktivierung als Implementierungsarbeitspaket. |

### AP-2026-002: ResultTable-Infrastruktur implementierungsreif spezifizieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-002` |
| Ziel | Den Kandidaten `TC-2026-003` als erstes `toolbelt_core`-Modul ohne offene Vertragsfragen spezifizieren. |
| Scope | Modulgrenze, Objektinventar, öffentliche Schnittstelle, Schemaquelle, Metadaten- und Datentypnormalisierung, `@KeepData`, Preflight, DDL, Transaktionen, Fehler, Deployment, Lifecycle und Testmatrix. |
| Dependencies | `TC-2026-003`, `USP_CONTRACT.md`, Modul- und Deployment-Modell. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; einzige Procedure klassifiziert; keine ungeregelten weiteren persistenten Objekttypen benötigt; Referenztabellen- und Vertrauensgrenze definiert; interne Temp-Namensregel festgelegt; Fehler-, Transaktions-, Collation-, Datentyp-, Deploy- und Uninstall-Verträge dokumentiert; vollständige Testmatrix vorhanden. |
| Tests | Statischer Abgleich gegen USP-Vertrag, T-SQL-Regeln, Modul-/Deployment-Modell, Namenskonventionen, Datenschutz, Supportmatrix und Architekturentscheidungen; Runtime-Tests für diese reine Designwelle `not applicable`. |
| Blocker | Keine |
| Evidenz | `Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md`, `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017`; geprüft am 2026-07-29. |
| Nächster Schritt | `AP-2026-003` ausführen. |

### AP-2026-001: Backlog Research Wave 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-001` |
| Ziel | Eine erste belastbare, versionsbezogene Kandidatenwelle für SQL Server 2019, 2022 und 2025 erstellen. |
| Scope | `Backlog/TOOLBELT_CANDIDATES.md`; vorhandene Kandidaten präzisieren und neue Compatibility-, Core-, String-, Datetime-, JSON- und Binary-Kandidaten erfassen. |
| Dependencies | Repository-Grundaufbau und Backlog-Curator-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, Ziel-Repository, Versionsbezug, spätere native Funktion, Nutzen, Technologieoptionen, Performance-/Security-Aspekte, Plattformgrenzen, Duplikatprüfung, Primärquellen, Prüfdatum und nächsten Schritt. |
| Tests | Primärquellenprüfung gegen Microsoft Learn; Duplikatprüfung innerhalb der Toolbelt-Listen; Abgrenzung zu `SQL_Server_Analyze`; Fakten und offene Punkte getrennt formuliert. |
| Blocker | Keine |
| Evidenz | `TC-2026-001` bis `TC-2026-013`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Weitere Kandidatenwellen nach Abhängigkeit oder durch den Backlog Curator ergänzen. |

## Vorlage

```markdown
### AP-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | AP-YYYY-NNN |
| Ziel | <Messbares Ziel> |
| Scope | <Betroffene Module, Schemas und Objekte> |
| Dependencies | <Arbeitspakete, Module oder externe Voraussetzungen> |
| Priorität | <P0 / P1 / P2 / P3> |
| Status | <proposed / researched / ready for development / active / blocked / completed / rejected> |
| Implementation Status | <nur für Module; aus module.yaml abgeleitet> |
| Validation Status | <nur für Module; aus module.yaml abgeleitet> |
| Release Status | <nur für Module; aus module.yaml abgeleitet> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.

### Clone W1: zusätzliche Lifecycle-Sichtbarkeit einzeln freigegeben

Am 2026-10-02 bestätigte der Benutzer nach konkreter Besprechung: "Ja, Lifecycle-Sichtbarkeitsgate freigeben". Bestehendes DB-VIEW DEFINITION und SELECT auf sys.sql_expression_dependencies werden für Deploy/Uninstall vor Änderungen und unter AppLock vorausgesetzt; fehlender oder unklarer Nachweis blockiert53926/2. Keine GRANT-Aktion. Computed-only53901/3 bleibt getrennt. Die finalen öffentlichen Adapter vom 2026-10-03 bestanden die native Lifecycle-Nachqualifikation einschließlich 0-/NULL-Predicate-Injektionen vor Änderungen und unter AppLock. CI am geprüften Head 76888216 bestanden; ein tatsächlicher Lowpriv-Principal bleibt offen.

### Tabellenklon W1: finaler öffentlicher Scope 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

### XLSX-Anzeigeformatierung 1.2.0 – genehmigte Umsetzung

Stand 2026-10-04, Codex: die einzeln freigegebene Anzeige-TVF ist im bestehenden SAFE-Provider additiv implementiert. Acht Inputs, zwei Outputs, zehn Literalformate, en-US/de-DE/tr-TR, exakte SqlDecimal-Rundung half-away-from-zero, Datetimecarry/time24h-Status8 und unveränderte Typquote wurden konkret genehmigt. Raw-/Typquellen unverändert. Begrenzte aktuelle Offline- und lokale Nativequalifikation vom 2026-10-04 bestanden; zentrale1.2-Nutzung, vollständige Matrix, Minimalrechte und aktuelle Head-CI bleiben offen.

Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.

Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`. Keine neue Rechte-/Providergrenze.

Historische 1.0-/1.1-Nachweise bleiben getrennt. [Vertrag](../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md).

Ergänzung 2026-10-05, Codex: Der öffentliche Adapter-Slice
`DisplayCentral10Upgrade` bestand zentral auf Linux2019/latest CL150:
genuine1.0→1.2 mit frischer Session, neun Slots/vier CLR-Bindings, Display-Lifecycle,
Repeat, installierte Display.Contract/Safety sowie Clientmetadaten und
Raw→Type→Display aus frischer Consumerdatenbank. Confirm0/Uninstall, äußerer
eigener Prozesswatchdog und unabhängiger frischer OwnDB-/OwnTrustaudit bestanden;
keine Konfigurations-/Rechteänderungen. Diese konkreten zentralen Lücken sind
geschlossen; vollständige Lifecycle-/Kollisionsmatrix, weitere Ziele,
Minimalrechte und Heap bleiben offen. Status weiterhin teilweise validiert und
unreleased; keine neue fachliche API oder Providerfreigabe.

Ergänzung 2026-10-05, Codex: `DisplayCentralLifecycle` bestand auf demselben
Linux2019/latest-/central-/CL150-Ziel mit vier postDROP-/preCOMMIT-Rollbackfällen
und zwei AppLock-Abweisungen. Der vorhandene vollständige Lifecycle-Snapshot,
neun Slots/vier Bindings, exakter SAFE-Binaryhash und neutrale Session blieben
erhalten. Bestätigter Uninstall, äußerer eigener Prozesswatchdog und frischer
unabhängiger OwnDB-/OwnTrustaudit bestanden ohne Konfigurations-/Rechteänderungen.
Der frühere gemischte Setup-Prüflauf bleibt FAILED_CLEANED; ein gezielter
Read-only-Probe begründet die getrennte Sessionzustandsprüfung. API/Consumer/
Upgrades nicht wiederholt; Kollisionsmatrix, weitere Ziele, Minimalrechte und
Heap bleiben offen. Kein neuer Funktions-/Provider- oder Releaseumfang.

Ergänzung 2026-10-05, Codex: `DisplayCentralFutureCollisions4` bestand mit vier
Fremdslot-Fixtures auf genuine1.1 zentral Linux2019/latest CL150. Aktueller1.2-
Deploy weist ab und bewahrt vollständigen Snapshot; aktueller release-aware
Uninstall bewahrt exakten Fremdslot. Fünf genuine1.1-Installationen einschließlich
Setup/Restores, native Zeugen, finaler aktueller Uninstall, äußerer eigener
Prozesswatchdog und unabhängiger frischer OwnDB-/OwnTrustaudit bestanden ohne
Konfigurations-/Rechteänderungen. Originale Vorgänger-Uninstalls, weitere
Kontexte, Minimalrechte und Heap bleiben offen; keine erneute API-/Consumer-/
Upgrade- oder Lifecycle-six-Qualifikation.
