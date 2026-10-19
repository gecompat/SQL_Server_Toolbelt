# Phonetik – Testmatrix

Version 1.0.0 bleibt `partially validated` und `unreleased`.
Die [Testevidenz](README.md) beschreibt die tatsächlichen begrenzten Läufe.

| Scope | Gezielter Nachweis | Status |
|---|---|---|
| Offline-Differential | Vollständige Primary-/Alternatebytes einschließlich AJ-Endblank gegen die gebundenen Apache-Commons-Codec-1.18.0-Quellen; fester endlicher Korpus | 32 Fälle am 2026-10-08 und erweiterte 36 Fälle am 2026-10-09 bestanden; kein vollständiger Scanner-, SAFE-, SQL-, Matrix- oder Release-PASS |
| Algorithmen / Eingabe | Framework je223 Assertions unter drei Kulturen; vier lokale Fixtures; vollständige Codes und terminales J-Leerzeichen | Begrenzter Framework-Scope und endlicher Java-Differentialkorpus bestanden; vollständige Scannerabdeckung offen |
| Bridge / SQL | Acht echte Reader je local/central und zwei lokale Größenwitnesses je Ziel; Typen, NULL, Status, Bytes, eine Zeile, EOF/noNext | Begrenzter Scope bestanden; Größen aus Quelle hergeleitet; kein Differentialnachweis dieser SQL-Größenfälle |
| Artefakt | Build; eigene IL-/Metadatenprüfung ohne unbekannte eigene IL-Aufrufe; vier installierte Slots und exakte Binarybindung | Bestanden im Kandidatenscope; keine transitive SAFE-Vollqualifikation |
| Lifecycle | Clean/repeat, resolved Consumer Deploy/Uninstall55266/1, zentrale Confirm0-Ablehnung55267/1, unveränderter Snapshot/gesunde Session, Uninstall/repeat und frische eigene Bereinigung | Begrenzter local/central Scope bestanden; unresolved NOT_ESTABLISHED, übrige Negativmatrix offen |
| Plattform | Linux SQL2019/latest CL150 und Windows SQL2025/exakt CU8 CL170; local/central innerhalb derselben eigenen Testdatenbank | Ausgewählte Ziele bestanden; weitere Ziele/CL und CrossDB offen |
| Betrieb / CI | Tatsächliche Minimalrechte, Heap/CPU/Wallclock/Produktionskapazität und aktuelle Head-CI | Offen; öffentliche CI ist Windows-Offline, kein SQL-Lauf |

Keine vollständige Matrixpflicht vor jedem kleinen Fix. Ein Teilnachweis wird
niemals als gesamte Produktvalidierung gezählt. Historische Fehlversuche
bleiben fehlgeschlagen und werden nicht durch spätere Erfolge umetikettiert.

`MarkRelease.sql` schreibt und `Preflight.sql` entfernt datenbankweite
Release-Marker per Extended Property ohne Objektlevel. Schema-/Assembly-DDL-Rechte
belegen diese Operationen nicht allein; Microsoft dokumentiert für
[`sp_addextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql)
die Datenbank-Ausnahme für `db_ddladmin`. Eine tatsächliche Minimalrechteprobe
für den vollständigen Lifecycle wurde nicht ausgeführt und es wurden keine
Rechte vergeben.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-09`
- Nachweis: `local: Tests/Differential/run-differential-phonetic.ps1 mit DifferentialCorpus.tsv`
- Scope: Bereits dokumentierter einmaliger Offlinevergleich unter Windows/.NET Framework 4.8 mit explizitem JDK27 und unveränderten Apache-Commons-Codec-1.18.0-Quellen: 36 feste Fälle, davon 20 Cologne und 16 Double Metaphone, stimmen in vollständigen Primary-/Alternatebytes überein. Vier Ergänzungen HCL/ACL/-CR/ACR liefern 45/085/47/087; die 32 bisherigen Fälle bleiben unverändert. Vorhandene Assembly mit belegter Herkunft aus fünf unveränderten aktuellen C#-Quellen wiederverwendet, kein neuer Produktbuild. Zwei Compiler und zwei Consumer erfolgreich. stderr nur decodiert leer; kein Datei-Cleanup-PASS. Keine vollständige Scanner-, SQL-, SAFE-, Zielmatrix-, Minimalrechte- oder Releasequalifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
