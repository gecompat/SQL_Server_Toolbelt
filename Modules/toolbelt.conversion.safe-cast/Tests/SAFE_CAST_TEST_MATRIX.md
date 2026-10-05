# Safe Cast 1.0.0 – Testmatrix

Die sechs einzeln freigegebenen Inline-TVFs folgen dem
[kanonischen Vertrag](../../../Documentation/Architecture/SAFE_CAST_CONTRACT.md).
Testcode ist kein Ausführungsnachweis. Die begrenzte native Qualifikation auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 besteht jeweils local/
central/Consumer einschließlich Clientmetadaten und 38 Lifecyclefällen.
Frische unabhängige Audits bestätigen die eigene Bereinigung und Inputpins.
Weitere physische Plattform-/CL-Matrix, Minimalrechte und Heap sind `not executed`.

| Artefakt | Fester Prüfscope |
|---|---|
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Contract.Tests.sql` | 182 synthetische feste Fälle; sechs Zieltypen, acht Statuswerte, stabile Codes und typed Value-Oracles; je CROSS/OUTER APPLY, drei Language/DATEFORMAT-Sitzungsformen und vier explizite Inputcollations |
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Metadata.Tests.ps1` | Sechs echte schemagebundene IFs, je zwei Parameter und drei Spalten; Default 8192, tatsächliche Katalogtypen/Längen/Precision/Scale/Collation/Nullability; 18 direkte Reader für OK/SQL_NULL/INVALID_ARGUMENT, genau eine Zeile ohne weiteren Resultset |
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Lifecycle.Tests.sql` | Installierte Baseline: genau sechs markierte Objekte, IF/SCHEMABINDING und Parameter-/Spaltenzahlen |
| `Modules/toolbelt.conversion.safe-cast/Tests/Static/validate_contract.py` | Tatsächliche Source-Signaturen/Inlineform/Header/NoIO, feste Typen, gekoppelte Manifest-/Deploy-/Uninstall-/Dokumentations-/Testartefakte; keine SQLausführung |

Die 182 Fälle enthalten SQL-NULL vor ungültigem Budget, Budget0/−1/NULL/8193,
UTF16-Bytegrenzen, leer/Whitespace, NUL/Surrogate/Nicht-ASCII, native-versus-strikte
Lexik, bigint-Min/Max±1, Decimal20/18-Maximum mit zusätzlicher Null oder Nichtnull,
negative Gegenstücke, Bereich vor SCALE, 4096 führende Nullen bzw. Fractionziffern,
Calendar/Leap/ISO-T/Fraction/Offset, GUID-Braces/Suffix und bit0/1.
Jede erfolgreiche Sessionform umfasst 1456 APPLY-Ergebnisse, insgesamt 4368.
Die festen Value-Oracles konvertieren ausschließlich kurze bekannte gültige
Erwartungswerte zum Zieltyp; native Rundung dient nicht als Klassifikationsoracle.

Collations: `Latin1_General_100_BIN2`, `Latin1_General_100_CI_AS`,
`Latin1_General_100_CS_AS`, `Latin1_General_100_CI_AS_SC_UTF8`.
Sitzungsformen: us_english/mdy, German/dmy, us_english/ymd. Sprache und DATEFORMAT
werden auf erfolgreichem Abschluss auf den Vorzustand zurückgesetzt.
Ein unerwarteter Enginefehler ist FAIL; Fehlerpayloads gehören nicht ins Repository.

SQLfixtures nehmen `ToolbeltDatabase` als SQLCMD-Variable: leer bedeutet aktuelle
DB, gesetzt den expliziten zentralen Provider. Der Clientreader nimmt eine bereits
offene Connection sowie optionale Timeout-/Readbudget-Callbacks. Die Adapter
besitzen Installation, Wiederholung, zentrale Consumer, Caller-/AppLock-/Rollback-/
Fremdslot-/Markerfälle, Confirm und Uninstall; diese Baseline behauptet deren
Ausführung nicht. Cleanup ist ausschließlich über den eigenen Resourcejournal-
Scope und frische Dispositionchecks zu qualifizieren.

Keine Performance-, Parallelitäts-, Heap- oder allgemeine Produktionszusage.
Weitere physische Ziele/CLs/Minimalrechte erst nach dokumentierter Ausführung.

Lokale Vorbereitung 2026-10-05: `python Modules/toolbelt.conversion.safe-cast/Tests/Static/validate_contract.py`
bestand einschließlich des nicht schreibenden kanonischen Generatorchecks;
PowerShell-AST des Clientreaders und diff-Whitespace bestanden.
Anschließend bestanden beide SQLfixtures die unabhängige Offlineprüfung mit
ScriptDom150 und leerem ToolbeltDatabase (je 0 Syntaxfehler). Native Ausführung
ist separat im [Evidenzprotokoll](README.md) nachgewiesen: je 13104 feste API-
Oracles und 54 direkte Clientreader pro finalem Zieladapter. Drei frühere
Gesamtfehlläufe bleiben getrennt fehlgeschlagen; keine gesamte Zielmatrixzusage.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Finales gleiches Source-/Deployment-/Fixture-/Adapterpaar auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 jeweils local/central und mit separatem SC-/UTF8-Consumer bestanden: je 13104 feste API-Oracles, 54 direkte Clientreader, Clean/Repeat, installierte Baseline, 38 gezielte Caller-/Lock-/Rollback-/TypedMarker-/Fremdslot-/Confirm0-Fälle und Uninstall/Repeat. Je Exit0, vollständige Kanäle und leeres Stderr; frische unabhängige Audits bestätigen COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures mit exakter Wiederherstellung und zwei Abweisungen sowie alle Inputpins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap-/Produktionskapazität und exakte Head-CI bleiben getrennt offen; frühere Fehlläufe werden nicht umgewertet.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
