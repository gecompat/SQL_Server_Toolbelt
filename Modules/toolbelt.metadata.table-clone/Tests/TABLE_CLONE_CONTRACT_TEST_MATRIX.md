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
- Nachweis: `Source-only W2; Runtime und aktueller CI-Head noch offen`
- Scope: V3 Map-/FK-Erweiterung; keine neue Nativequalifikation aus historischen W1-Läufen.
- Ergebnis: `not executed`
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

## W2 / V3 – noch nicht ausgeführte neue Gates

| Scope | Konkreter Oracle | Status |
|---|---|---|
| Map / Ordnung | zwei gemappte Tabellen, Lücken/umgekehrte Inputordnung, alle TABLEs vor Schlüsseln, EP vor FK, States zuletzt | Source vorbereitet; Native offen |
| FK | Composite constraint_column_id, Self-FK und Zweizyklus; interne Umleitung/externe KEEP; trusted/untrusted/disabled, Aktionen/NFR, unabhängiger Zielkatalog | Wave2.Contract.sql; Native offen |
| Properties | originaler decimal sql_variant/Metadaten; FK-EP bei Include1 Unsupported10; Include0 W1-strikt | Contract/Safety; Native offen |
| Map / Atomik | REJECT13, sameObject Input/Output, doppelte aufgelöste Source9; Sentinel/Map/TC/XS erhalten | Wave2.Safety.sql; Native offen |
| Quoten | Map64/65 mit unabhängigen Quellen; 2048/2049 Objekt+FK-Spaltentupel mit FK-Dedup, zwei getrennte1024-Spaltentabellen, getrennte128/2MiB | Wave2.Caps.sql plus Static vorbereitet; SQL noch nicht ausgeführt, weitere128/2MiB-Grenzläufe offen |
| Weitere Negativfälle | Schema-/Ordinal-/NUL-/129Units/Targetalias, disabledtrusted, späte FK-/Namensfehler, intact/doomedCaller und alleKeepData | teilweise Sourcekopplung; umfassende Native-Orakel offen |
| Lifecycle | genuine2→3, clean/repeat/uninstall, lokale/centrale Consumer-/Slot-/Marker-/AppLock-Negative | historische V2 nicht aufV3 übertragen; offen |
| Aktueller Head | Source/static/docs vorhanden; GitHub/physischeVersion-/CL-Matrix/Minrechte | offen |

Die source-only Kopplungsprüfungen sind kein tatsächlicher Nachweis einer disabled/trusted Catalogform oder 2048-Metadatengrenze. W1-Fixturedateien bleiben unverändert; nur der aktuelle Lifecycle-/Helpmetadata-Versionsvertrag ist aufV3 gekoppelt.
