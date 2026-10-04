# Öffentlicher Beispielkatalog

Der [Beispielkatalog](API_CATALOG.md) zeigt alle öffentlichen aufrufbaren
Objekte: Views, Stored Procedures, T-SQL-/CLR-Funktionen und CLR-Aggregate.
Er enthält kurze Erklärungen, Parameter mit SQL-Typ, Default und Richtung,
synthetische Aufrufe, Voraussetzungen und Links zu den bestehenden Verträgen.
Tabellen, Assemblies und interne Helfer sind keine Aufrufoberfläche.

Die [HTML-Ansicht](API_CATALOG.html) lässt sich lokal im Browser durchsuchen;
die [SQL-Beispielsammlung](API_EXAMPLES.sql) enthält einzeln auswählbare,
auskommentierte Beispiele. Sie legt keine Zieldatenbank fest. Beispiele mit
Dateien, Handlern, Claims oder Plan-Hashes benötigen ihre beschriebenen
Voraussetzungen und können Zustände verändern. Nicht gesammelt ausführen.

## Quellen und Pflege

- `Modules/*/module.yaml` bestimmt Umfang, Sichtbarkeit, Typ und Modulversion.
- `Modules/*/Source/*.sql` liefert Parameterreihenfolge, SQL-Typen, Defaults
  und OUTPUT. Auch dynamisch deklarierte CLR-Aggregate werden berücksichtigt.
- [api_examples.json](api_examples.json) enthält die redaktionellen
  Kurzbeschreibungen, Parametererklärungen, synthetischen Beispiele und Voraussetzungen je API.
- Modullokale Objektseiten bleiben die verbindlichen fachlichen Verträge,
  insbesondere für zulässige Parameterwerte, Resultsets und Grenzen.

Der Katalog ersetzt keine Objektseite und behauptet keine Runtime-Validierung.
Er wird ausschließlich offline aus Repositoryquellen erzeugt. Zugangsdaten,
installierte SQL-Kataloge und reale Ausgaben werden nicht eingelesen.

Bei einer neuen oder entfernten öffentlichen API muss die Beispielregistry
mitgepflegt werden. Jeder Source-Parameter benötigt eine passende Erklärung;
neue oder entfernte Parameter stoppen die Prüfung bis zur redaktionellen Pflege.
Bei Vertragsänderungen sind Beschreibung, Beispiele und
Voraussetzungen fachlich zu prüfen; der Generator kann diese semantische
Prüfung nicht übernehmen. Die drei Ausgabedateien nicht direkt bearbeiten.

Vom Repository-Root aus generieren und anschließend prüfen:

```bash
python Tests/Documentation/generate_api_catalog.py --write
python Tests/Documentation/generate_api_catalog.py
python Tests/Documentation/test_api_catalog.py
```

Die Ausgabe ist deterministisch. Die Read-only-Prüfung erkennt fehlende oder
veraltete API-Einträge, unbekannte öffentliche Typen, mehrdeutige Quellen und
abweichende generierte Dateien. Source-/Vertragsfingerprints erkennen auch
Änderungen ohne sichtbare Signaturänderung. LF und CRLF werden gleich behandelt.
Die bestehende Dokumentations-CI führt Prüfung und Regressionstests über das
Impact-Paket `public_api_catalog` in der Repo-Map aus; ein Vollaudit prüft sie
ebenfalls. Geänderte Quellen und die neu generierten Dateien gemeinsam committen.
