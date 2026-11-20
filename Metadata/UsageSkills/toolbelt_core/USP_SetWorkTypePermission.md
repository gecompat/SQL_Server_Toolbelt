---
name: "toolbelt-toolbelt-toolbelt-core-usp-setworktypepermission"
description: "Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkTypePermission"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@Principal", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig."}, {"name": "@PermissionName", "sql_type": "varchar(32)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig."}, {"name": "@PermissionState", "sql_type": "varchar(8)", "sql_default": "'ALLOW'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_SetWorkTypePermission.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# USP_SetWorkTypePermission

## Zweck und Einsatzfälle

Konfiguriert eine ausdrückliche Work-Type-Delegation an einen vorhandenen Datenbankprincipal.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Work-Type-Katalog 1.2.0, vorhandener Work Type und vorhandener Datenbankprincipal.
- EXECUTE sowie CONTROL auf toolbelt_core.WorkTypePermission; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@Principal` | `sysname` | `NULL` | Input | Vorhandener Datenbankprincipal als unquotierter sysname, nach Datenbank-Namensvergleich. Zulässige sys.database_principals-Typen taxativ: S=SQL-Benutzer, U=Windows-Benutzer, G=Windows-Gruppe, R=Datenbankrolle, E=externer Benutzer, X=externe Gruppe; principal_id darf nicht 0 sein. Kein Serverlogin oder automatisch angelegter Principal; NULL/leer/fehlender Eintrag ist ungültig. |
| `@PermissionName` | `varchar(32)` | `NULL` | Input | Taxativ und binär/case-sensitiv: ENQUEUE erlaubt das Einreihen; CLAIM erlaubt das Beanspruchen von Arbeit; EXECUTE_NEW_SESSION erlaubt den Start über den Second-Session-Provider. Keine weiteren Aktionen und kein implizites UPPER. SQL-Space-Padding ist vom binären Vergleich nicht aufgehoben. Fachlich erforderlich, NULL ungültig. |
| `@PermissionState` | `varchar(8)` | `'ALLOW'` | Input | Taxativ und binär/case-sensitiv: ALLOW legt eine erlaubende lokale Policy an (Default); DENY legt eine verbietende Policy an und gewinnt gegen passende ALLOWs; REMOVE entfernt den Eintrag genau dieser Aktion/Principal-Zuordnung. NULL/andere Werte ungültig. Dies ersetzt keine SQL-Objekt-EXECUTE-Rechte und vergibt keine Serverrechte. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Kein fachliches Resultset.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='demo.noop', @Principal=N'ContosoProducer', @PermissionName='ENQUEUE', @PermissionState='ALLOW';
```

## Rechte

EXECUTE und CONTROL auf toolbelt_core.WorkTypePermission.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Parameter, Autorität, Principal, Work Type oder Transaktionszustand ungültig.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-type/Documentation/USP_SetWorkTypePermission.md`

Keine Installations-, Definitions- oder Rechteattestation.
