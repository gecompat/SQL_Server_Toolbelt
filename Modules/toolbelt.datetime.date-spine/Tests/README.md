# Date-Spine-Tests

- `Static/validate_contract.py` prüft Artefakte, Objektform und Dependency-Marker.
- `Runtime/DateSpine.Contract.sql` prüft API, Semantik, Grenzen, `DATEFIRST`
  und Skalierung.
- `Runtime/Lifecycle.Contract.sql` prüft Releaseobjekte und Modulmarker.
- `Runtime/Central.Contract.sql` prüft dreiteilige Aufrufe aus einer
  synthetischen Consumer-Datenbank.
- `Tests/CI/run-date-spine-linux.sh` orchestriert lokale und zentrale
  Lifecycle-Tests sowie Cleanup.

Runtime-Evidenz wird erst nach tatsächlicher Ausführung in `module.yaml`
eingetragen.

Evidenz 2026-08-30: `local: Tests/CI/run-lab-local.ps1` war auf den physischen
Linux-Zielen 2019, 2022 und 2025 erfolgreich. Die Windows-Runtime wurde wegen
nicht erreichbarer Zielverbindungen nicht ausgeführt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Explizit ausgewählte SQL-Server-2019-, 2022- und 2025-Windows-Ziele; SQL-Anmeldungs-Preflight
- Ergebnis: `not executed; Zielverbindungen waren vor der ersten Testmutation nicht erreichbar`
<!-- END GENERATED:MODULE_EVIDENCE -->
