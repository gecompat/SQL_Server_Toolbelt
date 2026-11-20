---
name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesbigintstatus"
description: "Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen."
skill_format_version: "1.0"
module_id: "toolbelt.core.generate-series"
schema_name: "toolbelt_core"
object_name: "TVF_GenerateSeriesBigIntStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Start", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile."}, {"name": "@Stop", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL."}, {"name": "@Step", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows."}]
source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_GenerateSeriesBigIntStatus

## Zweck und Einsatzfälle

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen. Begrenzte Kontrolloberfläche für nicht vertrauenswürdige Eingaben.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows oder Linux; Compatibility Level 150/160/170. Modul installiert, kein CLR oder externer Provider. Alle drei Argumentpositionen müssen im Funktionsaufruf angegeben werden; DEFAULT in der dritten Position oder explizites NULL aktiviert den Richtungsdefault.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile. |
| `@Stop` | `bigint` | `kein Default` | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL. |
| `@Step` | `bigint` | `NULL` | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows. |

## Ergebnisse

Value bigint NULL, Status varchar(16) NOT NULL und RequestedRows decimal(38,0) NULL. Bei gültigen höchstens 1000000 Werten je eine Zeile mit Status OK und derselben Gesamtzahl. Sonst genau eine Kontrollzeile: SQL_NULL bei NULL in Start/Stop (Value/RequestedRows NULL), INVALID bei Step=0 (beide NULL), EMPTY bei falscher Richtung (Value=NULL, RequestedRows=0), LIMIT bei mehr als 1000000 Werten (Value=NULL, RequestedRows=exakte Gesamtzahl). NULL-Prüfung hat Vorrang vor Step=0.

## Aufrufbeispiele

```sql
SELECT Value,Status,RequestedRows
FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,2) ORDER BY Value;
-- (1,OK,3), (3,OK,3), (5,OK,3).
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000001,1);
-- Eine Zeile: Value=NULL, Status=LIMIT, RequestedRows=1000001.
```

## Rechte

Vorhandenes SELECT für SELECT-Aufrufe auf der Funktion; REFERENCES für entsprechende Referenzverwendungen. Kein Rechtegrant oder Identitätswechsel. Die Installation allein macht unbegrenzte Aufrufe durch untrusted Principals nicht sicher.

## Ressourcenbedarf

Multistatement-TVF berechnet die angeforderte Anzahl in decimal(38,0) vor der Expansion. Oberhalb 1000000 keine Fachzeilenexpansion, sondern eine LIMIT-Kontrollzeile. Bis zu 1000000 Zeilen werden über den bigint-Kern in die Rückgabetabelle eingefügt; diese Grenze ist kein Laufzeit-/Speicherversprechen.

## Nebenwirkungen

Keine persistenten Daten-, Datei-, Netzwerk-, Konfigurations- oder Truständerungen. Die Statusfunktion befüllt ausschließlich ihre lokale Rückgabetabelle. Keine Ausführungsautorität durch diese Beschreibung.

## Fehlerbehandlung

NULL, Step=0, falsche Richtung und Mengenüberschreitung werden wie oben als Kontrollzeilen ausgegeben. Typbindung und unerwartete Enginefehler bleiben Fehler.

## Aussagegrenzen

ORDER BY selbst angeben; keine Ausgabeordnung aus ROW_NUMBER ableiten. Keine Datums-, Dezimal- oder beliebige Zahlenbreitensemantik. Bei der Statusfunktion sind Kontrollzeilen von gültigen Werten durch Status zu unterscheiden; COUNT(*) ist dort keine verlässliche Fachzeilenzahl. Mathematische Fassade und Statusoberfläche haben ausdrücklich unterschiedliche NULL-/Fehlerprioritäten und Mengengrenzen.
