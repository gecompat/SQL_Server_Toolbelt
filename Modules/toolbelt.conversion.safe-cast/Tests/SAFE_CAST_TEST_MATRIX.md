# Safe Cast 1.0.0 – Testmatrix

Die sechs einzeln freigegebenen Inline-TVFs folgen dem
[kanonischen Vertrag](../../../Documentation/Architecture/SAFE_CAST_CONTRACT.md).
Testcode ist kein Ausführungsnachweis. Die begrenzte native Qualifikation auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 besteht jeweils local/
central/Consumer einschließlich Clientmetadaten und 38 Lifecyclefällen.
Frische unabhängige Audits bestätigen die eigene Bereinigung und Inputpins.
Weitere physische Plattform-/CL-Matrix, Minimalrechte und Heap sind `not executed`.
Am 2026-10-06 bestanden auf demselben ausgewählten Windows2025/exaktCU8-Ziel
zusätzlich CL150 und CL160 den vollständigen local/central/Consumer-Adapter.
Je 13104 feste API-Oracles, 54 Clientreader und 38 Lifecyclefälle wurden
ausgeführt; frische unabhängige Audits bestätigten eigene Bereinigung,
Fixturewiederherstellung und unveränderte Input-/Sourcepins. Andere physische
Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI bleiben offen.

| Artefakt | Fester Prüfscope |
|---|---|
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Contract.Tests.sql` | 182 synthetische feste Fälle; sechs Zieltypen, acht Statuswerte, stabile Codes und typed Value-Oracles; je CROSS/OUTER APPLY, drei Language/DATEFORMAT-Sitzungsformen und vier explizite Inputcollations |
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Metadata.Tests.ps1` | Sechs echte schemagebundene IFs, je zwei Parameter und drei Spalten; Default 8192, tatsächliche Katalogtypen/Längen/Precision/Scale/Collation/Nullability; 18 direkte Reader für OK/SQL_NULL/INVALID_ARGUMENT, genau eine Zeile ohne weiteren Resultset |
| `Modules/toolbelt.conversion.safe-cast/Tests/Runtime/Lifecycle.Tests.sql` | Installierte Baseline: genau sechs markierte Objekte, IF/SCHEMABINDING und Parameter-/Spaltenzahlen |
| `Modules/toolbelt.conversion.safe-cast/Tests/CI/Test-SafeCastLifecycle.ps1` | CI-Adapter der unveränderten kanonischen Helper: 18 local-/20 central-Fälle pro CL; gleicher Callerzustand, AppLock, Rollback, typisierte Marker, Fremdslot, Confirm0; gepinnte eigene DB-Identität, privates Restorejournal, bestätigter Uninstall/Repeat und frische Abwesenheitsprüfung |
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

Stand 2026-10-07: Der CI-Adapter ersetzt seine überlappenden zentralen
Teilprüfungen durch die vollständigen 38 kanonischen Lifecyclefälle pro CL.
Die historischen CI-Nachweise unten behalten ihren ursprünglichen Scope;
der erweiterte Runtime-Nachweis ist separat am exakten PR-Head zu prüfen.
Das Modul bleibt `partially validated` und `unreleased`.

### Offene Minimalrechte-Qualifikation

Für die sechs TVF-Aufrufe ist vorhandenes `SELECT` nötig. Der Lifecycle-
Preflight prüft datenbankweites `VIEW DEFINITION`, `SELECT` auf
`sys.sql_expression_dependencies`, `CREATE FUNCTION` sowie `ALTER` auf dem
vorhandenen Schema oder `CREATE SCHEMA` für ein neues Schema. `MarkRelease.sql`
schreibt zusätzlich zwei Extended Properties **auf Datenbankebene**;
`Uninstall.sql` entfernt sie. Laut Microsoft brauchen diese Operationen eigene
wirksame Rechte; `db_ddladmin` allein darf keine datenbankweite Property
hinzufügen. Primärquellen:
[`sp_addextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql),
[`sp_updateextendedproperty`](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-updateextendedproperty-transact-sql),
[`sys.sql_expression_dependencies`](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql).
Die Unvollständigkeit der bisherigen Schema-/Funktionsrechtebeschreibung
ist eine Schlussfolgerung aus Quellen und Skript; die exakte kleinste
erfolgreiche Rechtemenge ist **nicht** nativ belegt.

Ein späterer Versuch benötigt einen bereits vorhandenen, ausdrücklich
ausgewählten Testprincipal auf einem erlaubten Ziel. Effektive Rechte und
Vorzustand werden privat erhoben; ohne geeigneten Principal bleibt der Test
**NOT_EXECUTED**. Aufruf, Erstinstallation mit vorhandenem/neuem Schema,
Repeat sowie lokaler/zentraler Uninstall einschließlich Markerbereinigung
sind getrennt zu prüfen, Fehler mit Rollback- und Own-State-Audit. Der
bisherige physische Labadapter benötigt für die eigene DB-Bereinigung
`sysadmin`; sein Erfolg ist kein Minimalrechtebeweis. Hier werden keine
Rechte erteilt, Principals angelegt oder SQL-Objekte verändert.

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
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Auf demselben bereits ausgewählten schema-validierten Windows2025/exaktCU8-Ziel bestanden zusätzlich CL150 und CL160 mit jeweils vollständigem local/central/Consumer-Adapter: je 13104 feste API-Oracles, 54 direkte Clientreader und 38 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeres Stderr. Frische unabhängige Audits bestätigten COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures exakt restauriert mit zwei Abweisungen sowie unveränderte Input- und sechs Sourcepins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
