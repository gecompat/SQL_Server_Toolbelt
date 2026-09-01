# Regex-Contract-Testmatrix

| Bereich | Pflichtnachweis |
|---|---|
| CLR | .NET Framework 4.8, nur System/System.Data, SAFE, identischer Provider auf Windows/Linux |
| Dialekt | Literale, Escapes, Punkt, Klassen/Bereiche/Negation, Gruppen, Alternation, Anker, Quantifier bis 1.000 |
| Klassen | ASCII-`\d`/`\s`/`\w`, Unicode-`\p{L}` |
| Flags | `c`, `i`, `m`, `s`, keine Duplikate, kulturinvariantes IgnoreCase |
| IsMatch | Treffer, Nichttreffer und NULL-Propagation |
| Instr | Start, Occurrence, Start-/Ende-exklusiv, 0 ohne Treffer, UTF-16-Positionen |
| Count | nicht überlappend, Startposition und Empty-Match-Fortschritt |
| Abweisung | Backreferences, Lookaround, benannte/atomare/bedingte/Balancing Groups und beliebige .NET-Syntax |
| Grenzen | Input 2 MiB, Pattern 8.000 Bytes, Quantifier 1.000, fester Timeout 250 ms |
| Fehler | SQL 6522 mit stabilem `TBX_REGEX_*`-Präfix |
| Lifecycle | exakter SHA2-512-Trust, Erst-/Wiederholungsdeployment, Kollision, Central, Uninstall, Cleanup |
| Matrix | SQL Server 2019/2022/2025 auf Windows base und Linux latest |

RE2-Parität, lineare Laufzeit, SARGability, Parallelplanfähigkeit, Replace,
Substring, Capture-Ausgabe, Split und Match-Resultsets sind keine R1b-Tests.

Die vollständige Pflichtmatrix wurde am 2026-08-30 über
`local: Tests/CI/run-lab-local.ps1` erfolgreich ausgeführt. Alle Testdaten
waren synthetisch; erzeugte Objekte und neue Trust-Einträge wurden entfernt,
die Lab-Umgebungen nicht beendet.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: R1b auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest; SAFE CLR, exakter SHA2-512-Trust, Toolbelt-Dialekt, UTF-16, Grenzen, Timeout, Fehlerpräfixe, Erst- und Wiederholungsdeployment, Kollision, Central, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
