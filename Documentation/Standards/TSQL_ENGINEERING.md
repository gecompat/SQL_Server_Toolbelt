# T-SQL-Engineering-Regeln

## Grundprinzipien

- Set-basierte Operationen vor Cursor- oder Schleifenlösungen.
- Inline Table-valued Functions klar vor Multi-statement Table-valued Functions, wenn der fachliche Vertrag dies erlaubt.
- Für eine öffentliche Scalar-valued Function wird nach Möglichkeit eine
  semantisch äquivalente inline Table-valued Function angeboten.
- Kein Boilerplate ohne dokumentierten Zweck.
- Öffentliche und interne technische Identifier sind englisch; Kommentare sind deutsch.

## SVF und inline TVF

- Die inline TVF ist der kanonische relationale Kern, wenn sich dieselbe
  Fachlogik als ein relationaler Ausdruck implementieren lässt.
- Die SVF darf zusätzlich als bequeme skalare Aufrufvariante bestehen. Sie
  liest ihren Rückgabewert aus der kanonischen inline TVF oder verwendet einen
  nachweislich gleichwertigen gemeinsamen Kern.
- Eine inline TVF, die in ihrem `SELECT` lediglich die SVF aufruft, ist keine
  Performancealternative und erfüllt diese Regel nicht.
- Die inline TVF liefert bei skalarer Semantik genau eine Zeile und eine
  fachlich benannte Ergebnisspalte. Dadurch bleiben `CROSS APPLY` und
  `OUTER APPLY` eindeutig verwendbar.
- Objektseite, Modul-README und Beispiele nennen die inline TVF als bevorzugte
  mengenorientierte API. Die SVF bleibt für Einzelaufrufe und bestehende
  skalare Aufrufstellen dokumentiert.
- Contract-Tests prüfen Ergebnisparität, `NULL`- und Fehlersemantik sowie den
  tatsächlichen Objekttyp. Ein behaupteter Parallelitätsvorteil benötigt einen
  reproduzierbaren Plan- oder Runtime-Nachweis.
- Ist keine sinnvolle inline-TVF-Implementierung möglich, dokumentiert das
  Modul die technische Ursache und die geprüften Alternativen. Bloße
  Implementierungsbequemlichkeit genügt nicht als Ausnahme.

Nicht ge-inline-te Scalar UDFs verhindern Intra-query-Parallelität. SQL Server
2019 und neuer kann geeignete T-SQL-Scalar-UDFs bei Compatibility Level 150
oder höher automatisch in den aufrufenden Ausdruck einbetten und dadurch
Parallelität wieder ermöglichen. Eligibility und tatsächliches Inlining sind
jedoch kein stabiler Bibliotheksvertrag. Die relationale inline-TVF-API wird
deshalb unabhängig davon angeboten.

Primärquellen:

- [Microsoft: Scalar UDF Inlining](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver17)
- [Microsoft: Query Processing Architecture Guide](https://learn.microsoft.com/en-us/sql/relational-databases/query-processing-architecture-guide?view=sql-server-ver17)
- [Microsoft: CREATE FUNCTION](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17)

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
- Scalar-UDF-Inlining nicht als Ersatz für eine explizite relationale API
  voraussetzen.
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
