# ZIP: native Prüfung der Entry-Bytegrenzen

Am 2026-11-06 bestand die vorhandene öffentliche ZIP-1.4-Extraktions-USP
ihre feste Grenze von **134217728 komprimierten Bytes** und die dokumentierte
maximale Ausgabe von **67108864 Bytes**, jeweils einschließlich der Abweisung
von genau einem Byte darüber. Windows SQL2025/CU8 CL170 und Linux
SQL2019/latest CL150 wurden jeweils lokal und direkt zentral geprüft:
vier Kontexte, acht positive und acht strikte negative Proben. Beide Gesamtläufe
und beide frischen unabhängigen Abschlussaudits sind erfolgreich:
**PASS_FOR_DECLARED_ENTRY_BYTE_SCOPE**.

## Gültige unabhängige Eingaben

Der [Composer](../../Tests/Release/compose_zip_entry_limits.py) erzeugt vier
vollständige klassische Single-Disk-ZIP32-Archive mit einem `payload.txt`-Entry.
Für die komprimierte Grenze bestehen die DEFLATE-Daten aus gültigen leeren
nicht finalen Stored-Blöcken und einem abschließenden komprimierten Literal.
Alle Blöcke liegen vor dem Finalblock; es handelt sich nicht um ignoriertes
Padding nach dem Stream. Die tatsächlichen komprimierten Längen sind
134217728/134217729 Bytes, die Nutzinhalte ein beziehungsweise zwei Bytes.
Damit greift keine vorherige Ausgabe- oder Archivgrenze.

Für die Ausgabegrenze enthalten zwei Stored-Entries synthetische Nullbytes
mit tatsächlichen Längen 67108864/67108865. Der öffentliche Parameter
`@MaxEntryBytes` wird auf sein dokumentiertes Maximum 67108864 gesetzt;
keine Produktquote wird geändert. Der unabhängige Python-Standardreader
dekodiert alle vier tatsächlichen Entries vollständig und prüft CRC, Namen,
Methode, Größen sowie SHA-256 des ausgegebenen Inhalts.

## Tatsächlicher öffentlicher Aufruf

Die Probe verwendet `toolbelt_archive.USP_ExtractZipEntryFromBinary` mit
ihrem öffentlichen ResultTable-Weg, keine interne CLR-Funktion als Ersatz.
Ein Streamparameter liefert das Archiv. Die extrahierte Payload bleibt in
der eigenen SQL-ResultTable; der Client prüft Zeilenzahl, Namen, beide Längen,
Methode, CRC, Verschlüsselungsflag, tatsächliche Payloadlänge und deren SHA-256.
Damit wird auch die vollständige 64-MiB-Ausgabe geprüft, ohne sie für den
Nachweis zusätzlich vollständig zum Client zu übertragen.

Die beiden Überschreitungen müssen SQL51325/State1 und jeweils die konkrete
Komprimat- beziehungsweise `@MaxEntryBytes`-Meldung liefern. Der SQL-Testbatch
erfasst diesen tatsächlichen Fehler in TRY/CATCH und verlangt eine leere
ResultTable. Ein anderer Fehler, ein Abbruch ohne Orakel oder eine Teilrow
zählt nicht als Erfolg. Vor SQL erkannte reservierte Alias-Schreibweise im
Testadapter wurde korrigiert und der vollständige Batch mit Parser150 geparst;
dies war kein nativer Versuch und keine Produktänderung.

## Bindung und Abschluss

Ausgeführter Snapshot:
[`41eb15c6`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/41eb15c698ca628003725b1761ef2dd5c6cc71fe).
Der [Treiber](../../Tests/Release/Invoke-ZipEntryLimitsLab.ps1) bindet den
bekannten unveränderten SAFE-DLL-Stand an den vorhandenen
[ZIP-Binarynachweis](zip-entry-count-qualification.json), die kanonischen
Deploymentexports sowie tatsächliche Originaldateihashes und Quellenpins.
Read-only-Handles halten die Eingaben während des Laufs unverändert.
Kein Build, neues Paket, Manifest-, SQL-, C#- oder Quotenpatch.

Sechs Offlinegegenproben prüfen vollständige Produktionsgrenzarchive und
unabhängige Header, bestehende Ausgabedateien und private Zielpfade, die echte
Scope-/Pinprüfung ohne Payload-/Lab-/SQL-Zugriff, Autoritätstyp und exakte Ziele,
fremde selbst gehashte DLLs sowie Quoten- und Fristabweichungen. Scopeprüfung
allein ist ausdrücklich kein Dateiinhalts- oder SQL-Nachweis.

Diese unabhängige Welle hatte höchstens vier Ziel-/Auditaufrufe, vier eigene
Datenbanken und 45 Minuten ohne Wiederholung. Zwei Läufe und zwei separate
Audits schlossen alle vier Aufrufe und Datenbanken innerhalb der Originalfrist
ohne nativen Fehler. Die jeweils nötige Konfigurations-/Trustvorbereitung und
Wiederherstellung ist Teil des Laufs, kein ungezählter Zusatzdispatch.
Die vorherige Archivbyte-Welle und sämtliche älteren Grenzen bleiben geschlossen.

Tatsächliche Engine-/Plattform-/Versionsprüfung, Modul-/Modusmarker, exakte
SAFE-Assembly, unveränderte Produktdefinitionen und neutraler Transaktionszustand
sind gebunden. Datenbanken werden nur nach voller ID-/Erstellungszeit-/Owner-
Prüfung entfernt. Eigener Hashtrust benötigt unverändertes Tupel und globale
Verbraucherfreiheit; Konfigurationsdrift blockiert fremde Wiederherstellung.
Die frischen Audits binden finale unveränderte Originaljournale, abwesende
Datenbanken und vollständigen Konfigurations-/Trustvergleich. Keine Rechte,
neuen Identitäten, Lab- oder Infrastrukturänderungen.

Der Host war Windows; Linux bezeichnet das SQL-Ziel. Direkt zentral ist SameDB,
keine neue CrossDB-Identität. Functional-Verschlüsselung mit explizitem Labtrust
ist keine authentifizierte TLS-Abnahme. Andere Ziel-/CL-Kontexte, Heap,
Parallelität, beliebige Clientübertragung, weitere Interoperabilität und gesamte
Modul-/Releasequalifikation bleiben separat. Historische Tabellen/Records bleiben
unverändert; private Originale und große Inputs bleiben außerhalb Git.
Modulstatus weiterhin teilweise validiert und unveröffentlicht; keine Tags.
