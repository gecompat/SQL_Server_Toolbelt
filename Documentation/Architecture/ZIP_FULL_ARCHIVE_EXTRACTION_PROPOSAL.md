# Vorschlag: Vollständige ZIP-Archivextraktion ins Dateisystem (`TC-2026-034`)

## Stand und Freigabegrenze

Stand 2026-11-13: Der Benutzer hat die vorgeschlagene Funktionsrichtung
bestätigt: alle regulären Datei-Entries des Archivs verarbeiten, beim ersten
Fehler anhalten und pro Entry einen Status ausgeben. Ressourcenlimits sind
zulässig, müssen aber durch den Aufrufer steuerbar und innerhalb des
qualifizierten technischen Bereichs erweiterbar sein. Diese Planungsantwort
genehmigt den Vertrag im hier beschriebenen Umfang zur weiteren Besprechung;
sie ist keine Source-, Test-, Lab-, Rechte- oder Veröffentlichungsfreigabe.
Der Benutzer ergänzte am selben Tag: vorhandene Dateien standardmäßig nicht
überschreiben; das Verhalten soll aber über einen Aufrufparameter explizit
aktivierbar sein. Ein aktiviertes Überschreiben ersetzt nur die jeweilige Datei
atomar und ändert weder Stop-at-first-error noch die Teilergebnis-/Nicht-
Archivatomaritätsregeln.

Die In-memory-Erzeugung `USP_CreateZipFromEntries` ist bereits ausdrücklich
freigegeben und implementiert. `toolbelt.archive.zip-files` 1.0.0 stellt
außerdem einzelne Entry-zu-Datei-Extraktion und Datei-basierte ZIP-Erzeugung
bereit. Dieser Vorschlag betrifft ausschließlich die neue vollständige
Archiv-zu-Dateisystem-Operation; bestehende Einzel-Entry- und Writerverträge
bleiben unverändert.

## Vorgeschlagener V1-Vertrag

- Eine neue öffentliche USP im vorhandenen `toolbelt.archive.zip-files`-
  Modul verarbeitet alle Datei- und Directory-Entries des gelieferten
  `varbinary(max)`-Archivs. Ein optionaler Caller-Entryfilter ist nicht Teil
  von V1; gezielte Einzel-Entry-Auswahl bleibt durch die vorhandene API
  abgedeckt.
- Das Ziel wird ausschließlich durch einen vorhandenen `RootAlias` und einen
  relativen Zielordner unter diesem Root bestimmt. Freie absolute Pfade,
  Netzwerkpfade und automatische Rootanlage sind ausgeschlossen.
- ZIP-Verzeichnis-Entries werden unter dem Root tatsächlich angelegt.
  Benötigte Elternverzeichnisse dürfen sicher implizit angelegt werden, sofern
  der konfigurierte Root die vorhandene `AllowCreateDirectory`-Operation
  erlaubt. Existiert ein Zielverzeichnis bereits als Directory, gilt der
  Directory-Entry als erfolgreich; ein gleichnamiges File ist ein Fehler.
- Absolute-, UNC-, Laufwerks-, Device-, ADS-, Traversal-, NUL- und
  Reparse-/Symlinkpfade werden fail-closed abgewiesen. Namen werden nicht
  stillschweigend normalisiert oder umgeschrieben. Zwei verschiedene ZIP-Namen,
  die auf dem Zielsystem denselben Dateipfad bezeichnen würden, sind eine
  Kollision.
- Zuerst wird das Central Directory vollständig geprüft: Struktur, Entryzahl,
  Namen, sichere Zielpfade, Duplikate/Kollisionen, bekannte Größen und
  bestehende Zielkonflikte. Erst danach beginnt die erste Dateimutation.
  Payload, CRC und tatsächliche Expansion werden pro Entry während der
  Extraktion geprüft.
- Entries werden in Central-Directory-Reihenfolge nacheinander extrahiert.
  Der erste Entryfehler stoppt weitere Verarbeitung. Jede einzelne Datei wird
  über den bestehenden atomaren Staging-/Publish-Vertrag veröffentlicht;
  Dateien früherer erfolgreicher Entries bleiben bei einem späteren Fehler
  erhalten. Es gibt keine Behauptung gemeinsamer Archiv-/Dateisystematomarität
  und keinen kompensierenden Delete.
