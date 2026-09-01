# Test-Evidence

Die Manuelle Windows-CLR-Preflight-Validierung vom 2026-08-04 war auf SQL Server 2025 unter Windows erfolgreich. Sie umfasste .NET-Framework-4.8-CLR-Build, SHA2-512-Trust, lokales Deployment, alle Help-Verträge und die kontrollierte SQL-Authentication-Ablehnung im `Caller`-Modus ohne I/O-Spuren. Der Lauf `Ergänzender Windows-CLR-Preflight-Lauf` vom 2026-08-05 bestätigte kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`.

Windows-Authentication-, NTFS-ACL- und weitere I/O-Tests bleiben `not executed`. Reale Pfade, Benutzer, NTFS-ACLs, Runtime-Ausgaben und Inhalte bleiben außerhalb des Repositorys.

Der .NET-Framework-4.8-Build und der statische Vertrag waren im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 erfolgreich. Dies ist kein Windows-SQL-Server-/NTFS-Runtime-Nachweis.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-05`
- Nachweis: `Ergänzender Windows-CLR-Preflight-Lauf`
- Scope: SQL Server 2025 Windows; kontrolliertes ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem WorkPath
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
