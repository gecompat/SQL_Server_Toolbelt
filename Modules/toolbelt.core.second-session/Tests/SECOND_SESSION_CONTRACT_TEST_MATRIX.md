# Second-Session-Contract-Testmatrix

- Providerkonfiguration nur für vorhandenen Linked Server
- `rpc out = true`
- `remote proc transaction promotion = false`
- echter Probe auf dieselbe Datenbank mit anderer `@@SPID`
- keine Linked-Server-/Login-/Credential-Erzeugung im Modul-Lifecycle
- Work-Type-Auflösung ohne Raw SQL
- Handler-Modi `NONE` und `JSON_PAYLOAD`
- exakte Handler-Signaturprüfung
- Remote-Principal benötigt `EXECUTE`
- Execution-/Correlation-ID, Actor und Tenant in der Remote-Session
- synchroner Handler-Returncode
- `WITH RESULT SETS NONE`
- Remote-Transaktionsrollback bei Handlerfehler
- Remote-Commit überlebt normalen Caller-Rollback
- Remote-Commit aus `XACT_STATE() = -1`
- direkte Ausgabe in uncommittable Caller
- ResultTable Replace/Append nur in committablem Zustand
- Providerdrift wird vor Ausführung abgelehnt
- vier parallele Second-Session-Aufrufe
- Redeploy erhält Providerkonfiguration
- Befüllter versionsgleicher 1.1.0-Repeat: zwei echte Deploys mit deaktiviertem
  Einzelprovider; acht Spalten einschließlich exakter Rowversionbytes,
  verschiedene 100-ns-Auditzeitpunkte und Unicode-/Padding-Autoren;
  ausgewählte Katalogmetadaten samt Objekt-IDs, vorhandenen Permissions,
  eigenen Annotationen und Tabellen-/Spalten-MS_Description; ohne RPC
- lokales und zentrales Deployment
- Data-Loss-geschützter Uninstall
- physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest

Der neue befüllte Tabellenrepeat benötigt eine eigene leere
Installationsdatenbank und wird separat von historischen Providerfällen
qualifiziert. Er erzeugt keine Benutzergrants, konfiguriert keine Linked
Server und beweist weder Minimalrechte noch Providerkonnektivität.
Windows, weitere Repeat-Compatibility-Levels und historische Übergänge bleiben
ohne eigene erfolgreiche Evidenz `not executed`. Cleanup und Grenzen stehen
im [Tests/README](README.md#befüllter-versionsgleicher-repeat).

## Ausgeführte Provider-Evidenz

- SQL Server 2025 Linux Loopback-RPC-Spike: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095
- Vollständige Modulmatrix: wird mit dem produktiven Runtime-Workflow nachgeführt.

- SQL Server 2025 Windows, manuelle lokale Validierung vom 2026-08-04: erfolgreich; lokale und zentrale Bereitstellung, Collation-übergreifender Abgleich, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützter und vollständiger Uninstall.

- Version 1.1.0 / `@SuppressResult`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-08`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37693379887`
- Scope: Commit 32ee260e413b8de7f9b2046ffdc11618b0afd69b: zwei echte befüllte 1.1.0-Repeats lokal/zentral auf Linux2019/150,2022/160,2025/170 mit genau einem deaktivierten synthetischen loopback-Eintrag; alle acht Spalten einschließlich unterschiedlicher Auditzeiten, Unicode-/Padding-Autoren und Rowversionbytes sowie ausgewählter Katalog, vorhandene Permissions und eigene Annotationen/MS_Description erhalten. Keine RPC-/Configure-USP-Aufrufe im neuen Tabellenrepeat. Bestehende API-/Provider-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung bestanden; abhängige W5b-Suite37693379826 ebenfalls SUCCESS am selben Head. Neue Windows-Repeats, weitere Repeat-CLs, nichtleere Benutzergrants, echte Minimalrechte, historische Übergänge und Hard-Interrupt-Recovery bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
