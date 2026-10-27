# JSON-Constructor: Frameworkprüfung der gelieferten DLLs

Der vorhandene Frameworklauf für `toolbelt.json.constructors` wurde mit den
`Toolbelt.JsonConstructors.dll`- und `Toolbelt.JsonCore.dll`-Bytes aus dem
gebundenen CLR-Installationspaket ausgeführt. Die Paketprüfsumme und beide
Einträge wurden gegen Sidecar und `CLR-PACKAGE.json` geprüft. Danach wurden die
beiden DLLs in einem neuen privaten `.runtime`-Verzeichnis mit dem bestehenden
Quell-Frameworklauf verglichen. Beide DLLs waren bytegleich zu dessen
in diesem Lauf erzeugten Ausgaben. Anschließend bestand der vorhandene
JSON-Core-Closure-IL-Gate direkt auf der Constructor-Paket-DLL und ihrer
gebundenen Core-Abhängigkeit.

Die festen synthetischen `BridgeGoldens.tsv`-Orakel bestanden in den drei
vorhandenen Kulturen mit je 37 Ergebniszeilen und 960 Assertions. Der große
Grenzfall bestand mit drei Ergebniszeilen und 67 Assertions. Insgesamt wurden
27 Frameworkphasen mit vollständigen Nachpins abgeschlossen. Der
JSON-Schema-Teil des bestehenden Quelllaufs war nicht an die Schema-DLL im
Paket gebunden und wird hier nicht als Paketnachweis ausgewiesen.

Die maschinenlesbare [Qualifikationsprojektion](JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.json)
bindet den öffentlichen Paket- und DLL-SHA-256, die unveränderte Goldenquelle,
die geprüften Phasen und die Scopegrenzen. Die Prüfung verwendete weder SQL
noch eine Labverbindung. Sie erweitert weder API- oder Minimalrechte-,
Ressourcen-, Lifecycle- noch Gesamt-CLR-Nachweise und ändert keine
Modulstatus- oder Veröffentlichungsfreigabe.

Sieben Tests in der bestehenden Release-Suite prüfen den Report, den
Paketbindungsparser und seine Negativgrenzen. Der Runner
`Tests/Release/Invoke-JsonConstructorsPackageQualification.ps1`
prüft Paket-Sidecar, Archivpfade, Manifestgrößen und DLL-Hashes, extrahiert nur
die beiden festgelegten Dateien in ein neues ignoriertes `.runtime`-Ziel und
prüft die Quellen sowie extrahierten DLLs nach Ausführung erneut. Die sieben
Regressionen in `Tests/Release/test_json_constructor_package_gate.py`
kontrollieren falsche Archiv- und DLL-Pins, zusätzliche und doppelte Einträge,
Pfadtraversierung, unzulässige Ausgabepfade und die aktuelle öffentliche
Projektion.

Die vollständige bestehende Release-Regressionssuite bestand am 2026-10-27:
`python -B Tests/Release/test_prepare_release.py` — 139 Tests in 298,935
Sekunden. Die sieben neuen Paket-, Evidenz- und Pfadtests liefen darin mit.
Eine erste Adapterinitialisierung scheiterte vor der ersten Frameworkphase an
der Hostauswahl; sie wird im Bericht getrennt mit null ausgeführten Phasen
geführt.

Der Lauf am 2026-10-27 erfolgte mit dem bereits vorhandenen Roslyn-Compiler,
PowerShell 7 als Prozesshost und Windows PowerShell 5.1 für Reflection. Es
wurde nichts installiert. Die vollständigen Prozessausgaben und Laufbelege
liegen ausschließlich im privaten, ignorierten `.runtime`-Verzeichnis.
