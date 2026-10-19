# JSON Pointer 1.0.0 – Nachqualifikation vom 2026-10-19

Alle zwölf vollständigen Adapter sind erfolgreich. Frische rein lesende
Kontrollverbindungen bestätigen Inputbindung, Fixturewiederherstellung und
die Abwesenheit aller eigenen Testdatenbanken.

Die ausdrückliche Fortsetzung beauftragt genau eine endliche Pointer-Welle
nach vollständig grüner Main-Integration von PR333. Alle 34 Push-Workflows
des Mergecommits `bea86dd361c7e27f7ae66bd12ac02ddb4c22c44e` waren zuvor
erfolgreich. Diese Basis enthält die freigegebene SC-006-Härtung; Produkt-,
Deployment-, Runtime-Fixture- und Labadapterquellen bleiben unverändert.
Version 1.0.0 bleibt `partially validated` und `unreleased`.

## Tatsächlich ausgeführte Matrix

`Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full` verwendet jeweils
local, central und einen separaten zentralen SC-/UTF8-Consumer. Linux-Auswahl:
`latest`; Windows-Auswahl: `base` einschließlich der ausdrücklich freigegebenen
CU-Äquivalente. Nur schema-validierte, tatsächlich bereite Einzelziele gemäß
AGENTS-Regeln; kein Ziel-/Providerfallback.

| SQL Server | Linux | Windows |
|---|---|---|
| 2019 | CL150 bestanden | CL150 bestanden |
| 2022 | CL150/160 bestanden | CL150/160 bestanden |
| 2025 | CL150/160/170 bestanden | CL150/160/170 bestanden |

Je abgeschlossenem Adapter bestanden 3072 feste Contract-/Safety-APPLY-Oracles,
15 direkte Clientreader und 42 Lifecyclefälle (20 local, 22 central). Alle
zwölf Prozesse endeten mit Exit0, vollständigen Ausgabekanälen und leerem
Stderr. Insgesamt: 36864 APPLY-Oracles, 180 Clientreader und 504 Lifecyclefälle.

54 Contract- und 74 Safetyfälle werden unter vier Inputcollations jeweils
mit CROSS/OUTER APPLY in drei Kontexten ausgewertet. Status, Typ, Wert und
Fehlerpriorität besitzen feste synthetische Erwartungen. Direkte ADO.NET-
Reader prüfen Parameter, Defaults, Typen, Nullability, genau eine Zeile und
das Fehlen weiterer Resultsets. Lifecycle umfasst Erstinstallation/Repeat,
Caller-TX intakt/doomed mit XACT_ABORT OFF/ON, AppLock, post-DROP/pre-COMMIT-
Rollback, typisierte Marker, Fremdslots, echte Dependencies, Confirm0 sowie
Uninstall/Repeat. Frühere Fehlläufe behalten ihren historischen Status.

## Bindung und Bereinigung

Vor Mutationen wurden zwölf ausgewählte Adapter, alle relevanten Inputs und
das gemeinsame Budget eingefroren: ein Paket/ein PR/ein Verantwortlicher,
jeder ausgewählte Adapter einmal, keine automatischen Retries. Ein eigener
äußerer Prozesswatchdog begrenzt jeden Adapter auf 400 Sekunden; intern gelten
300 Sekunden Arbeit und 360 Sekunden einschließlich eigener Bereinigung.
Zwischen den Läufen und vor dem Evidenznachtrag wurden sämtliche Pins geprüft.

Der vorhandene Adapter bindet eigene synthetische Datenbanken an Owner,
DB-ID und CreateDate. Zwölf zusätzliche unabhängige read-only Verbindungen
bestätigten tatsächliche Serverversion und Plattform sowie alle 36 eigenen
Datenbanken abwesend. Die frisch gelesenen Abschlussjournale bestätigten
COMPLETE/42, beide Modi und je zwei Marker-, Fremdslot- und Dependencyfixtures
mit exakter Wiederherstellung und je zwei erwarteten Abweisungen. Die
Compare-and-restore-Oracles selbst liefen im nativen Adapter vor dem Drop.
Keine Konfigurations-, Rechte-, Trust- oder Lab-Infrastrukturänderungen.
Private Journale, Rohkanäle, Pins, Endpunkte und Messwerte bleiben außerhalb Git.

Die Kontrollen erfolgten vor dem nachträglichen Manifest-/Evidenzeintrag.
Dieser ändert Dokumentationsregistrierung und datierte Nachweise, keine
Produkt- oder Testsemantik. Die bereits vor dem Freeze nachgeführte
Vertragsdokumentation beschreibt das seit SC-006 genehmigte 64-MiB-Parserbudget;
sie erteilt keine neue Funktionsfreigabe.

Alle Verbindungen verwenden `TestPurpose=Functional`, Encrypt=True und den
expliziten booleschen Trustwert des Labvertrags. Keine Trustumschaltung nach
Fehlern. Authentifizierte TLS-Abnahme bleibt separat `not executed`.

## Reproduktion

