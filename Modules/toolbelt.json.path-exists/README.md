# JSON Path Exists

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
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich. Windows-Läufe
bleiben `not executed`. Modulstatus: `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Pfad-, JSON-, NULL-, Wildcard-, BIN2-, native Paritäts-, Kollisions-, Lifecycle- und Uninstall-Verträge
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
