# Contract-Testmatrix: Date/Time Bucket

| Bereich | Pflichtfälle |
|---|---|
| Typen | `date`, `datetime2(7)`, `datetimeoffset(7)` |
| Dateparts | `year` bis `millisecond`, dokumentierte Aliasse |
| Width | `1`, mehrere Einheiten, `0`, negative Werte, `int`-Grenzen |
| Origin | Default, explizit, Zeitanteil, Monatsende, unterschiedliche Offsets |
| Richtung | Value vor und nach Origin; mathematisches Floor für negative Abstände |
| Grenzen | minimale und maximale Date/Time-Werte, Engine-Overflow unverändert |
| Validation | Codes `10`, `11`, `12`; NULL-Propagation |
| Parität | ausgewählte Vektoren gegen natives `DATE_BUCKET` auf 2022/2025 |
| Optimizer | öffentliche Inline-TVFs vor internem einzeiligem Core; kein Fehler `8632` |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

## Evidenzstatus

Der Workflow und die Contract-Tests sind vorhanden; Runtime ist
`not executed`.

[W2a Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2a-portable-runtime.yml)
