# Contract-Testmatrix: Date/Time Truncation

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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

SQL Server 2025 Linux war mit Compatibility Levels 150, 160 und 170
einschließlich Lifecycle, Central und Uninstall erfolgreich. Physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben `not executed`.

[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2a-portable-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger W2a-Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
