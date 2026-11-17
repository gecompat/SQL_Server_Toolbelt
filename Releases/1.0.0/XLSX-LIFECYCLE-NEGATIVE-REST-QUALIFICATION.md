# XLSX: aktuelle negative Lifecycle-Matrix

Ausführung am 2026-11-16 (UTC): `PASS_FOR_DECLARED_SCOPE`. Das unveränderte
aktuelle fokussierte XLSX-Paket besteht die hier benannten Negativprofile auf
allen zwölf Windows-/Linux-Engine-/CL-Paaren lokal und direkt zentral.
[Exakte Originalmethoden und Resultate](XLSX-LIFECYCLE-NEGATIVE-REST-QUALIFICATION.json).

| Plattform / Patchselektor | SQL 2019 | SQL 2022 | SQL 2025 | Modi |
|---|---|---|---|---|
| Linux / latest | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |
| Windows / CU32, CU26, CU8 | CL150 | CL150, CL160 | CL150, CL160, CL170 | lokal / direkt zentral |

## Tatsächlich ausgeführter Umfang

Jede der 24 Routen verwendet genau eine eigene Datenbank und die aktuelle
öffentliche Install-/Repeat-Lieferung. Beide SAFE-Binaryhashes, Modulversionen,
Compatibility Level und Sitzungszustand werden geprüft. Die unveränderte
`Display.Lifecycle.sql` bestätigt die neun bekannten Slots samt Release-Markern
und das genaue interne Display-Binding. Daraus wird kein zusätzlicher Nachweis
aller denkbaren CLR-/Consumerprofile abgeleitet.

Die originalen Helper aus `run-xlsx-types-lab.ps1` werden als einzelne
Definitionen importiert. Dessen älterer Top-level-Lab-/Legacy-Lauf wird nicht
gestartet. Die gemeinsame begrenzte SQL- und Ownershipschicht stellt sämtliche
Verbindungen bereit; auch der zweite Lockhalter bleibt in der eigenen aktiven
Datenbank. Seine Transaktion und Verbindung werden im `finally` beendet.

| Pro Route | Konkrete Prüfung | Gesamt auf 24 Routen |
|---|---|---|
| 4 Rollbackfälle | Deploy nach DROP von `TVF_InterpretXlsxCell`, Uninstall nach DROP von `TVF_InternalInterpretXlsxCell`, beide zusätzlich vor ihrem eigenen COMMIT; synthetischer Fehler 51592 | 96 |
| 2 Lockfälle | Deploy und Uninstall unter gehaltenem exklusivem Transaktions-AppLock; erwartete Ablehnung 51533 | 48 |
| 16 Sichtbarkeitsfälle | Zwei vorhandene Berechtigungsprädikate, je 0/NULL in beiden Phasen von Deploy und Uninstall; erwarteter Fehler 51535/State2 | 384 |

Alle 528 Negativfälle bestanden. Vor/nach jeder Ablehnung bleiben vollständige
Objektdefinitionen und IDs, Modul-/Schema-/Assemblymarker, Schema-ID und der
SAFE-Assemblyinhalt unverändert. Die primäre Sitzung bleibt ohne offene
Transaktion. Der zusätzliche globale Definitionsvergleich erhält auch die
Paketdependencies. Nach den Negativfällen folgen die öffentlichen
Uninstall-/UninstallAbsent-Aufrufe und die eigene Ressourcenbereinigung.

Die 16 Sichtbarkeitsvarianten ersetzen ausschließlich die vorhandenen
`HAS_PERMS_BY_NAME`-Prädikate synthetisch durch 0/NULL für die ausgewählte Phase.
Es werden keine Rechte vergeben oder widerrufen. Das belegt die benannte
Fehlerbehandlung, keine tatsächliche Lowpriv-/Owner-/CrossDB-Identität.

## Abschluss und Grenzen

Zwölf erfolgreiche native Gesamtläufe und zwölf getrennte frische Auditprozesse
bestanden. Jeder Audit bindet exakt das finale Journal und bestätigt die
Abwesenheit eigener Datenbanken/Trustreste sowie die ursprüngliche
Konfiguration; vorbestehende/fremde Zustände bleiben erhalten. Alle 24 eigenen
Datenbanken sind entfernt.

Der unveränderte gemeinsame Rahmen umfasst höchstens 28 Lauf-/Auditaufrufe,
28 DB-Reservierungen und 60 Minuten ab erstem nativem Start, darin höchstens
zwei gezielt geänderte Adapterfälle bei Befund und bestätigtem Cleanup.
Verbraucht wurden 24 Aufrufe/Reservierungen; keine nativen Fehlfälle oder
Adapterkorrekturen. Die Welle ist geschlossen. Freie Plätze eröffnen keine
weitere Wiederholung. Aktuelle DLLs, Paket und bestehende Entwicklungs-/Trust-
freigabe werden wiederverwendet; keine neue Produktfunktion oder Infrastruktur.

Sechs SQL-freie Zulassungs-/Seamgegenproben, die tatsächliche eigene Holder-
Zuordnung, ursprüngliche Helper mit Testdoubles einschließlich Fehlercleanup,
alle drei tatsächlichen Modus-/Fixtureselektionen und der vollständige neue
Adapter mit Journal-/Counter-/Kinderfehlergegenproben bestanden. Die
Testdoubles werden nicht als native SQL-Ausführung ausgegeben. Die tatsächliche
Methodenversion `fec80171328bcd2c8646eef411af68041d92c4c1` bleibt separat erhalten;
alle ausgeführten öffentlichen Runtimeeingaben stimmen exakt mit ihren
Original-Git-Bytes überein. Private Journale, Rohkanäle und Tools bleiben privat.

Weitere Kollisions-/Owner-/echte Minimalrechteprofile, Caller-doomed-Fälle,
OS-/VM-Ausfall mit verlorenem Koordinator, Heap/Kapazität, authentifiziertes TLS
und der vollständige Modulumfang werden nicht zusätzlich qualifiziert.
XLSX bleibt teilweise validiert und unveröffentlicht; keine Tags oder Releases.

Reproduzierbare Integritätsprüfung ohne SQL:

```text
python Scripts/Release/validate_xlsx_lifecycle_negative_rest.py
```
