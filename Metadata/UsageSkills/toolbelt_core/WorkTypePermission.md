---
name: "toolbelt-work-type-worktypepermission"
description: "Interne persistente identitäts- und versionsgebundene Work-Type-Delegation."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "WorkTypePermission"
object_type: "TABLE"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_core.USP_SetWorkTypePermission"]
---

# WorkTypePermission

## Zweck und Einsatzfälle

Interne persistente identitäts- und versionsgebundene Work-Type-Delegation. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Voraussetzungen

SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Parameter und Zugriff

Keine Aufrufparameter. Schema: WorkTypeId bigint NOT NULL, PrincipalId int NOT NULL, PermissionName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL, PrincipalSid varbinary(85) NOT NULL, PrincipalCreatedAt datetime NOT NULL, WorkTypeVersion binary(8) NOT NULL, IsDenied bit NOT NULL. Primary Key (WorkTypeId,PrincipalId,PermissionName); Foreign Key auf WorkType(WorkTypeId) mit ON DELETE CASCADE; CHECK PermissionName IN ENQUEUE/CLAIM/EXECUTE_NEW_SESSION nach SQL-Textvergleich. WorkTypeVersion speichert den gebundenen Elternstand, ist kein eigener rowversion-Datentyp und wird nicht automatisch aktualisiert.

## Ergebnisse

Persistente Policyzeilen mit obigem Schema, kein ausführbares Objektresultset und keine garantierte Tabellenordnung. IsDenied=0 erlaubt, 1 verbietet im jeweiligen gebundenen Kontext. Direkte DML kann die Verwaltungsregeln umgehen und ist kein Consumervertrag; vorgesehener Schreibweg USP_SetWorkTypePermission, Auswertung durch interne TVF.

## Aufrufbeispiele

```sql
-- Bestehender synthetischer Work Type und DBprincipal sind Voraussetzung.
EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName='contoso.noop',@Principal=N'ContosoProducer',@PermissionName='ENQUEUE',@PermissionState='ALLOW';
-- Persistente App-Delegation, nur im autorisierten Verwaltungsscope.
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
```

## Rechte

Keine direkte DML-Empfehlung für Anwendungen. Bestehende administrative DDL-/Tabellenrechte nur im ausdrücklich autorisierten Verwaltungskontext. Vorgesehene Änderung über die öffentliche SetPermission-USP. Keine automatisch erteilten Server-/Datenbankrollen, SQL-GRANTs oder erweiterten Rechte. Gleichnamiger Login in einer anderen Datenbank ersetzt kein gültiges DBprincipal-Mapping.

## Ressourcenbedarf

Persistente Zeilen pro WorkType/Principal/Aktion mit festem Primärschlüssel. Keine eigene globale Zeilen-/Speicherquote oder zeitliche Retention; veraltete Bindungen können bis zu ausdrücklicher Verwaltung/Elternlöschung physisch bestehen. Kein Fremdschlüssel auf sys.database_principals. Keine feste CPU-/Heap-/Grant-/Latenz- oder Parallelitätszusage.

## Nebenwirkungen

CREATE bei fehlender Tabelle, Constraints und kaskadierende Policyentfernung beim Löschen eines WorkType. Ein reines SELECT ändert keine Daten. Elternupdates ändern dessen RowVersion und machen bestehende Policybindungen unwirksam, ohne diese Zeilen automatisch zu löschen.

## Fehlerbehandlung

Engine-/Constraint-/Berechtigungsfehler bei direktem DDL/DML, keine eigene Geschäftsfehlerzeile. PK verhindert doppelte Zuordnung, FK bindet Elternexistenz; SID-/Versionsechtheit ist Auswertungsvertrag, nicht durch einen Systemkatalog-FK garantiert.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Policy-/Minimalrechte-/Skill-/Installerabnahme. Historische Belege behalten ihre ursprüngliche Bindung. App-Delegation ist kein SQL-GRANT und ersetzt keine Objekt-/Datenbank-/Handlerrechte. Keine SQL-Server-Rollenanlage, Identitätsumschaltung, Tenant-Isolation oder pauschale Rechteattestation.
