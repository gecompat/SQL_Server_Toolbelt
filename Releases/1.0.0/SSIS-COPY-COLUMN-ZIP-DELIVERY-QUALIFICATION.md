# SSIS Copy Column V1: native ZIP-Liefermatrix

Stand: 2026-11-15 · `PASS_FOR_DECLARED_SCOPE` · unveröffentlicht

Die [aktuelle Liefermatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/CopyColumn.Delivery.20261115.json)
belegt die tatsächliche Installation desselben Copy-Column-V1-ZIPs auf zwölf
Windows-/CL-/Moduskontexten: SQL2019/CU32 CL150, SQL2022/CU26 CL150/160 und
SQL2025/CU8 CL150/160/170 jeweils lokal und direkt zentral. 96 neue
Installationsassertions und zwölf frische unabhängige Abschlussaudits bestehen.
Alle zwölf eigenen Datenbanken sind entfernt; eigener Trust ist auf Abwesenheit
geprüft, eigene Konfigurationsänderungen sind zurückgenommen beziehungsweise
waren nicht erforderlich. Neue Identitäten oder Rechte wurden nicht angelegt.

## Was tatsächlich aus dem Archiv geprüft wurde

Je Kontext führt der unveränderte achtteilige Paketchecker aus:

1. Frischer Scope ohne SSIS-Assembly oder öffentliche/interne Prozedur.
2. Installation der exakt qualifizierten DLL aus dem entpackten ZIP.
3. Erwartete Versionen von ResultTable, Parser und SSIS.
4. Tatsächlicher öffentlicher CLR-Aufruf für eine Bindingsvorlage mit festem
   Ergebnisschema aus dem synthetischen, im Archiv enthaltenen DTSX.
5. Wiederholungsinstallation mit erhaltenen Prozeduridentitäten und DLL-Bytes.
6. Vollständiger SSIS-Uninstall.
7. Erneuter Uninstall im abwesenden Zustand.
8. Erhalt der gemeinsam installierten Abhängigkeiten.

Der Coordinator verwendet den eingefrorenen vorhandenen Labtreiber. Die neue
Hülle bindet den konkreten Paketnamen, alle Archivdateien, den aktuellen
qualifizierten DLL-Hash, die Produktquellen und den unveränderten Full-Framework-
Nachweis mit 29 Kindern vor SQL. Der vorhandene API-Suitenhook wird entfernt;
die gültigen Fach-/API-/Copy-Column-Nachweise werden in ihrem Scope übernommen.
Keine bestandenen Fachfälle werden allein für diesen Liefernachweis wiederholt.
`ApiOnly` ist gesetzt, `Full` und `ReleaseRights` bleiben aus. Zentral bedeutet
hier direkte Nutzung in der zentralen Datenbank, kein neuer CrossDB-Consumer.

Die [Nativehülle](../../Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CopyColumnDeliveryLab.ps1)
benötigt einen privaten hashgebundenen Runset mit exakter Ziel-/Patch-/CL-/Modus-
Liste und ursprünglicher Deadline. `-ValidateOnly` und `-DescribeOnly` führen
keine SQL-Verbindung aus. Der Audit ist ein separater Prozess, der das endgültige
Journal bindet und Datenbank-/Trustabwesenheit sowie Konfigurationszustand prüft.
Zehn [Zulassungsgegenproben](../../Tests/Release/test_ssis_copy_column_delivery.py)
und elf [Recordgegenproben](../../Tests/Release/test_ssis_copy_column_delivery_evidence.py)
schützen Quellenbindung, Journallebenszyklus, Zähler, Cleanup und Scopegrenzen.

## Erhaltener erster Fehler und gemeinsamer Rahmen

Die Vorbereitung hatte leere Journalverzeichnisse vorab angelegt. Der erste
Coordinator wies diese Kollision vor jeder SQL-Verbindung zurück: kein SQL-
Preflight, kein Journal, keine Datenbank-, Trust- oder Konfigurationsänderung.
Ein separater SQL-Audit war ohne Zielaktivität und Journal nicht ausführbar;
er wird ausdrücklich nicht als PASS geführt. Die leeren eigenen Verzeichnisse
wurden geprüft entfernt. Die korrigierte Zulassung verlangt vor einem Run einen
noch nicht vorhandenen Journalpfad; eine neue Gegenprobe prüft diesen Vertrag.

Die ursprünglichen Fehler-/Quell-/Runsetbytes bleiben erhalten. Die Korrektur
verwendete dieselbe Uhr und dieselben Zähler: maximal 28 Aufrufreservierungen,
16 DB-Reservierungen und 60 Minuten, höchstens zwei geänderte Adapterkontexte.
Tatsächlich geschlossen: 26 Reservierungen, 25 Driverdispatches, davon ein
Start vor SQL und zwölf Run-/Auditpaare. Die unbenutzte erste Auditreservierung
bleibt gezählt. 13 DB-Reservierungen, zwölf tatsächlich angelegte/entfernte DBs;
ein geänderter Adapterkontext, keine Wiederholung bestandener Kontexte.
Die früheren Source- und Hostwellen bleiben unverändert geschlossen.

## Grenze des Ergebnisses

Dies ist die native Archivinstallations-/Lebenszyklusmatrix und keine neue
vollständige funktionale ZIP-, Prozedur-, Rechte-, SSMS-, TLS- oder Modulabnahme.
Die frühere umfassende ZIP-Matrix bleibt an ihr ursprüngliches Archiv gebunden.
Der [aktuelle Modellhost](SSIS-COPY-COLUMN-HOST-QUALIFICATION.md) ist getrennt
qualifiziert. SQL CLR unter Linux, SSIS-Runtime-Parität, unbegrenzte Kapazität
und OS-/VM-Verlust werden nicht behauptet. Gesamtmodul weiterhin
`partially validated`, `unreleased`; Head-/Main-CI sind eigene Integrationsgates.
Keine Veröffentlichung oder Tags.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-15`
- Nachweis: `local: sichtbarer Windows-SSMS-Gesamtfall am aktuellen Copy-Column-Archiv`
- Scope: PASS_FOR_DECLARED_SCOPE: Windows SQL2025/CU8 CL150 lokal, Windows-NTLM, ausgewaehltes Labziel und verschluesselte funktionale Verbindung. Oeffentliche Erst-/Wiederholungsinstallation, aktuelle API, echte Unicode-Zellenkopie mit184441 normalisierten UTF16-Einheiten, native SQLCMD-Stopprobe und vollstaendiges Script mit2 Ergebniszeilen und Phase2-Receipt. Koordinator PASS_CLEANED17, frischer finaljournalgebundener Windows-Audit PASS, eigeneDB/SSMS entfernt und Konfiguration/Trust wiederhergestellt, andereVerbraucher unveraendert. Benutzerhilfe nurAnmeldung/Gridoptionen;4GUI-Ausfuehrungen durchAgent. Rahmen2Aufrufe/1DB/4GUI/45Minuten geschlossen, keine nativenFehler/Wiederholung. Gueltige Delta-/Host-/Archivnachweise uebernommen; keine neue vollstaendige funktionale ZIP-/TLS-/Modulabnahme.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
