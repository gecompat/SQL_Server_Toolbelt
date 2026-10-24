# Releasevorbereitung prüfen

## API- und Grenzqualifikation

`api-qualification-spec.json` benennt die 165 ausgewählten kanonischen
Fixtures, ihre Adapter und die gezielten Ergänzungen. Der
[Ergebnisbericht](../../Releases/1.0.0/API-QUALIFICATION.md) und die
[45-Modul-Zuordnung](../../Releases/1.0.0/EVIDENCE-MAP.md) begrenzen den
Nachweis. Modulmanifeste bleiben die Quelle der alten Evidenz; diese Liste
ist keine zweite allgemeine Testregistry und wertet keine Module auf.

Nach Paketprüfung und dem unten beschriebenen Erzeugen eines neuen privaten
Complete-Payloads (oder bei verifiziert bytegleichem vorhandenem Payload):

```powershell
python -B Tests/Release/prepare_api_qualification.py `
  --source-zip Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip `
  --complete-input .runtime/complete-new/complete.zip `
  --output .runtime/api-new-inputs
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -InputDirectory .runtime/api-new-inputs -PlanOnly
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -InputDirectory .runtime/api-new-inputs `
  -EvidenceDirectory .runtime/api-new-run -FreezeOnly
```

Diese Schritte bauen keine DLL und verbinden sich nicht mit SQL Server.
Der Stager prüft das ausgelieferte Paket, unveränderte Produktquellen und
SQL-/DLL-Payloads, übernimmt die kanonischen Fixturebytes und erzeugt zwei
synthetische XLSX-Eingaben. Relative Kompositionshelfer behalten ihre
kanonischen Hashes. Der Plan umfasst 74 Ziel-/CL-/Gruppenfälle mit eigenen
Datenbanken für local/central/Consumer. Die Auswahl ergänzt insbesondere
SQL2022/CL150, niedrigere SSIS-CLs und noch unbelegte CSV-Grenzziele.
Core, Text, Formate, CSV und strikte Cancellation-Negativfälle haben je zwölf
Fälle; Parser/TableClone/SSIS sechs Windows-Fälle; acht getrennte Translate-
Großfälle ergänzen die noch nicht belegten Ziele. Die vollen Safe-Cast- und
JSON-Pointer-Matrizen sowie bereits gültige unveränderte CSV-/Translate-
Großnachweise werden in ihrem tatsächlichen Scope wiederverwendet.

Vor nativer Ausführung Zusatzprompt lesen, Labvertrag/Schema prüfen, aktuelle
Verbraucher und vorhandene Rechte klären sowie gegebenenfalls die separat
autorisierte temporäre CLR-Konfiguration privat journalisieren. Erst danach:

```powershell
./Tests/Release/Invoke-ApiQualificationMatrix.ps1 `
  -FrozenRunset .runtime/api-new-run/runset.json
