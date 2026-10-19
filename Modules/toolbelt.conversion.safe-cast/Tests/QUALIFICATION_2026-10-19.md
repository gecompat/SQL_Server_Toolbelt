# Safe Cast 1.0.0 – Nachqualifikation vom 2026-10-19

Alle zwölf vollständigen Adapter sind erfolgreich. Frische rein lesende
Kontrollverbindungen bestätigen Inputbindung, Fixturewiederherstellung und
die Abwesenheit aller eigenen Testdatenbanken.

Der Benutzer beauftragte nach der getrennten Statusbereinigung die autonom
ausführbaren Safe-Cast-Labfälle und einen eigenen PR. Produktbasis ist
`fd05c333e882cb10610636257392e47e99580967`. Die sechs SQL-Quellen sowie alle
Deployment-, Runtime-Fixture- und Labadapterquellen bleiben unverändert.
Version 1.0.0 bleibt `partially validated` und `unreleased`.

## Tatsächlich ausgeführte Matrix

Der vorhandene Adapter `Tests/CI/run-safe-cast-lab.ps1` verwendet jeweils
local, central und einen separaten zentralen SC-/UTF8-Consumer. Linux-Auswahl:
`latest`; Windows-Auswahl: `base` einschließlich der ausdrücklich freigegebenen
CU-Äquivalente. Ausschließlich schema-validierte READY-Ziele, kein Fallback.

| SQL Server | Linux | Windows |
|---|---|---|
| 2019 | CL150 bestanden | CL150 bestanden |
| 2022 | CL150/160 bestanden | CL150/160 bestanden |
| 2025 | CL150/160/170 bestanden | CL150/160/170 bestanden |

Je abgeschlossenem Adapter bestanden 13104 feste APPLY-Oracles, 54 direkte
Clientreader und 38 Lifecyclefälle (18 local, 20 central). Alle zwölf
Prozesse endeten mit Exit0, vollständigen Ausgabekanälen und leerem Stderr.
Insgesamt sind 157248 APPLY-Oracles, 648 direkte Clientreader und
456 Lifecyclefälle erfolgreich.

Die unveränderten Orakel prüfen sechs schemagebundene Inline-TVFs, Parameter,
Defaults, typgenaue Value-/Status-/ErrorCode-Ausgaben, Nullability, Collations
und genau eine Zeile ohne weiteren Resultset. Dazu kommen feste Sprach-/
DATEFORMAT-/Inputcollations, Grenzen und Verlustfreiheit. Clean/Repeat,
Caller-TX mit XACT_ABORT OFF/ON und intaktem/doomed Zustand, AppLock,
post-DROP/pre-COMMIT-Rollback, typisierte Marker, Fremdslots, Confirm0 und
Uninstall/Repeat sind enthalten. Frühere Fehlläufe behalten ihren damaligen
Status und werden nicht in diesen PASS umetikettiert.

## Aktueller Metadatenhelper und Setupfehler

Die am 2026-10-09 als SOURCE_ONLY dokumentierte Command-Ownership-Wartung
wurde im normalen nativen Metadatenpfad der abgeschlossenen Läufe ausgeführt.
Zusätzlich bestand unter Windows/PowerShell 7:

```powershell
pwsh -NoProfile -File Modules/toolbelt.conversion.safe-cast/Tests/Framework/Test-CommandSetup.ps1
```

Der Test extrahiert genau den unveränderten `New-SafeCastCommand`-Helper aus
der kanonischen Quelle. Ein werfender Timeoutprovider und ein ungültiger
Timeout lösen zwei echte SqlCommand-Setupfehler aus; unabhängige
Disposed-Events bestätigen jeweils genau eine Commandfreigabe und keine
Freigabe der fremden Connection. Keine Verbindung wird geöffnet, kein SQL
wird ausgeführt. Die zwei Setupzweige sind belegt; beliebige weitere
Fehlerpfade, Heap- oder Leak-Benchmarks werden nicht behauptet.

## Bindung und Bereinigung

Der Adapter validiert Schema und Auswahl vor der Anmeldung. Eingaben,
Produkt-/Deployment-/Fixture-/Helperquellen und der gelesene Labprompt sind
vor/nach jedem Lauf hashgebunden. Der eigene Restoreumfang wird ausschließlich
privat journalisiert, Datenbanken werden über Owner, ID und CreateDate gebunden.

Zwölf frische rein lesende Kontrollverbindungen bestätigten tatsächliche
Serverversion und Plattform, alle eingefrorenen Inputs, je zwei exakt
wiederhergestellte Marker- und Fremdslotfixtures sowie die Abwesenheit aller
36 eigenen Testdatenbanken auf Linux und Windows. Keine Konfigurations-, Rechte- oder
Truständerungen. Ein Parameterbindungsfehler des lokalen read-only Auswerters wurde vor
der erfolgreichen Kontrollausführung korrigiert; kein nativer Produktfehler
und kein deshalb wiederholter Adapter. Private Journale, Rohkanäle, reale
Serverdetails und Messwerte bleiben außerhalb des Repositorys.

Die Kontrollen erfolgten vor dem nachträglichen Dokumentations-/Evidenzeintrag
im Manifest. Dieser ändert nur Test-/Dokumentationsregistrierung und datierte
Nachweise. Öffentlicher Vertrag, Produktquellen, Deployments, Runtime-Fixtures
und Labadapter bleiben identisch; aus dem Metadatennachtrag wird keine neue
Runtimeausführung abgeleitet.

