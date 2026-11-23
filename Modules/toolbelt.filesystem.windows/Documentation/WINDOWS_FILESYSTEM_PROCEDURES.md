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
- Rekursives Löschen verwendet vor der ersten Mutation einen vollständigen
  begrenzten Prüfplan. Startdirectory-Tiefe0, Childdirectory-Tiefe1;
  `@MaxDepth = 0` erlaubt nur direkte Dateien. Tiefe und Eintragsgrenze werden
  vor der ersten Löschung abgewiesen. Danach werden ausschließlich geprüfte
  Einträge und Directories nichtrekursiv gelöscht. Erneute Reparse-/Typprüfungen
  beseitigen keine Dateisystemraces; I/O-/Racefehler können Teilzustände hinterlassen.

## Streaming und Identität

SQL-LOB-Zugriffe (`SqlBytes`/`SqlChars` Length/Read) erfolgen im ursprünglichen SQL-Kontext zwischen den Dateisystem-Sitzungen. Binary verwendet weiterhin einen 1-MiB-Puffer, Text 32768 Zeichen plus den begrenzten Encoding-Puffer; der vollständige Inhalt wird nicht materialisiert. Für Caller wird dieselbe einmal erfasste Windows-Identität bei jedem Datei-Open, Write, Flush, Dispose, Publish und Cleanup verwendet. Nach ungewissem Impersonation-Enter oder Undo wird nicht unter ServiceAccount weitergearbeitet. `ServiceAccount` bleibt eine ausdrücklich gewählte Alternative.

## Requestbezogene Caller-Authentifizierung — Sourcekorrektur

Alle neun CLR-Einstiegspunkte verwenden im Caller-Pfad dieselbe Authentifizierungspruefung. Eine Contextconnection liest vor Impersonation `CONNECTIONPROPERTY('auth_scheme')`; Connection und Command sind vor der Identity-Erfassung vollstaendig disposed. Nur die exakt ordinalen Windows-Modi `NTLM`, `KERBEROS`, `DIGEST`, `BASIC` und `NEGOTIATE` zusammen mit einer nichtleeren Windows-Identity werden akzeptiert. SQL-Authentifizierung, NULL und unbekannte Werte werden mit dem bestehenden `CallerWindowsAuthenticationRequired` abgewiesen. `ServiceAccount` bleibt ausdruecklicher Opt-in; es gibt keinen Fallback, keine DMV-/Sichtrechte-Abhaengigkeit und keine neue API.
