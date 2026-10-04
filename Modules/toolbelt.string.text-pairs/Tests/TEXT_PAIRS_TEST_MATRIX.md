# Paarvergleich 1.0.0 – Pflichtmatrix

Gezielte Nachweise des privaten begrenzten Labadapters:

|Datum / Ziel|Tatsächlich geprüfter Scope|
|---|---|
|2026-10-03, SQL Server 2019 Linux/latest CL150 local, SC-UTF8|Fünf SQL-Fixtures; clean/repeat/uninstall/repeat; separate frische Bereinigungsprüfung|
|2026-10-04, SQL Server 2025 Windows/CU8 CL170 local, SC-UTF8|Fünf SQL-Fixtures; Repeat und uninstall/repeat; separate frische Bereinigungsprüfung|
|2026-10-04, separate zentrale Qualifikation|InstalledMetadata; alle drei Algorithmen direkt mit fünf typgenauen Feldern, EOF/noNext; drei ResultTable-Aufrufe ohne Resultset; Confirm0 strikt55128/1, Fullcatalog unverändert und Session gesund; Confirm1 Uninstall/repeat; frischer Audit: zwei eigene Datenbanken entfernt, ein eigener Trusteintrag wiederhergestellt|

Keine Config-, SQL-Rechte- oder Owneränderungen. Der frühere zentrale
Adapterfehler wegen NULL-Secondarycount bleibt ein bereinigter Fehllauf;
seine vier erfolgreichen Teilabschnitte zählen nicht als Gesamt-PASS.

Die übrigen Nachweise bleiben **OPEN**, insbesondere tatsächliche
Minimalrechte, fremde CLR-PC-Kollisionen, weitere Lifecycle-Negativfälle,
Zielkombinationen und exakte aktuelle Head-CI. Versions-, Plattform-, Modus-
und Compatibility-Level-Abdeckung werden jeweils ausdrücklich belegt;
ein einzelner Lauf qualifiziert keine anderen Kombinationen. Kein
Evidencetransfer vom Provider; `partially validated`, `unreleased`.


|Bereich|Oracle / Fixture|
|---|---|
|Signatur/Metadaten|InstalledMetadata.Contract.sql: 11 Parameter, P, fünf logische Resultfelder, statische drei Providerconsumer|
|API/Kerne|TextPairs.Contract.sql: signed Ordinals, Zusatzspalten, Unicode/NUL/Trailing/NULL, drei öffentliche TVFs, synthetische hardGoldens und gemischte Codes|
|Admission|TextPairs.Boundaries.sql: Row/Text/Work at/+1, Parametercaps, invalid Algorithm/Schwelle/Profile, Shape/Ordinals; globale Fehler vor Resultmutation|
|Publish|TextPairs.Atomicity.sql: Dummyshape, Replace/Append/Empty, late Constraintfailure, Caller-Savepoint/SET/TC-Erhalt|
|Client/Help|Help.Contract.sql: zwölf Helpfelder/Sections/Defaults und Sentinel. Client separat: direkter SELECT und ResultTable ohne SELECT, Debug nur Messages, exakte EOF/noNext; Help bei fehlenden Dependencies|
|Caller|OwnTX/committable Caller ON/OFF, doomed nondooming Guard, distributed Savepointunsupported; ursprünglicher Fehler und Optionen erhalten|
|Lifecycle|clean/repeat/uninstall, gleicher Mode, bekannte Marker/Slots/Hash, unknown/future/foreign erhalten, Consumerblock, AppLock und injizierter Rollback; exakt SQL-P zulassen. Synthetische fremde CLR-PC am eigenen Namen mit imitierten bekannten Markern: Deploy/Uninstall müssen vor Adoption/Drop ablehnen und ObjectID, Definition, Assemblybindung und sämtliche Marker bytegleich erhalten (Nativefixture/Adapter noch offen)|
|Ownership/Visibility|AdminVIEW/DependencySELECT0/NULL, Fullbinaryhash falsch/NULL, nicht sichtbare Consumer; Runtime ohne DBweite Sicht/Hashpflicht|
|Bereinigung|Exakte eigene Identität, vorhandene fremde Ressourcen erhalten; unabhängiger frischer Absenznachweis|

SQL-Fixtures allein sind keine vollständige Client-/Lifecycle-/Minimalrechtequalifikation. Diese Bereiche benötigen den separat geprüften begrenzten Adapter; keine geplanten Cases als bestanden zählen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `private bounded Windows-/Central-Labadapter; unabhängiger physischer Receipt-/Journal-/Capture-/Pin-Audit`
- Scope: SQL Server 2025 Windows/CU8 CL170 SC-UTF8 local: fünf öffentliche SQL-Fixtures und Lifecycle-Wiederholungen. Separat central: InstalledMetadata, drei direkte typgenaue Algorithmusconsumer mit EOF/noNext, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-Bestätigung 55128/1 mit unverändertem Katalogsnapshot, Wiederholung und eigene Bereinigung. Keine Config-/Rechte-/Owneränderung. Minimalrechte, weitere Lifecycle-Negativfälle und Ziele bleiben offen; aktuelle PR-Head-CI separat.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
