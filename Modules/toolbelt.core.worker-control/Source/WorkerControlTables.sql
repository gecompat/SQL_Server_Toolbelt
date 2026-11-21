-- Interne persistente Provideridentitäten; keine Rechteerteilung oder öffentlichen DML-Verträge.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'toolbelt_core.WorkerControlConfiguration',N'U') IS NULL
BEGIN
 CREATE TABLE toolbelt_core.WorkerControlConfiguration
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-workercontrolconfiguration"
-- description: "Interne Einzeilenkonfiguration der Managed-Worker-Admission."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "WorkerControlConfiguration"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_SetWorkerConcurrency", "toolbelt_core.USP_SetWorkerIntervals", "toolbelt_core.VW_WorkerStatus"]
-- ---
--
-- # WorkerControlConfiguration
--
-- ## Zweck und Einsatzfälle
--
-- Interne Einzeilenkonfiguration der Managed-Worker-Admission. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
--
-- ## Parameter und Zugriff
--
-- Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `ConfigurationId` | `tinyint` | NOT NULL; Primärschlüssel und CHECK=1 |
-- | `MaxConcurrentExecutions` | `int` | NOT NULL; >=0 |
-- | `HeartbeatSeconds` | `int` | NOT NULL;1..3600 |
-- | `UnreachableSeconds` | `int` | NOT NULL;3..86400 und>=3*HeartbeatSeconds |
-- | `ConfigVersion` | `rowversion` | NOT NULL; enginegeneriert |
--
-- Neuanlage initialisiert ConfigurationId1,MaxConcurrentExecutions1,HeartbeatSeconds15,UnreachableSeconds60. Das sind einmalige Seedwerte, keine Spaltendefaults; nur ConfigVersion wird automatisch von der Engine erzeugt. PK/CHECK erlauben höchstens eine Zeile, erzwingen ihre Existenz nicht. 0 ist für MaxConcurrentExecutions zulässig; kein kleineres positives Maximum ist in der Tabelle festgelegt. Bestehende leere Tabelle wird durch den CREATE-Guard nicht erneut initialisiert.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
-- FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
-- ```
--
-- ## Rechte
--
-- Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.
--
-- ## Ressourcenbedarf
--
-- Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
 (ConfigurationId tinyint NOT NULL CONSTRAINT PK_WorkerControlConfiguration PRIMARY KEY,
 MaxConcurrentExecutions int NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,
 ConfigVersion rowversion NOT NULL,
 CONSTRAINT CK_WorkerControlConfiguration_Id CHECK(ConfigurationId=1),
 CONSTRAINT CK_WorkerControlConfiguration_Limits CHECK(MaxConcurrentExecutions>=0 AND HeartbeatSeconds BETWEEN 1 AND 3600 AND UnreachableSeconds BETWEEN 3 AND 86400 AND UnreachableSeconds>=3*HeartbeatSeconds));
 INSERT toolbelt_core.WorkerControlConfiguration(ConfigurationId,MaxConcurrentExecutions,HeartbeatSeconds,UnreachableSeconds) VALUES(1,1,15,60);
END;
IF OBJECT_ID(N'toolbelt_core.WorkerRegistration',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerRegistration
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-workerregistration"
-- description: "Interne Workeridentität mit Generation, Principalbindung und gepinnten Intervallen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "WorkerRegistration"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_RegisterWorker", "toolbelt_core.USP_HeartbeatWorker", "toolbelt_core.USP_SetWorkerState", "toolbelt_core.VW_WorkerStatus"]
-- ---
--
-- # WorkerRegistration
--
-- ## Zweck und Einsatzfälle
--
-- Interne Workeridentität mit Generation, Principalbindung und gepinnten Intervallen. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
--
-- ## Parameter und Zugriff
--
-- Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `WorkerId` | `uniqueidentifier` | NOT NULL |
-- | `WorkerGeneration` | `bigint` | NOT NULL;>0 |
-- | `WorkerToken` | `uniqueidentifier` | NOT NULL; vertrauliches internes Token |
-- | `OwnerPrincipalId` | `int` | NOT NULL; gespeicherte Principal-ID, kein FK |
-- | `ProviderKind` | `varchar(16)` | NOT NULL; BIN2, keine CHECK-Wertemenge in der Tabelle |
-- | `State` | `varchar(16)` | NOT NULL; BIN2, ACTIVE/PAUSED/DRAINING/UNREACHABLE/CLOSED |
-- | `AdmissionPaused` | `bit` | NOT NULL |
-- | `Capacity` | `int` | NOT NULL;>0 |
-- | `RunMode` | `varchar(16)` | NOT NULL; BIN2, BOUNDED/CONTINUOUS |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |
-- | `HeartbeatSeconds` | `int` | NOT NULL; keine eigene Bereichsconstraint dieser Tabelle |
-- | `UnreachableSeconds` | `int` | NOT NULL; keine eigene Bereichsconstraint dieser Tabelle |
--
-- Zusammengesetzter Primärschlüssel WorkerId/WorkerGeneration. Keine weiteren Uniqueness-/FK-/Spaltendefaultregeln, insbesondere kein FK auf SQL-Principals und keine Eindeutigkeit des WorkerToken. Die Tabellenconstraints prüfen nur positive Generation/Kapazität und die genannten State-/RunMode-Mengen. ProviderKind, Heartbeatintervalle, LastHeartbeat, AdmissionPaused und Zustandszusammenhänge werden nicht durch zusätzliche CHECKs abgesichert. Ein gespeicherter OwnerPrincipalId ist allein keine dauerhafte Principalidentitätsattestation.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT WorkerId,WorkerGeneration,State,Capacity,OccupiedSlots,ConfigVersion
-- FROM toolbelt_core.VW_WorkerStatus ORDER BY WorkerId,WorkerGeneration;
-- ```
--
-- ## Rechte
--
-- Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.
--
-- ## Ressourcenbedarf
--
-- Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
 (WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,
 OwnerPrincipalId int NOT NULL,ProviderKind varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 State varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,AdmissionPaused bit NOT NULL,Capacity int NOT NULL,
 RunMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 LastHeartbeatAtUtc datetime2(7) NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,
 CONSTRAINT PK_WorkerRegistration PRIMARY KEY(WorkerId,WorkerGeneration),
 CONSTRAINT CK_WorkerRegistration_Generation CHECK(WorkerGeneration>0),
 CONSTRAINT CK_WorkerRegistration_State CHECK(State IN('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED')),
 CONSTRAINT CK_WorkerRegistration_Capacity CHECK(Capacity>0),
 CONSTRAINT CK_WorkerRegistration_RunMode CHECK(RunMode IN('BOUNDED','CONTINUOUS')));
