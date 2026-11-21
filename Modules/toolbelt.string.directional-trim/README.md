# Directional TRIM Compatibility


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.

Der aktuelle Quellstand vom 2026-11-21 enthält gezielte funktionale Korrekturen
für die bei der Skillprüfung gefundenen Randfälle. Der Modulstatus ist bis zu
den [neuen nativen Gegenproben](../../Scripts/Install/Tests/QUALIFICATION.md#aktuelle-funktionskorrekturen-native-gegenproben-offen)
teilweise validiert. Historische Nachweise bleiben an ihre ursprünglichen
Artefakte gebunden. Die vollständigen Usage-Skills stehen in der ausgelieferten
Funktions-DDL und unter [Metadata/UsageSkills](../../Metadata/UsageSkills/README.md);
eine Skillbeschreibung attestiert weder Installation noch Aufruferrechte.


Aktuelle [Utility-Callerrechte](../../Releases/1.0.0/UTILITY-CALLER-QUALIFICATION.md): einzelne SELECT-/EXECUTE-Grants für16 öffentliche Funktionen lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen; andere APIs, direkte Dependencies und Helper bleiben unzugänglich. Frühere Voll-, Last-, Client- und Lifecycle-Nachweise behalten ihren Scope; keine Statusaufwertung.

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Das Modul setzt `LEADING`, `TRAILING` und `BOTH` als zwei kanonische inline TVFs um. `TVF_TrimDirectionalVarchar` und `TVF_TrimDirectionalNvarchar` erhalten ihren jeweiligen Rückgabetyp und sind für `CROSS APPLY` vorgesehen.

```sql
SELECT trimmed.Value
FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'..Contoso..', N'.', 'LEADING') AS trimmed;
```

`@Direction` akzeptiert ausschließlich `LEADING`, `TRAILING` oder `BOTH`; andere Werte erzeugen einen unveränderten Enginefehler. `NULL` für Text oder Zeichensatz liefert `NULL`, ein leerer Zeichensatz lässt den Text unverändert. `NCHAR(0)` wird nicht als trimmbares Zeichen behandelt.

Weitere Details: [Unicode-Objektvertrag](./Documentation/TVF_TrimDirectionalNvarchar.md), [varchar-Objektvertrag](./Documentation/TVF_TrimDirectionalVarchar.md) und [Moduldesign](../../Documentation/Architecture/DIRECTIONAL_TRIM_MODULE_DESIGN.md).

Aktuelle Evidenz: [Run 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399) sowie der lokale Lauf vom 2026-08-29 – vollständiger Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich; Modulstatus `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; lokales und zentrales Deployment, CI-/CS-/UTF-8-Collations, leere Trim-Menge, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