Alle Verbindungen verwenden `TestPurpose=Functional`, erforderliche
Verschlüsselung und den expliziten booleschen Trustwert des Labvertrags.
Keine Trustumschaltung nach Fehlern. Authentifizierte TLS-Abnahme bleibt
separat `not executed` und ist keine Safe-Cast-Voraussetzung.

## Reproduktion

Aus dem Repositoryroot in PowerShell 7, nach Lesen des exportierten Labprompts
und mit den schema-validierten Labvariablen, beispielsweise ein einzelner Lauf:

```powershell
$journalManifest = Join-Path ([IO.Path]::GetTempPath()) ('SafeCast-' + [guid]::NewGuid().ToString('N') + '.txt')
[IO.File]::WriteAllText($journalManifest, '')
$driver = Join-Path (Get-Location) 'Tests/CI/run-safe-cast-lab.ps1'
$promptHash = (Get-FileHash -LiteralPath $env:SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE -Algorithm SHA256).Hash
$driverHash = (Get-FileHash -LiteralPath $driver -Algorithm SHA256).Hash
pwsh -NoProfile -File $driver -Platform linux -Version 2022 -Patch latest -CompatibilityLevel 160 `
    -JournalManifestPath $journalManifest -ExpectedPromptSHA256 $promptHash `
    -ExpectedDriverSHA256 $driverHash
if ($LASTEXITCODE -ne 0) { throw 'Safe-Cast-Qualifikation fehlgeschlagen.' }
```

Der Standard des Adapters prüft beide Deploymentmodi. Andere Matrixeinträge
explizit nach Plattform, Version, Patch und CL auswählen;
Windows verwendet `-Patch base`. Der ausgeführte äußere Prozesswatchdog
begrenzt jeden einzelnen Adapter auf 400 Sekunden. Der Adapter hält 300
Sekunden Arbeitszeit und insgesamt 360 Sekunden einschließlich Restore ein.
Ein Timeout ist kein PASS. Nach ungeklärtem Abbruch sind privates Journal und
frischer Own-State-Audit vor neuen abhängigen Testverbrauchern erforderlich.

## Verbleibende Grenzen

| Gate | Stand und Voraussetzung |
|---|---|
| Tatsächliche Minimalrechte | `not executed`: benötigt einen vorhandenen, ausdrücklich ausgewählten Testprincipal mit getrennt prüfbaren Aufruf-, Schema-/Funktions- und datenbankweiten Markerrechten. Der sysadmin-Adapter ist kein Minimalrechtebeweis. Keine Principals oder Grants angelegt. |
| Heap, Parallelität und Produktionskapazität | `not executed`: benötigt eigenen Workload, Ressourcenbudget und Abnahmescope. Die optionalen Zeitmessungen für ResultTable/Base64/Series werden nicht auf Safe Cast übertragen. |
| Harter Runner-/Hostausfall | `not executed`: reguläre Deadlines und erfolgreicher Own-Cleanup beweisen keine Wiederherstellung nach hartem Ausfall. Kein Labhost oder SQL-Dienst wurde beendet. |
| Authentifizierte TLS-Abnahme | Separater Transportnachweis; blockiert unabhängige Safe-Cast-Fachtests nicht. |
| Head-/Integrations-CI und Veröffentlichung | PR-CI ist separat am exakten Head nachzuweisen; keine Veröffentlichung autorisiert. |

## Prüfaufwand

Ein Qualifikationspaket, ein PR und ein Verantwortlicher. Die aktuelle Matrix
bindet insbesondere den seit den frühen Nachweisen gewarteten Metadatenhelper;
historische grüne Läufe werden nicht als aktuelle Ausführung ausgegeben.
Jeder Ziel-/CL-Adapter läuft einmal, ohne neue Runtime-Workflows, Agenten oder
erneute fremde Modulmatrizen. Die Setupfehlerproben benötigen keine zusätzlichen
SQL-Sitzungen. Unbekannter Token-/Kostenverbrauch bleibt unbekannt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-safe-cast-lab.ps1; Tests/Framework/Test-CommandSetup.ps1`
- Scope: Aktuelle physische Windows-/Linux-Matrix SQL2019 CL150, SQL2022 CL150/160, SQL2025 CL150/160/170: zwölf vollständige local/central/Consumer-Adapter erfolgreich, je 13104 feste APPLY-Oracles, 54 direkte Clientreader und 38 Lifecyclefälle. Alle Exit0, vollständige Kanäle, leeres Stderr. Zwölf frische read-only Kontrollverbindungen bestätigten tatsächliche Version/Plattform, unveränderte Input-/Sourcepins vor dem Dokumentationsnachtrag, je zwei exakt restaurierte Marker-/Fremdslotfixtures und alle 36 eigenen DBs abwesend. Keine Konfigurations-/Rechte-/Truständerungen. Aktueller Metadatenhelper im normalen nativen Pfad bestanden; zusätzlich zwei echte source-extrahierte SqlCommand-Setupfehler mit genau einer Dispose-Beobachtung und unveränderter fremder Connection ohne SQL bestanden. Functional mit erforderlicher Verschlüsselung und explizitem Lab-Trustwert; authentifizierte TLS-Abnahme separat. Minimalrechte, harter Runner-/Hostausfall, Heap-/Produktionskapazität, exakte Head-CI und Veröffentlichung bleiben separate Nachweise; weiterhin teilweise validiert und unveröffentlicht.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
