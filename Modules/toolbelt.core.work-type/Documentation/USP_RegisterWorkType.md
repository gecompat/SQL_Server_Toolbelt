# toolbelt_core.USP_RegisterWorkType

## Zweck

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

## Verhalten und Ergebnis

Registriert eine vorhandene Stored Procedure. Exakte Wiederholungen sind idempotent. Abweichende Konfigurationen benötigen `@AllowUpdate = 1`; deaktivierte Einträge benötigen zusätzlich `@Reactivate = 1`. `@ExpectedRowVersion` ermöglicht Optimistic Concurrency.

`ParameterMode` ist auf `NONE` und `JSON_PAYLOAD` begrenzt. `PayloadContractJson` ist deklarative Metadaten und wird nicht als SQL ausgeführt.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion. |
| `@HandlerSchema` | `sysname` | `NULL` | Input | Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE. |
| `@HandlerProcedure` | `sysname` | `NULL` | Input | Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Input | Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Input | Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{"description":"synthetic payload"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Input | Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig. |
| `@IsIdempotent` | `bit` | `0` | Input | Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung. |
| `@AllowUpdate` | `bit` | `0` | Input | Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten. |
| `@Reactivate` | `bit` | `0` | Input | Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='demo.noop', @HandlerSchema=N'dbo', @HandlerProcedure=N'USP_DemoNoop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RegisterWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
