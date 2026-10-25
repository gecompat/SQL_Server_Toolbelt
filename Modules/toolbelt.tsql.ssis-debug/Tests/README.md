# SSIS-Debug: Prüfmatrix und Evidenz

Stand 2026-10-25. Die nativen Nachweise unten behalten ihre ursprünglichen
Ausführungsdaten und Buildbindungen. Alle eingecheckten DTSX-Fixtures sind synthetisch und werden
mit `Fixtures/build_fixtures.py` erzeugt; keine Kundenpakete oder Runtimewerte.

`Framework/Invoke-Contract.ps1` prüft den exakten ScriptDom-Pin und führt
isolierte .NET-Framework-Prozesse mit begrenztem Stack und Watchdog aus.
Profil `Full` umfasst derzeit 21 Kindprozesse: JSON-Grenzen und exakte Werte,
Format 6/8, Vorlagen-Roundtrip, Source/Union/Derived/Lookup/Split/Destination,
CTE-Parsecache, blockierte Komponenten, unzulässige SQL-Statements sowie
Operator-, Struktur-, Kommentar-, Projektions- und Textgrenzen.

Bestanden: 21 Kindprozesse einschließlich gezielter Reviewregressionen zu
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
- Datum: `2026-10-25`
- Nachweis: `local: deterministischer ZIP-Doppelbau, Integritäts-/Manipulationssuite6, Installer-Orakel55, extrahiertes ValidateOnly und ODBC-Paketläufe Windows2025 local/central mit unabhängigen Audits`
- Scope: Aktualisiertes SSIS-ZIP mit exakt qualifiziertem PR411-Binary, unverändertem Deployment-SQL/Trustmanifest und Parser-/ScriptDom-Pins; keine neue Assembly gebaut.175 Dateien einschließlich exakter Buildquellroots, Installationsanleitung und SSMS-Beispiel. Zwei native Paketkontexte mit je8 Neuinstallations-/Lifecycle-,14 echten SSIS-Upgrade-,36 Kern- und61 API-Assertions,238 insgesamt. Ursprünglicher Lieferbuild → gemeinsamer Kern → Objektkennungsexport, alte Vorlagen und Identitäten erhalten. Zwei frische Abschlussaudits: zwei eigene DB-Namen abwesend, zehn Trustzustände und Konfiguration wiederhergestellt, Eingabepins unverändert. Grenzen300/360/400 und40/45 erhalten; echter ODBC-Client mit expliziter Functional-Labanmeldung und Encrypt=True ohne Fallback. Frühere sechs Full-Enginekontexte bleiben separat gebunden. Öffentlicher Windows-Authentifizierungsprozess, authentifizierte TLS-/SSMS-GUI-Abnahme, Gesamtpaket-Update und Veröffentlichung nicht belegt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Die Exchange-Gegenproben prüfen zusätzlich `--bundle` auf beiden Hosts. Fehlende,
ungültige, namespacefremd überschattete und doppelte DTSIDs bleiben ausdrücklich
getrennte Fälle; Paketbytehash und Modellvorkommen müssen übereinstimmen. Diese
synthetischen Kernproben belegen weder eine SSISDB-Ausführung noch deren Revision.
