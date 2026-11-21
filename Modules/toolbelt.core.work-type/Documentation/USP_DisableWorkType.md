# toolbelt_core.USP_DisableWorkType

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_DisableWorkType.md)
steht in der ausgelieferten DDL und folgt bei `@Hilfe=1` als zusätzliche
vier-spaltige Skillzeile auf die bisherige Standardhilfe. Die Projektion ist
quell-/offlinegeprüft, nicht neu nativ abgenommen.

Wichtig beim ResultTable-Routing: Ohne Callertransaktion liegt der eigene
Katalog-Commit vor Helperprüfung und Ausgabe. Ein Routingfehler bedeutet daher
nicht, dass die Deaktivierung zurückgenommen wurde. Jede tatsächliche
Katalogänderung erzeugt eine neue RowVersion und macht ältere gebundene
Work-Type-Policies unwirksam, bis sie ausdrücklich neu konfiguriert werden.

## Zweck

Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.

## Verhalten und Ergebnis

Deaktiviert einen Work Type, erhält aber die registrierte Konfiguration. Ein optionaler Grund wird gespeichert. Wiederholtes Disable ist idempotent.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@DisabledReason` | `nvarchar(1000)` | `NULL` | Input | Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='demo.noop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_DisableWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