```

Jeder Fall hat einen eigenen äußeren Watchdog und einen separaten
Cleanup-/Pinaudit; auch `FAILED_CLEANED` verlangt diesen Audit. Unbekanntes
Cleanup stoppt weitere Mutationen bis zur Reconciliation. Korrekturen
brauchen neue relevante Inputs, einen neuen privaten Evidenceordner,
`-ChangedInputReason` und denselben `-SharedBudgetFile`; Start, verbrauchte
Versuche und erfolgreiche Fälle bleiben erhalten. Keine blinden Retries.
Nach allen Verbrauchern sind eigene Konfiguration und Trustzustände
wiederherzustellen und unabhängig zu prüfen.

Die gemeinsame Obergrenze ist 90 Case-/Recoveryversuche und 36000 Sekunden
ab dem ursprünglichen Start. Arbeitszeit/Cleanup-Gesamtdeadline/äußerer
Watchdog sind in Sekunden 300/360/400 für gewöhnliche Fälle,
960/1200/1240 für Core, 1800/2160/2200 für Formate und CSV sowie
1200/1440/1480 für große Translate-Fälle. Je Fall bleiben zusätzlich
90 Sekunden für den unabhängigen Audit reserviert. Das sind Harnessgrenzen;
die öffentlichen Ressourcen- und intrinsischen Regex-Zeitbudgets ändern sich
dadurch nicht.

`-CarryForwardCases <privates-case-journal>` übernimmt ausschließlich einen
vom Adapter ausdrücklich unterstützten, vollständig bestandenen Präfix nach
konkretem Befund. Das eingefrorene Runset bindet altes Journal, alten Runset
und damaligen Audit. Vor neuen Mutationen prüft ein lesender Preflight erneut
Zielidentität, bereinigten Vorzustand, bytegleiche Produkt-/Fixtureinputs und
die tatsächlichen Kontexte. Abweichungen werden abgewiesen. Ein beobachteter
intrinsischer Regex-Timeout bleibt ein blockierter Fixtureaufruf und der
gesamte Fall `PARTIAL`; er wird weder als Erfolg noch als neuer Retry gezählt.
Die gemeinsame Fortschrittsdatei trennt vollständige und partielle Fälle.

Bei einem unerwarteten Fehler der kanonischen `Captures.Contract.sql`
ergänzt der API-Adapter ausschließlich im ausgeführten Testtext Phase und
Fallnummer. Die strikten Orakel, Produktbytes und der ursprüngliche SQL-Fehler
bleiben erhalten. Erfolgreiche Aufrufe erzeugen keine zusätzlichen Meldungen.
Auch ein als `PARTIAL` erfasster Regex-Timeout hält seinen vollständigen
Fehlertext samt CLR-Stack und synthetischem Unterfall im **privaten**
Casejournal (`blockedFixtures[].privateDiagnostic` und `privateFixtureCase`).
Diese Felder dürfen nicht in öffentliche Ergebnisse oder PRs kopiert werden.
Die Diagnose erklärt einen Fehler; sie hebt ihn weder auf noch erlaubt sie
einen unveränderten Retry. Die Offline-Regressionssuite prüft die bytegenau
erhaltene Fixture, Fail-closed-Verhalten bei Quelldrift und den gebundenen
Eventcallback über `Test-ApiCaptureDiagnostic.ps1`.
Der [Capture-Untersuchungsbericht](../../Releases/1.0.0/CAPTURE-TIMEOUT-INVESTIGATION.md)
trennt absichtliche Fehlerproben, bestandene Originalfixtures und die weiterhin
offene historische Ursache.
Die spätere [Capture-Abnahme](../../Releases/1.0.0/CAPTURE-RELEASE-ACCEPTANCE.md)
dokumentiert die ausdrücklich freigegebene Abschlussregel mit Restrisiko und
die zusätzliche `Runtime/Regex.Capture.Rights.sql`. Diese Fixture benötigt
den separat freigegebenen Aufbau eines Benutzers ohne Login in einer eigenen
temporären Testdatenbank; sie ist kein Installationsskript. Der native Scope
ist lokal/direkt zentral, keine Lowpriv-CrossDB-Anmeldung.

Die Coregruppe lädt die vorhandene `WorkTypeAuthorization.Fixture.sql`
ausschließlich in eigene disposable Datenbanken: explizite dbo-Policy für
alte Fachfixtures, kein Deploymentinclude, keine echten Minimalrechte.
Die zusätzliche Cancellation-Fixture prüft die dokumentierten Fehlernummern
strikt und beweist eine doomed Callertransaktion mit einem echten FK-Zeugen.
Die zusätzliche CSV-Fixture prüft die gemeinsame Default-16-MiB-Grenze mit
vollständigen Byte- und Erhaltungsorakeln; die beiden Direct-SELECT-Suiten
verwenden ihre kanonischen Clientorakel einschließlich erwarteter Fehler.

Für SSIS erzeugt `prepare_ssis_functional_fixture.py` eine private Ableitung
der kanonischen V1-Fixture: Nur der exakt begrenzte Principal-/Rechteblock
wird ausgelassen, sonstige Assertions bleiben bytegleich. Die drei fehlenden
niedrigeren Windows-CLs prüfen die funktionalen Fälle einschließlich NOLOCK-
Zeugen. Im zentralen Modus wird die eigene Consumerdatenbank ausdrücklich
übergeben; das tatsächlich generierte SQL wird ausgeführt. Diese Ableitung
qualifiziert keine SSIS-Minimalrechte. Direkte API-Metadaten verwenden den
kanonischen Metadatenhelfer.

Serverdatei-, Provider-, Principal- und harte Recoveryvoraussetzungen werden
dadurch nicht bereitgestellt. Erfolgreiche frühere Lifecycle-/Lastnachweise
werden nicht allein zur Statusauffrischung wiederholt.

Offline-Regressionsprüfung ohne SQL: `python -B
Tests/Release/test_prepare_release.py`. Die bestehende Dokumentations-CI
führt diese Suite aus; es gibt keinen zusätzlichen Workflow.

## Gemeinsamer Gesamtpaket-Test

Der freigegebene [Support-Zielumfang](../../Releases/1.0.0/SUPPORT.md) wird durch
`prepare_complete_package.py` aus dem tatsächlichen Gesamt-ZIP in private
Testinputs übersetzt. Es verwendet dessen Modul-/Deploymentquellen, fertig
mitgelieferte DLLs und kanonischen Offline-Exporter. Kein Build oder SQL-Zugriff.
Windows-local umfasst 45 Module, Windows-central 43, Portable-local/central
jeweils 40. Fehlende Plattformfähigkeiten begrenzen transitiv ihre Consumer.

```powershell
python -B Tests/Release/prepare_complete_package.py `
  --package Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip `
  --output .runtime/complete-new/complete.zip
