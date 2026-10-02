# Regex-Funktionsvertrag

Zusätzlicher Capturemodus ab 1.3.0:
[TVF_RegexCaptures](TVF_RegexCaptures.md) und
[SVF_RegexReplaceGroups](SVF_RegexReplaceGroups.md). Diese zwei separat
freigegebenen APIs erlauben normale und benannte Captures, sämtliche
Wiederholungen beziehungsweise strikt gebundene Gruppenreferenzen.
Die folgenden bisherigen R1b-/R2a-/R2b-Verträge bleiben unverändert.

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

## R2a-Transformationsvertrag

[Replace](./SVF_RegexReplace.md) und [Substring](./SVF_RegexSubstring.md)
verwenden denselben Dialekt, kulturinvariante Flags und UTF-16-Positionen.
Ihre max-Flags werden vor Gebrauch auf vier Codeeinheiten geprüft, Profil
akzeptiert exakt die ASCII-Werte `standard` oder `large`. Andere Schreibweise,
Trailing Spaces und NULL werden zurückgewiesen; der Input-NULL-Kurzschluss
hat Vorrang. R1b bleibt bei seinen bisherigen Signaturen und Größenlimits.

| Ressource | standard | large, ausdrücklich gewählt |
|---|---|---|
| Quelle/Ersatz/Output je | 2 MiB UTF-16 | 16 MiB UTF-16 |
| Pattern | 8.000 UTF-16-Codeeinheiten | identisch |
| Kooperatives Gesamtbudget | 500 ms | 2.000 ms |
| Engine-Suchschritt | höchstens 250 ms | höchstens 250 ms |

Gesamtbudget umfasst Parser, Konstruktor, Suche, Enumeration und Outputbau.
Wenn die gebundene Enginegrenze nicht mehr ins Restbudget passt, wird eine
Regexinstanz mit höchstens der Hälfte des Restbudgets konstruiert und bis zur
nächsten nötigen Verkleinerung wiederverwendet; dabei parst .NET das bereits
übersetzte Pattern erneut. Prüfung vor/nach Konstruktion und jedem Such-/Append-
Schritt. Kein NextMatch mit unbegrenzter Gesamtenumeration. Nicht
unterbrechbarer Konstruktor, GC, Allokation und SQL-Scheduling begründen
keine harte Wall-Clock-Garantie. Die Deadline begrenzt auch viele billige
Treffer; kein Teilergebnis bei Überschreitung.

R2a begrenzt zusätzlich Gruppenverschachtelung auf 64 und Alternationszeichen
außerhalb von Klassen/Escapes auf 1.024, übersetzte Pattern auf 64.000
Codeeinheiten. Numerische Quantifier behalten die R1b-Grenze 1.000.
Diese Sicherheitsgrenzen garantieren keine lineare Laufzeit. Pattern zählen
UTF-16-Codeeinheiten, keine Grapheme oder Unicode-Skalarwerte. Ergebnisgröße
wird vor jedem Append geprüft. `max` ist kein Versprechen bis 2 GB.

Zusätzliche Präfixe: `TBX_REGEX_REPLACEMENT_TOO_LARGE`,
`TBX_REGEX_OUTPUT_TOO_LARGE`, `TBX_REGEX_PATTERN_TOO_COMPLEX`. Input-/Pattern-,
Flags-/Parameter- und Timeoutpräfixe bleiben stabil.

`varchar` mit klassischer oder UTF-8-Codepage wird beim Caller unter seiner
Quell-Collation ausdrücklich nach `nvarchar(max)` konvertiert, bevor eine
zentrale Datenbank aufgerufen wird. Unicode-Output wird nicht still in eine
andere Codepage zurückkonvertiert. Varchar-Wrapper und bounded/max-
Performancevarianten sind ohne Verlustfreiheitsvertrag und Messnutzen nicht
Teil von R2a. Quelle/Builder/Ergebnis werden materialisiert; LOB-Parallelität,
Streaming und Native-RE2-Parität sind nicht zugesagt.

SQL Server weist Defaultwerte auf CLR-max-Parametern mit Fehler 1096 zurück.
Die öffentlichen R2a-SVFs sind daher T-SQL-Fassaden mit max-Defaults vor zwei
intern markierten CLR-Kernen ohne Defaults. Diese Struktur bewahrt die
ungekürzte Validierung und fügt Aufrufkosten hinzu; Inlining und Parallelität
werden nicht zugesagt. SELECT-Aufrufe verwenden explizite DEFAULT-Platzhalter;
EXEC erlaubt das Weglassen von Defaultparametern. Die internen Kerne sind
keine weitere öffentliche API und werden mit dem Modul installiert/entfernt.
