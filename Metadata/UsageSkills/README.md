# Kanonische Usage-Skills

Je katalogisiertem Toolbelt-Objekt liegt hier eine redaktionell geprüfte
Markdown-Datei mit versioniertem YAML-Frontmatter. Die Verzeichnisse folgen
den SQL-Schemas. Schemafreie Assemblies stehen unter `_assemblies` und
verwenden `schema_name: ""`. Das Inventar stammt aus den Moduldeklarationen.
Der [Vertrag](../../Backlog/OBJECT_USAGE_SKILLS.md) legt Identität, Abschnitte
und Parameterfelder fest.

Bei Prozeduren bedeutet `argument_required`, dass SQL keinen Default für
den Parameter kennt. Funktionen erwarten jede Argumentposition. Ein deklarierter
Funktionsdefault wird an dieser Position über `DEFAULT` verwendet.
`business_required` und `nullable` beschreiben die fachliche Validierung.

Die 257 Quellen decken das vollständige Inventar einschließlich technischer
Objekte und der [Skill-View](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md)
ab. Prüfe Änderungen gegen die Implementierung. Der Generator lehnt fehlende,
doppelte sowie ungeprüfte Quellen ab. Verwende synthetische Beispiele.

- Die View enthält pro Objekt den vollständigen Skill einschließlich Frontmatter.
- DDL-Kommentare zwischen `OBJECT_USAGE_SKILL:BEGIN` und
  `OBJECT_USAGE_SKILL:END` tragen denselben Text. Bei Assemblies fügt der
  gemeinsame Installer den Kommentar in die erzeugte DDL ein.
- Prozeduren geben den Skill bei `@Hilfe = 1` vor dem Fachpfad aus. Die
  [Prozedurhilfe](../../Documentation/Standards/USP_CONTRACT.md#2-hilfevertrag)
  beschreibt das Resultset und vorhandene Standardhilfe.

Nach der redaktionellen Änderung die betroffene DDL- und Hilfeprojektion
aktualisieren. Für die konstante View stehen folgende Befehle zur Verfügung.

```powershell
python -B Scripts/Metadata/generate_usage_skills.py --write
python -B Scripts/Metadata/generate_usage_skills.py --check
python -B -m unittest discover -s Tests/Metadata
```

Ein Aufruf ohne Schalter prüft das Inventar. `--output` liefert eine zusätzliche
SQL-Datei an einem neuen Pfad. Die statischen Prüfungen vergleichen den
vollständigen Text der Projektionen. Native Hilfe-, Callerzustands- und
Installationsnachweise werden separat geführt.
