# XLSX-Testmatrix

## Neue 1.1-Typwelle

| Bereich | Tatsächlich ausgeführter Scope | Ergebnis / Grenze |
|---|---|---|
| Zellkern | de-DE/en-US/tr-TR, API-/Numeric-/Temporal-Goldens | 19311 Assertions PASS; kein Heapnachweis |
| Finite Scanner | unabhängiger Vergleich mit historischer Number-/ISO-Grammatik | 12370 Vergleiche PASS |
| Native API/Metadaten | Linux 2019/latest CL150; Windows 2025/CU8 CL150/160/170, jeweils local/central | drei Types-Fixtures + Client-/native Nullability PASS im privaten finalen Adapter |
| Lifecycle | clean/genuine1.0/repeat, Caller OFF/ON intakt/doomed, AppLock, postDROP/preCOMMIT, Kollisionen, historische Zukunftsslots, Consumer/Uninstall | PASS; doomed inline Witness-Topologie, keine SQLCMD-Prozessbehauptung |
| Sichtbarkeit | 0/NULL-Prädikatinjektionen vor/unter AppLock, 51535/2 | PASS synthetisch; tatsächliche Lowpriv-Rollen NOT_EXECUTED |
| Raw→Type | neun synthetische Zellen nach API-CL-Schleifen (2019 CL150, 2025 CL170), zusätzlich zentraler Caller | PASS; kein erneuter vollständiger Raw-Reader-Grenzlauf |
| Eigener Cleanup | frischer schema-/identitätsgebundener eigener Abwesenheitsaudit nach finalem Lauf | PASS; keine Konfigurations-/Rechteänderungen |
| Öffentlicher Adapterport | reproduzierbare Repository-Pfade, bytegleiche fachliche Prüftexte | unabhängiger Review und finale öffentliche Läufe beider ausgewählten Targets vollständig PASS samt frischen eigenen Cleanup-Audits |
| CI | aktueller exakter PR-Head | separat als Mergegate geprüft; keine CI-PASSbehauptung aus dem Nativenachweis |
| Offen | weitere physische Targets, tatsächliche Minimalrechte, Heap-/Produktionskapazität | NOT_EXECUTED; partially validated/unreleased |

Historische FAILED-Adapterstände (214 Trustargument, 51592/3 Caller-Testtopologie, SCRIPT_FAILED expandedCommit-Seam) und ihre separate eigene Bereinigung stehen im Tests-README. Kein Fehllauf wird umgewertet. Alle folgenden Raw-Readernachweise beziehen sich auf den historischen 1.0-Release mit damaligem Binary, nicht pauschal auf den neuen 1.1-Provider.

Historische1.0-Evidenz: `local: Tests/Runtime/Invoke-LabContract.ps1`, 2026-10-02; Linux 2019/latest und Windows 2025/CU8 erfolgreich nach finaler EOF-Formatpflege.

Stand: 2026-10-01; synthetische Fixtures, kein Produktionsdaten-Nachweis.

Fixnachweis 2026-10-02: vollständiger identischer Adapter auf Linux 2019/latest und Windows 2025/CU8 erneut PASS, einschließlich interner Help-Modi 0/1, XLSX-/ZIP-Lifecycle-Callerablehnung bei XACT_ABORT OFF/ON und XLSX-SQLCMD-Fehlerstatus 50000. CLR-Binaries gegenüber den historischen Pässen unverändert. Die nachfolgenden offenen Matrixfälle bleiben offen.

