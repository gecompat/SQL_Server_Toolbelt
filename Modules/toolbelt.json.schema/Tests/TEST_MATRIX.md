# JSON Schema – Abnahmematrix

| Bereich | Nachweis | Zustand |
|---|---|---|
| Profil, Priorität, Referenzen, Budget |159 Fälle/1174 Assertions je drei Cultures | bestanden offline |
| Exakte Zahlen |854 Fälle/6830 Assertions je drei Cultures, unabhängige rationale Vergleichsorakel | bestanden offline |
| Managed Bridge |120 Assertions je drei Cultures | bestanden offline |
| Closure | Eigene IL, kanonische bytegleiche Builds, bekannte Source-/Binarypins | bestanden offline |
| T-SQL | Source und expandierte Lifecycle-Skripte in ScriptDom150/160/170 | bestanden offline |
| Direkter SQL-Aufruf |30 native Contractfälle auf Linux2019/latest CL150 und Windows2025/CU8 CL150/160/170 jeweils local/central; Pointer über4000 UTF16-Einheiten mit Escape und NUL bytegenau | bestanden im begrenzten Scope |
| ResultTable | Zehn Typen/Ordinals, KeepData, echte Constraintfehler mit Ownrollback/Caller-Savepoint/doomed-Erhalt | beide Ziele local/central bestanden; Minimalrechte offen |
| Help und API-Metadaten | Help zuerst, echte Clientreader mit zehn Typen/Ordinals, parameterisierte dynamische Bridge | bestanden auf beiden Zielen local/central |
| Grenzen | Tiefe129, Budget1, MaxErrors0/1, Diagnosetrunkierung und abgesenkte Bytegrenzen/Fehlerpriorität in30 Contractfällen | bestanden auf beiden Zielen local/central; maximale Bytegrenzen separat offen |
| Lifecycle | local/central, Repeat, zwei Consumer-Abweisungen, Uninstall/Repeat und Coreidentität | bestanden auf beiden Zielen; Fremdslot-/Marker-/Owner-/Lockvollmatrix offen |
| Constructorsmigration | Genuine bekannte1.2→1.3, fünf Procedure-ObjectIds/Rechte und effektive Owner erhalten; drei CLR-Slots/Assembly atomar neu, post-DROP-Rollback | beide Ziele local/central bestanden |
| Plattformmatrix | SQL2019/2022/2025; CL150/160/170 soweit unterstützt; Windows/Linux | Lab: Linux2019 CL150 und Windows2025 CU8 CL150/160/170; separate PR176-CI Linux2019/2022/2025 bestanden |

Die Offline-Driver besitzen endliche Prozessbudgets, prüfen tatsächliche
Exitcodes und Capture und schreiben private Evidenz ausschließlich in neue,
ignorierte `.runtime`-Verzeichnisse. SQL-Testziele werden erst aus dem
schema-validierten Labvertrag ausdrücklich ausgewählt. Neue Trusthashes
werden exakt identifiziert; die aktuelle Schema-Testwelle besitzt die
[fortgeltende Benutzerfreigabe](../Documentation/TRUST_UNICODE_BINDING_OPT_IN.md).
Kein Infrastruktur- oder Produktionsbetrieb. Frühere6552-/Fixture-/Cleanup-
und6282-Migrationsfehlläufe bleiben getrennte Fehlerhistorie.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central:30 Contractfälle, Safety/Help/ResultTable/Callerrollback, direkte Clientmetadaten, Repeat, Consumer-Abweisungen, Uninstall/Repeat und eigenes DB-/Trustcleanup bestanden. Je frischer hashgebundener Dispositionaudit bestanden; keine Konfigurations-/Rechte-/Owneränderungen. Constructorsmigration auf diesen Levels nicht ausgeführt; weitere physische Ziele und Minimalrechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
