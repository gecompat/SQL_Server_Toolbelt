# Tests – SQL Server Toolbelt

## Aktueller markerfreier Installationsstand

Aktuelle Installation und Paketierung werden durch `Scripts/Install/Tests`,
`Deployment/Tests/Test-MarkerlessPackage.ps1` und
`Deployment/Tests/Test-CurrentInstall.ps1` geprüft. Komponenten-Staticprüfungen
vergleichen zuerst die aktuellen Fachquellen mit dem ursprünglichen Stand;
anschließend bleiben die originalen Lifecycleassertions am festen Vorgänger
`2fbe8e3e` erhalten. Ein Fachunterschied verwirft die Wiederverwendung.

Die nativen CI-Jobs für Deploy/Upgrade/Uninstall des abgelösten SQLCMD-/Marker-
Lifecycle laufen ausschließlich bei ausdrücklichem workflow_dispatch am festen
Originalcommit. Automatische PR-/Main-Prüfungen behalten Komponenten-Gates;
passende reine Framework-/Buildprüfungen laufen weiter an aktuellen Quellen.
Die neuen Installer-/Paketprüfungen bleiben separate aktuelle Gates. Es wird
keine historische native Matrix als Abnahme der neuen Deploymentbytes ausgegeben.
Ein neuer Fachvertrag benötigt neue passende Runtimeadapter und Nachweise;
der Äquivalenzguard blockiert ein stilles Weiterverwenden alter Belege.



Der [aktuelle Nachweisabgleich](../Releases/1.0.0/CURRENT-QUALIFICATION-REST.md) trennt geschlossene Teilumfänge, notwendige Vertragslücken und zusätzliche Untersuchungen ohne Ausführungsauftrag. Die [XLSX-Testübersicht](../Modules/toolbelt.file.xlsx-memory/Tests/README.md) führt ihre aktuellen einzelnen Quellenbindungen zusammen. Spätere gültige Belege haben Vorrang vor pauschalen historischen Offen-Zeilen; daraus folgt kein Gesamtmodul-PASS.

Die [aktuelle direkte Vorgängermatrix](../Releases/1.0.0/TABLE-CLONE-KNOWN-PREDECESSORS-QUALIFICATION.md)
belegt fünf echte öffentliche Versionen 2.0.0/3.0.0/3.1.0/4.0.0/4.1.0
gegen 4.1.1 auf 24 lokalen/direkt zentralen Windows-/Linux-SQL-Kontexten:
360 eindeutige Uninstall-/Upgrade-Rollback-/Direktupgradeprofile, zwölf
vollständige Läufe und zwölf frische Audits. Alle 24 eigenen DBs entfernt;
keine Fehler, Wiederholung grüner Profile, Produkt- oder Rechteänderung.
Ältere pauschale Offenangaben zu diesen direkten Vorgängerpfaden sind damit
erledigt; historische Teilnachweise und übrige Modulpflichten bleiben getrennt.

Die [aktuelle Planner-Fünfrechtematrix](../Releases/1.0.0/TABLE-CLONE-PLANNER-RIGHTS-QUALIFICATION.md)
besteht auf 24 lokalen/direkt zentralen Windows-/Linux-SQL-Kontexten:
24 vollständige Originalfixtures mit gebundener interner Direktaufrufverweigerung
und zwölf frische Audits. Alle 24 temporären Benutzer und eigenen DBs entfernt;
keine Rechte außerhalb dieser eigenen DBs. Der gezielte Planner-Sichtbarkeits-
und Aufrufketten-Scope ist geschlossen; Executor-/Copy-/Trigger-Rechte sowie
andere Clients/Identitäten und Modulgesamtpflichten bleiben getrennt.

Die [aktuelle genuine V1-Lifecycle-Profilmatrix](../Releases/1.0.0/TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md)
belegt 240 eindeutige Profile auf 24 lokalen/direkt zentralen Windows-/Linux-
Kontexten: elf vollständige Fälle und ein Fall mit vier gebunden wiederverwendeten
Profilen plus bestandenem Restumfang. Beide ursprünglichen Koordinatoren bleiben
fehlgeschlagen. Alle 26 eigenen DBs entfernt, 14 frische Audits bestanden;
keine Rechte-/Produkt-SQL-/Server-/Labänderung. V1-Upgrade, aktuelles Uninstall,
Repeat und die drei gezielten Rollbackprofile sind damit belegt. Andere genuine
Zwischenversionen und übrige Modulpflichten bleiben getrennt.

Der [vollständige SQLCMD-Caller-Abbruch vom 2026-11-07](../Releases/1.0.0/TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md)
besteht auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte, 96 vollständige Deploy-/Uninstall-Profile mit XACT_ABORT OFF/ON.
Einschließlich erhaltenem Erstfehler bestätigen 13 frische Audits die Entfernung
aller 25 angelegten eigenen DBs. Die geänderte Kindprozess-Isolation behebt
nur den Testadapter; Produkt-SQL, Rechte und Serverzustand bleiben unverändert.
Die früher pauschal offenen vollständigen SQLCMD-Caller-Includes sind damit
geschlossen. Linux-Clienthost und genuine Upgrade-/Uninstall-/Recoveryfälle
bleiben separat; ältere datierte Teilnachweise behalten ihren ursprünglichen Scope.

Dieses Verzeichnis enthält die gemeinsame Test-Infrastruktur und Testdokumentation.

## Begrenzte Dokumentationsabnahme

