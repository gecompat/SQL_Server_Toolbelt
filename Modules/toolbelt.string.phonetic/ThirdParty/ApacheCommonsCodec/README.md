# Apache Commons Codec – Herkunft und Lizenz

Die beiden markierten C#-Portierungen verwenden die vollständigen Scanner von
Apache Commons Codec 1.18.0, Commit `5f76abb946164b943bc2cf367bc1d70b8f6e70d1`.
Cologne Phonetic beschreibt das Verfahren von Hans Joachim Postel (1969);
Double Metaphone beschreibt das Verfahren von Lawrence Philips.

[Original ColognePhonetic.java](https://github.com/apache/commons-codec/blob/5f76abb946164b943bc2cf367bc1d70b8f6e70d1/src/main/java/org/apache/commons/codec/language/ColognePhonetic.java)
und [Original DoubleMetaphone.java](https://github.com/apache/commons-codec/blob/5f76abb946164b943bc2cf367bc1d70b8f6e70d1/src/main/java/org/apache/commons/codec/language/DoubleMetaphone.java)
sind die Primärreferenzen. Die unveränderten Apache-Lizenz- und NOTICE-Dateien
liegen daneben. Die Apache-Header sind in beiden Ports erhalten.

Änderungen vom 2026-10-04: C#-Port, festes geschlossenes Eingabealphabet,
begrenzte Eingabe-/Ausgabegrößen, vollständiger Double-Metaphone-Scanner ohne
Default-Vierzeichen-Clamp und eager SQL-CLR-Bridge. Das terminale alternative
J-Leerzeichen bleibt erhalten. Keine Aspell-Wortliste wurde übernommen.

Die Java-Bibliothek wird nicht installiert oder zur Runtime geladen. Ein
Versionswechsel erfordert erneuten Quellen-/Lizenzreview und Differentialtests;
bei Wegfall der Referenz bleibt diese Version mit dokumentierter Herkunft
festgeschrieben. Es gibt keine Drittanbieter-Binaryabhängigkeit.

## Externe Differential-Testreferenz 2026-10-08

Die Aussage zur fehlenden Java-Runtimeabhängigkeit betrifft das SQL-Produkt.
Der zusätzliche externe Offline-Testadapter verwendet ausdrücklich ausgewählte
Java/Javac-Inputs und elf unveränderte Referenzdateien: acht Javaquellen sowie
LICENSE, NOTICE und pom.xml. Das portable Manifest bindet Commit, Tree,
Version und jede Datei; die Referenz liegt außerhalb des Produkts unter einem
expliziten ReferenceDirectory. Kein automatischer Fetch, Installieren oder
Fallback. Der Differentiallauf bleibt NOT_EXECUTED; Herkunft und Lizenztexte
sowie die markierten Produktionsports bleiben unverändert.
