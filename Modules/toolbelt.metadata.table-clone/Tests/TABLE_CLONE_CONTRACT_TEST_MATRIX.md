# Table Clone Testmatrix – historische V1-Evidenz

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
- Nachweis: `Begrenzte private W2-Nativeadapter; physische Prozess-/Journalprüfung und frischer Cleanup-Audit`
- Scope: Am 2026-10-04 bestanden begrenzte private Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal: Clean3 und genuine2→3 mit frischer Session, Repeat, resolved Consumer mit Deploy-/Uninstall-Ablehnung53926/1 und unverändertem Katalogsnapshot/gesunder Transaktion sowie Uninstall/Repeat. Je Lauf wurden zwei eigene Datenbanken entfernt; frische Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Linux: drei W2-Fixtures und eine W1-Regressionsfixture stammen als Teilnachweis aus einem historischen insgesamt fehlgeschlagenen Lauf; der identische Produkt- und Fixturestand wurde wiederverwendet und im finalen Lifecycle-PASS nicht erneut ausgeführt. Windows: dieselben vier Fixtures bestanden einmal in Clean3 im aktuellen erfolgreichen Lauf, nicht erneut im Upgradezyklus. Unresolved Consumer: NOT_ESTABLISHED. Keine vollständige Produktqualifikation; weitere Ziele/CL, zentrale V3-Nutzung, Minimalrechte, übrige Lifecycle-Negativfälle und aktuelle Head-CI bleiben offen. Status bleibt teilweise validiert und unveröffentlicht.
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
