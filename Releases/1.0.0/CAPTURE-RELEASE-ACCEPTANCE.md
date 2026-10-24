# Capture: begrenzte Releaseabnahme und Minimalrechte

Stand: 2026-10-24. Das historische Capture-Timeout-Gate ist für die exakt
gebundene Regex-DLL nach der unten dokumentierten ausdrücklichen
Benutzerentscheidung **angenommen**. Der Vorfall bleibt „Ursache ungeklärt,
nicht reproduziert“. Es wird keine Capture-Produktkorrektur behauptet.
Andere Regex-/Toolbelt-Releasegates bleiben getrennt offen; kein Modul wird
hochgestuft oder veröffentlicht.

## Abschlussregel und unveränderte Nachweise

Die direkte Benutzerantwort „Ja, mit diesen Nachweisen und dokumentiertem
Restrisiko“ erlaubt den Abschluss nach vollständiger Prüfung der unveränderten
Funktions-, Größen-, Timeout- und Atomaritätsorakel am finalen Binary.
Die [maschinenlesbare Abnahme](capture-release-acceptance.json) bindet die
ausgelieferte DLL, relevante aktuelle Quellen und bisherige Evidenz.

Die [Regex-Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md) enthält die physische
Windows-/Linux-Matrix SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
auf dieser DLL. Die [anschließende Capture-Untersuchung](CAPTURE-TIMEOUT-INVESTIGATION.md)
belegt den zuvor blockierten Originalpfad mit seinem Drei-Fixture-Vorlauf
sowie direkte Capture-Clientmetadaten einschließlich großer Ausgabegrenzen
lokal/zentral. Die gezielten Timeoutproben bestätigen die Diagnose und halten
unerwartete Timeouts weiterhin als `PARTIAL` fest. Die direkte Clientfixture
prüft atomare Fehler ohne erste verwertbare Zeile.

Die DLL und die relevanten kanonischen Capture-/Intake-/Budgetquellen sind
unverändert. Alle früheren `FAIL`-/`PARTIAL`-Datensätze bleiben erhalten.
Kein späterer Erfolg schreibt einen historischen Fall um. Gesamtbudgets
500/2000 ms, höchstens 250 ms je Suche und 2/16 MiB Textgrenzen bleiben bestehen.
Die Abnahme behauptet weder eine bewiesene historische Ursache noch eine
Garantie, dass unter beliebigem Scheduling kein Timeout mehr auftreten kann.
Neue relevante Binary-/Quelländerungen verlangen einen erneuten Abgleich
mit den betroffenen Nachweisen.

## Neue Minimalrechteprüfung

Der Benutzer hat ausschließlich in eigenen temporären Lab-Testdatenbanken
Benutzer ohne Login, gezielte Datenbankgrants/-entzüge und vollständigen
Cleanup freigegeben. Server-Logins und fremde Rechte bleiben außerhalb
dieses Aufbaus. Die kanonische
[Releasefixture](../../Tests/Release/Runtime/Regex.Capture.Rights.sql) prüft:

- Ohne Grant werden beide öffentlichen Aufrufe mit exakt SQL229 abgewiesen.
- `REFERENCES` allein erlaubt keinen normalen skalaren Fachaufruf.
- `SELECT` auf der Capture-TVF und `EXECUTE` auf der skalaren Replace-Fassade
  erlauben die festen Wertorakel bei gleicher Ownership.
- Direkte CLR-Kernaufrufe bleiben ohne eigene Grants gesperrt.
- Nach Rechteentzug werden die öffentlichen Aufrufe wieder mit SQL229 abgewiesen.

