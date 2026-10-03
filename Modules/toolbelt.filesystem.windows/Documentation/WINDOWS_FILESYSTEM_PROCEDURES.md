# Öffentliche Procedures: Windows Filesystem

Alle Procedures verwenden Root-Aliasse und relative Pfade. `@ExecutionIdentity = 'Caller'` ist der Default; zulässige Alternative ist `ServiceAccount`.

| Procedure | Zweck | Speicher- und Sicherheitsgrenze |
|---|---|---|
| `USP_ReadBinaryFileChunk` | Liest Binary ab `@ByteOffset`. | Maximal 16 MiB je Aufruf; Rückgabe der nächsten Position. |
| `USP_ReadTextFileChunk` | Liest Text mit expliziter Codepage. | Maximal 16 MiB; ein Chunk endet an einer Decodergrenze. |
| `USP_WriteBinaryFile` | Schreibt `varbinary(max)`. | Liest die SQL-LOB in 1-MiB-Blöcken und veröffentlicht über `.part`. |
| `USP_WriteTextFile` | Schreibt `nvarchar(max)` mit Codepage/BOM. | Kodiert und schreibt in 32-Ki-Zeichenblöcken. |
| `USP_TranscodeTextFile` | Konvertiert Source nach Target. | StreamReader/Writer-Pfad, ohne vollständiges Laden der Datei. |
| `USP_ListDirectory` | Listet Files und Directories. | `@MaxDepth` und `@MaxEntries` begrenzen die Traversierung. |
| `USP_CreateDirectory` | Erzeugt ein Directory. | Nur bei `AllowCreateDirectory = 1`. |
| `USP_RemoveFile` | Entfernt eine File. | Nur bei `AllowDelete = 1`; keine Root-/absolute Pfade. |
| `USP_RemoveDirectory` | Entfernt ein Directory. | Rekursion nur mit `@Recursive = 1`, begrenzt durch Tiefe und Einträge. |

Der Provider verwendet strikte Encoder-/Decoder-Fallbacks. Nicht repräsentierbare Zeichen oder ungültige Bytefolgen führen zu einem Fehler; es gibt keine stille Ersetzung. Die unterstützte Codepage wird von .NET Framework/Windows bereitgestellt und ist vor Produktivnutzung am Zielsystem zu prüfen.

Fehler aus dem CLR-Provider werden von jeder öffentlichen Fassade mit der
betroffenen Dateisystemoperation eingeordnet; die technische Ursache folgt in
der Fehlermeldung.

## Einschränkungen

- SQL Server auf Linux ist nicht unterstützt, da `EXTERNAL_ACCESS` dort nicht verfügbar ist.
- Absolute Pfade, UNC-Pfade, Laufwerksqualifizierer, `..`-Ausbrüche und Reparse Points werden abgewiesen.
- Ein konfigurierter `WorkPath` muss relativ zum Root liegen und wird für temporäre `.part`-Dateien verwendet. Ohne `WorkPath` erfolgt das Staging im Zielverzeichnis.
- Rekursives Löschen ist durch die Reparse-Point-Prüfung und Limits abgesichert. Der unvermeidbare TOCTOU-Rest zwischen Prüfung und Delete wird im manuellen Windows-Test gezielt geprüft.

## Streaming und Identität

SQL-LOB-Zugriffe (`SqlBytes`/`SqlChars` Length/Read) erfolgen im ursprünglichen SQL-Kontext zwischen den Dateisystem-Sitzungen. Binary verwendet weiterhin einen 1-MiB-Puffer, Text 32768 Zeichen plus den begrenzten Encoding-Puffer; der vollständige Inhalt wird nicht materialisiert. Für Caller wird dieselbe einmal erfasste Windows-Identität bei jedem Datei-Open, Write, Flush, Dispose, Publish und Cleanup verwendet. Nach ungewissem Impersonation-Enter oder Undo wird nicht unter ServiceAccount weitergearbeitet. `ServiceAccount` bleibt eine ausdrücklich gewählte Alternative.