./Tests/Release/Invoke-CompletePackageMatrix.ps1 `
  -PackagePath .runtime/complete-new/complete.zip `
  -EvidenceDirectory "$PWD/.runtime/complete-new-run" -PlanOnly
```

Das private Ausgabe-Elternverzeichnis muss neu angelegt werden. Native
Ausführung erfolgt nur nach Lesen des Labprompts, schema-validierter Auswahl,
Preflight und eingefrorenem Runset/Restbudget wie beim CLR-Paketadapter unten.
Der Defaultscope `full` verlangt Repeat und Absent-Repeat. Der ausdrücklich
getrennte Scope `install-uninstall` prüft Erstinstallation, feste Smoke-Oracles,
den unveränderten JSON-Pointer-Securityfixture, zentrale Consumer und einmaligen
Uninstall. Er qualifiziert **keinen** Repeat oder Absent-Repeat und ersetzt
keine API-/Minimalrechte-/Recoverymatrix. Die tatsächlichen Fälle, Fehler und
Blocker stehen im [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md).

Beide Scopes teilen bei Korrekturfortsetzungen denselben expliziten
`-SharedBudgetFile`. Die erste Diagnosewelle hatte 18 Caseversuche/7200 Sekunden.
Der anschließende ausdrückliche Auftrag zur Behebung beider Lifecyclefehler
erweitert den gemeinsamen Rahmen für die korrigierte Vollmatrix auf
30 Versuche/10800 Sekunden und für die dadurch erforderliche eigenständige
CLR-Paketabnahme auf insgesamt 42 Versuche/14400 Sekunden. Ursprünglicher Start,
verbrauchte Versuche und Teilnachweise bleiben erhalten; die Scopes besitzen
getrennte Fortschrittslisten. Kein Budgetreset. Bereits
vollständig qualifizierte Fälle werden nicht erneut ausgeführt. Das Journal
führt den ausgewählten Scope; Fehler bleiben Fehler. Neue abhängige Arbeit
setzt unabhängige Cleanup-/Inputaudits voraus. Der Runner verändert weder
Labinfrastruktur noch Rechte oder Logins; eine notwendige temporäre
CLR-Konfiguration wird separat unter der bestehenden engen Autorität
journalisiert und nach allen Verbrauchern wiederhergestellt.

## Vorgebaute CLR-Lieferung

Die [CLR-Installationsanleitung](../../Releases/1.0.0/CLR-INSTALL.md) ist der
Endanwenderweg. [prepare_clr_package.py](../../Scripts/Release/prepare_clr_package.py)
packt die zwei bereits bytegleichen Builds mit eingefrorenen Produktquellen;
SSIS-/Parser-/ScriptDom-Bytes bleiben aus dem bestehenden qualifizierten ZIP
erhalten. Ein neues privates Ausgabeverzeichnis und der vorhandene
`build-check.json`-Satz werden ausdrücklich übergeben:

```powershell
python -B Scripts/Release/prepare_clr_package.py --build-directory $QualifiedDoubleBuild `
  --output .runtime/clr-package-new/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip
python -B Scripts/Release/prepare_clr_package.py `
  --verify Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip
