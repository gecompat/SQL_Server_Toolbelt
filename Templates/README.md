# Templates – SQL Server Toolbelt

Dieses Verzeichnis enthält nicht ausführbare Vorlagen für neue Module und SQL-Objekte.

## Verwendung

1. Kopiere `Templates/Module/` in einen neuen Modulordner unter `Modules/`.
2. Ersetze alle `{{Platzhalter}}`.
3. Wähle für jedes Objekt die passende Source- und Dokumentationsvorlage.
4. Entferne nicht benötigte Vorlagen.
5. Benenne `.sql.template` erst nach vollständiger Implementierung, Prüfung und Dokumentation in `.sql` um.

## Objekttypspezifische Vorlagen

| Typ | Source | Dokumentation |
|---|---|---|
| Stored Procedure | `Module/Source/USP.sql.template` | `Module/Documentation/USP.md.template` |
| Table-valued Function | `Module/Source/TVF.sql.template` | `Module/Documentation/TVF.md.template` |
| Scalar-valued Function | `Module/Source/SVF.sql.template` | `Module/Documentation/SVF.md.template` |
| View | `Module/Source/VW.sql.template` | `Module/Documentation/VW.md.template` |

Die generische Verwendung eines USP-Vertrags für TVFs, SVFs oder Views ist unzulässig. Jede Vorlage enthält nur die für ihren Objekttyp geltenden Vertragsabschnitte.
