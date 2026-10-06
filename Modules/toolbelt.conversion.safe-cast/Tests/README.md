# Safe Cast – Tests

Die [Testmatrix](SAFE_CAST_TEST_MATRIX.md) beschreibt den synthetischen
182-Fälle-API-Vertrag, tatsächliche Clientmetadaten und die installierte
Lifecyclebaseline der sechs einzeln freigegebenen Inline-TVFs.
Die erfolgreiche native Teilqualifikation und ihre Grenzen stehen unten;
Code und Offlineprüfung ersetzen sie nicht.

`Runtime/Contract.Tests.sql` bindet den expliziten SQLCMD-Wert
`ToolbeltDatabase` (leer=currentDB, Name=central), verwendet feste Zieltypen
und führt CROSS/OUTER APPLY in drei Language/DATEFORMAT-Sitzungsformen mit
vier Inputcollations aus. Private `#tbx_SafeCast_`-Temps werden vor der Anlage
auf Kollision geprüft. Surrogatfixtures entstehen aus festen UTF16-Binarybytes.
Ein unerwarteter Enginefehler ist FAIL, keine erfolgreiche Statusrow.

`Runtime/Metadata.Tests.ps1` erhält eine bereits offene SqlConnection,
optional `ToolbeltDatabase`, `CommandTimeoutProvider` und `ReadBudgetProvider`.
Es prüft echte Clientmetadaten und Katalogbindungen für sechs Funktionen;
18 direkte Reader müssen genau eine Row ohne weiteren Resultset liefern.

`Runtime/Lifecycle.Tests.sql` qualifiziert nur die installierte Baseline.
Der eigene CI-Adapter besitzt Setup/Repeat, zentrale Consumer, Confirm,
Caller-/AppLock-/Rollback-/Fremdslot-/Markerfälle und Uninstall/own cleanup.
Ein installierter Marker oder vorhandener Testcode beweist diese Fälle nicht.

Statisch: `python Modules/toolbelt.conversion.safe-cast/Tests/Static/validate_contract.py`.
Der pfadbezogene Dokumentationsworkflow führt diesen Source-/Deploymentvertrag
bei Änderungen am Safe-Cast-Modul ebenfalls aus; das ist kein SQL-Runtime-
oder vollständiger exakter Head-CI-Nachweis.
`Tests/CI/Test-LabDriverArgumentCase.ps1` prüft die Parameterbindung des
Labtreibers mit synthetischen Argumenten ohne Verbindung zum Lab.
Der gekoppelte Generator läuft ausschließlich im nicht schreibenden Checkmodus.
Der [Safe-Cast-Runtime-Workflow](../../../.github/workflows/safe-cast-runtime.yml)
prüft in flüchtigen Linux-SQL-Server-Containern 2019/2022/2025 die zulässigen
Compatibility Levels mit local/central/Consumer: feste API-Fixtures,
Clientmetadaten, installierte Baseline, Repeat und Uninstall.
Der CI-Adapter weist außerdem den zentralen Uninstall ohne explizite
Consumerbestätigung mit `55426/state1` ab und prüft danach die installierte
Baseline erneut, bevor der bestätigte Uninstall ausgeführt wird. Ein
synthetischer View im zentralen Provider belegt zusätzlich eine tatsächliche
`sys.sql_expression_dependencies`-Referenz. Deploy und Uninstall müssen ihn
mit `55425/state3` abweisen; die installierte Baseline und der View bleiben
bis zur kontrollierten Entfernung des Testverbrauchers erhalten. Die gezielten
Caller-/Lock-/Rollback-/Fremdslot-/Markerfälle des separaten Labadapters,
Minimalrechte und Hard-Interrupt-Recovery gehören nicht zu diesem CI-Scope.
Lokale statische Prüfung und Client-AST bestanden am 2026-10-05;
Beide SQLfixtures bestanden anschließend die unabhängige ScriptDom150-
Offlineprüfung (je 0 Syntaxfehler, leerer ToolbeltDatabase). Native Ausführung
war in diesem Vorbereitungsstand offen; die späteren Läufe stehen unten.

Der erste begrenzte lokale Lauf am 2026-10-05 auf SQL Server 2019 Linux/latest
CL150 scheiterte beim lokalen Deploy mit SQL1054/state6: Projektionswildcards
in den CTEs sind bei SCHEMABINDING unzulässig. Kein API- oder Lifecyclefall
wurde dadurch qualifiziert. Der Lauf endete `FAILED_CLEANED`; eine unabhängige
neue Verbindung bestätigte die Abwesenheit der einzigen eigenen Testdatenbank
und die unveränderten eingefrorenen Inputs. Keine Konfigurations-, Rechte-
oder Truständerungen. Vollständige Kanäle und eigene Journale bleiben privat.
Die Korrektur ersetzt die Wildcards durch explizite Spaltenlisten und ergänzt
den statischen Vertrag um deren Verbot; erfolgreiche Wiederholung ist separat
nachzuweisen.

Der korrigierte zweite Lauf bestand Deploy und Repeat, scheiterte aber im
API-Fixture mit SQL102/state1 an einem geklammerten COLLATE-Namen im dynamischen
Test-SQL. Eine separate reine SELECT-Probe reproduzierte diesen Syntaxfehler.
Die feste interne Vierer-Allowlist wird deshalb ohne Identifierklammern
eingesetzt; der öffentliche Funktionsvertrag bleibt unverändert. Auch dieser
Lauf endete `FAILED_CLEANED`, mit unabhängig frisch bestätigter Abwesenheit
seiner einzigen eigenen Datenbank und vollständig geprüften Inputpins.
Kein vollständiger API-, Client- oder Lifecycle-PASS aus diesem Lauf.

