# Regex-Tests

Der statische Validator prüft CLR-Projekt, Parsergrenzen, SAFE-/Trust-
Deployment, Manifest und Runtimeartefakte. Der Runtimeadapter deckt den
Dialekt, UTF-16-Positionen, NULL, Flags, Grenzen, stabile 6522-Präfixe,
Timeout, Erst-/Wiederholungsdeployment, Kollision, Central und Uninstall ab.

Die vollständige Pflichtmatrix lief am 2026-08-30 auf physischen SQL-Server-
2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich.
Die Adapter löschten ihre synthetischen Datenbanken und neu erzeugten
Trust-Einträge; die Lab-Umgebungen wurden nicht beendet.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: R1b auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest; SAFE CLR, exakter SHA2-512-Trust, Toolbelt-Dialekt, UTF-16, Grenzen, Timeout, Fehlerpräfixe, Erst- und Wiederholungsdeployment, Kollision, Central, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
