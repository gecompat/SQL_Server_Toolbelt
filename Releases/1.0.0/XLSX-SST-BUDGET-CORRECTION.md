# XLSX: SST-Budgetkorrektur des Quellkandidaten

Der korrigierte Quellkandidat besteht die unveränderte Grenze von 50.000
Shared Strings sowie die Abweisung von 50.001 auf zwölf Windows-/Linux-
Ziel-/Kompatibilitätsfällen, jeweils lokal und direkt zentral. Das Zeitbudget
bleibt auf höchstens 5.000 ms begrenzt; kleinere Werte von 1 bis 5.000 ms und
alle übrigen Größen-, XML-, Allokations- und Sicherheitsgrenzen bleiben erhalten.
Die [gebundene Evidenz](xlsx-sst-budget-correction.json) und der
[Kandidaten-Snapshot](Artifacts/Xlsx-Sst-Budget-Candidate.zip) enthalten die
konkrete neue DLL- und Quellenbindung.
Das Kandidatenarchiv enthält die vollständige unveränderte Repositorylizenz
einschließlich Urheberangabe in der kanonischen LF-Fassung.

## Korrektur und feste Orakel

Die isolierte Diagnose zeigte einen erheblichen Kostenanteil der häufigen
präzisen Uhrabfrage im SQL-CLR-Host. Die erste alternative Berechnung mit
rohen präzisen Zeitstempeln löste den Budgetfehler nicht und wurde verworfen.
Die neue Implementierung verwendet `Environment.TickCount` nur zum Planen
der inneren präzisen Prüfungen. Die präzise Uhr startet weiterhin am
ursprünglichen Feldinitialisierer. `Checkpoint()` und die Freigabe der
materialisierten Ergebnisse prüfen weiterhin präzise mit `elapsed >= budget`.
Bei Budgets bis einschließlich 32 ms bleibt jede Zwischenprüfung präzise.
Der 32-ms-Abstand ist eine Planungsmarge, keine Zusage über die Auflösung
der Betriebssystemuhr. Das Budget bleibt kooperativ; einzelne
Frameworkoperationen und SQL-Marshalling sind nicht unterbrechbar.

Die Workbooks enthalten weiterhin 50.000 beziehungsweise 50.001 eindeutige
Strings. Die positiven Referenzen 0, 24.999 und 49.999 liefern die festen
Texte `v00000`, `v24999` und `v49999`: 24 erfolgreiche Routen und insgesamt
72 geprüfte Ergebniszeilen. Alle 24 Overflow-Routen weisen vor der ersten
Zeile SQL-Fehler 51520 mit `TBX_XLSX_SHARED_STRING_COUNT_LIMIT` nach.
Zwölf unmittelbare und sechs abschließende Leseaudits bestanden; die
24 eigenen Datenbanken und 24 eigenen Trusteintragsereignisse wurden bereinigt.
Diese Ereignisse sind keine Anzahl unterschiedlicher Hashes.

## Framework, IL und ursprüngliche Quellen

Der deterministische Doppelbuild wurde gegen die unveränderten ZIP-DLL-
Bytes gebunden. Der Uhr-Grenztest bestand mit 35 Assertions. Von den
19 bestehenden Frameworkphasen bestanden zunächst 18. `OwnIL` wies den
neuen Uhrzugriff ab; dieser ursprüngliche Fehlerbeleg bleibt erhalten.
Ein gezielter Nachfolgelauf bestand mit der engen Zulassung ausschließlich
von `System.Environment.get_TickCount` als statischer, parameterloser
Methode mit `int`-Ergebnis. Die Negativkontrollen für `MachineName` und
`GetEnvironmentVariable(string)` werden nicht zugelassen und nicht aufgerufen.
Die übrigen 18 unveränderten Phasen wurden nicht wiederholt. Zusammen sind
die 19 Phasen quellengebunden nachgewiesen; der erste Gesamtlauf wird
weiterhin als fehlgeschlagen ausgewiesen.

Die früheren Paket-, Caller- und Grenzberichte behalten ihre ursprünglichen
Ausführungspins. Für die inzwischen geänderten Dateien `Workbook.cs` und
`Test-ProviderIL.ps1` prüfen ihre Adapter die exakten alten Bytes aus dem
unveränderten Kandidaten-Quellarchiv und binden zusätzlich den neuen Stand.
Der neue Workbook-Nachweis trennt die ausgeführte Quelle mit genau einer
CRLF-Zeile von ihrer verlustfrei rekonstruierten LF-Fassung im Repository.
Die private Kopie des bestehenden SQL-Grenztreibers änderte ausschließlich
die Repository-/Helperpfadbindung; Orakel und Bereinigung bleiben erhalten.
Zwei historische JSON-Berichte lagen im lokalen Kontext mit vollständigen
CRLF-Zeilenenden vor. Ihre ursprünglichen lokalen Hashes und die exakten
LF-Fassungen sind getrennt gebunden; nur diese verlustfreie Projektion wird
für Cold-Checkouts akzeptiert. Inhalte und native Ausführungspins bleiben
unverändert.

## Gemeinsame Offline-Testdatei

Eine nachfolgende unabhängige Änderung zur Fensterunterdrückung ergänzte
Hilfsfunktionen in `Tests/Release/test_prepare_release.py`. Die zunächst
verwendete Bindung der gesamten Sammeldatei war dafür zu breit. Der
[unveränderte qualifizierte Dateistand](Artifacts/Xlsx-Sst-Offline-Test-Source.zip)
bleibt mit seinem ursprünglichen SHA-256 einschließlich Lizenz erhalten.
Die aktuelle Bindung prüft gezielt die Klasse
`FunctionCallerQualificationTests`, ihre Basen und Decorators, vorhandene
Setup-/Teardown-Fixtures und den vollständigen Quelltext der Methode
`test_fixed_function_compositions_and_current_native_reports` einschließlich
ihrer Decorators. AST-Positionen grenzen die Quelltextblöcke ein;
LF-/CRLF-Zeilenenden werden dabei kanonisch verglichen.
Modulimporte, globale Initialisierung und rekursiv referenzierte Helfer
gehören ebenfalls zur Bindung. Ein Austausch des Release-Loaders oder
eine globale Umbindung der Klasse kann die Prüfung damit nicht umgehen.

Unabhängige Top-Level-Helfer und andere Tests werden dadurch nicht als
SST-Ausführungsquellen eingefroren. Änderungen an der gebundenen Methode,
ihren Decorators, der Klassenbasis oder den Fixtures sowie fehlende oder
doppelte Methoden werden weiterhin erkannt. Produkt-DLL, native Orakel,
vorherige Berichtspins und fremde Fensterunterdrückungsänderungen bleiben
unverändert; es wurden keine SQL-Läufe wiederholt.

## Verbleibende Releasegates

Das vorbereitete CLR-Installationspaket enthält weiterhin die frühere DLL.
Sein [ursprünglicher SST-Budgetfehler](XLSX-BOUNDARY-QUALIFICATION.md) bleibt
für diese Paketbytes gültig. Der neue Snapshot ist ein separat qualifizierter
Quellkandidat und kein aktualisiertes Installationspaket. Vor einer finalen
Releaseabnahme sind Paketpflege, die erforderlichen Nachweise für die neuen
Paketbytes und die übrigen [Releasegates](RELEASE-GATES.md) abzuschließen.
Modulstatus bleibt `partially validated`, Releasezustand `unreleased`;
Veröffentlichung und Tags sind nicht freigegeben. SSIS ist nicht Bestandteil
dieser Korrektur.
