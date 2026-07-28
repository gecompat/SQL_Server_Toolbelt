# Deployment-Modell

## Deployment-Modi

SQL Server Toolbelt unterstützt zwei gleichwertige Deployment-Modi:

### Lokale Installation (Zieldatenbank)

- Module werden direkt in der Zieldatenbank installiert.
- Keine Abhängigkeit von einer separaten Toolbelt-Datenbank.
- Geeignet für isolierte Umgebungen oder einzelne Datenbanken.

### Zentrale Installation (Toolbelt-Datenbank)

- Module werden in einer dedizierten Toolbelt-Datenbank installiert.
- Andere Datenbanken können die Toolbelt-Objekte cross-database verwenden.
- Cross-database-Verwendung ist Designziel, keine Garantie.
- Synonyme oder lokale Wrapper sind zulässig; ihre Grenzen müssen dokumentiert sein.

## Keine divergierenden Implementierungen

Es darf keine unterschiedlichen lokalen und zentralen Fachimplementierungen geben. Die kanonische Implementierung existiert genau einmal; Synonyme und Wrapper verweisen darauf.

## Lifecycle-Artefakte

Jedes Modul besitzt:

| Artefakt | Zweck |
|---|---|
| `Install.sql` | Erstinstallation; idempotent; Preflight |
| `Upgrade.sql` | Versionsupgrade; Preflight; kein Datenverlust ohne Warnung |
| `Uninstall.sql` | Vollständige Entfernung; kein automatisches Löschen von Nutzerdaten |

## Preflight-Anforderungen

Vor der ersten Mutation prüfen:
- SQL-Server-Version und -Edition
- Betriebssystem (Windows/Linux)
- Vorhandensein und Version abhängiger Module
- Erforderliche Rechte
- Collation-Kompatibilität

Bei gescheitertem Preflight: klare Fehlermeldung, vollständiger Abbruch, keine Mutation.

## Unterstützte Plattformen

| Plattform | Status |
|---|---|
| SQL Server 2019 (Windows) | Zielplattform |
| SQL Server 2022 (Windows) | Zielplattform |
| SQL Server 2019 (Linux) | Zielplattform |
| SQL Server 2022 (Linux) | Zielplattform |
| Azure SQL Database | Nicht automatisch; pro Modul prüfen |
| Azure SQL Managed Instance | Nicht automatisch; pro Modul prüfen |

## CI und Tests

Noch keine Runtime-CI oder große Actions-Matrix. Anforderungen dokumentiert in [TEST_AND_VALIDATION_POLICY.md](../Standards/TEST_AND_VALIDATION_POLICY.md).
