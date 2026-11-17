# XLSX: gezielter Abschluss der WrongType-Prozesslücke

Ausführung am 2026-11-17 (UTC): `PASS_FOR_DECLARED_SCOPE`. Nach der konkreten
Benutzerfreigabe wurde ausschließlich Linux SQL 2025/latest CL160 lokal/zentral
(Fallindex 4) neu ausgeführt, gefolgt von einem separaten frischen Audit.
Der [maschinenlesbare Abschluss](XLSX-WRONGTYPE-PROCESS-CLOSURE.json) bindet
diese neue Methode und den unveränderten [historischen PARTIAL-Bericht](XLSX-WRONGTYPE-REST-QUALIFICATION.md).
Dessen unbekannter ursprünglicher Rückgabewert und beide alten Fehler werden
nicht nachträglich geändert oder zu Erfolg erklärt.

## Neuer nativer Nachweis

Ein Gesamtlauf und ein unabhängiger Audit bestanden mit jeweils tatsächlichem
Exitcode 0, vollständiger Capture und leerem Stderr. Die numerischen Rückgaben
werden unmittelbar nach Invoke-OwnedProcess als eigene exclusive-CreateNew-
Receipts mit WriteThrough/Flush(true) gesichert, bevor andere Journaldaten
weitergelesen oder aggregiert werden. Weitere gebundene Receipts verbinden sie
mit Runset, finalem Native-Journal sowie vollständigen stdout-/stderr-Bytes.
Das sind vier eigene Primär-/Bindungsreceipts, kein aus Journalstatus oder
späteren Beobachtungen abgeleiteter Prozesswert.

Der neue Body besteht unverändert die WrongType-Fixture, beide Modi und ihre
Deploy-/Uninstall-Ablehnungen samt Funktionszeugen. Der frische Audit bindet
das identische finale Journal und bestätigt die Entfernung beider neuen eigenen
Datenbanken sowie eigene Konfigurations-/Trustwiederherstellung und den Erhalt
fremder Zustände. Vorhandene DLLs und Paket wurden wiederverwendet.

Der vorab freigegebene Rahmen bleibt exakt: höchstens zwei Ziel-/Auditaufrufe,
zwei eigene Datenbanken, 45 Minuten, keine weitere Wiederholung. Verbraucht wurden
zwei Aufrufe und zwei DBs innerhalb der Frist; keine Fehler oder Wiederholung.
Ein exklusiver Attemptmarker verhindert einen weiteren Start. Vor SQL werden
die neue konkrete Autorisierung, grüne tatsächliche Main-CI von PR #616,
Integrationsabstammung, aktueller Source-/Runsetstand, noch offener historischer
Prozessgate und exakt ausgewählter Fall 4 geprüft.

## Wiederverwendung und aktueller Status

Die anderen elf erfolgreich dokumentierten Prozesskontexte wurden nicht erneut
ausgeführt. Zusammen mit ihren gültigen ursprünglichen Nachweisen ist damit die
benannte WrongType-Teilmatrix auf zwölf Engine-/CL-Paaren beziehungsweise 24
lokalen/direkt zentralen Routen für diesen unveränderten Build qualifiziert.
Der alte SQL-Fachnachweis und zwölf ursprüngliche Cleanup-Audits bleiben
eigenständig; die alte PARTIAL-Datei bleibt historisch unverändert.

Die SQL-freien Berichtsgegenproben verweigern fehlende numerische/gebundene
Receipts, falschen Zielkontext, fehlenden Audit oder Cleanup, Umwertung alter
Fehler, breite Wiederholung, zusätzliche Rechte, Sourceabweichungen und eine
Beobachtung erst nach Metadatenreads. Der Receiptwriter wurde separat mit
synthetischen Daten auf vollständiges Schreiben, Parsen und Nichtüberschreiben
geprüft; Parse-, Autorisierungs- und Reihenfolgeprüfungen bestanden ohne SQL.

Andere Slots, reale Owner-/Lowpriv-/Loginprofile, weitere Clienthosts, Heap/
Kapazität, TLS und die vollständige Modulqualifikation bleiben getrennt.
Kein ursprünglicher fehlgeschlagener Controller wird aufgewertet. Produktcode,
Rechte, Identitäten und Lab-Infrastruktur sind unverändert; keine Veröffentlichung
oder Tags. XLSX bleibt insgesamt teilweise validiert.

Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_wrongtype_process_closure.py
python -B Tests/Release/test_xlsx_wrongtype_process_closure.py
```
