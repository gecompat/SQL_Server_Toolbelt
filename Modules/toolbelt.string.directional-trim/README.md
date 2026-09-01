# Directional TRIM Compatibility

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w1-portable-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger W1-Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
