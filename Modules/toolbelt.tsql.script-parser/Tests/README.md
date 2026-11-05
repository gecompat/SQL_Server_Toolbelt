# Tests für `toolbelt.tsql.script-parser`

## Prüfartefakte

- `Static/validate_contract.py` — statischer Code- und Artefakt-Validator.
- `Framework/Invoke-Guard.ps1` — dependency-freie Prüfungen desselben Rohtextwächters.
- `Framework/Invoke-Contract.ps1` — begrenzte Framework-Kindprozesse für den frisch gebauten Provider mit exakter Dependency und Artefakt-Fingerprints.
- `Runtime/ScriptParser.Contract.sql` — Funktionsverträge (AST, Tokens, Properties, Errors, NULL-Handling).
- `Runtime/Bounds.Contract.sql` — gemeinsame Grenzen, Fehlerpriorität und atomare Ablehnung.
- `Runtime/Syntax.Contract.sql` — repräsentativer Syntaxkorpus mit konkreten Knoten-/Eigenschafts-/Token- und Versionsorakeln.
- `Runtime/Lifecycle.Contract.sql` — Installationsmarker, Extended Properties und Assembly-Inventar.
- `Runtime/Lifecycle.Snapshot.sql` und `Runtime/Lifecycle.CollisionFixture.sql` — private Vergleichssnapshots und synthetische Fehlerzustände, ohne öffentliche Runtime-Evidenz.
- `Runtime/Central.Contract.sql` — Cross-Database-Aufruf im Central-Deployment-Modus.

## Aktueller Stand vom 2026-11-05

Der unveränderte aktuelle Providerbuild besteht die native API-Matrix und
datenbanklokalen Minimalrechte auf Windows SQL Server 2019/CU32 CL150,
2022/CU26 CL150/160 sowie 2025/CU8 CL150/160/170, jeweils lokal und zentral.
Insgesamt bestanden 72 Suite-Ausführungen. Jeder finale Lauf ist
`PASS_CLEANED`, sein frischer Parser-Audit ist PASS; Konfiguration, Trust und
Verbraucherzustand sind separat frisch wiederhergestellt und geprüft.
Auf 2025 blockierte zunächst ein eigener DMV-Prüftask die Wiederherstellung;
dieser Fehler bleibt erhalten. Nach eng begrenzter Taskzuordnung ist auch
der separate finale Wiederherstellungsaudit PASS.

Die Testidentität ist ein eigener temporärer Datenbankbenutzer ohne Login.
Der Benutzer hat diese eng begrenzte Abweichung vom früheren Testplan
ausdrücklich freigegeben. Nur SELECT auf die vier öffentlichen Funktionen
wurde erteilt; alle vier positiven Aufrufe und die DENY-Gegenprobe bestanden,
ohne db_owner, CONTROL oder ALTER ANY ASSEMBLY. Dies belegt keine neue
Clientanmeldung und keine gemappte Lowpriv-Cross-DB-Identität.

Die öffentliche Token-Grenze 8191/8192/8193 ist auf allen zwölf Kontexten
nativ geprüft. Die Errors-Fälle 255/256 sowie der vorgelagerte Atomfehler
bei 257 sind zusätzlich auf den zehn Kontexten von 2022/2025 geprüft.
Eine echte 257er-Errors-Quotenüberschreitung wird daraus nicht abgeleitet.
Der abschließende Frameworklauf hat 248 Fälle, darunter das Originalbudget
mit gleichzeitig unveränderten Produktionslimits. Eine separate
Invariantenprüfung verwirft sieben unsichere Quellmutanten; die
Qualifikationsprüfung verwirft zwölf falsche Ergebnis-/Bindungsbehauptungen.

Der [aggregierte Nachweis](Qualification/Current.Build.20261105.json)
bewahrt die nicht ausgeführten öffentlichen Grenzaufrufe. Der
[kombinierte Nachweisvertrag](OUTPUT_QUOTA_ACCEPTANCE_PROPOSAL.md)
ist durch ausdrückliche Benutzerentscheidung vom 2026-11-05 freigegeben.
Das Modul ist für diesen aktuellen Build und Nachweisvertrag `validated`,
weiterhin `unreleased`. Native-, Binary- und Invariantenbelege bleiben
getrennt; daraus wird kein vollständiger nativer Quoten-Branchlauf.
Konkrete private Artefakt-, Quellen-, Ziel-, Journal- und Auditbindungen
sind separat erhalten; der öffentliche Quellvergleich dient der
Drifterkennung, nicht als Ersatz dieser Originalnachweise.

Die ersten Fehler durch einen veralteten Lifecycle-Hash und die ursprüngliche
SQL-2025-Caller-Wiederherstellungsblockade bleiben Historie. Der Lifecycle-Test
liest seine exakten Sollhashes jetzt aus dem vor SQL validierten Manifest;
ein neues Produktbinary wird nicht gegen einen früheren Literalhash geprüft.
Die SQL-2022-Matrix enthält ausschließlich CL150/160. Keine Wiederholung der
abgeschlossenen SSIS-Welle, kein Produktcodewechsel und keine Veröffentlichung.

