# Testausführung

Die [Trigger-Welle](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
erhält zwei begrenzte Windows-Fixtures: `Trigger.Contract.sql` für tatsächlich
ausgeführte synthetische Vorschaupläne und `Trigger.Safety.sql` für atomare
Ablehnungen. Linux prüft den unveränderten Option0-Pfad, neue13/14-Metadaten
und den Release4.0-Hash ohne Parser. Source und Fixtures sind vorhanden;
hieraus wird kein Runtime-PASS abgeleitet. Unveränderte historische Fachtests
werden für den nativen Wellenlauf nicht pauschal wiederholt.

Am2026-10-04 bestanden beide Trigger-Fixtures auf Windows2025/exakt CU8 CL170
lokal einmal in Clean4. Clean4 und genuine3.1→4 mit frischer Session, Repeat,
13/13/14 Parameter, unabhängiger Clienthash mit typgenauer NOT-NULL/Binary32/
EOF-Ausgabe, vier resolved-Consumer-Ablehnungen und Uninstall/Repeat bestanden.
Zwei eigene DBs entfernt, temporärer Parsertrust wiederhergestellt und
vorbestehender ScriptDom-Trust erhalten; frischer Cleanup und vollständige
Prozess-/Journal-/Inputpinprüfung unabhängig physisch geschlossen.
Keine Konfigurations-, Rechte- oder Owneränderung. Linux2019/latest CL150:
separater erfolgreicher Option0-/Lifecycle-Lauf wiederverwendet; spätere
Corekorrekturen ausschließlich Option1 unabhängig geprüft. Frühere
Fehlerläufe sind kein Gesamt-PASS. Weitere native Ziele/CL, zentrale4.0,
Minimalrechte, serverweite negative Fixtures und unsichtbare/mehrdeutige
Kontexte nicht ausgeführt; unresolved Consumer nicht etabliert. Head-CI separat
im PR. Teilweise validiert, unveröffentlicht; keine vollständige Produktqualifikation.

## Executor 3.1

Die neue Welle verwendet `Execute.Contract.sql` und `Execute.Safety.sql`
gezielt einmal je ausgewähltem Lab-Ziel; historische Planner-Grenzfixtures
werden nicht wiederholt. Signatur-/Hash-/Modus-/Lifecyclekopplung ist statisch
geprüft. Die begrenzten privaten Native- und Clientadapter bestanden am
2026-10-04 auf Linux2019/latest CL150 und Windows2025/exakt CU8 CL170,
jeweils lokal. Clean3.1 und genuine3→3.1 einschließlich Repeat, resolved
Consumer, Uninstall und eigener Bereinigung sind geprüft. Die beiden neuen
Fixtures und der Clientnachweis wurden im Upgradezyklus nicht wiederholt.
Head-CI ist ein separater PR-Nachweis; keine vollständige Ziel-/CL-/Minimalrechtematrix.

Static: `python Modules/toolbelt.metadata.table-clone/Tests/Static/validate_contract.py`.
Die ausgeführten privaten Adapter validierten den exportierten Schema-Vertrag;
keine Infrastruktur-, Konfigurations-, Rechte- oder Truständerung.
CI-Workflow registriert2019/2022/2025Linux, vorhandener Workflow ist keine Evidenz.

Historische Version1.0.0: Am2026-10-01 vollständige finale2019Linux/latest- und2025Windows/CU8-Adapter erfolgreich; Source,
Statementstruktur, Help-/Resultmetadaten, Indexshape und eigener/caller/doomed
Transaktionsscope geprüft. Weitere Zielversionen/GitHub/LowprivCrossDB offen.
Siehe [Testmatrix](TABLE_CLONE_CONTRACT_TEST_MATRIX.md).
Lifecycle-Caller-Tx: SQLCMD-Includes prüfen tatsächlichen Nonzeroexit; der
SqlClient-Metadatentest prüft die frühesten kanonischen Guard-Batches auf
derselben offenen Caller-Session bei XACT_ABORT ON/OFF mit Count/State,
synthetischen Daten und Modulmarker. Keine serverweite sys.messages-Änderung.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Begrenzter privater Datenkopie-Nativeadapter (PowerShell/SqlClient); unabhängige physische Prozess-/Journalprüfung`
- Scope: Version4.1.0, normaler Scope: SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 ausschließlich lokal. Copy.Contract.sql und Copy.Safety.sql mit fünf gruppierten Form-/KEEP-/REGENERATE-/Self-FK-/Byte-/FK-Zustands-/Safety-/Rollback-Orakeln je einmal Clean4.1 bestanden. Clean/Repeat, genuine4.0→4.1 aus unveränderten öffentlichen Blobs mit frischer Session, vier Slots13/14/14/9, vier resolved-Copy-Consumer-Ablehnungen53926/1, Uninstall/Repeat und fünffeldrige Clientausgabe mit genauen SQL-/CLR-Typen, NOT NULL, exakten Werten, EOF und keinem Folgeresult bestanden. Je zwei eigene Datenbanken entfernt; vollständige Prozesskanäle, Inputpins, Journale und frischer Cleanup-Audit unabhängig physisch geprüft. Keine Serverkonfigurations-, Rechte-, Owner- oder Truständerungen. Erster Linuxfehler51020/1 nach Installation kein PASS: privater FK-Brückenname korrigiert, betroffener Scope wiederholt. Zusätzlich auf Linux2019/latest CL150 vier dynamische Identity-Fälle bestanden: KEEP bei ursprünglichem OFF, spätes CHECK547 mit Rollback, vorbestehendes Target-ON und Other-ON mit Original8107; direkte INSERT-Proben in derselben Verbindung, Caller-TX/SET sowie vier typgenaue NOT-NULL-Witnesszeilen/EOF geprüft. SNAPSHOT-Quellkonsistenz und bis Ende gehaltene Targetsperren durch tatsächliche Sperrbeziehungen und konkurrierende Writes belegt; isolierter Nichtleer-Lauf beobachtet Blockierung und Original53944/1 mit gesunder Session und erhaltenen Targets. Identity und positiver SNAPSHOT-Fall sind abgeschlossene Teilnachweise aus insgesamt fehlgeschlagenen Adapterläufen; unveränderte Produktbytes geprüft und erfolgreiche Fälle nicht wiederholt. Adapterfehler266, Nichtleer-Rendezvous und Cleanup3701 kein PASS. SNAPSHOT ausschließlich in eigenen synthetischen DBs privat journalisiert, vorbereitet, wiederhergestellt; eigene DBs entfernt und Prozesskanäle/Pins/Journale/frische Bereinigung unabhängig physisch geprüft. Head-CI separat im Pull Request. Weitere native Ziele/CL, zentrale Nutzung, tatsächliche Minimalrechte, große Nutzdaten-/Heapmatrix und vollständige Produktqualifikation nicht ausgeführt; teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Welle1 / 2.0.0

[Freigegebener Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md):
Computed/PERSISTED, Filter, optional typisierte Extended Properties, zehn Parameter,
sieben SET-Zeilen und TABLE8. Neue Source und Oracles sind kein Runtime-Nachweis.
Neue Runtimefixture: Wave1.Contract.sql (synthetische externe DDL/Typen/Owner/Atomik).
Genuine1.0 aus publicPinfdafa8038e4d5240dd727096f144c8d5fd884117, unveränderte Bytes;
kein zurückversionierter neuer Installer. W1 Runtime: ausgewählter öffentlicher Scope bestanden; CI am geprüften Head 76888216 bestanden; tatsächliche Minimalrechte: NOT_EXECUTED.
Das am2026-10-02 zusätzlich freigegebene Lifecycle-Sichtbarkeitsgate53926/2 wird vor Änderungen und unter AppLock geprüft. Statische sechzehn 0-/NULL-Predicate-Injektionsformen bezeugen die Kopplung am echten Installertext; kein tatsächlicher Lowpriv-Kontext. Die finalen öffentlichen Nativeadapter prüfen beide Lifecycle-Passes mit 0-/NULL-Injektionen und unverändertem Modulbestand. W1-Runtime im ausgewählten öffentlichen Scope und CI am geprüften Head 76888216 bestanden; tatsächliche Lowpriv-Kontexte bleiben offen.

## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

Der dedizierte öffentliche Adapter ist Tests/CI/run-table-clone-wave1-lab.ps1; genuine Artefakte erzeugt Deployment/New-LegacyTestArtifacts.ps1. Für einen reproduzierbaren Lauf sind LegacyDirectory, der erwartete externe Prompt-SHA256 und die exakte Plattform-/Versions-/Patchauswahl anzugeben. Optionale gepaarte ExpectedRunId/JournalPath ermöglichen die Bindung eines unabhängigen Callers; kein latest-Journal wird adoptiert. Der Linux-CI-Shelladapter ist eine getrennte disposable CI-Prüfung.


### Gezielte CI-Prefixkorrektur

Die CI-Diagnose bestätigte auf Linux 2019/2022/2025 jeweils genau eine vollständige Form: ein führendes LF, die drei exakten öffentlichen Kommentarzeilen und der vollständige CREATE-Header mit drei Leerzeichen. Die Predicate-Testfixture akzeptiert zusätzlich ausschließlich diese byteexakte Form; Diagnoseausgabe und zusätzliches Resultset sind wieder entfernt. Bestehende Headerersetzung, Ablehnungs-, Transaktions- und Restoreorakel bleiben unverändert. Die korrigierte Fixture bestand anschließend in erneuten vollständigen öffentlichen Native-Läufen auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL150/160/170 jeweils lokal und zentral, einschließlich eigener Bereinigung und ohne Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. CI am geprüften Head 76888216: alle sieben Checks SUCCESS einschließlich CloneLinux2019/2022/2025. Der Zähler32 bleibt nur der Visibility-Teilbereich; tatsächliche Lowpriv-Kontexte und weitere physische Ziele bleiben offen.

## W2 / 3.0.0 – begrenzte Native-Nachweise

[Map-/FK-Vertrag](../../../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md). V3 verschiebt den Standardtail auf Position9..12; neue Fixtures Wave2.Contract/Safety/Caps sind vorbereitet. Die oben genannten W1-Läufe bleiben historische Version2-Evidenz. Die aktuellen begrenzten V3-Nachweise folgen getrennt.

Die gezielte Caps-Fixture enthält Map64/65, zwei unabhängige1024-Spaltentabellen sowie exakt2048/2049 Childobjekt-/FK-Spaltentupel mit einem nur einmal pro Menge gezählten FK. Ein normaler1025ter Spaltenkatalog ist durch SQL Server nicht herstellbar; dafür wird kein API-Negativnachweis erfunden. Beide Lifecycle-Pässe berücksichtigen außerdem unaufgelöste sameDB-Consumer mit katalogäquivalenten DB-/Schema-/Objektnamen. Die Caps-Fixture gehört zum unten abgegrenzten W2-Teilnachweis. Unresolved-Consumer-Verhalten wurde nicht etabliert.


Am 2026-10-04 bestanden begrenzte private Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal: Clean3 und genuine2→3 mit frischer Session, Repeat, resolved Consumer mit Deploy-/Uninstall-Ablehnung53926/1 und unverändertem Katalogsnapshot/gesunder Transaktion sowie Uninstall/Repeat. Je Lauf wurden zwei eigene Datenbanken entfernt; frische Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Linux: drei W2-Fixtures und eine W1-Regressionsfixture stammen als Teilnachweis aus einem historischen insgesamt fehlgeschlagenen Lauf; der identische Produkt- und Fixturestand wurde wiederverwendet und im finalen Lifecycle-PASS nicht erneut ausgeführt. Windows: dieselben vier Fixtures bestanden einmal in Clean3 im aktuellen erfolgreichen Lauf, nicht erneut im Upgradezyklus. Unresolved Consumer: NOT_ESTABLISHED. Keine vollständige Produktqualifikation; weitere Ziele/CL, zentrale V3-Nutzung, Minimalrechte, übrige Lifecycle-Negativfälle und aktuelle Head-CI bleiben offen. Status bleibt teilweise validiert und unveröffentlicht.
## Datenkopie 4.1 – vorbereitete gezielte Orakel

Copy.Contract.sql und Copy.Safety.sql enthalten zusammen genau fünf gruppierte
synthetische Orakel: Spaltenpositionslücken/KEEP/NULL/Nutzdatenbytes/passende
bestehende FKs; Identity-only DEFAULT VALUES, normale REGENERATE-Kopie und
Self-FK einschließlich verbotener Identity-Beziehung; fehlende zyklische
FK-Zustände/existierender aktiver Zyklus/externe Referenz; Admission-, Form-,
Temp-, Help- und Callergrenzen; spätes ResultTable-CHECK mit gemeinsamem
Rollback von Daten/FK-DDL/Ausgabe. Die Helperprozedur lebt ausschließlich als
lokale Test-Temp-Prozedur. Der Help-Resultset wird nur in der Testfixture mit
INSERT EXEC aufgenommen; Produkt-/Core-Aufrufe verwenden ResultTable.

Lifecycle.Contract.sql bindet vier P-Slots und die Parameterformen
13/14/14/9. Execute.Contract.sql bindet den unveränderten Hash-v1 mit Release4.1.
Der Linux-CI-Adapter führt die fünf neuen Gruppen einmal am höchsten
unterstützten CL je bestehendem Ziel aus. Der öffentliche W1-Labadapter ist
nur an die aktuelle Source-/Lifecycleversion gekoppelt und liefert damit
keinen neuen Copy-Qualifikationsnachweis.

Stand 2026-10-04: Alle fünf Gruppen bestanden auf Linux2019/latest CL150 und
Windows2025/exakt CU8 CL170 jeweils einmal im Cleanzyklus. Clientmetadata mit
fünf typgenauen NOT-NULL-Feldern, EOF/keinem Folgeresult sowie Clean/Repeat,
genuine4.0→4.1 mit frischer Session, vier Copy-Consumer-Ablehnungen53926/1 und
Uninstall/Repeat bestanden. Je zwei eigene Datenbanken entfernt; Inputpins,
Prozesskanäle, Journale und frischer Cleanup-Audit unabhängig physisch geprüft.
Keine Serverkonfigurations-, Rechte-, Owner- oder Truständerungen. Der erste
Linuxfehler51020/1 wurde durch Korrektur des privaten FK-Brückennamens behoben;
der betroffene Scope wurde wiederholt, der Fehlerlauf zählt nicht als PASS.
Separate gezielte Root-Nachweise auf Linux2019 CL150 bestanden: vier dynamische
IDENTITY_INSERT-Fälle mit direkten Before-/After-INSERT-Proben und Caller-
ON-Erhalt; SNAPSHOT-Quellkonsistenz/gehaltene Target-X-Sperren sowie konkurrierend
bestätigter Nichtleerbestand mit Original53944/1, gesunder Session und erhaltenen
Targets. Die Identity-Fälle und der positive SNAPSHOT-Fall wurden als fertige
Teilnachweise aus insgesamt fehlgeschlagenen Adapterläufen bei unveränderten
Produktbytes wiederverwendet; der abschließende isolierte Nichtleer-Lauf bestand.
Adapterfehler266/Rendezvous/Cleanup3701 zählen nicht als PASS. Nur eigene DBs
erhielten journalisiertes SNAPSHOT; Option wiederhergestellt, eigene DBs entfernt,
physische Nachweise und frische Bereinigung unabhängig geprüft. Head-CI separat
im PR. Weitere
Versionen/CL, Minimalrechte, große Nutzdaten-/Heapmatrix und vollständige
Produktqualifikation werden nicht aus diesen fünf Gruppen abgeleitet.
