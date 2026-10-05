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
Der gekoppelte Generator läuft ausschließlich im nicht schreibenden Checkmodus.
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

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1`
- Scope: Finales gleiches Source-/Deployment-/Fixture-/Adapterpaar auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 jeweils local/central und mit separatem SC-/UTF8-Consumer bestanden: je 13104 feste API-Oracles, 54 direkte Clientreader, Clean/Repeat, installierte Baseline, 38 gezielte Caller-/Lock-/Rollback-/TypedMarker-/Fremdslot-/Confirm0-Fälle und Uninstall/Repeat. Je Exit0, vollständige Kanäle und leeres Stderr; frische unabhängige Audits bestätigen COMPLETE38, drei eigene DBs abwesend, je zwei Marker-/Fremdslotfixtures mit exakter Wiederherstellung und zwei Abweisungen sowie alle Inputpins. Keine Konfigurations-/Rechte-/Truständerungen. Weitere physische Ziele, Minimalrechte, Heap-/Produktionskapazität und exakte Head-CI bleiben getrennt offen; frühere Fehlläufe werden nicht umgewertet.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