Die Unterscheidung von TVF- und skalaren Rechten entspricht der
[Microsoft-Referenz für Objektberechtigungen](https://learn.microsoft.com/en-us/sql/t-sql/statements/grant-object-permissions-transact-sql?view=sql-server-ver17).
Der native Befund zeigt zugleich eine bisher falsche Angabe `SELECT/REFERENCES`
in den kanonischen skalaren Regex-Dokumentationen und SQL-Headern. Diese
Korrektur samt gekoppelten finalen Paketquellen bleibt ausdrücklich ein
weiteres Arbeitspaket; der fehlerhafte Installationstext wird nicht als korrekt
freigegeben. Der nachgewiesene Ausführungsvertrag benötigt keinen Produktpatch.

Am 2026-10-24 bestanden zwölf physische Ziel-/CL-Fälle der oben genannten
Matrix, jeweils lokal und direkt zentral: 24 Fixtureaufrufe, je vier Phasen
mit vier Proben. Die positive Skalarphase entzieht den vorherigen
`REFERENCES`-Grant ausdrücklich und prüft die effektiven Rechte. Eine frühere
Testversion belegte nur die Kombination `EXECUTE` plus `REFERENCES`; ihre
zwölf erfolgreichen Fälle und zwei Fehlerkontrollen bleiben historisch und
werden nicht als Nachweis für `EXECUTE` allein verwendet.

Drei zusätzliche private, gezielt veränderte Kontrollen führen falsche
Ergebnisbytes, eine falsche erwartete Fehlernummer beziehungsweise einen
überflüssigen `REFERENCES`-Grant ein. Alle wurden tatsächlich `FAILED_CLEANED`, einschließlich
unabhängigem Audit. Sie sind Ablehnungsnachweise und kein funktionaler PASS.

Ausführung über `Tests/Release/Invoke-ApiQualificationLab.ps1` mit eingefrorenen
privaten Runsets, kanonischer Fixture und zusätzlichem äußerem Watchdog.
Nur eigene synthetische Datenbanken und vorhandene qualifizierte DLL-/SQL-
Payloads wurden verwendet. Jeder Fall hatte einen separaten Cleanup-/Pinaudit.
Der frische unabhängige Schlussaudit bestätigte 87 eigene DB-Namen abwesend,
66 zielgebundene Trustzustände wiederhergestellt oder unverändert und alle
originalen und finalen Eingabebindungen getrennt erhalten. Sechs temporäre CLR-Konfigurationen wurden
wiederhergestellt und jeweils separat auditiert. Keine Server-Logins,
Truststore-, Infrastruktur- oder Sicherheitslockerung.

Functional nutzte den portabel entdeckten schema-validierten Labvertrag,
`Encrypt=True` und dessen expliziten booleschen Trustwert ohne Fallback.
Authentifizierte TLS bleibt separat `not executed`. Die neuen Fälle zählen
zum gemeinsamen privaten endlichen Releaseprogramm; der ursprüngliche Start
und Verbrauch bleiben über Fortsetzungen erhalten. Kosten-/Tokenmessung ist
`UNKNOWN`.

## Verbleibende Grenzen und Fortsetzung

Die Minimalrechteprüfung umfasst eigene Verbindungen in der lokalen oder
zentralen Installationsdatenbank. Sie belegt **keine** Anmeldung oder
Lowpriv-CrossDB-Nutzermappings. Weitere Modulpflichtfälle, Provider-/Datei-/
Identitäts-/Worker-/Recovery-/Clientgates, die genannte Rechte-Dokumentation
und das finale Paket stehen weiter in den
[Releasegates](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt).

Die bestehende Offline-Release-Suite prüft die Source-/Binary-/Evidenzbindung;
sie ersetzt keinen nativen Minimalrechtetest:

```powershell
python -B Tests/Release/test_prepare_release.py
```

Die Releasefortsetzung ist jetzt ausdrücklich autonom freigegeben. Ein
Implementierungsverantwortlicher führt betroffene Tests aus; unveränderte
grüne Framework-/Funktions-/Lifecycle-Matrizen werden weiterverwendet.
Es entstehen keine neuen CI-Jobs oder Reviewketten. Echte aktuelle Head-CI
und nach autorisiertem Merge die tatsächliche Main-Push-CI werden separat
im PR dokumentiert. Veröffentlichungsfreigabe, Tag und GitHub-Release fehlen.
