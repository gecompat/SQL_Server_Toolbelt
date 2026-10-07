# CHANGELOG

## 2026-10-07 – W4b-CI mit verifizierter Bereinigung und Fehlerorakel

- Der vorhandene Work-Type-Runner bindet Name und Owner vor dem Start,
  entfernt nur die vollständige eigene ID und prüft frische Namensabwesenheit.
  Fremder Bestand und unbekannte Bereinigung bleiben sichtbare Fehler.
- Seine Uninstall-Negativphase verwendet auch im Lab eine private Datei und
  verlangt zusätzlich zur Fehlerkategorie einen Fehlerexit. Ein Exit0 mit
  Fehlertext ist kein erfolgreicher Abweisungsnachweis.
- Gemeinsamer Offlineharness, Dokumentationsgate und bestehendes Impact-Paket
  erfassen diese Grenzen. Lab-Container-No-op, öffentliche SQL-Verträge,
  fachliche Fixtures, Images, Matrix und Runtimeworkflow bleiben erhalten.

## 2026-10-07 – Work-Queue-CI mit eigener Identität und Ausgabeablage

- Runner-Cleanup bindet den bestehenden Container an Version, Run, Attempt
  und Owner, entfernt ausschließlich seine vollständige ID und verlangt
  frische Namensabwesenheit. Fremder Bestand und unbekannter Cleanup bleiben
  sichtbare Fehler; Runner-SQL-Drops über den Namen entfallen.
- Vier Negativphasen verwenden auch im Lab eine eigene private Ausgabeablage.
  Die sieben bestehenden Lab-Drops und der Container-No-op bleiben erhalten;
  ein Fehler der privaten Dateibereinigung beendet den Labadapter mit Exit1.
- Gemeinsamer Offlineharness, Dokumentationsgate und bestehendes Impact-Paket
  erfassen den Adapter. Öffentliche SQL-Verträge, fachliche Fixtures, Images,
  Versions-/CL-Matrix und Runtimeworkflow bleiben unverändert.

## 2026-10-07 – Eigenen W4a-CI-Container verifiziert bereinigen

- Der vorhandene Execution-Foundations-Adapter bindet den Runner an
  SQL-Version, Run, Attempt und Owner. Cleanup entfernt nur die gemeinsam
  mit dem Owner gelesene vollständige ID und verlangt frische Namensabwesenheit.
  Fremder Bestand oder unbestätigter Cleanup werden zum sichtbaren Fehler.
- Gemeinsamer synthetischer Harness, selektives Dokumentationsgate und
  bestehende Impact-Pakete erfassen den Adapter. Lab-No-op, fachliche
  SQL-Verträge, Fixtures, Zielmatrix und Lifecycle-Suite bleiben unverändert.
- Der ResultTable-Validator erkennt seinen einzelnen Pfad im gemeinsamen
  Cleanupgate, ohne eine Nachbarschaft zu anderen Pfadargumenten zu verlangen.

## 2026-10-07 – Eigenen ResultTable-CI-Container verifiziert bereinigen

- Der vorhandene Adapter bindet sein flüchtiges Runnerziel an SQL-Version,
  Run, Attempt und Owner. Cleanup entfernt nur die zusammen mit dem Label
  gelesene vollständige ID und verlangt frische Namensabwesenheit. Fremder
  Bestand oder unbestätigter Cleanup erzeugen einen sichtbaren Fehler.
- Der bestehende gemeinsame Offlineharness und sein selektives Dokumentations-
  gate erfassen jetzt diesen Adapter. Lab-No-op, öffentliche SQL-Funktion,
  bestehende Runtime-Suite, Performanceflag und Zielmatrix bleiben unverändert.

## 2026-10-07 – Eigenes Worker-CI-Ziel verifiziert bereinigen

- Der vorhandene Linux-Workerworkflow bindet sein flüchtiges Ziel vor dem
  Start an Run, Attempt und Owner. Der getrennte Cleanupstep entfernt nur
  die zusammen mit dem eigenen Label gelesene vollständige Container-ID
  und bestätigt danach frische Namensabwesenheit; Fehler bleiben sichtbar.
- Ein begrenzter synthetischer Test extrahiert die tatsächlichen beiden
  Workflowsteps und prüft Übergabe, Fehler und Dockerargumente ohne Docker
  oder SQL. Bestehende Faultjobs führen ihn aus. Produkt-SQL, Workerlogik,
  Image, Port, Provider, Matrix und Labadapter bleiben unverändert.

## 2026-10-07 – Eigene Tabellenklon-CI-Container verifiziert bereinigen

- Der vorhandene Runner-Adapter bindet seinen Container an Run, Attempt,
  SQL-Version und ein eigenes Ownerlabel. Die zusammen mit dem Label gelesene
  vollständige Container-ID ist das Löschziel; fremder Namensbestand bleibt
  erhalten. Fehlende Sicht oder fehlgeschlagene Abwesenheitsprüfung verhindern
  einen erfolgreichen Cleanupstatus.
- Der gemeinsame synthetische Cleanup-Test und seine CI-/Impactkopplung
  erfassen den Tabellenklon-Adapter. Die selektiven Documentation-CI-Guards
  verwenden Git-Pathspecs und unterscheiden kein Match von einem Diff-Fehler;
  ein fehlendes optionales Suchwerkzeug überspringt die Tests nicht mehr.
  Keine neue SQL-Funktion, Zielmatrix,
  Rechte- oder Truständerung; Lab-Shimpfad bleibt unverändert. Normales
  EXIT-Cleanup ist kein Nachweis für harte Runner-/Hostunterbrechung.

## 2026-10-07 – Schema-CI folgt der vorhandenen CL-Matrix

- Der bestehende Schema-Upgrade-/API-/Safety-/CrossDB-Scope läuft local und
  central auf allen bereits gewählten CI-CLs, einschließlich SQL2025/CL150/160.
  Consumer und Provider werden vor jeder Stufe auf denselben CL gebunden.
- Der eigene Upgrade-Snapshot wird nach verifiziertem Schema-Uninstall
  entfernt, damit jede Folgestufe mit einem frischen genuine1.0.0-Stand
  beginnt. Core wird erst nach allen Stufen entfernt.
- Keine zusätzlichen Constructor-Lastfixtures im Schema-Loop, keine neuen
  Binaries, Trusthashes oder öffentlichen Verträge. Head-CI wird im PR
  belegt; teilweise validiert und unveröffentlicht, übrige Matrix offen.

## 2026-10-07 – Vollständige kanonische JSON-Pointer-Lifecycle-CI

- Der flüchtige Linuxadapter ersetzt überlappende zentrale Teilprüfungen durch
  dieselben20 local-/22 central-Fälle je CL wie der vorhandene Labadapter.
  Dependency-, Caller-, Lock-, Rollback-, Marker-, Fremdslot- und Confirm0-
  Prüfungen verwenden unverändert dessen gemeinsamen Helper.
- Ein begrenzter Driver bindet eigene Fixtures an DB-Identität und Sourcepins,
  führt private Restorejournale und bestätigt Uninstall/Repeat/Abwesenheit.
  Feste Fehlerskategorien werden erst nach Restore ausgegeben.
- Testcode allein ist kein Runtime-PASS; exakte Head-CI wird im PR belegt.
  Produkt-SQL und öffentliche Verträge unverändert, teilweise validiert und
  unveröffentlicht. Weitere physische Ziele, Minimalrechte, Ressourcen und
  Hard-Interrupt-Recovery bleiben offen.

## 2026-10-07 – Safe-Cast-CI verwendet vollständige kanonische Lifecyclefälle

- Der flüchtige CI-Adapter ersetzt zentrale Teilprüfungen durch dieselben
  18 local-/20 central-Fälle pro CL wie der vorhandene Labadapter, einschließlich
  Callerzustand/SET-Optionen, AppLock, Rollback, Marker, Fremdslot und Confirm0.
- Eigene DB-Identität und Sourcepins, ein privates Restorejournal sowie
  frische Abwesenheitsprüfungen binden den begrenzten Driver an seine Fixtures.
  Testcode allein ist kein Runtime-PASS; exakte Head-CI wird im PR nachgewiesen.
- Produkt-SQL und öffentliche Verträge unverändert; Minimalrechte, gemessene
  Ressourcen und Hard-Interrupt-Recovery bleiben offen. Teilweise validiert,
  unveröffentlicht.
- Erster [nativer CI-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37541002552)
  scheiterte beim ersten lokalen Lifecycleaufruf auf allen drei SQL-Versionen;
  die Ursache war wegen unterdrückter fester Diagnosekategorien noch offen.
  Der Adapter gibt jetzt erst nach Restore eine strikt gefilterte feste
  Fehlerstufe/-kategorie aus. Rohtexte und private Journale bleiben verborgen;
  der fehlgeschlagene Lauf wird dadurch nicht zu erfolgreicher Evidenz.

## 2026-10-07 – Runtime-CI bei Helper- und Generatoränderungen

- Safe-Cast- und JSON-Pointer-Runtime-CI berücksichtigen ihre tatsächlich
  geladenen gemeinsamen Lifecycle-Hilfsdateien und die vom statischen Vertrag
  ausgeführten Deploymentgeneratoren jetzt sowohl bei Pull Requests als auch
  bei Pushes auf `main`. Reine Änderungen dieser Abhängigkeiten lassen dadurch
  die bestehenden nativen Prüfungen nicht mehr aus.
- Testumfang und öffentliche SQL-Verträge bleiben gleich; daraus folgt keine
  zusätzliche Lifecycle-, Rechte-, Ressourcen- oder Releasequalifikation.

## 2026-10-06 – Schema1.0.1: begrenzte native CI bestanden

- [Runtime37532174433](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37532174433)
  und Docs37532174428 am exakten Head83164b539e637deeb1ad21b74a15cad99e0184c1
  PASS, einschließlich Windows und Linux SQL2019/CL150,2022/CL160,2025/CL170.
  Schema jeweils local/central: genuine Upgrade, erwarteter55699-Rollback,
  Mode-Abweisung, Uninstall/Reinstall/Repeat,40 Contractfälle je Modus,
  Safety, CrossDB und Cleanup. Je SQL-Version acht Upgrade- und zwei
  Safety-Witnesses; kein UnexpectedSQL/CleanupUnverified-Witness.
- SQLCMD-Dateifaulttransport bestand im tatsächlichen Testpfad; daraus wird
  keine exakte Actual168-Rootcause abgeleitet. Frühere failed/PENDING-Records
  bleiben erhalten. Jeder spätere Head benötigt vor Integration eigene
  erfolgreiche Checks; übrige Ziel-/
  Minimalrechte-/Lifecycle-/Kapazitätsmatrix offen, unveröffentlicht.

## 2026-10-06 – JSON Schema1.0.1: SchemaPointer-Reihenfolge korrigiert

- Finale Offline-Läufe `qual4`/`package4` nach Common-Härtung bestanden:
  15 Phasen mit unveränderten Harnesszahlen und acht Packagingfälle.
  Genau ein strict-UTF8-Byteinput ist an den festen historischen
  Snapshot-SHA256 gebunden; gültig neu gerahmte Constructorframes werden
  im Generator und Driver vor Ausgabe mit `SCHEMA_PATCH_BASELINE_PIN`
  abgewiesen. Kandidat und aktive Registry/Binaryhashes sind semantisch
  exakt gleich. Die folgenden sechs Packagingfälle aus `qual3`/`package3`
  bleiben erfolgreiche Nachweise des früheren Scriptstands.
- Erster [nativer CI-Versuch](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37525258700)
  am Head `58993f7012a0b458db377d7d4374b7bf162f0432`: SQL2019/2022 scheiterten
  mit Msg515 in UpgradeCapture Permissions wegen NULL für den leeren
  FOR-XML-Katalog. Capture/Verify normalisieren diesen nun symmetrisch
  auf `0x`; unabhängiger Review und ScriptDom14/42 bestanden. SQL2025
  lief bei Erfassung noch; native Abnahme am korrigierten Head
  sowie die ergänzte Windows-CI-Qualifikation bleiben PENDING.
- Schemaformfehler und Referenzzyklen folgen vollständig codierten
  SchemaPointern; decodierte Instanzmember und numerische Instanzarrays
  behalten ihre Reihenfolge. Profil, Signatur und Ergebnisfelder unverändert.
- Expliziter1.0.0→1.0.1-Maintenancepfad und Uninstall beider bekannten
  Releases implementiert; historische Closure unverändert erhalten.
  Core-/Constructorbytes bleiben gleich. Die eigene neue Schemazeile
  trägt ausschließlich die tatsächlich ausgeführte begrenzte Patchqualifikation.
