# Historische Dokumentation für gebundene Release-Nachweise

`QualifiedDocumentation.zip` bewahrt acht Objektbeschreibungen exakt aus
Commit `9363cb42eff328590276ad4d4f2289d4f3575262`, dem Main-Stand vor der
Objektreferenz aus PR #482, einschließlich der unveränderten Lizenz.
Der SHA256 des Archivs ist
`71af74733f2c8429a0a0e408e5b7499328ffb299ece3ec0be123313ef820c1fd`.

Diese Texte gehören ausschließlich zu den ursprünglichen Help-/CSV-/XLSX-
Nachweisen. Die aktuelle [Objektreferenz](../../../../Documentation/Reference/README.md)
darf ihren Parametervertrag weiter präzisieren; diese neuen Texte werden
nicht durch historische Runtime-Nachweise qualifiziert. Native Berichte,
SQL-/CLR-Quellen, Fixtures, Binaries und ursprüngliche Pins bleiben erhalten.

[`documentation_history.py`](../../documentation_history.py) liest nur
diese acht exakt registrierten Dokumentpfade aus dem hashgebundenen Archiv.
Alle ausführbaren Produktquellen werden weiterhin direkt aus dem aktuellen
Repository geprüft. Die zwei eng begrenzten Checkerprojektionen nehmen nur
die expliziten Dokument-Leseadapter zurück, bevor bestehende Methodenpins
geprüft werden; andere Änderungen bleiben Fehler. Der aktuelle Leseadapter
behauptet keine neue native Ausführung oder Qualifikation seiner selbst.

Die normalen Dokumentations-, Katalog- und Lesewegprüfungen prüfen die aktuellen
Texte. Das Archiv ist keine aktive Anleitung und kein Installationspaket.