| Bereich | Orakel | Ausführung / Ergebnis |
|---|---|---|
| Build und API-Allowlist | Framework-4.8-Build; Methoden, Konstruktoren, Typeinitializer, Referenzen, Stream-only XmlReader, kein calli/InlineSig/PInvoke | Framework PASS |
| Begrenztes NoIO | Fünf verweigerte Canaries; gültiges Workbook; DTD/externe Relationship abgelehnt | Framework Sandbox PASS; kein OS-Trace |
| SQL SAFE | tatsächliche Aufrufe und SAFE-Katalogbindung | Windows 2025/CU8 und Linux 2019/latest identisches aktuelles Binary PASS |
| Sparse Inhalt | Koordinaten, Hidden/Date1904, Unicode, Rich/SST/Inline, leere/fehlende Werte, Formel/Cache separat | Framework und Windows PASS |
| Strukturfehler | falsche XML-Eltern, doppelte Koordinaten/WorkbookPr, verschachtelte si, fehlende SST, unbekannte Zelltypen | Framework PASS |
| Tatsächliche Grenzfixtures | 100000/100001 Zellen; 8 MiB/+1 UTF-16-Einheit SST | Framework PASS |
| Outputexpansion | exakte reduzierte Chargegrenze/+1; wiederholte große SST; THROW 51520, Ziel unverändert | Framework und Windows PASS |
| Parametergrenzen | alle Ressourcenparameter NULL und Ceiling+1 | Windows SQL PASS |
| Vollgröße übriger Caps | reale 16-MiB-Archiv-/Part-, 64-MiB-Summen-, 256-Part-, 32-Sheet- und 50000-SST-Grenzworkbooks | not executed; Konfigurationsprüfung ist kein Kapazitätsnachweis |
| Öffentliche Metadaten | SELECT, NULL-SELECT, Help, Defaultaufruf, keine Zusatzresultsets | Windows SQLClient PASS |
| Routing | local, central und fremde Caller-Datenbank ohne lokale Provider | Windows PASS |
| ResultTable | Ersetzen/Anhängen, NULL-Noop, Schemafehler 51025, Ziel bei Parserfehler unverändert | Windows PASS |
| Transaktionen | echte CHECK-Fehler 547, OwnTx, Caller-Savepoint, XACT_ABORT OFF/ON | Windows PASS |
| Namespace | reserviertes Ziel/private Caller-Temps vor separater Core-Compilergrenze; Help/NULL-Bypass | Windows PASS; separate explizite CS-/CI-Datenbankmatrix pending |
| Lifecycle | Redeploy, Uninstall, echte ZIP-1.3→1.4-Assemblyhashes, Writer-SQL-Regression | Windows PASS |
| Fremdbestand / Rechte | sämtliche neuen Namenskollisionen, konkurrierender Lifecycle, minimale EXECUTE-Rollen, Help ohne installierte Dependencies | vollständige Matrix not executed |
| Portabilität | übrige SQL-Versionen/Plattformen | not executed; kein Ersatzprovider |
| Ressourcen | Peak-RAM, SQL-Memory-Grant, Tempdb-/Lockmessung, Produktionslast | not executed; keine Zusage |
| Hosted CI | qualification workflow | vorhanden, noch nicht ausgeführt |

Die als Windows-PASS aufgeführten öffentlichen Adapterfälle wurden abschließend mit identischem Binary auch auf Linux 2019/latest erfolgreich ausgeführt, einschließlich local/central/cross-database und der tatsächlichen ZIP-1.3-Upgradefixture. Die Framework-Prüfungen bleiben Framework-Evidenz, keine zusätzlichen SQL-Live-Ceilingmessungen.

Der 128-MiB-Chargecap ist eine interne konservative Zählgrenze, kein vollständiger Speicherpeak. Outputstrings zählen vier Bytes je UTF-16-Codeeinheit und wiederholte Referenzen erneut. Nicht unterbrechbare Framework-/SQL-Operationen liegen außerhalb einer harten Zeitgarantie.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-xlsx-types-lab.ps1`
- Scope: Finaler identischer öffentlicher XLSX1.1-Adapter Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 jeweils local/central: drei Types-Fixtures, SQL-/Client-/native Nullability, clean/genuine1.0/repeat, CallerOFF/ON intakt/doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, synthetische0/NULL-Sichtbarkeitsgates, Consumer/Uninstall; RawType nach API-Schleifen auf letzterCL150/170 plus zentralerCaller. Voller PASS samt frischen eigenen Cleanup-Audits. Keine Konfigurations-/Rechteänderungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Lowpriv-Rechte, übrige physische Targets und Heap/Produktionskapazität offen. Historische FAILED-Adapterstände bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
