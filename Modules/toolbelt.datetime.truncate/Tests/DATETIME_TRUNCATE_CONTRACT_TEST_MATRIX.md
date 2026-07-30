# Contract-Testmatrix: Date/Time Truncation

| Bereich | Pflichtfälle |
|---|---|
| Typen | `date`, `datetime2(7)`, `datetimeoffset(7)` mit typgleicher Ausgabe |
| Dateparts | kanonische Werte und Aliasse von `year` bis `microsecond` |
| Woche | mehrere `DATEFIRST`-Werte, `iso_week`, Unterlauf an `0001-01-01` |
| Fractional Scale | `millisecond` und `microsecond` bei Scale 7 |
| Offset | positive und negative nicht volle Stunden; Offset bleibt erhalten |
| Validation | Codes `10`, `11`, `12`; vollständig typisierte NULL-Propagation |
| Parität | ausgewählte Vektoren gegen natives `DATETRUNC` auf 2022/2025 |
| Performance | mengenorientierter `CROSS APPLY`-Aufruf; Planform vor Release prüfen |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

## Evidenzstatus

Der Workflow und die Contract-Tests sind vorhanden; Runtime ist
`not executed`.

[W2a Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2a-portable-runtime.yml)
