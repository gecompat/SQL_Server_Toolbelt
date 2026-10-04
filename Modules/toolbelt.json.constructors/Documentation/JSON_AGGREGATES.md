# JSON-Aggregate

Die einzeln freigegebenen SAFE-CLR-Aggregate ergänzen die vier bestehenden
Konstruktor-USPs. `AGF_JsonArray(Ordinal,ValueKind,Value,Profile)` und
`AGF_JsonObject(Ordinal,Key,ValueKind,Value,Profile)` liefern nvarchar(max).
Ordinal int ist positiv und je Gruppe eindeutig. Key/Kind/Value sind
nvarchar(max), Profile tinyint ist exakt 1 oder 2 und bleibt je Gruppe gleich.
Keys sind vollständig längensensitive UTF16-Identitäten, ohne Culture-/Trim-
oder Paddingnormalisierung. SQL-NULL ist nur für Kind `null` erforderlich.

Ausgabe folgt Ordinal; die SQL-Verarbeitungsreihenfolge ist unerheblich.
Doppelte Ordinals oder Objectkeys, ungültige Literale/Unicode, gemischte
Profile und überschrittene Budgets sind Fehler; kein Teilergebnis.
Leere Aggregation liefert `[]` beziehungsweise `{}`. Ein JSON-Entry darf
höchstens Tiefe127 besitzen; der äußere Container ergibt maximal128.
Die Legacy-USPs übernehmen diese AGF127-Grenze ausdrücklich nicht.

Die genauen Entry-, Payload- und Wiregrenzen, Fehlerprioritäten, Bridge-
und Lifecyclebindings stehen im
[kanonischen JSON-1.2-Vertrag](../../../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md).
Die bekannte Registryzeile ist offline qualifiziert. Begrenzte native
Installations-, Fixture-, Upgrade- und Uninstallteilnachweise sind vorhanden;
die genaue Reichweite steht in [Tests](../Tests/README.md). Weitere
SQL-Clientmetadaten, Engine-Merge-/Serializationqualifikation und minimale
Callerrechte der öffentlichen 1.2-Umsetzung bleiben offen. Keine globale
Heap-, Spill-, Callbackhäufigkeits- oder Hardwallzusage.

```sql
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),Value nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'a',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,Value,Profile) AS JsonValue
FROM @Entries;
```
