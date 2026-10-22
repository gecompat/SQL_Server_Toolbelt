# Dokumentation und Lesewege

SQL Server Toolbelt richtet sich an Entwickler und Administratoren mit
T-SQL- und SQL-Server-Grundkenntnissen. Wähle zunächst ein Modul und dessen
belegte Plattform. Eine Zielplattform oder vorhandener Code bedeutet noch
keine vollständige Validierung; den aktuellen Umfang bestimmen das jeweilige
`module.yaml`, die Modulbeschreibung und ihre Testmatrix.

## Ein Modul kennenlernen und vorbereiten

1. Suche das benötigte Modul in der [Modulübersicht](../Modules/README.md).
   Öffne seine README und Objektseiten. Prüfe SQL-Version, Betriebssystem,
   Deployment-Modus, Dependencies, Rechte und Einschränkungen.
2. Wähle anhand des [Deployment-Modells](Architecture/DEPLOYMENT_MODEL.md)
   zwischen lokaler und zentraler Installation. Lies anschließend den
   [Deploymentablauf](../Deployment/README.md): Er beschreibt PowerShell 7,
   `sqlcmd`, ausdrückliche Zielwahl, CLR-Eingaben und Fehlergrenzen.
3. Beginne mit dem dort beschriebenen `-PlanOnly` für deine Modulauswahl.
   Der erwartete Plan nennt Module, automatisch ergänzte Dependencies und
   erforderliche Eingaben; er installiert nichts. Fehlende Eingaben oder
   ungeeignete Voraussetzungen zuerst klären. Der Runner baut keine Binaries
   und erteilt keine Rechte oder Trustfreigaben.
4. Führe ein Deployment erst mit den dokumentierten Voraussetzungen auf einer
   bewusst gewählten Umgebung aus. Die Module haben eigene Transaktionen;
   ein späterer Fehler rollt frühere erfolgreich installierte Module nicht
   pauschal zurück. Wiederholung und Uninstall folgen dem jeweiligen Lifecycle.
5. Wähle danach ein einzelnes passendes Beispiel im
   [API-Katalog](Reference/README.md). Erklärt werden Parameter und
   Voraussetzungen; für Resultsets, Seiteneffekte und Fehler bleibt die
   verlinkte Objektseite maßgeblich. Die SQL-Beispielsammlung nicht gesammelt
   ausführen. Vergleiche das Ergebnis mit dem dort beschriebenen Vertrag.

## Abweichungen untersuchen

Bei einem Deploymentfehler den [Deploymentablauf](../Deployment/README.md)
und die Voraussetzungen des betroffenen Moduls prüfen. Bei abweichenden
Ergebnissen zur Objektseite und zum dort verlinkten Fachvertrag zurückgehen.
Die [Hinweise zur Herkunft und Fehlermeldung](../CONTRIBUTING.md) erklären,
welche Versionen und lokalen Belege für eine Untersuchung benötigt werden.
Reale Ausgaben und Zugangsdaten bleiben privat. Eine bestandene Testmatrix
belegt ausschließlich ihre genannten Ziele und Fälle.

## Quellen und Verzeichniszwecke

| Bereich | Zweck und nächste Quelle |
|---|---|
| `Modules/` | Implementierung, Modulmanifest, Objektseiten, Deployment und modulspezifische Tests |
| `Deployment/` | Repository-Runner und ausführbare Vorbereitungsschritte |
| `Documentation/Architecture/` | Gemeinsame Fachverträge, Architekturentscheidungen und ausdrücklich datierte Integrationsnachweise |
| `Documentation/Standards/` | Gemeinsame Engineering-, Datenschutz- und Qualitätsregeln |
| `Documentation/Reference/` | Abgeleiteter API-Katalog; [Quellen und Generierung](Reference/README.md#quellen-und-pflege) |
| `Backlog/` | Ideen und recherchierte Kandidaten; keine automatische Implementierungsfreigabe |
| `Tests/` | Testprogramme und Nachweisgrenzen; [Dokumentationsprüfung](../Tests/Documentation/README.md) |

Für Beiträge und Projektpflege beginne mit [CONTRIBUTING.md](../CONTRIBUTING.md).
KI-Steuerung wird gesondert über [AGENTS.md](../AGENTS.md) entdeckt. Dieser
Einstieg führt zu den aktiven Projektregeln und deren maschinenlesbaren
Quellen; er ist keine zusätzliche Produktanleitung.
