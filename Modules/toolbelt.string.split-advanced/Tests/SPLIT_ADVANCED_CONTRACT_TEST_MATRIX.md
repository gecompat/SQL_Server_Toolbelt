# Split-Advanced Contract Test Matrix

| Scope | Abdeckung |
|---|---|
| API | fünf Parameter und fünf Resultsetfelder; Defaultwerte, APPLY |
| Token | NULL/leer, KeepEmpty inklusive NULL, lückenlose Ordinals, Originaltokens |
| Parser | Quotes überall, Escape allgemein, längster Match, atomare Fehler |
| Unicode | BIN2, Spaces, Supplementary-Paare, NUL, Steuerzeichen-Surrogate |
| JSON | Syntax/root, nichtstring/nested/null, leer, Duplikate, Arrayreihenfolge |
| Limits | Input 65536/65537, JSON 16384/16385, 16/17, Separator 64/65 |
| Lifecycle | local/central, Driftkorrektur, fremde Kollision, Schemaerhalt, Dependencyblocker, zentrale Betreiberbestätigung |
| Collation | lokale CS_AS, zentrale BIN2, Verbraucher CI_AS |
| SELECT-Rechte | synthetische eingeschränkte User lokal und direkt im zentralen Installationskontext; keine serverweiten Login-/Trust-Fixtures |

[Runtime](Runtime/SplitAdvanced.Contract.sql), [Lifecycle](Runtime/Lifecycle.Contract.sql), [Cross-DB](Runtime/Central.Contract.sql). Keine Performanceaufwertung aus diesen Funktionstests; kein USP-/Unquoting-Testscope.

Der Cross-DB-Funktionstest verwendet den administrativen Testkontext.
Niedrigprivilegierter Cross-DB-Zugriff erfordert separat administrierte,
in beiden Datenbanken passende Login-/User-/SELECT-Berechtigungen; die
WITHOUT-LOGIN-/EXECUTE-AS-USER-Probe beweist keine Cross-DB-Authentifizierung.
Die zusätzlichen IF/TF-Drift- und SELECT-Minimalrechteproben wurden gezielt
auf SQL Server 2025 Linux ausgeführt, nicht rückwirkend auf anderen Zielen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux: erweiterter vollständiger Adapter nach Review mit IF/TF-Driftkorrektur und Drift-Uninstall, nichtnullable IsValid-Metadaten und explizitem NULL-Oracle sowie SELECT-Minimalrechteproben lokal und direkt im zentralen Installationskontext. Niedrigprivilegierter Cross-DB-Aufruf mit mapped Caller nicht ausgeführt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
