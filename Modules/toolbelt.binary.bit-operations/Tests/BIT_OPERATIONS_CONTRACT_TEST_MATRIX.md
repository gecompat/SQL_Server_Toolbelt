# Contract-Testmatrix: Bigint Bit Operations

| Bereich | Pflichtfälle |
|---|---|
| Shift | links, rechts, negativ, `0`, `63`, `64`, größere Beträge, bigint-Min/Max |
| Logik | Right Shift negativer Werte füllt mit null; Left Shift verwirft Übertrag |
| Bit Count | `0`, `-1`, Min/Max, wechselnde Muster, `NULL` |
| Get Bit | Offset `0`, `63`, negativ, `64`, Vorzeichenbit |
| Set Bit | setzen, löschen, Default `1`, ungültiger Bitwert, Vorzeichenwechsel |
| Validation | Codes `10`, `11`; typisierte NULL-Propagation |
| Parität | alle fünf Operationen mit Vektoren gegen SQL Server 2022/2025 |
| Performance | mengenorientierter `APPLY`-Aufruf und Vergleich mit nativer Funktion |
| Lifecycle | Erstdeployment, Wiederholung, Kollision, Central, Uninstall |

`binary(n)` und `varbinary(n)` sind nicht Teil dieser Matrix.

## Evidenzstatus

Der Workflow und die Contract-Tests sind vorhanden; Runtime ist
`not executed`.

[W2a Portable Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2a-portable-runtime.yml)