IF OBJECT_ID(N'toolbelt_core.WorkerSlotReservation',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerSlotReservation
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-workerslotreservation"
-- description: "Interne persistente Slot-/Claim-/Attemptbindung mit Budgetbelegung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "WorkerSlotReservation"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution", "toolbelt_core.VW_WorkerExecutionStatus"]
-- ---
--
-- # WorkerSlotReservation
--
-- ## Zweck und Einsatzfälle
--
-- Interne persistente Slot-/Claim-/Attemptbindung mit Budgetbelegung. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
--
-- ## Parameter und Zugriff
--
-- Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `SlotReservationId` | `uniqueidentifier` | NOT NULL; Primärschlüssel |
-- | `WorkerId` | `uniqueidentifier` | NOT NULL; Teil des Worker-FK |
-- | `WorkerGeneration` | `bigint` | NOT NULL; Teil des Worker-FK |
-- | `WorkItemId` | `bigint` | NOT NULL; FK auf WorkItem |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `ClaimToken` | `uniqueidentifier` | NOT NULL; vertrauliches internes Token |
-- | `ExecutionId` | `uniqueidentifier` | NOT NULL; eindeutig, kein FK auf ExecutionContext |
-- | `State` | `varchar(24)` | NOT NULL; BIN2, RESERVED/RUNNING/STOP_REQUESTED/STOPPING/UNKNOWN/COMMITTED/ROLLED_BACK/CLOSED |
-- | `IsOccupied` | `bit` | NOT NULL; gespeicherte Budgetbelegung |
-- | `AttemptNonce` | `uniqueidentifier` | NULL; vertrauliche Attemptbindung |
-- | `BoundPrincipalId` | `int` | NULL; gespeicherte Principal-ID, kein FK |
-- | `CreatedAtUtc` | `datetime2(7)` | NOT NULL; kein Spaltendefault |
-- | `EndedAtUtc` | `datetime2(7)` | NULL |
--
-- ExecutionId ist eindeutig; WorkItemId/ClaimGeneration ist als Paar eindeutig, auch für erhaltene terminale Reservations. FK WorkerId/WorkerGeneration auf WorkerRegistration sowie FK WorkItemId auf WorkItem, ohne ON DELETE CASCADE. Keine Spaltendefaults. Außer der State-Wertemenge keine CHECKs für positive Claimgeneration, Zeitreihenfolge, Occupied-/State-Konsistenz oder Token-/Noncebeziehungen. ExecutionContext-/Principalbindung und Freigabe werden durch verändernde Providerpfade geprüft, nicht allein durch diese Tabelle. UNKNOWN darf nicht als erfolgreich beendet oder frei interpretiert werden.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
-- FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
-- ```
--
-- ## Rechte
--
-- Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.
--
-- ## Ressourcenbedarf
--
-- Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
 (SlotReservationId uniqueidentifier NOT NULL CONSTRAINT PK_WorkerSlotReservation PRIMARY KEY,
 WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkItemId bigint NOT NULL,
 ClaimGeneration bigint NOT NULL,ClaimToken uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,
 State varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,IsOccupied bit NOT NULL,AttemptNonce uniqueidentifier NULL,
 BoundPrincipalId int NULL,CreatedAtUtc datetime2(7) NOT NULL,EndedAtUtc datetime2(7) NULL,
 CONSTRAINT UQ_WorkerSlotReservation_Execution UNIQUE(ExecutionId),
 CONSTRAINT UQ_WorkerSlotReservation_Claim UNIQUE(WorkItemId,ClaimGeneration),
 CONSTRAINT FK_WorkerSlotReservation_WorkerRegistration FOREIGN KEY(WorkerId,WorkerGeneration) REFERENCES toolbelt_core.WorkerRegistration(WorkerId,WorkerGeneration),
 CONSTRAINT FK_WorkerSlotReservation_WorkItem FOREIGN KEY(WorkItemId) REFERENCES toolbelt_core.WorkItem(WorkItemId),
 CONSTRAINT CK_WorkerSlotReservation_State CHECK(State IN('RESERVED','RUNNING','STOP_REQUESTED','STOPPING','UNKNOWN','COMMITTED','ROLLED_BACK','CLOSED')));
IF OBJECT_ID(N'toolbelt_core.WorkerExecutionDisposition',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerExecutionDisposition
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-workerexecutiondisposition"
-- description: "Interne aktuelle Hold-/Stop-Disposition je Queueauftrag."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "WorkerExecutionDisposition"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_StopWorkerExecution", "toolbelt_core.USP_ReleaseHeldWork", "toolbelt_core.USP_ReconcileWorkerExecution", "toolbelt_core.VW_WorkerExecutionStatus"]
-- ---
--
-- # WorkerExecutionDisposition
--
-- ## Zweck und Einsatzfälle
--
-- Interne aktuelle Hold-/Stop-Disposition je Queueauftrag. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
--
-- ## Parameter und Zugriff
--
-- Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `WorkItemId` | `bigint` | NOT NULL; Primärschlüssel und FK auf WorkItem |
-- | `SlotReservationId` | `uniqueidentifier` | NOT NULL; FK auf WorkerSlotReservation |
-- | `IsHeld` | `bit` | NOT NULL |
-- | `StopStatus` | `varchar(24)` | NOT NULL; BIN2, NONE/REQUESTED/STOPPING/ROLLED_BACK_HELD/ALREADY_COMMITTED/UNKNOWN |
-- | `HoldVersion` | `rowversion` | NOT NULL; enginegeneriertes Concurrencytoken |
--
-- Primärschlüssel WorkItemId erlaubt höchstens eine aktuelle Disposition pro Item. Separate FKs auf WorkItem und Reservation garantieren deren Existenz, nicht die Übereinstimmung des WorkItemId der Reservation; keine zusammengesetzte Kohärenzconstraint. Keine Spaltendefaults außer automatisch erzeugter rowversion. StopStatus-Wertemenge ist begrenzt, aber ihre Konsistenz mit IsHeld/Reservationszustand ist keine Tabellen-CHECK-Regel. HoldVersion ist ein Concurrencywert, keine Zeitangabe oder Freigabeautorität.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
-- FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
-- ```
--
-- ## Rechte
--
-- Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.
--
-- ## Ressourcenbedarf
--
-- Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
 (WorkItemId bigint NOT NULL CONSTRAINT PK_WorkerExecutionDisposition PRIMARY KEY,
 SlotReservationId uniqueidentifier NOT NULL,IsHeld bit NOT NULL,StopStatus varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,
 HoldVersion rowversion NOT NULL,
 CONSTRAINT FK_WorkerExecutionDisposition_WorkItem FOREIGN KEY(WorkItemId) REFERENCES toolbelt_core.WorkItem(WorkItemId),
 CONSTRAINT FK_WorkerExecutionDisposition_Reservation FOREIGN KEY(SlotReservationId) REFERENCES toolbelt_core.WorkerSlotReservation(SlotReservationId),
 CONSTRAINT CK_WorkerExecutionDisposition_Stop CHECK(StopStatus IN('NONE','REQUESTED','STOPPING','ROLLED_BACK_HELD','ALREADY_COMMITTED','UNKNOWN')));
