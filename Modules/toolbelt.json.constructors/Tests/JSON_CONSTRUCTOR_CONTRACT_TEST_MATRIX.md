# JSON Constructor Testmatrix

## Neue Uninstall-Metadatenvoraussetzung (2026-10-02)

Die einzeln freigegebene fail-closed Voraussetzung wurde nach Umsetzung mit
`Tests/CI/run-json-groups-lab.ps1 -RuntimeTests InstalledMetadata.Contract.sql`
auf Linux 2019/latest und Windows 2025 exakt CU8 jeweils lokal/zentral erneut
geprüft. Beide tatsächlichen Prozesse Exit0; gekoppelte Lifecycle-/Client-/
Consumerprüfungen erfolgreich, private Journale COMPLETE, alle eigenen
Datenbanken entfernt, keine Konfigurations- oder Rechteänderung.
Kein neuer Default-All-PASS und kein tatsächlicher Missing-rights-Nachweis.
Vier neue CI-Injektionen ersetzen je eine Permissionpredicate erst in Pass 1
unter AppLock durch 0 bzw. NULL und verlangen 53622 sowie anschließend intakte
Lifecycle-/InstalledMetadata-Verträge. Diese negativen Injektionen und neue
Exact-head-CI sind noch nicht ausgeführt.

## Additive Gruppenwelle 1.1.0

Vor-Source-Gate als Commit `412dbdd3` festgehalten. Genau zwei neue Fassaden verwenden den bestehenden Kern mit GroupMode.

Am 2026-10-02 bestanden auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal und zentral die fünf Runtime-Fixtures `JsonConstructors.Contract.sql`, `Collation.Contract.sql`, `JsonGroups.Contract.sql`, `JsonGroups.Boundaries.sql` und `InstalledMetadata.Contract.sql` sowie Clientmetadaten. Dazu gehören alte ungruppierte Regression, Unicode-/Literalfälle, Gruppierung, beide Resultschemas, KeepData/Empty-Routing, späte Fehler und echte 100000-Gruppen-/16-MiB-Grenzen. Diese Teilnachweise stammen aus insgesamt fehlgeschlagenen Läufen: Das spätere Central-Orakel meldete 54600/45 wegen einer column_id-Lücke. Sie sind kein vollständiger Adapter-PASS.

Die finalen fokussierten Läufe wählten ausdrücklich nur `-RuntimeTests InstalledMetadata.Contract.sql`. Beide Adapter bestanden lokal und zentral Metadaten, genuine unveränderte 1.0-Upgrades, Repeat, Rollback/Postlock/AppLock, Marker, Future-Slot-Typen, Dependencies, committable/doomed Callertransaktionen mit ON/OFF-Optionen, Central-Bestätigung, den tatsächlichen Consumer am höchsten ausgewählten CL, Uninstall und eigene Bereinigung. Die Wiederherstellungsjournale wurden unabhängig geprüft: abgeschlossen, eigene Datenbanken entfernt, keine Konfigurations- oder Rechteänderung. Daraus wird kein finaler Default-All-Fixtures-PASS abgeleitet.

Frühere fehlgeschlagene Läufe bleiben erhalten: 53609/4 im Escape-Budget-Orakel, 206 im Kollisionsfixture, 3998 im Caller-Batch und 54600/45 im Central-Orakel. Die jeweiligen Test-/Adapterkorrekturen ändern keinen Corevertrag.

Neue Minimalrechte, weitere Zielkombinationen und Produktions-/Parallelkapazität bleiben offen. Die Uninstall-Voraussetzung `VIEW DEFINITION`/`SELECT` wurde am 2026-10-02 einzeln freigegeben; die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen. Aktuelle CI wird als separater PR-Mergegate nachgewiesen. Status `partially validated`, `unreleased`. Historische 1.0-Evidenz unten gilt ausschließlich für die damaligen drei Slots.

## Historische Ausführung 1.0.0

Am 2026-10-01 auf physischen SQL Server2019Linux/latest und2025Windows/CU8
ausgeführt: `local: Tests/CI/run-lab-local.ps1`. Nur der unten beschriebene Scope
ist erfolgreich; vorhandener Testcode allein ist keine weitere Evidenz.

| Scope | Vertrag | Stand |
|---|---|---|
| Values | alle5Kinds, strikte Zahlen ohne Konvertierung, Escaping/Controls, NULL, tatsächliches/decodiertes Unicode | PASS |
| Keys/Ordinals | exakteBytes+Längen, NUL/Duplicates/Case/Spaces, positive unique gaps | PASS |
| Grenzen | Precopy-Metadatengates, exakteBytes/Escapeexpansion, 2/16MiB,100000Entries,Overflow | PASS |
| USP | Helpfirst/Defaults, tatsächliche Client-Resultmetadaten, ResultTable/KeepData, SchemaBlocker, own/caller/doomed Tx | PASS |
| Lifecycle | alle Marker/Hashes, Repeat/local/central, echte registrierte MSTVF-Typdrift repariert, drei Zielnamenskollisionen vor Mutation, fremde Dependency/Uninstall | PASS |
| Collation/Namespace | CS-Datenbank/CI-tempdb, binäre Keys, uppercase reservierter Input/unverwandte private Tempobjekte vor Core-Kompilierung, Helpbypass | PASS |
| Rechte | lokale eingeschränkte EXECUTE-Probe für beide öffentlichen APIs | PASS |
| Rest | 2022,2019Windows,2025Linux,GitHub-hosted, mapped low-privilege CrossDB und Produktions-/Parallelkapazität | not executed |

Risikobasierte Auswahl statt vollständiger neuer Matrix. Admin-CrossDB-Erfolg
beweist keine niedrigprivilegierten gemappten Callerrechte.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-json-groups-lab.ps1 (Uninstall-Metadatenvoraussetzung)`
- Scope: Neue fail-closed Uninstall-Voraussetzung VIEW DEFINITION/SELECT: fokussierter Adapter Exit0 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral; Runtime-Auswahl nur InstalledMetadata.Contract.sql, gekoppelte genuine1.0-/Repeat-/Rollback-/AppLock-/Caller-/Marker-/Future-/Dependency-/Client-/Central-/Uninstallprüfungen PASS. Beide Journale COMPLETE, alle eigenen Datenbanken entfernt, keine Konfigurations-/Rechteänderung. Kein Default-All-PASS, keine tatsächliche Minimalrechtequalifikation; negative synthetische Predicate-Injektionen und neue Exact-head-CI noch nicht ausgeführt. Historische Nachweise bleiben unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
