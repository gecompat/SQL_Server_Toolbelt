# SSIS-Debug: Prüfmatrix und Evidenz

Der aktuelle Entwicklungsvertrag steht im
[SSIS_CURRENT_API_CONTRACT.md](../../../Documentation/Architecture/SSIS_CURRENT_API_CONTRACT.md).

## Aktuelle Lieferung und ihr begrenzter Nachweis

Die [aktuelle Binarymatrix](Qualification/Current.Windows.CL.20261029.json)
belegt sechs Windows-Kontexte: SQL2019/CL150, SQL2022/CL160 und SQL2025/CL170
jeweils lokal und zentral. Je 206 Assertions prüfen den aktuellen Default,
38 geordnete Parameter einschließlich 24 `bigint`-Limits, Hilfe vor Validierung,
editierbare typisierte Entwurfswerte und Rückgabe der vollständigen Vorlage,
ResultTable-Schutz sowie tatsächlich ausgeführte geordnete Row-Count-/Flatfile-
Debug-Scripts mit festen synthetischen Sollwerten. Sechs unabhängige Audits
bestätigen Bereinigung und Eingabepins. Ein vorheriger Adapterfehler samt
erfolgreichem Audit bleibt im Nachweis erhalten.

Die [aktuelle ZIP-Qualifikation](Qualification/Current.InstallPackage.20261029.json)
prüft den exakten entpackten Build separat auf SQL2019/CL150 lokal und
SQL2025/CL170 zentral: Neuinstallation, Wiederholung, aktuelle Fachfälle und
Deinstallation/Wiederholung mit zwei unabhängigen Abschlussaudits. Die
[Standalone-Runtimequalifikation](../../../Releases/1.0.0/ssis-current-standalone-runtime-qualification.json)
prüft denselben vollständigen reinen T-SQL-Batch auf beiden Enginezielen in
beiden Modi: vier Installationskontexte mit Repeat, aktuelle Fachfälle,
Sitzungs-/Transaktions-Negativkontrollen und zwei unabhängigen Audits.
Die [Installer-Provenienz](../../../Releases/1.0.0/ssis-current-standalone-installer.json)
bindet die ausgeführten Bytes an Paket und Paketqualifikation.

`Runtime/Invoke-CurrentLab.ps1` verwendet die unveränderte strikte Lab-
Schutzhülle und eigene aktuelle Fälle. `Invoke-ComponentsV2Audit.ps1` bleibt
der unabhängige lesende Audit. Fünf Offline-Lieferprüfungen kontrollieren
aktuelle Bindungen und Manipulationsfälle; der SQL-Parameteradapter wird ohne
Verbindung mit tatsächlicher `SqlValue`-Konvertierung geprüft. Das lange
Framework-Transportexperiment mit 2730 Einheiten verwendet ausdrücklich
512 MiB Ausgabebudget und ist kein Nachweis für das 128-MiB-Defaultbudget.

Diese Fälle belegen weder die übrigen CLs neuerer Engines noch tatsächliche
SSIS-Ausführung, Windows-Anmeldung, SSMS-GUI, authentifiziertes TLS oder den
administrativen Trust-Opt-in des Installers. Aktuelle Head-/Main-CI und
Integration sind separate Gates. Modulstatus: teilweise validiert und
unveröffentlicht. Die [Bedienungsanleitung](../Documentation/CurrentInstallation.md)
führt zu den aktuellen Dateien und Ergebnissen.

## Historische Nachweise

Die nachfolgenden V1- und Komponenten-V2-Aufzeichnungen sind historische
Nachweise ausschließlich ihrer ursprünglichen Builds und Inputs; sie
qualifizieren den aktuellen Defaultvertrag nicht. Der Treiber
`Runtime/Invoke-ComponentsV2Lab.ps1`
bindet den unveränderten bisherigen Labtreiber und die neuen Fälle getrennt.
`Runtime/Invoke-ComponentsV2Audit.ps1` prüft dessen private Abschlussjournale mit
einer eigenen ausschließlich lesenden Verbindung. Eine Syntax- oder
Adapterprüfung allein ist kein nativer Funktionsnachweis.

Die historische [V2-Binarymatrix](Qualification/ComponentsV2.Windows.CL.20261028.json)
bestand zwölf Windows-Engine-/CL-/Modusfälle mit jeweils eigenem
Bereinigungsaudit. Der [gezielte Variablenplannachweis](Qualification/ComponentsV2.VariablePlan.20261028.json)
bestand den vollständigen 256-Gruppen-Ausdruck und feste NULL-/Unicode-Orakel
mit explizitem `unlimited` und endlichen äußeren Watchdogs. Die separaten
30-Sekunden-Budgetfehler der vollständigen Zielentdeckung bleiben erhalten;
dieser Nachweis behauptet keine Default-Budget-Abnahme dafür.

Das damalige V2-ZIP ist offline auf gebundene Artefakte, Quellen, Attribution und
Manipulation geprüft. Die [native ZIP-Qualifikation](Qualification/ComponentsV2.InstallPackage.20261028.json)
bestand zwei Windows-Paketfälle mit insgesamt 1190 Assertions und zwei
unabhängigen Cleanup-Audits. Die [Standalone-Installer-Qualifikation](../../../Releases/1.0.0/ssis-components-v2-standalone-installer-runtime-qualification.json)
bestand zwei Windows-Zielkontexte in local und central, einschließlich vier
V2-Opt-in-Vorlagenprüfungen und zwei unabhängigen Audits. Die
[Installer-Provenienz](../../../Releases/1.0.0/ssis-components-v2-standalone-installer.json)
bindet die erzeugten T-SQL-Bytes an Paket und Paketqualifikation. Das
`integration_binding`-Objekt des Runtimeberichts dokumentiert genau zwei
Metadatenänderungen: CRLF→LF-Normalisierung der ZIP-Qualifikation und den
zugehörigen Qualifikationshash in der Installerprovenienz. Die ursprünglichen
nativen Eingabepins bleiben unverändert; Installerbytes und
Qualifikationssemantik sind gebunden.

Native Records belegen keine CI; Head-/Main-CI und Integration werden am
jeweiligen PR-/Merge-Head getrennt nachgewiesen. Weitere Plattformen und
authentifiziertes TLS bleiben unqualifiziert; Veröffentlichung ist nicht
freigegeben. Der Modulstatus bleibt teilweise validiert und unveröffentlicht.
Der V1-Installer wird nicht als V2-Lieferung umgedeutet.

Stand 2026-10-25. Die nativen Nachweise unten behalten ihre ursprünglichen
Ausführungsdaten und Buildbindungen. Alle eingecheckten DTSX-Fixtures sind synthetisch und werden
mit `Fixtures/build_fixtures.py` erzeugt; keine Kundenpakete oder Runtimewerte.

