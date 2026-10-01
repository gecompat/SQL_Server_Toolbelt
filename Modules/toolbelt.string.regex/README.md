# toolbelt.string.regex

## Status

Version `1.1.0` ergänzt den am 2026-10-01 ausdrücklich freigegebenen R2a-
Slice mit Substring und literal Replace. R1b-Signaturen bleiben unverändert.
Die erweiterte R1b-/R2a-Matrix wurde am 2026-10-01 auf SQL Server 2019/2022/2025
unter Windows und Linux erfolgreich geprüft, einschließlich Upgrade,
Central-Aufrufen, Vertragsgrenzen und parallelen Large-Aufrufen. Der aktuelle
Stand steht im Manifest; dies ist keine Veröffentlichung.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

## Zweck

Das Modul stellt fünf portable Skalarfunktionen für einen bewusst begrenzten
Toolbelt-Regexdialekt bereit:

- `toolbelt_string.SVF_RegexIsMatch`;
- `toolbelt_string.SVF_RegexInstr`;
- `toolbelt_string.SVF_RegexCount`.
- [toolbelt_string.SVF_RegexReplace](./Documentation/SVF_RegexReplace.md);
- [toolbelt_string.SVF_RegexSubstring](./Documentation/SVF_RegexSubstring.md).

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
Engine-Suchschritt auf 250 ms begrenzt. R2a hat eigene 2-/16-MiB-Profile,
8.000-Codeeinheiten-Pattern und kooperative Gesamtbudgets 500/2.000 ms.
Details stehen im [Funktionsvertrag](./Documentation/REGEX_FUNCTIONS.md).
Ungültige Verträge und Timeouts erscheinen
als SQL-CLR-Fehler 6522 mit einem stabilen `TBX_REGEX_*`-Präfix.

## Aussagegrenzen

Das Modul verspricht weder RE2-Parität noch lineare Laufzeit, SARGability oder
Parallelplanfähigkeit. Backreferences, Lookaround, benannte und bedingte
Gruppen, atomare und Balancing Groups sowie beliebige .NET-Syntax sind
ausgeschlossen. Replace, Substring, Captures, Split und Match-Resultsets sind
nicht Bestandteil von R1b. Bei großen Tabellen sollen selektive relationale
Prädikate vor dem Regex-Aufruf angewendet werden.

R2a verwendet T-SQL-SVF-Fassaden vor internen SAFE-CLR-Kernen, weil direkte
CLR-max-Parameter keine Defaults unterstützen. Zusätzliche Aufrufkosten sind
kein Speedup; keine ScheiniTVF oder Inlining-/Parallelitätszusage. Quelle,
Builder und Ergebnis werden materialisiert. Unicode-Decoding einer varchar-
Quelle geschieht unter ihrer Quell-Collation vor zentraler Nutzung.

Deployment aktiviert CLR nicht, verändert weder `clr strict security` noch
`TRUSTWORTHY` und lädt keine Drittanbieterbibliothek. Der separate
administrative Trust-Schritt autorisiert ausschließlich den exakten
SHA2-512-Hash des reproduzierbar gebauten Releaseartefakts.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: R1b auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest; SAFE CLR, exakter SHA2-512-Trust, Toolbelt-Dialekt, UTF-16, Grenzen, Timeout, Fehlerpräfixe, Erst- und Wiederholungsdeployment, Kollision, Central, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
