# Design: Semantic Version Validation

Der Parser implementiert die strikte ASCII-Grammatik von Semantic Versioning
2.0.0 als zustandsbasierte Multi-statement TVF. Core-Zahlen bleiben Strings;
Länge und binäre Ziffernfolge vermeiden numerischen Overflow.

Comparator und Sort Key hängen ausschließlich vom Parser ab. Der Key codiert
Core-Komponenten mit Festbreiten-Längenpräfixen sowie Pre-release-Identifier
mit getrennten numerischen/alphanumerischen Markern. Release steht über
Pre-release; Build Metadata wird ignoriert.

Lokales und zentrales Deployment folgen dem allgemeinen Lifecycle-Vertrag.
Der Modulfehlerbereich ist `51080–51089`. SQL Server 2025 Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich; physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben offen.
