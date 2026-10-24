# Capture-Timeout: Diagnose und offener Produktbefund

Dieser Bericht bewahrt den Untersuchungsstand vor der anschließenden
Benutzerentscheidung. Die spätere [begrenzte Capture-Abnahme](CAPTURE-RELEASE-ACCEPTANCE.md)
schließt das historische Timeout-Gate für die gebundene DLL mit ausdrücklich
akzeptiertem Restrisiko; sie behauptet keine nachträglich bewiesene Ursache.

Stand: 2026-10-24. Dieser Bericht folgt der
[vorherigen Regex-Untersuchung](REGEX-TIMEOUT-QUALIFICATION.md) und dem
ausdrücklichen Auftrag zur Capture-Timeout-Behebung. Es wird nichts
veröffentlicht; die autonome Weiterentwicklung bleibt pausiert.

## Ergebnis und Grenze

Der historische `TBX_REGEX_TIMEOUT` in `Captures.Contract.sql` unter Linux
SQL2019/CL150 local ließ sich nicht reproduzieren. Eine Capture-Korrektur im
Produktcode ist deshalb **nicht belegt**. Das Capture-Releasegate bleibt offen.
Ein bestandener Diagnoselauf ersetzt weder den früheren Teilnachweis noch
eine Ursachenanalyse. Es gibt keine neue DLL, API oder erhöhte Sicherheitsgrenze.

Korrigiert wurde ein nachgewiesener Diagnoseverlust des Release-Testadapters:
Als `PARTIAL` behandelte Regex-Timeouts enthielten bisher nur Fixture, Kontext
und Präfix. Der ursprüngliche Fehlertext mit CLR-Stack ging verloren; bei
Capture fehlten zusätzlich Phase und Fallnummer.

Der Adapter ergänzt im ausgeführten Capture-Testtext einen äußeren Fehlerpfad.
Nur bei unerwartetem Fehler sendet dieser einen synthetischen Phasen-/Fallmarker
und wirft den ursprünglichen SQL-Fehler erneut. Alle kanonischen Fixturebytes
und strikten Orakel bleiben nach Entfernen dieser Annotation exakt erhalten.
Ein gefilterter, an seinen Zustand gebundener SqlClient-Callback nimmt den
Marker auf; der Handler wird auch im Fehlerfall entfernt. Fehlertext und
Unterfall stehen ausschließlich im bereits privaten Casejournal. Ein Timeout
bleibt `PARTIAL`, niemals `PASS`. Quelldrift oder doppelte Annotation werden
abgewiesen.

## Tatsächlich ausgeführte Prüfungen

Die [abstrahierte Evidenz](capture-timeout-investigation.json) bindet Quellen,
Sicherheitsgrenzen und Ergebnisse. Private Journale, Fehlertexte, Zeiten,
Endpoints und Trustdetails werden nicht veröffentlicht.

| Prüfung | Ergebnis und Aussagegrenze |
|---|---|
| Private Ablaufspur mit ursprünglichem Drei-Fixture-Vorlauf | Vier Fixtureaufrufe bestanden; alle 58 Capture-Unteraufrufe mit unveränderten Orakeln bestanden. Historischer Timeout nicht reproduziert |
| Gezielter Timeout im ersten Capture-Unterfall | Lokal und zentral tatsächlich `PARTIAL`; ursprünglicher SQL6522/Timeout, CLR-Stack und genauer Unterfall blieben erhalten |
| Gezielter Timeout statt des erwarteten Größenfehlers im Negativfall 27 | Lokal und zentral tatsächlich `PARTIAL`; der falsche Fehler wurde nicht als bestandener Negativtest gewertet. Phase, Fall und CLR-Stack blieben erhalten |
| Ursprüngliche Capture-Fixture mit neuer Fehlerdiagnose | Ursprünglicher Drei-Fixture-Vorlauf lokal sowie Capture-Vertrag und direkte Clientmetadaten lokal/zentral: sieben Fixtureaufrufe bestanden. Große Capture-Ausgabegrenzen aus dem unveränderten Metadatenhelfer eingeschlossen |
| Offline-Vertrag | Bytegenaue Wiederherstellung der kanonischen Fixture, unveränderter Rethrow, Ablehnung von Drift/Doppelannotation und gefilterter Callback in getrenntem ScriptScope bestanden |
| Unabhängiger Cleanup-/Pinaudit | Nach jedem Fall separat bestanden. Abschließend zwölf eigene DB-Namen abwesend und neun zielgebundene Trustzustände wiederhergestellt oder unverändert; keine Konfigurationsänderung |

Native Ausführung: der kanonische `Invoke-ApiQualificationLab.ps1` mit
eingefrorenen privaten Eingaben und einem begrenzten privaten Fallstarter;
die beiden absichtlichen Fehlerproben verändern ausschließlich synthetische
Testparameter. Ihr erwartetes `PARTIAL` ist Diagnoseevidenz und kein
erfolgreicher API-Grenznachweis. Die Produkt-, Deployment-, DLL- und
kanonischen Modulfixturebytes blieben unverändert.

Alle vier Case-/Diagnoseversuche teilen den ursprünglichen endlichen Rahmen
von höchstens 48 Versuchen und 21600 Sekunden. Die inneren 300-/360-Sekunden-
Grenzen und der zusätzliche äußere 400-Sekunden-Watchdog blieben erhalten.
Kein Budgetreset oder unveränderter blinder Retry. Functional verwendete den
schema-validierten portabel entdeckten Labvertrag, `Encrypt=True` und dessen
ausdrücklichen booleschen Trustwert ohne Fallback. Authentifizierte TLS ist
weiter `not executed`. Kosten-/Tokenmessung: `UNKNOWN`.

## Nachprüfung und nächster Schritt

Die [Release-Testanleitung](../../Tests/Release/README.md#api--und-grenzqualifikation)
beschreibt private Runsets und die neuen Diagnosefelder. Die vorhandene
Offline-Suite führt den neuen Diagnosevertrag mit aus:

```powershell
python -B Tests/Release/test_prepare_release.py
```

Bei einem künftig unerwarteten Capture-Timeout zuerst den privaten Unterfall
und CLR-Stack auswerten, anschließend nur eine durch den konkreten Befund
begründete Probe mit geänderten relevanten Eingaben planen. Es wurde kein
reproduzierbarer Produktdefekt identifiziert, der jetzt eine fachliche
Änderung oder einen weiteren unveränderten Testlauf rechtfertigt. Eine
größere Zeitreserve oder die Akzeptanz eines Timeouts als Größenfehler
wären keine Korrektur.

Die übrigen elf unveränderten grünen Regex-Ziel-/CL-Nachweise, vorgebauten
Pakete und deren Lifecycle-Evidenz wurden nicht zur Statusauffrischung
wiederholt. Der frühere Methodenstand bleibt durch seinen Hash im
unveränderten Quell-ZIP belegt; die neue Adapterbindung steht separat in der
Capture-Evidenz. Kein historischer Hash wurde auf neue Bytes umgeschrieben.
Der ausgelieferte Kandidat behält seine bisherigen Paketbytes; eine spätere
finale Paketaktualisierung und echte Head-CI bleiben eigene Gates.
Minimalrechte-, Heap-/Parallel-, Host-Recovery- und übrige
[Releasegates](RELEASE-GATES.md#was-vor-veröffentlichung-offen-bleibt) bleiben
offen. Keine Statusaufwertung, neue Workflowjobs oder zusätzliche Reviewkette.
