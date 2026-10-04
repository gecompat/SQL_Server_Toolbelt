# Table Clone Testmatrix – historische V1-Evidenz

## Trigger 4.0 – gezielter Nachweis

| Scope | Oracle | Ausführung |
|---|---|---|
| Drei Trigger auf zwei Mapquellen, exakte Namen und umgeschriebener Body, Unicode/Literale/Kommentare, CTE/Alias, Zustände und echte DML-Wirkung | `Runtime/Trigger.Contract.sql` | Windows2025/exakt CU8 CL170 lokal PASS am2026-10-04, einmal Clean4 |
| EXEC, nicht gemappte/ungelöste/externe Referenz, Verschlüsselung und Namenskollision; Sentinel/Callerzustand erhalten | `Runtime/Trigger.Safety.sql` | Dasselbe Windowsziel PASS; externe Systemkatalogreferenz durch AST53903/19 abgelehnt |
| Planner13/Executor14, Release4.0-Hash, Option0 ohne Parser und genuine3.1→4.0 | Begrenzter privater Nativeadapter | Windowsziel PASS; Linux2019/latest CL150 separater Option0-/Lifecycle-PASS wiederverwendet, spätere Änderungen nur Option1 |
| Unsichtbare/mehrdeutige Bindung, weitere native Ziele/CL und zentraler Triggerpfad | Keine Ableitung aus historischen Teilnachweisen | Nicht ausgeführt |

