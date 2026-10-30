# JSON-Schema-Paket-IL-Nachweis

## Zweck

Dieser Nachweis prüft die vorhandene `Toolbelt.JsonSchema.dll` aus dem
CLR-Installationspaket mit dem bestehenden JSON-Closure-IL-Gate. Die
Paketprüfung ist ein eigener Nachweis nach der
[JSON-Constructor-Paketqualifikation](JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.md).
Der dortige Bericht und seine Quellen bleiben unverändert.

## Gebundene Eingaben

| Eingabe | Bindung |
|---|---|
| Vorgängerbericht | Öffentlicher Main-Commit `e559896b4f9e4f496a09bfa7b7c5d690512bc433`, exakter SHA-256 im maschinenlesbaren Bericht |
| CLR-Installationspaket | SHA-256 des unveränderten Constructor-Reports und dessen bestehender Sidecar-Prüfsumme |
| JSON-Schema-DLL | SHA-256 und Größe aus dem Paketmanifest; bytegleich mit dem erzeugten Framework-Output |
| JSON-Core-DLL | SHA-256 und Größe aus dem Paketmanifest; bytegleich mit dem erzeugten Framework-Output und als IL-Abhängigkeit geladen |
| Frameworkquelle | Bestehender abgeschlossener 27-Phasen-Receipt, alle erfolgreichen Witnesses, neun gepinnte Outputs und frische Eingaben |
| feste Orakel | `BridgeGoldens.tsv` und `NumberOracles.tsv` samt Hashes aus dem Vorgängerbericht |

Das Paket wird für die Validierung aus einem einzelnen gelesenen Bytepuffer
geprüft. Das Manifest muss die vollständigen Paketpfade und die gespeicherten
SHA-256-Werte samt Dateigrößen korrekt binden. Die Schema- und Core-DLLs werden
unter einem frischen privaten `.runtime`-Ziel extrahiert.

## Prüfung

Der erfolgreiche Quell-Frameworklauf wurde nicht erneut ausgeführt. Sein
privater Receipt wurde erneut als `COMPLETE` geprüft: 27/27 feste Phasen,
Post-Pins bestanden, 43 eingefrorene Eingabedateien unverändert, 38 öffentliche
Frameworkquellen aktuell hashgleich und neun erzeugte Binärdateien unverändert.
Das umfasst die festen Schema-, Zahlen- und Bridge-Orakel.

Anschließend lief `Test-JsonClosureIL.ps1` unter Windows PowerShell 5.1 direkt
auf der Schema-DLL aus dem geprüften Paket. Die paketgebundene Core-DLL wurde als
Abhängigkeit mit Hash-Pin übergeben. Der IL-Lauf bestand ohne unbekannte
Bindungen; neue Paket-/Framework-/Prozesseingaben wurden danach erneut geprüft.

Die vollständige Release-Regressionssuite bestand mit 148 Tests in 291,842 s.
Der separate Windows-Consumer-Check und die inkrementelle Dokumentationsprüfung
laufen zusätzlich über die bestehenden PR-/Main-Workflows.

Der frühere Source-IL-Eintrag bleibt als Source-IL ausgewiesen. Er wird nicht
rückwirkend als direkter Paketnachweis dargestellt.

Der spätere, davon getrennte [Deploy-AppLock-Funktionsnachweis](json-schema-deploy-lock-qualification.json)
prüft zwei konkrete Sperrkonflikte und positive Kontrollen auf einem lokalen
Windows/SQL-Server-2025/CL170-Ziel. Er erweitert diesen Paket-IL-Nachweis nicht
zu einer allgemeinen SQL-, API- oder Rechtequalifikation.

## Grenzen

Der Nachweis qualifiziert die Schema-DLL für den angegebenen festen IL-Scope.
Er belegt keine vollständige CLR- oder SQL-Qualifikation, keine API-Rechte,
keinen Modulstatus, keine TLS-Identität und keine Veröffentlichung. SQL und Lab
wurden nicht verwendet; Veröffentlichungs- und Tagfreigabe bleiben
nicht autorisiert.

Maschinenlesbare Werte, Hashes und Quelldateien stehen im
[JSON-Bericht](JSON-SCHEMA-PACKAGE-QUALIFICATION.json). Der Adapter und die
neun Offlineprüfungen sind in der bestehenden Release-Suite eingebunden.