- Überschreiben von Dateien ist standardmäßig aus. Der vorgeschlagene
  Aufrufparameter `@OverwriteExistingFiles bit = 0` kann Überschreiben
  aktivieren; er ersetzt nur die jeweilige
  Datei atomar und macht den gesamten Archivlauf nicht atomar. Das
  Overwriteverhalten und Zielkonflikte werden im Resultat eindeutig
  diagnostiziert.
- Das Ergebnis enthält für jeden Archiv-Entry seinen Ordinal und Status
  (`completed`, `failed` oder `not_attempted`), einschließlich Directory-
  Entries, sowie den kontrollierten Fehlercode für den Abbruch. Erfolgreiche
  Einträge werden nicht nachträglich als fehlgeschlagen dargestellt. Pfade und
  Fehlermeldungen erscheinen nicht in Debug-/Serverlogs.

## Steuerbare Ressourcenlimits

Jede Größen- und Anzahlgrenze erhält einen konservativen Default sowie einen
vom Caller pro Aufruf steuerbaren Wert. Der vorgeschlagene Parametervertrag ist:

| Parameter | Typ | Bedeutung |
|---|---|---|
| `@MaxArchiveBytes` | `bigint` | Länge des kompletten ZIP-Inputs |
| `@MaxEntries` | `bigint` | Zahl sämtlicher Dateien und Verzeichnisse |
| `@MaxEntryBytes` | `bigint` | Maximal expandierte Nutzdaten je Datei |
| `@MaxTotalExpandedBytes` | `bigint` | Summe expandierter Nutzdaten aller Dateien |
| `@MaxCompressionRatio` | `decimal(9,2)` | Maximales tatsächliches Expansionsverhältnis je Datei |
| `@MaxPathLength` | `int` | Maximale ZIP-Entryname-Länge in UTF-16-Codeeinheiten |
| `@OverwriteExistingFiles` | `bit` | `0` (Default) verweigert vorhandene Dateien; `1` erlaubt atomaren Ersatz pro Entry |

Die Ressourcengrenzen sind unabhängig voneinander; NULL/0/negativ ist ungültig,
keiner dieser Werte bedeutet unbegrenzt. Ein höherer zulässiger Wert wird beim
Aufruf ausdrücklich übergeben und darf nicht durch einen kleineren festen
internen Wert stillschweigend gekappt werden. Defaults und der initial
qualifizierte caller-steuerbare Wertebereich werden erst nach technischer
Prüfung festgeschrieben.

Es soll keine willkürliche, unveränderliche Produktgrenze unterhalb der
repräsentierbaren ZIP-/SQL-/Providergrenzen geben. Kann ein angeforderter Wert
die durch Datentypen, ZIP-Felder oder den qualifizierten Provider tatsächlich
unterstützte Grenze überschreiten, muss die Fehlermeldung die betroffene
Dimension und den aktuellen Maximalwert nennen. Eine Erweiterung erfolgt dann
als konkret qualifizierte Provider-/Versionsänderung; der öffentliche Vertrag
muss den Wert nicht dauerhaft auf das erste Default-/Ceilingprofil einfrieren.
Ein Limit darf nie stillschweigend abgesenkt werden. Harte technische Grenzen
und caller-steuerbare Betriebsgrenzen sind in Hilfe und Tests getrennt
auszuweisen.

Die Architektur soll Entrypayloads sequenziell und begrenzt streamen, statt
das gesamte expandierte Archiv gleichzeitig im Speicher zu halten. Falls der
bestehende Binary-Reader diese Anforderung oder höhere caller-gesteuerte
Einzel-Entrywerte nicht erfüllt, ist eine gezielte Providererweiterung für
diesen Slice einzuplanen; das bestehende Einzel-Entry-API wird dadurch nicht
stillschweigend geändert.

## Noch im Vertragsreview festzulegen

Vor der Implementierungsfreigabe sind folgende technische Details mit den
bestehenden Verträgen abzugleichen und als konkrete Signatur/Resulttable
festzuhalten:

