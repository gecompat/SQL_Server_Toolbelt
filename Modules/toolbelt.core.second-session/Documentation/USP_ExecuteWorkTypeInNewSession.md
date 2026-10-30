# toolbelt_core.USP_ExecuteWorkTypeInNewSession

## Zweck

Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.

## Verhalten und Ergebnis

Löst den Work Type lokal auf, prüft Providerdrift und übergibt ausschließlich gebundene Parameter an den internen Remote-Dispatcher. Execution- und Correlation-ID werden aus dem aktiven Execution Context übernommen oder deterministisch ergänzt.

Die Ergebniszeile enthält Caller- und Remote-Session-ID, Caller-Transaktionszustand, Context-IDs, Handler-Returncode und Remote-Dauer. Ein Handlerfehler wird nicht in Erfolg umgewandelt.

`@ResultTable` folgt dem allgemeinen USP-Vertrag, ist aber bei `XACT_STATE() = -1` nicht zulässig. Die direkte Standardausgabe bleibt in diesem Zustand verfügbar.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Zusätzlich sind Handler-EXECUTE und die Policy EXECUTE_NEW_SESSION erforderlich. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei registriertem ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD ist ein nicht-NULL JSON-Objekt erforderlich. Höchstens 1048576 UTF-16-Bytes (1 MiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keinen führenden Tab/CR/LF. Die Objektfelder richten sich nach dem konkreten Handlervertrag, nicht nach einem allgemeinen Work-Type-Schema. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive Context-ID, sonst eine neu erzeugte ID. Explizite ID wird übernommen; keine Lookup-Pflicht auf eine vorher gespeicherte Ausführung. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. NULL/Default verwendet die aktive CorrelationId, sonst die ausgewählte ExecutionId. Eine explizite ID hat Vorrang. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Actor oder ORIGINAL_LOGIN(), leerer Text bleibt expliziter Text. Keine Identitäts-/Rechtevergabe durch diesen Wert. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Unicode-Text nvarchar(256); NULL/Default übernimmt den aktiven Tenant oder bleibt NULL. Leer ist ein expliziter Wert; keine Mandantenberechtigungsprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Bei XACT_STATE()=-1 unzulässig, ebenso zusammen mit SuppressResult=1; direkte Ausgabe bleibt bei uncommittable Caller möglich. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert die Infrastruktur-Ergebniszeile oder routet sie nach ResultTable (Default/NULL); 1 unterdrückt nur diese Ausgabe nach erfolgreichem Remote-Handlerlauf und Returncodeprüfung. Mit nicht-NULL ResultTable unvereinbar. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='demo.noop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ExecuteWorkTypeInNewSession.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
