# CLR-Sicherheit und Portabilität

## Einsatz von SQL CLR

SQL CLR wird nur eingesetzt, wenn es gegenüber T-SQL technisch begründet ist. Die Entscheidung dokumentiert mindestens:

- messbaren oder nachvollziehbaren Performance-Unterschied;
- Security-Auswirkungen;
- Deployment- und Trust-Aufwand;
- Plattform- und Versionsgrenzen;
- Wartungs- und Build-Anforderungen;
- geprüfte T-SQL- und externe Alternativen.

## Runtime und Plattformgrenzen

SQL CLR in SQL Server verwendet .NET Framework. .NET Core sowie .NET 5 oder neuer sind keine SQL-CLR-Runtime.

| Plattform | `SAFE` | `EXTERNAL_ACCESS` | `UNSAFE` |
|---|---:|---:|---:|
| SQL Server auf Windows | unterstützt | unterstützt, wenn autorisiert | unterstützt, wenn autorisiert |
| SQL Server auf Linux | unterstützt, modulabhängig | nicht unterstützt | nicht unterstützt |
| Azure SQL Database | nicht als reguläres SQL CLR verfügbar | nicht verfügbar | nicht verfügbar |

Eine Signatur oder Hash-Autorisierung hebt eine Plattformgrenze nicht auf. Ein Modul muss seinen tatsächlichen `PERMISSION_SET`, die Plattformen und den Validierungsstatus im Manifest ausweisen.

## `clr strict security`

`clr strict security` bleibt im regulären Installationspfad aktiviert. Die Option wird weder stillschweigend noch als Standardvoraussetzung deaktiviert.

## Trust-Modell

Bevorzugter Trust-Weg für offizielle Release-Binaries:

1. exakten SHA2-512-Hash kontrolliert in `sys.trusted_assemblies` registrieren;
2. Strong Name beziehungsweise asymmetrischen Schlüssel verwenden, wenn ein stabiler Herausgeberschlüssel fachlich sinnvoller ist;
3. X.509-Zertifikate nur einsetzen, wenn sie gegenüber den beiden vorherigen Wegen einen konkreten Vorteil besitzen.

Der Konsument benötigt beim Hash-Pinning kein Zertifikat. Bei Strong Name benötigt er nur die signierte Assembly beziehungsweise deren öffentlichen Schlüssel, niemals den privaten Signing Key.

## Signing-Artefakte

Nicht in das Repository aufnehmen:

- private Signing Keys;
- PFX-, P12-, PVK- oder private SNK-Dateien;
- Zertifikate mit privatem Schlüssel;
- Passwörter oder andere Signing-Secrets.

Öffentliche Schlüssel oder öffentliche Zertifikate dürfen aufgenommen werden, wenn sie für reproduzierbare Verifikation erforderlich und ausdrücklich dokumentiert sind.

## `TRUSTWORTHY ON`

`TRUSTWORTHY ON` ist kein regulärer, automatischer oder bevorzugter Installationsweg.

Eine Last-Resort-Ausnahme ist nur zulässig, wenn:

1. selektivere Alternativen wie Hash-Trust, Assembly- oder Module-Signing, Zertifikate, asymmetrische Schlüssel, explizite Berechtigungen und geeignete Provider geprüft wurden;
2. nachvollziehbar dokumentiert ist, warum diese Alternativen nicht funktionieren oder unverhältnismäßig sind;
3. ein getrenntes Opt-in mit ausdrücklicher Benutzerfreigabe existiert;
4. Datenbank-Owner, `EXECUTE AS`, privilegierte Rollen und Restore-/Failover-Verhalten geprüft sind;
5. die Ausnahme eine eigene Entscheidung in `DECISIONS.md` erhält;
6. der reguläre Installer `TRUSTWORTHY` nicht selbst aktiviert.

Die Ausnahme ist nicht auf CLR beschränkt; sie betrifft den gesamten Datenbank-Trust-Kontext.

## Parallelität und Speicher

- CLR-Routinen so schreiben, dass sie einen parallelen Plan nicht unnötig verhindern.
- Parallelität nicht garantieren und nicht durch eigene Worker Threads erzwingen.
- Datenzugriff aus CLR-UDFs vermeiden, wenn er nicht fachlich erforderlich ist.
- Keine globalen veränderlichen Zustände oder unnötigen Locks.
- Große Ergebnismengen nach Möglichkeit streamen und nicht vollständig materialisieren.
- Allokationen pro Zeile und unnötige Konvertierungen minimieren.

## Portable Provider

Für jede Windows-only-Capability ist zu prüfen, ob eine betriebssystemunabhängige Alternative möglich ist. Zwei Provider werden nur gepflegt, wenn ein relevanter Unterschied bei Performance, Overhead, Capability oder Security besteht. Sie müssen denselben öffentlichen fachlichen Vertrag und dieselbe Fehlersemantik einhalten.

## Primärquellen

- Microsoft: Common Language Runtime Integration Programming Concepts  
  https://learn.microsoft.com/sql/relational-databases/clr-integration/common-language-runtime-clr-integration-programming-concepts
- Microsoft: CREATE ASSEMBLY  
  https://learn.microsoft.com/sql/t-sql/statements/create-assembly-transact-sql
- Microsoft: TRUSTWORTHY database property  
  https://learn.microsoft.com/sql/relational-databases/security/trustworthy-database-property
