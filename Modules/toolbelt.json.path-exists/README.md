# JSON Path Exists

Nachqualifikation 2026-10-19: Der vollständige aktuelle Moduladapter bestand auf SQL Server 2019/2022/2025 unter Windows und Linux. Runtime: `validated`; Release: `unreleased`. Die folgenden datierten älteren Abschnitte beschreiben ihren damaligen Stand. Details: [V0c-Gatebericht](../../Tests/V0C_RELEASE_GATE_STATUS.md).

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Das Modul implementiert den freigegebenen Pfadprüfungs-Slice von
`TC-2026-009` für SQL Server 2019 und neuer.

```sql
DECLARE @Document nvarchar(max) =
    N'{"info":{"addresses":[{"town":"Wien"},{"town":"Graz"}]}}';

SELECT path_result.PathExists
FROM toolbelt_json.TVF_JsonPathExists
     (@Document, N'$.info.addresses[*].town') AS path_result;
-- 1
```

`PathExists` entspricht dem Rückgabemodell der nativen Funktion:

- `1`, wenn der Pfad mindestens einen Wert einschließlich JSON `null` findet;
- `0`, wenn der Pfad fehlt, das JSON ungültig ist oder der Pfad nicht zum
  unterstützten V1-Vertrag gehört;
- SQL `NULL`, wenn `@Json` oder `@Path` SQL `NULL` ist.

Unterstützt werden Root `$`, optionale Modi `lax`/`strict`,
case-sensitive Property-Schritte, quotierte JSON-Schlüssel, nullbasierte
Array-Indizes und `[*]`. Die SQL-Server-2025-Preview-Erweiterungen
Array-Range, Indexliste und `last` sind nicht Teil des portablen V1-Vertrags.

Die zustandsbehaftete Pfadtraversierung benötigt eine Multi-statement TVF.
Ein zusätzlicher Scalar-Wrapper wird in Version 1 bewusst nicht angeboten:
Er würde keine Inline-TVF-Alternative besitzen und könnte weitere
Parallelität verhindern. Für mengenorientierte Aufrufe ist `APPLY` die
kanonische API.

Details:
[TVF_JsonPathExists](./Documentation/TVF_JsonPathExists.md),
[Moduldesign](../../Documentation/Architecture/JSON_PATH_EXISTS_MODULE_DESIGN.md).

Aktuelle Evidenz:
[Run 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943)
– SQL Server 2025 Linux mit Compatibility Levels 150/160/170 erfolgreich;
der vollständige Adapter ist seit 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Die Windows-Matrix ist seit der Nachqualifikation
vom 2026-10-19 erfolgreich belegt. Modulstatus nach Nachqualifikation 2026-10-19: `validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger lokaler/zentraler Moduladapter, versionsabhängige CL150/160/170, Lifecycle und Uninstall; Security-Budgets, NULL/Limit, Minimalrechte und zentrale Status-API
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Freigegebene Security-Härtung 2026-10-15

SC-022: TVF_JsonPathExistsStatus unterscheidet FOUND/MISSING/INVALID/SQL_NULL/LIMIT. Grenzen:16 MiB Input, lexikalische Tiefe128 vor nativem Parser,128 Segmente,10000 Frontierwerte und64 MiB kumulative Parserinputs. Legacy PathExists ist bei LIMIT NULL statt0. MSTVF-Statuskern, keine partielle Frontierausgabe.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

Aktueller Securitystand nach der Nachqualifikation vom 2026-10-19: `validated`,
`unreleased`. Die neuen Verträge, die vollständige Fachmatrix, lokale
Minimalrechte und zentrale Statusaufrufe sind auf allen sechs Zielen geprüft.
