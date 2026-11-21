# toolbelt_core.USP_ConfigureSecondSessionLoopback

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_ConfigureSecondSessionLoopback.md)
steht in der DDL und folgt bei `@Hilfe=1` als zusätzliche vier-spaltige Skillzeile
auf die Standardhilfe. Die neue Projektion ist offline geprüft, nicht nativ
abgenommen. Die Probe läuft auch bei `@Enabled=0`; zurückgegebener DBname und
SPID sind kein kryptografischer Nachweis derselben physischen SQLinstanz.
Ohne Callertransaktion liegt der eigene Konfigurations-Commit vor dem
ResultTable-Routing. Ein Outputfehler kann daher persistente Konfiguration
hinterlassen.

## Zweck

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

## Verhalten und Ergebnis

Konfiguriert ausschließlich den Namen eines bereits vorhandenen Loopback-Linked-Servers. Vor dem Speichern werden Serveroptionen und ein echter Remote-Probe geprüft. Der Probe muss dieselbe Datenbank in einer anderen `@@SPID` erreichen.

Die Procedure legt keinen Linked Server, kein Login-Mapping und keine Credentials an. Änderungen können optional mit `@ExpectedRowVersion` gegen Lost Updates geschützt werden.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Administrativ vorhandener sichtbarer Loopback-Linked-Server mit RPC OUT und
  deaktivierter Transaktionspromotion, gültigem Loginmapping und Remote-Probe-Recht.
  Diese Prozedur speichert die lokale Auswahl; sie legt keine Infrastruktur an.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'TBX_LOOPBACK';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ConfigureSecondSessionLoopback.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
