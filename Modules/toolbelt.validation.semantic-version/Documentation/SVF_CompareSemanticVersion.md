# `SVF_CompareSemanticVersion`

Vergleicht zwei `varchar(8000)`-Werte nach SemVer 2.0.0. Ergebnis: `-1`, `0`,
`1`; `NULL`, falls mindestens eine Eingabe ungültig ist. Build Metadata wird
ignoriert. Zahlen werden über Länge und anschließend ASCII-binär verglichen.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373
