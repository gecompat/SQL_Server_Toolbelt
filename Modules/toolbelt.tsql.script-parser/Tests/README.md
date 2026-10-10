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

## Status

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
- Datum: `2026-10-09`
- Nachweis: `local: Scripts/New-ClrReleaseArtifacts.ps1; Tests/Framework/Invoke-Contract.ps1 -QualificationProfile Reconstructed82; Tests/Static/validate_contract.py`
- Scope: Aktuelle rekonstruierte Offline-Regression: exakter ScriptDom-18.0.117.0-Pin, reproduzierter .NET-Framework-4.8-Releasebuild und 82 isolierte Kindprozesse bei 262144 Byte Stack. Historischer vor-Source-Runner bleibt nicht ausgeführt, ist aber durch Benutzerentscheidung geschlossen; dieser Lauf ersetzt ihn nicht. Keine SQL-Ausführung, Trust-, Konfigurations- oder Rechteänderung.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