`Framework/Invoke-Contract.ps1` prüft den exakten ScriptDom-Pin und führt
isolierte .NET-Framework-Prozesse mit begrenztem Stack und Watchdog aus.
`Full` enthält gemäß aktuellem `Invoke-Contract.ps1` 26 begrenzte Kindprozesse:
JSON/V1-Grenzen, Format-6/8-Import und -Übersetzung, V2-Grund- und UTF8-Cases,
kombinierter Scale-Fall, Sicherheits-/SQL-Regressionsfälle, Release- und
kooperatives Budget sowie fünf Parsergrenzen und sieben Parserformen. Die
V2-spezifischen Profile `ComponentsV2`, `ComponentsV2Branch` und
`ComponentsV2Utf8Collation` bleiben separat auswählbar. Frühere Full21- und
Full23-Nachweise behalten ihre damaligen Eingaben und Umfänge; keiner davon
ersetzt die aktuellen V2-Installationsrecords. Diese Frameworkprofile öffnen
keine SQL-Verbindung.

Für die ausdrückliche CL-Abnahme akzeptiert `Invoke-LabContract.ps1`
`-CompatibilityLevel 150|160|170` nur soweit die gewählte Engine dies unterstützt.
Der Adapter setzt und verifiziert den Wert ausschließlich in seinen eigenen
Test- und Consumerdatenbanken und hält die tatsächlichen Werte privat fest.
Ohne den Parameter bleibt der bisherige Engine-Default unverändert.
`-ReleaseRights` verlangt `-Full` und ergänzt einen loginlosen eigenen Caller:
Help mit EXECUTE, Vorlage/Analyse mit expliziter Metadatensicht ohne Quell-SELECT,
einzeln verweigerte Rechte mit strikten SQL-Fehlerorakeln sowie Erhalt einer
befüllten ResultTable bei Überschreitung der Paketbytegrenze. Keine Server-Logins,
CrossDB-Identitätsverwaltung oder Erweiterung der Funktions-/Sicherheitsbudgets.
Dies beschreibt den Harness; tatsächliche Ergebnisse werden separat gebunden.
Der Ausgabegrenztest umfasst außerdem ursprüngliche Komponenten-IDs mit
3999/4000/4001 UTF-16-Einheiten. Die öffentliche Spalte bleibt `nvarchar(4000)`;
eine längere ID wird vor der SQL-Materialisierung als `resource_limit` abgewiesen.
Zulässige IDs müssen vollständig erhalten bleiben; eine bereits befüllte
ResultTable darf durch die Abweisung nicht verändert werden.

Historischer Full21-Nachweis: 21 Kindprozesse einschließlich gezielter Reviewregressionen zu
Lookup-Dezimalprodukt, Textlängen, SUM/AVG/LEN, Integerpräzedenz,
NULLbarkeit und Zeitpräzision, Erhalt von WHERE-Klauseln, Katalogdrift,
reiner TVF ohne Alias und Unicode-Lookup-Collations. SQL-Vorfilter, JSON,
Paketgröße, XML-Tiefe, Komponenten, Eingaben, Spalten und Pfade haben gezielte
minus-eins/exakt/plus-eins-Orakel. UTF-16, DTD-Ablehnung, doppelte Identitäten,
Sensitive-Redaction und Managed-Source-Aliase 11 bis 17 sind enthalten.
Reproduzierbarer Framework-Build und fokussierte Quellprüfungen bestanden.
Zusätzlich bestehen zwölf isolierte SQL-Syntaxprüfungen
(`Framework/Invoke-Syntax.ps1`) für Source und expandierte Deploy-/Uninstall-
Scripts in SQL150/160/170. Binärliterale wurden hierfür normalisiert.
Das ist keine native SQL- oder SSIS-SDK-Qualifikation.

`Runtime/Invoke-CoreContract.ps1` mit `-Full` bindet `Invoke-V1Cases.ps1`
je DTSX-Format sowie `Invoke-ComponentCases.ps1` einmal im Format 8 ein.
`Invoke-ApiCases.ps1` prüft 14 Parameter und das tatsächliche 13-spaltige
Resultset einschließlich Typen, Längen, NULLbarkeit und ResultTable-Collation.
`Invoke-LifecycleCases.ps1` prüft atomare Kollisions-, Dependency-, Consumer-,
AppLock- und Callertransaktionsablehnung. Der Adapter
`Runtime/Invoke-LabContract.ps1` wählt schema-validierte, bereite Labziele,
verifiziert den reproduzierbaren Release und dessen exakte Dependencypins
und legt ausschließlich eigene synthetische Testdatenbanken an. Er prüft
Deployment/Repeat/Uninstall/Repeat und stellt den eigenen DB-/Trust-/
Konfigurationsscope wieder her. Eine frische Kontrollverbindung bestätigte
anschließend je Ziel den Cleanup. Keine Runtime-Logs oder Labdetails werden
als Repositoryartefakte gespeichert.

Native Qualifikation vom 2026-10-17 am finalen Produktbuild. Aufruf je Version:

```powershell
& Tests/Runtime/Invoke-LabContract.ps1 -Version 2025 -Patch base `
    -Modes local,central -Full -PredecessorRoot $previousReleaseRoot `
    -DatabaseCollation Latin1_General_100_CI_AS_SC_UTF8
```

`previousReleaseRoot` enthält die separat verifizierten Originalartefakte
von Parser 2.0.0 und Table Clone 4.1.0. Kein Hash- oder Markerersatz für ein
echtes Upgrade. Die ursprüngliche Triggerfixture läuft vor, die aktuelle
Triggerfixture nach dem gekoppelten Upgrade auf 2.0.1/4.1.1.

| SQL Server / Datenbankcollation | Modus | Kern | API | Lifecycle | Gesamtstatus |
|---|---|---:|---:|---:|---|
| 2019 / BIN2 | local / central | je 181 | je 61 | je 15 | bestanden |
| 2022 / CS_AS | local / central | je 181 | je 61 | je 15 | bestanden |
| 2025 / CI_AS_SC_UTF8 | local / central | je 181 | je 61 | je 15 | bestanden |

Das sind 1.542 erfolgreiche native Assertions in sechs vollständigen Läufen.
Deployment/Repeat/Uninstall/Repeat, echte Vorgängerupgrades mit Triggerregression
und frische Cleanup-Audits bestanden auf allen drei ausgewählten Zielen.

Vollständige Namen: `Latin1_General_100_BIN2`, `Latin1_General_100_CS_AS`,
`Latin1_General_100_CI_AS_SC_UTF8`. Die Collations wurden risikobasiert auf
die Engineversionen verteilt; keine vollständige kartesische Collationmatrix.
Die nativen Aufrufe verwenden den öffentlichen Standarddialekt SQL150;
die Syntaxprofile SQL150/160/170 sind zusätzlich offline geprüft.

Die fachlichen Orakel umfassen:

- Alle generierten CTE-Stufen ohne Vorbereitung in frischen Sessions,
  genaue Ziel-/Stufenauswahl sowie ausführbare bekannte Vorstufen bei
  unbekanntem Nachfolger; Conversion, gemeinsamer Eingangsstand bei Overwrite
  und Variablenshadowing im näheren Scope.
- Direkte DECLARE-Änderungen: Split-Schwelle erhält Cache und Trefferauswahl;
  relevanter Lookupparameter ändert Fingerprint und tatsächlich gelesene
  Referenzmenge. Cache-Ownership-Manipulation wird abgewiesen.
- Composite-/NULL-/Mehrfachtreffer, eingefrorene beliebige Auswahl,
  explizite Sortierung und Unicode-Textschlüssel mit abweichenden Collations.
