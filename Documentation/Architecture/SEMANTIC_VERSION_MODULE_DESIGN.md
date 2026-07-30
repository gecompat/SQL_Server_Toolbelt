# Design: Semantic Version Validation

Der Parser implementiert die strikte ASCII-Grammatik von Semantic Versioning
2.0.0 als zustandsbasierte Multi-statement TVF. Core-Zahlen bleiben Strings;
Länge und binäre Ziffernfolge vermeiden numerischen Overflow.

Version `1.1.0` stellt Comparator und Sort Key jeweils als inline TVF und als
SVF-Wrapper bereit. Die inline TVFs sind die kanonischen relationalen Kerne;
die nicht schemagebundenen SVFs delegieren vollständig an sie. Dadurch können
Wiederholungs- und Upgrade-Deployments die kanonischen TVF-Kerne ersetzen.
Beide Kerne hängen ausschließlich vom Parser ab. Der Key codiert
Core-Komponenten mit Festbreiten-Längenpräfixen sowie Pre-release-Identifier
mit getrennten numerischen/alphanumerischen Markern. Release steht über
Pre-release; Build Metadata wird ignoriert.

Für mengenorientierte Verwendung ist `OUTER APPLY` beziehungsweise
`CROSS APPLY` auf die inline TVFs zu bevorzugen. Ein konkreter
Parallelitätsvorteil wird nur anhand reproduzierbarer Ausführungspläne
behauptet.

Lokales und zentrales Deployment folgen dem allgemeinen Lifecycle-Vertrag.
Der Modulfehlerbereich ist `51080–51089`. SQL Server 2025 Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich; physische
SQL-Server-2019-/2022- und Windows-Läufe bleiben offen.
