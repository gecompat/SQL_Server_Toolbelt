# Architektur: Identifier- und Multipart-Name-Toolkit

## Entscheidung

`toolbelt.metadata.identifier` verwendet einen begrenzten zustandsbasierten
T-SQL-Parser. `TVF_ParseMultipartName` ist der einzige fachliche Kern;
`SVF_QuoteMultipartName` ist ein dünner Wrapper.

## Begründung

Eine Zerlegung nur an Punkten ist fachlich falsch, weil delimitierte
Identifier selbst Punkte enthalten können. Ein regulärer Ausdruck wäre auf
SQL Server 2019/2022 nicht portabel. Ein linearer Zustandsautomat bildet
öffnende/schließende Klammern, `]]`-Escapes und ausgelassene Bestandteile
direkt ab und ist bei der festen Eingabegrenze leichter prüfbar.

Die Parse-Funktion ist bewusst eine Multi-statement TVF. Eine Inline TVF
würde für den zustandsbehafteten Escape-Vertrag entweder rekursive CTE-Grenzen
oder schwer wartbare Präfixanalysen benötigen. Für maximal 1035 Zeichen ist
die klarere, lineare Implementierung der maßgebliche Trade-off.

## Sicherheitsgrenze

Das Modul erzeugt Identifiertext, aber keine Autorisierungsentscheidung.
Aufrufer müssen weiterhin festlegen, welche Server, Datenbanken, Schemas und
Objekte fachlich zulässig sind. Eingaben werden nie als SQL-Ausdruck
interpretiert.

## Nicht enthalten

- Objekt- oder Berechtigungsauflösung;
- automatische Ergänzung von Server, Datenbank oder Standardschema;
- doppelt quotierte Identifier;
- Normalisierung von Schreibweise oder Whitespace;
- Wildcard- oder Ausdrucksauswertung.

## Quellen

- Microsoft (2026): [Transact-SQL-Syntaxkonventionen](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transact-sql-syntax-conventions-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [`QUOTENAME`](https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17).
- Microsoft (2026): [`CREATE FUNCTION`](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17).