- Help zuerst, Resultsetanzahl, alle KeepData-Konstellationen, Dummyspalten,
  Indexerhalt, atomare Fehler sowie gesunde und nicht mehr schreibfähige
  Callertransaktionen und SET-Erhalt.
- Parallele unbestätigte DML als Dirty Read und tatsächliches Warten auf
  Sch-M trotz NOLOCK; Cross-DB-Aufruf und Ausführung aus einer Clientdatenbank.
- Loginloser synthetischer Principal mit den erforderlichen Metadatenrechten
  ohne Quell-SELECT; fehlende Metadatensicht blockiert die Analyse.
- Views/lokale Synonyme, reine TVF und RLS-Funktion sowie ausgewählte
  berechnete Spalte; prozedurale Computed-UDF, versteckter TVF-Tabellenzugriff,
  Remote-Synonyme und schreibende/mehrteilige Quelltexte bleiben blockiert.

Die nativen Regressionen führten zu fünf Korrekturen: vollständiger
SelectStatement-Kontext beim Rendern von QueryExpression (WHERE-Erhalt),
optionaler Alias reiner TVFs, XACT_STATE-Guard vor dem CLR-Aufruf,
präzise Behandlung katalogbelegter interner Computed-Spaltenkanten und
undelimitierte, streng begrenzte COLLATE-Namen. Computed-Spaltenkanten bleiben
im Driftfingerprint; die UDF-/Remote-/Mehrdeutigkeitsprüfungen bleiben aktiv.

Frühere Fehlerläufe sind kein PASS. Ihr eigener Datenbank-/Trust-/
Konfigurationsscope wurde wiederhergestellt und frisch geprüft. Reale
Runtimeausgaben, Hashjournale und Labdetails bleiben außerhalb des Repositories.

Die pauschale TLS-Sperre ist durch die Benutzerklarstellung vom 2026-10-16
ersetzt. `Functional` übernimmt den expliziten booleschen Trustwert des
schema-validierten Vertrags; Encrypt bleibt True, kein automatischer Fallback.
Diese Fachläufe verwenden explizit `TrustServerCertificate=True`.
Authentifizierte TLS-Abnahme bleibt separat `not executed`.

