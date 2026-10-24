# Begrenzte Regex-Timeout-Untersuchung

Stand: 2026-10-24. Expliziter Benutzerauftrag: den offenen Timeout im Lab
untersuchen und beheben, Sicherheitsbudgets unverändert lassen, einen PR
vorlegen. Keine Veröffentlichung; autonome Weiterentwicklung bleibt pausiert.

## Befund und Korrektur

Der frühere SQL6522-Fehler in `Transformations.Contract.sql` kam aus
`RegexReplace` mit `TBX_REGEX_TIMEOUT` beim kooperativen Gesamtbudget.
Die sieben isolierten positiven Grenzaufrufe und die ursprüngliche vollständige
Fixture mit ihrem Text-Testvorlauf bestanden in dieser Untersuchung bereits
mit der alten qualifizierten DLL. Ein deterministischer Reproduktionsnachweis
für den historischen Timeout liegt damit nicht vor.

Der Replace-Pfad kopierte auch unveränderte große Quellen sowie einen
vollständigen Literalersatz über einen StringBuilder erneut. Die Korrektur
vermeidet diese Materialisierung nach derselben Validierung und erforderlichen
Suche. Occurrence=0 enumeriert weiterhin terminale leere Treffer. Die
abschließende Deadlineprüfung bleibt bestehen. Diese Kopien sind ein möglicher
Beitrag zum Timeout, keine bewiesene alleinige historische Ursache.

Der neue deterministische Frameworkvertrag weist den Kopierpfad bei der alten
DLL mit `REPLACE_REDUNDANT_NO_MATCH_COPY` nach. Er verlangt vollständige
Ergebnisbytes und unveränderte Semantik; Referenzidentität ist lediglich ein
internes Allokationsorakel. Die Grenzen bleiben 500/2000 ms insgesamt,
höchstens 250 ms je Suche und 2/16 MiB je Quelle/Ersatz/Output.

## Qualifikationsstand

[regex-timeout-qualification.json](regex-timeout-qualification.json) bindet den
ausgeführten Produktcommit, die ausgelieferte DLL, Methoden-/Fixturequellen
und tatsächlichen abstrakten Fälle. Private Journale und Labdaten bleiben lokal.

| Prüfung | Ergebnis am 2026-10-24 / Grenze |
|---|---|
| Unveränderte Diagnose | Sieben isolierte Byteorakel und ursprüngliche Transformationsfixture mit Text-Vorlauf bestanden bereits mit der alten DLL; historischer Timeout nicht reproduziert |
| Reproduzierbarer Build | Zwölf Projekte jeweils zweimal; Bytegleichheit und PE-/Pfadprüfung bestanden. Gegenüber der vorigen Lieferung änderte sich nur die Regex-DLL |
| Framework 4.8 | Alter Binarystand scheitert am neuen Kopierorakel; korrigierte DLL besteht. Bestehende Transformations-, Relations-, Intake- und Capturesuiten bestehen. 500/2000/250 ms und 2/16 MiB unverändert |
| Native Replace-/Substring-Grenzen | Ursprüngliche Transformationsfixture und sieben unabhängige vollständige Byteorakel auf allen zwölf Ziel-/CL-Kombinationen jeweils lokal und zentral bestanden |
| Weitere Regex-Regression | 203 Fixtureaufrufe bestanden, 1 Capture-Aufrufe bleiben blockiert. Direkte Clientmetadaten und zentraler Consumer eingeschlossen; keine vollständige neue Modulabnahme |
| CLR-Paket | Zwölf Fälle / 24 Deploymentpfade einschließlich Repeat, Consumer, Uninstall und separatem Cleanup bestanden |
| Vollständiges Toolbelt-Paket | Zwölf Fälle / 24 Deploymentpfade einschließlich Erstinstallation, hashgebundenem Repeat, Consumer, Uninstall und wiederholtem Uninstall bestanden |

Die physische Matrix ist Windows/Linux mit SQL2019 CL150, SQL2022 CL150/160
und SQL2025 CL150/160/170. Verwendet wurden die unveränderten kanonischen
`Invoke-ApiQualificationLab.ps1`, `Invoke-ClrPackageLab.ps1` und
`Invoke-CompletePackageLab.ps1` über einen privaten begrenzten Fallstarter.
Die Matrix-Orchestratoren wurden nicht erneut ausgeführt. Die zugehörigen
öffentlichen Fixtures und der zusätzliche
[Bytegrenzvertrag](../../Tests/Release/Runtime/Regex.Materialization.Boundaries.sql)
sind reproduzierbare Testinputs; das Lab wird weiterhin portabel entdeckt
und vor Verwendung schema-validiert.

