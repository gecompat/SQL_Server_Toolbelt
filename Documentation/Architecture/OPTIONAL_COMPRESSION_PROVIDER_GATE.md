# Gate für optionale Kompressionsprovider (`TC-2026-036`)

## Ergebnis

`TC-2026-036` bleibt zurückgestellt, bis ein konkretes Format und ein
belegter Anwendungsfall vorliegen. Es wird kein generisches
`Compress(format, payload)`-Objekt vorbereitet.

Kompressionsalgorithmen, Container und Datei-I/O haben unterschiedliche
Sicherheits-, Lizenz-, Deployment- und Interoperabilitätseigenschaften. Ein
allgemeiner Formatparameter würde diese Unterschiede hinter einer scheinbar
einheitlichen API verbergen und unkontrollierte Providerzulassung fördern.

## Wiederaufnahmebedingung

Für ein einzelnes Format muss vor der Funktionsbesprechung dokumentiert sein:

| Entscheidung | Mindestinhalt |
|---|---|
| Format und Interoperabilität | Exaktes Formatprofil, erzeugende/lesende Gegenstelle und benötigte Features. |
| Nutzen | Warum ZIP oder native Gzip-Wertfunktionen nicht genügen. |
| Datenfluss | In-memory, Datei oder Stream; maximale komprimierte und dekomprimierte Größe. |
| Provider | Standardbibliothek oder konkrete Abhängigkeit einschließlich Lizenz, Wartung, CVE- und Supply-Chain-Verantwortung. |
| Sicherheit | Bomb-/Outputlimits, Checksummen, Fehlerverhalten, verschlüsselte Container und Metadatenbehandlung. |
| Plattform | Unterstützte SQL- und Betriebssystemmatrix sowie Deployment-/Trust-Voraussetzungen. |

Erst danach wird ein separates Modul `toolbelt.compression.<format>` mit
formatbezogenem Vertrag erwogen. Der Bedarf für Brotli, Zstandard, bzip2, 7z
oder andere Formate wird nicht aus einer allgemeinen Wunschliste abgeleitet.

## Abgrenzung

ZIP bleibt ein eigener Containervertrag. Gzip ist wegen fehlendem belegten
Mehrwert eines Stream-/Dateiadapters separat zurückgestellt. Dieser Gate-Text
ist keine Implementierungsfreigabe und trifft keine Auswahl für eine externe
Bibliothek.
