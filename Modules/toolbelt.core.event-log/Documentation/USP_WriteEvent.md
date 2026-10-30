# toolbelt_core.USP_WriteEvent

## Zweck

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

## Verhalten und Ergebnis

Schreibt genau ein Event über den konfigurierten Second-Session-Provider. Die Procedure gibt kein fachliches oder infrastrukturelles Resultset aus. ExecutionId, CorrelationId, Actor und Tenant werden aus expliziten Parametern oder dem aktiven Execution Context übernommen.

Die Procedure kann in einer regulären, zurückgerollten oder uncommittable Caller-Transaktion verwendet werden. Ein erfolgreicher Returncode bedeutet, dass der Remote-Handler synchron erfolgreich committed hat. Provider- oder Handlerfehler werden an den Caller weitergegeben.

Der interne `USP_WriteEventInternal`-Kern hat einen Help-Aufruf für seine
gebundene JSON-Payload und den fehlenden fachlichen Resultset-Vertrag. Direkte
Aufrufe bleiben auf die vorgesehene Event-Log-Fassade beschränkt; Hilfe
validiert oder speichert keine Payload.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EVENT_LOG_OBJECTS](EVENT_LOG_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EventName` | `varchar(128)` | `NULL` | Input | Fachlich erforderlicher lowercase-ASCII-Schlüssel varchar(128), LEN 3..128, beginnt mit a-z; weitere Zeichen ausschließlich a-z, 0-9, Punkt, Unterstrich oder Bindestrich, z.B. app.import.started. Kein Trim oder automatisches Lowercasing. Technischer Default NULL nur für Hilfe; NULL/leer/ungültige Lexik wird abgewiesen. |
| `@EventLevel` | `varchar(16)` | `'INFO'` | Input | Taxativ: TRACE = feinste Ablaufdetails; DEBUG = technische Diagnose; INFO = normale Information (Default und NULL); WARNING = Warnung; ERROR = Fehler; CRITICAL = kritischer Fehler. UPPER normalisiert die Schreibweise; SQL-Gleichheitsregeln gelten. Die Werte sind Klassifikationen, keine automatische Retry-, Abbruch- oder Filtersteuerung. |
| `@Category` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Kategorietext mit Zeichen A-Z, a-z, 0-9, Punkt, Unterstrich und Bindestrich. NULL und leer sind zulässig; keine automatische Normalisierung. |
| `@Message` | `nvarchar(4000)` | `NULL` | Input | Optionaler menschenlesbarer Unicode-Text nvarchar(4000); NULL/leer erlaubt. Er wird persistiert, nicht ausgeführt; Secrets/vertrauliche Inhalte müssen vorher bereinigt werden. |
| `@DataJson` | `nvarchar(max)` | `NULL` | Input | Optionaler JSON-Objekttext nvarchar(max), höchstens 65536 UTF-16-Bytes (64 KiB); Arrays/Scalarroots und ungültiges JSON werden abgewiesen. Nach Entfernen gewöhnlicher führender Spaces muss { folgen; führender Tab/CR/LF genügt dieser LTRIM-Prüfung nicht. NULL bedeutet keine Zusatzdaten; leer ist ungültig. Beispiel N'{"rows":12}'. |
| `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | SQL-datetime2(7) als fachlicher UTC-Zeitpunkt, z.B. CONVERT(datetime2(7),'2026-10-30T12:00:00',126); kein Offset im Typ und keine Zeitzonenkonvertierung. NULL/Default verwendet SYSUTCDATETIME(). |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@SourceDatabaseName` | `sysname` | `NULL` | Input | Datenbankkennzeichnung als sysname (bis 128 UTF-16-Codeeinheiten), als reiner Name/Text. NULL/Default wird DB_NAME(); leer wird abgewiesen. Eine explizite Kennzeichnung wird nicht auf Existenz geprüft. |
| `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Kein zusammengesetzter Objektname, keine Existenz- oder Rechteprüfung. |
| `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung als sysname (bis 128 Codeeinheiten); NULL/leer wird gespeichert. Text-Metadatum, keine Ausführung und keine Objektauflösung. |
| `@ErrorNumber` | `int` | `NULL` | Input | Optionale int-Fehlernummer aus ERROR_NUMBER(), NULL bedeutet kein Fehlerkontext. Anders als ErrorEnvelope wird hier keine Positivitätsprüfung dieses Feldes durchgeführt. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Optionaler int-Wert 0..25 einschließlich aus ERROR_SEVERITY(); NULL erlaubt, außerhalb Fehler. Die EventLevel-Klassifikation wird dadurch nicht automatisch geändert. |
| `@ErrorState` | `int` | `NULL` | Input | Optionaler int-Wert 0..255 einschließlich aus ERROR_STATE(); NULL erlaubt, außerhalb Fehler. |
| `@ErrorProcedure` | `sysname` | `NULL` | Input | Optionale Fehlerprocedure als sysname (höchstens 128 Codeeinheiten), etwa ERROR_PROCEDURE(); NULL/leer erlaubt, kein auszuführender Aufruf. |
| `@ErrorLine` | `int` | `NULL` | Input | Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL erlaubt, 0/negativ wird abgewiesen. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_WriteEvent @EventName='demo.completed', @Message=N'Synthetic example';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_WriteEvent.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
