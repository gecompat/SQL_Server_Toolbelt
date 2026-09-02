# Manueller Windows-Runtime-Testplan

Status: ausstehend. Dieser Testplan ist für die manuelle Ausführung auf einem Windows-SQL-Server vorgesehen; er erzeugt keine Runtime-Evidenz im Repository.

## Sicherheitsrahmen

- Ausschließlich eine dedizierte Testdatenbank sowie einen synthetischen, leeren Testroot verwenden.
- Testroot, RootAlias, Konten, ACLs, Hostnamen, Dateien und vollständige Fehlermeldungen nicht in das Repository übernehmen.
- Für `Caller` nur Windows Authentication verwenden. Für `ServiceAccount` eine getrennte, explizite Testreihe ausführen.
- Vor Löschtests nur künstlich erzeugte Dateien und Directories verwenden. Root selbst darf nie Löschziel sein.
- Reparse-Point- und Junction-Tests nur in einer isolierten Teststruktur durchführen.

## Vorbedingungen

1. Das Modul entsprechend `Deployment/README.md`, `Add-TrustedAssembly.sql` und `Deploy.sql` in einer Testdatenbank installieren. `clr enabled` und `clr strict security` müssen bereits aktiv sein; der Installer ändert keine Instanzoption.
2. Einen RootAlias mit einem ausschließlich synthetischen Root konfigurieren. Für die Testreihe müssen `AllowRead`, `AllowWrite`, `AllowList`, `AllowDelete` und `AllowCreateDirectory` gezielt aktiviert sein; ein relativer `WorkPath` ist für die Staging-Prüfung zu setzen.
3. Getrennte NTFS-Rechte vorbereiten: ein Windows-Caller mit erlaubtem Zugriff, ein Windows-Caller ohne Zugriff und – nur für `ServiceAccount` – das SQL-Server-Dienstkonto.
4. Vor jedem Testlauf `@Hilfe = 1` jeder öffentlichen Procedure ausführen und die Rückgabe auf Parameter- und Resultset-Vertrag prüfen.

Für den read-only Einstieg steht
`Tests/Runtime/WindowsCallerListDirectory.Manual.sql` bereit. Es wird im
SQLCMD-Modus mit einem Betreiber-RootAlias ausgeführt und prüft `Caller` über
`USP_ListDirectory`, ohne Dateien oder die Root-Konfiguration zu ändern.

## Testreihen

| ID | Test | Erwartung |
|---|---|---|
| DEP-01 | Trust, `CREATE/ALTER ASSEMBLY`, Public Procedures und Uninstall | Erfolgreich; kein `TRUSTWORTHY ON`, `UNSAFE` oder `xp_cmdshell`. |
| ID-01 | `Caller` mit Windows Authentication und erlaubter ACL | Read/List/Write im synthetischen Root erfolgreich. |
| ID-02 | `Caller` mit SQL Authentication | Kontrollierte Ablehnung, kein I/O. |
| ID-03 | `Caller` ohne NTFS-Recht | Kontrollierte Zugriffsverweigerung, kein partielles Target. |
| ID-04 | `ServiceAccount` explizit | Nur mit dessen NTFS-Rechten erfolgreich; ohne Recht kontrolliert abgelehnt. |
| IO-01 | Binary Write/Read in mehreren Chunks | Byteidentischer Roundtrip; `NextByteOffset` und `EndOfFile` korrekt. |
| IO-02 | Text UTF-8, UTF-16 LE/BE und Windows-1252 | Erwarteter Text und erwartetes BOM-Verhalten. |
| IO-03 | Ungültige Bytefolge und nicht repräsentierbares Zeichen | Kontrollierter Fehler, keine stille Ersetzung. |
| IO-04 | Transcoding mit größerem Testtext | Korrekte Zieldatei ohne vollständiges In-memory-Laden; fehlgeschlagene Ausgabe bleibt unveröffentlicht. |
| FS-01 | List/Create/Remove mit relativem Pfad | Nur innerhalb des RootAlias erfolgreich. |
| FS-02 | Absolute Pfade, UNC, Laufwerksqualifizierer und `..` | Kontrollierte Ablehnung. |
| FS-03 | Reparse Point/Junction beim Read, List, Write und Delete | Kontrollierte Ablehnung, keine Traversierung. |
| FS-04 | Atomarer Write: bestehendes Target plus erzwungener Abbruch | Bestehendes Target unverändert; keine veröffentlichte Teil-Datei. |
| DEL-01 | Nichtrekursives und rekursives Directory-Delete | Nichtrekursiv nur leere Directory; rekursiv nur mit `@Recursive = 1`. |
| DEL-02 | `@MaxDepth` und `@MaxEntries` | Grenze wird kontrolliert erzwungen, kein unvollständiges Löschen. |
| DEL-03 | TOCTOU-Beobachtung bei Junction-/Reparse-Point-Wechsel | Beobachtung dokumentieren; bei unerwarteter Traversierung sofort abbrechen und keinen weiteren Löschtest ausführen. |

## Rückmeldung an Codex

Bitte nur diese abstrahierte Tabelle übermitteln:

| Test-ID | SQL Server-Version | Auth-Modus | Ergebnis | Fehlernummer/Kategorie | Bemerkung |
|---|---|---|---|---|---|
| z. B. ID-02 | 2022 | SQL Authentication | pass | kontrollierte Caller-Ablehnung | keine I/O beobachtet |

Keine realen Pfade, Konten, ACLs, Hostnamen, Dateiinhalte, Screenshots oder vollständigen Rohlogs übermitteln. Bei einem Fehler genügen Test-ID, SQL-Fehlernummer, gekürzte Fehlerkategorie und die Angabe, ob eine Datei oder Directory unerwartet verändert wurde.

Nach Bewertung der abstrakten Rückmeldung wird die Runtime-Evidenz im Modulmanifest und in der Testmatrix nachgezogen.
