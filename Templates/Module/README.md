# Templates – SQL Server Toolbelt

Dieses Verzeichnis enthält Vorlagen für neue Module und Objekte.

## Verwendung

1. Benötigten Ordner aus `Templates/Module/` kopieren.
2. Platzhalter (`{{ModuleName}}`, `{{SchemaName}}`, usw.) ersetzen.
3. Alle `.sql.template`-Dateien sind **nicht ausführbar**; `.sql` nicht anfügen ohne vollständige Implementierung.

## Inhalt

| Vorlage | Beschreibung |
|---|---|
| `Module/README.md` | Modul-README-Vorlage |
| `Module/module.yaml.template` | Modul-Manifest-Vorlage |
| `Module/Documentation/Module.md.template` | Modul-Dokumentation |
| `Module/Documentation/PublicObject.md.template` | Dokumentation eines öffentlichen Objekts |
| `Module/Source/Object.sql.template` | SQL-Objekt-Vorlage (nicht ausführbar) |
| `Module/Deployment/Install.sql.template` | Install-Skript-Vorlage (nicht ausführbar) |
| `Module/Deployment/Upgrade.sql.template` | Upgrade-Skript-Vorlage (nicht ausführbar) |
| `Module/Deployment/Uninstall.sql.template` | Uninstall-Skript-Vorlage (nicht ausführbar) |
| `Module/Tests/Static/README.md` | Statische Testdokumentation |
| `Module/Tests/Runtime/README.md` | Runtime-Testdokumentation |
| `Module/Examples/README.md` | Beispiel-Vorlage |
