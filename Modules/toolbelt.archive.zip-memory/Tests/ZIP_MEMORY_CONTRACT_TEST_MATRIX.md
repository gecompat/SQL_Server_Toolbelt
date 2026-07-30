# Contract-Testmatrix: ZIP Memory Extraction

| Bereich | Pflichtfall | Status |
|---|---|---|
| API | Objektart, Parameter, Reihenfolge und Typen | `not executed` |
| Help | vollstaendiger Help-Vertrag bei `@Hilfe = 1` | `not executed` |
| Erfolg | gueltiger Stored-Entry wird extrahiert | `not executed` |
| Entry fehlt | unbekannter Name liefert Fehler `51322` | `not executed` |
| Duplicate Name | doppelter Name liefert Fehler `51323` | `not executed` |
| Verschluesselt | `@FailIfEncrypted = 1` liefert Fehler `51324` | `not executed` |
| Encrypted Status | `@FailIfEncrypted = 0` liefert `IsEncrypted = 1` und `EntryPayload = NULL` | `not executed` |
| Grenzen | `@MaxEntryBytes` und `@MaxCompressionRatio` werden erzwungen | `not executed` |
| Methode | Deflate und jede andere nicht-`Stored` Compression Method liefert `51327` | `not executed` |
| ZIP64 | ZIP64 ist im V1A-Vertrag nicht unterstützt und darf nicht als positiver Erfolgsfall geführt werden | `not executed` |
| CRC | V1A prüft Header-/Metadatenkonsistenz; eine neu berechnete Payload-CRC ist kein V1A-Testversprechen | `not executed` |
| ResultTable | Insert in `@ResultTable` und `@KeepData`-Verhalten | `not executed` |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | `not executed` |
| Matrix | SQL Server 2025 Linux, Compatibility 150/160/170 | `not executed` |
| Release | physische SQL Server 2019/2022 und Windows | `not executed` |
