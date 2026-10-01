# JSON Constructor Testmatrix

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
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019 Linux/latest und 2025 Windows/CU8; local/central, Typ-/Literal-/Unicode-/Grenz-/Help-/ResultTable-/Transaktions-/Clientmetadaten-, CS/CI-Namespace-, lokale Minimalrechte-, Repeat-/Marker-/Hash-/TF-Drift-/Kollisions-/Uninstall-Contracts; 16 MiB Ergebnis und 100000 Entries. Weitere Ziele, GitHub und CrossDB-Minimalrechte nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
