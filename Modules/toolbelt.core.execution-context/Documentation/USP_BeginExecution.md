# toolbelt_core.USP_BeginExecution

## Zweck

Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.

## Verhalten und Ergebnis

Beginnt einen Root-Context oder erhöht bei erlaubter Verschachtelung den `ScopeDepth`. Eine explizit übergebene Execution-ID wird am Root verwendet; andernfalls wird `NEWID()` erzeugt. Die Correlation-ID erbt standardmäßig die Execution-ID.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EXECUTION_CONTEXT_OBJECTS](EXECUTION_CONTEXT_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | OUTPUT | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@AllowNested` | `bit` | `1` | Input | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_BeginExecution @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_BeginExecution.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
