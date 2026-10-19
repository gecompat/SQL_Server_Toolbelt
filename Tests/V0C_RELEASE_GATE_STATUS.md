# V0c – Rest-Gates der ersten Releasekohorte

Stand: 2026-10-19. Auftrag: autonom ausführbare Rest-Gates der verbindlichen
16-Modul-Kohorte abarbeiten, Fehler beheben und externe Voraussetzungen
abgrenzen. Keine neue öffentliche SQL-Funktion und keine Veröffentlichung.
Die Kohorte steht in [BACKLOG.md](../.ai/BACKLOG.md#v0av0bv0c-releasevalidierung-und-erste-releasekohorte).

## Stand der 16 Module

13 Module sind `validated`; drei bleiben wegen der Performance-Abnahme
`partially validated`. Alle 16 bleiben `unreleased`.

| Modul | Version | Validierung |
|---|---|---|
| `toolbelt.core.result-table` | 1.0.0 | `partially validated` |
| `toolbelt.conversion.base64` | 1.1.0 | `partially validated` |
| `toolbelt.core.generate-series` | 1.0.0 | `partially validated` |
| `toolbelt.metadata.identifier` | 1.0.0 | `validated` |
| `toolbelt.string.split-characters` | 1.0.0 | `validated` |
| `toolbelt.validation.semantic-version` | 1.1.0 | `validated` |
| `toolbelt.conversion.integer-base` | 1.1.0 | `validated` |
| `toolbelt.datetime.calendar-difference` | 1.0.0 | `validated` |
| `toolbelt.string.directional-trim` | 1.0.0 | `validated` |
| `toolbelt.conversion.uri-component` | 1.0.0 | `validated` |
| `toolbelt.datetime.truncate` | 1.0.0 | `validated` |
| `toolbelt.datetime.bucket` | 1.0.0 | `validated` |
| `toolbelt.binary.bit-operations` | 1.0.0 | `validated` |
| `toolbelt.json.path-exists` | 1.0.0 | `validated` |
| `toolbelt.core.console-message` | 1.0.0 | `validated` |
| `toolbelt.metadata.capability-catalog` | 1.0.0 | `validated` |

## Nachweise dieser Welle

| Prüfung | Scope | Ergebnis |
|---|---|---|
| Vollständige Fachadapter | Alle 16 Module; physische SQL Server 2019/2022/2025, Linux latest und Windows mit den freigegebenen CU-Äquivalenten zu base; versionsabhängige CL150/160/170 | `success`; 66 vollständige Adapterläufe |
| Verschärfte SemVer-Orakel | Vollständiger Adapter auf allen sechs Zielkombinationen; NULL- und Kardinalitätsorakel vom 2026-10-09 eingeschlossen | `success` |
| ADO.NET-Client | Alle sechs Ziele; beide Provider, vollständige geordnete Frames, Unicode, CRLF, Leerzeichen, Prozentzeichen, Help, Eingabegrenze und atomare Ablehnung | `success` |
| Status-APIs mit Minimalrechten | [SQL-Vertrag](V0C_StatusPermissions.Contract.sql) auf allen sechs Zielen; sieben Statusfunktionen mit objektbezogenem SELECT, ohne CONTROL und ohne direkten SELECT-Zugriff auf die unbegrenzten Series-APIs | `success` |
| Zentrale Status-APIs | [SQL-Vertrag](V0C_StatusCentral.Contract.sql) auf allen sechs Zielen; echte separate Consumer-Datenbank, sieben Statusfunktionen und Series-Limit | `success` |
| Base64-Performance-Orakel | Aus dem Workload extrahierte Bedingung mit NULL, falschem und richtigem Binärwert; SQL Server 2025 Linux, CL170 | `success`; funktional, kein Benchmark |
| Plattform und Cleanup | Hostplattform aller sechs Ziele lesend verifiziert; keine Rückstände im eigenen Laufumfang, fremder Bestand bleibt unberührt | `success` |
| Dokumentation, Dependency- und Manifestkonsistenz | `python -B Tests/Documentation/validate_documentation.py --all --write`; vollständiger Audit, betroffene statische Verträge und Datenschutzprüfung | `success` |

Produktbasis ist `1dc2311d11fac2e83afe3892bdb3c3aa36158d12`.
Die fachlichen SQL-Quellen bleiben unverändert. Die Qualifikation ergänzt
ältere datierte Nachweise; sie wird nicht auf andere Module übertragen.
GitHub-CI am abschließenden PR-Head wird getrennt im PR ausgewiesen.
Die hier beschriebenen lokalen Nachweise ersetzen keine Head-CI.

Alle Labverbindungen verwenden den schema-validierten Vertrag,
`TestPurpose=Functional`, erforderliche Verschlüsselung und dessen expliziten
Trustwert. Es gibt keinen Provider- oder TLS-Fallback. Authentifizierte
TLS-Abnahme: separat `not executed`; kein Blocker für diese Fachprüfungen.
Es werden keine realen Endpoints, Credentials, Runtime-Logs oder Messwerte
versioniert. Eigene Testdatenbanken werden scopegebunden entfernt.

## Reproduktion

Die vorhandenen Labvariablen müssen auf einen schema-validen Vertrag mit
den explizit ausgewählten bereiten Zielen verweisen. In PowerShell 7 im
Repositoryroot:

```powershell
$adapters = @(
    'run-result-table-linux.sh', 'run-base64-linux.sh',
    'run-generate-series-linux.sh', 'run-identifier-linux.sh',
    'run-split-characters-linux.sh', 'run-semantic-version-linux.sh',
    'run-integer-base-linux.sh', 'run-w1-linux.sh', 'run-w2a-linux.sh',
    'run-w2b-json-path-linux.sh', 'run-w2c-linux.sh'
)
$priorPerformance = $env:TBX_RUN_PERFORMANCE_WORKLOAD
try {
    $env:TBX_RUN_PERFORMANCE_WORKLOAD = '0'
    ./Tests/CI/run-lab-local.ps1 -TestPurpose Functional -TestSuite full `
        -Versions 2019,2022,2025 -Platforms linux,windows -RunScripts $adapters
    if ($LASTEXITCODE -ne 0) { throw 'V0c-Fachmatrix fehlgeschlagen.' }
} finally {
    $env:TBX_RUN_PERFORMANCE_WORKLOAD = $priorPerformance
}
./Tests/CI/run-console-clients-lab.ps1
```

Die aktuelle Welle verteilt dieselben elf Adapter auf getrennte Läufe;
grüne unveränderte Fälle werden dabei nicht erneut ausgeführt.
Der neue [Minimalrechte-Vertrag](V0C_StatusPermissions.Contract.sql) setzt
die fünf genannten Module in einer eigenen Testdatenbank voraus. Er legt
eine synthetische Datenbankidentität an und entfernt sie wieder.
Der [zentrale Vertrag](V0C_StatusCentral.Contract.sql) wird nach zentralem
Deployment in einer separaten Consumer-Datenbank mit der SQLCMD-Variablen
`ToolbeltDatabase` ausgeführt. Er verwendet die vorhandene Testidentität,
erteilt keine Cross-DB-Rechte und behauptet keine allgemeine Delegation
unter anderen Endbenutzeridentitäten.

## Behebung und Aussagegrenzen

Der Base64-Performance-Workload konnte ein unerwartetes NULL bei der
Roundtrip-Prüfung übersehen. Die Bedingung weist NULL nun ausdrücklich ab;
das extrahierte Orakel wurde mit positiven und negativen Werten geprüft.
Die Performance-Messung selbst wurde nicht ausgeführt.

Die statische Split-Characters-Prüfung akzeptierte den gültigen YAML-Wert
`validation_status: "validated"` nicht, obwohl die unquotierte Schreibweise
bereits zulässig war. Sie akzeptiert nun beide Schreibweisen; der
vollständige Dokumentationsaudit einschließlich dieser Prüfung ist erfolgreich.

Die zusätzliche Console-Prüfung erfasst tatsächliche ADO.NET-InfoMessage-
Frames; die W2c-Suite deckt ODBC/sqlcmd ab. Im abgeschlossenen Clientlauf
kam NOWAIT jeweils vor Abschluss des Clientbefehls an; ein früherer
Einzellauf lieferte keine solche vorzeitige Beobachtung. Die Probe
dokumentiert dies ohne eine Pufferungsursache zu behaupten.
Clientlatenz und optische Formatierung bleiben gemäß bestehendem
[Enginevertrag](../Documentation/Architecture/CONSOLE_MESSAGE_MODULE_DESIGN.md#aussagegrenzen)
außerhalb der Zusage. Eine visuelle SSMS-Prüfung wurde nicht ausgeführt;
es wird keine universelle Aussage für weitere Clients abgeleitet.
Der zusätzliche ADO.NET-Clientprozess lief unter Windows/PowerShell 7;
die sechs Plattformkombinationen bezeichnen die SQL-Server-Ziele.

## Externe Voraussetzungen und Entscheidungen

| Punkt | Benötigt | Wiederaufnahme / Grenze |
|---|---|---|
| ResultTable-Performance | Ein reserviertes oder ausreichend skaliertes, nachweislich lastkontrolliertes SQL-Server-2025-/CL170-Ziel | Vorhandenen Performanceadapter mit flüchtiger Kalibrierung und unabhängiger Bestätigung ausführen |
| Base64-Performance | Dasselbe qualifizierte Ziel | NULL-sicher korrigierten Workload mit Kalibrierung und Bestätigung ausführen |
| Generate-Series-Performance | Dasselbe qualifizierte Ziel | Bestehenden Zehn-Millionen-Workload verwenden; der bekannte instabile gemeinsame Entwicklungs-Docker-Host wird nicht erneut versucht |
| Veröffentlichung | Ausdrückliche Benutzerentscheidung nach Erledigung der fehlenden Gates | Alle 16 Module bleiben `unreleased`; ein kleinerer Releaseumfang wäre eine eigene Entscheidung |

Für alle drei Performancefälle gelten unverändert drei Batches mit je
Warm-up und fünf Samples, höchstens 20 % Batch-Median-Varianz und die
bestehende Regressionsgrenze. Instabilität bedeutet `not executed`, keinen
PASS. Kalibrierung und Bestätigung belegen Wiederholbarkeit dieses Ziels,
keine plattformübergreifende Leistungszusage. Basis und Messwerte bleiben
flüchtig. READY im Labvertrag allein belegt keine Lastkontrolle.
Toolbelt startet oder skaliert hierfür keine Labressourcen selbst.

SC-018 bleibt außerdem eine Betreibergrenze: Unvertrauenswürdige Principals
dürfen die unbegrenzten mathematischen Series-Alt-APIs nicht direkt erhalten.
Die neue Minimalrechteprüfung belegt die nutzbare begrenzte Oberfläche,
ändert aber keine bestehenden Installationsrechte und schließt keine
unbekannten Grants in realen Umgebungen.

Die weiteren V0b-Gates für File Content, ZIP Memory und Windows Filesystem
liegen außerhalb dieser 16-Modul-Kohorte. Deren Fixtures,
Interoperabilitäts- und manuellen Sicherheitsnachweise bleiben separat
offen. Sie werden durch diese Welle weder ausgeführt noch als erledigt markiert.

## Prüfaufwand

Ein Arbeitspaket, ein PR und ein Implementierungsverantwortlicher; keine
zusätzlichen Agenten oder neuen Workflows. Die elf vorhandenen Adapter sind
auf die 16 Kohortenmodule begrenzt. Der vollständige Dokumentationsaudit ist
für diesen Qualifikationsstand und die betroffene Kopplungsregistry erforderlich.
CI bestätigt anschließend den stabilen PR-Head nach den bestehenden Filtern.
Zuverlässige Token-/Kostenmessung ist nicht verfügbar; dafür wird kein
Verbrauchswert behauptet.
