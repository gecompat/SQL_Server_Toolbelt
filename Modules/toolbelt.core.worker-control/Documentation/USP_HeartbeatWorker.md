# USP_HeartbeatWorker

Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.

Öffentliche Worker-Control-Fassade.

## Parameter

- `@WorkerId uniqueidentifier = NULL`
- `@WorkerGeneration bigint = NULL`
- `@WorkerToken uniqueidentifier = NULL`
- `@Debug tinyint = 0`
- `@Hilfe bit = 0`

## Ergebnis

Kein fachliches Resultset.

Hilfe zuerst ohne Fachprüfung; Debug erzeugt hier keine eigenen Messages. Ein tabellarisches Ergebnis nutzt den kanonischen ResultTable-Vertrag atomar. Fehler 54210..54239, bestehende Queue-/Enginefehler bleiben getrennt. Vorhandene EXECUTE-Rechte sind erforderlich; keine Rechtevergabe. Nachweise und offene Grenzen: [Modulstatus](../README.md); unveröffentlicht.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Aktuelle Nachweise und Grenzen stehen im [Modulstatus](../README.md).

## Beispielaufruf

Zusammenhängende Betriebsbeispiele mit Beschaffung der IDs/Versionen und
Ergebnisdeutung: [Worker starten und steuern](../../../Workers/ExternalQueue/USAGE.md).
Ein untenstehender `@Hilfe=1`-Aufruf liest nur die Referenz, er führt keine
Workeraktion aus.

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

## Hilfe und Fehlerklärung

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_HeartbeatWorker.md)
steht auch in der DDL. `@Hilfe=1` liefert zusätzlich zur bisherigen Standardhilfe
eine Skillzeile mit `SkillFormatVersion`, `SchemaName`, `ObjectName` und
`SkillMarkdown nvarchar(max)`. Fachlich erforderliche NULL-Defaults dienen nur
der Hilfe. Die Skillreferenz trennt tatsächliche Owner-/Tokenprüfungen von
administrativer EXECUTE-Autorität sowie die Rückgabe neuer Identitäten von
einer Bestätigung bereits laufender Arbeit. Historische Nachweise bleiben
an ihre ursprünglichen Artefakte gebunden.

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_HeartbeatWorker.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