```

Das Ausgabeziel muss neu sein und sein Elternverzeichnis bestehen. Das Tool
kompiliert und verbindet sich nicht mit SQL. Der aktuelle Paketcheck bindet
DLLs und SQL an die tatsächlich ausgeführte Welle in `clr-qualification.json`;
veränderte SQL-/DLL-/Methodenbytes erfordern eine betroffene Neuabnahme.
Reine Dokumentationsänderungen werden nur bei exakt erhaltenen funktionalen
Payloads übernommen. Dateipfade, PE-/Buildpfadguard, Trustwerte, Profile und
innere/äußere Prüfsummen werden geprüft. Die Standardregressionssuite prüft
das echte versionierte CLR-ZIP zusätzlich; keine neue CI oder Labwelle.

`Invoke-ClrPackageMatrix.ps1` nutzt den schema-validierten Labvertrag und
zwölf explizite Windows-/Linux-/SQL-/CL-Fälle, mit den jeweiligen Windows-
beziehungsweise Portable-Profilen. Jeder Case hat 300/360 Sekunden Arbeit/
Cleanup und einen äußeren 400-Sekunden-Watchdog. Sämtliche Korrekturfortsetzungen
teilen eine private ursprüngliche Budgetdatei mit höchstens 18 Caseversuchen
und 7200 Sekunden; erfolgreiche Fälle werden nicht wiederholt. Eine Fortsetzung
ab `-StartCaseIndex` setzt das vollständig geprüfte Präfix voraus. Neue Quellen
werden in einem neuen privaten `EvidenceDirectory` eingefroren und verwenden
denselben `SharedBudgetFile`; jeder Versuch bleibt getrennt. Automatische
Retries, Provider-/Trustfallbacks und Labinfrastrukturverwaltung fehlen.

Der Adapter setzt bereits aktiviertes CLR und vorhandene administrative Rechte
voraus. Die stehende enge Testkonfigurationsfreigabe kann separat mit privatem
Vor-/Wiederherstellungsjournal verwendet werden. Der Case übernimmt keine
pauschale Serverkonfiguration. Neue Trusteinträge bekommen eine eindeutige
eigene Beschreibung und vollständigen Fingerprint; Consumer-/Datenbankdrift
blockiert Cleanup. Vorbestehender Trust bleibt erhalten. Ein separater Prozess
prüft anschließend Datenbankabwesenheit, Trustfingerprints und Inputpins.
Der konkrete [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md) grenzt die
tatsächliche Installation von einer vollständigen neuen API-/Releaseabnahme ab.

Für geänderte Installations-SQL kann ein neuer privater CLR-Testkandidat mit
`prepare_clr_package.py --unqualified-candidate` gebaut werden. Er bleibt
ausschließlich unter `.runtime`, trägt `qualification_state=pending`, enthält
keinen vorgetäuschten Qualifikationsnachweis und wird vom normalen Prüfmodus
abgewiesen. Der native CLR-Matrixrunner akzeptiert ihn nur mit dem ebenfalls
ausdrücklichen Schalter `-UnqualifiedCandidate`. Erst nach realer Abnahme werden
Qualifikationsprojektion, endgültiges Paket und deren Bindungen erneuert;
der öffentliche Releaseplan akzeptiert keinen ungeprüften Kandidaten.

## Quellpaket und gemeinsame Regressionen

Die Tests prüfen den [Releasegenerator](../../Scripts/Release/prepare_release.py)
und die [v1.0.0-Freigabematrix](../../Releases/1.0.0/README.md). Es werden
keine SQL-Verbindungen, Labressourcen, Builds, Tags oder Veröffentlichungen erzeugt.

```powershell
python -B Tests/Release/test_prepare_release.py
```

Geprüft sind transitive Kanalbegrenzung und Dependencyfehler, unveränderter
Publikationsstatus, Manifest-/Matrixdrift, Ausschluss privater Pfade,
ZIP-Pfadsicherheit, Symlinks und doppelte Pfade. Der vorhandene
Dokumentationsvalidator ruft diesen Test impactbezogen auf.

Der tatsächliche Paketbau ruft zusätzlich den vorhandenen verbindungsfreien
SQL-Exporter für die stabilen Kandidaten lokal und zentral auf. Der anschließende
Prüfmodus vergleicht alle Dateien, Prüfsummen und den eingefrorenen Gitstand.
Die generierten SQL-Dateien werden erneut offline exportiert und bytegenau
verglichen; ein nachträglich passend gehashtes SQL kann diese Bindung nicht ersetzen.
Das ist eine Packagingprüfung; eine native Installation oder die fachliche
Veröffentlichungsabnahme wird daraus nicht abgeleitet.

## Natives stabiles Paket im Lab prüfen

Der [Matrixrunner](Invoke-StablePackageMatrix.ps1) prüft die tatsächlich
gepackten `Install-Stable-local.sql` und `Install-Stable-central.sql` für die
19 stabilen Kandidaten. Er verwendet ausschließlich den schema-validierten
Labvertrag, dessen Zusatzprompt vor dem Aufruf gelesen werden muss. Es gibt
keinen Provider- oder TLS-Fallback. Die jetzige endliche Auswahl umfasst
zwölf Kombinationen: Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und
SQL2025 CL150/160/170. Weitere bereite Patchziele überschreiten diese
Runsetgrenze und werden nicht stillschweigend weggelassen oder nachgetestet.

```powershell
[void][IO.Directory]::CreateDirectory("$PWD/.runtime")
./Tests/Release/Invoke-StablePackageMatrix.ps1 `
  -EvidenceDirectory "$PWD/.runtime/release-native-new" -PlanOnly
./Tests/Release/Invoke-StablePackageMatrix.ps1 `
  -EvidenceDirectory "$PWD/.runtime/release-native-new"
