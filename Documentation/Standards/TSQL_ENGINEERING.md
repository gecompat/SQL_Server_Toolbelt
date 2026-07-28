# T-SQL-Engineering-Regeln

## Grundprinzipien

- Set-basierte Operationen vor Cursor- oder Schleifenlösungen.
- Inline Table-valued Functions klar vor Multi-statement Table-valued Functions, wenn der fachliche Vertrag dies erlaubt.
- Kein Boilerplate ohne dokumentierten Zweck.
- Öffentliche und interne technische Identifier sind englisch; Kommentare sind deutsch.

## Error Handling

- Error Handling an fachlichen und transaktionalen Grenzen, nicht nach jedem Statement.
- `TRY/CATCH` bei Transaktionen, Cleanup, dynamischem SQL oder gekoppelten Mutationen.
- Fehler mit `THROW` weitergeben; keine ursprüngliche Fehlerursache verschleiern.
- `XACT_ABORT ON` bei transaktionalen Abläufen prüfen.
- Inline TVFs nicht allein wegen allgemeiner Fehlerbehandlung in Multi-statement TVFs umwandeln.

## Performance

- SARGability erhalten und implizite Konvertierungen vermeiden.
- Cardinality Estimation und Optimizer-Sichtbarkeit berücksichtigen.
- Keine unnötigen Parallelitätssperren; `MAXDOP` nur begründet.
- Memory Grants, Sorts, Hashes und Materialisierung großer Resultmengen prüfen.
- TempDB bewusst und speicherschonend verwenden.
- Parameter Sniffing, lokale Variablen und `RECOMPILE` bewusst einsetzen.

## Datentypen

- `varchar` und `nvarchar` nach fachlicher Semantik, Zeichenvorrat, Codepage, Collation, Speicherbedarf und Konvertierungskosten wählen.
- `nvarchar` ist kein pauschaler Default.
- Längen, Precision und Scale explizit angeben.
- Parameter- und Spaltentypen so ausrichten, dass unnötige implizite Konvertierungen vermieden werden.

## Collation

- Toolbelt-Code erzeugt in seinen unterstützten Pfaden keine unbeabsichtigten Collation-Konflikte.
- Vergleichs-, Sortier- und Suchsemantik je Modul dokumentieren.
- Nutzervergleiche beliebiger fremder Collations werden nicht automatisch repariert.
- Interne Temp-Tabellenspalten mit Textdaten erhalten eine bewusst gewählte Collation.

## Metadaten

- Reguläre Objekte bevorzugt direkt über `sys.objects`, `sys.schemas`, `sys.tables`, `sys.columns`, `sys.types`, `sys.indexes` und weitere Catalog Views lesen.
- Geeignete read-only Catalog-Abfragen dürfen `WITH (NOLOCK)` verwenden, wenn das relevante Objekt laut Aufrufvertrag strukturell stabil ist.
- Präzise nach Datenbank, Schema, Typ und Name einschränken; danach mit IDs weiterarbeiten.
- `OBJECT_ID`, `SCHEMA_ID` und ähnliche Funktionen nicht unnötig wiederholt in Prädikaten aufrufen.
- Lokale Temp-Tabelle einmalig mit `OBJECT_ID(N'tempdb..#Name', N'U')` auflösen; anschließend über `tempdb.sys.*` und diese `object_id` weiterarbeiten.
- Den physischen Temp-Tabellensuffix nicht rekonstruieren.
- Keine unnötige Revalidierung eines laut Vertrag stabilen Objekts.

## Temp-Objekte

- Interne Temp-Objekte auch bei verschachtelten und rekursiven Aufrufen eindeutig benennen.
- Generische interne Namen wie `#Temp`, `#Result`, `#Help` oder `#Hilfe1` sind unzulässig.
- Constraints und Indizes auf Temp-Objekten nicht mit kollisionsanfälligen globalen Namen versehen.

## Dynamisches SQL

- Nur einsetzen, wenn statisches SQL nicht ausreicht.
- Werte über `sp_executesql` parametrisieren.
- Benutzereingaben nicht ungeprüft in SQL-Text konkatenieren.
- Identifier vollständig validieren und mit `QUOTENAME` behandeln.
- Generiertes SQL darf bei `@Debug >= 3` als Message erscheinen, sofern keine Secrets enthalten sind.

## Alternative Technologien

SQL CLR, C#, Python, R oder Java sind zulässig, wenn T-SQL nicht die beste Lösung ist. Die Entscheidung dokumentiert Performance, Security, Deployment, Plattform, Wartung und portable Alternativen.