Aus dem Repositoryroot mit PowerShell 7, nach Lesen des exportierten Labprompts
und Schema-/Zielprüfung, beispielsweise ein einzelner vollständiger Adapter:

```powershell
$journalManifest = Join-Path ([IO.Path]::GetTempPath()) ('Pointer-' + [guid]::NewGuid().ToString('N') + '.txt')
[IO.File]::WriteAllText($journalManifest, '')
$driver = Join-Path (Get-Location) 'Tests/CI/run-json-pointer-lab.ps1'
$promptHash = (Get-FileHash -LiteralPath $env:SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE -Algorithm SHA256).Hash
$driverHash = (Get-FileHash -LiteralPath $driver -Algorithm SHA256).Hash
pwsh -NoProfile -File $driver -Platform linux -Version 2022 -Patch latest -CompatibilityLevel 160 `
    -QualificationScope full -JournalManifestPath $journalManifest `
    -ExpectedPromptSHA256 $promptHash -ExpectedDriverSHA256 $driverHash
if ($LASTEXITCODE -ne 0) { throw 'Pointer-Qualifikation fehlgeschlagen.' }
```

Der Adapter prüft standardmäßig beide Deploymentmodi und den Consumer.
Weitere Einträge explizit nach Plattform, Version, Patch und CL auswählen;
Windows verwendet `-Patch base`. Der äußere 400-Sekunden-Watchdog und die
frischen read-only Pin-/Fixture-/Own-State-Kontrollen gehören zusätzlich zum
ausgeführten Qualifikationsverfahren. Der einzelne obige Aufruf enthält noch
keinen äußeren Watchdog oder unabhängigen Abschlussaudit. Ein Timeout ist kein
PASS; unbekannter Cleanup muss vor weiteren abhängigen Mutationen geklärt sein.

## Verbleibende Grenzen

| Gate | Stand und Voraussetzung |
|---|---|
| Tatsächliche Minimalrechte | `not executed`: benötigt vorhandenen, ausdrücklich ausgewählten Principal mit getrennt prüfbaren Aufruf-, Schema-/Funktions- und datenbankweiten Markerrechten. Sysadmin-Lifecycle ist kein Minimalrechtebeweis. |
| Last, Heap und Parallelität | Keine neue Last- oder Kapazitätsqualifikation. Historische Lastfälle behalten Originaldatum und Bindung; ihre Anwendbarkeit auf SC-006 ist hier nicht nachgewiesen. |
| SC-006-Grenzfälle | Der aktuelle Produktstand ist gebunden. `Security.Contract.sql` ist kein Bestandteil des unveränderten physischen full-Adapters; dieser Bericht behauptet dafür keinen physischen Grenztest. Die Linux-Runtime-CI führt die Securityfixture separat aus. |
| Harter Runner-/Hostausfall | `not executed`: reguläre Deadlines und erfolgreicher Cleanup ersetzen keinen Ausfall-/Recoverybeweis. Kein SQL-Dienst oder Labhost wurde beendet. |
| Authentifizierte TLS-Abnahme | Separater Transportnachweis; blockiert unabhängige Pointer-Fachtests nicht. |
| Head-/Integrations-CI und Veröffentlichung | Separat am exakten PR-/Mergecommit nachzuweisen; keine Veröffentlichung autorisiert. |

## Prüfaufwand

Seit den historischen vollständigen Labnachweisen änderten sich insbesondere
Produktquelle/Deployment (freigegebenes SC-006-Parserbudget), Argumentbindung
und gemeinsamer Connection-/Trusthelper. Diese alten Läufe ersetzen daher
keinen aktuellen Matrixnachweis. Jeder der zwölf ausgewählten Adapter wurde
einmal ausgeführt; keine neuen Runtime-Workflows, Agenten oder Testreplays.
Kosten- und Tokenverbrauch bleiben `UNKNOWN`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-json-pointer-lab.ps1 -QualificationScope full`
- Scope: Aktuelle physische Windows-/Linux-Matrix SQL2019 CL150, SQL2022 CL150/160, SQL2025 CL150/160/170: zwölf vollständige local/central/Consumer-Adapter erfolgreich, je 3072 feste Contract-/Safety-APPLY-Oracles, 15 direkte Clientreader und 42 Lifecyclefälle. Alle Exit0, vollständige Kanäle, leeres Stderr. Zwölf frische read-only Kontrollverbindungen bestätigten tatsächliche Version/Plattform, unveränderte Input-/Sourcepins vor dem Evidenznachtrag, je zwei exakt restaurierte Marker-/Fremdslot-/Dependencyfixtures mit je zwei Abweisungen und alle 36 eigenen DBs abwesend. Keine Konfigurations-/Rechte-/Truständerungen. Functional mit erforderlicher Verschlüsselung und explizitem Lab-Trustwert; authentifizierte TLS-Abnahme separat. Aktueller Source einschließlich freigegebener SC-006-Härtung gebunden; deren separate Security.Contract.sql gehört nicht zum physischen full-Adapter. Keine neue Last-, Minimalrechte-, Heap-/Parallel-, Host-Recovery- oder Releasequalifikation; aktuelle Head-CI separat. Weiterhin teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
