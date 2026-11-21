---
name: "toolbelt-second-session-vw-secondsessionproviders"
description: "Katalogsicht auf gespeicherten Second-Session-Provider und sichtbare Linked-Server-Flags."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "VW_SecondSessionProviders"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql", "Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# VW_SecondSessionProviders

## Zweck und Einsatzfälle

Katalogsicht auf gespeicherten Second-Session-Provider und sichtbare Linked-Server-Flags. Keine automatische Erstellung oder Reparatur eines Linked Servers, Loginmappings oder RPC-Providers.

## Voraussetzungen

Installiertes Modul mit dieser Tabelle, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Die Sicht benötigt zusätzlich bestehende Sichtbarkeit in master.sys.servers. Die DDL selbst prüft keine funktionierende Remoteverbindung, Treiberverfügbarkeit oder Datenbank-/Serveridentität.

## Parameter und Zugriff

Keine Aufrufparameter. Vorgesehener Schreibweg USP_ConfigureSecondSessionLoopback, vorgesehener Leseweg VW_SecondSessionProviders. Direkte privilegierte Tabellen-/View-DML ist kein Consumervertrag und könnte die Probe-/Prüfregeln der Fassade umgehen. Eine SQL-Sicht ist hier kein ausdrücklich erzwungenes DML-Verbot.

## Ergebnisse

ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL, LinkedServerName sysname NOT NULL, IsEnabled bit NOT NULL DEFAULT 1, CreatedAtUtc datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(), CreatedBy sysname NOT NULL DEFAULT ORIGINAL_LOGIN(), ModifiedAtUtc datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME(), ModifiedBy sysname NOT NULL DEFAULT ORIGINAL_LOGIN(), RowVersion rowversion NOT NULL (8 Byte). Zusätzlich drei logisch nicht-NULL bit-Felder: LinkedServerExists, RpcOutEnabled, RemoteProcTransactionPromotionEnabled. LEFT JOIN auf master.sys.servers nach BIN2-Namensvergleich und is_linked=1. Fehlender/unsichtbarer Join: Exists=0,RpcOut=0,Promotion=1. Kein Ersatzdatensatz, falls die gespeicherte Konfiguration fehlt; dann null Zeilen. RowVersion wird hier roh als rowversion projiziert, nicht in einen neuen Zähler umgerechnet. Provider-/Auditspalten bleiben unverändert. Keine Tabellen-/View-Ausgabeordnung. NULL-/Typmetadaten eines abgeleiteten Views sind nicht mit einer neuen fachlichen Validierung gleichzusetzen.

## Aufrufbeispiele

```sql
SELECT ProviderName,IsEnabled,LinkedServerExists,RpcOutEnabled,RemoteProcTransactionPromotionEnabled
FROM toolbelt_core.VW_SecondSessionProviders;
-- Keine Zeile: kein gespeicherter Provider.
-- Flags sind sichtbare Katalogzustände, kein Connectivity-/TLS-Test.
```

## Rechte

Vorhandenes SELECT auf der öffentlichen Sicht plus funktionierende bestehende Ownership-/Abhängigkeitsrechte und notwendige master.sys.servers-Metadatensichtbarkeit. Kein pauschaler Direkt-DML-Grant auf die interne Tabelle vorgeschlagen. Auditprincipals und Linked-Server-Namen sind reale Umgebungsmetadaten und privat zu behandeln. Zentrale Nutzung braucht gültiges Ziel-DB-Mapping/Rechte; keine automatische Rechteerteilung.

## Ressourcenbedarf

Kleine Providerkatalogtabelle mit PK/Unique-Index und serverseitigem Metadatenjoin; keine eigene Heap-/CPU-/Latenz-/Zeilenquote. Der CHECK begrenzt bekannte Providernamen, aber ersetzt keine Probe oder physische Endpointbindung. Optimizer und vorhandene Rechte bestimmen die tatsächliche Katalogsicht; keine Parallelitäts-/Memory-Grant-Zusage.

## Nebenwirkungen

Reiner vorgesehener SELECT-Pfad ohne RPC, Probe, Session-Context-Änderung, Transaktion oder Datenmutation. Ein späterer Aufruf kann andere Flags sehen; kein stabiler Remotezustand oder Snapshotversprechen. Kein Netzwerkzugriff durch das bloße Lesen dieser Objekte.

## Fehlerbehandlung

Keine eigenen Geschäftsfehlercodes/-resultsets. Engine-/Berechtigungs-/Constraintfehler bleiben sichtbar. Fehlende sichtbare Linked-Server-Zeile wird in der View durch sichere negative Flags dargestellt, nicht als erfolgreiche Transportprüfung. Datenbankgleicher Name, SPID- oder Katalogflags sind keine authentifizierte Serveridentität.

## Aussagegrenzen

Quellgeprüfter Vertrag dieser Objekte, keine neue native Hilfe-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Katalogeintrag/IsEnabled bedeutet weder erreichbare noch richtig authentifizierte Verbindung. Die View attestiert weder Installation aller Abhängigkeiten noch ausreichende Aufruferrechte.
