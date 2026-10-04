# Phonetik – Testmatrix

Version 1.0.0 unreleased. Alle Runtime-/Framework-/CI-Zeilen sind NOT_EXECUTED.
Source-Review und statische Prüfungen werden getrennt dokumentiert.

| Scope | Gezielter Nachweis | Status |
|---|---|---|
| Algorithmen | Kurze Primärreferenzgoldens, vollständiger Code >4, terminales J-Leerzeichen, Kulturunabhängigkeit | NOT_EXECUTED |
| Eingabe | NULL/leer, UTF16 vor Alphabet, rohe Quote vor UTF16, 4096 ß, Supplementary und alphabetfremde Zeichen | NOT_EXECUTED |
| Bridge | Eager feste Einzeilenarrays, FillRow-Typ-/Resultkonsistenz, technische Fehler nicht als Resultcode | NOT_EXECUTED |
| Artefakt | Exakter Kandidatenhash, SAFE-Metadaten, vier SQL-Slots, keine Fremd-Binaryreferenz | NOT_EXECUTED |
| SQL | Contract, Boundaries, InstalledMetadata, tatsächliche Clientfelder/NULL/EOF | NOT_EXECUTED |
| Lifecycle | Local/central, clean/repeat/uninstall/repeat, Erwartungshash, vollständige Marker/Owner, fremde Slots/Consumer, Caller-TX/AppLock/Rollback | NOT_EXECUTED |
| Plattform | SQL2019/2022/2025 Windows/Linux CL150/160/170 | NOT_EXECUTED |
| Betrieb | Tatsächliche Minimalrechte, Heap/CPU/Wallclock/Produktionskapazität | NOT_EXECUTED |

Keine vollständige Matrixpflicht vor jedem kleinen Fix. Die tatsächliche
Qualifikation erfolgt risikobasiert mit Root-koordinierter eigener Bereinigung;
ein Teilnachweis wird niemals als gesamte Produktvalidierung gezählt.