# toolbelt_core.USP_RequeueDeadLetter

## Zweck

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

## Verhalten und Ergebnis

`USP_RequeueDeadLetter` beginnt für ein `DEAD_LETTER`-Item einen neuen Retry-Zyklus. Es unterstützt eine optionale `rowversion`-Prüfung und speichert den Requeue-Grund. Lifetime-Attempts, bereinigte letzte Fehlerdaten und der Idempotency Key bleiben erhalten. Eine Barrier erzeugt dabei einen neuen Claim-Snapshot.

Die eigene Hilfe nennt die tatsächlichen Spalten aus `VW_WorkQueue`, die
Rowversion-Option und den Requeue-Vertrag. `@ResultTable` verwendet dieselbe
transaktionale Ausgabe wie die Queue-Mutation; Callertransaktionen bleiben
für diesen USP ausgeschlossen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/&lt;=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- Eine tatsächliche eigene DEAD_LETTER-ID einsetzen.
DECLARE @WorkItemId bigint=NULL;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@WorkItemId, @RequeueReason=N'Synthetischer Wiederholungsversuch';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RequeueDeadLetter.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
