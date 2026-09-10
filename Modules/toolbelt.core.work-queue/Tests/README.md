# Work-Queue-Testevidenz

Die Runtime-Suite verwendet ausschließlich synthetische Work Types, Payloads
und Datenbanken. Sie prüft Vertrag, Parallelität, Redeployment, zentrale
Installation, Datenverlustschutz und vollständigen Uninstall. Claim-Token und
Payloadwerte werden nicht als Repository-Evidenz persistiert.

Am 2026-09-10 lief die Work-Queue-v2-Suite auf synthetischen SQL-Server-2019-,
2022- und 2025-Linux-Zielen erfolgreich. Sie deckt Retry/Dead Letter,
Idempotenz, Barrier-Snapshot und -Parallelität, Upgrade, Central, Lifecycle
sowie Cleanup ab. Der Windows-v2-Nachweis ist nicht ausgeführt; frühere
E1b-Windows-Evidenz belegt die v2-Erweiterung nicht. Alle synthetischen
Testdatenbanken werden durch den Adapter entfernt.

Evidenzquelle: `GitHub Actions: Work-Queue Runtime #34533724721`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-10`
- Nachweis: `GitHub Actions: Work-Queue Runtime #34533724721`
- Scope: Work Queue 2.0.0 auf synthetischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen; öffentlicher Vertrag, Retry/Dead Letter, Idempotenz, Barrier- und Parallelitätsfälle, Upgrade, Lifecycle, Central, Redeployment, Uninstall und Cleanup
- Ergebnis: `success; Windows-v2-Matrix not executed`
<!-- END GENERATED:MODULE_EVIDENCE -->