Der dritte Lauf bestand lokal die 4368 festen API-Oracles, installierte
Lifecyclebaseline, Clientmetadaten und 16 gezielte Caller-/Lock-/Rollback-/
Markerfälle einschließlich exakter Markerwiederherstellung. Nach dem echten
Uninstall scheiterte die Vorbereitung des Fremdslotfalls an
`SAFE_CAST_COMPLETE_SNAPSHOT_INVALID`. Er endete `FAILED_CLEANED` mit
Bereinigung im Lauf; der unabhängige neue Audit bestätigte die Abwesenheit
der einzigen eigenen Datenbank, alle Inputpins und unveränderte Nullscopes
für Konfiguration, Rechte und Trust. Eine reine synthetische SELECT-Probe
zeigte: scalar FOR JSON bei leerer Liste und dessen Hash sind NULL; explizites
`N'[]'` erhält einen vollständigen Hash. Der Adapter normalisiert seine drei
obersten Metadatenlisten entsprechend, ohne Vergleichsfelder zu entfernen.
Kein Gesamt-PASS, kein zentraler oder Windows-Nachweis aus diesem Teillauf.

Der vierte Gesamtadapter bestand am 2026-10-05 auf SQL Server 2019 Linux/latest
CL150, jeweils local und central sowie mit separatem zentralem SC-/UTF8-Consumer.
Drei Ausführungen des API-Fixtures ergeben13104 feste APPLY-Oracles;
Clientmetadaten umfassen54 direkte Reader. Clean/Repeat, installierte Baseline,
Uninstall/Repeat und 38 konkrete Lifecyclefälle bestanden: Callerzustände,
AppLock, vier Rollbackinjektionen je Modus, typisierte Marker, Fremdslots
und zentrale Confirm0-Abweisung. Jede Marker-/Fremdslotfixture wurde exakt
wiederhergestellt. Tatsächlicher Exit0, vollständige Kanäle und leeres Stderr.
Der unabhängige neue Audit bestätigte COMPLETE, alle eingefrorenen Inputs,
zwei Marker- und zwei Fremdslotfixtures mit je zwei Abweisungen und erfolgter
Wiederherstellung sowie die Abwesenheit aller drei eigenen Datenbanken.
Keine Konfigurations-, Rechte- oder Truständerungen. Weitere physische Ziele,
Minimalrechte und Heap-/Produktionskapazität bleiben `not executed`;
Windows und exakte Head-CI sind getrennte Nachweise. Die drei früheren
Gesamtfehlläufe bleiben fehlgeschlagen.

Der anschließende Windows-Gesamtadapter bestand mit demselben finalen Produkt-,
Fixture- und Adapterstand auf SQL Server 2025/exaktCU8 CL170. Derselbe local/
central/Consumer-Scope mit 13104 festen API-Oracles,54 direkten Clientreadern
und 38 Lifecyclefällen; Exit0, vollständige Kanäle und leeres Stderr.
Der unabhängige neue Audit bestätigte COMPLETE38, drei eigene Datenbanken
abwesend, alle Inputpins und je zwei exakt wiederhergestellte Marker- und
Fremdslotfixtures mit je zwei Abweisungen. Keine Konfigurations-, Rechte-
oder Truständerungen. Beide begrenzten Zielnachweise ergeben `partially validated`,
`unreleased`; übrige physische Ziel-/CL-Matrix, tatsächliche Minimalrechte,
Heap und exakte Head-CI bleiben separate Nachweise.

Am 2026-10-06 bestanden auf demselben zuvor ausgewählten, schema-validierten
Windows2025/exaktCU8-Ziel auch CL150 und CL160 mit dem vollständigen local/
central/Consumer-Scope. Je 13104 feste API-Oracles, 54 direkte Clientreader,
38 Lifecyclefälle und Uninstall/Repeat; tatsächlicher Exit0, vollständige
Kanäle und leeres Stderr. Zwei frische unabhängige Audits bestätigten je
COMPLETE38, drei eigene Datenbanken abwesend, je zwei Marker- und
Fremdslotfixtures exakt wiederhergestellt mit je zwei Abweisungen sowie
unveränderte Input- und sechs Sourcepins. Keine Konfigurations-, Rechte- oder
Truständerungen. Die frühere CL170- und Linux-Evidenz bleiben eigenständige
Nachweise; weitere physische Ziele, Minimalrechte, Heap und vollständige
Runtime-Head-CI sind weiterhin offen.

Der begrenzte Modulworkflow bestand am 2026-10-06 am exakten
[PR186-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/186):
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402202963)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402203046)
waren erfolgreich, einschließlich aller drei Linux-Jobs 2019/2022/2025.
Nach Merge bestanden auf `main` erneut
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837670)
und [Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837558).
Die 38 gezielten Lifecyclefälle des Labadapters sind nicht Teil dieser CI.
Weitere physische Ziele, tatsächliche Minimalrechte, Hard-Interrupt-Recovery,
Heap und Releasequalifikation bleiben offen; `partially validated`,
`unreleased`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-06`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Auf demselben bereits ausgewählten schema-validierten Windows2025/exaktCU8-Ziel bestanden zusätzlich CL150 und CL160 mit jeweils vollständigem local/central/Consumer-Adapter: je 13104 feste API-Oracles, 54 direkte Clientreader und 38 Lifecyclefälle. Je Exit0, vollständige Kanäle und leeres Stderr. Frische unabhängige Audits bestätigten COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures exakt restauriert mit zwei Abweisungen sowie unveränderte Input- und sechs Sourcepins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap und vollständige Runtime-Head-CI bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
