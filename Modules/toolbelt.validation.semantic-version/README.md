# toolbelt.validation.semantic-version

Strikte Semantic-Version-2.0.0-Validierung und Präzedenz für ASCII-Strings bis
`varchar(8000)`.

Status: `implemented`, `partially validated`, `unreleased`.

Öffentliche Objekte:

- `TVF_ParseSemanticVersion` – genau eine Validierungs-/Komponentenzeile;
- `SVF_CompareSemanticVersion` – `-1`, `0`, `1` oder `NULL`;
- `SVF_SemanticVersionSortKey` – binärer, collation-unabhängiger Präzedenzkey.

Core-Zahlen bleiben Dezimalstrings und können daher nicht numerisch
überlaufen. Build Metadata wird erhalten, aber bei Präzedenz und Sort Key
ignoriert. Es gibt kein Trimmen, `v`-Präfix oder stilles Korrigieren.

Aktuelle Evidenz:
[Semantic-Version Runtime Run 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben offen.

Siehe [Design](../../Documentation/Architecture/SEMANTIC_VERSION_MODULE_DESIGN.md)
und [Testmatrix](./Tests/SEMANTIC_VERSION_CONTRACT_TEST_MATRIX.md).
