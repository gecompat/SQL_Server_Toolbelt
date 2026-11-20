# Maßgebliche Usage-Skillquellen

Je katalogisiertem Toolbelt-Objekt steht hier eine redaktionelle Markdown-Datei
unter seinem Schema. Das Frontmatter enthält JSON-kompatible YAML-Werte, damit
Unicode, Defaults, boolesche Angaben und Parameterlisten ohne zusätzliche
Runtimebibliothek eindeutig gelesen werden. Die Abschnitte sind im
[Vertrag](../../Backlog/OBJECT_USAGE_SKILLS.md) festgelegt.

Die Dateien enthalten quellgeprüfte Prototypen und ausdrücklich ungeprüfte
Migrationsentwürfe aus den bisherigen öffentlichen Beschreibungen. Maßgeblich
ist jeweils `review_status`; `draft` darf nicht ausgeliefert werden. Unbekannte
Parametersemantik bleibt im Entwurf ausdrücklich ungeklärt. Die Dateien
belegen noch keine vollständige Umsetzung oder native Integration.

Das aktuelle vollständige Inventar wird aus den Moduldeklarationen ermittelt,
einschließlich technischer Assemblies, bisher fehlender Filesystem-Helfer und
der freigegebenen neuen View. Fehlende oder ungeprüfte Quellen werden vom
Generator zurückgewiesen und nicht als fertige Beschreibungen ausgegeben.

```powershell
python -B -m unittest discover -s Tests/Metadata
python -B Scripts/Metadata/generate_usage_skills.py
```

Der zweite Aufruf muss bis zur vollständigen Abdeckung fehlschlagen und erzeugt
keinen Teilinstaller. `--output` schreibt erst nach vollständiger Abnahme eine
neue SQL-Datei. Bestehende Dateien werden nicht überschrieben.

Skilltexte beschreiben bekannte Quellen. Sie attestieren weder Installation,
identische vorhandene Definitionen noch Aufruferrechte und erteilen keine
Ausführungsautorität. Private Pakete, Serverdaten, Zugangsdaten und echte
Runtimeausgaben gehören nicht in diese Dateien.
