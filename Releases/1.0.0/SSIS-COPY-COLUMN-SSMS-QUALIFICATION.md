# Aktuelles Copy-Column-Archiv: sichtbarer SSMS-Gesamtfall

Stand: 2026-11-15 · `PASS_FOR_DECLARED_SCOPE` · unveröffentlicht

Der [native Record](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Ssms.CopyColumn.20261115.json)
belegt den sichtbaren Windows-/SSMS-Gesamtfall mit genau derselben DLL und
denselben Artefakten des bereits qualifizierten Copy-Column-V1-ZIPs.
Windows SQL2025/CU8, CL150, lokale Installation: ein Koordinator
`PASS_CLEANED`, 17 Prüfungen, vier GUI-Ausführungen und ein separater frischer
Windows-Abschlussaudit `PASS`. Es wurde kein früherer Gesamtfall umetikettiert.

## Tatsächlich ausgeführter Ablauf

1. Eine eigene sichtbare SSMS-Instanz führte vor der Testdatenbank den
   Zielvorcheck aus. Serverwitness und einmalige Beobachtungskennung stimmten;
   Windows-NTLM, CU8 und Verschlüsselung wurden tatsächlich festgestellt.
2. Der öffentliche Windows-Installer installierte die bekannten aktuellen
   Artefakte und wiederholte die Installation mit unverändertem Trustzustand.
   Die 40-Parameter-API und ein synthetischer vollständiger Debugpfad bestanden.
3. Der tatsächliche SSMS-API-Aufruf erzeugte ein Unicode-DebugScript. Die echte
   Gridzelle wurde über SSMS kopiert und unverändert privat gespeichert.
   Nach CR/LF-Normalisierung stimmten alle 184.441 UTF-16-Einheiten mit dem
   serverseitigen Hash überein, bevor irgendeine Kopie ausgeführt wurde.
4. Die unveränderte negative Probe lief in SQLCMD-Modus mit `:ON ERROR EXIT`.
   Der erwartete Fehler 51001 war sichtbar. Der spätere Sentinelbatch wurde
   nicht ausgeführt; der Koordinator bestätigte Receiptphase 1 unverändert.
5. Die vollständige Kopie und der unveränderte Receipt wurden als gebundene
   SQLCMD-Hülle ausgeführt. Der tatsächliche Editorinhalt war vorher mit der
   Hülle verglichen. Zwei erwartete Ergebniszeilen und der Unicode-Receipt
   erschienen; die vollständige Messages-Ausgabe enthielt keine unerwarteten
   Ausführungsfehler. Receiptphase 2 wurde tatsächlich erreicht.
6. Nur die eigene SSMS-Instanz wurde geschlossen. Eigene Datenbank entfernt,
   Konfiguration und Trust wiederhergestellt, andere Verbraucher unverändert.
   Der frische unabhängige Windows-Audit bindet das exakte finale Journal.

Der Benutzer übernahm die Windows-Anmeldung und die abfragebezogenen
Gridoptionen. Die vier GUI-Ausführungen, echte Kopie, Inhaltsprüfungen und
sichtbare Ergebnis-/Messages-Prüfung führte der Agent aus. Anmeldedialoge
wurden nicht automatisiert. Bei unzuverlässigen UIA-Indizes wurden frische
Screenshots und tatsächliche Zwischenablagevergleiche verwendet. Private
Journale, Rohtexte, Prozess-/Zielbindungen und Hashes bleiben lokal.

## Methodenbindung und Grenzen

[`Invoke-CopyColumnSsms.ps1`](../../Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-CopyColumnSsms.ps1)
bindet die unveränderten bestehenden Vorcheck-/Installer-/GUI-/SQLCMD-/Receipt-
und Cleanupmethoden an das aktuelle Archiv. Der
[Artefaktguard](../../Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/CopyColumnArtifacts.ps1)
prüft die qualifizierten Quellprojektionen, Archivbytes und alle vier
SSIS-Releaseartefakte. Parserherkunft und ResultTable-Quellpins bleiben geprüft.
Die ursprünglichen Methoden, Records und ZIPs wurden nicht verändert.

Neun [SQL-freie Zulassungsgegenproben](../../Tests/Release/test_ssis_copy_column_ssms.py)
und neun [Evidenzgegenproben](../../Tests/Release/test_ssis_copy_column_ssms_evidence.py)
verhindern veraltete Artefakte, unvollständige Quellen, fingierte Gesamtfälle,
fehlende Audits, versteckte Benutzerhilfe und eine Aufwertung des Scopes.

Der gemeinsame Rahmen war vor dem Start auf einen Gesamtlauf und einen Audit,
eine eigene Datenbank, vier GUI-Ausführungen und 45 Minuten begrenzt. Alle
Zähler sind geschlossen; kein nativer Fehllauf und keine Wiederholung.
Frühere Wellen, Fehler und Grenzen bleiben unverändert erhalten.

Dies qualifiziert den Clienttransport am aktuellen Archiv mit der bestehenden
synthetischen Unicodefixture. Es ist keine neue Copy-Column-GUI-Fachfixture,
vollständige funktionale ZIP-/Prozedur-/Rechtematrix oder strikte TLS-Abnahme.
`TrustServerCertificate=True` bleibt ausdrücklich eine funktionale Verbindung.
Die gültigen Delta-, Host- und Archivnachweise wurden wiederverwendet.
Gesamtmodulstatus bleibt `partially validated`, `unreleased`; kein Release oder Tag.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-15`
- Nachweis: `local: sichtbarer Windows-SSMS-Gesamtfall am aktuellen Copy-Column-Archiv`
- Scope: PASS_FOR_DECLARED_SCOPE: Windows SQL2025/CU8 CL150 lokal, Windows-NTLM, ausgewaehltes Labziel und verschluesselte funktionale Verbindung. Oeffentliche Erst-/Wiederholungsinstallation, aktuelle API, echte Unicode-Zellenkopie mit184441 normalisierten UTF16-Einheiten, native SQLCMD-Stopprobe und vollstaendiges Script mit2 Ergebniszeilen und Phase2-Receipt. Koordinator PASS_CLEANED17, frischer finaljournalgebundener Windows-Audit PASS, eigeneDB/SSMS entfernt und Konfiguration/Trust wiederhergestellt, andereVerbraucher unveraendert. Benutzerhilfe nurAnmeldung/Gridoptionen;4GUI-Ausfuehrungen durchAgent. Rahmen2Aufrufe/1DB/4GUI/45Minuten geschlossen, keine nativenFehler/Wiederholung. Gueltige Delta-/Host-/Archivnachweise uebernommen; keine neue vollstaendige funktionale ZIP-/TLS-/Modulabnahme.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