`Documentation/validate_documentation.py` führt die Releaseprüfungen über
[`run_release_validation.py`](Documentation/run_release_validation.py) aus.
Dieser Einstieg führt jeden unterschiedlichen Release-Test aus. Ausschließlich
die bekannte doppelte Registrierung derselben CSV-Metadatenklasse wird
zusammengeführt; andere oder dreifache Registrierungen scheitern zur Klärung.
Subtests, negative Kontrollen und unabhängige Pflichtwiederholungen bleiben
erhalten. Die Originale historisch gebundener Prüfer bleiben archiviert. Die heutige
Suite trennt Originalquellenintegrität und aktuelle Anwendbarkeit; siehe
[Release-Quellenbindungen](Release/README.md#historische-quellen-und-aktuelle-qualifikation).

Der Runner meldet vor jedem Test eine Fortschrittsmarke. Bei einem Timeout
beendet der Validator den Lauf als Fehler und zeigt Skript, ursprüngliche
Zeitgrenze, zuletzt gestarteten Test und begrenzte Ausgabeteile. Auch ein
bereits gestarteter, aber nicht abgeschlossener Test gilt nicht als bestanden.
Die vollständige Releasesuite hat lokal und in CI ein Limit von 20 Minuten;
die bisherige Elf-Minuten-Grenze reichte für erfolgreiche lokale Läufe nicht
mehr aus. Der umschließende Dokumentations-CI-Job ist auf 35 Minuten begrenzt,
damit nach der Suite auch die Kandidatenprüfungen (zwei Minuten), die
Paketintegritätsprüfung (sechs Minuten) und die übrigen Konsistenzprüfungen
Platz haben. Deren eigene Grenzen und das Unterdrücken von
Windows-Konsolenfenstern bleiben erhalten. Die Paketgrenze erhält nach einem belegten Timeout und einem erfolgreichen
Einzellauf nahe der alten Vier-Minuten-Grenze zwei Minuten Reserve; Assertions,
innere Prozessgrenzen und Testumfang bleiben erhalten. Kein neuer Job und
keine neue native Testwelle entstehen. Die Grenzen sind Abbruchschranken,
keine garantierten Laufzeiten. Reproduzierbare Gegenproben:

```powershell
python Tests/Documentation/test_validation_execution.py
```

Die [CSV-/Phonetic-Framework-Paketprofile](../Releases/1.0.0/CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md)
verknüpfen zwei vorhandene CLR-Harnesses mit den ausgelieferten DLL-Bytes.
Es handelt sich um begrenzte Offlinebelege ohne SQL-Ausführung oder Änderung
des Modulstatus.

Die [workflowübergreifende Impact-Prüfung](CI/CHANGE_IMPACT_REVIEW_2026-10-19.md)
beschreibt die tatsächlichen Consumer-Trigger, den deterministischen lokalen
Cleanup-Test und die Grenzen einer späteren Local-to-Remote-Wiederverwendung.

Die Offline-Prüfung des repositoryweiten SQL-Exports liegt unter
[`Deployment/Tests/Test-SqlExport.ps1`](../Deployment/Tests/Test-SqlExport.ps1).
Sie prüft die aktuelle vollständige Modulclosure, Dependency-Auswahl, rekursive
Includes, Eingaben, deterministische Dateierzeugung und Fehler ohne SQL-Zugriff.
Der Documentation-Workflow führt sie bei betroffenen Deployment-/Source-/
Manifeständerungen aus. Dies ist kein Nachweis für Datenmigrationen oder
gemeinsame SQL-Laufzeitkompatibilität; siehe
[Deployment-Grenzen](../Deployment/README.md#datenerhaltung-und-derzeitige-grenzen).

## Aktueller Stand

Der manuelle [SQLGlot-Research-Spike](Research/SqlDialect/README.md) prüft
synthetische T-SQL-/Databricks-Parser-/Generatorfälle mit gepinntem lokalem
Python-Paket. Der ergänzte native Lab-Runner hat 81 feste Fälle auf sechs
SQL-Server-Labzielen erfolgreich geprüft: Ergebnisse, NULL-Verhalten und
Clientdatentypen, insgesamt 486 Fallausführungen. Die drei COUNT-/ROW_NUMBER-
Roundtrip-Lücken sind behoben. Kein Toolbelt-Modul installiert; Databricks- und authentifizierte
TLS-Qualifikation bleiben getrennt offen. Performance ist wie unten beschrieben
teilweise qualifiziert.
Die [native Databricks-Prüfung](../Documentation/Research/SQLGLOT_NATIVE_DATABRICKS_PROBE.md)
bleibt wegen des aktuell fehlenden Zugangs auf Benutzerauftrag vom 2026-10-17
`not executed`. Es wird keine zusätzliche Infrastruktur eingerichtet.
Der ergänzende [lokale Spark-SQL-Lauf](../Documentation/Research/SQLGLOT_NATIVE_SPARK_PROBE.md)
bestand am 2026-10-17 auf Apache Spark 4.0.2 mit 57 positiven und neun
negativen Fällen. Gleiche synthetische Daten und Abfragen, Ergebnisparität
mit den gebundenen SQL-Server-Nachweisen; kein Databricks-Nachweis daraus.
Die portable Testlaufzeit liegt nur unter `.runtime/`, ohne Cloud-/Labänderung.
Die [anschließende Performance-/Planprüfung](../Documentation/Research/SQL_DIALECT_PERFORMANCE_PROBE.md)
bestand mit 34 SQL-Server- und 20 Spark-Ergebnis-/Planfällen auf größeren
synthetischen Mengen. 18 Zeitserien erfüllen das Stabilitätsgate, 36 bleiben
für Zeitvergleiche `not executed`; Performance insgesamt `partially validated`.
Messwerte und Rohpläne bleiben ausschließlich lokal unter `.runtime/`.

Der Repository-Grundaufbau ist abgeschlossen. 45 Module sind implementiert;
17 sind `validated`, 28 sind `partially validated`, 0 sind `not executed`. Für alle existieren
statische sowie synthetische Runtime- und Lifecycle-Contract-Testartefakte.

Die ResultTable-Runtime-Action auf GitHub-hosted Linux war am 2026-07-29 mit
der vollständigen Suite für SQL Server 2019, 2022 und 2025 erfolgreich.
Die Base64- und Generate-Series-Runtime-Workflows für SQL Server 2025 und
Compatibility Levels 150, 160 und 170 waren erfolgreich.

Die vollständige lokale Matrix `local: Tests/CI/run-lab-local.ps1` war am
2026-09-01 für alle automatisierten Adapter auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich. Neben
lokalem und zentralem Deployment, Lifecycle und Uninstall umfasst sie die
modulspezifischen Kollisions-, Collation-, Transaktions-, Konkurrenz-,
Metadatensichtbarkeits- und Skalierungsfälle. Die sieben weiterhin nur
teilvalidierten Module haben getrennt dokumentierte Performance-,
Client-/Treiber-, Fixture-, Interoperabilitäts- oder manuelle Sicherheitsgates.

Die E1b Work Queue ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich. Der vollständige
Scope umfasst Lease, Heartbeat, explizite Recovery, Token-Invaliderung, den
echten Upgradepfad `1.0.0 → 1.1.0`, Parallelität und Lifecycle. Das Modul ist
`validated` und `unreleased`.

Der R1a-Research-Slice unter [`Research/Regex`](./Research/Regex/README.md)
vergleicht die native SQL-Server-2025-RE2-Semantik reproduzierbar mit .NET
Framework 4.8. Er erzeugt kein Modul und keine öffentliche Runtime-API. Die
native Linux-2025-Matrix unter Compatibility 150/160/170 und der lokale
.NET-Framework-Harness sind erfolgreich; Windows-SQL-Runtime ist
`not executed`.

Das daraus getrennt freigegebene R1b-Modul `toolbelt.string.regex` ist mit
seinem begrenzten Dialekt, SAFE-CLR-/SHA2-512-Vertrag, Grenzen, Timeout,
Fehlerpräfixen und Lifecycle auf physischen SQL-Server-2019-/2022-/2025-
Zielen unter Windows base und Linux latest erfolgreich. Dieser historische
R1b-Nachweis ist vom aktuellen R2b-Stand 1.2.0 zu trennen: risikobasiert auf
2019 Linux und 2025 Windows/CU8 geprüft, `partially validated`, `unreleased`.

Die W2c-Module sind dort einschließlich Langtext-/Unicode-, Marker-/Drift-,
Wiederholungsdeployment, Lifecycle, Central und Uninstall ebenfalls
erfolgreich.
Das Modul `toolbelt.file.content` ist auf SQL Server 2025 Linux mit
Compatibility Levels 150, 160 und 170 einschließlich synthetischer
Text-/Binary-Fixtures, Allowlist, Lifecycle und Uninstall erfolgreich.

## Pflicht-Testarten je Modul

| Testtyp | Inhalt |
|---|---|
| statisch | Naming, Header, Datenschutz, Manifest, Links und Vertragskonsistenz |
| API-Contract | Parameter, Defaults, Resultsets, Help, Fehler und Rechte |
| USP-Contract | `@Hilfe`, `@Debug`, `@ResultTable`, `@KeepData`, verschachtelte Aufrufe |
| Deploy | Erstinstallation, kontrollierte Wiederholung und jede unterstützte Vorgängerversion |
| Uninstall | vollständige Entfernung und Dependency-Schutz |
| Collation | unterschiedliche Server-, Datenbank- und TempDB-Collations |
| Deployment | lokal, zentral und Cross-database, soweit unterstützt |
| Plattform | SQL Server 2019, 2022 und 2025; Windows und Linux getrennt |
| Provider | jeder alternative Provider als eigener Nachweis |
| Recovery | Cleanup und Zustand nach Fehlern |
| Dokumentationskonsistenz | diff-basierte Prüfung registrierter Status-, Link- und Kopplungsartefakte |

## Modulspezifische Testmatrizen

Die Tabelle ist das vorhandene modulbezogene Verzeichnis der ausdrücklich
benannten Restschritte. Der Text nach dem Status nennt jeweils den nächsten
belegten Schritt oder die dafür fehlende Voraussetzung; typische Gruppen sind
weitere zugesagte Ziele/CLs, Rechte und Identität, Lifecycle/Upgrade,
Datei-/Client-/Hostverhalten sowie Last und Recovery. Diese Gruppen erzeugen
keine zusätzlichen Kombinationen: maßgeblich sind die Supportdeklaration und
die jeweilige kanonische Modulmatrix. Ein als `validated` markierter Eintrag
deckt seinen beschriebenen Scope ab. Wenn für eine darüber hinausgehende
Abnahme hier kein Restschritt benannt ist, gilt: im Inventar nicht benannt;
vor weiterer Abnahme die kanonische Matrix und den zugesagten Umfang prüfen.
Nicht qualifizierter Umfang ist nicht automatisch eine Veröffentlichungspflicht.

Die verlinkten späteren Berichte korrigieren alte pauschale Offen-Aussagen,
behalten aber ihre ursprünglichen Quellen-, DLL- und Ausführungspins. Eine
Metadatenpflege oder ein späterer Kandidat ist keine neue native Ausführung.
Die Tabelle ersetzt weder diese Bindungsprüfung noch den Manifeststatus.
Vor der nächsten Testwelle sind Supportumfang, Pflichtfall, feste Ergebnisorakel
und Voraussetzungen abzugleichen. Die Übersicht erweitert keine bestehenden
Funktionsfreigaben; optionale Messungen bleiben von Pflichtfällen getrennt.

Die neue JSON-Welle besitzt einen gemeinsamen Offline- und nativen Labdriver.
Ihre Teilnachweise sind getrennt von historischen Constructorständen dokumentiert.

| Modul | Matrix | Status | Nächster belegter Schritt / Voraussetzung |
|---|---|---|
| `toolbelt.json.core` | [TEST_MATRIX.md](../Modules/toolbelt.json.core/Tests/TEST_MATRIX.md) | `partially validated`; historische Core-/Consumer-Lifecycles bleiben getrennt. [Neue physische Ergänzung](../Releases/1.0.0/JSON-SCHEMA-MISSING-TARGETS-QUALIFICATION.md): acht Windows-/Linux-Ziel-/CL-Paare,16 lokale/direkt zentrale Schema-Consumer-Kontexte, Core-Erhalt/Uninstall und acht frische Audits | Die [direkte Core-Sperrmatrix](../Releases/1.0.0/JSON-CORE-APPLOCK-QUALIFICATION.md) schließt Deploy/Uninstall unter gemeinsamer exklusiver Sitzungssperre und nach Freigabe auf 24 Kontexten mit 96 Profilen; Erstfehler und 13 frische Audits bleiben erhalten. Die [fünf direkten Core-Grenzen](../Releases/1.0.0/JSON-CORE-FIVE-BOUNDARIES-QUALIFICATION.md) sind auf zwölf Paaren lokal/zentral belegt: 876 eindeutige Profile und 14 frische Audits; zwei Fehler bleiben erhalten, 28 Originalprofile gezielt wiederverwendet. Weitere Owner-/Drift-/übrige Lock-/Migrations- und Ressourcenfälle konkretisieren; keine volle Modulqualifikation aus den Consumer-Teilnachweisen. |
| `toolbelt.json.schema` | [TEST_MATRIX.md](../Modules/toolbelt.json.schema/Tests/TEST_MATRIX.md) | `partially validated`; [neue physische Ergänzung](../Releases/1.0.0/JSON-SCHEMA-MISSING-TARGETS-QUALIFICATION.md) mit16 Contract-/Safety-/direkten Clientmetadatenkontexten und ausgewähltem Repeat-/Consumer-/Uninstallscope. Das [Datenpfad-Callerprofil](../Releases/1.0.0/JSON-SCHEMA-CALLER-PROFILE.md) auf zwölf Ziel-/CL-Paaren und die [Manifest-/Paketbindung](../Releases/1.0.0/CALLER-METADATA-UPDATE.md) sind bereits abgeschlossen | Nicht erneut die grünen Drei-Objektrechte-Fälle prüfen. Offen: übrige Lifecycle-/Owner-/Drift-/Lock-/Kollisions-/Sessionprofile, tatsächliche CrossDB-Identitäten und zugesagte Ressourcenfälle. Die [Sessionergänzung](../Releases/1.0.0/JSON-SCHEMA-XACT-ABORT-QUALIFICATION.md) belegt vier frühe Caller-Guardfälle mit XACT_ABORT ON/NOCOUNT OFF oder ON bei fehlenden Modulen, einen frischen Audit und eigene DB-Entfernung. Frühere einzelne Caller-/Lock-/Confirmfälle und neue ON-Fälle behalten ihren engen Scope; keine vollständige Sessionmatrix. Die [OFF/ON-Ergänzung](../Releases/1.0.0/JSON-SCHEMA-NOCOUNT-QUALIFICATION.md) belegt zusätzlich Deploy/Uninstall mit XACT_ABORT OFF und NOCOUNT ON bei fehlenden Modulen samt frischem Audit; Die [installierten Uninstall-Profile](../Releases/1.0.0/JSON-SCHEMA-INSTALLED-SESSION-QUALIFICATION.md) schließen zusätzlich OFF/ON,ON/OFF,ON/ON auf Windows2025/CU8 CL170 lokal mit aktuellem Core/Schema und frischem Audit; weitere Ziele/SET-/Lifecyclefälle bleiben getrennt. |
| `toolbelt.json.pointer` | [JSON_POINTER_TEST_MATRIX.md](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md) | `partially validated`; [physische Volladapter](../Modules/toolbelt.json.pointer/Tests/QUALIFICATION_2026-10-19.md) bleiben gebunden. [Kleine Securityfixture](../Releases/1.0.0/JSON-POINTER-SECURITY-QUALIFICATION.md): 18 neue und sechs wiederverwendete Kontexte, zwölf frische Audits, 18 eigene DBs entfernt. [Direkte SELECT-Callerrechte](../Releases/1.0.0/POINTER-CALLER-QUALIFICATION.md) mit 24 positiven Profilen/72 SQL229-Abweisungen separat belegt | Keine pauschal offene kleine Security- oder direkte Datenpfad-Rechteprüfung. Lifecycle-DDL-Rechte, echte Lowpriv-CrossDB-Identitäten, übrige zugesagte Ressourcen-/Heap-/Parallelitäts-/Recovery- und getrennte Releasegates bleiben offen. |
| `toolbelt.conversion.safe-cast` | [SAFE_CAST_TEST_MATRIX.md](../Modules/toolbelt.conversion.safe-cast/Tests/SAFE_CAST_TEST_MATRIX.md) | `partially validated`; zwölf physische API-/Metadaten-/Lifecycleadapter laut [Scopebericht](../Modules/toolbelt.conversion.safe-cast/Tests/QUALIFICATION_2026-10-19.md). Das spätere [Callerprofil](../Releases/1.0.0/SAFE-CAST-RIGHTS-QUALIFICATION.md) belegt alle sechs öffentlichen TVFs mit einzelnem SELECT auf zwölf Ziel-/CL-Paaren lokal/direkt zentral | Kein pauschal fehlendes Datenpfad-Minimalrechte- oder physisches APIgate. Tatsächliche CrossDB-Identitäten, Lifecycle-DDL-Rechte, Heap-/Konkurrenz-/Recovery- und übrige ausdrücklich zugesagte Restprofile bleiben getrennt. |
| `toolbelt.string.text-pairs` | [TEXT_PAIRS_TEST_MATRIX.md](../Modules/toolbelt.string.text-pairs/Tests/TEXT_PAIRS_TEST_MATRIX.md) | `partially validated`; die fünf frühen Funktionsfixtures und zentrale Client-/Lifecyclefälle bleiben eigene Teilnachweise. [Callerprofil](../Releases/1.0.0/TEXT-PAIRS-CALLER-QUALIFICATION.md): öffentliche Batch-USP mit einzelnem EXECUTE auf zwölf Ziel-/CL-Paaren lokal/direkt zentral, drei Algorithmen und feste direkte/ResultTable-Ausgaben | Die USP-Datenpfad-Minimalrechte nicht erneut als unbelegt führen. Die drei gesperrten Vergleichs-TVFs gehören zur separaten Edit-Distance-Abhängigkeit; übrige Funktions-/Client-/Lifecycle-/Ressourcen- und echte CrossDB-Gates behalten ihren eigenen Scope. |
| `toolbelt.file.csv-memory` | [CSV_TEST_MATRIX.md](../Modules/toolbelt.file.csv-memory/Tests/CSV_TEST_MATRIX.md) | `partially validated`; vorhandene fachliche und Lifecycle-Teilnachweise. [Parser-/Writer-/ResultTable-Callerprofile](../Releases/1.0.0/CSV-CALLER-PROFILE.md) auf zwölf Windows-/Linux-Ziel-/CL-Paaren sowie [Manifest-/Paketbindung](../Releases/1.0.0/CSV-METADATA-UPDATE.md) sind belegt | Keine Wiederholung dieser Rechteprofile. Noch fehlende physische Vollfixtures, Fremdslot-/Drift-/Lifecycle-/Heapprofile und echte CrossDB-Identitäten konkretisieren; Callerprofile sind keine gesamte Funktionsmatrix. |
| `toolbelt.file.xlsx-memory` | [XLSX_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md) | `partially validated`; [Raw-Caller](../Releases/1.0.0/XLSX-RAW-CALLER-PROFILE.md), [Zell-Caller](../Releases/1.0.0/XLSX-CELL-CALLER-QUALIFICATION.md) und [Metadaten-/Paketpflege](../Releases/1.0.0/XLSX-METADATA-UPDATE.md) bleiben an ihre Originale gebunden. [32/33-Blattgrenze](../Releases/1.0.0/XLSX-BOUNDARY-QUALIFICATION.md) bestanden; [SST50000/50001](../Releases/1.0.0/XLSX-SST-BUDGET-CORRECTION.md) auf separat gebundenem Quellkandidaten bestanden | Kein pauschal fehlender Caller- oder SST-Nachweis. Vor einem aktuellen Gesamtstatus SQL-/DLL-/Overlaybindungen zusammenführen; ältere Callerfälle nicht als neue Prüfung einer späteren DLL ausgeben. Andere Ausgabe-/XML-/Archiv-/Heap-/Lifecycle- und Identitätsprofile bleiben separat. |
| `toolbelt.archive.zip-files` | [ZIP-Testmatrix](../Modules/toolbelt.archive.zip-files/Tests/ZIP_FILES_TEST_MATRIX.md) | `validated`. Sechs native Windows-/CL-Kontexte und gebundene Spezialfälle für Windows/local. | Aktuelle Nachweise in der Testmatrix. Der historische Marker-Lifecycle ist separat dokumentiert. |
| `toolbelt.archive.zip-memory` | [Aktuelle portable ZIP-Memory-Matrix](../Modules/toolbelt.archive.zip-memory/Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md#aktueller-portabler-build) | `validated`; Windows-Lab und Linux-CI, 2019 CL150, 2022 CL150/160, 2025 CL150/160/170, jeweils lokal und zentral. Reader- und Writer-Grenzfälle auf zwei repräsentativen Plattformkontexten. | Unveränderte [Entryanzahl](../Releases/1.0.0/ZIP-ENTRY-COUNT-QUALIFICATION.md), [Archivgrößengrenze](../Releases/1.0.0/ZIP-ARCHIVE-BYTE-QUALIFICATION.md) und [Callerrechte](../Releases/1.0.0/ZIP-CALLER-PROFILE.md) verwenden vorhandene Belege. |
| `toolbelt.core.event-log` | [EVENT_LOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.event-log/Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Rollback-, uncommittable-, Context-, Retention- und Concurrency-Verträgen | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.error-envelope` | [ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.error-envelope/Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.execution-context` | [EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-context/Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Context-Lifecycle und Sessionisolation | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.execution-cancel` | [EXECUTION_CANCELLATION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.execution-cancel/Tests/EXECUTION_CANCELLATION_CONTRACT_TEST_MATRIX.md) | `partially validated` gemäß kanonischem Manifest; vorhandene Windows-/Linux-API- und Lifecyclematrix. Zusätzlich besteht die vollständige achtspaltige Windows-Repeat-Matrix auf allen unterstützten Windows-CLs lokal/zentral mit Principalbindung; [aktueller Repeat-Scope](../Modules/toolbelt.core.execution-cancel/Tests/README.md#vollständige-achtspaltige-windows-repeat-matrix-vom-2026-11-06). | Der [Linux-CI-Repeat](../Modules/toolbelt.core.execution-cancel/Tests/README.md#linux-repeat-mit-explizitem-compatibility-level) setzt/verifiziert ebenfalls alle unterstützten Engine-/CL-Paare lokal/zentral; tatsächliche Ergebnisse sind am exakten Head/Main zu prüfen. Nichtleere Benutzergrants, echte Minimalrechte und historische Versionsübergänge bleiben ohne eigenen Nachweis unqualifiziert; keine erneute Windows-Testwelle erforderlich. |
| `toolbelt.core.second-session` | [SECOND_SESSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.second-session/Tests/SECOND_SESSION_CONTRACT_TEST_MATRIX.md) | `partially validated`; ursprüngliche Windows-/Linux-Matrix 2019/2022/2025 einschließlich Loopback-Provider, Transaktion und Konkurrenz | Die markerfreie Quelländerung ist nicht durch die ursprüngliche Matrix qualifiziert; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.work-type` | [WORK_TYPE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-type/Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md) | `partially validated` gemäß kanonischem Manifest; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Removal- und Konkurrenzvertrag | Die vorhandenen Plattform-/Providerbelege bleiben gültig. Eine Modulgesamtaufwertung ist im Manifest nicht erklärt; vor einem Statuswechsel vollständigen Pflichtumfang und Nachweisbindung abgleichen. Kein zusätzlicher SQL-Lauf allein wegen dieser Textkorrektur. |
| `toolbelt.file.content` | [FILE_CONTENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; [Repeat](../Releases/1.0.0/FILE-CONTENT-REPEAT-COMPLETION.md) und [gezielte Lifecycleprofile](../Releases/1.0.0/FILE-CONTENT-LIFECYCLE-QUALIFICATION.md) gebunden. [AppLockergänzung](../Releases/1.0.0/FILE-CONTENT-APPLOCK-QUALIFICATION.md): 24 Kontexte/96 Profile/zwölf frische Audits | Erklärter Repeat-, Versions-/Kollisions-/Uninstallscope und exakte Abweisung unter bestätigter fremder Sitzungssperre mit Erfolg nach Freigabe geschlossen. Die [Definitionsdriftmatrix](../Releases/1.0.0/FILE-CONTENT-DEFINITION-DRIFT-QUALIFICATION.md) belegt zusätzlich 48 gezielte Bodyreparaturen mit stabiler Objekt-ID und erhaltenen Allowlist-Daten/Rechten, zwölf frische Audits. Die [Sitzungsverlustprüfung](../Releases/1.0.0/FILE-CONTENT-LEASE-RECOVERY.md) belegt vier Deploy-/Uninstall-Recoveries nach Beenden eigener ruhender AppLock-Halter auf Windows2025/CU8 CL170 lokal/zentral, frischen Audit und zwei eigene DB-Bereinigungen; beide alten FAILED_CLEANED bleiben erhalten. Tabellen-/Schema-/Owner-/ACLdrift, nichtleere Grants/Minimalrechte, aktive Mutations-/Host-/Transportabbrüche und übrige zugesagte Ressourcen-/Providerprofile bleiben getrennt; echte Datei-I/O bleibt optional. |
| `toolbelt.filesystem.windows` | [WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md) | `partially validated`; Caller-Impersonation, NTFS-ACL- und breitere manuelle I/O-Matrix offen | Windows-Identität und I/O: Caller-Impersonation, NTFS-ACL und breitere manuelle I/O-Fälle mit geklärter Identität und passenden Fixtures prüfen. |
| `toolbelt.core.result-table` | [RESULT_TABLE_CONTRACT_TEST_MATRIX.md](./RESULT_TABLE_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.work-queue` | [WORK_QUEUE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.work-queue/Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische 2.0-Matrix, echter 2.0→2.1-Upgrade auf 2019 Linux und gezielte SQL-Managedkopplung auf 2019 Linux/2025 Windows CU8 bestanden; vollständiger Providerlauf offen | Providerlauf: den vollständigen zugesagten Providerlauf mit passender vorkonfigurierter Providerkombination durchführen. |
| `toolbelt.core.worker-control` | [WORKER_CONTROL_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md) | `partially validated`; bestehende SQL-Admission-/Control-/Lifecyclebelege. Zusätzlich bestand die [Windows-Terminalhistorie](../Releases/1.0.0/WORKER-TERMINAL-HISTORY-WINDOWS.md) auf SQL2025/CU8 CL170 lokal im ManagedSqlOnly-Gesamtlauf mit frischem Abschlussaudit. | Der neue Scope ist kein externer Provider-/FullProduct-, Minimalrechte-, Windows-Client-/TLS- oder Host-/Transportnachweis; weitere Zielkombinationen bleiben eigenständig. Vorhandene separate Providerbelege behalten ihren jeweiligen Umfang. |
| `toolbelt.conversion.base64` | [BASE64_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.base64/Tests/BASE64_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.core.generate-series` | [GENERATE_SERIES_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.generate-series/Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md) | `validated`; Windows-/Linux-Fachmatrix 2019/2022/2025 und Pflicht-Lastfall auf SQL 2025 Linux CL170 erfolgreich; Zeitmessung optional | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.metadata.identifier` | [IDENTIFIER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.identifier/Tests/IDENTIFIER_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische Matrix am damaligen Quellstand erfolgreich | Aktuelle Grenzfälle in [FunctionEdgeCases.sql](Metadata/FunctionEdgeCases.sql) sind vorbereitet. Native Ausführung steht aus. |
| `toolbelt.string.split-characters` | [SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-characters/Tests/SPLIT_CHARACTERS_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.string.split-advanced` | [SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.split-advanced/Tests/SPLIT_ADVANCED_CONTRACT_TEST_MATRIX.md) | `partially validated`; [aktuelle Funktions-/Clientmatrix](../Releases/1.0.0/SPLIT-ADVANCED-CURRENT-QUALIFICATION.md) und direkte Callerprofile gebunden. [Gezielte Lifecyclematrix](../Releases/1.0.0/SPLIT-ADVANCED-LIFECYCLE-QUALIFICATION.md): 24 lokale/zentrale CS_AS-/BIN2-Kontexte, 240 Profile, zwölf frische Audits [AppLockergänzung](../Releases/1.0.0/SPLIT-ADVANCED-APPLOCK-QUALIFICATION.md): 24 Kontexte, 96 Profile, zwölf frische Audits. | Exakte Versions-/Bestätigungs-/Consumerabweisungen, kanonische Drift-/Typreparatur, Fremdobjekterhalt, Neuinstallation und fehlendes Uninstall im erklärten Scope geschlossen. Deploy-/Uninstall-Sperrabwehr und Erfolg nach bestätigter Freigabe im erklärten Scope geschlossen. Weitere Genuine-/Rollback-/Session-/Consumer-Collation-/Ressourcen-/Recoveryprofile, Linux-Clienthost bleiben getrennt. [Echter gemappter SQL-CrossDB-Caller](../Releases/1.0.0/SPLIT-ADVANCED-MAPPED-CALLER-QUALIFICATION.md): Windows2025/CU8 CL170 zentral, sechs Profile, drei gezielte DB-Rechte und frischer Audit bestanden; andere Identitäts-/Zielpfade bleiben separat. |
| `toolbelt.string.phonetic` | [PHONETIC_TEST_MATRIX.md](../Modules/toolbelt.string.phonetic/Tests/PHONETIC_TEST_MATRIX.md) | `partially validated`; Frameworklauf mit 669 Assertions und endlicher Java-Korpus mit 36 Fällen bleiben gebunden. [Aktuelle direkte Callerrechtezuordnung](../Releases/1.0.0/CLR-STRING-CALLER-CURRENT-BINDING.md): zwei öffentliche TVFs mit einzelnem SELECT, Modulquellen unverändert | Keine pauschal fehlenden direkten Datenpfad-Rechte. Die [vorhandene API-Matrix](../Releases/1.0.0/CLR-STRING-API-CURRENT-BINDING.md) mit drei Originalfixtures auf zwölf Zielpaaren lokal/direkt zentral ist aktuell quellengebunden; pauschale API-Ziellücken sind überholt. Scannerabdeckung, weitere Bridge-/Lifecyclekontexte, transitive SAFE-, DDL-/Owner-/CrossDB- und Ressourcenpflichten bleiben separat. |
| `toolbelt.string.edit-distance` | [EDIT_DISTANCE_TEST_MATRIX.md](../Modules/toolbelt.string.edit-distance/Tests/EDIT_DISTANCE_TEST_MATRIX.md) | `partially validated`; vorhandene Framework-/Build-/IL-/Nativebelege für 1.1 bleiben gebunden. [Aktuelle direkte Callerrechtezuordnung](../Releases/1.0.0/CLR-STRING-CALLER-CURRENT-BINDING.md): drei öffentliche TVFs mit einzelnem SELECT, Modulquellen unverändert | Keine pauschal fehlenden direkten Datenpfad-Rechte. Die [vorhandene API-Matrix](../Releases/1.0.0/CLR-STRING-API-CURRENT-BINDING.md) mit fünf Originalfixtures auf zwölf Zielpaaren lokal/direkt zentral ist aktuell quellengebunden. Die spätere [Neuausführung](../Releases/1.0.0/EDIT-DISTANCE-MISSING-TARGETS-QUALIFICATION.md) dokumentiert 80 redundante API-Fixtures plus 16 Baselinereceipts, acht frische Audits und entfernte eigene DBs; keine weiteren API-Wiederholungen. Lifecycle-DDL-/Owner-/CrossDB-/Heap-/Betriebs-/Recoverypflichten bleiben getrennt. |
| `toolbelt.string.regex` | [REGEX_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.regex/Tests/REGEX_CONTRACT_TEST_MATRIX.md) | `partially validated`; Regex1.3: physische Windows-/Linux-API-Matrix2019/2022/2025 über alle unterstützten CLs lokal/zentral gebunden. Historisches Capture-Gate für exakte DLL mit ausdrücklich akzeptiertem Restrisiko angenommen; skalare EXECUTE-Dokumentation/Paketbindung korrigiert. [Aktueller Abgleich](../Releases/1.0.0/RELEASE-GATES.md#regex-aktueller-nachweisabgleich-vom-2026-11-06). | Original203 PASS/1Capture PARTIAL bleiben erhalten; kein Ursachen-/Capture-Fixnachweis und keine Schedulinggarantie. Lowpriv-CrossDB, weitere Ressourcen-/Parallelitäts-/Host-Recovery- und übrige Modulpflichtfälle bleiben separat. |
| `toolbelt.validation.semantic-version` | [SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.validation.semantic-version/Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.conversion.integer-base` | [INTEGER_BASE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.integer-base/Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.calendar-difference` | [CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.calendar-difference/Tests/CALENDAR_DIFFERENCE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.date-spine` | [DATE_SPINE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.date-spine/Tests/DATE_SPINE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Dependency-, Kollisions- und Skalierungsverträgen | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.string.directional-trim` | [DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.string.directional-trim/Tests/DIRECTIONAL_TRIM_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische Matrix am damaligen Quellstand erfolgreich | Aktuelle Grenzfälle in [FunctionEdgeCases.sql](Metadata/FunctionEdgeCases.sql) sind vorbereitet. Native Ausführung steht aus. |
| `toolbelt.conversion.uri-component` | [URI_COMPONENT_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.conversion.uri-component/Tests/URI_COMPONENT_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische Matrix am damaligen Quellstand erfolgreich | Aktuelle Grenzfälle in [FunctionEdgeCases.sql](Metadata/FunctionEdgeCases.sql) sind vorbereitet. Native Ausführung steht aus. |
| `toolbelt.datetime.truncate` | [DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.truncate/Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich nativer Parität und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.datetime.bucket` | [DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.datetime.bucket/Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich 100.000-Zeilen-Workload und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.binary.bit-operations` | [BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.binary.bit-operations/Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md) | `validated`; vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich nativer Parität und Kollisionsschutz | Im Inventar ist für den beschriebenen Scope kein weiterer Punkt benannt; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.json.path-exists` | [JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.path-exists/Tests/JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische Matrix am damaligen Quellstand erfolgreich | Aktuelle Grenzfälle in [FunctionEdgeCases.sql](Metadata/FunctionEdgeCases.sql) sind vorbereitet. Native Ausführung steht aus. |
| `toolbelt.json.constructors` | [JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md) | `partially validated`; vorhandene Fachmatrizen. Vier-USP-Callerprofile auf [Windows](../Releases/1.0.0/JSON-CONSTRUCTORS-CALLER-QUALIFICATION.md) und [Linux-SQL-Zielen](../Releases/1.0.0/JSON-CONSTRUCTORS-LINUX-CALLER-QUALIFICATION.md),2019/2022/2025 über alle unterstützten CLs lokal/direkt zentral bestanden; je144 positive Profile und144 Abweisungen. Drei ursprüngliche Windows-Gesamtfehler separat erhalten. | Die [direkte Clientmatrix](../Releases/1.0.0/JSON-CONSTRUCTORS-CLIENT-METADATA-QUALIFICATION.md) ist auf24Kontexten mit480Profilen/zwölfAudits bestanden. Die [aktuelle genuine1.2→1.3-Migration](../Releases/1.0.0/JSON-CONSTRUCTORS-CURRENT-MIGRATION-QUALIFICATION.md) plus Core/Schema-Consumer ist auf24Kontexten/zwölf frischen Fallaudits bestanden. Die [direkten Aggregate-Minimalrechte](../Releases/1.0.0/JSON-CONSTRUCTORS-AGGREGATE-CALLER-QUALIFICATION.md) sind ebenfalls auf24 Kontexten mit48 positiven Profilen,144 SQL229-Abweisungen und zwölf frischen Audits bestanden; zwei vorherige bereinigte Adapterfehler bleiben erhalten. Die [nichtleere USP-ACL-Migration](../Releases/1.0.0/JSON-CONSTRUCTORS-NONEMPTY-ACL-QUALIFICATION.md) besteht nach neuer ausdrücklicher Freigabe auf 24 Kontexten: zwölf vollständige Läufe/zwölf frische Audits, 120 erhaltene Prozeduridentitäten/96 Objektgrants über Rollback/Upgrade/Repeat, 24 Benutzer/DBs entfernt. Beide vorherigen bereinigten Gesamtfehler bleiben erhalten. Offen bleiben direkte CLR-/Assembly-ACLs und andere Owner, Netzwerk-/CrossDB-Identitäten, Linux-Clienthost und übrige konkret zugesagte Modulpflichtfälle; keine Modulgesamtfreigabe. |
| `toolbelt.metadata.table-clone` | [TABLE_CLONE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.table-clone/Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md) | `partially validated`; historische V1/W1 bleiben getrennt. Aktuelle fünf Copygruppen: [Zielbericht](../Releases/1.0.0/TABLE-CLONE-COPY-TARGET-QUALIFICATION.md) mit22 neuen Windows-/Linux2019/2022/2025-CL-Kontexten lokal/direkt zentral und zwei begrenzt wiederverwendeten lokalen Zeugen; zwölf frische Audits, eigene DBs entfernt | Die [aktuelle Planner-/Executor-Matrix](../Releases/1.0.0/TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md) belegt vier unveränderte 4.1.1-Fixtures auf 24 Kontexten mit 96 vollständigen Fixture-Ausführungen und zwölf frischen Audits. Die [aktuelle W1-/W2-Matrix](../Releases/1.0.0/TABLE-CLONE-W1-W2-QUALIFICATION.md) ergänzt sieben Originalfixtures auf 24 Kontexten mit 168 Ausführungen, zwölf erfolgreichen Gesamtfällen und 13 frischen Audits; Erstfehler und unveränderte Originalfrist bleiben erhalten. Der [aktuelle Trigger-Consumer](../Releases/1.0.0/TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md) belegt zwölf Windows-Kontexte/24 Originalfixture-Ausführungen/sechs frische Audits. Der korrigierte einzelne Providerpin liegt nur im Option-1-Gate; Option-0-Belege bleiben über geprüfte Quellenäquivalenz verwendbar. Die [Windows-Clientmatrix](../Releases/1.0.0/TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md) belegt 24 Windows-/Linux-SQL-Kontexte und zwölf frische Audits für Reader/Help/ResultTable und frühe Caller-Guardfragmente. Der [vollständige SQLCMD-Abbruch](../Releases/1.0.0/TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md), der [genuine V1-Lifecycle](../Releases/1.0.0/TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md), die [direkten fünf Vorgänger](../Releases/1.0.0/TABLE-CLONE-KNOWN-PREDECESSORS-QUALIFICATION.md) und die [Planner-Fünfrechtematrix](../Releases/1.0.0/TABLE-CLONE-PLANNER-RIGHTS-QUALIFICATION.md) schließen ihre beschriebenen Teilumfänge; historische Fehlläufe bleiben erhalten. Die [Executor-Grundrechtematrix](../Releases/1.0.0/TABLE-CLONE-EXECUTOR-RIGHTS-QUALIFICATION.md) ergänzt 24 reale SQL-/TCP-Kontexte, 144 Profile und zwölf frische Audits; alle eigenen DBs/Logins entfernt. Offen: weitere Quoten-Branches, erweiterte Executor-/Copy-/Trigger-Rechte, Linux-Clienthost, weitere Provider sowie noch unbelegte Consumer-/Namespace-/Sicherheits-/Recoveryfälle. Kein pauschal offener Planner- oder direkter bekannter Vorgängerpfad. |
| `toolbelt.pseudonymization.deterministic` | [CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.pseudonymization.deterministic/Tests/CONTRACT_TEST_MATRIX.md) | `partially validated`; frühere Safety-/Funktionsadapter bleiben getrennt. [Isolierte API-/Lookup-Rechteprofile](../Releases/1.0.0/DETERMINISTIC-RIGHTS-QUALIFICATION.md) auf zwölf Ziel-/CL-Paaren sowie [acht zusätzliche GeoJitter-Kombinationen](../Releases/1.0.0/GEO-MISSING-TARGETS-QUALIFICATION.md) bestanden | Keine pauschal fehlenden direkten Callerrechte. Der [exakte129-Byte-UDT](../Releases/1.0.0/GEO-EXACT129-QUALIFICATION.md) ist auf24 aktuellen Kontexten mit24 Ablehnungen,24 Punkt-Kontrollen und zwölf frischen Audits qualifiziert. GeoJitter erweitert weder automatisch die übrige Funktionsfamilie noch deren Lifecycle-/Clientmatrix. Echte CrossDB-Identitäten, übrige Ziel-/Ressourcen-/Recoveryprofile bleiben getrennt. |
| `toolbelt.core.console-message` | [CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.console-message/Tests/CONSOLE_MESSAGE_CONTRACT_TEST_MATRIX.md) | `validated` gemäß [Manifest](../Modules/toolbelt.core.console-message/module.yaml). Der physische Moduladapter vom2026-10-19 belegt Windows/Linux2019/2022/2025 über die enginegerechten CLs lokal/zentral einschließlich Lifecycle, ODBC/sqlcmd und separaten ADO.NET-Frames/Unicode/Atomik/NOWAIT-Beobachtungen | Der ältere offene Client-/Framingstatus ist für diesen ausgewählten Umfang überholt. Keine allgemeine Latenz-, Darstellungs- oder beliebige Treiberzusage; zusätzliche Zusagen würden einen eigenen Scope brauchen. |
| `toolbelt.metadata.capability-catalog` | [CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.metadata.capability-catalog/Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md) | `partially validated`; ursprüngliche Windows-/Linux-Matrix 2019/2022/2025 einschließlich eingeschränkter Metadatensichtbarkeit ohne Rechteausweitung | Die markerfreie Quelländerung ist nicht durch die ursprüngliche Matrix qualifiziert; vor weiterem Statusschluss zugesagten Umfang und kanonische Modulmatrix abgleichen. Keine allgemeine Gatevollständigkeit abgeleitet. |
| `toolbelt.tsql.script-parser` | [TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.tsql.script-parser/Tests/TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md) | `partially validated`: das private Binärpaar bestand die aktuellen API-, Minimalrechte- und gezielten Ausgabeprüfungen in zwölf Windows-Kontexten. | [Aktuelle native Abnahme](../Scripts/Install/Tests/QUALIFICATION.md#privates-parser-binärpaar-und-minimalrechte); frühere kombinierte Quotennachweise gelten für ihre ursprünglichen Artefakte. |
| `toolbelt.tsql.ssis-debug` | [SSIS-Debug-Prüfmatrix](../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) | `partially validated`, unveröffentlicht; Copy Column V1 als zusammengesetztes Explain-/Prozedurguard-Delta mit 56 nativen Profilen, 1.112 Assertions und 14 Audits. [Aktuelle und historische Umfänge](../Releases/1.0.0/RELEASE-GATES.md#qualifikationsabgleich-nach-copy-column-v1). | Vollständige ältere ZIP-/SSMS-/TLS-/Sicherheitsabnahmen gelten für ihre ursprünglichen Builds. Keine vollständige neue Modul-, ZIP-, SSMS-, TLS- oder Linux-Hostabnahme aus dem Delta. |

Eine Testmatrix ist noch kein Nachweis einer erfolgreichen Ausführung.

Der aktuelle Status am Anfang jeder Inventarzeile muss dem kanonischen
`validation_status` im Modulmanifest entsprechen. Die bestehende
Dokumentationsprüfung vergleicht diese Angaben automatisch. Historische
Teilnachweise und deren damalige Statuswörter bleiben davon getrennt erhalten.

## Testdaten

- ausschließlich deterministische synthetische Testdaten;
- keine Produktions- oder Originaldaten, personenbezogenen oder sensiblen Daten sowie internen oder vertraulichen Informationen;
- keine nicht öffentlichen Infrastrukturangaben, realen Runtime-Ausgaben oder konkreten Remote-Runner-Hardwarewerte;
- fachlich relevante öffentliche Organisations-/Projektnamen und öffentliche Links sind zulässig;
- Rand- und Fehlerwerte ausdrücklich abdecken.

## Evidenz

Jede ausgeführte Prüfung nennt Befehl oder Workflow, Scope, Version, Plattform, Provider, Ergebnis, Datum und Einschränkungen. Nicht ausgeführte Prüfungen bleiben als `not executed` sichtbar.

## CI

Die capability-bezogene GitHub-hosted Linux-CI ist aktiv. Der
[Dokumentationsvalidator](./Documentation/README.md) prüft Pull Requests
inkrementell. Eine Dokumentationsänderung benötigt keine vollständige
Runtime-Matrix.

Details: [TEST_AND_VALIDATION_POLICY.md](../Documentation/Standards/TEST_AND_VALIDATION_POLICY.md)