IF OBJECT_ID(N'toolbelt_core.WorkerExecutionCommitWitness',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerExecutionCommitWitness
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-workerexecutioncommitwitness"
-- description: "Interne persistente Witnesskomponente für einen gebundenen Managedattempt."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "WorkerExecutionCommitWitness"
-- object_type: "TABLE"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.worker-control/Source/USP_BeginWorkerTransactionWitness.sql", "Modules/toolbelt.core.worker-control/Source/USP_RecordWorkerCommit.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution", "toolbelt_core.VW_WorkerExecutionStatus"]
-- ---
--
-- # WorkerExecutionCommitWitness
--
-- ## Zweck und Einsatzfälle
--
-- Interne persistente Witnesskomponente für einen gebundenen Managedattempt. Internes Objekt; keine direkte fachliche Tabellenmutation. Öffentliche Einstiege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Installiertes Worker-Control1.0.0 und passende Queue2.1.0-/ExecutionContext-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Markerfreier create-only-Installer erhält vorhandene Objekte; hier ist eine passende aktuelle Definition vorausgesetzt, kein eigenständiges CREATE/Upgrade aus dem Skill. Keine CLR-/Datei-/Netzwerk-/LLM-Aufrufe der Relation.
--
-- ## Parameter und Zugriff
--
-- Keine SQL-Aufrufparameter, technischen Defaults, OUTPUT-Parameter, @Hilfe oder ResultTable-Option. Schema-/Seed-/Defaultregeln sind Speicherverträge, keine Callerargumente. Lesen über die öffentlichen Statusviews und Mutation über autorisierte Worker-Control-/Providerpfade. Kein direktes DML-Beispiel auf der internen Tabelle.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `SlotReservationId` | `uniqueidentifier` | NOT NULL; Primärschlüssel und FK auf WorkerSlotReservation |
-- | `AttemptNonce` | `uniqueidentifier` | NOT NULL; vertrauliche Attemptbindung |
-- | `ExecutionId` | `uniqueidentifier` | NOT NULL |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `RecordedAtUtc` | `datetime2(7)` | NOT NULL; kein Spaltendefault |
--
-- Primärschlüssel/FK SlotReservationId sichert höchstens einen Witness je Reservation. Keine Spaltendefaults und keine weitere FK-/CHECK-Absicherung von Nonce, ExecutionId, Claimgeneration oder Zeit gegenüber der Reservation. Eine Zeile ist keine kryptografische Signatur oder selbständige Commitattestation. Der interne Transaktionspfad schreibt den Witness innerhalb des Handlertransaktionsrahmens; der spätere RecordWorkerCommit prüft zusätzlich Connection-/Nonce-/Principal-/Claim-/COMPLETED-Bindung. Eine uncommittete Zeile und ihr RecordedAtUtc beweisen keinen erfolgten Commit.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT SlotReservationId,WorkItemId,ClaimGeneration,State,IsHeld,HoldVersion,StopStatus
-- FROM toolbelt_core.VW_WorkerExecutionStatus ORDER BY WorkItemId,ClaimGeneration;
-- ```
--
-- ## Rechte
--
-- Keine direkten Tabellenrechte für normale Caller voraussetzen oder erteilen. Vorhandene EXECUTE-Rechte auf die benötigten öffentlichen Steuer-/Dispatchprozeduren und SELECT auf ihre Statusviews nutzen. Direkter Tabellenzugriff erfordert eigene vorhandene Rechte und wird durch diesen Skill nicht autorisiert.
--
-- ## Ressourcenbedarf
--
-- Persistente Tabellen-/Historiengröße, Indizes, Join-/Zählplan und konkurrierende Sperren bestimmen Aufwand/Logwachstum. Keine implementierte Zeilen-/Byte-/CPU-/Heap-/Zeitquote dieser Relation. PK/Unique/FK unterstützen Zuordnung, garantieren keine bestimmte Laufzeit. Kein automatischer Retentions-/Purgeprozess durch Tabelle oder View; Sperr-, Log-, Speicher- und Timeoutfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Engine wendet Schlüssel/FKs/CHECKs und rowversion bei tatsächlicher autorisierter Mutation an. Tabelle startet keine Handler, Heartbeats, Abbrüche, Reconciliation, Cleanup oder eigene Transaktionen. Initialisierung nur im jeweils bewachten CREATE-Pfad. Keine Statuszeile setzt selbständig einen SQL-Prozess fort.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen fachlichen Fehlercodes/Returnwerte der Tabelle. Ungültige Schlüssel/FKs/CHECKs/NOT-NULL oder fehlende Rechte ergeben Enginefehler. Constraints ersetzen keine Provider-/Transaktions-/Principal-/Proofprüfung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recovery-/Clientmetadatenabnahme. Historische Fachnachweise behalten ihre eigene Artefakt- und Zielbindung. Status, Generation und Heartbeat allein beweisen weder erfolgreichen Handlercommit noch Rollback; UNKNOWN bleibt ungeklärt. Keine Exactly-once-, Kill-/Hostverlust- oder Vollqualifikationsbehauptung. Keine Installations-/Rechteattestation. IDs, Tokens, Principals und betriebliche Statusdaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
 (SlotReservationId uniqueidentifier NOT NULL CONSTRAINT PK_WorkerExecutionCommitWitness PRIMARY KEY,
 AttemptNonce uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,
 ClaimGeneration bigint NOT NULL,RecordedAtUtc datetime2(7) NOT NULL,
 CONSTRAINT FK_WorkerExecutionCommitWitness_Reservation FOREIGN KEY(SlotReservationId) REFERENCES toolbelt_core.WorkerSlotReservation(SlotReservationId));
GO
