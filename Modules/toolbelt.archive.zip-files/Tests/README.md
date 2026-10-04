# ZIP-Dateifassaden – Evidenz und Grenzen

Implementation 1.0.0, unveröffentlicht. Aktuell kein SQL-/Native-/NTFS-
Lauf des neuen Moduls. Statische Sourceprüfungen sind kein Runtime-PASS.
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

[Matrix](ZIP_FILES_TEST_MATRIX.md) registriert fünf SQL-Fixtures und weitere
notwendige Native-/Client-/Lifecycle-/NTFS-Orakel. SELECT-Typen/EOF,
Caller Windows/SQLauth, ServiceAccount, NoOverwrite/Races, encrypted/CRC/ratio,
alle KeepData-Zustände, doomedTX, Cleanup, Providerconsumer und echte
Zielmatrix bleiben offen. Vorhandene Provider-Teilnachweise werden nicht
als ZIP-Dateifassaden-PASS umgedeutet.

ZipFiles.Atomicity beweist bei späterer tatsächlicher Ausführung nur SQL-
Output-Rollback plus bereits veröffentlichte Datei; keine gemeinsame
SQL-/Dateisystematomarität. Keine Produktionskapazitäts-/Heap-/Hardwallzusage.

Lifecycle.AliasCollision.Setup.sql ist ausschließlich synthetische Vorbereitung
in einer eigenen CI-Test-DB ohne ZIP2-Slots. Es zählt nicht als PASS; der
Nativeadapter muss originale Deploy-/Uninstall-First-GO-Bodies, 54634/state1
und vollständige Snapshotgleichheit getrennt prüfen.
