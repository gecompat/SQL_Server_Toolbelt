# Work-Queue-Testevidenz

Die Runtime-Suite verwendet ausschließlich synthetische Work Types, Payloads
und Datenbanken. Sie prüft Vertrag, Parallelität, Redeployment, zentrale
Installation, Datenverlustschutz und vollständigen Uninstall. Claim-Token und
Payloadwerte werden nicht als Repository-Evidenz persistiert.

Am 2026-08-30 war der vollständige E1b-Adapter auf physischen
SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest
erfolgreich. Der Scope umfasst Lease, Heartbeat, Recovery, Token-
Invalidierung, aktiven Ablaufvertrag, vier echte Claim-Sessions, Central,
Lifecycle sowie das erfolgreiche Upgrade `1.0.0 → 1.1.0` und dessen
blockierenden Active-Claim-Preflight. Alle synthetischen Testdatenbanken
wurden entfernt; die Lab-Umgebungen selbst blieben unberührt.

Evidenzquelle: `local: Tests/CI/run-lab-local.ps1`.
