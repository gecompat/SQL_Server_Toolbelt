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
Der Client berechnet ihn aus dem triggerfreien4.1-Vorschauresult, den exakt
verwendeten Identifiern und Optionen sowie der Installationsdatenbankidentität.
Es gibt keine neue öffentliche Hash- oder Vorschau-API. Ein Hash ist keine
Berechtigung und keine allgemeine Driftgarantie.
Hashlayout1 bindet jetzt das Modulrelease4.1.0; historische3.1-/4.0-Hashes sind
damit kein gültiger4.1-Erwartungswert. IncludeTriggers bleibt0 und gehört
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

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@ExpectedPlanHash` | `varbinary(max)` | `NULL` | Input | Fachlich erforderliche exakt 32 Bytes varbinary des SHA256-Planhashes aus dem dokumentierten Hashlayout1 für Modul4.1.0. Aus unveränderten triggerfreien Vorschauzeilen, exakten Optionen und Installationsdatenbankidentität gemäß TABLE_CLONE_EXECUTE_CONTRACT.md/Examples/CalculatePlanHash.py berechnen. Kein Hextext ohne Konvertierung, kein Hash allein des Scripttexts. NULL/falsche Länge ungültig, Abweichung vom frisch erzeugten Plan bricht ab. |
| `@ForeignKeyMode` | `varchar(16)` | `'CREATE'` | Input | Taxativ, bytegenau ohne Trim/Casefold: CREATE (Default) führt alle fachlichen Planzeilen einschließlich FKs/Zustände aus; DEFER überspringt ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE für spätere Datenkopie. Beide Zeilenarten bleiben im vollständigen Planhash. NULL/andere Werte ungültig; bestehende Constraints werden nicht deaktiviert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Der Executor plant intern ausdrücklich mit Debug=0 und erzeugt keine eigenen zusätzlichen Diagnosemessages; bei ResultTable wird der übergebene Wert an den Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#tabellenklon).