[Microsoft dokumentiert](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/impersonation-and-credentials-for-connections?view=sql-server-ver17), dass lokale Datenzugriffe während Caller-Impersonation bis Undo nicht verfügbar sind. Die Korrektur trennt diese Zugriffe, verändert jedoch weder den öffentlichen Vertrag noch die Encoding-Semantik. Den aktuellen begrenzten Framework-/Auth-Probe-Nachweis beschreibt der folgende Evidenzabschnitt; vollständige NTFS-Qualifikation bleibt offen. Historische Nachweise gelten für ihre damaligen Sources.
## Requestbezogene Caller-Authentifizierung — Sourcekorrektur

Alle neun CLR-Einstiegspunkte verwenden im Caller-Pfad dieselbe Authentifizierungspruefung. Eine Contextconnection liest vor Impersonation `CONNECTIONPROPERTY('auth_scheme')`; Connection und Command sind vor der Identity-Erfassung vollstaendig disposed. Nur die exakt ordinalen Windows-Modi `NTLM`, `KERBEROS`, `DIGEST`, `BASIC` und `NEGOTIATE` zusammen mit einer nichtleeren Windows-Identity werden akzeptiert. SQL-Authentifizierung, NULL und unbekannte Werte werden mit dem bestehenden `CallerWindowsAuthenticationRequired` abgewiesen. `ServiceAccount` bleibt ausdruecklicher Opt-in; es gibt keinen Fallback, keine DMV-/Sichtrechte-Abhaengigkeit und keine neue API.

[Microsofts CONNECTIONPROPERTY-Vertrag](https://learn.microsoft.com/en-us/sql/t-sql/functions/connectionproperty-transact-sql?view=sql-server-ver17) beschreibt diese requestbezogenen Modi. Der vorbereitete Frameworktest ruft nur das echte reine Auth-Praedikat mit fuenf erlaubten und zehn abgewiesenen synthetischen Werten auf. Die neun NoOverwrite- und sieben Streaming-Faelle bleiben erhalten. Die aktuelle begrenzte Sourcebuild-/Framework-/Auth-Probe-Evidenz folgt unten. Direkte CLR-/RunAs- und vollständige NTFS-Nachweise bleiben offen; frühere Nachweise gelten für ihre historischen Sources.

## Aktueller begrenzter Nachweis 2026-10-04

Der aktuelle Provider bestand einen privaten begrenzten produktiven C#-Sourcebuild und den sourcegebundenen Frameworklauf: neun NoOverwrite-Fälle/270 Assertions sowie sieben Streaming-Fälle/188 Assertions; darin enthalten ist die reine Caller-Policyprüfung mit fünf erlaubten und zehn abgewiesenen Werten. Vollständige Captures, Exit0, eigene Bereinigung und abschließende Sourcepins wurden geprüft. Die synthetischen Sequenzfälle beweisen keine echte Impersonation.

Die private native Zwei-Fall-Authentifizierungsprüfung auf SQL Server 2025/CU8 unter Windows bestand: Windows-Caller (NTLM) schrieb drei synthetische Bytes über `USP_WriteBinaryFile`; SQL-Authentifizierung wurde mit `51540/1` und `CallerWindowsAuthenticationRequired` vor Datei-/Staging-I/O abgewiesen. Eigene DB-, Root- und Trustbereinigung und eine separate frische Prüfung bestanden, ohne Konfigurations-, Rechte- oder Owneränderungen. Dieser begrenzte Probe-Scope ist kein vollständiger Produkttest.

Aktueller kanonischer Projektbuild/Releaseartefakt, direkte CLR-/RunAs-Qualifikation aller neun Einstiegspunkte, vollständige NTFS-/Caller-/ServiceAccount-Matrix, Races, weitere Ziele und aktuelle Head-CI bleiben separate offene Gates. Status `partially validated`, Version1.0.0 und `unreleased` bleiben erhalten; frühere Nachweise sind historisch.
