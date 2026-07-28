# Deployment-Modell

## Deployment-Modi

SQL Server Toolbelt unterscheidet zwei gleichwertige Modi, soweit eine Capability beide technisch unterstützt.

### Lokale Installation

- Modul wird direkt in einer fachlichen Zieldatenbank installiert.
- Keine Abhängigkeit von einer separaten Toolbelt-Datenbank.
- Erforderlich oder bevorzugt bei `SCHEMABINDING`, computed columns, Constraints, lokalen Types oder strikten Datenbankgrenzen.

### Zentrale Installation

- Modul wird in einer dedizierten Toolbelt-Datenbank installiert.
- Andere Datenbanken verwenden Objekte über dreiteilige Namen, lokale Wrapper oder Synonyme.
- Synonyme werden in der konsumierenden Datenbank angelegt und ersetzen keine Berechtigungs- oder Zielobjektprüfung.
- Cross-database-Verwendung ist Designziel, keine Garantie.

## Kanonische Implementierung

Lokale und zentrale Modi dürfen keine voneinander abweichende Fachlogik enthalten. Deployment-Adapter, Wrapper oder Synonyme verwenden denselben kanonischen Kern.

## Capability-Kennzeichnung

Ein Modulmanifest kennzeichnet explizit:

- `local`;
- `central`;
- `central_with_synonyms`;
- `local_required`;
- `central_preferred`.

Nicht unterstützte Modi werden begründet; sie werden nicht stillschweigend als `not applicable` gesetzt.

## Dependencies

Abhängigkeiten liegen standardmäßig in derselben Installationsdatenbank. Cross-database-Dependencies müssen im Manifest ausdrücklich Ort, Datenbankparameter und Mindestversion deklarieren.

Vor der ersten Mutation prüft der Installer:

- SQL-Server-Version und Edition;
- Betriebssystem und Provider;
- Compatibility Level, soweit relevant;
- Modulabhängigkeiten und Versionen;
- Installationsort und Deployment-Modus;
- erforderliche Rechte;
- Collation- und Plattformgrenzen.

Ein gescheiterter Preflight führt zu verständlicher Meldung und vollständigem Abbruch ohne Teilinstallation.

## Lifecycle-Artefakte

| Artefakt | Zweck |
|---|---|
| `Install.sql` | Erstinstallation, Preflight und kontrollierte Registrierung |
| `Upgrade.sql` | Upgrade von bekannten Vorgängerversionen |
| `Uninstall.sql` | vollständige Entfernung der Modulobjekte unter Beachtung abhängiger Module |

Install und Upgrade müssen kontrolliert wiederholbar sein. Uninstall entfernt keine fremden Objekte oder Nutzerdaten.

## Grundmatrix

| Plattform | Grundstatus |
|---|---|
| SQL Server 2019 Windows | Zielplattform |
| SQL Server 2022 Windows | Zielplattform |
| SQL Server 2025 Windows | Zielplattform |
| SQL Server 2019 Linux | Zielplattform, modulabhängig |
| SQL Server 2022 Linux | Zielplattform, modulabhängig |
| SQL Server 2025 Linux | Zielplattform, modulabhängig |
| Azure SQL Database | nicht automatisch unterstützt |
| Azure SQL Managed Instance | nicht automatisch unterstützt |

Die tatsächliche Unterstützung wird je Modul, Deployment-Modus und Provider validiert.