```

`-PlanOnly` verbindet sich nicht mit SQL und legt kein Evidenzverzeichnis an.
Der eigentliche Lauf benötigt ein neues direktes privates Arbeitsverzeichnis
unter `.runtime`, vorhandene administrative Testrechte und die vollständigen
Paketprüfwerkzeuge. Der Runner prüft das Archiv vor SQL, friert Eingaben und
Auswahl ein und startet pro Fall einen eigenen Prozess mit äußerem
400-Sekunden-Watchdog. Der Fall besitzt 300 Sekunden Arbeits- und insgesamt
360 Sekunden einschließlich Cleanupbudget; die ganze Matrix höchstens 4800
Sekunden. Kein automatischer Retry und keine neue Testwelle bei Fehlern.

Jeder Fall erzeugt drei eigene Datenbanken, prüft SQL-Version/Plattform und CL,
installiert den jeweiligen Gesamt-Export in frischer Sitzung und wiederholt ihn.
Die 19 Versions-/Modusmarker sowie Objektdefinitionen müssen erhalten bleiben.
Fünf feste Smoke-Oracles prüfen Series, Base64, Date Spine, JSON Path Exists
und ResultTable auch über den zentralen Consumerpfad. Reverse Dependencyorder
und zweimaliger Uninstall dürfen keine Modulobjekte/-marker zurücklassen.
Die Paketprüfung ersetzt keine erneute vollständige Qualifikation aller APIs.

Vor DROP werden eigener Name, Datenbank-ID, Erstellungsidentität, eigener
Marker und Bereinigungssichtbarkeit geprüft. Ein gesonderter Prozess prüft
anschließend lesend alle Namen auf Abwesenheit und die eingefrorenen Inputs.
Bei unbekannter Ownership oder Cleanup stoppt die Matrix. Journale und
Diagnosen bleiben privat; es werden keine Rechte, Logins, Serveroptionen,
Trusteinträge, Labressourcen oder fremden Datenbanken geändert.

Die rein lokalen Negativtests in `Test-StablePackageHarness.ps1` prüfen
Pfad-/Ownershipgrenzen und abgewiesene SQLCMD-Direktiven ohne SQL-Anmeldung.
Sie laufen innerhalb der bestehenden Release-Regressionssuite und des
Dokumentationsjobs; die native Matrix wird dadurch nicht gestartet.

## Skalarrechte und dokumentierte Produktrevision prüfen

Die zusätzliche [Regex-Skalarrechtequalifikation](../../Releases/1.0.0/REGEX-RIGHTS-QUALIFICATION.md)
verwendet im API-Harness einen eigenen, endlich ausgewählten SQL-Fixturescope.
Sie legt ausschließlich in eigenen temporären Datenbanken Benutzer ohne Login
an und prüft feste Werte, fehlende Rechte, REFERENCES allein, EXECUTE allein,
Rechteentzug sowie gesperrte interne Kerne. Die separate Projektion enthält
auch zwei absichtlich abgewiesene Orakelvarianten; diese sind keine funktionalen
Erfolge. Der Quellvergleich für die anschließende Rechte-Dokumentationskorrektur
erlaubt nur fünf konkrete SQL-Headerkommentare, bekannte Markdown-Seiten und
den engen Manifestnachtrag. Andere Runtime-, Versions-, Objekt- oder
Dependencyänderungen werden abgewiesen. Beide Produktstände sind aus den
gebundenen öffentlichen bzw. aktuellen Quellbundles rekonstruierbar;
unreferenzierte alte Gitobjekte sind dafür keine Voraussetzung.

## Optionalen CLR-Installer nativ prüfen

Der optionale ODBC-Clientpfad des bestehenden CLR-Paketharness wird in einem
privaten eingefrorenen Runset ausdrücklich mit `client = OdbcSqlcmd`,
`extractedPackage` und einem vorab gepinnten `sqlcmd` gewählt. Er ruft den
vollständigen Pakethelper mit dem freigegebenen vorhandenen SQL-Konto auf;
ohne Auswahl bleibt SqlClient erhalten. Paket, entpackte Metadaten, Helper,
Tool und Labvertrag müssen vor Mutationen gebunden sein. Runsets und
Zugangsdaten gehören nicht ins Repository. Umfang, unveränderte Grenzen und
Ergebnisse stehen im [Clientnachweis](../../Releases/1.0.0/CLR-CLIENT-QUALIFICATION.md).
Die vorhandenen Offline-Harnessprüfungen bleiben im selben Release-Testlauf;
es entsteht kein zusätzlicher CI-Job oder automatischer Labtest.

## CLR-Buildinputs isoliert prüfen

```powershell
python -B Scripts/Release/check_clr_builds.py `
  --msbuild $msbuild --output .runtime/release-clr-new
```

