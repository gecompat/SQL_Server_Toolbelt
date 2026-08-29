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
