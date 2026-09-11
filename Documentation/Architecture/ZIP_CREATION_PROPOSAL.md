# Vorschlag: In-memory-ZIP-Erzeugung (`TC-2026-034`)

## Status

Die bestehende ZIP-Memory-Funktion extrahiert einen einzelnen Entry und bleibt
unverändert. Dieses Dokument bereitet eine getrennte Erzeugungsfunktion vor.
Es autorisiert weder ein SQL-Objekt noch Datei-I/O, Archivschreiben oder eine
Änderung am validierten Extraktionsvertrag.

## Empfohlener V1-Schnitt

V1 erzeugt ein einzelnes ZIP-Binary im Speicher aus einer expliziten,
typisierten Entry-Liste. Es schreibt keine Dateien, liest keine Pfade, nimmt
keine bestehenden Archive entgegen und fügt ihnen keine Einträge hinzu.

Die Entry-Liste soll als eigene öffentliche Table Type mit genau zwei Spalten
festgelegt werden: eine positive Ordinalspalte und ein Name-Payload-Paar. Eine
Table Type vermeidet das dynamische Auslesen einer Caller-Tabelle und ein JSON-
oder Base64-Transportformat für Binärdaten. Ihr Name und die genaue
Spaltendefinition bleiben bis zur Funktionsbesprechung offen.

## Vertragsvorschlag

| Aspekt | Vorschlag |
|---|---|
| Reihenfolge | Eindeutige, positive Ordinals bestimmen die Central-Directory- und Eintragsreihenfolge. |
| Namen | Nicht leer, maximal 1.024 UTF-16-Codeeinheiten, binär eindeutig und als relativer ZIP-Pfad ohne NUL, `..`, Laufwerkspräfix oder führenden Separator. |
| Payload | `varbinary(max)` ist zulässig; SQL-`NULL`-Payload ist Fehler, leere Payload ist ein regulärer Entry. |
| Methode | `Stored` oder `Deflate`, pro Aufruf fest gewählt. Zusätzliche Methoden bleiben spätere Provider. |
| Metadaten | Keine Caller-gesteuerten Dateizeiten, Attribute, Kommentare oder Extra Fields in V1; der Output bleibt reproduzierbar. |
| Grenzen | Maximale Entryanzahl, einzelne Payloadgröße, Gesamtausgabegröße und Verhältnisgrenzen werden vor der Verarbeitung geprüft. |
| Ergebnis | Ein `varbinary(max)`-Archiv plus nicht sensible Metadaten; keine Persistierung und keine fachlichen Daten in Debug-/Fehlerausgaben. |

V1 erzeugt keine verschlüsselten, ZIP64-, Multi-Disk-, symlink- oder
Verzeichnisentries. Duplicate-Namen werden vor der Kompression abgelehnt.
Der Namevertrag verhindert spätere Zip-Slip-Interpretation auch dann, wenn
eine andere Komponente das Archiv entpackt.

## Technologie und Integrität

Der vorhandene sichere ZIP-CLR-Provider ist ein möglicher Ausgangspunkt, aber
der Writer braucht einen eigenen, begrenzten Implementierungsteil. Er muss
Local Header, Central Directory, CRC32 und Deflate-Stream erzeugen und die
deklarierte Länge mit der tatsächlich geschriebenen Länge abgleichen. Ein
unabhängiger Leser testet jedes erzeugte Archiv gegen die öffentlichen
Metadaten.

Die spätere Assembly bleibt nur dann `SAFE`, wenn sie wie das bestehende Modul
keinen Datei-, Netzwerk-, Prozess- oder Registryzugriff benötigt. Ein
File-System-Writer, atomische Dateierstellung, Overwrite und ACLs gehören zu
einem späteren, eigenen Providervertrag.

## Tests und Entscheidungspunkt

Tests verwenden ausschließlich synthetische Entrynamen und Payloads. Sie
umfassen leer/nicht leer, Stored/Deflate, Unicode, Binärduplikate,
Namensfehler, Größen-/Anzahllimits, CRC-/Längenprüfung, deterministische
Reihenfolge, unabhängiges Lesen, Wiederholungsdeployment, Lifecycle und die
SQL_Server_Lab-Matrix für 2019, 2022 und 2025 auf Windows und Linux. CUs sind
nur bei patchgebundenen Tests relevant.

Vor einer Implementierungsfreigabe wird der V1-Schnitt bestätigt oder
geändert: typisierte In-memory-Entryliste, zwei Methoden und ein Binaryoutput
ohne Datei-I/O. Danach werden der öffentliche Table Type, die Signatur,
konkrete Grenzen, Fehlerbereich und die Providerentscheidung als Funktion
besprochen und freigegeben.

## Quellen

- [PKWARE: ZIP APPNOTE](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)
- [bestehendes ZIP-Moduldesign](./ZIP_ARCHIVE_MODULE_DESIGN.md)
- [bestehender Candidate](../../Backlog/TOOLBELT_CANDIDATES.md#tc-2026-034-zip-archive-kontrolliert-extrahieren-und-erzeugen)
