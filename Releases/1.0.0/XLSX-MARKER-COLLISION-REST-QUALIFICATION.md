# XLSX: aktuelle Marker-, Modus- und Dependency-Kollisionen

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Das aktuelle
fokussierte XLSX-Paket besteht die sechs unten benannten vorhandenen
Kollisionsprofile auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal und direkt
zentral. Der [JSON-Bericht](XLSX-MARKER-COLLISION-REST-QUALIFICATION.json)
bindet die tatsächliche Methode, sämtliche öffentlichen Inputs und das Paket.

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Geprüfte Fehler und unveränderte Zustände

Nach öffentlicher Erst-/Repeatinstallation prüft die unveränderte
Display.Lifecycle-Fixture die neun Slots, Release-Marker und das genaue
interne Display-Binding. Die aktuelle Quelle der Types.CollisionFixture und
die originale sechsfach-ForEach-Schleife aus run-xlsx-types-lab.ps1 werden
unverändert verwendet. Nur dieser eindeutig ausgewählte AST wird im gebundenen
lokalen Kontext ausgeführt; der historische Top-level-Lab-/Legacy-Lauf bleibt
aus. Die übrigen SQL-/Deadline-/Ownershiphelfer stammen aus dem aktuellen
begrenzten Paketadapter.

| Fixtureklasse | Veränderung ausschließlich in eigener Test-DB | Erwartete Ablehnung |
|---|---|---|
| VersionUnknown | Versionsmarker 9.9.9 | Deploy 51534 |
| VersionPadded | Versionsmarker mit folgendem Leerzeichen | Deploy 51534 |
| ModePadded | Deploymentmodus mit folgendem Leerzeichen | Deploy 51534 |
| MarkerPadded | Objektversionsmarker mit folgendem Leerzeichen | Deploy 51534 |
| MarkerMissing | fehlender Modul-ID-Marker am eigenen List-Objekt | Deploy 51534 |
| Dependency | eigene synthetische abhängige View | Uninstall 51535 |

Die 24 Routen ergeben 144 erwartete Ablehnungen: 120 Deploy- und 24
Uninstallfälle. Jeweils bleibt der vollständige Snapshot des absichtlich
veränderten Zustands nach der Ablehnung exakt erhalten. Der originale
Fixture-Restore wird erst danach ausgeführt; insgesamt 144 Restores.
Abschließend muss wieder der vollständige unveränderte ursprüngliche
Katalog-/Assemblysnapshot vorliegen. Eine fehlende Restore-Anweisung,
unerwartete Fehlernummer oder Katalogmutation kann keinen PASS ergeben.

Das zusätzliche paketweite Definitionsorakel erhält auch Dependencies; die
Sitzung bleibt ohne offene Transaktion. Öffentliche Uninstall-/UninstallAbsent-
Aufrufe und eigene Ressourcenbereinigung folgen erst nach den Fehlerfällen.

## Abschluss, Nachweisbindung und Grenzen

Zwölf COMPLETE-Fälle und zwölf getrennte frische AUDIT_PASS bestätigen genau
die finalen Journale. Alle 24 eigenen Datenbanken sind entfernt; eigene
Konfigurations-/Trustzustände sind wiederhergestellt und fremde Zustände
unverändert. Verbraucht wurden 24 von maximal 28 Lauf-/Auditaufrufen und
DB-Reservierungen innerhalb des ursprünglichen 60-Minutenfensters; keine
nativen Fehler oder geänderten Adapterfälle. Die Welle ist geschlossen.
Restplätze eröffnen keine Wiederholung.

Aktuelle qualifizierte DLLs, Paket und bestehende Entwicklungs-/Trustfreigabe
werden wiederverwendet. Produktcode, öffentliche Verträge, Rechte, Identitäten,
Labressourcen, Zertifikate und Truststores bleiben unverändert. Frühere
Upgrade-, Zukunftsslot-, Caller-, Größen- und anderen Fehlernachweise behalten
ihre ursprünglichen Grenzen und werden nicht erneut ausgeführt.

SQL-freie Gegenproben prüfen falsche Admission, die echte Originalschleife
mit genau sechs Fixture-/Restore-Aufrufen und fünf Deploy-/einem Uninstallziel,
fehlenden Restore, Mutation und Restorefehler ohne PASS-Aufwertung sowie die
tatsächliche Modus-/Fixtureselektion. Sie sind keine zusätzlichen SQL-Ausführungen.

Andere Slot-/WrongType-/Owner-/Minimalrechte-/CrossDB-Identitätsprofile,
weitere Clienthosts, harte OS-/VM-Verluste, Heap/Kapazität und TLS bleiben
separat. Keine vollständige Modulqualifikation und keine Veröffentlichung.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_marker_collision_rest.py
python -B Tests/Release/test_xlsx_marker_collision_rest.py
```
