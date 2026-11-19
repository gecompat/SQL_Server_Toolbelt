# Versionierter rc.4-Release- und Installationssatz

Dieser Ordner enthält den neuen Ein-Aufruf-Installationssatz, Quellkandidaten,
Prüfsummen und Buildbeleg. Für Anwender beginnt der Weg bei der
[Kurzanleitung](../../RC4-INSTALL.md); die [Releasehinweise](../../RC4.md)
erklären die getrennte Bindung der neuen Vorbereitung und der alten SQL-Basis.

Die ZIPs entstehen aus dem in `BUILD-RECEIPT.json` genannten Vorbereitungscommit.
Der spätere Release-Tag zeigt auf die grüne Integration dieser fertigen Dateien
nach main. Deshalb sind Quellen- und Tagcommit absichtlich getrennt.
Die gelieferten ZIPs bleiben in Git, werden aber aus späteren Git-Quell-Exports
ausgeschlossen, damit keine rekursiv wachsenden Pakete entstehen.
