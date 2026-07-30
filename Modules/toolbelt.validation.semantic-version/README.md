# toolbelt.validation.semantic-version

Strikte Semantic-Version-2.0.0-Validierung und Präzedenz für ASCII-Strings bis
`varchar(8000)`.

Status: `implemented`, `not executed`, `unreleased`.

Öffentliche Objekte:

- `TVF_ParseSemanticVersion` – genau eine Validierungs-/Komponentenzeile;
- `SVF_CompareSemanticVersion` – `-1`, `0`, `1` oder `NULL`;
- `SVF_SemanticVersionSortKey` – binärer, collation-unabhängiger Präzedenzkey.

Core-Zahlen bleiben Dezimalstrings und können daher nicht numerisch
überlaufen. Build Metadata wird erhalten, aber bei Präzedenz und Sort Key
ignoriert. Es gibt kein Trimmen, `v`-Präfix oder stilles Korrigieren.

Aktuelle Evidenz:
[Semantic-Version Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/semantic-version-runtime.yml)
ist `not executed`.

Siehe [Design](../../Documentation/Architecture/SEMANTIC_VERSION_MODULE_DESIGN.md)
und [Testmatrix](./Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md).