Die damalige offene Integrations-CI ist inzwischen abgeschlossen:
[PR #327](https://github.com/gecompat/SQL_Server_Toolbelt/pull/327) wurde am
2026-10-18 integriert. Am Mergecommit `2df46efc9e5e255b545408c9b1acab91679b7b11`
bestanden [SSIS Offline](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/39151017241),
[Table Clone Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/39151017199)
und [Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/39151017301).
Diese am 2026-10-19 lesend bestätigten Ergebnisse gelten für genau diesen
Commit und Workflow-Scope. Jeder spätere PR benötigt eigene Head-CI;
Release und authentifizierte TLS-Abnahme bleiben separat offen.
SSIS-SDK-/Engineparität, Produktionslast und eine vollständige Kombination
aller Ressourcenmaxima werden nicht behauptet. Linux ist für diese UNSAFE-
Assembly nicht anwendbar. Der Modulstatus bleibt teilweise validiert und
unveröffentlicht.

Verarbeitungsumfang der wiederaufgenommenen Welle: ein Owner, derselbe
unabhängige Reviewer, ein initialer Auftrag und zwei begrenzte Befundfolgeaufträge.
Der zweite Folgeauftrag war eine vorab begrenzte Ausnahme für die neu nativ
erkannte Computed-Dependency-Sicherheitsgrenze. Keine weitere Reviewkette.
Die abschließende COLLATE-Renderkorrektur wurde mit geschlossener Tokenprüfung,
Frameworkregression und nativer Matrix geprüft; keine unabhängige Prüfung
jedes finalen Bytes wird behauptet. Unveränderte Parser245-/Guard60-Nachweise
werden wiederverwendet. Keine neue pauschale Runtime-CI, keine Runtime-Logs
im Repository; Token-/Kostenmessung nicht verfügbar, endlicher Aufgaben-/
Agentenumfang statt behauptetem Geldlimit.

Der PR ergänzt eine begrenzte Windows-CI in
[`ssis-debug-build.yml`](../../../.github/workflows/ssis-debug-build.yml):
ein Job für den zweimaligen aktuellen Providerbuild mit exaktem ScriptDom-Pin,
Full21, fünfzehn Source-/Beispielsyntaxfälle und PowerShell-Adaptersyntax.
`-SourceOnly` verlangt keine privaten Releaseartefakte; der normale Syntaxrunner
prüft einundzwanzig Fälle einschließlich expandierter Deploymentartefakte.
Dieser CI-Build ist kein neues qualifiziertes SQL-Releasebinary; weder
Dependency-/Trustpins noch native Nachweise werden automatisch umgebunden.
Keine zusätzliche Labmatrix oder TLS-Abnahme. Vorhandene Consumer-CI bleibt
wegen Parser-/Dependency- und gemeinsamem Transportcode erforderlich;
keine weitere Reviewdelegation allein für PR-Text oder CI-Auswertung.

Das [vollständige SSMS-Beispiel](../Examples/README.md) verwendet dieselbe
synthetische Format-8-Fixture und die bereits nativ geprüften Demotabellen.
`Invoke-Syntax.ps1` prüft dessen vollständiges SQL zusätzlich mit150/160/170,
ohne OPENROWSET, Demo-DDL oder Generatoraufrufe auszuführen. Diese begrenzte
Erweiterung verwendet den vorhandenen Windowsjob und denselben ScriptDom-Pin;
sie ergänzt drei Parseraufrufe, keine weiteren Jobs, Builds, Frameworkkinder,
SQL-/Labzugriffe oder Reviewagents. Die manuelle SSMS-Bedienung einschließlich
Dateileserechten ist damit kein neuer Runtime-Nachweis.

Die [Installationsanleitung](../Examples/Installation/README.md) ergänzt zwei
SQL-Beispiele für Vorbereitung und Kontrolle. Der bestehende Syntaxrunner
prüft beide mit150/160/170, also sechs zusätzliche Parseraufrufe.
`Tests/Framework/Invoke-InstallationExample.ps1` prüft mit synthetischen Dateien,
Manifesten und einem sqlcmd-Prozessdoppel die Artefakt-/Pinabweisung vor dem
ersten externen Aufruf, den verbindungslosen ValidateOnly-Modus, die fünf Phasen mit
exakten Trustparametern, Arbeitsverzeichnisse, beide expliziten Transportwerte
und den Abbruch an jeder Phase ohne Folgeaufruf oder Transportfallback.
Es werden weder eine echte SQL-Verbindung noch CLR-/Trust-/Datenbankänderungen
ausgeführt. Beide Erweiterungen laufen im vorhandenen Windowsjob; keine
weiteren Jobs, Builds, Framework-CLR-Kinder, Labzugriffe oder Reviewagents.
Die Beispiele und diese Offlineprüfung sind keine neue native Installation
oder Releasequalifikation. Die bestehenden Manifest-/Offline-Exportgates
bleiben erhalten; unbekannte Token-/Kostenverbräuche werden nicht beziffert.

Die PR-Integration besteht zusätzlich den Offline-Gesamtexport mit45 Modulen
(33 Fälle/178 Assertions). Der generische Deployer übernimmt beide SSIS-
Prozedurdefinitionen ausschließlich aus kanonischen Sources, sperrt deren
Überschreibung und prüft den ausdrücklich übergebenen Releasehash. Keine
Ausführung von Exportdateien oder zusätzliche native Gesamtqualifikation.
Die beiden Git-Zeilenendenkanonisierungen am gemeinsamen Guard und an den
generierten Dependencypins wurden durch vollständigen Textvergleich nach
CRLF→LF-Normalisierung als inhaltsgleich geprüft. Die ursprünglichen nativen
Releaseartefakte und deren Trustpins wurden dabei nicht neu erzeugt oder
nachträglich als neuer CI-Binarynachweis ausgewiesen.

## Aktuelle Validierungsevidenz

Neue Buildqualifikation vom 2026-10-18: Der Parserbuild ohne PDB-Debugdaten
ist aus zwei verschiedenen Verzeichnissen bytegleich; alle 57 Methoden-ILs
bleiben unverändert. Neu ausgeführt: 245 Parser-Frameworkfälle, 21 SSIS-
Frameworkfälle, 21 Syntaxprüfungen und 55 Installerassertionen. Der neu
gebundene Satz besteht auf Windows SQL2019/BIN2, SQL2022/CS_AS und
SQL2025/CI_AS_SC_UTF8 jeweils lokal und zentral 181 Kern-, 61 API- und
15 Lifecycleassertionen (1.542 insgesamt), echte Parser-/Table-Clone-Upgrades
einschließlich beider Triggerfixtures und Repeat. Die drei eigenen Journale
enden mit `PASS_CLEANED`. Funktionale Tests verwendeten den expliziten
Trustwert des schema-validierten Labvertrags mit erforderlicher Verschlüsselung;
authentifizierte TLS- und Releaseabnahme bleiben getrennt. Die zugehörige
Integrations-CI ist oben mit dem exakten Mergecommit nachgewiesen; der
native Lauf selbst war kein CI-Nachweis.

Die geänderten Binary-/Dependencypins begründen diese neue begrenzte
Qualifikation. Ein vollständiger Releaseaudit, Performance- oder weiterer
Minimalrechtenachweis wird daraus nicht abgeleitet. Die Prüfung erfolgt in
einer kohärenten Welle ohne zusätzliche Reviewagents; erfolgreiche unveränderte
Prüfungen werden nicht erneut ausgeführt. Private Builds-/Nativeprotokolle und
Wiederherstellungsjournale bleiben außerhalb des Repositorys.

Das versionierte [Installationspaket](../InstallPackages/README.md) wird im
bestehenden SSIS-Offlinejob zusätzlich mit
`Tests/Static/validate_install_package.py` geprüft. Der Check liest nur das ZIP:
Dateipfade, vollständige Hashlisten, drei DLLs, beide Deployments, aktuelle
Dependency-Pins, Pflichtskripte und CodeView-/PDB-Freiheit der Toolbelt-Binaries.
Er ergänzt denselben Job ohne weiteren Build, neue Jobs oder SQL-/Labzugriffe.
Die Ausnahme in `.gitignore` gilt nur für die benannte ZIP, deren Prüfsumme
und die zugehörige README. Ungefilterte Laufzeitlogs und private Journale
werden nicht aufgenommen.

Der Benutzer hat am 2026-10-18 die Veröffentlichung mit eingebettetem lokalen
Parser-Buildpfad abgelehnt und stattdessen Pfadbereinigung und neue Qualifikation
freigegeben. Die ursprüngliche Nativevidenz wird nicht auf neue Hashes umgedeutet.

## Aktuelle Releasequalifikation mit expliziten Compatibility Levels

[Release.Windows.CL.20261025.json](Qualification/Release.Windows.CL.20261025.json)
bindet den Scope-Identitätskern1.2 aus PR427 an den tatsächlich geprüften Binary.
Zwölf Windows-Kontexte: SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170,
jeweils lokal und zentral. Pro Kontext bestehen181 Kern-,61 API-,28 Rechte-/
Grenzen-,15 Lifecycle- und8 echte Iterationsbuild-Upgrades:3.516 Assertions.
Der SQL-Generator bleibt Dialekt150; die Datenbank-CLs wurden explizit gesetzt
und unabhängig ausgelesen. Full23 am finalen Provider und128 externe
Modellgegenproben ergänzen diesen eng abgegrenzten Nachweis.

Die Rechtefälle verwenden ausschließlich eigene Benutzer ohne Login.
Help braucht EXECUTE; Vorlage und Analyse brauchen zusätzlich Metadatensicht.
Die generierten SELECT-Stufen scheitern ohne Quell-SELECT strikt mit SQL229.
Die bestehende4000-Zeichen-ID-Grenze und atomare Ablehnung übergroßer Pakete
sind geprüft; Sicherheitsbudgets wurden nicht erhöht. Fünf korrigierte
Testadapterversuche bleiben FAILED_CLEANED und mitgezählt. Alle zwölf positiven
und fünf fehlgeschlagenen Fälle haben frische unabhängige Cleanup-/Konfigurationsaudits.

Die [aktuelle ZIP-Projektion](Qualification/Release.InstallPackage.20261025.json)
bindet den finalen185-Dateien-Satz an zwei neue Windows2025-Paketläufe lokal/zentral:
je8 Neuinstallations-/Repeat-/Uninstall-,8 reale Iterations-Upgrades,36 Kern- und61
API-Assertions,226 insgesamt. Doppelpaketierung, Integritäts-/Manipulationssuite6,
zusätzliche fehlende-Paketübersicht-Gegenprobe und extrahiertes ValidateOnly bestehen.
Eine zuvor fehlende interne Paketübersicht wurde ergänzt; zwei erfolgreiche frühere
Paketfälle bleiben im gemeinsamen Budget erhalten und wurden für den geänderten
Container durch zwei weitere erfolgreiche Fälle ergänzt. Der Installer braucht
weiterhin keinen Build. Der öffentliche Windows-Anmeldeprozess ist damit nicht
neu abgenommen. Das Gesamtpaket hat eigene Nachweise unter Releases/1.0.0.
SSMS-/Windows-Identität, authentifizierte TLS-Verbindung, Linux-Exporthost,
SSISDB-/SDK-Parität und Produktions-/Ressourcengrenzen bleiben offen.
Modulstatus und allgemeine Autonomie bleiben unverändert.

## Historisches Iterations-Installationspaket

Die [Paketprojektion](Qualification/Iterations.InstallPackage.20261025.json)
bindet den endgültigen ZIP-Hash an den Paketquellcommit und die tatsächlich
ausgeführten ODBC-Läufe aus dem vollständig entpackten Satz. Beide ZIP-Bauten
waren byteidentisch. Alle drei DLLs, das neue SSIS-Deployment und die ursprünglichen
Trustmanifeste sind exakt an die eigene Buildqualifikation gebunden; beim Packen
wurde keine Assembly neu gebaut. Der Lieferumfang umfasst178 Dateien mit
Quellen, Anleitung, SQL-/PowerShell-Skripten und SSMS-Beispiel.

| Paketpfad auf Windows SQL2025 / CI_AS_SC_UTF8 | Neuinstallation / Lifecycle | Upgrade | Kern | API | Ergebnis |
|---|---:|---:|---:|---:|---|
| local | 8 | 8 | 36 | 61 | bestanden |
| central | 8 | 8 | 36 | 61 | bestanden |

226 zusätzliche Assertions prüfen denselben neuen Binary über echtes
ODBC-sqlcmd mit expliziter schema-validierter Functional-Anmeldung. Frische
Installation, Repeat, Uninstall/Absent-Repeat und Austausch des ausgelieferten
#411-Builds bestehen. Die ursprüngliche JSON-Vorlage bleibt am finalen Einstieg
verwendbar; Assembly-/Prozeduridentitäten bleiben erhalten. Der öffentliche
PowerShell-Installer besteht55 Offline-Prozess-Orakel sowie ValidateOnly am
realen entpackten Satz; sechs Integritäts-/Manipulationsfälle bestehen.

Nach der ganzen Welle wurden alle acht Fälle nochmals unabhängig auditiert:
14 eigene Datenbanknamen abwesend,32 relevante Trustzustände und sämtliche
Konfigurationsbaselines wiederhergestellt, eingefrorene Inputs unverändert.
Acht von maximal zehn gemeinsam reservierten Versuchen wurden verbraucht;
es gab keinen nativen Fehllauf. Ursprünglicher Start und Grenzen300/360/400
sowie40/45 Sekunden bleiben erhalten. Private Restorejournale und zugeordnete
SQLCMD-Inputs bleiben lokal erhalten; keine Labressource bleibt eingerichtet.

Windows-Authentifizierung des öffentlichen Installers, SSMS-GUI und
authentifizierte TLS-Abnahme werden damit nicht nachträglich als ausgeführt
markiert. Ein ausführbares externes Exporthost-Programm ist nicht enthalten;
Linux-Hostlauf, echte SSISDB-Korrelation, vollständige SDK-/Ressourcen-/
Produktionsnachweise sowie Gesamtpaket-Synchronisation und Veröffentlichung
bleiben separat. Die allgemeine Moduldokumentation und das Paketmanifest
weisen den eingefrorenen Lieferquellstand aus; spätere reine Repo-Dokumentation
ändert die geprüften ZIP-Bytes nicht.

## Iterationsbuild: vollständige Windows-Buildqualifikation

Die [Iterationsprojektion](Qualification/Iterations.Windows2019-2025.20261025.json)
bindet den neuen gemeinsamen Kern, DLL und Deployment-SQL an die tatsächlichen
Build- und Testinputs. Das zusätzliche `iterationContainer` des optionalen
Identitätstransports1.1.0 stammt aus demselben Kern; öffentliche SQL-Parameter,
Resultsets, Legacy-Modell und Identitätstransport1.0.0 bleiben unverändert.

| Engine / eigene Datenbankcollation | Modi | Kern je Modus | API | Lifecycle | Upgrade | Ergebnis |
|---|---|---:|---:|---:|---:|---|
| Windows SQL2019 / BIN2 | local / central | 181 | 61 | 15 | 8 | bestanden |
| Windows SQL2022 / CS_AS | local / central | 181 | 61 | 15 | 8 | bestanden |
| Windows SQL2025 / CI_AS_SC_UTF8 | local / central | 181 | 61 | 15 | 8 | bestanden |

Sechs vollständige neue Kontexte ergeben1.590 Assertions. Upgrade bedeutet
hier: tatsächlich ausgelieferter #411-Binary → unterschiedlicher Iterationsbinary,
beide weiterhin1.0.0. Der Vorgänger wird zusätzlich gegen seinen vorhandenen
qualifizierten DLL-/Deploymentnachweis geprüft. Assembly- und öffentliche/interne
Prozeduridentitäten sowie die alte JSON-Vorlage bleiben verwendbar. Frühere
Legacy-/Parser-/Table-Clone-Upgrades werden nicht erneut ausgeführt oder auf
diesen Build umetikettiert. Die Defaultdialekte und risikobasiert verteilten
Collations behalten ihren bisherigen Scope; keine kartesische Vollmatrix.

Der Release-Doppelbuild ist byteidentisch; Full21 und97 gemeinsame
Modell-/Iterations-/Paritätsgegenproben am exakten neuen Binary bestehen.
Parser-/ScriptDom-Pins bleiben unverändert. Nach jedem Lauf und nochmals
abschließend bestätigten sechs unabhängige Audits zwölf eigene DB-Namen als
abwesend,24 Trustzustände und die Konfigurationsbaselines als wiederhergestellt
sowie unveränderte Laufinputs. Alle sechs Versuche bestanden.

Arbeits-/Cleanup-/äußere Grenzen300/360/400 und Kommandogrenzen40/45 Sekunden
bleiben erhalten. Functional verwendet erforderliche Verschlüsselung und den
expliziten Lab-Trustwert ohne Fallback. Windows-Anmeldung/SSMS-GUI,
authentifizierte TLS-Abnahme, Linux-Exporthost, SDK-/Ressourcen-/Produktions-
und Releaseabnahme behalten ihre eigenen offenen Grenzen.

Paketpins und der reine ZIP-Packer werden nicht als CLR-Deploymentinputs in
das Release-Trustmanifest aufgenommen: Sie binden dieses Manifest erst nach
seiner Qualifikation und wären andernfalls zyklisch. CLR-Quellen, SQL-Quellen,
Runtimeverträge und Releasebuilder bleiben vollständig gebunden. Die exakten
Paketquellen, Manifeste und Containerbytes haben eigene Integritätsgates.

## Aktualisiertes Installations-ZIP mit qualifiziertem Objektkennungsexport

Die [Paketprojektion vom 2026-10-25](Qualification/InstallPackage.20261025.json)
bindet den finalen ZIP-Hash, Paketquellcommit und tatsächlich ausgeführten
Testcommit. Das ZIP wurde zweimal byteidentisch gepackt; keine Assembly wurde
dafür neu gebaut. DLLs, generiertes Deployment-SQL und ursprüngliche
Trustmanifeste entsprechen exakt dem unten qualifizierten Buildsatz.

| Physische Engine / eigene DB-Collation | Modus | Frische Installation / Lifecycle | SSIS-Upgrades | Kern | API | Status |
|---|---|---:|---:|---:|---:|---|
| Windows SQL2025 / CI_AS_SC_UTF8 | local | 8 | 14 | 36 | 61 | bestanden |
| Windows SQL2025 / CI_AS_SC_UTF8 | central | 8 | 14 | 36 | 61 | bestanden |

Das sind 238 neue Assertions aus genau dem entpackten Satz. Die kanonischen
SQL-Deployments liefen über echtes ODBC-sqlcmd mit expliziter Lab-Anmeldung,
Verschlüsselung und dem booleschen Lab-Trustwert. Direkte Clientorakel prüfen
die installierten Bytes, JSON-Vorlage und API-Metadaten. Frische Installation,
Repeat, Uninstall/Absent-Repeat sowie ausgelieferter Build → gemeinsamer Kern
→ Objektkennungsexport sind bestanden. Beide alten JSON-Vorlagen bleiben
am finalen Einstieg verwendbar; Assembly-/Prozeduridentitäten bleiben erhalten.

Die neuen Fälle prüfen den gemeinsamen Paket-/Clientpfad repräsentativ auf
SQL2025. Sie wiederholen die sechs unveränderten Full-Buildkontexte nicht und
werden nicht als neue SQL2019-/SQL2022-Paketläufe dargestellt. Die unten
erhaltene Buildqualifikation umfasst weiterhin ihren eigenen vollständigen
Scope. Parser-/ScriptDom-Pins und SQL-/DLL-Bytes sind unverändert.

Nach jedem Fall und nochmals abschließend bestätigten unabhängige
Kontrollverbindungen zwei eigene Datenbanknamen als abwesend, zehn relevante
Trustzustände und alle Konfigurationsbaselines als wiederhergestellt sowie
unveränderte Eingabepins. Beide Versuche bestanden. Die Grenzen300/360/400
Sekunden und Kommandogrenzen40/45 wurden nicht erhöht. Private Journale,
SQLCMD-Inputs und Rohlogs bleiben als lokal zugeordnete Qualifikationsevidenz
erhalten; kein Labzustand bleibt dafür eingerichtet.

Sechs Offlinefälle prüfen Integrität und die Ablehnung selbstkonsistent neu
gehashter falscher DLLs, Quellbytes, Release-/Nachweis-Metadaten und ZIP-Pfade.
55 bestehende Prozess-Orakel prüfen Reihenfolge, Flags und Fehlerabbruch des
PowerShell-Installers. `ValidateOnly` besteht am tatsächlich entpackten Satz.
Der öffentliche Windows-Authentifizierungsprozess wurde dabei nicht nativ
ausgeführt; hierfür bleibt eine nutzbare Windows-Testidentität erforderlich.
Dies ist weder eine authentifizierte TLS- noch eine SSMS-GUI-Abnahme.

Das Paket enthält175 Dateien einschließlich Quellen, fertigen DLLs/SQL-Dateien,
Installationsanleitung und SSMS-Beispiel. `buildSourceRoots` erhält die exakten
Parser-Buildquellen mit ihren ursprünglichen Zeilenenden getrennt vom
SSIS-Buildinput. Copyright-, Lizenz- und Attributionstexte bleiben erhalten.
Der vorhandene Windows-CI-Job prüft Paketintegrität und Gegenproben gemeinsam,
ohne doppelten Baselinecheck, neue Jobs oder native Lab-CI. Weitere Full-/
Modellparitätsprüfungen bleiben ihre vorgeschriebenen eigenen CI-Gates.

Die Gesamtpakete unter `Releases/1.0.0/`, ausführbare Exporthost-Lieferung,
SSISDB-/SDK-/Produktionsnachweise und Veröffentlichung bleiben separat.

Die Paketquellen bleiben am im ZIP ausgewiesenen Commit eingefroren. Spätere
unabhängige Dokumentationsänderungen auf `main` schreiben diesen bereits
geprüften Container nicht um. Der historische CLR-Gesamtpaketprüfer liest seine
Methoden aus dem checksumgeprüften Recoveryarchiv und Git-Bundle. Er verifiziert
weiterhin die unveränderten Methodenhashes und die mitgelieferten Methodenquellen;
der aktuelle Checkout ersetzt nicht nachträglich die damaligen Testinputs.
Gegenproben für falsches Recoveryprodukt sowie SQL-, DLL-, Methoden- und
eingebetteten Quellendrift bleiben aktiv. Alte Paketbytes und Nachweise wurden
dafür nicht geändert. Die zusätzliche lokale Recoveryprüfung bleibt auf diese
Integritätsgrenze begrenzt und startet keine nativen Wiederholungsläufe.

## Build mit Objektkennungsexport: Windows SQL2019/2022/2025

Die eigenständige Qualifikation vom 2026-10-25 gilt für den aus PR #411
gebauten CLR-Kern am Produktquellstand
`bab9188d0af72c0ca852019ad5bc039070903c94`. Die
[maschinenlesbare Projektion](Qualification/Identities.Windows2019-2025.20261025.json)
bindet den tatsächlich ausgeführten Testcommit, Produktquellen, DLL und
Deployment-SQL. Frühere Nachweise bleiben an ihren ursprünglichen Binaries
gebunden. Der Releasebuilder erzeugte den neuen Satz zweimal byteidentisch;
alle 21 Framework-Fälle bestanden am exakt anschließend nativ geladenen Binary.
Die Assertionzahlen der Tabelle gelten jeweils für einen Modus.

| Engine / eigene Datenbankcollation | Modi | Kern je Modus | API | Lifecycle | SSIS-Buildupgrade | Ergebnis |
|---|---|---:|---:|---:|---:|---|
| Windows SQL2019 / BIN2 | local / central | 181 | 61 | 15 | 14 | bestanden |
| Windows SQL2022 / CS_AS | local / central | 181 | 61 | 15 | 14 | bestanden |
| Windows SQL2025 / CI_AS_SC_UTF8 | local / central | 181 | 61 | 15 | 14 | bestanden |

Sechs positive Einzelkontexte umfassen insgesamt 1.626 Assertions. Jeder Lauf
prüft die vollständigen Stufen-, Cache-, API-, ResultTable-, Rechte- und
Lifecyclefälle sowie Repeat und wiederholten Uninstall. Die Collations sind
risikobasiert verteilt; die nativen Generatoraufrufe verwenden SQL150. Eine
kartesische Collation-/Dialektmatrix wird damit nicht behauptet.

Die Upgradefolge verwendet drei unterschiedliche echte SSIS-1.0.0-Binaries:
ursprünglich ausgelieferter ZIP-Build → zuvor qualifizierter gemeinsamer Kern
(`e718acc`) → Build mit Objektkennungsexport. Der Runner bindet den mittleren
Satz zusätzlich an den unten erhaltenen früheren Qualifikationsnachweis.
Assembly- und öffentliche/interne Prozeduridentitäten bleiben bei beiden
Austauschschritten erhalten. Die im Originalbuild und im mittleren Build
jeweils erzeugten JSON-Vorlagen funktionieren am endgültigen öffentlichen
Einstieg. Es werden keine fiktiven Versionsmarker als Upgradeersatz verwendet.

Für diese Folge ergänzt der bestehende Einzelmodusaufruf den Parameter
`-SsisIntermediateReleaseDirectory $qualifiedCommonCoreReleaseDirectory`.
Dieser Pfad enthält den vorab geprüften mittleren Releaseartefaktsatz;
`-SsisPredecessorReleaseDirectory` verweist auf den ursprünglichen ZIP-Build,
`-SsisReleaseDirectory` auf den neuen Build. Der neue Runner lehnt fehlende echte
Vorgänger, abweichende DLL-/Deploymenthashes, falsche Produktbindung und
abweichende Dependency-Pins vor jeglicher Trust-/SQL-Mutation ab.
Ohne den zusätzlichen Parameter bleibt die bisherige direkte Upgradefolge erhalten.

In jedem Kontext bestanden außerdem die echten Parser-2.0.0→2.0.1- und
Table-Clone-4.1.0→4.1.1-Upgrades mit ursprünglicher und aktueller Triggerfixture.
Die Arbeitsgrenze bleibt 300 Sekunden, die Cleanupdeadline 360 Sekunden ab
Zielstart und der private äußere Watchdog 400 Sekunden. Kommandogrenzen von
40/45 Sekunden und Sicherheitsorakel wurden nicht erhöht. Nach jedem Lauf und
nochmals nach Abschluss bestätigten unabhängige Kontrollverbindungen den
Cleanup. Alle zwölf eigenen Datenbanknamen waren abwesend, alle 36 relevanten
Trustzustände wiederhergestellt, sämtliche Konfigurationsbaselines erhalten
und die eingefrorenen Eingabebytes unverändert. Es gab keine fehlgeschlagenen
nativen Versuche in dieser Welle.

Die Läufe verwenden `Functional`, erforderliche Verschlüsselung und den
expliziten booleschen Lab-Trustwert ohne Fallback. Authentifizierte TLS-Abnahme
bleibt separat `not executed`. Keine Labdetails, Rohlogs oder Restorejournale
werden veröffentlicht. Produktquellen und öffentlicher SQL-Vertrag wurden
nicht geändert; der Modulstatus bleibt teilweise validiert und unveröffentlicht.

Zum Zeitpunkt dieser Buildqualifikation enthielt das Installations-ZIP noch
den früheren ausgelieferten Build und keinen Exporthost. Paketlieferung, Linux-Hostlauf,
reale SSISDB-Korrelation, vollständige SDK-/Ressourcen-/Produktionsnachweise
und abschließende Releasefreigabe gehören nicht zu dieser Qualifikation.

## Historischer gemeinsamer Build: Windows SQL2019/2022 und Upgrade

Die zusätzliche Qualifikation vom 2026-10-25 gilt für den Produktquellstand
`e718accba206153c7af6aece1bf180cb23a16203`. Sie verwendet denselben SSIS-Binary
und dasselbe Deployment-SQL wie der separat dokumentierte SQL2025-Nachweis
zum gemeinsamen Modellkern. SQL2025 wurde nicht wiederholt. Die
[maschinenlesbare Projektion](Qualification/Windows2019-2022.20261025.json)
bindet die tatsächlichen Eingaben, Fälle und Ergebnisgrenzen.

| Engine / eigene Datenbankcollation | Modus | Kern | API | Lifecycle | SSIS-Buildupgrade |
|---|---|---:|---:|---:|---:|
| Windows SQL2019 / BIN2 | local | 181 | 61 | 15 | 8 |
| Windows SQL2019 / BIN2 | central | 181 | 61 | 15 | 8 |
| Windows SQL2022 / CS_AS | local | 181 | 61 | 15 | 8 |
| Windows SQL2022 / CS_AS | central | 181 | 61 | 15 | 8 |

Der später über PR #411 integrierte Objektkennungsexport verändert den
geteilten CLR-Kern. Die Nachweise hier bleiben am vorigen Binary gebunden;
sie qualifizieren keinen daraus neu gebauten CLR-Binary. Der Objektkennungsexport
hat eigene Offlinegegenproben und den oben getrennt dokumentierten nativen
Nachweis. Die erfolgreichen alten Läufe werden nicht umetikettiert.

Alle vier Fälle bestanden, insgesamt 1.060 Assertions. Der öffentliche
Generator verwendet dabei SQL150; weitere Dialekte und andere Nachweise
behalten ihre getrennte ursprüngliche Bindung.

`Invoke-SsisBuildUpgradeCases.ps1` installiert den tatsächlich ausgelieferten
SSIS-1.0.0-Binary aus dem bisherigen qualifizierten ZIP. Danach wird er durch
den neuen, unterschiedlichen 1.0.0-Build ersetzt. Die Tests lesen beide
Assemblyinhalte zurück, prüfen erhaltene Assembly-/Prozeduridentitäten und
verwenden eine zuvor erzeugte JSON-Vorlage am neuen öffentlichen Einstieg.
Es wird keine fiktive Vorgängerversion angelegt. Zusätzlich bestehen in jedem
Kontext die echten Parser-2.0.0→2.0.1-/Table-Clone-4.1.0→4.1.1-Upgrades mit
beiden Triggerfixtures, Repeat sowie Uninstall/Absent-Repeat.

Die begrenzten Aufrufe verwenden je genau einen Modus:

```powershell
foreach ($mode in 'local','central') {
    $journal = Join-Path $privateEvidenceRoot ('native-' + $mode + '-' + [guid]::NewGuid().ToString('N'))
    & Tests/Runtime/Invoke-LabContract.ps1 -Version 2019 -Patch base `
        -Modes $mode -Full -PredecessorRoot $genuineParserPredecessorRoot `
        -SsisPredecessorReleaseDirectory $shippedSsisReleaseDirectory `
        -SsisReleaseDirectory $verifiedNewReleaseDirectory `
        -ParserReleaseDirectory $exactPinnedParserReleaseDirectory `
        -QualifiedProviderSha512 $verifiedNewProviderHash `
        -JournalDirectory $journal -DatabaseCollation Latin1_General_100_BIN2
}
```

Das Beispiel wird aus dem Modulverzeichnis ausgeführt. Die angegebenen
Verzeichnisse enthalten vorab geprüfte Original-/Releaseartefakte; der
Journalpfad muss für jeden Aufruf neu sein. Für SQL2022 wurde derselbe Ablauf
mit `-DatabaseCollation Latin1_General_100_CS_AS` ausgeführt. Der Runner prüft Hashes vor SQL und kann den eingefrorenen
Labvertrag und Zielschlüssel zusätzlich explizit binden. Er verwendet keine
abweichende lokale Parser-DLL als Ersatz für den festgelegten Dependency-Pin.

Ein erster SQL2019-local-Versuch scheiterte im neuen Testadapter an der
Sichtbarkeit seiner Zeitbudgetvariablen im Unterskript. Er bleibt
`FAILED_CLEANED`; sein Cleanup wurde vor der Korrektur und nochmals abschließend
mit den ursprünglichen Eingabebytes unabhängig geprüft. Der korrigierte
Einzelmoduspfad bestand anschließend alle vier Fälle. Das Arbeitsbudget bleibt
300 Sekunden, die Cleanupdeadline 360 Sekunden ab Zielstart. Für die dokumentierte
Qualifikation überwachte zusätzlich ein privater 400-Sekunden-Watchdog jeden
Aufruf und ließ bei unklarem Zustand keinen Folgefall zu.
Die vorhandenen 40-/45-Sekunden-Kommandogrenzen werden nicht erhöht.

Der finale Adapter erhält außerdem das bisherige Verhalten von Aufrufen mit
mehreren Modi. Die vier qualifizierten Aufrufe hatten jeweils genau einen Modus;
ihr SQL-, Budget- und Orakelpfad bleibt unverändert. Ausführung und aktuelle
Anwendbarkeit sind in der Projektion getrennt. Sieben Offlinegegenproben in
`Framework/Invoke-NativeDeadline.ps1` prüfen Vererbung über eine echte
Skriptgrenze, Ablaufgrenzen und den bisherigen Mehrfachmoduspfad. Im vorhandenen
Windows-CI-Job kommt dafür ein kurzer PowerShell-Schritt hinzu, ohne neue Jobs,
Labzugriffe oder eine Verdopplung der Generator-Frameworkprozesse.

Vier positive und ein historischer Abschlussaudit bestätigten alle zehn eigenen
Datenbanknamen als abwesend, alle 25 geprüften Trustzustände als wiederhergestellt
und die Konfigurationsbaselines als erhalten. Originale, Journale und Rohlogs
bleiben lokal. Produktquellen und der versionierte Installationssatz wurden
nicht geändert. Das damalige ZIP lieferte den früheren Binary und
keinen Exporthost. Ein SQL2025-Upgrade war nicht Teil dieses historischen
Nachweises; der oben dokumentierte neue Build hat einen eigenen Nachweis.
Neuer Paketlieferstand, Linux-Hostlauf und weitere Ressourcen-/SDK-/
Produktionsaussagen bleiben separat; authentifizierte
TLS-Abnahme und Veröffentlichung sind damit nicht belegt.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-29`
- Nachweis: `local: SSIS-Komponenten-V2 ZIP- und Standalone-T-SQL-Paketqualifikationen`
- Scope: Separates V2-ZIP mit zwei Windows-Paketfällen, 1190 Assertions und zwei unabhängigen Cleanup-Audits; Standalone-T-SQL-Installer auf Windows SQL2019/CL150 und SQL2025/CL170 in local/central, vier V2-Opt-in-Vorlagenprüfungen und zwei unabhängige Audits. Die getrennten Reports binden Binary, Paket, Installer und Ausführungseingaben. Eine separate CRLF→LF-Integrationsbindung dokumentiert genau zwei Metadatenänderungen: Normalisierung des ZIP-Qualifikations-JSONs und Anpassung seines Hashfelds in der Installerprovenienz; Ausführungspins und Installerbytes bleiben unverändert. Native Records belegen keine CI; Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head getrennt nachgewiesen. Vollständige Plattform-/Engine-Matrix, authentifiziertes TLS und Veröffentlichung bleiben unqualifiziert beziehungsweise nicht freigegeben; der Modulstatus bleibt unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Die Exchange-Gegenproben prüfen zusätzlich `--bundle` auf beiden Hosts. Fehlende,
ungültige, namespacefremd überschattete und doppelte DTSIDs bleiben ausdrücklich
getrennte Fälle; Paketbytehash und Modellvorkommen müssen übereinstimmen. Diese
synthetischen Kernproben belegen weder eine SSISDB-Ausführung noch deren Revision.

### Pipelineidentitäten im gemeinsamen Austausch

Der optionale Pipelinebundle wird durch denselben Austauschtest gegen externen
und Frameworkhost verglichen. Die Gegenfälle prüfen gleiche Modellkennungen,
Ports und Kanten, den Unterschied zwischen Pfadname und SDK-Identifikationsstring
sowie unqualifizierte native Referenzsyntax. Die bestehenden Generatorfälle
bleiben Regressionen. Diese Prüfung führt weder SSISDB-Pakete noch neue
CLR-Releaseartefakte aus; die native Analyze-Abnahme bleibt getrennt.

## Gebundener Vorgänger der Pipeline-Folgequalifikation

Der Labrunner akzeptiert mit `-SsisQualifiedPredecessorEvidence` zusätzlich
`Release.Windows.CL.20261025.json`. Damit kann der tatsächlich ausgelieferte
Scope-Identitätsbuild als Upgrade-Ausgangspunkt verwendet werden. Originaler
Quellcommit, DLL- und Deploymenthash sowie Parser-/ScriptDom-Pins bleiben
verbindlich. Die [neue Buildprojektion](Qualification/Pipeline.Windows.CL.20261025.json)
bindet zwölf erfolgreich ausgeführte Windows-/CL-/Modusfälle und3516 Assertions
an den Pipeline-Identitätsbuild. SQL2019 nutzt CL150, SQL2022 CL150/160 und
SQL2025 CL150/160/170, jeweils lokal und zentral. Hinzu kommen 23 begrenzte
Frameworkfälle, 147 gemeinsame Modellgegenproben und zwölf unabhängige
Abschlussaudits. Der historische Scope 1.2-Nachweis bleibt unverändert.

Die zusätzlichen Pipelinefelder stammen aus derselben bereits begrenzten
XML-/Graphmaterialisierung. Der öffentliche SQL-Einstieg, Parserprofile,
Katalogzugriffe und Sicherheitsbudgets sind unverändert; der optionale
Pipelineexport ist weiterhin eine externe Hostoperation. Eine neue
SQL-Schnittstelle oder SSIS-Runtime wird daraus nicht abgeleitet.

## Historische Pipeline-Paketlieferung

Die [Paketprojektion](Qualification/Pipeline.InstallPackage.20261025.json)
bindet den finalen ZIP-Hash an zwei neue Windows-SQL2025-Fälle lokal und
zentral. Die entpackten Installationsskripte wurden mit ODBC-sqlcmd geprüft:
Neuinstallation, Repeat, Uninstall/Repeat und tatsächliches Scope 1.2→Pipeline-
Upgrade. Zusammen 226 Assertions; zwei frische unabhängige Abschlussaudits
bestätigten Cleanup, Inputpins und wiederhergestellte Konfigurationen.

Das ZIP enthält den unveränderlichen Quell-/Anleitungssnapshot seines
Paketcommits. Die nach der Ausführung ergänzte Paketprojektion steht im
Repository; sie verändert keine enthaltenen DLL-/SQL-Bytes. Die Prüfung
ersetzt weder Windows-Anmeldung/SSMS-GUI noch authentifizierte TLS-Abnahme.

## Aktueller Lookup-Ausgangsrollenbuild

Die [Buildprojektion](Qualification/LookupRoles.Windows.CL.20261025.json)
bindet den Build aus PR #447 an zwölf Windows-/CL-/Modusfälle und 3516
Assertions. SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170
wurden jeweils lokal und zentral geprüft. Der tatsächlich ausgelieferte
Pipelinebuild ist über den Selektor Pipeline.Windows.CL.20261025.json der
exakte Upgradevorgänger; DLL-/Deploymenthash, Quellcommit und Pins sind Pflicht.
23 begrenzte Frameworkfälle und 165 gemeinsame Core-/Host-Gegenproben ergänzen
die native Matrix. NO_MATCH bleibt auf das qualifizierte Lookup-Profil begrenzt;
unbekannte Profile und mehrdeutige Ausgangsmengen bleiben UNKNOWN. Alle zwölf
finalen unabhängigen Cleanup-/Pin-/Konfigurationsaudits bestanden. Frühere
Nachweise behalten ihre eigenen Quellen und Grenzen. Sicherheitsbudgets,
SQL-API und Modulstatus bleiben unverändert; Veröffentlichung nicht autorisiert.

## Aktuelle Lookup-Paketlieferung

Die [Paketprojektion](Qualification/LookupRoles.InstallPackage.20261025.json)
bindet den finalen ZIP-Hash an zwei Windows-SQL2025-Fälle lokal/zentral mit
ODBC-sqlcmd: Installation, Repeat, Uninstall/Repeat und echtes Upgrade vom
zuvor ausgelieferten Pipelinebuild. 226 Assertions und zwei frische unabhängige
Abschlussaudits bestätigen Ergebnisse, Cleanup, Pins und Konfiguration.
Das ZIP enthält seinen unveränderlichen Paketcommit; die spätere Paketprojektion
im Repository ändert keine enthaltenen SQL-/DLL-Bytes. Windows-Anmeldung,
SSMS-GUI und authentifizierte TLS-Abnahme bleiben gesondert offen.