- Offline:169 Profilfälle/1275 Assertions,854 Zahlenfälle/6830 Assertions
  und120 Bridge-Assertions je drei Kulturen, eigene IL, bytegleicher
  Schema-Projektbuild, sechs Patch- und sieben Releasepaketierungsorakel
  sowie ScriptDom14 Batches/42 Assertions bestanden. Der historische
  Erzeuger reproduzierte die echten1.0.0-Bytes aus50 Originalblobs in53
  erfolgreichen Prozessphasen. Syntax und18 synthetische CI-Cleanupfälle
  sowie33 Selector-/Bindungsfälle ohne Labzugriff bestanden. Keine erneute
  lokale Maximallastqualifikation.
- Native1.0.1-API, echter SQL-Upgrade und exakte aktuelle Head-CI noch offen;
  bisherige1.0.0-Nachweise bleiben historische Evidenz. Teilweise validiert,
  unveröffentlicht, kein neuer öffentlicher Funktionsscope.

## 2026-10-06 – JSON-Pointer-Contract-, Safety- und Client-CI ergänzt

- Ein modulbezogener Runtime-Workflow prüft den bestehenden Pointer-Vertrag
  in flüchtigen Linux-SQL-Server-2019/2022/2025-Containern über die jeweils
  unterstützten Compatibility Levels, local/central/Consumer, Safety,
  Clientmetadaten, Repeat und Uninstall. Produkt-SQL und öffentlicher Vertrag
  bleiben gleich.
- Gezielte Lifecycle-Negativfälle, Hard-Interrupt-Recovery, weitere physische
  Ziele, Minimalrechte und Maximalworkload/Heap sind dadurch nicht qualifiziert.

## 2026-10-06 – Safe-Cast-API- und Client-CI ergänzt

- Ein modulbezogener Runtime-Workflow prüft den bestehenden Safe-Cast-Vertrag
  in flüchtigen Linux-SQL-Server-2019/2022/2025-Containern über die jeweils
  unterstützten Compatibility Levels, local/central/Consumer, Clientmetadaten,
  Repeat und Uninstall. Produkt-SQL und öffentlicher Vertrag bleiben gleich.
- Gezielte Lifecycle-Negativfälle, Hard-Interrupt-Recovery, weitere physische
  Ziele, Minimalrechte und Heap sind dadurch nicht qualifiziert.

## 2026-10-06 – Safe Cast auf Windows 2025 mit CL150/160 qualifiziert

- Derselbe bereits ausgewählte Windows2025/CU8-Testserver bestand die
  vollständigen Safe-Cast-Adapter zusätzlich mit CL150 und CL160, je local/
  central/Consumer, festen API-/Clientprüfungen und 38 Lifecyclefällen.
  Frische unabhängige Audits bestätigten eigene Bereinigung,
  Fixturewiederherstellung und unveränderte Eingaben. Produkt-SQL und
  öffentlicher Vertrag blieben unverändert.
- Weitere physische Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI
  bleiben offen; teilweise validiert und unveröffentlicht.

## 2026-10-06 – JSON Pointer auf Windows 2025 mit CL150/160 qualifiziert

- Derselbe bereits ausgewählte Windows2025/CU8-Testserver bestand die vollständigen
  Pointer-Adapter zusätzlich mit CL150 und CL160, je local/central/Consumer,
  Contract/Safety/Client und42 Lifecyclefällen. Frische unabhängige Audits
  bestätigten eigene Bereinigung, Fixturewiederherstellung und unveränderte
  Eingaben. Produkt-SQL und öffentlicher Vertrag blieben unverändert.
- Weitere physische Ziele, Minimalrechte, Maximalworkload/Heap und vollständige
  Runtime-Head-CI bleiben offen; teilweise validiert und unveröffentlicht.

## 2026-10-06 – Exakte Argumentbindung der Safe-Cast-/Pointer-Labtreiber

- Plattform, Version, Deploymentmodus und Pointer-Qualifikationsscope werden
  bereits bei der Parameterbindung exakt geprüft. Ein synthetischer CI-Test
  führt nur die isolierten Paramblöcke aus; kein Labzugriff oder Produkt-SQL.
  Die nachgelagerte exakte Zielauswahl war bereits geschlossen.

## 2026-10-06 – JSON-Pointer-Quellvertrag in der pfadbezogenen CI

- Der bestehende statische JSON-Pointer-Vertrag läuft bei Moduländerungen und
  manuellem Workflowaufruf im Dokumentationsworkflow. Produkt-SQL,
  Runtimeadapter und Modulstatus bleiben unverändert; ein erfolgreicher
  Quellvertrag ersetzt keine SQL-Runtime- oder vollständige Head-CI-Abnahme.

## 2026-10-06 – Safe-Cast-Quellvertrag in der pfadbezogenen CI

- Der bestehende statische Safe-Cast-Vertrag läuft bei Moduländerungen und
  manuellem Workflowaufruf im Dokumentationsworkflow. Produkt-SQL,
  Runtimeadapter und Modulstatus bleiben unverändert; ein erfolgreicher
  Quellvertrag ersetzt keine SQL-Runtime- oder vollständige Head-CI-Abnahme.

## 2026-10-05 – SAFE JSON: Windows-CL150/160-Qualifikation und Selectorbindung

- Derselbe begrenzte Core-/Schema-Scope bestand auf Windows2025/exaktCU8
  zusätzlich mit CL150 und CL160 jeweils local/central:30 Contractfälle,
  Safety/Client/Lifecycle und frische unabhängige Dispositionaudits.
- Labadapter erlaubt150/160/170; exakter Linux2019-Guard bleibt150.
  Öffentliche SQL-Verträge und bekannte DLLs unverändert. Constructor1.3
  und genuine1.2→1.3 separat auf beiden Levels local/central einschließlich
  post-DROP-Rollback und frischen Audits bestanden; vollständige Ziel-/
  Minimalrechtequalifikation bleibt offen.
- Inkonsistente Casebindung am ersten Zielguard gehärtet; nachfolgender
  Selector blieb bereits geschlossen.33 Assertions und Originalstand-Negativtest
  bestanden, erneuter kanonischer CL160-Lablauf frisch auditiert. Test in CI/
  Impact registriert; laufende JSON-Runtimeprüfung wird erhalten.


## 2026-10-05 – Historischer Queue-Capture: aktuelle Helperkopplung

- Exakten Prozesshelperpin nach qualifizierter Timeout-Erweiterung aktualisiert;
  historische Queue2.0-Blobs und Capturebudgets unverändert. Helperänderungen
  sind jetzt in Worker-CI und Work-Queue-Impact registriert.
- Offlinecapture aller15 Originalblobs/14 Includes bestanden; neue native
  Migrations-CI separat. Vorheriger Helperpin-Fehler bleibt fehlgeschlagen.


## 2026-10-05 – JSON Schema1.0, gemeinsamer Core1.0 und Constructors1.3

- Freigegebene `USP_ValidateJsonSchema` mit Profil `toolbelt-2020-12-v1`,
  zehn Ergebnisfeldern, vollständigem Preflight, exakten Zahlen/Unicode,
  lokalen nichtrekursiven Referenzen und globalem Arbeitsbudget umgesetzt.
- Ein physischer SAFE-JSON-Core für Schema und die sieben Constructoradapter;
  drei getrennte bekannte Assemblies und explizite SameDB-Dependencies.
  Öffentliche Constructorverträge und AGF-Wireversion3 bleiben erhalten.
- Source-/Framework-/IL, drei kanonische bytegleiche Projektbuilds und sieben
  Paketierungskontrollen bestanden. Interne Schema-CLR-Bindungen verwenden
  Unicode; öffentliche ASCII-Felder bleiben varchar. Consumer-DROP verwendet
  `WITH NO DEPENDENTS`, um den gemeinsamen Core zu erhalten.
- Native Core-/Schema-Läufe auf Linux2019/latest CL150 und Windows2025/CU8
  CL170 local/central bestanden Contract/Safety/Client/Repeat/Consumer-Reject/
  Uninstall und eigene Bereinigung. Constructor-Fixtures einschließlich16 MiB
  und100000 Einträgen bestanden Linux lokal und Windows lokal/zentral.
- Genuine1.2→1.3 auf Linux local/central bestanden: fünf Procedureidentitäten/
  Rechte und effektive Owner erhalten, drei eigene CLR-Slots/Assembly atomar
  ersetzt, post-DROP-Rollback und Zusatzmetadaten-Abweisung geprüft. Der
  verworfene ALTER-Versuch scheiterte an SQL6282; Fehlerhistorie bleibt sichtbar.
  Windowsmigration anschließend ebenso local/central bestanden; aktuelle Head-CI offen.
- Schema-Trustfreigabe gilt für weitere separat qualifizierte Schemahashes
  der laufenden freigegebenen Testwelle ohne erneute Frage. Kein Produktions-
  oder Infrastrukturauftrag. Weitere Matrix, Minimalrechte, CrossDB und volle
  Lifecycle-/Heapqualifikation offen. Neue Module teilweise validiert und
  unveröffentlicht;44 Module insgesamt,19 validiert/25 teilweise validiert.

## 2026-10-05 – AI Repository Foundation1.19.0

- Exakte öffentliche Quelle4aafd20442275d0fdedf291fc6e12e8fe1f683cc nach
  vollständiger Feature-/Hashprüfung integriert; bestehende Projektregeln,
  drei Adapter und neun ausgewählte Capabilities erhalten.
- Zwei neue Features bewertet: sichere CI-Ablösung und metadatenbasierte
  Sessionsteuerung.24 Runtime-Workflows erhalten laufende Prüfungen, solange
  keine belegte Bereinigung nach harter Unterbrechung besteht.
- Foundationintegrität,34 relevante Upstream-Regressionsfälle, vollständiger
  Projektdokumentationsaudit und YAML-Verträge bestanden. Konkrete
  Sessionthresholds und automatische Clientrotation bleiben optional.
- [Bewertung und Grenzen](Documentation/Architecture/FOUNDATION_1_19_INTEGRATION.md).


## 2026-10-05 – JSON Pointer1.0.0 und freigegebener nativer128er-Guard

- Einzeln freigegebene lesende native MSTVF TVF_ResolveJsonPointer mit vier
  Parametern, vier BIN2-Ergebnisspalten, vollständiger Unicode-/Tiefenpolicy,
  exakten Keys und getrennten Statuswerten geschrieben; eigener atomarer
  Lifecycle und Source-abgeleiteter Deploymentgenerator, kein CLR.
- Offlineverträge, Syntax/Ast und vollständige Dokumentationskopplung bestanden.
  Zwei native Linux2019-Adapter bestanden Deploy/Repeat und432 Contract-Oracles,
  scheiterten an ISJSON-Tiefe129. Eigene Bereinigung und Inputpins jeweils
  unabhängig bestätigt; frühere Fehler bleiben fehlgeschlagen.