Der [Triggervertrag](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
grenzt die Welle ab. Historische Nachweise unten bleiben ihren Releases zugeordnet.

## Executor 3.1 – neue gezielte Welle

| Scope | Oracle | Ausführung |
|---|---|---|
| Signatur14, Hash-/Modus-/Lifecyclekopplung | `Static/validate_contract.py` | Static bestanden; kein SQL-Nachweis |
| Single/Map, CREATE/DEFER, zyklische/Self-FKs, DB-DDL-Trigger, spätes ResultTable-Rollback, DEFAULT-UDF-Ablehnung | `Runtime/Execute.Contract.sql` | PASS2019Linux CL150/2025Windows exaktCU8 CL170, je einmal Clean3.1 |
| Hashlänge/Mismatch, fremde/aliasierte Tempbrücken, gesunder Caller-TX/Help/SET-Erhalt | `Runtime/Execute.Safety.sql` | Dieselben beiden Ziele PASS, je einmal Clean3.1 |
| Drei aktuelle Releaseobjekte, 12/12/14 Parameter, genuine3→3.1/Repeat/Consumer/Uninstall | Gezielter privater Lifecycleadapter | Dieselben beiden Ziele PASS; öffentliche `Lifecycle.Contract.sql` hier nicht ausgeführt |
| Unabhängiger Client-Hash/typgenaues dreispaltiges Result/NOT-NULL/Binary32/EOF | Gezielter privater Clientadapter | Dieselben beiden Ziele PASS, je einmal Clean3.1 |
| Serverweiter negativer Trigger-/Eventnotification-Fall, Minimalrechte, weitere native Ziele/central | Keine Ableitung aus Teilnachweisen | Nicht ausgeführt; Head-CI separat im PR |

Die folgenden V1- und späteren V2-/V3-Abschnitte bleiben historische
Nachweise ihrer jeweiligen Produktstände; sie qualifizieren den Executor nicht.

## Historische V1-Matrix

| Scope | Vorhandener Oracle | Ausführung |
|---|---|---|
| Structure | synthetische externe DDL-Ausführung; Columns/Defaults/Checks/Indexkeys/INCLUDE/Richtung/Options/Identity; keine Datenkopie | PASS2019Linux/2025Windows |
| Naming | Determinismus, Kollision, Injectionidentifier,128/129Units/NUL | PASS2019Linux/2025Windows |
| Unsupported | Computed/Sparse/filteredIndex/sequentialKeyON/disabledCheck/EP/Trigger/incomingFK/Compression vor ResultTable-Mutation | PASS2019Linux/2025Windows |
| USP | Help/SELECT/Metadata, reservedOutput lower/uppercase vor Kernkompilierung, Replace/Append/SchemaBlocker/own/callerSavepoint/doomed | PASS2019Linux/2025Windows |
| Lifecycle | install/repeat/P-TFdrift/allMarkerHash/twoCI-caseCollisions/foreignConsumer/uninstall | PASS2019Linux/2025Windows |
| Caller Lifecycle | Deploy/Uninstall ON/OFF Count/State/Daten/Marker unverändert; SQLCMD Nonzeroexit | PASS2019Linux/2025Windows |
| Rights | eingeschränkter lokaler Caller mit DBweiter VIEW DEFINITION, verweigerte Sicht, hidden-incoming-FK atomar53901/vollsicht53903, adminCrossDB | PASS2019Linux/2025Windows |
| Platforms | risikobasiert2019Linux/latest CL150 und2025Windows/CU8 CL150/160/170; keine vollständige6Matrix | PASS ausgewählter Scope |

Keine realen Quell-DDL/Rohlogs als Evidence. Weitere Unsupportedfeatures benötigen
zusätzliche gezielte synthetische Oracles vor Statusaufwertung; kein vollständiges
SMO-/DacFx-Kompatibilitätsversprechen oder Produktions-/Parallelitätsnachweis.
CHANGE_TRACKING, LOCK_ESCALATION und andere nicht gelistete Tabellenoptionen:
Erhalt nicht qualifiziert, kein vollständiges Cloneframework.

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

### datetimeoffset-Produktpfadregression

`Wave1.DateTimeOffset.sql`: 18 separat typisierte Originale (Skala0/3/7,
Offset0/+05:30/-12:34, Bruchteile1234567/9999999), Rundungsuebertrag vorAPI,
oeffentlicher ScriptOnly-Plan/externeTestausfuehrung und beide Richtungen
Name-/Wertbytes plus alle fuenf Variantmetadaten gegen gespeicherteSource.
Nativeausführung dieser separaten Fixture im finalen öffentlichen Scope bestanden; kein Formatter-only- oder historische27-Typ-Fixture-Nachweis.

## Finaler öffentlicher W1-Nachweis 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

## W2 / V3 – begrenzte Nachweise 2026-10-04

Am 2026-10-04 bestanden begrenzte private Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal: Clean3 und genuine2→3 mit frischer Session, Repeat, resolved Consumer mit Deploy-/Uninstall-Ablehnung53926/1 und unverändertem Katalogsnapshot/gesunder Transaktion sowie Uninstall/Repeat. Je Lauf wurden zwei eigene Datenbanken entfernt; frische Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Linux: drei W2-Fixtures und eine W1-Regressionsfixture stammen als Teilnachweis aus einem historischen insgesamt fehlgeschlagenen Lauf; der identische Produkt- und Fixturestand wurde wiederverwendet und im finalen Lifecycle-PASS nicht erneut ausgeführt. Windows: dieselben vier Fixtures bestanden einmal in Clean3 im aktuellen erfolgreichen Lauf, nicht erneut im Upgradezyklus. Unresolved Consumer: NOT_ESTABLISHED. Keine vollständige Produktqualifikation; weitere Ziele/CL, zentrale V3-Nutzung, Minimalrechte, übrige Lifecycle-Negativfälle und aktuelle Head-CI bleiben offen. Status bleibt teilweise validiert und unveröffentlicht.

| Scope | Nachweis | Grenze |
|---|---|---|
| Contract/Safety/Caps + W1-Regressionsfixture | Linux historischer Teilnachweis; Windows aktueller Clean3-PASS | Kein Gesamt-PASS des historischen Linux-Laufs |
| Clean3/genuine2→3, Repeat, Uninstall/Repeat | Beide ausgewählten lokalen Ziele PASS | Weitere Versionen/CL/central offen |
| Resolved Consumer | Beide Zyklen je Deploy/Uninstall53926/1, Snapshot/TC0 erhalten | Unresolved NOT_ESTABLISHED |
| Cleanup | Zwei eigene Datenbanken je Lauf entfernt, frischer Audit PASS | Keine Rechte-/Config-/Owner-/Truständerungen |
| Übrige Matrix, Minimalrechte, aktuelle Head-CI | Nicht aus diesen Nachweisen abgeleitet | OFFEN |

Die Caps-Fixture umfasst Map64/65, zwei getrennte1024-Spaltentabellen sowie2048/2049 Childobjekt-/FK-Spaltentupel mit FK-Dedup. Ein normaler1025ter Spaltenkatalog ist nicht herstellbar; dafür wird kein Negativnachweis behauptet. Separate zusätzliche128Index-/2MiB-Grenzläufe, umfassende KeepData-/Caller-/Namespace-Negativfälle und disabled/trusted-Sonderformen bleiben offen.
## Copy4.1 – fünf gezielt ausgeführte Gruppen

| Gruppe | Gezieltes Orakel | Stand |
|---|---|---|
| 1 | Spaltenpositionen trotz unterschiedlicher column_id-Lücken; KEEP, NULL, exakte29 Nutzdatenbytes, bestehender passender FK | PASS Linux2019 CL150 / Windows2025 exaktCU8 CL170 |
| 2 | Identity-only drei DEFAULT VALUES/0Bytes; normale REGENERATE-Kopie; Self-FK KEEP und Identity-Beziehungsablehnung | Dieselben Ziele PASS |
| 3 | Fehlende zyklische FKs nach Copy mit erhaltenen Zuständen; bestehender aktiver Zyklus und externe Referenz abgelehnt | Dieselben Ziele PASS |
| 4 | Globale Rows/Bytes, Form, nichtleeres Target, zusätzlicher Target-FK, fremde Core-/FK-Temps; Help/Caller-TX/SET | Dieselben Ziele PASS |
| 5 | Spätes ResultTable-CHECK: Original547, eigene Daten/FK-DDL/Ausgabe gemeinsam zurückgerollt | Dieselben Ziele PASS |

Lifecycle-Metadaten: vier P-Slots 13/14/14/9 und Release4.1-Sourcehashes.
Der Executor behält Hash-v1 und14 Parameter; nur die Releasebindung ist4.1.
Alle Gruppen einmal je Cleanzyklus am2026-10-04. Clean/Repeat, genuine4.0→4.1,
Copy-Consumer-Gates, Uninstall/Repeat und typgenaue Clientmetadata/EOF bestanden;
eigene Bereinigung und physische Nachweise unabhängig geprüft.
Vier dynamische Identity-Scope-/Caller-ON-Fälle sowie SNAPSHOT-Quellkonsistenz,
gehaltene Target-X-Sperren und aktuelles Nichtleer-Gate53944/1 auf Linux2019
CL150 separat nachgewiesen. Identity und positiver SNAPSHOT-Fall sind fertige
Teilnachweise aus insgesamt fehlgeschlagenen Adapterläufen; unveränderte
Produktbytes geprüft, keine Wiederholung. Isolierter Nichtleer-Lauf vollständig
bestanden; eigene DB-Option wiederhergestellt, DBs entfernt und physische
Nachweise/Bereinigung unabhängig geprüft. Head-CI separat im PR.
Keine unveränderte Vollmatrix erneut,
keine Head-CI-/Lowpriv-/Heap-/weitere Plattformbehauptung aus Testcode.