1. **Ergebnisform (Vorschlag):** `Ordinal bigint`,
   `EntryName nvarchar(max)`, `EntryKind varchar(8)`, `Status varchar(16)`,
   `BytesWritten bigint NULL`, `ErrorCode varchar(64) NULL`. Central-Directory-
   Reihenfolge; genau eine Zeile je gelisteten Entry. Directory-Entries erhalten
   `EntryKind='directory'`, Status `completed` und BytesWritten `0`, wenn das
   Verzeichnis existiert oder angelegt wurde; Dateien erhalten
   `EntryKind='file'` und `completed`, `failed` oder `not_attempted`. Implizite
   Elternverzeichnisse erhalten keine eigene Entryzeile. Bei erstem Fehler wird
   dieser Entry `failed`, spätere
   Entries `not_attempted`; frühere `completed`-Ergebnisse bleiben erhalten.
   Malformed Archive ohne lesbares Central Directory liefern vor Mutation den
   regulären Modulfehler, weil keine verlässliche Entry-Liste existiert.
2. Name, Position/Default und Validierung des Overwrite-Parameters sowie
   Ergebnisnamen/-typen; genaue bekannte Ressourcen- und
   fachliche Fehlercodes, plus Verhalten eines Fehlers vor der Entryauflistung.
3. Identitätsprofil: vorhandenen Caller-/ServiceAccount-Vertrag übernehmen;
   kein neuer RunAs-Modus durch diesen Slice.
4. Defaultwerte und zunächst unterstützte caller-steuerbare Maxima pro
   Ressourcendimension nach Streaming-/Format-/SQL-Grenzqualifikation.
5. Wie Zielkonflikte vorab geprüft und konkurrierende Änderungen zwischen
   Preflight und atomarem Publish gemäß dem vorhandenen Root-/Reparse-/Race-
   Vertrag behandelt werden.
6. Welche vorhandenen Rootrechte für Root-Lesen, Zielschreiben, Auflisten und
   Verzeichniserstellung erforderlich sind; keine automatische Rechtevergabe.
7. ResultTable-Integration und Verhalten bei Fehlern, nachdem vorherige
   Dateien bereits veröffentlicht wurden.

## Entwicklungs- und Qualifikationsplan nach Freigabe

1. Den finalen Vertrag samt Limits, Fehlerpriorität und Resultschema einfrieren;
   die Implementierungsfreigabe des Benutzers dokumentieren.
2. Den bestehenden ZIP-Reader, ZIP-Filesystemprovider und
   `WriteBinaryFile`-Stagingkern wiederverwenden. Keine zweite ZIP-Parser- oder
   Root-Sicherheitsimplementierung anlegen.
3. Den gesamten Central-Directory-Preflight ohne Dateimutationen ausführen;
   erst nach erfolgreichem Preflight pro Entry staging, CRC-/Expansionprüfung
   und atomaren Publish ausführen.
4. Synthetische Tests für leere Archive, gemischte Dateien/Verzeichnisse,
   explizite Directory-Entries mit tatsächlicher Anlage und Status `completed`,
   implizite Elternverzeichnisse und File-/Directory-Kollisionen,
   Traversal-/absolute-/NUL-/Symlinknamen, Exact-/Case-Kollisionen,
   bestehende Ziele, defekte spätere Entries, CRC-/Ratiofehler, Callergrenzen,
   überhöhte Werte, gleichzeitige Zieländerung, Stop/Teilergebnis,
   ResultTable und Callertransaktion erstellen.
5. Die frei steuerbaren Grenzwerte an den qualifizierten Rändern und jeweils
   oberhalb des Rands prüfen. Der zweite Fall muss vor Mutation mit dem
   konkreten technischen Maximum abbrechen. Sequenzielle Speicherverwendung
   und Parallelität nur mit gemessener Evidenz beschreiben.
6. Betroffene ZIP-Files- und Windows-Filesystem-Verträge, Hilfetexte,
   Manifest-/Releasebindungen und Testmatrix gemeinsam aktualisieren.
   Bestehende Windows-only/local-Modulgrenzen bleiben bestehen, solange keine
   separate Plattform-/Central-Freigabe und Qualifikation erfolgt.
7. Erforderliche unabhängige Source-/Securityreview, schema-validierte
   ausgewählte Labtests, frische eigene Cleanup-Audits und tatsächliche
   Exact-head-CI getrennt nachweisen. Keine Veröffentlichung ohne eigene
   Freigabe.

## Abgrenzungen

Keine In-memory-Writeränderung, kein ZIP64-/Multi-Disk-/Verschlüsselungssupport,
keine Entryauswahl/Filterung, kein RunAs, keine fremden Root-Aliase, keine
automatische Bereinigung bereits veröffentlichter Dateien und kein Linux- oder
Central-Modus durch implizite Ableitung aus dem portablen Binary-Reader.
