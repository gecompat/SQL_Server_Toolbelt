# Contract-Testmatrix: Bigint Bit Operations

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
einschließlich Lifecycle, Central und Uninstall erfolgreich. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben `not executed`.

[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)
