# Directional TRIM Compatibility

Das Modul setzt `LEADING`, `TRAILING` und `BOTH` als zwei kanonische inline TVFs um. `TVF_TrimDirectionalVarchar` und `TVF_TrimDirectionalNvarchar` erhalten ihren jeweiligen Rückgabetyp und sind für `CROSS APPLY` vorgesehen.

```sql
SELECT trimmed.Value
FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'..Contoso..', N'.', 'LEADING') AS trimmed;
```

`@Direction` akzeptiert ausschließlich `LEADING`, `TRAILING` oder `BOTH`; andere Werte erzeugen einen unveränderten Enginefehler. `NULL` für Text oder Zeichensatz liefert `NULL`, ein leerer Zeichensatz lässt den Text unverändert. `NCHAR(0)` wird nicht als trimmbares Zeichen behandelt.

Weitere Details: [Unicode-Objektvertrag](./Documentation/TVF_TrimDirectionalNvarchar.md), [varchar-Objektvertrag](./Documentation/TVF_TrimDirectionalVarchar.md) und [Moduldesign](../../Documentation/Architecture/DIRECTIONAL_TRIM_MODULE_DESIGN.md).

Aktuelle Evidenz: [Run 30552721606](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30552721606) – SQL Server 2025 Linux mit Compatibility Levels 150/160/170 erfolgreich; Modulstatus `partially validated`.
