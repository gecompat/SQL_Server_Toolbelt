# Second-Session-Testevidenz

Der Provider-Spike auf SQL Server 2025 Linux hat einen synchronen Loopback-RPC mit deaktivierter Transaktionspromotion bestätigt. Remote-Commits überleben sowohl einen späteren Caller-Rollback als auch einen bereits uncommittable Caller; die Remote-Ausführung verwendet eine andere `@@SPID`.

Provider-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095

Die vollständige Modulmatrix für Konfiguration, Work-Type-Signaturen, Context-Propagation, ResultTable, Concurrency, Central, Lifecycle und Uninstall wird im dauerhaften W5a-Runtime-Workflow ausgeführt.

Die manuelle Windows-Validierung vom 2026-08-04 lief mit `System.Data.SqlClient` gegen SQL Server 2025 unter Windows erfolgreich. Sie umfasste lokale und zentrale Bereitstellung, einen Collation-übergreifenden Abgleich mit `master.sys.servers`, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützten und vollständigen Uninstall. Sie ist kein GitHub-Hosted-CI-Nachweis.

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.

Version `1.1.0` mit resultsetfreier Ausführung: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410
