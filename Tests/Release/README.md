# Releasevorbereitung offline prüfen

Die Tests prüfen den [Releasegenerator](../../Scripts/Release/prepare_release.py)
und die [v1.0.0-Freigabematrix](../../Releases/1.0.0/README.md). Es werden
keine SQL-Verbindungen, Labressourcen, Builds, Tags oder Veröffentlichungen erzeugt.

```powershell
python -B Tests/Release/test_prepare_release.py
```

Geprüft sind transitive Kanalbegrenzung und Dependencyfehler, unveränderter
Publikationsstatus, Manifest-/Matrixdrift, Ausschluss privater Pfade,
ZIP-Pfadsicherheit, Symlinks und doppelte Pfade. Der vorhandene
Dokumentationsvalidator ruft diesen Test impactbezogen auf.

Der tatsächliche Paketbau ruft zusätzlich den vorhandenen verbindungsfreien
SQL-Exporter für die stabilen Kandidaten lokal und zentral auf. Der anschließende
Prüfmodus vergleicht alle Dateien, Prüfsummen und den eingefrorenen Gitstand.
Die generierten SQL-Dateien werden erneut offline exportiert und bytegenau
verglichen; ein nachträglich passend gehashtes SQL kann diese Bindung nicht ersetzen.
Das ist eine Packagingprüfung; eine native Installation oder die fachliche
Veröffentlichungsabnahme wird daraus nicht abgeleitet.
