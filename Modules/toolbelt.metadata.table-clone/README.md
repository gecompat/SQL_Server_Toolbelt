# Table Clone Planner, Executor und Datenkopie

Release4.1 ergänzt die einzeln freigegebene
[`USP_CopyTableCloneData`](Documentation/USP_CopyTableCloneData.md): SameDB-Map,
leere formgleiche Ziele, KEEP/REGENERATE und vorhandenes SNAPSHOT/SERIALIZABLE.
Neun Parameter, fünf NOT-NULL-Summaryfelder;100000 Zeilen/16MiB global nur
absenkbar. Bestehende passende FKs bleiben unverändert, fehlende werden nach
Copy angelegt; eigene Transaktion, kein RESEED, keine Constraint-Deaktivierung
oder Rechteerteilung. [Vertrag](../../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md).
Normaler Copy-/Client-/Lifecycle-Scope auf Linux2019 und Windows2025/CU8
bestanden; vier dynamische Identity-Zustände und zwei SNAPSHOT-Konkurrenzfälle
separat auf Linux2019 geprüft. Abgeschlossene Teilnachweise aus Fehlerläufen
bleiben getrennt; Head-CI gesondert im PR. Historische Planner-/Executor-Evidenz
qualifiziert diese Erweiterung nicht.
Vier Slots13/14/14/9, interner Zweckpfad
COPY_FK; öffentliche Planner-/Executor-Signaturen bleiben erhalten.

`toolbelt_metadata.USP_ScriptTableClone` liefert eine geordnete DDL-Vorschau;
dieser Planner führt niemals DDL aus und kopiert keine Daten.
Siehe [Objektvertrag](Documentation/USP_ScriptTableClone.md),
[Architektur](../../Documentation/Architecture/TABLE_CLONE_PROPOSAL.md)
und [Testmatrix](Tests/TABLE_CLONE_CONTRACT_TEST_MATRIX.md).

Version3.1 ergänzt separat
[`USP_ExecuteTableClone`](Documentation/USP_ExecuteTableClone.md): frischer
kanonischer Plan, expliziter erwarteter Hash, ausschließlich neue SameDB-Ziele,
eigene Transaktion und vorhandene DB-/Servervollsicht. CREATE führt den ganzen
Plan aus; DEFER schiebt nur FK-/FK-Statezeilen auf. Keine Datenkopie,
Rechteerteilung oder externe Atomikzusage. Der
[Executor-Vertrag](../../Documentation/Architecture/TABLE_CLONE_EXECUTE_CONTRACT.md)
und das [Client-Hashbeispiel](Examples/CalculatePlanHash.py) sind gekoppelt.
Die gezielten lokalen 3.1-Nachweise sind bestanden; der genaue Scope und
die offenen Nachweise stehen im Manifest. V1/V2/V3-Evidenz bleibt historisch.

