# ZIP-Dateifassaden – Testmatrix

Sourceprüfungen sind keine SQL-/Windows-/NTFS-Evidenz. Alle Runtimezeilen
stehen zunächst auf not executed, keine breitere Providerqualifikation übernommen.

| Scope | Konkretes Orakel / Fixture | Status |
|---|---|---|
| Statisch | zwei Signaturen/Defaults, fünf-/sieben-/vierfeldrige Stages, statische EXECs, Help-/TX-/Publish-Reihenfolge, Brückenschutz, eigener später SQL-TX, zwei Lifecycle-P-Slots | Sourceprüfung separat |
| Help | Help.Contract.sql: beide 12-Feld-Helps, 17/12 Parameter, vier Results; Help vor TX/Dependencies/ResultTable, ignoriert Debug | not executed |
| Metadaten | InstalledMetadata.Contract.sql: exakte P-Slots/29 Parameter/3 statische Providerconsumer; echte Reader-Typen/EOF separat im Nativeplan | not executed |
| API | ZipFiles.Contract.sql: Create, Extract, Readback, KeepData Append/Replace, empty Entry/Archive | not executed |
| Sicherheitspriorität | ZipFiles.Safety.sql: Caller-TX, schemafremde eigene Brückenkollision erhalten, Input-/Output-Identität abgewiesen, geerbtes NULL-Writerlimit vor Publish | not executed |
| Später SQL-Fehler | ZipFiles.Atomicity.sql: Error547, vorherige SQL-Zeile erhalten, veröffentlichte Datei vorhanden | not executed |
| Output | beide direkte SELECT-/ResultTable-Wege und alle vier KeepData-Schema/Data-Kombinationen; EOF/noNext | not executed |
| ZIP-Negative | encrypted51324, CRC51327, Name/Duplicate/ratio/resource/budget; vorhandenes Target bytegleich, keine neue Datei | not executed |
| Caller-TX | active/doomed vor Arbeit; Help weiterhin rein; keine Caller-Rollbackübernahme | not executed |
| NTFS/Identität | Windows-Callerpositive, SQLauthnegative, explizit ServiceAccount; Root/deny/reparse/fehlendesDir | not executed |
| Publish | NoOverwrite/Overwrite, Stagecleanup, echte Konkurrenz; bestehendes Target bleibt bei Fehler erhalten | not executed |
| Lifecycle | clean/repeat/uninstall/repeat, fehlende Dependencies, partial/future marker, fremde P/PC und kollationgleiche abweichende Namen (Lifecycle.AliasCollision.Setup.sql + originale First-GO-Probes 54634/state1 und vollständiger Snapshot), Consumerblockade, AppLock/Rollback | not executed |
| Plattform | Windows2019/2022/2025 CL150/160/170 jeweils tatsächlich ausgewählte Kombination; Ceiling/Minimalrechte/CI separat | not executed |
| Linux/Central | vorhandener Windows-only/local_required Filesystemvertrag | not applicable |

## Sichere spätere Durchführung

Nur schema-validiertes ausdrücklich ausgewähltes READY-Ziel, private eigene
GUID-DB/Root-/Dateituples/Trust-Vorzustände mit Wiederherstellungsjournal.
Root-Alias der synthetischen Fixtures: ContosoZipFiles; eigenes existierendes
Testverzeichnis, keine realen Daten/Roots. Root koordiniert tatsächliche SQL-
und NTFS-Ausführung; keine implizite Rechte-/Config-/Providerfreigabe.
Dateinamen sind endlich: contract.zip, hello.txt, empty.txt, empty.zip und
published-before-sql-error.zip. Vorzustand/Ownmarker prüfen, eigene Dateien
nur nach frischer Identitätsprüfung entfernen. ACLtests ausschließlich eigene
Fixtures, jede eigene Änderung wiederherstellen. Kein Runtimepayload ins Repo.
Nativeplan bindet auch vorhandenen ZIP-/Filesystem-/ResultTablecode/Artefakte;
ein Sourcefixture allein beweist keinen sauberen Host-/Gastabschluss.