## Historischer Status vom 2026-10-19

Parser 2.0.1 bleibt `partially validated` und `unreleased`. Der pfadbereinigte
Build und 245 Frameworkfälle sind seit 2026-10-18 nachgewiesen. Auf Windows
SQL Server 2019/2022/2025 bestanden lokal und zentral echte Parser-Upgrades,
SSIS-/Table-Clone-Consumer, Triggerfixtures, Repeat und eigener Cleanup.
Die [SSIS-Evidenz](../../toolbelt.tsql.ssis-debug/Tests/README.md#aktuelle-validierungsevidenz)
beschreibt diesen begrenzten Scope. Alle nativen Parser-APIs, tatsächliche
Ausgabeceilings und Minimalrechte sind dadurch nicht vollständig qualifiziert.
Die frühere Pending-Konfiguration ist kein pauschaler aktueller Testblocker.

## Begrenzter aktueller Nativeinstieg

[`Invoke-ScriptParserCurrentLab.ps1`](../../../Tests/CI/Invoke-ScriptParserCurrentLab.ps1)
ergänzt den unveränderten, hashgebundenen nativen Parseradapter um einen
aktuellen Quellen-/Artefaktplan, eine exklusive Budgetreservierung und einen
separaten frischen Abschlussaudit. Er erzeugt keine neue Implementierungs-
oder Testfreigabe und konfiguriert keine Servereinstellung.

`Describe` komponiert den Adapter ohne SQL; `Run -ValidateOnly` prüft den
vorbereiteten Plan ohne Verbindung. `Run` und `Audit` benötigen jeweils
`PlanPath`, `ExpectedPlanSha256` und `BudgetPath`; `Audit` zusätzlich den
exakten `ExpectedJournalSha256` des finalen Laufjournals. Der private Plan
`parser-current-lab/v1` bindet Version, exakten CU-Patch, genau einen
schema-validierten Labselektor, Vertragspfad/-hash, Releaseverzeichnis,
vollständige Quellen- und vier Artefakthashes sowie ein eigenes temporäres
Verzeichnis außerhalb jedes Git-Worktrees. Konkrete Pläne, Zielinformationen,
Journale und Laufzeitausgaben bleiben privat. Keine Zugangsdaten im Plan.

Das vorbereitete Budget bindet dieselbe Welle/Version/Patch, höchstens einen
Lauf und einen Audit sowie drei eigene Datenbanken. Der Lauf hat 25 Minuten,
sein Cleanup ein eigenes 120-Sekundenfenster und der Audit fünf Minuten;
der gemeinsame verbleibende Zeitraum muss jeweils ausreichen. Der bestehende
Full-Framework-Test bleibt vor der ersten SQL-Verbindung. Ein begonnenes
Suitejournal ist kein Suite-PASS. Fehler bleiben Fehler, auch bei erfolgreicher
Bereinigung; ein unvollständiges Eigentumsjournal oder ein fehlender frischer
Audit erlaubt keinen Gesamterfolg. CLR-Voraussetzungen sind separat unter
der jeweiligen Testkonfigurationsfreigabe zu koordinieren.

Am 2026-11-05 wurde der aktuelle Quellstand in zwei getrennten Buildpfaden
reproduzierbar gebaut. Der Full-Framework-Test bestand seine 245 Fälle.
Der begrenzte Windows-SQL-2019-/CU32-Versuch scheiterte anschließend vor
der ersten API-Suite an einer Variablenkollision im neuen Adapter.
Die eigene Datenbank wurde entfernt; der Parser-Abschlussaudit wurde durch
eine unzutreffende Präfixprüfung blockiert. Ein separater frischer
Konfigurationsaudit bestätigte anschließend die Wiederherstellung und den
unveränderten Trust-/Verbraucherzustand. Der erste Versuch mit fehlender
CLR-Voraussetzung bleibt ebenfalls fehlgeschlagen, mit eigenem Audit-PASS.
Diese Befunde qualifizieren keine native Parser-API und keinen Gesamtfall.

Die Korrekturen sind durch ausführbare Offlinegegenproben abgesichert:

```powershell
./Tests/Release/Test-ParserCurrentLab.ps1
```

Die Gegenproben prüfen unter anderem die geerbte `ValidateSet`-Kollision,
beide tatsächlichen Datenbankpräfixe, fremde Präfixe, geblockten Trust,
abgelaufene Fristen, vollständige JSON-Mehrteiler und manipulierte Pläne.
Ihre Korrekturen sind noch nicht erneut nativ ausgeführt. Der Vollscope für
2.0.1 auf Windows 2019/2022/2025, tatsächliche öffentliche Ausgabeceilings
und Minimalrechte bleiben offen. Vorhandene Consumer-/Upgrade-Nachweise
behalten ihren ursprünglichen Scope; das Modul bleibt `partially validated`.

## Historischer Status des 2.0.0-Vollscopes

Die folgende Tabelle erhält die damaligen Ergebnisse. Ihre nicht ausgeführten
Vollscope-Fälle sind von den später erfolgreichen 2.0.1-Consumerprüfungen
zu unterscheiden.

| Umgebung | Scope | Ergebnis |
|---|---|---|
| Privater Offline-Runner, 2026-10-02 | 82 isolierte Framework-Kindprozesse mit exakt gepinnter Dependency; Kandidaten-Rohtextwächter, Parser 150/160/170, unabhängige Wiederholung | `success`, ausschließlich historisches Kandidaten-Gate vor Source; der nicht verfügbare Runner für den neuen Pin ist am 2026-10-09 durch Benutzerentscheidung geschlossen und wird nicht erneut eingeplant |
| Rekonstruierte Offline-Qualifikation | 82 isolierte Kindprozesse mit aktuellem Guard/Provider und dem exakt gepinnten aktuellen Binary-Paar | `success`, 2026-10-09; getrennte aktuelle Regression, kein Ersatz für den historischen Vor-Source-Nachweis |
| Windows (.NET Framework 4.8), 2026-10-02 | 245 begrenzte Kindprozesse: vier APIs, Grenzen, deterministische AST-/Property-/Offset-Orakel, Syntaxkorpus und Versionskontraste; unabhängig wiederholt | `success`; Ausgabequoten-Nachweis nur Accounting-Helper |
| SQL_Server_Lab, 2026-10-02 | Windows SQL Server 2025/CU8, CL150/160/170; saubere Installation, lokale/zentrale Nutzung, echtes 1.0-Upgrade, Wiederholung, vier APIs, Grenzen/Syntax, Caller-TX/SET-Erhalt, Kollisions-/Dependency-Schutz, Fremdobjekterhalt, Lock-/Rollbackfehler, Uninstall und eigenes DB-/Trust-Cleanup | `success` |
| Windows SQL Server 2019 | Live-Qualifikation nach schema-validiertem READY-/Login-Preflight | `not executed`: CLR-Aktivierung würde eine fachfremde Pending-Konfiguration mitaktivieren; keine Mutation, Entscheidung offen |
| Windows SQL Server 2022 | 2.0.0: separate Zielkombination | `not executed` |
| Statischer Validator, 2026-10-02 | 2.0.0-Artefakt- und Schnittstellenprüfung; shared guard 60 Prüfungen | `success` |

Die [Hardening-Qualifikation](../../../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md) trennt Kandidat, integrierten Provider und Live-SQL. Historische 1.0.0-Erfolge bleiben erhalten, qualifizieren jedoch weder die neuen Vertragsgrenzen noch 2.0.0. Abgesenkte private Ausgabequoten prüfen Atomarität; sie ersetzen keine Grenzqualifikation der tatsächlichen öffentlichen Limits. Fehlende Runner, minimale Rechte oder Upgrade-Fixtures dürfen nicht als PASS gelten.

Der Lab-Adapter [run-script-parser-lab.ps1](../../../Tests/CI/run-script-parser-lab.ps1) erfordert den frisch qualifizierten Release-Stand, die exakte vorherige 1.0.0-Assembly für echten Upgrade-Nachweis und bereits aktiviertes CLR bei unveränderter Strict Security. `-OptInExactTrust` bleibt der sichtbare administrative Testschritt mit vorhandenen Rechten und neuem privatem Journal. Die hashgebundene Trust-Freigabe für einzeln freigegebene Entwicklungswellen besteht seit 2026-10-10; das Deployment registriert Trust weiterhin nicht selbst. Vorhandene Einträge bleiben erhalten. Nur eindeutig neu angelegte Einträge ohne Assembly-Verbraucher werden nach eigenem Datenbank-Cleanup entfernt; unklare Scope-/Registrierungs-/Cleanup-Zustände bleiben ausdrücklich blockiert. Es gibt kein RECONFIGURE, keine Rechtevergabe, keinen Container- oder Provider-Fallback.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-11-05`
- Nachweis: `local: Invoke-ScriptParserCurrentLab.ps1 plus separate configuration recovery/audit; Framework/Invoke-Contract.ps1`
- Scope: Unveränderter aktueller Quellbuild2.0.1: native API-/datenbanklokale Minimalrechtematrix Windows2019CU32/2022CU26/2025CU8 über unterstützte CLs lokal/zentral,72 Suites; frische Parser-/Konfigurationsaudits PASS. Erste Lifecycle-Literalhashfehler und ursprüngliche2025Caller-Restoreblockade bleiben erhalten, finale eigene Wiederherstellung PASS. Token-Grenze nativ, Errors255/256 und vorgelagerte257er-Atomablehnung auf2022/2025. Framework248 inklusive unveränderter Originalbudgets; kombinierte Quotenabnahme ausdrücklich am2026-11-05 freigegeben, keine Aufwertung nicht ausgeführter öffentlicher Grenzaufrufe.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
