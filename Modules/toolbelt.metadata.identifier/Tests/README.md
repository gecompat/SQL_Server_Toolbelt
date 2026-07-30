# Tests für `toolbelt.metadata.identifier`

`Identifier.Contract.sql` prüft den öffentlichen Parser- und Quote-Vertrag.
`Lifecycle.Contract.sql` prüft Marker, Objekttypen und interne Dependency.
`Central.Contract.sql` prüft dreiteilige Aufrufe aus einer getrennten
synthetischen Konsumentendatenbank.

Die statische Prüfung und der
[Identifier-Runtime-Workflow](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/identifier-runtime.yml)
sind vorhanden. Runtime-Evidenz ist noch `not executed`.
