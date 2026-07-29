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
| `Deploy.sql` | parametergesteuerte Erstinstallation, Upgrade und Wiederholungsinstallation |
| `Uninstall.sql` | vollständige Entfernung der Modulobjekte unter Beachtung abhängiger Module |

`Deploy.sql` erhält mindestens den Modus `local` oder `central`. Beide Modi verwenden dieselbe kanonische Fachimplementierung.

Jedes Release führt ein versioniertes Objektmanifest. Daraus gelten folgende Regeln:

- Objekte des bekannten installierten Releases dürfen unabhängig von lokalen Änderungen aktualisiert werden.
- Bei erneuter Installation derselben Version werden alle Framework-Objekte erneut deployed.
- Nur Objekte, die im installierten Release enthalten waren und im Zielrelease fehlen, dürfen im regulären Deployment entfernt werden.
- Ein im Zielrelease neuer Objektname darf kein vorhandenes frameworkfremdes Objekt überschreiben.
- Frameworkfremde Objekte werden weder geändert noch gelöscht.
- Source-Hashes sind diagnostische Information und kein Deployment-Gate.

Interne Framework-Tabellen verwenden explizite versionierte Migrationen. Kontrolliertes `TRUNCATE`/`DELETE`/`INSERT` ist nur für eindeutig Toolbelt-eigene interne Inhalte zulässig; unbekannte oder fachliche Daten werden nicht pauschal ersetzt.

Preflight, Manifestvergleich und Deployment-Plan entstehen vor der ersten Mutation. Die Transaktion beginnt unmittelbar vor der ersten Änderung, umfasst die zusammengehörigen DDL-/DML-Schritte sowie die abschließende Versionsmarkierung und wird danach sofort beendet. Eine installationsbezogene Application Lock verhindert parallele Mutationen desselben Moduls.

Uninstall entfernt keine fremden Objekte oder Nutzerdaten.

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