`$msbuild` benennt ein vorhandenes MSBuild mit .NET-Framework-4.8-Targeting-Pack,
zum Beispiel portabel über `vswhere` entdeckt. Das Tool installiert nichts und
verlangt einen unveränderten Produktbaum. Es baut alle zwölf CLR-Projekte in
zwei getrennten eigenen Git-Quellkopien. Die bereits enthaltene ScriptDom-DLL
wird gegen ihren kanonischen Pin geprüft; JSON und ZIP werden vor ihren
Consumers gebaut. Releaseflags schließen PDB-Daten aus, `PathMap` verwendet
einen synthetischen Pfad. Beide Builds müssen identische DLL-Bytes liefern.

Buildlogs, DLLs, SHA-256-/SHA-512-Kandidatenliste und Buildpfade bleiben im
neuen `.runtime`-Unterverzeichnis. Kein vorhandenes Buildartefakt wird ersetzt.
Ein Erfolg bestätigt Reproduzierbarkeit und die PE-/Buildpfadprüfungen,
keine vollständige IL-/Framework-/SQL-Abnahme, Trustfreigabe oder Auslieferung.
Neue Binaryhashes benötigen weiter ihren konkreten Qualifikations-/Consumer-
und Releaseumfang. Der [Gatebericht](../../Releases/1.0.0/RELEASE-GATES.md)
trennt diese Grenzen von den tatsächlich ausgeführten Pakettests.

## Execution Context mit einzelnen Objektrechten prüfen

`Runtime/ExecutionContext.Rights.sql` ist eine zusätzliche feste SQL-Fixture
für den bestehenden API-Harness. Sie legt ausschließlich in dessen eigenen
temporären Datenbanken einen Benutzer ohne Login an. Für jedes der fünf
öffentlichen APIs prüft sie fehlende Rechte, genau das eine vorgesehene
Objektrecht und dessen Entzug. Auch während der positiven Phase müssen die
vier anderen APIs mit SQL229 gesperrt bleiben. Feste Identitäts-/Contextwerte,
Nested-/Clear-Verhalten, TVF-Zeile und scalar/NULL sind unabhängig vorgegeben.
Ein vorhandener Principal oder Sessioncontext blockiert den Test.

Der [Rechtebericht](../../Releases/1.0.0/EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md)
und seine JSON-Projektion binden die tatsächlich abgeschlossene Zwölfermatrix,
zwei absichtlich verworfene Orakelvarianten und frische unabhängige Audits.
Produkt- und Paket-SQL-/DLL-Bytes blieben unverändert. Kein neuer CI-Job,
automatischer Labstart oder Replay einer bereits grünen Vollmatrix.
