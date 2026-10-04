# ZIP-Dateifassaden – Testmatrix

Sourceprüfungen sind keine SQL-/Windows-/NTFS-Evidenz. Die nativen Teilnachweise
vom 2026-10-04 gelten ausschließlich für Windows SQL Server 2025/CU8, CL170,
local: elf frühere erfolgreiche Fälle und zwei später gezielt erfolgreiche
AppLock-Aliasfälle mit identischen Produktbytes. Kein gemeinsamer 13-Fälle-
Erfolgslauf; keine breitere Provider- oder vollständige Modulqualifikation.

| Scope | Konkretes Orakel / Fixture | Status |
|---|---|---|
| Statisch | zwei Signaturen/Defaults, fünf-/sieben-/vierfeldrige Stages, statische EXECs, Help-/TX-/Publish-Reihenfolge, Brückenschutz, eigener später SQL-TX, zwei Lifecycle-P-Slots | Sourceprüfung separat |
| Help | Help.Contract.sql: beide 12-Feld-Helps, 17/12 Parameter, vier Results; Help vor TX/Dependencies/ResultTable, ignoriert Debug | begrenzter nativer Teilnachweis erfolgreich |
| Metadaten | InstalledMetadata.Contract.sql: exakte P-Slots/29 Parameter/3 statische Providerconsumer; echte Reader-Typen/EOF separat im Nativeplan | begrenzter nativer Teilnachweis erfolgreich |
| API | ZipFiles.Contract.sql: Create, Extract, Readback, KeepData Append/Replace, empty Entry/Archive | begrenzter nativer Teilnachweis erfolgreich |
| Sicherheitspriorität | ZipFiles.Safety.sql: Caller-TX, schemafremde eigene Brückenkollision erhalten, Input-/Output-Identität abgewiesen, geerbtes NULL-Writerlimit vor Publish | begrenzter nativer Teilnachweis erfolgreich |
| Später SQL-Fehler | ZipFiles.Atomicity.sql: Error547, vorherige SQL-Zeile erhalten, veröffentlichte Datei vorhanden | begrenzter nativer Teilnachweis erfolgreich |
| Output | beide direkte SELECT-/ResultTable-Wege und alle vier KeepData-Schema/Data-Kombinationen; EOF/noNext | Contract-Teilnachweise vorhanden; vollständige Ausgabe-/KeepData-Matrix offen |
| ZIP-Negative | encrypted51324, CRC51327, Name/Duplicate/ratio/resource/budget; vorhandenes Target bytegleich, keine neue Datei | not executed |
| Caller-TX | active/doomed vor Arbeit; Help weiterhin rein; keine Caller-Rollbackübernahme | aktive TX-Abweisung in Safety erfolgreich; doomedTX weiter offen |
| NTFS/Identität | Windows-Callerpositive, SQLauthnegative, explizit ServiceAccount; Root/deny/reparse/fehlendesDir | Windows-Caller/SQLauth-Ablehnung erfolgreich; übrige NTFS-/ServiceAccount-Fälle offen |
| Publish | NoOverwrite/Overwrite, Stagecleanup, echte Konkurrenz; bestehendes Target bleibt bei Fehler erhalten | not executed |
| Lifecycle | clean/repeat/uninstall/repeat, fehlende Dependencies, partial/future marker, fremde P/PC und kollationgleiche abweichende Namen (Lifecycle.AliasCollision.Setup.sql + originale First-GO-Probes 54634/state1 und vollständiger Snapshot), Consumerblockade, AppLock/Rollback | Repeat/Uninstall-Repeat und vier Aliasprüfungen erfolgreich; weitere Negativ-/Consumer-/Rollbackfälle offen |
| Plattform | Windows2019/2022/2025 CL150/160/170 jeweils tatsächlich ausgewählte Kombination; Ceiling/Minimalrechte/CI separat | Windows2025/CU8 CL170 local teilweise validiert; übrige Kombinationen und CI offen |
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

Dependency-Interop: vier feste RequireObjectMarkers-Rollen (Writer/Core1, Legacyreader/FS0), DB-Version/P-Slot weiter verpflichtend; ZIP/Core-DBMode und Core-ObjMode unverändert. Positive native Legacyreader-Nutzung und unveränderte negative Writer-Markerfixture im begrenzten Lauf erfolgreich; weitere Dependency-Negative bleiben offen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater begrenzter Windows-local-Lauf und gezielte AppLock-Probes`
- Scope: SQL Server 2025/CU8 Windows, CL170, local: elf Fälle in früheren Teilabläufen erfolgreich, danach zwei gezielte Aliasprüfungen unter AppLock erfolgreich, mit identischen Produktbytes. Zusammen 13 Fallnachweise, kein gemeinsamer 13-Fälle-Erfolgslauf. Fünf SQL-Fixtures, Windows-Caller/SQLauth-Ablehnung, Deploy-/Uninstall-Repeat und Alias-First-GO-/AppLock-Schutz; eigene DB/Root abwesend, zwei Trustzustände wiederhergestellt und frische Prüfung erfolgreich, keine Konfigurations-/Rechte-/Owneränderung. Historische fehlgeschlagene Abläufe bleiben fehlgeschlagen; unveränderte Provider wiederverwendet, keine vollständige ZIP-/NTFS-/Zielmatrix-, Central-/Linux-, Minimalrechte- oder aktuelle Head-CI-Qualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
