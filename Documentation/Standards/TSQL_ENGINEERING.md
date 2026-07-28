# T-SQL-Engineering-Regeln

## Grundprinzipien

- Set-basiert; mengenorientierte Operationen vor Cursor- oder Schleifen-basierten Lösungen.
- Inline TVF klar vor Multi-statement TVF, wenn die Logik es erlaubt.
- Kein Boilerplate ohne dokumentierten Zweck.

## Error Handling

- Error Handling an fachlichen und transaktionalen Grenzen, nicht nach jedem Statement.
- `TRY/CATCH` bei Cleanup, Transaktionen, dynamischem SQL oder gekoppelten Mutationen.
- Fehler mit `THROW` weitergeben; kein stilles Verschlucken von Fehlern.
- `XACT_ABORT ON` bei Transaktionen prüfen.

## Performance

- SARGability: Suchbedingungen so schreiben, dass Indizes genutzt werden können.
- Cardinality Estimation: keine künstlichen Verzerrungen durch implizite Konvertierungen.
- Parallelität: keine unnötigen Parallelitätssperren; `MAXDOP`-Hinweise nur mit Begründung.
- Memory Grants: große Sortier- und Hash-Operationen in TVFs und Prozeduren bedenken.
- TempDB: Temp-Tabellen bewusst einsetzen; keine übermäßige TempDB-Belastung.
- Compile-Verhalten: Parameter Sniffing, lokale Variablen und `RECOMPILE` bewusst einsetzen.
- Implizite Konvertierungen vermeiden: Datentypen konsistent halten.

## Datentypen

- `varchar`/`nvarchar` nach Semantik, Zeichenvorrat, Codepage, Collation, Speicher- und Konvertierungskosten.
- `nvarchar` ist kein pauschaler Default für alle Strings.
- Längenangaben explizit; kein `varchar` ohne Länge.
- Numerische Typen präzise wählen; `decimal`/`numeric` mit expliziter Präzision.

## Collation

- Collation-safe für eigene unterstützte Pfade.
- Nutzervergleiche inkompatibler Collations nicht automatisch reparieren.
- Collation-Vertrag je Modul dokumentieren.

## Metadaten

- Reguläre Objekte bevorzugt direkt über Catalog Views:
  `sys.objects`, `sys.schemas`, `sys.tables`, `sys.columns`, `sys.types`, `sys.indexes`, usw.
- Geeignete read-only Catalog-Abfragen dürfen `WITH (NOLOCK)` verwenden.
- Präzise einschränken: Datenbank → Schema → Typ → Name, danach mit IDs weiterarbeiten.
- Metadatenfunktionen (`OBJECT_ID`, `SCHEMA_ID`, usw.) nicht unnötig wiederholen.
- Lokale Temp-Tabelle einmalig mit `OBJECT_ID(N'tempdb..#Name', N'U')` auflösen; danach über `tempdb.sys.*` und diese `object_id`.
- Physischen Suffix einer Temp-Tabelle nicht rekonstruieren.
- Keine unnötige Revalidierung eines laut Vertrag stabilen Objekts.

## Temp-Objekte

- Interne Temp-Objekte bei verschachtelten oder rekursiven Aufrufen eindeutig benennen.
- Verbotene Temp-Tabellennamen: `#Temp`, `#Result`, `#Help`, `#Hilfe1` und ähnlich generische Namen.

## Dynamisches SQL

- Dynamisches SQL nur wenn statisches SQL nicht ausreicht.
- SQL-Injection verhindern: Parameter über `sp_executesql` übergeben; keine String-Konkatenation mit Benutzereingaben.
- Dynamisch erzeugtes SQL bei `@Debug >= 3` als Message ausgeben.

## Technologieentscheidung

Wenn T-SQL nicht ausreicht, sind folgende Alternativen zulässig:
- SQL CLR (C#)
- Python (`sp_execute_external_script`)
- R (`sp_execute_external_script`)
- Java (`sp_execute_external_script`)

In allen Fällen: technische Begründung erforderlich (Performance, Security, Deployment, Plattform, Wartung).