Die freigegebene [Trigger-Welle](../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
ergänzt für Version4.0 den Plannerparameter `IncludeTriggers bit = 0` an Position9;
der Standardtail steht damit an Position10..13. Der Executor behält14 Parameter
und führt weiterhin keine Trigger aus. Nur das ausdrückliche Windows-Opt-in
verwendet den separat installierten Parser2.0 für eine begrenzte AST-Vorschau.
Trigger-Source, Statik und unabhängige Coreprüfung sind abgeschlossen;
der begrenzte Windows2025/CU8-Triggernachweis und der separate Linux2019-Option0-/Lifecycle-Nachweis sind bestanden.
Details und verbleibende Grenzen stehen im [Triggervertrag](../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md); Head-CI wird separat im PR nachgewiesen.
Historische3.1-Ergebnisse qualifizieren diese Erweiterung nicht.

Installieren nach `toolbelt.core.result-table >=1.0.0`, aus `Deployment`:
`sqlcmd -b -i Deploy.sql -v DeploymentMode=local`.
Uninstall: `sqlcmd -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`;
central benötigt ausdrückliche Betreiberbestätigung1.
Deploy und Uninstall lehnen aktive Caller-Transaktionen vor SET-/Temp-DDL ab:
Enginefehler50000 mit `TBX_TABLE_CLONE_CALLER_TRANSACTION`, nichtdoomendes
RAISERROR+RETURN; SQLCMD `:On Error exit` beendet den Scriptlauf.
Lokaler und zentraler Modus verwenden denselben Kern. Quelle/Ziel gehören
immer zur Installationsdatenbank; dreiteiliger Aufruf verschiebt diese nicht
in die Caller-Datenbank. Kein Wrapper über fremde Metadaten/Permissions.

Status und Evidenz sind ausschließlich im [Manifest](module.yaml) kanonisch.
Historische V1-Nachweise bleiben getrennt; Welle1/2.0.0 ist teilweise validiert und unveröffentlicht.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Begrenzter privater Datenkopie-Nativeadapter (PowerShell/SqlClient); unabhängige physische Prozess-/Journalprüfung`
- Scope: Version4.1.0, normaler Scope: SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 ausschließlich lokal. Copy.Contract.sql und Copy.Safety.sql mit fünf gruppierten Form-/KEEP-/REGENERATE-/Self-FK-/Byte-/FK-Zustands-/Safety-/Rollback-Orakeln je einmal Clean4.1 bestanden. Clean/Repeat, genuine4.0→4.1 aus unveränderten öffentlichen Blobs mit frischer Session, vier Slots13/14/14/9, vier resolved-Copy-Consumer-Ablehnungen53926/1, Uninstall/Repeat und fünffeldrige Clientausgabe mit genauen SQL-/CLR-Typen, NOT NULL, exakten Werten, EOF und keinem Folgeresult bestanden. Je zwei eigene Datenbanken entfernt; vollständige Prozesskanäle, Inputpins, Journale und frischer Cleanup-Audit unabhängig physisch geprüft. Keine Serverkonfigurations-, Rechte-, Owner- oder Truständerungen. Erster Linuxfehler51020/1 nach Installation kein PASS: privater FK-Brückenname korrigiert, betroffener Scope wiederholt. Zusätzlich auf Linux2019/latest CL150 vier dynamische Identity-Fälle bestanden: KEEP bei ursprünglichem OFF, spätes CHECK547 mit Rollback, vorbestehendes Target-ON und Other-ON mit Original8107; direkte INSERT-Proben in derselben Verbindung, Caller-TX/SET sowie vier typgenaue NOT-NULL-Witnesszeilen/EOF geprüft. SNAPSHOT-Quellkonsistenz und bis Ende gehaltene Targetsperren durch tatsächliche Sperrbeziehungen und konkurrierende Writes belegt; isolierter Nichtleer-Lauf beobachtet Blockierung und Original53944/1 mit gesunder Session und erhaltenen Targets. Identity und positiver SNAPSHOT-Fall sind abgeschlossene Teilnachweise aus insgesamt fehlgeschlagenen Adapterläufen; unveränderte Produktbytes geprüft und erfolgreiche Fälle nicht wiederholt. Adapterfehler266, Nichtleer-Rendezvous und Cleanup3701 kein PASS. SNAPSHOT ausschließlich in eigenen synthetischen DBs privat journalisiert, vorbereitet, wiederhergestellt; eigene DBs entfernt und Prozesskanäle/Pins/Journale/frische Bereinigung unabhängig physisch geprüft. Head-CI separat im Pull Request. Weitere native Ziele/CL, zentrale Nutzung, tatsächliche Minimalrechte, große Nutzdaten-/Heapmatrix und vollständige Produktqualifikation nicht ausgeführt; teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Welle1 / 2.0.0

[Freigegebener Vertrag](../../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md):
Computed/PERSISTED, Filter, optional typisierte Extended Properties, zehn Parameter,
sieben SET-Zeilen und TABLE8. Neue Source und Oracles sind kein Runtime-Nachweis.
Neue Runtimefixture: Wave1.Contract.sql (synthetische externe DDL/Typen/Owner/Atomik).
Genuine1.0 aus publicPinfdafa8038e4d5240dd727096f144c8d5fd884117, unveränderte Bytes;
kein zurückversionierter neuer Installer. W1 Runtime: ausgewählter öffentlicher Scope bestanden; CI am geprüften Head 76888216 bestanden; tatsächliche Minimalrechte: NOT_EXECUTED.
## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

## W2 / 3.0.0 – begrenzte Native-Nachweise

[Map-/FK-Vertrag](../../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md). V3 verschiebt den Standardtail auf Position9..12; neue Fixtures Wave2.Contract/Safety/Caps sind vorbereitet. Die oben genannten W1-Läufe bleiben historische Version2-Evidenz. Die aktuellen begrenzten V3-Nachweise folgen getrennt.


Am 2026-10-04 bestanden begrenzte private Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal: Clean3 und genuine2→3 mit frischer Session, Repeat, resolved Consumer mit Deploy-/Uninstall-Ablehnung53926/1 und unverändertem Katalogsnapshot/gesunder Transaktion sowie Uninstall/Repeat. Je Lauf wurden zwei eigene Datenbanken entfernt; frische Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Linux: drei W2-Fixtures und eine W1-Regressionsfixture stammen als Teilnachweis aus einem historischen insgesamt fehlgeschlagenen Lauf; der identische Produkt- und Fixturestand wurde wiederverwendet und im finalen Lifecycle-PASS nicht erneut ausgeführt. Windows: dieselben vier Fixtures bestanden einmal in Clean3 im aktuellen erfolgreichen Lauf, nicht erneut im Upgradezyklus. Unresolved Consumer: NOT_ESTABLISHED. Keine vollständige Produktqualifikation; weitere Ziele/CL, zentrale V3-Nutzung, Minimalrechte, übrige Lifecycle-Negativfälle und aktuelle Head-CI bleiben offen. Status bleibt teilweise validiert und unveröffentlicht.
