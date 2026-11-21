---
name: "toolbelt-work-type-tvf-worktypeauthorization"
description: "Interne fail-closed Autorisierungsentscheidung aus aktuellem DBtoken und expliziter Policy."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "TVF_WorkTypeAuthorization"
object_type: "TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@WorkTypeId", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Explizite interne WorkTypeId, kein frei auszuführender Name/SQL-Text. NULL, nicht vorhandene oder negative ID ohne passende Katalogzeile ergibt IsAllowed=0, keinen Parameterfehler. Kein SQL-Default; Position ausdrücklich angeben."}, {"name": "@PermissionName", "sql_type": "varchar(32)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bekannte Policyaktionen ENQUEUE, CLAIM oder EXECUTE_NEW_SESSION. NULL/unbekannte Aktion ohne passende Zeile ergibt 0, kein THROW und kein automatisches UPPER. BIN2-Textvergleich behält SQL-Space-Padding. Kein SQL-Default; Position ausdrücklich angeben."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_core.USP_EnqueueWork", "toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
---

# TVF_WorkTypeAuthorization

## Zweck und Einsatzfälle

Interne fail-closed Autorisierungsentscheidung aus aktuellem DBtoken und expliziter Policy. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Voraussetzungen

SQL Server 2019/2022/2025 auf Windows/Linux, passende CL150/160/170, lokal/zentral. WorkType-Katalog und Policyobjekte in derselben Datenbank; zentrale Verwendung wertet den tatsächlichen DBtoken dieses Katalogs aus. Kein Second-Session- oder Queue-Provider für diese lokale Policyverwaltung/-entscheidung erforderlich. Eine Policy bindet WorkTypeId, Aktion, tatsächliche DBprincipal-ID/SID/create_date und exakte binary(8)-RowVersion des Work Types. Ändert sich dessen RowVersion oder wird ein Principal unter neuer Identität wiederangelegt, wird die alte Zeile unwirksam statt automatisch übernommen. Aktuelle sys.user_token-Zeilen einschließlich wirksamer Rollen werden im jeweiligen Katalog ausgewertet; kein frei übergebener Actor/Name kann einen Callertoken ersetzen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeId` | `bigint` | `None` | Explizite interne WorkTypeId, kein frei auszuführender Name/SQL-Text. NULL, nicht vorhandene oder negative ID ohne passende Katalogzeile ergibt IsAllowed=0, keinen Parameterfehler. Kein SQL-Default; Position ausdrücklich angeben. |
| `@PermissionName` | `varchar(32)` | `None` | Bekannte Policyaktionen ENQUEUE, CLAIM oder EXECUTE_NEW_SESSION. NULL/unbekannte Aktion ohne passende Zeile ergibt 0, kein THROW und kein automatisches UPPER. BIN2-Textvergleich behält SQL-Space-Padding. Kein SQL-Default; Position ausdrücklich angeben. |

## Ergebnisse

Genau eine logische IsAllowed-bit-Entscheidung: alle passenden gültigen Policyzeilen werden aggregiert; mindestens ein IsDenied=1 gewinnt gegen alle ALLOWs, ausschließlich passende IsDenied=0 erlaubt, keine passenden sichtbaren Zeilen ergeben 0. Auch dbo erhält keinen impliziten Bypass. Diese interne Funktion prüft weder WorkType.IsEnabled noch Handlerexistenz/EXECUTE oder Providerzustand; diese weiteren Prüfungen bleiben beim öffentlichen Consumer. IsAllowed ist logisch immer 0 oder 1, keine Fehler-/Statusspalten und keine Zeilen je Rolle. Physische abgeleitete Nullable-Metadaten sind keine andere fachliche Entscheidung.

## Aufrufbeispiele

```sql
SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(NULL,NULL);
-- Genau eine Zeile IsAllowed=0. Interner Core, kein Handleraufruf.
```

## Rechte

Interner Helfer im vorhandenen Ownership-/Berechtigungspfad der freigegebenen öffentlichen Queue-/Second-Session-Einstiege; kein generischer Consumergrant vorgeschlagen. Liest WorkTypePermission, WorkType, sys.database_principals und sys.user_token unter den bestehenden Rechten/Sichtbarkeitsregeln. Fehlende sichtbare gültige Policy wird abgewiesen, echte Zugriffsfehler bleiben SQL-Fehler. Keine automatisch erteilten Server-/Datenbankrollen, SQL-GRANTs oder erweiterten Rechte. Gleichnamiger Login in einer anderen Datenbank ersetzt kein gültiges DBprincipal-Mapping.

## Ressourcenbedarf

Relationaler inline-TVF-Kern mit JOINs auf Token/Principal/WorkType und MAX-Aggregat; passende Policyindexe helfen, aber Plan/Schätzungen/Sichtbarkeit hängen vom Aufruf ab. Kein Actor-/Tenant-Suchscan als Autorisierung. Keine feste CPU-/Heap-/Grant-/Latenz- oder Parallelitätszusage.

## Nebenwirkungen

Rein lesend im tatsächlichen Callertoken, keine Identitätsumschaltung, Session-Context-Änderung, Transaktion, Datei-/Netzwerkoperation, Policyänderung oder Handlerausführung. Kein besonderer IsEnabled- oder Handler-EXECUTE-Check in dieser Funktion.

## Fehlerbehandlung

Genau eine logische IsAllowed-bit-Entscheidung: alle passenden gültigen Policyzeilen werden aggregiert; mindestens ein IsDenied=1 gewinnt gegen alle ALLOWs, ausschließlich passende IsDenied=0 erlaubt, keine passenden sichtbaren Zeilen ergeben 0. Auch dbo erhält keinen impliziten Bypass. Diese interne Funktion prüft weder WorkType.IsEnabled noch Handlerexistenz/EXECUTE oder Providerzustand; diese weiteren Prüfungen bleiben beim öffentlichen Consumer. NULL/ungültige nicht passende Argumente liefern normale 0, keine eigene Eingabeexception. Engine-/Berechtigungsfehler bleiben sichtbar und werden nicht in erfolgreiches ALLOW umgewandelt.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Policy-/Minimalrechte-/Skill-/Installerabnahme. Historische Belege behalten ihre ursprüngliche Bindung. App-Delegation ist kein SQL-GRANT und ersetzt keine Objekt-/Datenbank-/Handlerrechte. Keine SQL-Server-Rollenanlage, Identitätsumschaltung, Tenant-Isolation oder pauschale Rechteattestation.