Die neue gemeinsame Welle verbrauchte 40 von höchstens 48 Case-/
Diagnoseversuchen bei unverändertem ursprünglichen Start und 21600 Sekunden
Gesamtgrenze. Die inneren 300-/360-Sekunden-Fristen und der zusätzliche äußere
Watchdog blieben erhalten. Kosten-/Tokenmessung: UNKNOWN.

Jeder mutierende Fall hatte einen frischen separaten Cleanup-/Pinaudit.
Der abschließende unabhängige Gesamtaudit bestätigte alle
120 eigenen Datenbanknamen als abwesend und
67 zielgebundene Trustzustände als
wiederhergestellt oder unverändert. Eigene temporäre CLR-Konfiguration wurde
nach allen Verbrauchern wiederhergestellt und separat auditiert. Keine
Labressourcen, Logins, Rechte, Truststores, `clr strict security` oder
`TRUSTWORTHY` wurden geändert.

Functional verwendete `Encrypt=True` mit dem ausdrücklichen booleschen
Lab-Trustwert, ohne Fallback; authentifizierte TLS bleibt `not executed`.

## Verbleibender Capture-Teilnachweis

Auf Linux SQL2019/CL150 trat in der ursprünglichen
`Captures.Contract.sql` lokal ein zusätzlicher `TBX_REGEX_TIMEOUT` auf.
Die korrigierten Replace-/Substring-Grenzen bestanden im selben Lauf;
der Capture-Aufruf bleibt **PARTIAL**, einschließlich erfolgreichem Cleanup
und unabhängigem Audit. Eine anschließend mit Phase-/Fall-/Fehlerkontext
instrumentierte, ansonsten unveränderte Capture-Fixture bestand sowohl isoliert
als auch mit ihrem ursprünglichen Drei-Fixture-Vorlauf.
Dies beweist weder eine eindeutige Ursache noch eine Capture-Korrektur.
Es gab keinen unveränderten Retry und keine Budgeterhöhung.

Der ursprüngliche positive Transformationsabschluss ist auf der korrigierten
DLL belegt. Der neue Capture-Befund verhindert weiterhin eine vollständige
Regex-API-Freigabe; erforderliche Capture-, Minimalrechte-, Ressourcen-/Parallel-,
Upgrade-/Client- und Host-Recoveryfälle bleiben im jeweiligen Scope offen.
Die übrigen [Releasegates](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt)
bleiben separat. Historische Ergebnisse in
[API-QUALIFICATION.md](API-QUALIFICATION.md) werden nicht rückwirkend umgedeutet.

## Lieferbindung und Nachprüfung

Der aktualisierte [CLR-Installationssatz](CLR-INSTALL.md) enthält die neue
Regex-DLL sowie unveränderte übrige Binaries und eingebettete SQL-Bytes.
`clr-qualification.json` und `complete-qualification.json` binden die
tatsächlich geprüften SQL-/DLL-Payloads. Der Quellkandidat wird mit dem neuen
synthetischen Produktsnapshot erzeugt und gegen diese Payloads verglichen.
Metadatenpflege und aktuelle Anwendbarkeit sind von der Originalausführung
getrennt. Paketintegrität ist keine vollständige fachliche Freigabe.

Für eine eigene Framework-Nachprüfung unter Windows PowerShell 5.1:

```powershell
powershell -NoProfile -File Modules/toolbelt.string.regex/Tests/Runtime/run-framework-transformations.ps1 -AssemblyPath <ReleaseBinary>
```

Die bestehende Regex-CI führt denselben erweiterten Transformationsschritt aus.
Es wurden keine neuen Workflowjobs, Trigger, Reviewketten oder Modellorakel
eingeführt; die sieben zusätzlichen Assertions nutzen den vorhandenen Build.
Echte aktuelle Head-CI wird separat im PR nachgewiesen. Keine Veröffentlichung,
kein Mergeauftrag und keine Wiederaufnahme autonomer Weiterentwicklung.
