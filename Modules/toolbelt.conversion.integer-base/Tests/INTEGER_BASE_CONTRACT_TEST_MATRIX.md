# Integer-Base Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Fälle | Stand |
|---|---|---|
| Signatur | `bigint`, `varchar(93)`, `varchar(65)` | vorhanden |
| Alphabet | Länge 2/93, druckbares ASCII, binär eindeutig, kein `-` | vorhanden |
| Darstellung | Null, Vorzeichen, keine führenden Nullen, kein `+`/`-0` | vorhanden |
| Basen | 2, 8, 10, 16, 36, 62 und 93 | vorhanden |
| Grenzen | vollständiger `bigint`-Bereich und Decode-Overflow | vorhanden |
| Roundtrip | positive, negative und Grenzwerte | vorhanden |
| API-Parität | SVF und inline TVF, exakt eine Zeile, `OUTER APPLY` | vorhanden |
| Upgrade | `1.0.0` auf `1.1.0`, Wiederholung, Kollision | vorhanden |
| Lifecycle | lokal, zentral, Drift, Kollision, Uninstall | vorhanden |
| SQL Server 2025 Linux 150/160/170 | Version `1.1.0` | `success` |
| SQL Server 2019/2022 und Windows | Release-Matrix | `not executed` |

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860
