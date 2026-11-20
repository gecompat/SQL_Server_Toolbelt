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

## Aktueller Funktionsinstaller

Der [gemeinsame Quellinstaller](../../Scripts/Install/README.md) ist der normale
SQLCMD-freie Weg. Er verwendet Manifestabhängigkeiten beim Build und die
benötigten Objektsignaturen zur Laufzeit. Es gibt keine installierte Versions-,
Ownership- oder Modusregistry. Die Engine prüft die ausgeführten CREATE-Rechte;
der Installer verändert weder bestehende Objekte noch Rechte oder Konfiguration.
Bei Teilfehlern können zuvor erstellte Objekte bestehen bleiben. Dieser
create-only-Weg bietet kein Upgrade oder Uninstall; die nachfolgenden
Lifecycle-Regeln gelten ausschließlich für den klassischen markerbasierten Weg.
Historische Releaseartefakte behalten ihren ursprünglichen Vertrag.

## Einheitlicher aktueller Installationsweg

Modulmanifeste verweisen auf `Deployment/Build-Install.ps1` mit ihrer Modul-ID.
Der Builder ergänzt transitive Pflichtabhängigkeiten und liest kanonische
Source-Dateien aus dem gebundenen Inventar. Alle aktuellen SQL-Assemblynamen
beginnen mit `tlblt`; CLR-Klassennamen und Dateinamen sind davon unabhängig.
Die private ScriptDom-Identität trennt zusätzlich die CLR-Abhängigkeit von
fremden ScriptDom-Installationen.

Gemeinsamer Satz und Einzelmodule verwenden dieselbe SQL-Erzeugung. Der
PowerShell-Client führt deren normale SQL-Datei mit erneuter Zielbindung und
Sitzungssperre aus. Die abschließende Schnittstellenprüfung bestätigt keine
Definition oder Version namensgleicher bereits vorhandener Objekte.

Der SQL-Kern verändert keine Serverkonfiguration oder Rechte. Die separaten,
ausdrücklichen Clientoptionen CreateDatabase und EnableClr behalten den
[administrativen Vorbereitungsvertrag](../../Deployment/PROVISIONING.md).
Trust wird ausdrücklich gewählt: exakte Hashregistrierung oder vorhandener
DB-Trust mit beziehungsweise ohne Hashvergleich; auto wählt anhand des
vorhandenen TRUSTWORTHY-Zustands. Es gibt keinen Fehler-Fallback und keine
automatische Aktivierung von TRUSTWORTHY.

Es gibt kein aktuelles automatisches Upgrade oder Uninstall. Teilfehler können
bereits angelegte Objekte hinterlassen. Bestehende Daten und fremde Objekte
werden nicht für ein vermeintliches Gesamt-Refresh entfernt. Historische
markerbasierte Lifecycle-Verträge bleiben ausschließlich für ihre ursprünglichen
Releases gültig; die [ursprüngliche Architektur](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2fbe8e3e86f370b22ad2ce9f9716d971072a052b/Documentation/Architecture/DEPLOYMENT_MODEL.md)
und ihre Originalquellen bleiben unverändert im Vorgängercommit erhalten.

### Beauftragter Skillkatalog

Die [Skill-Integration](../../Backlog/OBJECT_USAGE_SKILLS.md) befindet sich noch
in Umsetzung. Ihr Vertrag sieht für alle Gesamt-/Teilprofile eines Quellstands
denselben vollständigen bekannten Objektkatalog vor. Eine spätere Teilinstallation
desselben Builds braucht den Katalog deshalb nicht zu erweitern. Einträge können
nicht installierte oder für das gewählte Profil ungeeignete Objekte beschreiben;
Voraussetzungen und Plattformgrenzen stehen im jeweiligen Skill. Die Sicht ist
keine Installations- oder Berechtigungsprüfung.

Auch diese Sicht folgt create-only. Eine Teilinstallation eines anderen Builds
ersetzt keinen bestehenden Katalog. Für dessen Aktualisierung braucht es eine
frische Installation oder eine getrennt kontrollierte manuelle Änderung; der
Installer entfernt oder überschreibt keine vorhandene Definition. Der vollständige
Katalog wird erst nach abgeschlossener Quellenabdeckung integriert, nicht als
Teilmenge ungeprüfter Beschreibungen.

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
