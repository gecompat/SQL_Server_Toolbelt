# Execution Cancellation Contract Test Matrix

## Explizites Linux-Repeatprofil

Der [aktuelle CI-Testweg](README.md#linux-repeat-mit-explizitem-compatibility-level)
verlangt SQL2019/150,SQL2022/150/160 und SQL2025/150/160/170 jeweils lokal und
direkt zentral. Beide Repeat-Einstiege setzen und verifizieren den Level vor
jeder achtspaltigen Originalfixture. Erwartet je Workflowlauf: zwölf Kontexte,
24 Deploys und36 Principalgegenproben. Ein Level- oder Fixturefehler verhindert
den Erfolgsmarker und weitere Levels. Reale Head-/Main-Jobergebnisse sind die
native Evidenz; sechs source-extracted Offlinefälle allein sind kein SQL-Nachweis.
Die bisherige Stellung außerhalb der CL-Schleife belegte nur den Image-Default,
keine vollständige Repeat-CL-Matrix. Bestehende Windows- und alte Linuxnachweise
werden weder wiederholt noch rückwirkend aufgewertet. Weitere Callerrechte,
nichtleere Grants und harte Recovery bleiben eigene Verträge.


| Bereich | Nachweis |
|---|---|
| Öffentlicher Vertrag | Parameter, Help, TVF- und SVF-Signatur, sichere Statusspalten |
| Persistenz | erste Anforderung, wiederholte Anforderung, monotone Speicherung |
| Context und Transaktion | implizite aktuelle ExecutionId, fehlender Context, aktive und uncommittable Caller-Transaktion |
| Konkurrenz | parallele Anforderungen derselben ExecutionId ergeben genau eine Statuszeile |
| Lifecycle | Dependency-, Kollisions-, Redeploy-, Local-, Central- und Uninstall-Vertrag |
| Befüllter 1.0.0-Repeat | Zwei echte Deploys in Local/Central; alle acht Spalten einschließlich Principal-ID/SID/Erzeugungsbytes und Rowversion, UTC-Auditwerte, NULL/Leerstring/Unicode/Padding, Objekt-IDs und ausgewählte Katalogmetadaten einschließlich vorhandener Permissions, eigener Annotationen und nichtleerer Tabellen-/Spalten-MS_Description; Status-API danach read-only |
| Isolierte Principalgegenproben | Drei zurückgerollte Datenänderungen mit tatsächlichem52743/1 aus dem originalen Capture-/Assert-Paar; automatische Rowversiondifferenz nur im temporären Negativsnapshot kompensiert, damit sie keine ausgelassene Principalspalte verdeckt |
| Plattformmatrix | SQL Server 2019, 2022 und 2025 auf Linux und Windows; CU nur bei patchabhängigem Test |

Die [vollständige achtspaltige Windows-Repeat-Matrix](README.md#vollständige-achtspaltige-windows-repeat-matrix-vom-2026-11-06)
bestand auf SQL2019/CU32 CL150, SQL2022/CU26 CL150/160 und SQL2025/CU8
CL150/160/170 jeweils lokal und direkt zentral: zwölf Kontexte,
24 Deploywiederholungen, 36 isolierte Gegenproben sowie sechs vollständige
Koordinatoren und sechs frische Audits. Das ist keine vollständige neue
API-/Rechte-/Transport- oder Unterbrechungsqualifikation.

Der historische [Windows-Teilnachweis](README.md#windows-repeat-vom-2026-11-06-elf-abgegrenzte-kontexte)
belegt elf Kontexte des vorherigen fünfspaltigen Tests; Windows2019 lokal
bleibt fehlgeschlagen und separat bereinigt. Der [erweiterte achtspaltige Test](README.md#aktueller-repeat-mit-vollständiger-principalbindung)
wurde in der späteren Restwelle eigens ausgeführt; bestehende Nachweise
erweitern ihren Datenumfang nicht rückwirkend.

Der befüllte Repeat ist unabhängig vom historischen Lifecycle zu
qualifizieren. Er verändert weder Source noch Deployment, erzeugt keine
Benutzergrants und belegt keine tatsächlichen Minimalrechte. Die neue
Windows-Repeat-Matrix ist oben geschlossen; weitere Linux-Repeat-CLs und
historische Versionsübergänge bleiben ohne
eigene erfolgreiche Evidenz `not executed`. Das Fixture benötigt eine eigene
leere Installationsdatenbank; sein Adapter verantwortet Cleanup auch nach
SQLCMD-Fehlerabbruch. Einzelheiten und Ausführungsgrenzen stehen in
[Tests/README](README.md#befüllter-versionsgleicher-repeat).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199`
- Scope: Commit fac18e590f854a26364e5f498c6a2b5d330a95c2: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf SQL Server 2019/150, 2022/160, 2025/170 Linux; alle fünf Spalten mit Rowversionbytes, synthetische Audit-/NULL-/Textwerte, ausgewählter Katalog und eigene typisierte Annotationen inklusive MS_Description erhalten. Vorhandene API-, Concurrency-, Consumer- und Uninstallfälle sowie eigene CI-Bereinigung bestanden. Keine neuen Windows-Repeats, weiteren Repeat-CLs, nichtleeren Benutzergrants, echten Minimalrechte oder historischen Schemaübergänge qualifiziert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
