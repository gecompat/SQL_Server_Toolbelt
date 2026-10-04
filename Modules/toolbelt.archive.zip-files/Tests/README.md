# ZIP-Dateifassaden – Evidenz und Grenzen

Implementation 1.0.0, teilweise validiert, unveröffentlicht. Begrenzte native
Windows-local-Teilnachweise sind vorhanden; vollständige Qualifikation offen.
Statische Sourceprüfungen sind kein Runtime-PASS.
Fachlicher Vertrag: [ZIP_FILES_CONTRACT](../../../Documentation/Architecture/ZIP_FILES_CONTRACT.md).

## Sourceprüfung

```text
python Modules/toolbelt.archive.zip-files/Tests/Static/validate_contract.py
python Tests/Documentation/validate_documentation.py --all
```

Der statische Validator prüft Signaturen, Brückenreservierung, statische
Dependencies, Publish-/SQL-TX-Reihenfolge und Lifecyclecode. Der vollständige
Docaudit ist wegen kanonischer Namingausnahme/Kopplung erforderlich.
Am 2026-10-04 waren der statische Sourcevertrag und der vollständige
Docaudit für 37 Module erfolgreich. Kein SQL-/Provider-/NTFS-Lauf wurde
dabei ausgeführt.

## Runtime

Am 2026-10-04 wurden auf SQL Server 2025/CU8 Windows, CL170, local elf
Fälle in früheren Teilabläufen erfolgreich geprüft: die fünf öffentlichen
SQL-Fixtures Help, InstalledMetadata, Safety, Contract und Atomicity,
Windows-Callerpositive, SQLauth-Ablehnung, Deploy-Repeat, Uninstall-Repeat
sowie die zwei Alias-First-GO-Prüfungen. Anschließend bestanden zwei gezielte
Aliasprüfungen unter AppLock mit denselben Produktbytes und tatsächlichem
Waiter-/Holder-/Resource-/Blocking-Nachweis. Dies sind zusammen 13 getrennte
Fallnachweise, kein erfolgreicher gemeinsamer 13-Fälle-Lauf.

Die früheren fehlgeschlagenen Abläufe bleiben fehlgeschlagen; ihre elf bereits
erfolgreichen Fälle wurden nicht erneut ausgeführt. Nach den Läufen wurden
eigene DB und Root entfernt, zwei Trustzustände wiederhergestellt und die
Abwesenheit frisch geprüft; keine Konfigurations-, SQL-Rechte- oder
Owneränderungen. Native Prozess- und Kanalabschlüsse wurden unabhängig geprüft.

Die unveränderten ZIP-/Filesystem-/ResultTable-Provider wurden wiederverwendet.
Vorhandene begrenzte Caller-/NTFS-Providerbelege sind keine Prüfung jeder
ZIP-Dateifassade unter jeder NTFS-Bedingung. [Matrix](ZIP_FILES_TEST_MATRIX.md)
trennt diese Teilnachweise von offenen ServiceAccount-/NoOverwrite-/Race-,
encrypted-/CRC-/ratio-, sämtlichen KeepData-/doomedTX-/Consumer-/Minimalrechte-
und weiteren Zielmatrix-/aktuellen Head-CI-Nachweisen.

ZipFiles.Atomicity belegt im begrenzten tatsächlichen Lauf nur SQL-
Output-Rollback plus bereits veröffentlichte Datei; keine gemeinsame
SQL-/Dateisystematomarität. Keine Produktionskapazitäts-/Heap-/Hardwallzusage.

Lifecycle.AliasCollision.Setup.sql ist ausschließlich synthetische Vorbereitung
in einer eigenen CI-Test-DB ohne ZIP2-Slots und allein kein PASS. Die begrenzten
nativen Aliasprüfungen konsumierten originale Deploy-/Uninstall-First-GO-Bodies,
verlangten 54634/state1 und vollständige Snapshotgleichheit; die beiden
AppLock-Fälle wurden separat gezielt abgeschlossen.

## Dependency-Markerrollen

Die positive Legacyform verlangt beim ZIP1.4-Reader keine Objekt-ModuleId/Version; Writer und Core bleiben strikt. Die unveränderte Safety-Fixture manipuliert die Writer-Objektversion und verlangt weiter54622/1 mit Restore. Static bindet die vier festen Rollen und den tatsächlichen ZIP1.4-WriterMarkers-Cursor; dies allein ist kein Native-PASS. Die vorhandene Legacyreaderform wurde im begrenzten nativen Contractlauf konsumiert; die negative Writer-Markerfixture bestand ebenfalls.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `Privater begrenzter Windows-local-Lauf und gezielte AppLock-Probes`
- Scope: SQL Server 2025/CU8 Windows, CL170, local: elf Fälle in früheren Teilabläufen erfolgreich, danach zwei gezielte Aliasprüfungen unter AppLock erfolgreich, mit identischen Produktbytes. Zusammen 13 Fallnachweise, kein gemeinsamer 13-Fälle-Erfolgslauf. Fünf SQL-Fixtures, Windows-Caller/SQLauth-Ablehnung, Deploy-/Uninstall-Repeat und Alias-First-GO-/AppLock-Schutz; eigene DB/Root abwesend, zwei Trustzustände wiederhergestellt und frische Prüfung erfolgreich, keine Konfigurations-/Rechte-/Owneränderung. Historische fehlgeschlagene Abläufe bleiben fehlgeschlagen; unveränderte Provider wiederverwendet, keine vollständige ZIP-/NTFS-/Zielmatrix-, Central-/Linux-, Minimalrechte- oder aktuelle Head-CI-Qualifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
