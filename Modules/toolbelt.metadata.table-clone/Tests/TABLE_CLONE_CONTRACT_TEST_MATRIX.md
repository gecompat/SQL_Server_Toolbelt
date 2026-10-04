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
- Nachweis: `Begrenzter privater Trigger-Nativeadapter; unabhängige physische Prozess-/Journalprüfung`
- Scope: Version4.0.0: SQL Server 2025 Windows/exakt CU8 CL170 ausschließlich lokal. Beide Trigger-Fixtures einmal in Clean4: Map-/Header-/Qualifier-/CTE-/Aliasumschreibung, UTF16/Kommentare/Literale, SET-/Event-/FIRST-LAST-/Disabledzustand und tatsächliches AFTER-/INSTEAD-Verhalten; sieben atomare Negativfälle einschließlich externer AST-Ablehnung53903/19 und bestehender/geplanter Namenskollisionen. Clean4 und genuine3.1→4 mit frischer Session, Repeat, drei Slots/13-13-14 Parameter, unabhängiger Clienthash mit typgenauer dreispaltiger NOT-NULL/Binary32/EOF-Ausgabe, vier resolved-Consumer-Ablehnungen53926/1 und Uninstall/Repeat bestanden. Zwei eigene Datenbanken entfernt, temporärer exakter Parsertrust wiederhergestellt und vorbestehender ScriptDom-Trust erhalten; frischer Cleanup, vollständige Prozesskanäle/Journale/Inputpins unabhängig physisch geprüft. Keine Konfigurations-, Rechte- oder Owneränderung. Separater Linux2019/latest-CL150-Option0-/4.0-Hash-/Lifecycle-PASS wiederverwendet: nachfolgende Coreänderungen ausschließlich Option1 unabhängig sourcegeprüft, keine erneute Linux-Ausführung oder Linux-Triggerqualifikation behauptet. Frühere Fehlerläufe kein Gesamt-PASS. Weitere native Ziele/CL, zentrale4.0, Minimalrechte, serverweite negative Fixtures und unsichtbare/mehrdeutige Kontexte nicht ausgeführt; unresolved Consumer nicht etabliert. Head-CI separat im PR; teilweise validiert und unveröffentlicht.
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
