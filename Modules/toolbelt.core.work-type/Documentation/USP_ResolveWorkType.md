# toolbelt_core.USP_ResolveWorkType

## Zweck

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

## Verhalten und Ergebnis

Löst genau einen Work Type auf. Standardmäßig müssen der Eintrag enabled, die Zielprocedure vorhanden und für den aktuellen Principal ausführbar sein.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@RequireEnabled` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt einen aktivierten Eintrag (Default und NULL); 0 lässt einen deaktivierten Eintrag zu. Der Eintrag und seine Handlerprocedure müssen unabhängig davon existieren. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | Taxativ für bit: 1 verlangt vorhandenes EXECUTE des Callers auf den Handler (Default und NULL); 0 überspringt nur diese EXECUTE-Prüfung, nicht die Handlerexistenz oder eine explizit gewählte Policyprüfung. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. NULL (Default) bedeutet keine zusätzliche Work-Type-Policyprüfung. Eine gewählte Aktion verlangt ein wirksames ALLOW unter Berücksichtigung von DENY. |
| `@SuppressResult` | `bit` | `0` | Input | Taxativ für bit: 0 liefert/routet die Resolverzeile (Default); 1 prüft ohne fachliche Ausgabe und ist mit ResultTable unvereinbar. Anders als beim Second-Session-Aufruf ist NULL hier ausdrücklich ungültig (51597). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Nicht zusammen mit SuppressResult=1. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='demo.noop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ResolveWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
