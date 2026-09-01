# Contract-Testmatrix: Date/Time Bucket

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
einschließlich Lifecycle, Central und Uninstall erfolgreich. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben `not executed`.

[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
