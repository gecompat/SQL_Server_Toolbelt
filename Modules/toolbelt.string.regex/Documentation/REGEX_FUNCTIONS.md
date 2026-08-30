# Regex-Funktionsvertrag

## Gemeinsame Parameter

`@Input nvarchar(max)` und `@Pattern nvarchar(max)` propagieren `NULL`.
`@Flags nvarchar(4)` besitzt den Default `N'c'`. Zulässig ist jede
duplikatfreie Kombination aus `c` oder `i` sowie `m` und `s`; `c` und `i`
schließen einander aus. Ohne `i` ist Matching case-sensitive. `i` verwendet
`RegexOptions.CultureInvariant` und keine Datenbank-Collation.

## `SVF_RegexIsMatch`

Gibt `bit` zurück: 1 bei mindestens einem Treffer, sonst 0. Bei `NULL` in
Input oder Pattern ist das Ergebnis `NULL`.

## `SVF_RegexInstr`

Zusätzliche Parameter sind `@Start int = 1`, `@Occurrence int = 1` und
`@ReturnOption int = 0`. Start und Occurrence beginnen bei 1.
`ReturnOption = 0` liefert den 1-basierten Start, `1` das 1-basierte
Ende-exklusiv. Positionen zählen UTF-16-Codeeinheiten. Ohne Treffer ist das
Ergebnis 0; eine Startposition nach Inputende liefert ebenfalls 0.

## `SVF_RegexCount`

`@Start int = 1` legt die erste zulässige Suchposition fest. Gezählt werden
nicht überlappende Treffer. Nach einem leeren Treffer schreitet die Engine um
eine UTF-16-Codeeinheit fort; am Inputende ist genau ein letzter leerer
Treffer möglich.

## Grammatik

Der Parser erlaubt:

- Literale sowie Escapes für Regex-Metazeichen und `\n`, `\r`, `\t`, `\f`;
- `.`, `^`, `$`, Gruppen mit `(...)` und Alternation `|`;
- Zeichenklassen, Negation und Bereiche;
- `?`, `*`, `+`, `{m}`, `{m,n}` und `{m,}` mit Obergrenze 1.000;
- `\d = [0-9]`, `\s = [\x09-\x0D\x20]`, `\w = [A-Za-z0-9_]`;
- ausschließlich die Unicode-Kategorie `\p{L}`.

Ohne `m` bezeichnet `$` ausschließlich das absolute Inputende. Mit `m`
gelten `^` und `$` zeilenweise. `s` lässt den Punkt auch Newlines matchen.
Gruppen sind semantisch nur für Priorität und Quantifizierung sichtbar;
Captures werden nicht ausgegeben.

## Fehler und Betrieb

Ungültige Pattern, Flags oder Positionsparameter, Größenverletzungen und der
feste 250-ms-Timeout erzeugen SQL-Fehler 6522. Die .NET-Innermeldung beginnt
stabil mit `TBX_REGEX_INVALID_PATTERN`, `TBX_REGEX_INVALID_FLAGS`,
`TBX_REGEX_INVALID_ARGUMENT`, `TBX_REGEX_INPUT_TOO_LARGE`,
`TBX_REGEX_PATTERN_TOO_LARGE` oder `TBX_REGEX_TIMEOUT`.

Die Begrenzung macht eine Backtracking-Engine nicht linear. Regex-Prädikate
sind nicht SARGable; selektive Schlüssel-, Bereichs- oder LIKE-Prädikate
sollten den Kandidatensatz zuerst reduzieren.
