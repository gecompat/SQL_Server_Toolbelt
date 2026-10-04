# Testausführung

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
- Nachweis: `Begrenzter privater Executor-Nativeadapter (PowerShell/SqlClient); unabhängige physische Prozess-/Journalprüfung`
- Scope: Version3.1.0: SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal. Je Ziel Clean3.1 und genuine3→3.1 aus unveränderten öffentlichen 3.0-Blobs mit frischer Session, Repeat, drei Releaseobjekte und 12/12/14 Parameter, resolved Consumer mit Deploy-/Uninstall53926/1 und unverändertem Snapshot/gesunder Transaktion, Uninstall/Repeat bestanden. Execute.Contract.sql und Execute.Safety.sql je einmal im erfolgreichen Cleanzyklus: Single/Map, CREATE/DEFER, zyklische/Self-FKs, DB-DDL-Trigger-Gate, später ResultTable-Fehlerrollback, DEFAULT-UDF-Gate, Hash-/Temp-Gates und Caller-TX/Help/SET-Erhalt. Unabhängiger Client-Hash und ein dreispaltiges Result mit genauen SQL-/CLR-Typen, NOT NULL, Binary32, EOF und keinem Folgeresult bestanden. Je zwei eigene Datenbanken entfernt; frischer Cleanup-Audit, vollständige Prozesskanäle und unveränderte Inputpins unabhängig geprüft. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Frühere fehlgeschlagene Läufe sind kein Gesamt-PASS. Serverweite negative Trigger-/Eventnotification-Fixtures, unresolved Consumer, tatsächliche Minimalrechte, weitere native Ziele/CL und zentrale Executor-Nutzung nicht ausgeführt. Head-CI ist separat im Pull Request nachzuweisen; teilweise validiert und unveröffentlicht.
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
