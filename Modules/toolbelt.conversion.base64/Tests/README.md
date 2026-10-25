# Base64-Testevidenz

Aktuelle [Callerrechte-Qualifikation](../../../Releases/1.0.0/CONVERSION-CALLER-QUALIFICATION.md): einzelne SELECT-Grants für TVFs und EXECUTE-Grants für Scalarwrapper, lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen. Die ältere pauschale SELECT-/REFERENCES-Formulierung im Manifest ist für Scalarwrapper veraltet; ihr gebundener Metadaten-/Paketrefresh bleibt separat offen. Andere Fach-/Lifecycle-/CrossDB-Gates und Modulstatus werden dadurch nicht erweitert.

Lastqualifikation 2026-10-19: Der vollständige Moduladapter einschließlich Pflicht-Lastfall (exakter 4-MiB-Roundtrip mit NULL-, Längen- und Inhaltsorakeln) bestand auf SQL Server 2025 Linux/latest CL170. Zusammen mit der unveränderten Windows-/Linux-Fachmatrix gilt `validated`; Release bleibt `unreleased`. Optionale Laufzeitmessungen: `not executed`. [Aktuelle Abnahme](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

Abnahmeänderung 2026-10-19: Große Lastfälle mit Ergebnisprüfung sind Pflicht; Laufzeitmessungen sind optional und kein Validierungs- oder Release-Gate. Maßgeblich ist [DEC-2026-036](../../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen). Ältere datierte Aussagen zur verpflichtenden Performance-Abnahme beschreiben den damaligen Vertrag.

Historischer Zwischenstand vor der Abnahmeänderung am 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Die abgegrenzte Performance-Abnahme bleibt offen; Runtime: `partially validated`, Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../../Tests/V0C_RELEASE_GATE_STATUS.md).

## 2026-10-09 – Leere Decode-Eingabe nach dem ersten PR311-Headlauf

Die Quellenkorrektur für den bestehenden Decoder sieht vor: Eine Nicht-NULL-
Eingabe mit leerer kanonischer Base64-Zeichenfolge ergibt `0x`; `NULL` bleibt
`NULL`. Der SVF-Wrapper verwendet denselben TVF-Kern. API, Normalisierung und
Fehlervertrag für ungültige Eingaben bleiben unverändert.

Der erste PR311-Headlauf scheiterte im Runtime-Contract mit Fehlerkategorie
`52303`. Die tatsächlich auslösende Eingabe und Laufzeitursache sind nicht
gemessen. Die neue Quellenkorrektur ist **SOURCE_ONLY** und noch nicht
runtimequalifiziert; der fehlgeschlagene Lauf ist kein PASS-Nachweis.
Frühere Quellenstände, datierte Matrixnachweise und generierte Evidenz bleiben
historisch erhalten. Modulversion `1.1.0`, `partially validated` und `unreleased`
bleiben unverändert; keine neue Matrix-, Performance- oder Releasezusage.

## 2026-10-09 – Quellenstand der sieben RFC-Orakel

Der Quellenkandidat schließt eine Testorakellücke in den sieben vorhandenen
RFC-4648-Vektoren: Positive SVF-/TVF-Wertprüfungen müssen unerwartetes NULL
abweisen; jede direkt aufgenommene Encode-/Decode-TVF muss pro Fall genau eine
Ergebniszeile liefern, auch bei fehlenden oder zusätzlichen Zeilen. Ein
CROSS-APPLY-Zeilenverlust darf keinen positiven Fall verdecken. Die sieben
Eingaben und Sollwerte, NULL-Eingabe-/OUTER-APPLY-Orakel und übrigen Fälle bleiben
unverändert; keine neuen Vektoren oder Produktkorrektur.

Quellenstand **SOURCE_ONLY**; neue verschärfte Orakel **NOT_EXECUTED**,
Quellenreview und Runtimequalifikation stehen noch aus. Belegt ist eine
Testorakellücke, kein gemessener Produktfehler. Datierte Matrixnachweise und
generierte Evidenz behalten ihren ursprünglichen Scope. Modulversion `1.1.0`,
`partially validated` und `unreleased` bleiben unverändert; breitere
Large-LOB-Performance-Evidenz bleibt offen.

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; breitere Large-LOB-Performance-Evidenz bleibt offen. Der Modulstatus bleibt `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Evidenzhistorie

Die Einschränkungen der datierten Einträge beschreiben den jeweiligen
damaligen Stand. Die physischen Windows-/Linux-Plattformlücken für SQL Server
2019, 2022 und 2025 wurden durch den im Modulmanifest dokumentierten Nachweis
vom 2026-09-01 geschlossen. Die breitere Large-LOB-Performance-Evidenz bleibt
offen.

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |
| 2026-07-30 | [Run 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837) | Version `1.1.0`; Compatibility 150/160/170; SVF-/TVF-Parität, `APPLY`, Fehler, Größen bis 1 MiB, Upgrade, lokale/zentrale Nutzung, Kollision und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-07-29 | [Base64 Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/base64-runtime.yml) | Workflow, statische und Runtime-Contract-Artefakte angelegt | `not executed` | Ein vorhandener Workflow ist kein Runtime-Nachweis |
| 2026-07-29 | [Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) | SQL Server 2025 Linux; Compatibility 150/160/170; RFC-4648, Fehler, Größen bis 1 MiB, lokale/zentrale Nutzung und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |

Der Modulstatus ist damit `partially validated`, nicht vollständig
`validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: SQL Server 2025 Linux/latest CL170; vollständiger aktueller Moduladapter einschließlich Pflicht-Lastfall: exakter 4-MiB-Roundtrip mit NULL-, Längen- und Inhaltsorakeln; lokales/zentral Deploy, Lifecycle, Uninstall und frischer eigener Cleanupaudit erfolgreich; ergänzt die unveränderte Sechs-Ziel-Fachmatrix. Laufzeitmessung optional und nicht ausgeführt gemäß DEC-2026-036
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
