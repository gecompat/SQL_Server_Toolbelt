# Shared Core – Abnahmematrix

| Bereich | Nachweis | Zustand |
|---|---|---|
| Budget und Tokenpolicy | 10 Budgetfälle, 37 Tokenfälle/95 Assertions | bestanden offline |
| Eigene IL und Negativfixtures | Geschlossene Bindungen; acht verbotene Fixtureklassen | bestanden offline |
| Buildidentität | Drei kanonische MSBuild-Projekte bytegleich | bestanden offline |
| Paketierung | Framing, Source-/Binarypins, Coreverweise | bestanden offline |
| Lifecycle-Syntax | Deploy/Uninstall in ScriptDom150/160/170 | bestanden offline |
| SQL Server2019/2022/2025, Windows/Linux | SAFE-Laden, Coreunsichtbarkeit, gemeinsame Owner | Linux2019 CL150 und Windows2025 CU8 CL170 local/central bestanden; weitere Ziele offen |
| Lifecycle | local/central, Repeat, Verbraucher-Abweisung, Erhalt nach Consumer-DROP | beide Ziele bestanden; Drift-/Owner-/Lockvollmatrix offen |
| Constructors1.2→1.3 | Atomare Neuerstellung eigener CLR-Slots, fünf Procedureidentitäten/Rechte erhalten, post-DROP-Rollback und zusätzliche Annotation abgewiesen | beide Ziele local/central bestanden; ALTER-Versuch6282 fehlgeschlagen |

Die ausführbaren Offline-Driver liegen in
[`toolbelt.json.schema/Tests/Framework`](../../toolbelt.json.schema/Tests/Framework/README.md).
Die nativen Teilnachweise und ihre Grenzen stehen in
[`NATIVE_EVIDENCE.md`](../../toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).
Die Benutzerfreigaben für die qualifizierten Trusthashes sind dokumentiert;
Deploymentskripte ändern Trust weiterhin nicht automatisch.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1`
- Scope: Linux2019/latest CL150 und Windows2025/CU8 CL170: Core-/Schema local/central, Repeat, zwei Consumer-Abweisungen, eigenes Cleanup und Coreidentität nach Schema-DROP bestanden. Genuine1.2→1.3 beide Ziele local/central samt post-DROP-Rollback, vier Constructor-Fixtures und unveränderten fünf Procedureidentitäten bestanden. Frische hashgebundene Dispositionaudits beider aktueller Core-/Schema-/Migrationsscopes bestanden. Weitere Lifecycle-/Zielmatrix und minimale Rechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
