# `SVF_CompareSemanticVersion`

Vergleicht zwei `varchar(8000)`-Werte nach SemVer 2.0.0. Ergebnis: `-1`, `0`,
`1`; `NULL`, falls mindestens eine Eingabe ungültig ist. Build Metadata wird
ignoriert. Zahlen werden über Länge und anschließend ASCII-binär verglichen.

Die SVF delegiert an
[`TVF_CompareSemanticVersion`](./TVF_CompareSemanticVersion.md). Für
mengenorientierte Vergleiche ist die inline TVF mit `APPLY` zu bevorzugen.

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984
