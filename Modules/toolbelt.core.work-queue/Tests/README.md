# Work-Queue-Testevidenz

Die Runtime-Suite verwendet ausschließlich synthetische Work Types, Payloads
und Datenbanken. Sie prüft Vertrag, Parallelität, Redeployment, zentrale
Installation, Datenverlustschutz und vollständigen Uninstall. Claim-Token und
Payloadwerte werden nicht als Repository-Evidenz persistiert.

Am 2026-08-30 war der vollständige Adapter auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Die drei explizit
ausgewählten Windows-Base-Ziele scheiterten bereits im SQL-Anmeldungs-
Preflight; dort wurde keine Testmutation ausgeführt. Alle synthetischen
Testdatenbanken der erfolgreichen und fehlgeschlagenen Adapterläufe wurden
entfernt, die Lab-Umgebungen selbst blieben unberührt.

Evidenzquelle: `local: Tests/CI/run-lab-local.ps1`.
