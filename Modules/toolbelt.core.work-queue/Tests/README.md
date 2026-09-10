# Work-Queue-Testevidenz

Die Runtime-Suite verwendet ausschließlich synthetische Work Types, Payloads
und Datenbanken. Sie prüft Vertrag, Parallelität, Redeployment, zentrale
Installation, Datenverlustschutz und vollständigen Uninstall. Claim-Token und
Payloadwerte werden nicht als Repository-Evidenz persistiert.

Am 2026-09-10 lief die Work-Queue-v2-Suite auf synthetischen SQL-Server-2019-,
2022- und 2025-Linux-Zielen erfolgreich. Der lokale Adapter bestand am
2026-09-11 auf physischen Windows-Zielen derselben Versionen. Der Scope deckt
Retry/Dead Letter, Idempotenz, Barrier-Snapshot und -Parallelität, Upgrade,
Central, Lifecycle sowie Cleanup ab. Alle synthetischen Testdatenbanken werden
durch den Adapter entfernt.

Evidenzquelle: `GitHub Actions: Work-Queue Runtime #34533724721`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Work Queue 2.0.0 auf physischen SQL-Server-2019-, 2022- und 2025-Windows-Zielen; öffentlicher Vertrag, Retry/Dead Letter, Idempotenz, Barrier- und Parallelitätsfälle, Upgrade, Lifecycle, Central, Redeployment, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
