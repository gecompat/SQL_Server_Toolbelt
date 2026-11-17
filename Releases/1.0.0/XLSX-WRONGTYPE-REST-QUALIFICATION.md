# XLSX: WrongType-Fremderhalt und ausdrücklich offener Prozessrückgabewert

Ausführung am 2026-11-17 (UTC): **PARTIAL**. Die SQL-Fachorakel sind auf allen
24 lokalen/direkt zentralen Routen bestanden und zwölf frische Abschlussaudits
sind PASS. Für einen nativen Fall blieb der Prozessrückgabewert nach einem
Controller-Journalfehler nicht erhalten. Er wird nicht als Exit0 rekonstruiert.
Der [JSON-Bericht](XLSX-WRONGTYPE-REST-QUALIFICATION.json) trennt diese Ebenen
und bindet alle drei tatsächlich ausgeführten Methodenstände.

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Tatsächliche SQL-Prüfung

Nach öffentlicher Erst-/Repeatinstallation bestätigt die unveränderte
Display.Lifecycle-Fixture neun Slots samt Markern und internem Display-Binding.
Die vorhandene Types.CollisionFixture wird ausschließlich mit WrongType
aufgerufen. Sie ersetzt in der eigenen Wegwerf-Datenbank die Prozedur
USP_ListXlsxWorksheets durch eine eigene synthetische skalare SQL-Funktion,
die 73 zurückgibt und keine Toolbelt-Modulmarker hat. Das verändert keinen
realen fremden Owner oder Principal; es ist eine Modulslot-Kollision.

Je Route müssen aktueller Deploy und bestätigter aktueller Uninstall mit 51534
abbrechen: insgesamt 48 Ablehnungen. Der vollständige Snapshot des absichtlich
veränderten XLSX-Zustands bleibt jeweils exakt gleich. Drei direkte Zeugen je
Route prüfen unveränderte Objekt-ID und Definition, Typ FN, keine Modulmarker
und den Rückgabewert 73: insgesamt 72 Zeugen. Der zusätzliche paketweite
Definitionsvergleich nimmt ausschließlich diesen einen erwartbar ersetzten
Slot aus; alle anderen Objekte und Dependencies bleiben unverändert.

Die ursprüngliche Fixture verlangt für diesen letzten destruktiven Fall
explizit die Bereinigung der eigenen Wegwerf-Datenbank. Daher werden weder
eine Fixture-Restaurierung noch erfolgreicher öffentlicher Uninstall oder
UninstallAbsent behauptet. Der Stub bleibt bis zur eigenen DB-Entfernung
unangetastet; normale öffentliche Deinstallation ist separat bereits belegt.

## Erhaltener Auditfehler und Controllerabbruch

Der erste native Fall erreichte COMPLETE. Sein erster Audit scheiterte an der
alten pauschalen Erwartung von sechs Lifecycle-Phasen. Der exakte ursprüngliche
Guard wurde mit dem tatsächlichen finalen Journal SQL-frei reproduziert.
Die korrigierte Erwartung umfasst hier nur zwei InstallAndRepeat-Phasen und
die expliziten zwei WrongType-Ablehnungen je Modus. Ein frischer eigener Audit
bestand am bytegleichen Originaljournal. Der erste Audit bleibt AUDIT_FAILED;
der native Fall wurde nicht wiederholt.

Die anschließende Fortsetzung brach beim atomaren Ersetzen des lokalen
Controllerjournals mit Access denied ab. Für Fall 4 (Linux SQL 2025/latest,
CL160, lokal und zentral) lagen das native COMPLETE-Journal einschließlich
bereinigter Ressourcen und die vollständige finale PASS-Ausgabe vor. Der
Controller-Rückgabestatus war nicht erhalten. Die alte DISPATCHED-Zeile mit
fehlendem Exitcode bleibt deshalb unverändert. Der bereits reservierte
separate Audit wurde frisch ausgeführt und bestand am identischen Journal.
Auch dieser Gesamtlauf wurde nicht wiederholt.

Die noch fehlenden Zielpaare wurden erst nach diesen frischen Audits und
striktem Abgleich von Originalhistorie, Startzeit, Paket, Zielmatrix und
Journalen fortgesetzt. Elf native Prozessrückgaben sind als Exit0 dokumentiert;
für Fall 4 bleibt die Prozessqualifikation offen. Keiner der abgebrochenen
ursprünglichen Controller wird zum vollständigen Gesamt-PASS umgedeutet.
Statusleser verwenden nun Dateifreigabe für Read/Write/Delete, um atomare
Journalersetzung nicht durch einen eigenen Lesehandle zu blockieren. Die
konkrete Ursache des ursprünglichen Sharingkonflikts ist damit nicht bewiesen.

## Abschluss und verbleibender Rest

Alle zwölf nativen Journale sind COMPLETE und alle zwölf frischen Fallaudits
PASS; alle 24 eigenen Datenbanken entfernt. Eigene Konfigurations-/Trustzustände
wurden wiederhergestellt und fremde Zustände erhalten. Der ursprüngliche
Rahmen bleibt unverändert: maximal 28 Ziel-/Auditaufrufe,28 DB-Reservierungen,
60 Minuten und höchstens zwei korrigierte Adapterfälle. Verbraucht wurden 25
Aufrufe, 24 DB-Reservierungen und beide Korrekturfälle. Die ursprüngliche
Startzeit blieb erhalten; die Welle ist geschlossen. Restplätze eröffnen keine
neue Ausführung.

Offen ist ausschließlich für diesen Teilumfang der vollständige native
Prozessabschluss von Fall 4; SQL-Fachorakel und Cleanup sind separat belegt.
Eine dafür erforderliche neue gezielte Ausführung braucht eine neue konkrete
endliche Freigabe. Andere grüne Kontexte dürfen nicht wiederholt werden.

SQL-freie Gegenproben prüfen Originalfixture und Oracle-Routing, fünf ungültige
Funktionszeugen, fehlenden Restore, Mutation und Kindfehler ohne PASS,
Audit-Lifecycle und unveränderte alte Scopes, exakte Recoverybindings sowie
Zeit-/Historien-/Capture-/Journalgegenproben. Synthetische Receipts sind keine
Native-Pässe. Die öffentlichen Berichtsprüfungen verhindern insbesondere eine
Aufwertung des fehlenden Prozessrückgabewerts oder die Löschung alter Fehler.

Produktcode, DLLs, Rechte, Identitäten und Lab-Infrastruktur bleiben
unverändert. Vorhandene Paket-/Größen-/Upgrade-/Caller-/Consumernachweise
werden wiederverwendet. Andere Slots, reale Owner-/Lowpriv-Identitäten,
Heap/Kapazität, TLS und der vollständige Modulumfang bleiben getrennt.
Keine Veröffentlichung oder Tags; XLSX weiterhin teilweise validiert.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_wrongtype_rest.py
python -B Tests/Release/test_xlsx_wrongtype_rest.py
```
