# Second-Session-Testevidenz

Der Provider-Spike auf SQL Server 2025 Linux hat einen synchronen Loopback-RPC mit deaktivierter Transaktionspromotion bestätigt. Remote-Commits überleben sowohl einen späteren Caller-Rollback als auch einen bereits uncommittable Caller; die Remote-Ausführung verwendet eine andere `@@SPID`.

Provider-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095

Die vollständige Modulmatrix für Konfiguration, Work-Type-Signaturen, Context-Propagation, ResultTable, Concurrency, Central, Lifecycle und Uninstall wird im dauerhaften W5a-Runtime-Workflow ausgeführt.

Windows und physische SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.
