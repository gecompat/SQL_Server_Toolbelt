---
name: "toolbelt-toolbelt-toolbelt-core-tvf-executioncancellationstatus"
description: "Liest den registrierten kooperativen Abbruchstatus einer Ausführung."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "TVF_ExecutionCancellationStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt keine Zeilen. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/TVF_ExecutionCancellationStatus.sql", "Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_ExecutionCancellationStatus

## Zweck und Einsatzfälle

Liest den registrierten kooperativen Abbruchstatus einer Ausführung. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `None` | Explizites Argument ohne SQL-Default. NULL findet keine Anforderung und ergibt keine Zeilen. Auch Null-GUID ist kein Parameterfehler; sie findet regulär keinen über die öffentliche Request-USP angelegten Eintrag. |

## Ergebnisse

Null oder genau eine Zeile: ExecutionId uniqueidentifier aus dem nicht-NULL-Schlüssel, IsCancellationRequested bit als konstanter Wert 1, RequestedAtUtc datetime2(7) aus nicht-NULL-Zeitpunkt. Kein synthetischer false-Datensatz. NULL-/nichtgefundene ID ergibt keine Zeile. Grund, RequestedBy, Principalbindung und RowVersion werden nicht ausgegeben; keine Ordnungszusage erforderlich.

## Aufrufbeispiele

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS IsRequested;
-- 0.
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
-- Keine Zeilen.
```

## Rechte

Vorhandenes SELECT auf der TVF und funktionierende bestehende Abhängigkeits-/Ownershiprechte auf den Kern bzw. die Tabelle; kein direkter Grant auf Auditgründe erforderlich. Zentrale Nutzung erfordert gültige Datenbankauthentifizierung/Mapping und passende Rechte im Toolbelt-Ziel; ein Dreiteilname allein erteilt diese nicht. Keine Serverrollen oder Identitätsumschaltung durch diese Objekte.

## Ressourcenbedarf

Indexgestützter Lookup nach einem uniqueidentifier-Schlüssel; Skalar ruft den relationalen Kern auf. Keine Materialisierung von Audittexten im Status. Neue IDs: höchstens 100000 Tabellenzeilen insgesamt und 10000 je exaktem Tupel des tatsächlichen DBprincipals (ID/SID/create_date). Ein transaktionsgebundener exklusiver AppLock im public-Kontext serialisiert Quotenprüfung und Insert, Timeout 10000 ms; eine bereits vorhandene ExecutionId ist vor Quotenprüfung ein No-op. Kein automatisches Löschen abgelaufener Anforderungen. Direktes privilegiertes DML wird durch diese Anwendungsquoten nicht als Tabellenconstraint verhindert. Keine feste CPU-/Heap-/Durchsatz-/Latenzgarantie.

## Nebenwirkungen

Nur lesender Statuszugriff ohne eigene Transaktion, Dateien, Netzwerk, Serverkonfiguration oder Mutation. Gewöhnliche SQL-Isolation/Sperren gelten; keine von der Caller-Isolation unabhängige Sofortsichtbarkeit. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Fehlerbehandlung

Keine eigene Validierung/THROW-Codes. NULL/nichtgefunden sind reguläre negative Statusfälle; unerwartete Engine-/Berechtigungsfehler bleiben sichtbar. Ein negatives Ergebnis bedeutet nur kein sichtbarer passender Eintrag, nicht abgeschlossener oder erfolgreicher Worker.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechteabnahme. Historische Fach-/Repeat-/Quotenbelege behalten ihre ursprüngliche Bindung. Keine Installations-/Rechteattestation, kein Echtzeit-/Unterbrechungsversprechen. Eine ExecutionId ist kein Authentifizierungsgeheimnis und diese APIs prüfen keine fachliche Eigentümerschaft einer ID. Kontextwerte sind keine Sicherheitsgrenze.
