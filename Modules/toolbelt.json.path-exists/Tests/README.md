# Tests JSON Path Exists

`JsonPathExists.Contract.sql` prüft Pfad-, JSON-, NULL-, Wildcard-,
Collation- und native Paritätsfälle. `Lifecycle.Contract.sql` prüft
Objektart und Modulmarker; `Central.Contract.sql` prüft den dreiteiligen
Aufruf.

Geplanter CI-Scope:

- SQL Server 2025 Linux;
- Compatibility Levels 150, 160 und 170;
- wiederholtes Deployment;
- lokaler und zentraler Aufruf;
- Uninstall.

Runtime-Evidenz ist bis zum erfolgreichen Workflow `not executed`.

Workflow:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2b-json-path-runtime.yml
