# Aktueller Abgleich: geschlossene Teilumfänge und echte Restqualifikation

Stand 2026-11-22 (Produktstand `db4f29db`). Diese Übersicht ordnet spätere
Nachweise vor älteren Offen-Formulierungen ein. Sie ersetzt keine Originalausführung, erweitert
keine Freigabe und ist kein Gesamtfreigaberecord. Die [45-Modul-Übersicht](../../Tests/README.md#modulspezifische-testmatrizen)
und jeweilige Modulmatrix bestimmen die tatsächlich zugesagten Pflichten.
Lokale nicht integrierte Vertragsentwürfe sind keine Implementierungsfreigabe.

## Gemeinsamer aktueller Installationssatz

Die [frühere gemeinsame Installer-Abnahme](CURRENT-INSTALL.md) schloss die
damalige Ctor-/Parser-/SSIS-Quellbindungslücke. [Zwölf native Fresh-Install-Profile](CURRENT-INSTALL-QUALIFICATION.md)
auf sechs Windows-/Linux-Enginepaaren mit den jeweiligen Standard-CLs und sechs
frischen Audits sind bestanden. Die aktuelle Parserbindung von SSIS ist eng
abgegrenzt aktualisiert; die übrige Modelllogik und geprüfte Binaries werden
wiederverwendet. Frühere Paket-, SSMS-, TLS- und Sicherheitsrecords bleiben
an ihre ursprünglichen Providerbytes gebunden und sind keine neuen Gesamtfälle.

Für den aktuellen markerfreien Installationssatz gelten die
[vier separat gebundenen Profilabnahmen](../../Scripts/Install/Tests/QUALIFICATION.md).
Die gepackte PowerShell-/ODBC-Ausführung auf Ubuntu ist für Portable zentral
auf Linux SQL Server 2025 CL170 belegt. Der anschließende Gesamtfall aus dem
aktuellen ZIP legte die fehlende Datenbank mit `-CreateDatabase` an,
aktivierte CLR mit `-EnableClr` und installierte 41 Module. Der Abschlussaudit
prüfte GUID, Konfiguration, Trust und Containerentfernung.
[Linux-Client ohne Vorbereitung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/45011758926) ·
[Gesamtfall mit Vorbereitung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/45013101814)

## Offene Abnahme des Dialektwerkzeugs

[PR #655](https://github.com/gecompat/SQL_Server_Toolbelt/pull/655) integriert
den freigegebenen Offline- und SQL-Server-Umfang. Auf `main` bestanden 24
Offline-Tests sowie zehn native SQL-Server-2025-Fälle für Werte, Schema,
NULL, Multiplizität und vereinbarte Reihenfolge. Die CI bestätigte die
Entfernung des Containers.
[Main-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/45023399256)

Die native Databricks-Abnahme steht ausdrücklich aus. Sie setzt ein
ausgewähltes, laufendes SQL-Warehouse voraus. Die historischen Spark-Belege
gelten für ihren Researchkorpus. Ob der vorgesehene `ROW_NUMBER`-Ersatzpfad
für laterales `TOP`/`LIMIT` nötig ist, hängt vom getesteten Warehouseprofil ab.
[Abnahmeweg](../../Scripts/SqlDialect/README.md#native-abnahme) ·
[V1-Vertrag](../../Documentation/Research/TSQL_DATABRICKS_V1_SCOPE_PROPOSAL.md#outer-apply-konkrete-erlaubte-regeln)

## Geschlossene Teilumfänge nicht erneut testen

| Alte pauschale Offen-Angabe | Späterer maßgeblicher Nachweis |
|---|---|
| Worker: Verlust der Antwort auf den tatsächlichen Commit ungetestet | [Nativer Main-Lauf nach PR #654](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/45020053497). Auf Linux SQL Server 2025 bestätigte eine getrennte Sitzung den persistierten Effekt vor dem Verbindungsabbruch. Der Worker meldete UNKNOWN und hielt den Slot belegt. Reconciliation bestätigte COMMITTED, gab den Slot frei und belegte genau einen Effekt. Der Container-Cleanup bestand. Der Fall gilt für Antwortverlust nach dauerhaftem Commit. |
| Table Clone: Triggerübernahme mit privatem Parserpaar fehlt | [Native Parserpaar-/Trigger-Abnahme](../../Modules/toolbelt.metadata.table-clone/Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md#privates-parserpaar--22-november-2026) für die sechs Windows-/Engine-/CL-Kontexte in lokal und zentral mit 24 Fixture-Ausführungen und drei Abschlussaudits. |
| Windows Filesystem: konkrete Codepage-, Chunk-, Limit- und Atomic-Write-Fälle fehlen | [Native I/O-Grenzfälle](../../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md#native-io-grenzfälle--22-november-2026) mit 22 SQL-Assertions auf SQL Server 2025/CU8 CL170 im Caller-Modus, separater Prüfung der Dateibytes und frischem Abschlussaudit. |
| ZIP: Windows-/CL-Fassaden und portables Memory-Profil offen | [ZIP Files](../../Modules/toolbelt.archive.zip-files/Tests/ZIP_FILES_TEST_MATRIX.md#vollständige-archivextraktion-v1) belegt die beauftragten Windows-/Local-Fälle einschließlich Einzel-Entry und Writer. [ZIP Memory](../../Modules/toolbelt.archive.zip-memory/Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md#aktueller-portabler-build) belegt den deklarierten portablen Umfang auf Windows und Linux lokal und zentral. |
| XLSX: reale Archiv-/Part-/Summen-/Partanzahl-Grenzen und aktuelles Paket fehlen | [192 native Grenzaufrufe auf 24 Routen, zwölf frische Audits und fokussiertes Paket](XLSX-NATIVE-PACKAGE-QUALIFICATION.md). Blattanzahl und SST haben ihre eigenen unveränderten Nachweise. Keine Heapmessung daraus ableiten. |
| XLSX: die benannten übrigen Typ-/Anzeige-Fixtures fehlen | [74 neue vollständige Fixture-Ausführungen, elf frische Audits](XLSX-CELL-API-REST-QUALIFICATION.md); nur die dort ausdrücklich benannten disjunkten Ziel-/Modusprofile. |
| XLSX: die benannten übrigen Typ-/Anzeige-Clientmetadaten fehlen | [37 neue Originalhelfer-Ausführungen mit 95 Readerfällen und elf frischen Fallaudits](XLSX-CELL-CLIENT-REST-QUALIFICATION.md). Der ursprüngliche Callback-Fehler und sein eigener Audit bleiben erhalten; Katalognullability und andere Client-/Consumerprofile bleiben separat. |
| XLSX: genuine 1.0 auf heutigen 1.2-Build fehlt | [24 aktuelle Upgrade-Routen, 48 Metadatenhelfer und 13 frische Audits](XLSX-GENUINE10-REST-QUALIFICATION.md). Originale 1.0-Sources und zwei unabhängige bytegleiche Builds; keine Versionmarkerfälschung. Genuine 1.1 und andere Fehler-/Consumerprofile bleiben getrennt. |
| XLSX: genuine 1.1 auf heutigen 1.2-Build fehlt | [24 aktuelle Upgrade-Routen, 48 Metadatenhelfer und zwölf frische Audits](XLSX-GENUINE11-REST-QUALIFICATION.md). Originale 1.1-Sources und zwei unabhängige bytegleiche Builds; ausgeführte CRLF-Testquellen zusätzlich exakt erhalten. Übrige Consumer-/Lifecycle-/Ownerprofile bleiben getrennt. |
| XLSX: sämtliche Lifecycle-/Visibilityfehler pauschal offen | [528 aktuelle Negativfälle auf 24 Routen, zwölf frische Audits](XLSX-LIFECYCLE-NEGATIVE-REST-QUALIFICATION.md). Nur vier benannte Rollback-, zwei AppLock- und 16 synthetische 0/NULL-Profile je Route; echte Lowpriv-/Ownerrechte bleiben getrennt. |
| XLSX: die vier bekannten Display-Zukunftsslots auf genuine1.1 fehlen aktuell | [96 aktuelle Ablehnungs-/Fremderhaltprofile auf 24 Routen, 120 genuine Katalogzeugen und 13 frische Audits](XLSX-FUTURE-COLLISION-REST-QUALIFICATION.md). Ursprünglicher Pfadfehler bleibt FAILED_CLEANED; weitere Slots und tatsächliche Owner-/Callerrechte bleiben separat. |
| XLSX: die vier bekannten Typ-Zukunftsslots auf genuine1.0 fehlen aktuell | [96 aktuelle Ablehnungs-/Fremderhaltprofile auf 24 Routen, 120 genuine Katalogzeugen und zwölf frische Audits](XLSX-TYPE-FUTURE-REST-QUALIFICATION.md). Exakte Originalartefakte wiederverwendet; weitere Slots und tatsächliche Owner-/Callerrechte bleiben separat. |
| XLSX: Caller-TX intakt/doomed und Katalognullability fehlen aktuell | [192 Deploy-/Uninstall-Ablehnungen, 24 echte Katalog-/Clientprüfungen, zwölf frische Audits](XLSX-CALLER-CATALOG-REST-QUALIFICATION.md). Nur die benannten OFF/ON-Profile und der vorhandene Windows-Client; keine neuen Owner-/Login-/SQLCMD-/OS-Ausfallbehauptungen. |
| XLSX: die sechs bekannten Marker-/Versions-/Modus-/Dependencyprofile fehlen aktuell | [144 aktuelle Ablehnungs-/Restoreprofile auf 24 Routen, zwölf frische Audits](XLSX-MARKER-COLLISION-REST-QUALIFICATION.md). Originale Fixture und Schleife; andere Slot-/WrongType-/Owner-/Identitätsprofile bleiben getrennt. |
| XLSX: installierte Komposition und providerfreie zentrale Consumer fehlen aktuell | [72 originale Kompositionen, 24 Consumer-Metadatenhelfer, zwölf Nullability-/Confirm0-Prüfungen und zwölf frische Audits](XLSX-COMPOSITION-CONSUMER-REST-QUALIFICATION.md). Zwölf eigene CS-Consumerdatenbanken ohne lokale Provider; vorhandene administrative Identität, keine neue gemappte/Lowpriv-Identität oder Linux-Clienthostqualifikation. |
| XLSX: WrongType und fehlende Prozessrückgabe | [SQL-Fachmatrix und gezielter neuer Prozessabschluss](XLSX-WRONGTYPE-PROCESS-CLOSURE.md). Elf bestehende Prozesskontexte wiederverwendet; ausschließlich Linux SQL2025/CL160 lokal/zentral neu mit zwei Aufrufen/frischem Audit. Historischer PARTIAL-Bericht, unbekannter ursprünglicher Rückgabewert und alte Fehler bleiben unverändert. |
| XLSX: direkte Zell-/Raw-Callerrechte sind pauschal ungetestet | [Zellrechte](XLSX-CELL-CALLER-QUALIFICATION.md), [Raw-Rechte](XLSX-RAW-CALLER-PROFILE.md) und [Metadatenpflege](XLSX-METADATA-UPDATE.md). Andere Owner und echte gemappte CrossDB-Identitäten bleiben getrennt. |
| Aggregate: vier große Entrygrenzen und Linux SQL2025/CL170 blockiert | [Aktuelle Timeoutkorrektur: 96 native Profile auf 24 Kontexten](JSON-AGGREGATE-NATIVE-TIMEOUT-FIX-QUALIFICATION.md). Alte fehlgeschlagene Koordinatoren bleiben fehlgeschlagen. Keine vollständige neue ZIP-Matrix daraus ableiten. |
| Table Clone: W1/W2, Planner-/Executor-Grundrechte, SQLCMD-Abbruch und bekannte Vorgänger fehlen allgemein | [W1/W2](TABLE-CLONE-W1-W2-QUALIFICATION.md), [Planner](TABLE-CLONE-PLANNER-RIGHTS-QUALIFICATION.md), [Executor-Grundprofil](TABLE-CLONE-EXECUTOR-RIGHTS-QUALIFICATION.md), [SQLCMD](TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md), [V1](TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md) und [fünf bekannte Zwischenversionen](TABLE-CLONE-KNOWN-PREDECESSORS-QUALIFICATION.md). Erweiterte Rechte und andere Fehlerstellen bleiben getrennt. |
| SSIS: frische aktuelle ZIP-/SSMS-Abnahme fehlt allgemein | [Aktueller ZIP-/SSMS-Gesamtfall](SSIS-CURRENT-ZIP-SSMS-QUALIFICATION.md) mit getrennt gebundenen strikten TLS-/Sicherheitsnachweisen. SQL-Anmeldung bei TLS wird nicht zu kombinierter Windows-/TLS-Identität. |
| Regex: Capture-Gate, physische R2b-Ziele und große Capture-Ausgabe pauschal offen | [Datierter aktueller Abgleich](RELEASE-GATES.md#regex-aktueller-nachweisabgleich-vom-2026-11-06). Die [originale 16-MiB-Capture-Ausgabegrenze](REGEX-CAPTURE-BOUNDARY-STATUS.md) ist auf allen 24 Routen einschließlich großem Opt-in belegt. Die ausdrücklich angenommene Restrisikogrenze bleibt erhalten; keine erfundene Ursachenklärung oder Timeoutgarantie. |

## Auswahl notwendiger Restarbeit statt pauschaler Offenliste

Benutzerklarstellung vom 2026-11-17: Nur notwendige, bereits fachlich freigegebene
Entwicklung und Qualifikation autonom bearbeiten. Zusätzliche Absicherung oder
Erweiterungen werden ausschließlich auf ausdrücklichen Wunsch ausgeführt.
Ein im Bericht genanntes „nicht ausgeführt“ beschreibt die Nachweisgrenze;
es ist für sich weder ein Defekt noch ein weiterer Arbeitsauftrag.

Notwendig ist ein Restfall, wenn er einen konkreten zugesagten Funktions-,
Plattform-, Deployment- oder Sicherheitsvertrag prüft und dafür nach Abgleich
keine gültige aktuelle Evidenz besteht. Vorhandene Sicherheitsanforderungen
werden nicht abgeschwächt. Bestehende Nachweise werden nur bei betroffener
Quelländerung, Befund oder tatsächlich vorgeschriebener Frische neu ausgeführt.
Der [freigegebene Supportzielumfang](SUPPORT.md) bleibt erhalten; eine weitere
Clientplattform folgt nicht automatisch aus einer unterstützten SQL-Plattform.

### Erledigte oder zusätzlich abgegrenzte Angaben

| Bisher als Rest genannte Angabe | Aktuelle Einordnung und Folge |
|---|---|
| SSIS: zusätzliche Kombination aus Windows-Anmeldung und strikt geprüftem TLS | Kein weiteres Pflichtgate des freigegebenen Debugvertrags. Funktionale Windows-/SSMS-Prüfung, strikter SQL-authentifizierter TLS-Test und Sicherheitsabnahme liegen getrennt vor. Keine kombinierte Abnahme behaupten und keinen neuen Lauf starten. |
| SSIS: volle Runtime-Parität, unbegrenzte Produktionskapazität oder Verlust des gesamten OS/der VM | Außerhalb des aktuellen Debugvertrags; keine Entwicklungs- oder Testwelle. Die bisherigen Nachweisgrenzen bleiben wahr. |
| Work Queue/Worker: lokaler Windows-Providerlauf fehlt allgemein | [Die sechs lokalen Windows-/CL-Kontexte mit je elf Providerfällen sind abgeschlossen](../../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md#aktueller-lokaler-windows-providerumfang). Der Record bleibt FullProduct=false; das ist kein Auftrag, beliebige weitere Providerfälle zu entwickeln. |
| Weitere Linux-Clienthosts, Clientstacks oder Authentifizierungskombinationen | Kein automatisches Pflichtgate aus der Windows-/Linux-SQL-Zielmatrix. Nur ausführen, wenn der konkrete Clientweg selbst zugesagt und freigegeben ist. Vorhandene Linux-Modellhostbelege bleiben gültig. |
| Beliebige historische Upgradepfade | Kein universeller Upgradevertrag. Tatsächlich zugesagte und bereits belegte Vorgängerpfade beibehalten; keine weiteren Ausgangsversionen allein wegen ihrer Existenz testen. |
| Heap-, Durchsatz-, Kapazitäts- oder vollständige Parallelitätsmessungen | Ohne konkrete Leistungs-/Ressourcenzusage zusätzliche Untersuchung, keine aktive Restwelle. Vertraglich feste Ausgabe-/Ressourcenlimits und Sicherheitsabbrüche bleiben erforderlich; ihre gültigen Grenznachweise werden wiederverwendet. |
| Vollständiges kartesisches Produkt aller Owner, Rechte, Identitäten, SET-Werte und Fehlerstellen | Kein eigenständiger Vertrag. Konkrete zugesagte Sicherheits- und Recoveryeigenschaften risikobezogen prüfen; keine zusätzliche Kombination ohne belegte notwendige Lücke. |
| Direkte interne CLR-Aufrufe oder beliebige weitere Consumer | Nicht automatisch öffentliche APIs. Nur dokumentierte öffentliche Aufrufwege und zugesagte Schutzgrenzen erzeugen notwendige Fälle. Bestehende Sicherheitsprüfungen bleiben erhalten. |

### Verbleibende Vertragsgrenzen

Die folgenden Einträge sind konkrete Abnahmethemen, keine pauschalen
Matrixaufträge. Ein vorhandener Teilnachweis bleibt für seinen Scope gültig.
Nur sein tatsächlich fehlender, zugesagter Teil darf ausgewählt werden.

| Bereich | Erforderlicher Vertragsbezug und verbleibende Abgrenzung |
|---|---|
| XLSX | [Namespace-, Lifecycle- und Sicherheitsvertrag](../../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md): der Erhalt fremder Caller-/ResultTable-Namensräume und tatsächlich zugesagte Aufrufrechte. Bereits geschlossene Größen-, Versions-, Marker-, WrongType-, Kompositions- und Callerprofile oben wiederverwenden. Weitere Owner-/Consumerprofile nur bei konkreter Zusage; keine allgemeine Heap- oder Clienthostwelle. |
| JSON | [Core](../../Modules/toolbelt.json.core/Tests/TEST_MATRIX.md), [Schema](../../Modules/toolbelt.json.schema/Tests/TEST_MATRIX.md) und [Constructors](../../Modules/toolbelt.json.constructors/Tests/JSON_CONSTRUCTOR_CONTRACT_TEST_MATRIX.md): öffentliche APIs, Ownership-/Dependency-Erhalt und atomarer Lifecycle im zugesagten Zielumfang. Vor Auswahl einer ACL-/Owner-/Recoveryprüfung die konkrete Zeile gegen spätere Berichte abgleichen. Keine pauschale direkte CLR-, Netzwerk-, Linux-Client- oder Ressourcenmatrix. |
| Table Clone | [Öffentlicher Clone-/Executorvertrag](../../Modules/toolbelt.metadata.table-clone/Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md): zugesagte Copy-/Trigger-/FK-/ResultTable-Funktionen und deren notwendige Aufrufrechte, atomare Fehler und Caller-Namensräume. Planner-/Executor-Grundrechte, W1/W2, SQLCMD und bekannte Vorgänger sind bereits belegt; keine pauschale neue Rechte- oder Recoveryvollmatrix. |
| Windows Filesystem | [I/O-/Caller-/Dateisicherheitsvertrag](../../Modules/toolbelt.filesystem.windows/Tests/WINDOWS_FILESYSTEM_CONTRACT_TEST_MATRIX.md): Die oben benannten I/O-Grenzen ergänzen die vorhandenen Caller-/NTFS-/Reparse- und begrenzten Racebelege. Weitere Identitäts-, Datei- oder ACL-Fälle benötigen eine konkrete vertragliche Lücke. |
| File Content und ZIP-Dateifassaden | [File Content](../../Modules/toolbelt.file.content/Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md) und [ZIP Files](../../Modules/toolbelt.archive.zip-files/Tests/ZIP_FILES_TEST_MATRIX.md): zugesagte Root-/Zielerhaltung, öffentliche Ausgabe-/KeepData-Semantik und sicherer Publish-/Abbruchpfad. Bereits belegte Repeat-/Drift-/Alias-/Grenzfälle nicht wiederholen. ZIP Files bleibt Windows/local; keine Linux-/Central-Erweiterung. |
| Regex und Worker | Die SQL-Capturegrenze, die lokalen Windows-Providerfälle und der Antwortverlust nach dauerhaftem Commit sind belegt. Andere Hostausfälle und Dispositionsgrenzen bleiben in ihren jeweiligen Verträgen dokumentiert. Für einen zusätzlichen Lauf ist eine konkrete noch unbelegte Zusage erforderlich. [Regex](../../Modules/toolbelt.string.regex/Tests/REGEX_CONTRACT_TEST_MATRIX.md) · [Worker Control](../../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md) |

Dieser Abgleich ändert weder Produktcode noch historische Records, Modulstatus
oder den freigegebenen Supportzielumfang. Insbesondere ist er kein Nachweis,
dass sämtliche genannten Vertragsgrenzen bereits vollständig geprüft wurden.
Für SSIS wird aus den hier genannten zusätzlichen Transport-/Runtimegrenzen
keine weitere notwendige Testwelle abgeleitet.

Vor einer neuen Welle die konkrete fehlende Matrixzeile, ihre aktuelle
Source-/Fixturebindung, den vorhandenen Gegenbeleg und den notwendigen
endlichen Scope festhalten. Neue Rechte, Infrastrukturänderungen und neue
Fachfunktionen behalten ihre konkreten Gates; geschlossene alte Laufbudgets
werden nicht erneuert. Fehlende Voraussetzungen blockieren nur den betroffenen
Fall, nicht unabhängig ausführbare notwendige Restarbeit.
Nicht veröffentlichen oder taggen.
