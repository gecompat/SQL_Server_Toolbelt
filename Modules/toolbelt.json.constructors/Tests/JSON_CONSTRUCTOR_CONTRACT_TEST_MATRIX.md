# JSON Constructor Testmatrix

## CLR-Migration 1.2.0: offene tatsächliche Gates

Source-/Registrykopplung und der unveränderte private Produktbuild sind
offline nachgewiesen. Die beiden lokalen Acht-Fixture-Läufe und das lokale
genuine1.1-Upgrade sind begrenzte native Teilnachweise, keine vollständige
öffentliche 1.2-Qualifikation; genaue Reichweite siehe Tests-README.

| Gate | Geforderter Nachweis | Stand |
|---|---|---|
| Legacy | alle vier APIs,8 Parameter, Helpfirst, globale Priorität, ResultTable/Caller; RawOnly→Original ISJSON→Finalize | Lokale Acht-Fixture-Teilnachweise; vollständiger Umfang offen |
| Bridge | exakt1 Row/8 nullable Felder, Kosten/Phasen/Codeformen, technische53611, Legacytiefe128 ohneAGF127 | Kanonische lokale Fixtures bestanden; weitere Grenzen offen |
| AGFs | leere/gruppierte Ausgabe, Ordnung/Duplikate/Profile, Grenzen/Merge/Serialisierung und Clientmetadaten | Positive lokale Fixture-Proben bestanden; vollständiger Umfang offen |
| Registry | bekannte file1SHA512/ArtifactId,6 exakt typisierte class5-Marker; unbekannter Target-/Installedhash ablehnen | Lokales Upgrade und fünf erste-GO-Markerablehnungen bestanden; weitere Fälle offen |
| Owner/Visibility | kohärente vorhandene Owner, NULL/0 Sicht blockiert vor Mutation und unter Lock; keine Reparatur | Guest-Kontext916/4 und Owneränderung NOT_EXECUTED; weitere Gates offen |
| Lifecycle | genuine1.0/1.1, Repeat, alle8 Slots, Future/Consumer, AppLock/Drift/Rollback, eigenes Uninstall | Windows2025/CU8 CL170: genuine1.1 lokal und genuine1.0 lokal/zentral, Repeat/Uninstall sowie zentrale erste-GO-Bestätigung und originaler Consumer bestanden; übriger Umfang offen |
| Rechte/CI | echte geeignete eingeschränkte Caller ohne GRANT; exakter Head und qualifiziertes Binary | Offen |

Neue Budget-/Unicode-/Literalfehler liefern keine erfolgreiche Teilrow.
Die privaten Offlineproben sind keine SQL-Engine-, Heap-/Spill- oder
Minimalrechtequalifikation; historische Wellen bleiben getrennt.

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
- Datum: `2026-10-04`
- Nachweis: `local: scoped JSON 1.2 qualification`
- Scope: Kanonischer Projektbuild mit MSBuild 18 ohne Profil-Overrides bytegleich zur unabhängig offline qualifizierten bekannten SAFE-Zeile. Lokal acht Original-Fixtures auf Linux2019 CL150 und Windows2025/CU8 CL170. Windows2025/CU8 CL170: genuine1.1 lokal und genuine1.0 lokal/zentral, Repeat, acht Slots/sechs typisierte Marker, Uninstall/Repeat; zentrale erste-GO-Bestätigung und originaler Consumer. Sechs erste-GO-Negativfälle, Guest916/4 und Ownerfall NOT_EXECUTED. Eigene Bereinigung/frische Abwesenheit bestanden, keine Konfigurations-/Rechte-/Owneränderung. Kein vollständiger Produkt-/Matrix-/Minimalrechte-/Heap-/Spillnachweis; aktuelle Exact-head-CI mit ihrem Compilerstand und Release offen. Historische Fehlversuche unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
