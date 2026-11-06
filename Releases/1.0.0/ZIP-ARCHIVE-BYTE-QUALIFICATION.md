# ZIP: native Prüfung der Archivbyte-Grenze

Am 2026-11-06 bestanden die vorhandenen ZIP-1.4-USPs für Listing und einzelne
Extraktion ihre feste Archivgrenze von **268435456 Bytes** und die Abweisung
von **268435457 Bytes**. Geprüft wurden Windows SQL2025/CU8 CL170 und Linux
SQL2019/latest CL150, jeweils lokal und direkt zentral: vier Kontexte, acht
positive Proben und acht strikte Fehlerproben. Beide Gesamtläufe und beide
frischen unabhängigen Abschlussaudits sind erfolgreich:
**PASS_FOR_DECLARED_ARCHIVE_BYTE_SCOPE**.

## Gültige unabhängige Eingaben

Der [Composer](../../Tests/Release/compose_zip_archive_limit.py) erzeugt zwei
vollständige ZIP32-Archive mit festem DOS-Datum. Ein Stored-Entry enthält
`abc`; ein zweiter, nicht zur Extraktion ausgewählter Stored-Entry enthält
synthetische Nullbytes. Beide Archive sind exakt an der Grenze beziehungsweise
ein Byte größer. Der unabhängige Python-Standardreader prüft sämtliche CRCs,
Namen, Größen und die kleine Zielpayload. Keine Original- oder Kundendaten.

Für jedes Archiv werden beide öffentlichen USPs tatsächlich aufgerufen.
An der Grenze muss Listing beide Entries mit den festen Größen und CRCs
liefern; Extraktion muss genau die drei Zielbytes ergeben. Über der Grenze
müssen beide Aufrufe SQL51325/State1 mit archivbezogener Meldung und ohne
Ergebniszeile liefern. Eine andere Größenablehnung zählt nicht als PASS.
Die große unselektierte Füllpayload wird nicht extrahiert; dieser Fall belegt
ausdrücklich weder 128-MiB-Komprimat- noch 64-MiB-Ausgabegrenzen.

## Methode und Bindung

Ausgeführter Snapshot:
[`0ec58129`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/0ec58129aa1f078cd5793ad81e78e2d04743f240).
Der [Treiber](../../Tests/Release/Invoke-ZipArchiveLimitLab.ps1) übergibt die
Eingaben mit einem Streamparameter und hält ihre Originaldateien während des
Laufs über separate Read-only-Handles unverändert. Dies ist keine allgemeine
Streaming- oder Memory-Grant-Zusage des Produkts. Originaldateihashes und
Metadaten werden vor SQL sowie beim unabhängigen Audit geprüft.

Die aktuelle öffentliche SQL-Bindung ruft tatsächlich `ZipEntryProvider`
auf; die technische `ArchiveSession`-Fassade für XLSX ist nicht Gegenstand
dieses Tests. Die unveränderte SAFE-DLL stammt aus dem vorhandenen CLR-
Installationspaket und muss dem bereits qualifizierten
[ZIP-Binarynachweis](zip-entry-count-qualification.json) entsprechen. Ein bloß
selbst gehashtes fremdes Binary wird abgewiesen. Kein Build, Produktpatch,
Quotenwechsel, Manifestupdate oder neues Paket.

Sechs Offlineprüfungen sichern gültige deterministische ZIP32-Strukturen,
ungültige Größen und bestehende Ausgabedateien, tatsächliche verbindungslose
Scope-/Pinprüfung, Autoritätstyp/Ziel-/Methodenbindung, fremde Binaries sowie
unzulässige Quoten- und Friständerungen. `-ValidateOnly` liest keine großen
Payloads und importiert kein Lab; es bestätigt nur den ausdrücklich benannten
Scope, die kleinen Inputs und Methodenpins. Der Nativeweg prüft zusätzlich
die tatsächlichen großen Originaldateien.

## Abschluss und Grenzen

Vor Start wurden höchstens vier Ziel-/Auditaufrufe, vier eigene Datenbanken
und 45 Minuten ohne Wiederholung festgelegt. Die je Lauf nötige CLR-
Vorbereitung und Wiederherstellung ist integriert, nicht als ungezählter
zusätzlicher Dispatch ausgelagert. Alle vier Aufrufe und vier Datenbanken
sind innerhalb dieser Originalfrist geschlossen, ohne nativen Fehlversuch.
Frühere Testbudgets und Fehler bleiben unverändert.

Die tatsächliche SQL-Hauptversion, Plattform und Softwareversion werden vor
Konfigurationsänderungen privat erfasst und gegen die Auswahl geprüft; der
Audit vergleicht die Version erneut. Modul-/Modusmarker, exakte SAFE-Assembly,
Produktdefinitionen und neutraler Transaktionszustand bleiben erhalten.
Eigene Datenbanken werden nur nach voller ID-/Erstellungszeit-/Ownerprüfung
entfernt. Eigener Hashtrust wird nur bei unverändertem Tupel und nach globaler
Verbraucherprüfung entfernt; Strict Security bleibt aktiv. Die bestehenden
Konfigurations-/Hashtrustfreigaben werden ausschließlich im eigenen Umfang
verwendet und wiederhergestellt. Frische Audits binden die finalen unveränderten
Originaljournale, Datenbankabwesenheit und den vollständigen Konfigurations-/
Trustvergleich. Keine Rechtevergabe, neuen Identitäten oder Labänderungen.

Der Prüfhost war Windows; Linux bezeichnet das SQL-Ziel. Direkt zentral heißt
SameDB-Nutzung, keine neue CrossDB-Identität. Functional übernimmt notwendige
Verschlüsselung und den expliziten Lab-Trustwert; keine authentifizierte TLS-
Abnahme. Andere physische Ziel-/CL-Kombinationen, komprimierte Entry- und
Ausgabegrenzen, Heap/Parallelität und vollständige Modul-/Releaseabnahme bleiben
separat. Private Originale und große synthetische Inputs bleiben außerhalb Git.
Modulstatus bleibt teilweise validiert und unveröffentlicht; keine Tags.