- [Konkrete notwendige Prioritätsänderung](Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
  anschließend ausdrücklich freigegeben: nonnegative128er-Strukturguard vor
  Nativevalidation, geschützter Scalarwrapper; bis128 bleibt Syntax vor
  caller-seitig abgesenktem MaxDepth. Oberfläche sonst unverändert.
- Historischer separater Lifecycle-Scope vor der Prioritätsänderung auf Linux2019/CL150 und Windows2025/
  CU8/CL170 erfolgreich: je local/central/Consumer,15 Clientreader,42 Lifecycle-
  Fälle und frischer Bereinigungs-/Fixture-/Pinaudit. Contract/Safety dabei
  ausdrücklich nicht ausgeführt; löste damals die noch offene Tiefenpriorität nicht.
- Finale vollständige Adapter des korrigierten freigegebenen Standes auf
  Linux2019/CL150 und Windows2025/exaktCU8/CL170 bestanden je local/central/
  Consumer,3072 feste APPLY-Oracles,15 Clientreader und42 Lifecyclefälle samt
  frischem Bereinigungs-/Fixture-/Pinaudit. Keine Konfigurations-/Rechte-/
  Truständerungen. Frühere Fehlläufe und Lifecycle-only-Scopes bleiben getrennt;
  weitere Ziele, Minimalrechte, Maximalworkload/Heap und exakteHead-CI separat
  offen. `partially validated`, `unreleased`.

## 2026-10-05 – Strict Safe Cast / 1.0.0

- Sechs einzeln freigegebene schemagebundene Inline-TVFs für bigint,
  decimal(38,18), date, datetime2(7), bit und uniqueidentifier. Genau eine
  Value/Status/ErrorCode-Zeile, strikte ASCII-/ISO-Lexik, höchstens8192
  Inputbytes, exakter Wertebereich vor Skalenverlust und keine stille Rundung.
- Finale lokale Adapter auf Linux2019/latest CL150 und Windows2025/exaktCU8
  CL170 bestanden jeweils local/central/Consumer: je13104 feste API-Oracles,
  54 Clientreader,38 Lifecyclefälle, Clean/Repeat und Uninstall/Repeat.
  Frische unabhängige Audits bestätigen Inputpins, exakte Marker-/Fremdslot-
  Wiederherstellung und eigene Bereinigung. Frühere drei Gesamtfehlläufe bleiben
  getrennt. Keine Konfigurations-, Rechte- oder Truständerungen.
- Teilweise validiert, unveröffentlicht. Weitere physische Ziel-/CL-Matrix,
  Minimalrechte, Heap und exakte Head-CI bleiben separate Nachweise.

## 2026-10-05 – CSV Memory / zusätzliche Qualifikation

- Zwei separate Linux2019/latest-CL150-Markerfälle: Deploy und Uninstall
  weisen synthetisches int statt bit mit SQL55324/state5 unverändert ab;
  exakte Restaurierung und frischer unabhängiger OwnDB-/Trustaudit bestanden.
  Keine Aufwertung der vollständigen Driftmatrix oder des 29-Fall-Zählers.
- Historische exakte PR169-Head-CI mit fünf erfolgreichen Checks dokumentiert;
  CSV-Produkt und CLR-Bytes unverändert, Status teilweise validiert/unveröffentlicht.

## 2026-10-05 – CSV Memory / 1.0.0

- Einzeln freigegebene `USP_ParseCsv` und `USP_WriteCsv` mit eigenem SAFE-CLR-Kern,
  rechteckigen HEADER-/DATA-Zellen, exaktem NULL-Token und atomarem ResultTable-Routing.
  100000 DATA-Records, 1024 Spalten, eine Million Zellen und 16 MiB UTF16-Textbytes;
  alle Budgets nur absenkbar. Kein Datei- oder Netzwerkzugriff.
- Binarygebundene .NET48-Frameworkprüfungen mit drei Kulturen, unabhängigen
  Quotingorakeln, harten Grenzen und IL-Prüfung bestanden. Finale öffentliche Labadapter
  auf Linux2019/latest CL150 und Windows2025/exakt CU8 CL170 bestanden jeweils lokal,
  zentral und mit separatem Consumer: SQL-Verträge, Budgets, Clientmetadaten,
  29 Caller-/Lock-/Rollbackfälle, Repeat und Uninstall/Repeat. Frühere fehlgeschlagene
  Syntax-, LF-Padding- und Help-Metadatenläufe bleiben getrennt; exakte Head-CI ist
  ein separater Mergegate.
- Teilweise validiert, unveröffentlicht. Weitere physische Ziele, tatsächliche
  Minimalrechte und Heap-/Produktionskapazität bleiben offen.

## 2026-10-04/05 – Managed Queue Worker / unveröffentlichte Welle

- Queue 2.1 und Worker-Control 1.0 ergänzen den bestehenden externen Provider
  um zentrale dynamische Parallelitätsbudgets, Generationen, Intervalle und
  kontrolliertes Drain. Stop/Hold verhindert automatische Wiederholung;
  bestätigte SQL-Endzustände und unbekannte Ausgänge bleiben getrennt.
- Dokumentations-/Kopplungsaudit und begrenzte Offlineprüfungen bestanden.
  Der SQL-Vertrag mit Admission, Generationen, Holdbypass, Help/ResultTable
  und sechs echten Lifecycle-Abweisungen bestand auf 2019 Linux und
  2025 Windows/exakt CU8. Der echte Queue-Upgrade 2.0→2.1 bestand auf 2019 Linux.
  Fehlgeschlagene Providerläufe bleiben getrennt dokumentiert; kein Gesamt-PASS.
- Unabhängiger Produktreview ohne neue Blockingfindings abgeschlossen.
  Fokussierte Managedläufe auf beiden ausgewählten SQL-Zielen einschließlich
  eigenem Cleanup bestanden; tatsächlicher Linux-Workerhost und exakte Head-CI
  bleiben getrennte Mergegates. Keine neuen
  Agent-, Broker- oder SSIS-Provider und kein Releaseauftrag.

## 2026-10-04 – Table Clone Datenkopie / 4.1.0

- Einzeln freigegebene SameDB-Kopie in leere formgleiche Targets mit neun
  Parametern und fünf NOT-NULL-Summaryfeldern. KEEP/REGENERATE und vorhandenes
  SNAPSHOT/SERIALIZABLE ausdrücklich wählen;100000 Zeilen/16MiB nur absenkbar.
- Bestehende passende FKs unverändert; fehlende gemappte Beziehungen nach Copy
  durch den gemeinsamen internen Renderer anlegen. Keine Constraint-Deaktivierung,
  Rechteerteilung oder automatische Konfiguration; Identity-Zählerfortschritt
  trotz Rollback, kein RESEED.
- Vier Lifecycle-Slots13/14/14/9. Fünf Copygruppen, Client und genuine4.0→4.1-
  Lifecycle auf Linux2019/Windows2025 exaktCU8 bestanden; eigene Bereinigung
  unabhängig geprüft. Vier dynamische Identity-Zustände und zwei SNAPSHOT-
  Konkurrenzfälle auf Linux2019 gezielt nachgewiesen; abgeschlossene
  Teilnachweise aus Fehlerläufen ausdrücklich getrennt wiederverwendet.
  Head-CI separat im PR; teilweise validiert und unveröffentlicht.

## 2026-10-04 – Table Clone Trigger-Vorschau / 4.0.0

- Einzeln freigegebenes Windows-Opt-in `IncludeTriggers=1` im bestehenden Planner;
  13 Parameter, Standardtail10..13. Executor behält14 Parameter und bleibt triggerfrei.
- AST-/Katalogbindung über den vorhandenen exakt gepinnten Parser2.0;
  UTF16-Identifierumschreibung mit erhaltenen Kommentaren/Literalen,
  quellengetreuen Events, SET-Metadaten, FIRST/LAST und Disabledzustand.
- Generierte Triggernamen teilen das Kollisionsgate mit bestehenden Objekten
  und geplanten Map-Zieltabellen. Lifecycle kennt4.0 und historische Releases;
  Hash-v1 bindet das neue Releasefeld4.0.
- Unabhängige Coreprüfung, statische Kopplung und offline Syntaxprüfung bestanden.
  Zwei gezielte Trigger-Fixtures auf Windows2025/exakt CU8 CL170 lokal bestanden;
  Clean4/genuine3.1→4, Repeat, Clienthash, Consumer, Uninstall und Cleanup bestanden.
  Linux2019/latest CL150 Option0-/Lifecycle-PASS wiederverwendet; nachfolgende
  Coreänderungen ausschließlich Option1, unabhängig geprüft. Temporären exakten
  Parsertrust wiederhergestellt; keine Konfigurations-, Rechte- oder Owneränderung.
  Head-CI separat im PR; weitere native Ziele, zentrale4.0-Nutzung und Minimalrechte offen.
  Teilweise validiert und unveröffentlicht; historische Evidenz bleibt getrennt.

## 2026-10-04 – Phonetik 1.0.0 (unreleased, begrenzte Teilnachweise)

- Zwei einzeln freigegebene IF-Fassaden und zwei interne FT auf eigener SAFE-Assembly.
- Geschlossene Alphabete, feste inhärente Transformation, UTF16-/Quotenpriorität
  und vollständige Double-Metaphone-Codes einschließlich terminalem J-Leerzeichen.
- Markierte Apache-1.18.0-Portierung mit Headern und modullokaler LICENSE/NOTICE.
- Explizite installierte SHA2-512-Erwartung, kohärente Owner/Slotmarker,
  zweipassiger AppLock-Lifecycle; Trust bleibt getrennt.
- Build, Framework (223 Assertions je drei Kulturen), eigene IL und begrenzte
  native Teilnachweise auf Linux2019/latest CL150 und Windows2025/exakt CU8
  CL170 bestanden. Vier lokale Fixtures und 18 Clientreader je Ziel sowie
  local/central Lifecycle mit frischer Bereinigung; keine Konfigurations-,
  Rechte- oder Owneränderungen. Java-Differential, vollständige Qualifikation
  und aktuelle Head-CI bleiben offen; teilweise validiert, unveröffentlicht.


## 2026-10-04 – ZIP-Dateifassaden 1.0.0, begrenzte Teilnachweise

- Zwei einzeln freigegebene lokale Windows-USPs verwenden statisch bestehende
  ZIP-Writer-/Reader- und Filesystemverträge; keine neue Assembly/Providerlogik.
- Vollständige Payloadvorbereitung vor Dateipublikation, TX-Abweisung und
  eigene späte SQL-ResultTable-Transaktion; keine SQL-/Dateisystematomarität.
- Drei konkrete Brücken-Temps als eng genehmigte Namingausnahme; kein Corefix.
- Lifecycle, Help, Manifest und fünf synthetische Runtime-Fixtures vorhanden;
  elf frühere und zwei gezielte AppLock-Fallnachweise auf Windows2025/CU8 CL170
  local bei identischen Produktbytes; kein gemeinsamer 13-Fälle-Erfolgslauf.
  Eigene Bereinigung frisch geprüft. Vollständige Qualifikation und aktuelle
  Head-CI separat offen; teilweise validiert, unveröffentlicht.

## 2026-10-04 – Gemeinsamer SAFE-JSON-Kern und Aggregate 1.2.0

- Zwei einzeln freigegebene Aggregate und eine interne CLR-Bridge verwenden
  denselben Kern wie die vier bestehenden Konstruktor-USPs; deren Signaturen,
  globale Budgets und ResultTable-Verträge bleiben erhalten.
- Bekannte Binarybytes, sechs exakt typisierte Assemblymarker und kohärente
  vorhandene Eigentümer binden den achtteiligen Lifecycle ohne Rechtevergabe.
- Offlinequalifikation, kanonischer Projektbuild, lokale Acht-Fixture-Läufe
  auf Linux2019/CL150 und Windows2025/CU8/CL170 sowie genuine1.1 lokal und
  genuine1.0 lokal/zentral mit Repeat/Uninstall und eigener Bereinigung bestanden.
- Sechs erste-GO-Negativfälle bestanden; weitere Lifecycle-, Minimalrechte-,
  Engine-Merge-/Heap-/Spill- und Zielmatrixnachweise bleiben offen. Aktuelle CI
  wird separat am PR-Head geprüft. `partially validated`, `unreleased`.

## 2026-10-03 – Begrenzter Paarvergleich 1.0.0, unveröffentlicht

- Eine individuell freigegebene USP über die drei vorhandenen statischen TVFs;
  keine neue CLR-/Assembly-/Unicodeimplementierung.
- Typgenaue caller-lokale Paare, globale Row-/Text-/Workadmission und vollständige
  Ergebnisprüfung vor gemeinsamer ResultTable-Helper-/Insert-Atomik.
- Eigener Lifecycle mit bekannten same-database Dependencies, administrativer
  exakter SHA2-512-Bindung und vorhandener Metadatensicht.
- Fünf synthetische SQL-Fixtures und Lifecycle-Wiederholungen auf Linux 2019
  local und Windows 2025/CU8 local erfolgreich; gezielter zentraler Windows-
  Client-/ResultTable-/Uninstall-Bestätigungsnachweis unabhängig geprüft.
  Minimalrechte, weitere Lifecycle-Negativfälle, Ziele und Head-CI bleiben offen.

## 2026-10-03 – XLSX-Anzeigeformatierung 1.2.0 (unreleased)

- Additive Anzeige-TVF mit acht Inputs, zwei Outputs, zehn Literalformaten und drei expliziten Kulturen im bestehenden SAFE-Provider. Exakte SqlDecimal-Rundung und begrenzter Temporalübertrag; Raw-/Typquellen bytegleich.
- Lifecycle erkennt echte 1.0/1.1-Upgrades und 1.2-Reinstall mit neun Slots; bestehendes Sichtbarkeitsgate unverändert. Separate genuine1.1-, Display-, Client-, Kompositions- und CI-Testquellen.
- Nachweisergänzung 2026-10-04:19 Offlinephasen am aktuellen Artefaktpaar und separate13 genuine1.1-Offlinephasen bestanden; unveränderte Genuine1.0-/ZIP1.3-Verpackung separat bestanden.
- Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.
- Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`.


## 2026-10-03 – Jaro-Winkler im bestehenden SAFE-Provider 1.1.0, teilweise validiert

- Individuelle Funktionsfreigabe und konkrete Erweiterung der bestehenden Assembly
  auf 1.1.0 kanonisch festgehalten; genau eine öffentliche IF und eine interne FT.
- UnicodeScalar als einziger physischer Helfer; bestehende Distanzverträge bleiben.
- Bekannte 1.0-/1.1-Lifecycle-Releases mit vier/sechs Slots, genuine historische
  Blobpaketierung und neue harte Golden-/Metadaten-/Clientfixtures vorbereitet.
- Neue 1.1-/genuine 1.0-Releasebuilds, vollständige Distanz-/Jaro-Frameworkregression,
  Pythonreferenz und beide IL-Metadatengates separat bestanden.
- Private, source-/binarygebundene native Gesamtadapter auf Linux 2019/latest
  CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral und SC-UTF8 bestanden:
  genuine Upgrade, sechs Slots, API/Client/Lifecycle/Caller/AppLock/Faults und
  unabhängige eigene DB-/Trustbereinigung. Keine Config-/Rechte-/Owneränderung.
- Doomed-Guardnachweis im eigenen DB-Prozedurkontext des ganzen originalen
  Firstbatch; kein vollständiger SQLCMD-doomed-Nachweis. Minimalrechte, weitere
  physische Ziele und Heap offen; aktuelle CI separat am PR-Head.
  `partially validated`, `unreleased`; frühere 1.0-Evidenz bleibt historisch.

## 2026-10-03 – Windows Filesystem NoOverwrite-Korrektur / 1.0.0 unreleased

- Binary-/Textschreiben und Transcoding geben das bestehende Overwrite-Flag an den kanonischen Helper weiter. NoOverwrite veröffentlicht ausschließlich per nicht überschreibendem Move und erhält auch ein während des Staging-Schreibens erzeugtes Ziel; der Overwrite=true-Pfad bleibt unverändert. Keine neue API, Lifecycle- oder Versionsänderung.
- Aktueller .NET-Framework-4.8-Projektbuild und Releaseartefakt-Erzeugung erfolgreich. Historischer privater Helpernachweis: neun synthetische Fälle/254 Assertions. Der aktuelle sourcegebundene Fixed-only-Harness bestand tatsächlich neun Fälle/254 Assertions einschließlich eigener Bereinigung und abschließender Pins; vier private tatsächliche Prozesskontrollen bestanden Nonzero, Timeout, Capturegrenze und Postpin-Drift. Windows-CI ist gekoppelt und bleibt ein separater Mergegate am exakten PR-Head. Die korrigierte Binary im SQL-Caller-/NTFS-Kontext ist nicht qualifiziert; `partially validated`, `unreleased`.

## 2026-10-03 – Script-only Tabellenklon Welle1 / 2.0.0

- Bestehende zwei USP-Slots erweitern die rein textuelle Vorschau um Computed/PERSISTED, gefilterte Rowstore-Indizes und optionale typisierte Extended Properties. Zehn Parameter einschließlich `IncludeExtendedProperties` an Position6 vor dem Standardtail verschieben die bisherigen Positionen6..9 auf7..10; sieben einzelne SET-Zeilen vor TABLE begründen die dokumentierte Signaturversion2.0.0. Keine Scriptausführung oder Datenkopie durch die API; Welle2 bleibt getrennt.
- Finale öffentliche Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral bestanden: vier Runtime-Fixtures, Clientmetadaten, 27 Propertytypen/Owner und separate18-datetimeoffset-Produktpfadregression, 2MiB-Atomik, genuine1.0-Upgrade, Caller-TX/SET, AppLock, Rollback, Kollisions-/Dependency-Erhalt, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung.
- Hashgebundene Source-/Helper-/Genuine-Inputs, tatsächlicher Exit mit vollständigen Kanälen, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen;32 ist ausschließlich der Visibility-Teilzähler. Die korrigierte Prefixfixture bestand in erneuten öffentlichen Native-Läufen auf beiden ausgewählten Zielen. Alle sieben CI-Checks am geprüften Head76888216 bestanden, einschließlich CloneLinux2019/2022/2025. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben offen. `partially validated`, `unreleased`; historische V1- und fehlgeschlagene Zwischenstände bleiben getrennt.

## 2026-10-02 – XLSX-Zelltypinterpretation 1.1.0

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

## 2026-10-02 – Levenshtein-/OSA-Provider 1.0.0, gezielt nativ teilweise qualifiziert

- Dedizierter portabler SAFE-CLR-Provider für genau die beiden einzeln
  freigegebenen Distanzfunktionen; zusätzliche Assembly-/Lifecyclefreigabe
  und Vor-Source-Vertrag dokumentiert. Jaro und Phonetik bleiben getrennt.
- Gemeinsame Unicode-Scalarvalidierung und zwei-/drei-Zeilen-DP, Standard/Large,
  strikter MaxDistance-/Fehlerprioritätsvertrag ohne Kürzung oder Näherung.
- Offline Vollmatrixreferenz 21185 und Framework 81380 Assertions erfolgreich,
  einschließlich tatsächlicher 1M-/16M-DP und Large-Bandberechnung; Releasebuild
  erfolgreich. Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.
- Historischer erster Linux-Lauf SQL468/State9 im Metadaten-Fixture wurde
  vollständig bereinigt; korrigierter neuer Gesamtadapter separat erfolgreich;
  teilweise validiert und unveröffentlicht.

## 2026-10-02 – Gruppierte JSON-Konstruktoren 1.1.0

- Zwei individuell freigegebene USPs liefern GroupOrdinal und JsonValue je vorhandener Gruppe; gemeinsame globale Budgets und atomare Ausgabe.
- Ein bestehender T-SQL-Prüf-/Escapingkern mit GroupMode; alte öffentliche Signaturen und ungruppierte Emptyverträge bleiben erhalten.
- Strikter fünfteiliger Lifecycle für 1.0/1.1, Caller-TX-Guard vor SET und echter unveränderter 1.0-Vorgänger als Testartefakt.
- Offline-Syntax, statische Kopplung und Dokumentationsaudit erfolgreich. API-/100000-/16-MiB-/Clientprüfungen auf Linux 2019/latest und Windows 2025/CU8 lokal/zentral erfolgreich als Teil früherer insgesamt fehlgeschlagener Läufe; finale fokussierte Metadaten-/Lifecycle-/Central-/Upgrade-/Bereinigungsadapter erfolgreich.
- Historische Oraclefehler 53609/4, Kollisionsfehler 206, Caller-Batchfehler 3998 und Central-Orakelfehler 54600/45 bleiben als fehlgeschlagene Läufe erhalten. Neue Minimalrechte einschließlich offener VIEW DEFINITION/SELECT-Entscheidung und separater aktueller CI-/PR-Mergegate offen. Teilweise validiert und unveröffentlicht.

## 2026-10-02 – Deterministic GeoJitter 1.2.0 implementiert, teilweise validiert

- Die einzeln freigegebene Inline-TVF erhält vor Source einen unabhängig
  geprüften begrenzten Vertrag für synthetische 2D-Points/SRID 4326,
  Entitätsparameter und Radius 1–10000 m (Default 100 m).
- Modellreferenz und sichere native Operanden auf ausgewählten Lab-Zielen
  qualifiziert; echte 128-Byte-/größere UDTs getrennt vom unbeobachteten
  129-Byte-Fall. Keine zusätzliche Spatial-API oder Anonymisierungszusage.
- Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.
- Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

## 2026-10-02 – Regex-Captures und gruppenbezogenes Replace 1.3.0

- Zwei einzeln freigegebene APIs über den gemeinsamen SAFE-CLR-Kern:
  alle Capture-Wiederholungen mit stabilen Gruppenordinals und getrenntes
  Replace mit strikten `$1`-/`${Name}`-/`$$`-Referenzen.
- Zusätzlich ausdrücklich freigegebene erwartete SHA2_512-Binaryhashbindung
  für Deploy/Uninstall; keine historische CLR-Versionsableitung oder Hashfallback.
- Finale Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8
  CL150/160/170 lokal/zentral erfolgreich: API-/Clientverträge, echter
  1.2-Upgrade, Reinstall, Caller-TX/SET-Erhalt, AppLock, Rollback,
  Kollisions-/Dependency-Erhalt, Uninstall und eigenes DB-/Trustcleanup.
- Frühere API-only-Nachweise bleiben getrennt; fehlgeschlagene Gesamtversuche
  führten zu korrigierter Vorgänger-SQLCMD-Normalisierung, optionsneutralem
  Snapshot und sicherer Credential-Quelle der zweiten Testverbindung.
- Neue Capture-Minimalrechte, weitere Ziele, ältere Capture-Upgrades und
  tatsächliche große SQL-Capture-Ausgabe offen. Aktuelle CI wird separat als PR-Mergegate nachgewiesen; teilweise
  validiert und unveröffentlicht, keine Heap-/Backtracking-/Durchsatzgarantie.

## 2026-10-02 – Parser-Härtung 2.0.0 in Arbeit

- Konkreter begrenzter Vertrag für die vier bestehenden TVFs vor Source
  dokumentiert und unabhängig geprüft. Der eingefrorene Wächterkandidat
  bestand 82 isolierte Framework-Kindprozesse mit exakter Dependency,
  einschließlich unabhängiger Wiederholung.
- Strikte Versionen und endliche Eingabegrenzen, vorgeschaltete
  Komplexitätsprüfung, keine partiellen ASTs und atomare begrenzte Ausgaben
  bilden die geplante Major-Inkompatibilität gegenüber 1.0.0.
- 245 integrierte Framework-Kindprozesse sowie Windows 2025/CU8 CL150/160/170
  bestanden: lokaler/zentraler Modus, echter 1.0-Upgrade, Wiederholung,
  Grenzen/Syntax, Caller-TX/SET-Erhalt, Kollisionsschutz und eigenes Cleanup.
- Zusätzlicher finaler Live-Lauf bestand saubere Erstinstallation,
  Fremdschema-/Shared-Dependency-Erhalt, Lock-Contention und eigene
  Transaktionswiederherstellung nach injiziertem post-DROP-Fehler.
- Windows 2019 bleibt wegen fachfremder Pending-Konfiguration blockiert;
  Windows 2022, minimale Rechte und tatsächliche Ausgabeceilings sind offen.
  Accounting-Helper ersetzen keine SQL-Ceilingqualifikation.
  Historische 1.0.0-Evidenz bleibt erhalten; 2.0 ist teilweise validiert.
  Kein Dependency-Upgrade, Trigger-Rewriting oder Release.

## 2026-10-02 – Erster externer Queue-Worker

- Manuell gestarteter PowerShell-Provider mit einem Supervisor, 1–8 Slots,
  separaten Handler-/Controlverbindungen und bestehenden SQL-Kern-APIs.
- Readonly-Claim-/Executionzuordnung, atomarer Handler-/Completecommit,
  kooperative Checkpoints, Watchdog und Drain ohne forcierten Abbruch.
- Retry ausschließlich explizit für geeignete Handler und transiente
  Fehler nach bestätigtem Rollback; Dead Letter separat gezählt.
  Ungeklärter Commit oder Ownershipverlust wird nicht blind wiederholt.
- Windows-Host-Labtests gegen SQL Server 2019 Linux/latest und 2025
  Windows/CU8 einschließlich tatsächlichem 60-Sekunden-Heartbeat erfolgreich.
  [Worker-Testmatrix](Workers/ExternalQueue/Tests/README.md) trennt finale
  Nachweise, erfolgreiche Linux-Host-CI auf SQL 2019 und offene Transport-/Rechte-/Recovery-/Central-
  Qualifikationen. Teilweise validiert, unveröffentlicht; kein Dienstbetrieb.

## 2026-10-02 – Deterministic Translate 1.1.0

- Additive echte Inline-TVF für formaterhaltende synthetische ASCII-Kennungen:
  casegekoppelte bijektive Buchstaben-/Ziffernabbildung, explizite Separatoren,
  Standard 2 MiB/Large 16 MiB, bytegenaue Fehlerpriorität und sichere native
  Operanden. Bestehende sechs Slots unverändert, keine weitere Dependency.
- Integrierte Referenzsuite und unabhängige Reviews erfolgreich. Vollständige
  Adapter auf Linux 2019/latest local/central und Windows 2025/CU8 central
  CL150/160/170 bestanden, einschließlich aller sieben Slots, Metadaten,
  echtem 1.0-Upgrade, Fehler-/Lifecyclefällen, Uninstall und eigenem Cleanup.
- Windows local: API-/Safetyfälle im früheren Gesamtfehllauf bestanden;
  separate korrigierte Metadaten-/Lifecycleprüfung erfolgreich. Dieser
  Teilnachweis ist kein nachträgliches PASS des ursprünglichen Gesamtlaufs.
- Keine Serverkonfiguration oder Rechteausweitung. Neue Minimalrechte,
  weitere physische Targets, Kapazität und aktuelle CI offen; teilweise
  validiert und unveröffentlicht, kein Merge- oder Releaseabschluss behauptet.

## 2026-10-02 – Deterministic Range, DateShift und Lookup 1.0.0

- Drei einzeln freigegebene synthetische Mapping-APIs mit einem gemeinsamen
  versionierten SHA256-/128-Rejection-Kern; keine CLR-, I/O-, persistierte
  Mapping- oder Anonymisierungsfunktion.
- Atomare Standard-USP-Ausgabe, Help-first vor privater Temp-Compilergrenze,
  versions-/ownershipgebundener Lifecycle und nichtdoomende frühe
  Callertransaction-Abweisung ohne SET-Änderung.
- Identische finale Adapter auf 2019 Linux/latest CL150 und 2025 Windows/CU8
  CL150/160/170 am 2026-10-02 erfolgreich. Weitere Targets, CrossDB-
  Minimalrechte und Produktionskapazität offen; teilweise validiert/unreleased.

## 2026-10-02 – Begrenzter XLSX-Raw-Reader 1.0.0 und ZIP-Fassade 1.4.0

- Individuell freigegebene Worksheetliste und sparse Raw/Text/Formula/Cache-Zellliste, SAFE und memory-only; kein SDK, File-I/O, Formula-Execution oder Typ-/Anzeige-Folgescope.
- Kanonischer ZIP-Parser wird über eine technische .NET-Fassade wiederverwendet. Ressourcenlimits, kooperatives Budget und konservativer 128-MiB-Outputcharge vor Ausgabe; keine Peak-RAM- oder harte Wallclock-Zusage.
- Finale synthetische Adapter auf Linux 2019/latest und Windows 2025/CU8 erfolgreich, einschließlich lokaler/zentraler Verwendung, Clientmetadaten, atomarer ResultTable, Caller-Scope, nichtdoomendem XLSX-/ZIP-Lifecycle und tatsächlichem ZIP-1.3-Upgrade. Begrenzte Framework-NoIO-/IL- sowie unabhängige Writer-Orakel erfolgreich.
- Bekannte Restmatrix offen; teilweise validiert und unveröffentlicht. Tatsächliche Releaseveröffentlichung, weitere Plattformen und Kapazitätsqualifizierung werden nicht behauptet.

## 2026-10-01 – Script-only Tabellenklon 1.0.0

- `USP_ScriptTableClone` liefert deterministische begrenzte SameDB-DDL-
  Vorschau für Spalten, Defaults, Checks, PK/UQ, Rowstore-Indizes und optionale
  Identity; keine DDL-Ausführung oder Datenkopie durch die öffentliche API.
- Unsupported atomar sichtbar, vollständiger Plan vor ResultTable-Mutation,
  datenbankweite Metadatensicht, Lifecycle-Callertransaktionen nichtdoomend
  abgewiesen und registrierte Typdrift kontrolliert repariert.
- Finale synthetische Adapter auf 2019 Linux/latest und 2025 Windows/CU8
  erfolgreich. Weitere Zielkombinationen, GitHub-Runtime und Lowpriv-CrossDB
  offen; `partially validated`, `unreleased`. Keine Folgeausbauten enthalten.

## 2026-10-01 – JSON-Konstruktoren 1.0.0

- Getrennte `USP_JsonArray` und `USP_JsonObject` mit einem gemeinsamen
  begrenzten Prüf-/Escapingkern, expliziten ValueKinds und caller-lokalen
  Eingabetabellen. Keine Typinferenz, JSON-Aggregate oder SQL-Ausführung.
- Atomare ResultTable-Ausgabe, Help-first, binär längensensitive Keys,
  strikte Zahlen-/Boolean-/Fragment-/Unicode-Verträge und begrenzte LOBs.
- Vollständige finale Adapter auf SQL Server 2019 Linux/latest und 2025
  Windows/CU8 erfolgreich; Lifecycle-Typreparatur und Namespace-Compilegrenzen
  nach unabhängigem Review nachgetestet. Weitere Ziele, gemappte CrossDB-
  Minimalrechte und Produktionskapazität offen; teilweise validiert/unreleased.

## 2026-10-01 – Regex Matches und Split 1.2.0

- `TVF_RegexMatches` und `TVF_RegexSplit` verwenden den bestehenden SAFE-CLR-
  Dialektkern. Originaltexte, UTF-16-Positionen und leere Tokens bleiben
  erhalten; keine Captures, Backreferences oder automatische Entquotierung.
- Vollständige begrenzte Materialisierung vor Ausgabe, MaxRows und vorhandene
  Standard-/Large-Budgets; Vertragsfehler und Timeout ohne Teilmenge.
- Vollständige Adapter auf SQL Server 2019 Linux/latest CL150 und 2025
  Windows/CU8 CL150/160/170 erfolgreich; echte 1.0-/1.1-Upgrades und lokale/
  direkt zentrale Minimalrechte geprüft. Weitere Ziele, Lowpriv-CrossDB und
  SQL-100k-Durchsatz offen; `partially validated`, `unreleased`.

## 2026-10-01 – ZIP-Writer 1.3.0

- `USP_CreateZipFromEntries` erzeugt begrenzte In-memory-ZIPs aus einer caller-lokalen Temp-Tabelle: Stored als Default, Deflate ausdrücklich wählbar, strikte UTF-8-Namen und atomare ResultTable-Ausgabe.
- Reiner SAFE-CLR-Kern, Help-first, Lifecycle-/Upgrade-/Kollisionsschutz und unabhängige Frameworktests; keine Datei-I/O- oder ZIP64-Erweiterung.
- Internes Empty-Payload-Marshalling des bestehenden Readers korrigiert; öffentliche SQL-Signaturen, Limits und encrypted NULL bleiben unverändert. Zusätzliche Readerkopien sind dokumentiert.
- Ausgewählte Live-Tests auf SQL Server 2019 Linux und 2025 Windows/CU8 erfolgreich; höhere SQL-Live-Grenzen und reale Produktionsarchive bleiben offen. Status `partially validated`, `unreleased`.

## 2026-10-01 – Unquoting und Split-USP

- `toolbelt.string.split-advanced` 1.1.0 ergänzt die einzeln freigegebenen
  `TVF_UnquoteToken` und `USP_SplitAdvanced`; der vorhandene Split-Kern bleibt
  unverändert und unquotet niemals automatisch.
- Unquoting behandelt explizite oder automatisch erkannte äußere Quote-Paare,
  doubled closing Qualifier und nur ausdrücklich aktivierte Backslash-Escapes.
  Fehler bleiben atomar; NULL, UTF-16-/BIN2-Grenzen und Fehlerpriorität sind
  Bestandteil des öffentlichen Vertrags.
- Die USP ergänzt Help, Debug-Messages und caller-lokale ResultTables mit
  ResultTable-Dependency und callerfreundlichen Transaktionen/Savepoints.
  Das Modul bleibt `partially validated` und `unreleased`; die konkrete
  Ausführungsevidenz und offene Grenzen stehen in seiner Testmatrix.

## 2026-10-01 – Regex R2a

- `toolbelt.string.regex` 1.1.0 ergänzt ausdrücklich freigegebene
  `SVF_RegexReplace` und `SVF_RegexSubstring`: literal Replacement, UTF-16,
  max-Signaturen, Standard-/Large-Profil und begrenzter Ergebnisbau.
- T-SQL-Fassaden erhalten max-Defaults vor internen SAFE-CLR-Kernen;
  kooperatives Gesamtbudget und Restbudget ergänzen Engine-Timeouts.
- Tests koppeln R1b-Regression, Profil-/Patterngrenzen, echte 1.0.0-Upgrades,
  Central-/Codepage-Aufrufe, Dependency-Schutz und konkurrierende LOBs.
- Alle Module bleiben `unreleased`; kein allgemeiner Benchmark oder
  Native-RE2-/Streaming-/Parallelitätsvertrag wird eingeführt.

## 2026-10-01 – S2 Quote/Escape Split

- Neues dependencyfreies Modul `toolbelt.string.split-advanced` mit verpflichtender `TVF_SplitAdvanced`, Originaltokens, längstem Separator und atomarer Geschäftsfehlerzeile.
- Grenzen, UTF-16-/BIN2-Semantik, priorisierte Fehler, local/central Lifecycle, CI-/Lab-Adapter und synthetische Contracttests umgesetzt; optionaler USP und Unquoting nicht enthalten.
- Risikobasierte physische Tests auf SQL Server 2019 Linux und 2025 Linux/Windows erfolgreich; weitere physische Zielkombinationen nicht ausgeführt. Die zusätzliche [GitHub-hosted Linux-Matrix 2019/2022/2025](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/36857332229) ist ebenfalls erfolgreich. Status `partially validated`, `unreleased`.

## 2026-09-01 – GitHub-hosted Linux-Versionsmatrix

- Alle fünfzehn bislang auf SQL Server 2025 beschränkten Modul-Runtime-Workflows
  laufen jetzt über die Matrix 2019, 2022 und 2025. Die Adapter unter `Tests/CI/`
  unterstützten diese Versionen bereits; nur die Workflows setzten `TBX_SQL_VERSION`
  nicht und verwendeten ein fest verdrahtetes 2025-Image.
- Zwei dadurch aufgedeckte Testadapterfehler sind behoben: der Loopback-Linked-Server
  der W5-Adapter verwendete `encrypt=optional`, das erst ab MSOLEDBSQL 19 existiert,
  und `run-file-content-linux.sh` setzte feste Compatibility Levels 150, 160 und 170.
- Kein öffentliches SQL-Objekt, kein Vertrag und kein Modulmanifest wurde geändert.
  Alle Module bleiben `partially validated`, weil die Windows-Matrix weiterhin offen ist.

## 2026-08-24 – ZIP-Metadaten-Listing und Statuswahrheit

- `toolbelt.archive.zip-memory` Version `1.2.0` stellt die neue
  Listing-API samt internem CLR-TVF, Lifecycle, Help, ResultTable,
  Local-/Central- und Struktur-/Encoding-/Pfadverträgen.
- Windows-.NET-Framework-4.8-Build und SQL-Server-2019-/2022-/2025-Linux-
  Runtime für Extraktion und Listing sind im
  [GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453)
  erfolgreich; Windows-Runtime und echte Extremgrößen bleiben offen.
- Aggregierte Manifeststatus, Kandidatenplan und Roadmap sind konsolidiert;
  doppelte AP-/Phasenabschnitte entfernt und zukünftige Wellen mit expliziten
  Freigabegates verankert.
- Der Dokumentationsvalidator prüft abgeleitete AP-Status lokal im jeweiligen
  Abschnitt, Manifestaggregate und eindeutige Planungs-IDs.

## 2026-08-05 – W5b Event Log

- `toolbelt.core.second-session` auf Version `1.1.0` mit `@SuppressResult` erweitert.
- `toolbelt.core.event-log` Version `1.0.0` implementiert: rollback-unabhängiger Writer, Event-View, begrenzte Retention und sauberer Work-Type-Lifecycle.
- SQL Server 2025 Linux CL150/160/170 einschließlich Rollback, uncommittable Caller, Concurrency, Central und Uninstall erfolgreich.

## 2026-08-05 – Work-Type-Katalog 1.1.0

- `toolbelt.core.work-type` um `toolbelt_core.USP_RemoveWorkType` erweitert.
- Entfernung ist nur nach Disable, mit `@AllowDelete = 1` und optionaler `rowversion`-Prüfung zulässig.
- Savepoint-, uncommittable-Caller-, ResultTable- und Lifecycle-Verträge werden capabilitybezogen getestet.

## 2026-08-04 – W5a Second Session

- `toolbelt.core.second-session` Version `1.0.0` implementiert.
- Registrierte Work-Types laufen synchron über einen administrativ vorbereiteten
  Loopback-Linked-Server in einer getrennten SQL-Server-Session; Raw SQL und
  im Modul gespeicherte Credentials bleiben ausgeschlossen.
- SQL-Server-2025-Linux-Loopback-Spike ist erfolgreich; physische SQL-Server-
  2019-/2022- und Windows-Läufe bleiben `not executed`.

## 2026-08-01 – W4b Work-Type-Katalog

- `toolbelt.core.work-type` Version `1.0.0` implementiert.
- Persistente Tabelle `toolbelt_core.WorkType` mit expliziten Constraint-/Indexnamen und `rowversion`.
- Register, Disable, Resolve, View, ResultTable, Concurrency, Redeploy, Central und Data-Loss-Uninstall-Schutz.
- `DEC-2026-025` schließt die Tabellen-/Constraint-/Index-Namenskonvention.
- SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193.

Alle wesentlichen Änderungen an SQL Server Toolbelt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

- 2026-10-07: Regex-CI-Cleanup prüft volle Container-ID und Owner gemeinsam,
  entfernt per ID und verlangt frische Namensabwesenheit. Run-Attempt-/SQL-/
  CL-Name und Owner vor Setup geprüft; Cleanupfehler bleiben sichtbar und
  bestätigter Cleanup erhält den vorherigen Fehlerstatus. Lab-No-op und
  vorhandene zusätzliche R2a-Trustbereinigung separat erhalten. Offlinegate
  und Dokumentation gekoppelt; Produkt-SQL, Binaries und Matrix unverändert.

- 2026-10-07: XLSX-Qualifikations-CI lädt nur15 benannte aktuelle und genuine
  historische Releaseinputs hoch. Private Argument-/Prozessdateien, Logs,
  Qualifikations- und Buildbäume bleiben außerhalb des Uploads. Die bestehende
  statische Prüfung kontrolliert die tatsächliche Auswahl mit synthetischen
  Sentinels;19 Frameworkphasen, Produktbinaries, SQL, Trust und Rechte unverändert.

- 2026-10-07: Constructors-CI-Cleanup bindet volle Container-ID und Owner aus
  derselben Aufnahme, entfernt per ID und verlangt frische Namensabwesenheit.
  Run-/Attempt-/SQL-Name und Owner vor Setup geprüft; privates Verzeichnis
  erst nach fallibler Vorbereitung, feste Cleanupzeugen und Fehlerstatuserhalt.
  Bestehende Offlineprobe/Testdokumentation gekoppelt; Produkt-SQL/Binaries,
  Matrix, Rechte, Trust und Lab unverändert. Kein Hard-Interrupt- oder
  Releasequalifikationsnachweis.

- 2026-10-07: Safe-Cast-CI-Cleanup bindet volle Container-ID und Owner aus
  derselben Aufnahme, entfernt per ID und verlangt frische Namensabwesenheit.
  Run-/Attempt-/SQL-Name vor Setup geprüft; privates Verzeichnis erst nach
  fallibler Vorbereitung, feste Cleanupzeugen und bisheriger Fehlerstatus.
  Bestehende Offlineprobe/Testdokumentation gekoppelt; Produkt-SQL, Matrix,
  Rechte, Trust und Lab unverändert. Kein Hard-Interrupt- oder
  Releasequalifikationsnachweis.

- 2026-10-07: Pointer-CI-Cleanup bindet volle Container-ID und Owner aus
  derselben Aufnahme, entfernt per ID und verlangt frische Namensabwesenheit.
  Run-/Attempt-/SQL-Name vor Setup geprüft; privates Verzeichnis erst nach
  fallibler Vorbereitung, feste Cleanupzeugen und bisheriger Fehlerstatus.
  Bestehende Offlineprobe/Testdokumentation gekoppelt; Produkt-SQL, Matrix,
  Rechte, Trust, Lab und manuelle Lastfälle unverändert. Kein Hard-Interrupt-
  oder Releasequalifikationsnachweis.

- 2026-10-07: Deterministic-CI-Container-Cleanup an gemeinsamen Owner-/ID-
  Nachweis und frische Abwesenheit gebunden; Run-/Attempt-/SQL-/CL-Identitaet,
  Fehlerstatus und feste Cleanupzeugen statt unterdruecktem name-only rm.
  Bestehende Offlineprobe und Dokumentations-Impact gekoppelt; Produkt-SQL,
  sechs CI-Paare, Rechte, Trust und Lab unveraendert. Head-/Main-Nachweis im PR;
  keine Hard-Interrupt-/Releasequalifikation.

- Die sechs bestehenden Deterministic-CI-Jobs binden ihren exakten
  Compatibility-Level-Opt-in vor Deploy/Upgrade an alle 13 eigenen Datenbanken
  und pruefen ihn vor jedem SQL-Skript erneut. Der erwartete Fehlerpfad
  startet nach fehlgeschlagenem Gate kein Skript. Ohne Opt-in bleibt der
  historische Multi-Level-Scope unveraendert; keine neue Produktfunktion,
  Zielmatrix, Rechte- oder Trustaenderung.

### Geändert

- AI Repository Foundation von `1.4.0` auf den manifestierten Core `1.8.0`
  aktualisiert. Semantische Upgrade-Bewertung, zentrales Registry-Profil,
  Repository-Continuity und Rule-Context-Cache-Governance sind integriert;
  optionale Foundation-Capabilities bleiben unselektiert.
- Die vollständige lokale Adaptermatrix ist auf physischen SQL-Server-2019-,
  2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich.
  20 Module sind damit `validated`; sieben bleiben wegen ausdrücklich
  abgegrenzter Performance-, Client-/Treiber-, Fixture-, Interoperabilitäts-
  oder manueller Sicherheitsgates `partially validated`.
- Die W1-Pflichtfälle decken zusätzlich CI-/CS-/UTF-8-Collations, leere
  Trim-Mengen, den vollständigen druckbaren ASCII-Raum, ungültige kurze
  Prozentsequenzen, Large-Input-Roundtrip und Fremdobjektkollisionen ab.
- W2a/W2b ergänzen Fremdobjektkollisionen sowie einen synthetischen
  100.000-Zeilen-Bucket-Workload; der Capability Catalog prüft eingeschränkte
  Metadatensichtbarkeit ohne Rechteausweitung.
- Second Session und Event Log verwenden im Loopback-Providervertrag
  `encrypt=no`, das von den eingesetzten OLE-DB-18-/19-Pfaden akzeptiert wird.

### Hinzugefügt

- `toolbelt.core.execution-cancel` Version 1.0.0 implementiert den
  freigegebenen W6d-Slice: persistierte, irreversible kooperative
  Cancellation je ExecutionId mit sicherer Status-TVF und Skalurfunktion.
  Der Kern führt kein `KILL` aus, verändert keine Work-Queue-Zeilen und
  akzeptiert keine aktive Caller-Transaktion.

- ADP-008 ergänzt für `toolbelt.core.console-message` einen Project Adapter
  0.1 mit deterministisch aus den kanonischen Modulquellen erzeugten Install-,
  Update- und Cleanup-Entrypoints. Der vorhandene Modulvertrag wurde auf SQL
  Server 2025 Linux getrennt unter Docker und Podman end-to-end erfolgreich
  ausgeführt; der Toolbelt-Runner bindet ausschließlich bestehende Lab-Runs
  und verwaltet keine Provider-Infrastruktur.

- `toolbelt.string.regex` Version `1.0.0` implementiert den ausdrücklich
  freigegebenen R1b-Slice mit `SVF_RegexIsMatch`, `SVF_RegexInstr` und
  `SVF_RegexCount`. Ein eigener Parser begrenzt den Toolbelt-Dialekt; Input,
  Pattern, Quantifier und Laufzeit besitzen feste Grenzen. Die identische
  .NET-Framework-4.8-Assembly läuft als `SAFE` SQL CLR ohne Drittanbieter-
  oder Native-Abhängigkeit und wird ausschließlich per exaktem SHA2-512-Hash
  autorisiert. Die vollständige physische Matrix SQL Server 2019/2022/2025
  unter Windows base und Linux latest ist erfolgreich; das Modul ist
  `validated` und `unreleased`. RE2-Parität, lineare Laufzeit, Replace,
  Substring, Captures, Split und Matches werden nicht zugesagt.

- `toolbelt.core.work-queue` Version `1.1.0` ergänzt den E1a-Kern um den
  ausdrücklich freigegebenen E1b-Slice: begrenzte Claim-Lease, monotone
  Generation, tokengebundener Heartbeat, explizite Batch-Recovery und
  aktive-Lease-Prüfung für Complete/Fail. Das echte Upgrade `1.0.0 → 1.1.0`
  erhält QUEUED-/terminale Daten und blockiert bei aktiven Alt-Claims vor der
  ersten Mutation. Der erste vollständige E1b-Lauf auf SQL Server 2025 Linux
  war erfolgreich; anschließend bestand die vollständige physische Matrix
  SQL Server 2019/2022/2025 unter Windows base und Linux latest. Das Modul ist
  `validated`. Retry/Dead Letter/Idempotenz, Cancellation und Worker
  bleiben getrennte Slices; das Modul bleibt `unreleased`.

- `toolbelt.datetime.date-spine` Version `1.0.0` mit drei portablen Inline
  TVFs für Tages-, ISO-Wochen- und Monatsperioden eines halboffenen
  `date`-Bereichs. Die vollständige Linux-Matrix auf SQL Server 2019, 2022 und
  2025 ist erfolgreich; Windows blieb wegen nicht erreichbarer SQL-
  Anmeldungs-Preflights `not executed`. Das Modul bleibt `unreleased`.

- Q1 Migration-Idempotency-Verifier für isolierte dependency-freie,
  zustandslose T-SQL-Module. V1 vergleicht den effektiven Katalog vor und nach
  einem Wiederholungsdeployment und prüft zwei unabhängige Uninstalls samt
  leerem Restzustand. Die physische SQL-Server-2019-/2022-/2025-Matrix ist auf
  Linux und Windows erfolgreich; alle synthetischen Testdatenbanken wurden
  anschließend entfernt.

- Windows-only Modul `toolbelt.filesystem.windows` mit EXTERNAL_ACCESS-SQL-CLR-Fassade für begrenztes Text-/Binary-I/O, explizite Codepages und Transcoding, Directory-Operationen und begrenztes rekursives Löschen. `Caller` ist der Default, `ServiceAccount` explizit; Build, Trust, Deployment, Help, SQL-Authentication-Ablehnung und kontrolliertes ServiceAccount-Schreiben sind validiert, die breitere Caller-/NTFS-/I/O-Matrix bleibt offen.

- `toolbelt.archive.zip-memory` ergänzt den ZIP-Metadaten-Pfad (TC-2026-033) im CLR-Provider inklusive Testhärtung für nicht-ASCII-Entry-Namen (`Grüße.txt` als Unicode-Konkatenausdruck). Version `1.2.0` stellt ihn über `USP_ListZipEntriesFromBinary` bereit; die vollständige Linux-SQL-Runtime-Matrix ist erfolgreich.

- W2c mit `toolbelt.core.console-message` für Unicode-sichere lange
  `PRINT`-/`RAISERROR ... WITH NOWAIT`-Messages und
  `toolbelt.metadata.capability-catalog` für eine read-only Projektion
  gültiger, unvollständiger oder ungültiger Database-level Modulmarker.
  Source, Lifecycle, Central-, Contract-, Dokumentations- und
  Runtime-Artefakte sind vorhanden. SQL Server 2025 Linux ist mit
  Compatibility Levels 150, 160 und 170 einschließlich Langtext-/Unicode-,
  Marker-/Drift-, Wiederholungs-, Lifecycle-, Central- und
  Uninstall-Contracts erfolgreich; beide Module sind `partially validated`.
- W2b-A mit `toolbelt.json.path-exists`: fehlerfreie SQL/JSON-Pfadprüfung
  für SQL Server 2019+ mit Root-, Property-, Array-Index-, Quote- und
  Wildcard-Semantik, gekoppelte Lifecycle-, Central-, Contract-,
  Dokumentations- und Runtime-Artefakte. SQL Server 2025 Linux ist mit
  Compatibility Levels 150, 160 und 170 einschließlich nativer Parität,
  Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich;
  Konstruktoren und JSON-Aggregate bleiben getrennt zurückgestellt.
- W2a mit typgetrennten Date/Time-Truncation- und Bucket-Inline-TVFs sowie
  Bigint-Shift-, Bit-Count-, Get-Bit- und Set-Bit-Funktionen. Die drei Module
  besitzen gekoppelte Lifecycle-, Central-, Contract-, Dokumentations- und
  Runtime-Artefakte. SQL Server 2025 Linux ist mit Compatibility Levels 150,
  160 und 170 einschließlich Wiederholungsdeployment, Lifecycle, Central und
  Uninstall erfolgreich; der Status ist `partially validated`.
- Sechs semantisch äquivalente inline-TVF-APIs für Base64, Integer-Base und
  Semantic Versioning als kanonische relationale Kerne für `CROSS APPLY` und
  `OUTER APPLY`; die vorhandenen SVFs bleiben Convenience-Wrapper.
- Kandidatenübergreifender Implementierungsplan für alle 46 Toolbelt-Kandidaten mit vorhandenen beziehungsweise vorgeschlagenen Modulen, öffentlichen Objektfamilien, Provider-Slices, Abhängigkeiten, Pflicht-Gates, Testschwerpunkten und Entwicklungswellen; ohne neue Implementierungsfreigabe.
- Formale Kandidaten `TC-2026-033` bis `TC-2026-046` für ZIP-/Kompressionsprovider, kontrollierte Datei-/Verzeichniszugriffe, getrennte Pseudonymisierungsbausteine, Objektklonen, XLSX-Lesen und eine providerneutrale Second-Session-Abstraktion; alle ohne Implementierungsfreigabe im Status `researched`.
- Deduplizierte Toolbelt-Research-Inbox mit 168 breit gefächerten Ideen und 92 öffentlichen Quellen; Mehrfachnennungen behalten ihre gemeinsamen Fundstellen; Funktionsideen aus dem Projektchat „SQL Server Toolbelt Planung“ zu Session Context, Sequence-Ranges, Schema-Introspektion, sicheren Dynamic-SQL-Primitiven, Resultset-Rendering und Temporal Queries sind nachgetragen.
- Repository-Grundaufbau mit autoritativen Steuerungsdateien, Architektur, Standards, Templates und Backlogs.
- Verbindlicher USP-Vertrag und SQL-Objekt-Namenskonventionen.
- GitHub-Copilot-Custom-Agent für die Backlog-Pflege.
- Erste evidence-basierte Backlog-Research-Welle mit den Kandidaten `TC-2026-001` bis `TC-2026-013`.
- Versionsbezogene Compatibility-Kandidaten für SQL Server 2019, 2022 und 2025 in den Bereichen Core, String, Datetime, JSON, Binary und Conversion.
- Implementierungsreife Spezifikation des ersten Kernmoduls `toolbelt.core.result-table`.
- Verbindliche ResultTable-Contract-Testmatrix für Help, Schema, `@KeepData`, DDL, Transaktionen, Collation, Deployment und Plattformen.
- Architekturentscheidungen `DEC-2026-013` bis `DEC-2026-017` für Modulscope, Schemaquelle, in-place-Umbau, Transaktionsvertrag und interne Temp-Namen.
- Folgearbeitspaket `AP-2026-003` für Implementierung und Validierung des ResultTable-Kernmoduls.
- Zweite Research-Welle mit den Execution-Infrastructure-Kandidaten `TC-2026-014` bis `TC-2026-022`.
- Kandidaten für transaktionsunabhängiges Logging, begrenzte Parallelisierung, Console-Ausgabe, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker-Leases und einen sicheren Work-Type-Katalog.
- Erstimplementierung von `toolbelt_core.USP_PrepareResultTable` mit Help-, Referenztabellen-, Typ-, Collation-, `@KeepData`-, Preflight-, in-place-DDL-, Debug-, Fehler- und Savepoint-Vertrag.
- Modulmanifest, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetisches Beispiel sowie statische und synthetische Contract-Testartefakte für `toolbelt.core.result-table`.
- Architekturentscheidung `DEC-2026-019` für gemeinsame Deployments, Release-Manifeste und kurze Mutationstransaktionen.
- GitHub-hosted Linux-Validierung für SQL Server 2019, 2022 und 2025.
- Manifestzentrierte Modulregistry mit gekoppelten Dokumentationspfaden und Contract-Versionen.
- Inkrementeller Dokumentations- und Change-Impact-Validator ohne externe Python-Abhängigkeiten.
- Eigener GitHub-Actions-Workflow für diff-basierte Dokumentationskonsistenz.
- Architekturentscheidung `DEC-2026-020` zur Status- und Change-Impact-Steuerung.
- Projektübergreifende Toolbelt-Landschaftsrecherche mit 16 direkten Libraries, Frameworks, Skriptkatalogen, Diagnose-, Maintenance- und Automationsprojekten.
- Prior-Art-Vergleich für zweite Sessions und Parallelisierungsprovider sowie Architekturfolgen für Packaging, Discovery, Versionierung, Tests, Lizenzierung, Security und Repository-Grenzen.
- Kandidaten `TC-2026-023` für einen abfragbaren Capability-/Versionskatalog und `TC-2026-024` für URI-Percent-Encoding/-Decoding.
- Quellenbasierte Vorprüfung der persönlichen Brainstorm-Themen Zahlensysteme, Kompression/Archive, Datei-/Verzeichniszugriff, Anonymisierung und Objektklonen.
- Kandidaten `TC-2026-025` bis `TC-2026-028` für kontrollierte PowerShell-Host-Automation, Python-Provider, versionsbezogene REST-/Web-Requests und getrennte KI-/Chat-Capabilities.
- ResultTable-Contract-Tests für explizite Collations, das 1024-Spalten-Limit, Caller-/uncommittable-Transaktionen und einen reproduzierbaren synthetischen Performance-Workload.
- Entscheidungsvorlage für das zweite Modul mit einem vertieften Vergleich von `TC-2026-004` und `TC-2026-012`, offenen Vertragsfragen, Provideroptionen, Testdimensionen und expliziten Implementierungs-Gates.
- ResultTable-Multi-Session-Contract für vier parallele Sitzungen mit identischen logischen Temp-Tabellennamen.
- Modul `toolbelt.conversion.base64` mit portablen Scalar UDFs für Base64- und Base64URL-Encoding/-Decoding.
- Parametergesteuertes lokales und zentrales Base64-Deployment, Uninstall, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Lifecycle- und Größenprüfungen.
- Serieller SQL-Server-2025-Linux-Workflow für Compatibility Levels 150, 160 und 170.
- Architekturentscheidung `DEC-2026-021` für scopebezogene Qualitäts-Gates unabhängiger Module.
- Erfolgreiche Base64-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich RFC-4648-, Fehler-, Größen-, Deployment- und Lifecycle-Contracts.
- Modul `toolbelt.core.generate-series` mit portablen Inline TVFs für `int`- und `bigint`-Zahlenreihen.
- Gemeinsamer `bigint`-Kern mit konstanten binär gestapelten Rowsets, zeilenzahlgesteuertem Row Goal und überlaufsicherer interner `decimal(38,0)`-Arithmetik.
- Parametergesteuertes lokales und zentrales Generate-Series-Deployment, Uninstall, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Lifecycle-, Grenz- und Größenprüfungen.
- Serieller SQL-Server-2025-Linux-Workflow für Generate-Series unter Compatibility Levels 150, 160 und 170.
- Erfolgreiche Generate-Series-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Semantik, nativer Parität, Fehlern, Grenzen, einer Million Werte, Row Goal, Join, `CROSS APPLY`, Deployment- und Lifecycle-Contracts.
- Formale Kandidaten `TC-2026-029` bis `TC-2026-031` für sicheres Identifier-Handling, Semantic Versioning und frei definierbare Zahlensysteme.
- Getrennte Split-Ausbaustufe `TC-2026-032` für mehrzeichige Separatoren, Escape und Quote.
- Modul `toolbelt.metadata.identifier` mit zustandsbasiertem Multipart-Parser und kanonischem Quote-Wrapper.
- Unterstützung für ein- bis vierteilige Namen, `[...]`, `]]`-Escapes, ausgelassene mittlere Teile und stabile abstrakte Validation Codes.
- Parametergesteuertes lokales und zentrales Identifier-Deployment, Uninstall, Objekt-/Moduldokumentation sowie statische, Contract-, Collation- und Lifecycle-Prüfungen.
- Modul `toolbelt.string.split-characters` mit literalem Multi-Separator-Vertrag, stabilen Ordinals und definierter Leer-Token-Semantik.
- Binärer Separatorvergleich, `nvarchar(max)`-Verarbeitung, Generate-Series-Dependency sowie lokales/zentrales Deployment und vollständige Lifecycle-Artefakte.

### Behoben

- Öffentliche Filesystem-Fassaden ordnen CLR-Providerfehler jetzt der jeweils
  angeforderten Operation zu. Die `file.content`-Reader liefern bei
  `OPENROWSET`-Enginefehlern Fehler `51326` mit vorangestelltem Kontext.
- Das Wiederholungsdeployment von `toolbelt.file.content` erhält die bestehende
  Root-Allowlist einschließlich ihrer Daten und aktualisiert ihre Beschreibung
  idempotent.
- `toolbelt.filesystem.windows` erkennt den `Caller`-Modus direkt über
  `SqlContext.WindowsIdentity` und hängt nicht mehr von der Sichtbarkeit
  serverweiter Login-Metadaten ab. Directory-Resultsets werden erst nach
  Beendigung der Windows-Impersonation an SQL Server zurückgegeben.
- Die internen CLR-Procedure-Bindings verwenden `CREATE OR ALTER`, sodass
  Assembly-Upgrades ohne Objektkollision wiederholbar ausgeführt werden.

### Geändert

- R1a dokumentiert und reproduziert die native SQL-Server-2025-RE2-Semantik
  für einen möglichen `LIKE`-/`INSTR`-/`COUNT`-Slice. Der Spike nimmt keine
  Dependency und keine Runtime-API auf: .NET Framework 4.8 ist semantisch
  nicht RE2-paritätisch, native RE2-Wrapper verletzen das portable
  `SAFE`-/Linux-Gate. Die Implementierung bleibt bis zur Richtungs- und
  Vertragsfreigabe gesperrt.

- W4a implementiert: `toolbelt.core.error-envelope` standardisiert explizite CATCH-Daten ohne Rethrow- oder Logging-Seiteneffekt.
- W4a implementiert: `toolbelt.core.execution-context` stellt Begin/Set/End, inline TVF und SVF-Wrapper über `SESSION_CONTEXT` bereit.
- Beide Module auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Lifecycle, Central und Sessionisolation validiert (https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948).

- ResultTable-Contract um einen natürlichen Enginefehler 2705 nach begonnener Mutation erweitert; Savepoint-Rollback von Schema, Daten und Caller-Transaktion auf SQL Server 2019/2022/2025 Linux validiert ([Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855)).
- Manuelle Windows-Runtime-Testpläne für ResultTable und ZIP Memory mit synthetischem Scope und abstrahierter Rückmeldung ergänzt.

- Modulregistry um das bereits vorhandene `toolbelt.file.content` ergänzt; Statusübersichten zeigen nun 19 implementierte, 18 teilweise validierte und ein nicht ausgeführtes Modul.
- Dokumentationsvalidator erkennt künftig jedes vorhandene, aber nicht registrierte `Modules/*/module.yaml` sowie veraltete Registry-Einträge.
- `toolbelt.file.content` im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 validiert und mit kanonischer Evidenz gekoppelt.
- ZIP-Backlog, Kandidaten, Implementierungsplan und Roadmap an die produktive CLR-Implementierung und die Linux-Matrix angepasst.
- Branchspezifischen Self-Mutation-Job aus dem ZIP-Workflow entfernt und Workflow-Berechtigung auf `contents: read` reduziert.
- Windows-Dateisystem-Arbeitspaket auf den tatsächlich verbleibenden manuellen Windows-SQL-Server-/NTFS-Runtime-Test reduziert.
- Welle `W1` implementiert: `TC-2026-002` als Calendar Difference,
  `TC-2026-008` als Directional TRIM Compatibility und `TC-2026-024` als
  RFC-3986-URI-Component-Percent-Encoding. Die drei Module besitzen
  eigenständige Lifecycle-Artefakte, Objektseiten und synthetische
  Contract-Tests. SQL Server 2025 Linux ist mit Compatibility Levels 150,
  160 und 170 einschließlich Wiederholungsdeployment, zentraler Nutzung und
  Uninstall erfolgreich; der Status ist `partially validated`.

- Base64, Integer-Base und Semantic Versioning auf Modulversion `1.1.0`
  angehoben; Deployment, Upgrade, Uninstall, Objektverträge, Beispiele,
  Manifeste und Testmatrizen um die inline-TVF-Alternativen erweitert.
- Inline-TVF-Remediation `AP-2026-014` nach erfolgreichen SQL-Server-2025-
  Linux-Läufen mit Compatibility Levels 150, 160 und 170 abgeschlossen.
- Datenschutz- und Vertraulichkeitsregeln präzisiert: fachlich relevante öffentliche Organisations-/Projektnamen und Links sowie `gecompat` und `Gerhard Pisch` sind zulässig; personenbezogene/sensible Daten, interne/vertrauliche Informationen, Original-Tabelleninhalte, reale Runtime-Ausgaben und konkrete Remote-Runner-Hardwarewerte bleiben ausgeschlossen.
- Bestehende Kandidaten zu Multi-Separator-Split und kalendarischer Differenz mit präziseren Versions-, Provider-, Performance- und Aussagegrenzen versehen.
- Roadmap um die abgeschlossene Research-Welle, die abgeschlossene ResultTable-Designphase und die geplante Implementierungswelle ergänzt.
- USP-Vertrag mit der kanonischen ResultTable-Runtime-Spezifikation und Testmatrix verknüpft.
- Repository-Map und Modulübersicht um das implementierungsreif geplante Kernmodul ergänzt.
- `@CreateStmt` für Version `1.0.0` zugunsten einer Referenztabelle zurückgestellt; die parsergestützte Capability bleibt als spätere Vertragsoption erhalten.
- Interne lokale Temp-Objekte verwenden den reservierten Präfix `#tbx_`; persistente Tabellenkonventionen bleiben offen.
- Implementierungs-Gate präzisiert: Ideen dürfen fortlaufend dokumentiert werden; jede konkrete Funktion benötigt vor der Implementierung eine Besprechung und anschließende ausdrückliche Benutzerfreigabe.
- `AP-2026-003` bis zur funktionsbezogenen Besprechung und Freigabe auf `blocked` gesetzt.
- `Backlog/personal_Backlog_Bainstorm.md` als verpflichtend zu berücksichtigenden, nicht autoritativen und historisch zu erhaltenden Research-Input in AI-Regeln, Repo-Map, Backlog-Prozess und Curator-Agent eingebunden.
- `AP-2026-003` nach ausdrücklicher funktionsbezogener Benutzerfreigabe auf `implemented` gesetzt; weitere Funktionen bleiben ohne eigene Freigabe blockiert.
- Anchor-Umbau am SQL-Server-Limit von 1024 Spalten in kontrollierte Teilschritte zerlegt.
- Getrennte Install-/Upgrade-Pfade durch ein gemeinsames `Deploy.sql` mit `DeploymentMode`, Release-Manifest, Application Lock und objektgenauer Herkunftsprüfung ersetzt.
- Source-Hashes von einem blockierenden Drift-Gate zu rein diagnostischer Information geändert.
- Modulstatus in getrennte Implementierungs-, Validierungs- und Release-Dimensionen aufgeteilt.
- README- und Modulübersichtsstatus als aus Manifesten erzeugte Abschnitte gekennzeichnet.
- ResultTable-Runtime-Workflow auf Source-, Deployment-, Manifest-, Runtime-Test- und CI-Adapteränderungen begrenzt.
- Execution-Infrastructure-Kandidaten um konkrete Prior Art aus tSQLt, SQL Server Multi Thread und der SQL Server Maintenance Solution ergänzt.
- Vorhandenen Base64-Kandidaten `TC-2026-012` anhand der nativen SQL-Server-2025-Semantik präzisiert.
- Toolbelt-Landschaftsrecherche auf den implementierten ResultTable-/Dokumentationsstand und die aktuellen SQL-Server-2025-REST-/AI-Funktionen konsolidiert.
- SQL Server 2022 und 2025 in der GitHub-hosted Linux-Matrix von der reduzierten Kompatibilitätsprüfung auf die vollständige ResultTable-Suite umgestellt.
- `TC-2026-012` als bevorzugten nächsten Besprechungskandidaten eingeordnet und `TC-2026-004` bis zur Grundsatzentscheidung über Typ-/Scale-Parität und Objektfamilie zurückgestellt; keine Implementierungsfreigabe erteilt.
- Vier parallele ResultTable-Sitzungen mit identischen logischen lokalen Temp-Tabellennamen auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich validiert; invasiven DDL-Trigger-Harness als ungeeignete Recovery-Evidenz verworfen.
- Das pauschale Phase-2-Gate eines vollständig validierten, fachlich unabhängigen Referenzmoduls durch ein scopebezogenes Gate ersetzt; konkrete Modulverträge, Eigenvalidierung und tatsächlich verwendete gemeinsame Infrastruktur bleiben verpflichtend.
- `TC-2026-012` nach Benutzerfreigabe vom Research-Kandidaten zum implementierten und auf SQL Server 2025 Linux teilweise validierten Modul überführt.
- `TC-2026-006` nach Benutzerfreigabe vom Research-Kandidaten zum implementierten und auf SQL Server 2025 Linux teilweise validierten Modul überführt.
- Veralteten Backlogstatus des bereits gemergten Base64-Arbeitspakets von `active` auf `completed` korrigiert.
- `TC-2026-001`, `TC-2026-030` und `TC-2026-031` nach gemeinsamer Vertragsbesprechung und ausdrücklicher Freigabe vom 2026-07-30 auf `ready for development` gesetzt; Arbeitspakete `AP-2026-011` bis `AP-2026-013` angelegt.
- `TC-2026-029` aus `RI-2026-011` als `AP-2026-010` implementiert und auf SQL Server 2025 Linux teilweise validiert.
- Identifier-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parser-, Quote-, Escape-, Omission-, Längen-, Fehler-, Deployment- und Lifecycle-Contracts erfolgreich.
- `TC-2026-001` als `AP-2026-011` implementiert; die breitere Split-Version mit Separatorstrings beliebiger Länge, frei definierbaren Quote-Zeichen und Escape bleibt getrennt als `TC-2026-032` im Research-Status.
- Split-Characters-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Literal-, Leer-Token-, NULL-/NUL-, Collation-, LOB-, Dependency-, zentraler und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.
- Modul `toolbelt.validation.semantic-version` mit striktem SemVer-2.0.0-Parser, Comparator und binärem Sort Key ohne numerischen Overflow.
- Semantic-Version-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parser-, Präzedenz-, Sort-Key-, Größen-, Deployment- und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.
- Modul `toolbelt.conversion.integer-base` mit kanonischer Codierung und strikter Decodierung des vollständigen `bigint`-Bereichs für frei definierbare ASCII-Alphabete der Basen 2 bis 93.
- Integer-Base-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Alphabet-, Kanonizitäts-, Grenzwert-, Overflow-, Deployment- und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.

### Korrigiert

- Bucket-SQL-Alias und Optimizer-Expansion korrigiert. Die drei öffentlichen
  Verträge bleiben Inline TVFs; ein interner einzeiliger Core verhindert den
  in der Runtime nachgewiesenen SQL-Server-Fehler `8632`.
- Modulzahl, Modulübersichten, Testinventar, Roadmap, Backlog, Research-Fokus
  und den kandidatenübergreifenden Implementierungsplan auf die tatsächlich
  vorhandenen 10 Module synchronisiert.
- W1-Evidenz in Manifesten und gekoppelter Dokumentation auf den finalen
  erfolgreichen Runtime-Lauf `30553118399` sowie den finalen
  Dokumentationslauf `30553118014` vereinheitlicht.
- Abgeschlossene Arbeitspakete aus dem aktiven Backlogabschnitt entfernt und
  den noch aktiven ResultTable-Validierungsscope getrennt ausgewiesen.
- W2a mit `TC-2026-004`, `TC-2026-005` und `TC-2026-007` nach
  funktionsbezogener Freigabe implementiert; offene JSON-Oberflächen bleiben
  getrennt in `W2b`.
- Dokumentationsvalidator um manifestbasierte Prüfungen für Modulzahl,
  README-/Testinventar, implementierte Kandidaten und Research-Inbox-Status
  erweitert; W1-Runtime-Trigger auf Runtime- und Manifestpfade begrenzt.
- Kandidatenstatus und nächste Schritte von `TC-2026-003`, `TC-2026-006`, `TC-2026-012` und `TC-2026-029` an den nachweisbaren Implementierungs- und Validierungsstand angeglichen.
- Custom-Agent-Profil auf gültige `.agent.md`-Struktur mit YAML-Frontmatter umgestellt.
- Generische Objektvorlagen durch objekttypspezifische USP-, TVF-, SVF- und View-Vorlagen ersetzt.
- USP-Vertrag und Teststandard um vollständige `@ResultTable`- und `@KeepData`-Contract-Tests ergänzt.
- SQL Server 2025 in Support-, Manifest- und Testmatrizen aufgenommen.
- CLR-Linux-Grenzen und `TRUSTWORTHY`-Ausnahmeregel präzisiert.
- Statusangaben nach dem initialen Merge aktualisiert.
- Entscheidungsprotokoll, Contribution-Regel und technische Identifier-Sprache konsolidiert.
- Bereits in `SQL_Server_Analyze` vorhandenen Unused-Index-Kandidaten aus dem offenen Analyze-Backlog entfernt.
- Identische Ziel- und Referenz-Temp-Tabelle wird vor jeder Mutation mit `51022` abgelehnt.
- Engine-Fehler beim Metadatenzugriff und bei `TRUNCATE` bleiben unverändert; der unzulässige `DELETE`-Fallback wurde entfernt.
- Debug-Stufen `4` bis `254` liefern für `USP_PrepareResultTable` denselben Detailumfang wie Stufe `3`.
- Deployment-Sessionoption und Objektartvergleich für XML- und Collation-stabile Ausführung korrigiert.
- Runtime-Testmetadaten für `datetime2(3)` und CI-Kollisionsvorbereitung korrigiert.
- Veraltete Runtime-Statusangaben in README, SECURITY und USP-Vertrag korrigiert.
- ResultTable-Evidenz auf den finalen erfolgreichen Linux-Workflow aktualisiert.

### Status

44 Module sind implementiert. 19 sind `validated`, 25 sind `partially validated`; 0 sind `not executed`. Die verbindliche, je Modul und Plattform getrennte Evidenz
steht in den Manifesten. Offene Windows- und modulspezifische Releasefälle
werden nicht aus Linux- oder Compatibility-Level-Läufen abgeleitet.

## 2026-10-04 – Table Clone Executor / 3.1.0

- Neuer expliziter `USP_ExecuteTableClone`: frischer kanonischer Plan,
  erwarteter Bytehash, ausschließlich neue SameDB-Ziele und eigene Transaktion.
  CREATE/DEFER bindet den vollständigen Plan; keine Daten- oder Triggerkopie.
- Vorhandene DB-/Servervollsicht und DDL-Seiteneffektgate, gekoppelte
  Deployment-/Uninstall-, Help-, ResultTable- und Client-Hashverträge.
- Gezielte lokale Nachweise auf SQL Server 2019 Linux/latest CL150 und
  2025 Windows/exakt CU8 CL170 bestanden, einschließlich genuine3→3.1,
  Caller-TX/SET, Fehlerrollback, Clientmetadata und eigener Bereinigung.
  Head-CI ist separat im Pull Request nachzuweisen; Modul weiterhin teilweise validiert und unveröffentlicht.

## 2026-10-04 – Table Clone W2 / V3 Source

- Vorhandene öffentliche/interne Prozedur mit TableMap an7 und ExternalReferenceRule an8; Standardtail9..12. Gemeinsamer W1-Renderer, Map-Snapshot, globale Reihenfolge, FK-Umleitung/KEEP, begrenzte Flags und FK-EP-Failclosed. Kein Execute-Wrapper, Provider oder Rechteänderung.
- Separate64Maps/1024Columns/128Indexes, exakt2048Childobjekte-plus-FK-Spaltentupel und globale2MiB. Begrenzte lokale W2-Native-/Upgrade-/Lifecycle-Nachweise auf Linux2019/latest CL150 und Windows2025/exakt CU8 CL170 bestanden mit frischer eigener Bereinigung. Linux-Fixtures sind wiederverwendeter Teilnachweis eines historischen Fehllaufs; Windows-Fixtures bestanden im aktuellen Clean3. Unresolved nicht etabliert, vollständige Qualifikation und aktuelle Head-CI offen; historische W1-Evidenz bleibt getrennt.
