# JSON Path Exists

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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
