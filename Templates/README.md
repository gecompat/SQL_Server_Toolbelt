# Templates – SQL Server Toolbelt

Dieses Verzeichnis enthält nicht ausführbare Vorlagen für neue Module und SQL-Objekte.

## Verwendung

1. Kopiere `Templates/Module/` in einen neuen Modulordner unter `Modules/`.
2. Ersetze alle `{{Platzhalter}}`.
3. Wähle für jedes Objekt die passende Source- und Dokumentationsvorlage.
4. Entferne nicht benötigte Vorlagen.
5. Benenne `.sql.template` erst nach vollständiger Implementierung, Prüfung und Dokumentation in `.sql` um.

Für Beispiele, Ergebnisdeutung und gezielte technische Erklärungen gilt der
[Dokumentationsstandard](../Documentation/Standards/CODE_DOCUMENTATION.md#objektreferenz-und-beispiele).
Fülle die Ergebnisdeutung passend zum konkreten Beispiel aus. Erkläre den
Implementierungsweg nur, wenn er nicht offensichtlich ist; bei einem
gemeinsamen Kern genügt ein gezielter Link. Entferne den optionalen
Technikabschnitt bei trivialen Objekten sowie alle Bearbeitungshinweise.
Die Vorlagen verlangen keinen zusätzlichen Grundlagenkurs oder neue SQL-Tests
allein für die Dokumentation.

## Objekttypspezifische Vorlagen

| Typ | Source | Dokumentation |
|---|---|---|
| USP mit fachlichem Resultset | `Module/Source/USP_Resultset.sql.template` | `Module/Documentation/USP_Resultset.md.template` |
| Infrastruktur-USP ohne eigenes Resultset | `Module/Source/USP_Infrastructure.sql.template` | `Module/Documentation/USP_Infrastructure.md.template` |
| Table-valued Function | `Module/Source/TVF.sql.template` | `Module/Documentation/TVF.md.template` |
| Scalar-valued Function | `Module/Source/SVF.sql.template` | `Module/Documentation/SVF.md.template` |
| View | `Module/Source/VW.sql.template` | `Module/Documentation/VW.md.template` |

Die generische Verwendung eines USP-Vertrags für TVFs, SVFs oder Views ist unzulässig. Infrastruktur-USPs erhalten keinen bedeutungslosen `@ResultTable`-Parameter.
