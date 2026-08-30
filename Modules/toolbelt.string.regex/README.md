# toolbelt.string.regex

## Status

Version `1.0.0` implementiert den am 2026-08-30 ausdrücklich freigegebenen
R1b-Slice. Die vollständige physische Matrix SQL Server 2019, 2022 und 2025
ist unter Windows base und Linux latest erfolgreich. Das Modul ist
`validated`, bleibt aber `unreleased`.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

## Zweck

Das Modul stellt drei portable Skalarfunktionen für einen bewusst begrenzten
Toolbelt-Regexdialekt bereit:

- `toolbelt_string.SVF_RegexIsMatch`;
- `toolbelt_string.SVF_RegexInstr`;
- `toolbelt_string.SVF_RegexCount`.

Ein eigener Parser akzeptiert ausschließlich den dokumentierten Dialekt und
übersetzt ASCII-Kurzklassen kontrolliert für die .NET-Framework-4.8-
Regexengine. Alle Aufrufe verwenden dieselbe `SAFE`-SQL-CLR-Assembly auf SQL
Server 2019, 2022 und 2025 unter Windows und Linux.

## Dialekt und Grenzen

Erlaubt sind Literale und dokumentierte Escapes, `.`, Zeichenklassen mit
Bereichen und Negation, Gruppen, Alternation, `^`, `$`, `?`, `*`, `+`,
`{m,n}` bis 1.000, ASCII-`\d`/`\s`/`\w`, Unicode-`\p{L}` und die Flags
`c`, `i`, `m`, `s`. Case-insensitive Matching ist kulturinvariant.

Input ist auf 2 MiB UTF-16-Daten, Pattern auf 8.000 UTF-16-Bytes und jeder
Aufruf fest auf 250 ms begrenzt. Ungültige Verträge und Timeouts erscheinen
als SQL-CLR-Fehler 6522 mit einem stabilen `TBX_REGEX_*`-Präfix.

## Aussagegrenzen

Das Modul verspricht weder RE2-Parität noch lineare Laufzeit, SARGability oder
Parallelplanfähigkeit. Backreferences, Lookaround, benannte und bedingte
Gruppen, atomare und Balancing Groups sowie beliebige .NET-Syntax sind
ausgeschlossen. Replace, Substring, Captures, Split und Match-Resultsets sind
nicht Bestandteil von R1b. Bei großen Tabellen sollen selektive relationale
Prädikate vor dem Regex-Aufruf angewendet werden.

Deployment aktiviert CLR nicht, verändert weder `clr strict security` noch
`TRUSTWORTHY` und lädt keine Drittanbieterbibliothek. Der separate
administrative Trust-Schritt autorisiert ausschließlich den exakten
SHA2-512-Hash des reproduzierbar gebauten Releaseartefakts.
