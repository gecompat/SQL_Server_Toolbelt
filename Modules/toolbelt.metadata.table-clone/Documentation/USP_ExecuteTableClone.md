# USP_ExecuteTableClone

Die einzeln freigegebene Erweiterung erzeugt einen frischen kanonischen
Tabellenklonplan und führt ihn nach exaktem Hashvergleich aus. Nur neue Ziele
in bestehenden Schemas derselben Installationsdatenbank sind zulässig.
Kein frei geliefertes SQL, keine Datenkopie und keine Triggerkopie.

Stand 2026-10-04: historisches3.1 implementiert und unabhängig sourcegeprüft;
begrenzte lokale3.1-Nachweise bestanden. Der4.0-Hash-/Planner-/Lifecyclepfad
bestand den im [Triggervertrag](../../../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
abgegrenzten lokalen Nachweis; vollständige Produktqualifikation bleibt offen.
Head-CI ist separat im PR nachzuweisen. Maßgeblich ist der
[Executor-Vertrag](../../../Documentation/Architecture/TABLE_CLONE_EXECUTE_CONTRACT.md).

## Parameter

Die ersten acht Parameter entsprechen unverändert `USP_ScriptTableClone` V3:
vier einzelne `nvarchar(max)`-Identifier mit Default NULL,
`IncludeIdentity bit=0`, `IncludeExtendedProperties bit=0`,
`TableMap sysname=NULL`, `ExternalReferenceRule varchar(16)='REJECT'`.

Danach folgen `ExpectedPlanHash varbinary(max)=NULL` und
`ForeignKeyMode varchar(16)='CREATE'`, schließlich der Standardtail
`ResultTable`, `KeepData`, `Debug`, `Hilfe`. Der erwartete Hash muss im
Fachmodus genau 32 Bytes enthalten. Help umgeht alle fachlichen Prüfungen.

`CREATE` führt alle fachlichen Planzeilen aus. `DEFER` überspringt nur
`FOREIGN_KEY` und `FOREIGN_KEY_STATE`; beide bleiben im vollständigen Hash.
Dies bereitet den separat freigegebenen Datenkopierworkflow vor und verändert
keine bestehenden Constraints. Groß-/Kleinschreibung und Padding werden
bei beiden fachlichen Moduswerten nicht normalisiert.

## Ergebnis

| Spalte | SQL-Typ | NULL |
|---|---|---|
| PlanHash | varbinary(32) | nein |
| TablesCreated | int | nein |
| StatementsExecuted | int | nein |

Genau eine Erfolgszeile nach Commit. Der Statementzähler zählt ausgeführte
fachliche Planzeilen; sieben SET-Zeilen und aufgeschobene FK-Zeilen zählen
nicht. Eine typisierte Extended-Property-Zeile zählt einmal.
Bei gesetzter ResultTable erfolgt ausschließlich deren kanonische
Replace-/Append-Ausgabe, kein zusätzliches SELECT.

## Rechte, Transaktion und Grenzen

Vorhandene DB- und Servermetadatensicht, lesbare Dependency-, Trigger- und
Eventnotification-Kataloge sowie erforderliche CREATE TABLE-, Schema-ALTER-
und REFERENCES-Rechte werden vorausgesetzt. Keine Rechteerteilung.
Relevante DDL-Trigger oder Eventnotifications blockieren; nichts wird
deaktiviert. DEFAULT-/CHECK-/Computed-Ausführungspfade mit UDF, CLR,
Sequenzen oder unklaren/externalen Dependencies werden abgewiesen.

Aktive Callertransaktionen werden vor Facharbeit abgelehnt. Die eigene
Transaktion umfasst neue Ziel-DDL und ResultTable-Veröffentlichung gemeinsam.
Ein später ResultTable-Fehler rollt deshalb auch die Ziel-DDL zurück.
Caller-SET-Zustand bleibt erhalten. Externe Effekte und Netzwerkfehler nach
Commit sind nicht Teil der Rollbackzusage.

Die Quell-/Zielstruktur und Serverbedingungen müssen während des Aufrufs
stabil bleiben; Toolbelt-AppLock schützt nicht gegen beliebige fremde DDL.
V3-Quoten einschließlich 64 Mapzeilen und 2 MiB Scripttext bleiben bestehen.
Zentraler dreiteiliger Aufruf bedeutet Ausführung in der Installationsdatenbank.

## Erwarteter Hash

Das versionierte Byteframing ist vollständig im Executor-Vertrag beschrieben.
Der Client berechnet ihn aus dem triggerfreien4.0-Vorschauresult, den exakt
verwendeten Identifiern und Optionen sowie der Installationsdatenbankidentität.
Es gibt keine neue öffentliche Hash- oder Vorschau-API. Ein Hash ist keine
Berechtigung und keine allgemeine Driftgarantie.
Hashlayout1 bindet jetzt das Modulrelease4.0.0; historische3.1-Hashes sind
damit kein gültiger4.0-Erwartungswert. IncludeTriggers bleibt0 und gehört
nicht zur unveränderten14-Parameter-Executorsignatur.

```sql
-- Reiner Hilfeaufruf, ohne Rechte-/Ziel-/Hashprüfung:
EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;

-- Fachaufruf nach der im Vertrag beschriebenen Client-Hashberechnung:
-- EXEC toolbelt_metadata.USP_ExecuteTableClone
--     @SourceSchema=N'dbo', @SourceTable=N'SyntheticSource',
--     @TargetSchema=N'dbo', @TargetTable=N'SyntheticClone',
--     @ExpectedPlanHash=@CalculatedPlanHash, @ForeignKeyMode='CREATE';
```

Der zweite Aufruf ist bewusst kommentiert: ein erfundener konstanter Hash
wäre kein ausführbares Beispiel. Das eigenständige
[Python-Clientbeispiel](../Examples/CalculatePlanHash.py) berechnet den Hash
aus unveränderten Vorschauzeilen und Optionen ohne SQL-Verbindung.
Gezielte lokale Runtime-Nachweise bestanden am 2026-10-04 auf SQL Server
2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170. Der genaue Scope
und die offenen Nachweise stehen im [Manifest](../module.yaml).
