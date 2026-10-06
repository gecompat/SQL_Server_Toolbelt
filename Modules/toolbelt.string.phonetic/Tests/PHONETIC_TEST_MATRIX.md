# Phonetik – Testmatrix

Version 1.0.0 bleibt `partially validated` und `unreleased`.
Die [Testevidenz](README.md) beschreibt die tatsächlichen begrenzten Läufe.

| Scope | Gezielter Nachweis | Status |
|---|---|---|
| Algorithmen / Eingabe | Framework je223 Assertions unter drei Kulturen; vier lokale Fixtures; vollständige Codes und terminales J-Leerzeichen | Begrenzter Scope bestanden; Java-Differential NOT_EXECUTED |
| Bridge / SQL | Acht echte Reader je local/central und zwei lokale Größenwitnesses je Ziel; Typen, NULL, Status, Bytes, eine Zeile, EOF/noNext | Begrenzter Scope bestanden; Größen aus Quelle hergeleitet, kein Java-Differential |
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
- Datum: `2026-10-04`
- Nachweis: `Begrenzte private Offline-/Nativeadapter mit unabhängiger physischer Prozess- und Bereinigungsprüfung`
- Scope: Am 2026-10-04 bestanden Build, Frameworkprüfungen mit jeweils 223 Assertions unter en-US/de-DE/tr-TR und die eigene IL-/Metadatenprüfung (keine unbekannten eigenen IL-Aufrufe). Begrenzte private Labadapter bestanden auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170. Je Ziel: vier Fixtures einmal lokal, acht echte Clientreader je local/central sowie zwei lokale Größenwitnesses; Clean/Repeat, resolved Consumer-Ablehnungen, zentrale Bestätigung und Uninstall/Repeat mit frischer eigener Bereinigung. Keine Konfigurations-, Rechte- oder Owneränderungen. Java-Differential, unresolved Consumer, weitere Ziele/CL, tatsächliche Minimalrechte, vollständige Lifecyclematrix und aktuelle Head-CI bleiben offen. Teilweise validiert und unveröffentlicht; kein vollständiger Produkt-PASS.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
