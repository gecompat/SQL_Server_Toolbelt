# SQL Server Toolbelt v1.0.0 vorbereiten

Status: **Releasevorbereitung, nicht veröffentlicht**. Der ausdrückliche
Benutzerauftrag umfasst das Gesamtpaket, die Trennung stabil/Preview und einen
Pull Request. Er umfasst keine Veröffentlichung und setzt die pausierte
autonome Weiterentwicklung nicht fort.

## Was enthalten ist

Alle 45 implementierten Module mit ihren unveränderten Modulversionen,
SQL-Quellen, vorhandenen CLR-Buildskripten, Deployment, Beispielen, Workern,
Dokumentation, Tests und Lizenzen sind im **Quellpaket-Kandidaten** enthalten.
Zusätzliche eigenständige SQL-Dateien bündeln die stabilen Kandidaten für
lokales beziehungsweise zentrales Deployment. Sie ändern keine öffentlichen
SQL-Verträge und werden durch den bestehenden Offline-Exporter erzeugt.

Die [Freigabematrix](FREIGABEMATRIX.md) unterscheidet 19 stabile und 26
Preview-Kandidaten. Ausgangspunkt ist der Manifest-Prüfstatus; transitive
Preview-Dependencies begrenzen den Kanal. Deshalb sind Second Session und
Event Log trotz eigenem `validated` vorläufig Preview. Alle Vorschläge
benötigen vor Veröffentlichung die konkrete fachliche Supportabnahme.

Das Quellpaket ist **kein vollständig vorgebautes CLR-Installationspaket**.
Der enthaltene [SSIS-Installationssatz](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md)
liefert bereits die gemeinsam qualifizierten SSIS-/Parser-/ScriptDom-Binaries.
Andere CLR-Module benötigen ihre dokumentierten passenden Binary-/Trustinputs.
Die maschinenlesbare Lieferform steht pro Modul in
[release-plan.json](release-plan.json). Fehlende Binaries werden nicht durch
ungeprüfte lokale DLLs oder einen stillen Neubuild ersetzt. Ein allgemeines
„alle CLR-Module ohne eigenen Build installieren“-Paket bleibt ein offenes
Liefergate vor einer entsprechenden Veröffentlichungszusage.

## Paket bauen und unabhängig prüfen

Voraussetzungen sind ein vollständiger Git-Checkout, Python 3.10 oder neuer
und PowerShell 7. Es werden weder SQL Server, `sqlcmd`, Labzugang noch
Verbindungsdaten benötigt. Die Python-Werkzeuge nutzen die Standardbibliothek.

Im Repositoryroot, nach Commit der Releasevorbereitung:

```powershell
python -B Scripts/Release/prepare_release.py --check
python -B Scripts/Release/prepare_release.py --build --source-commit HEAD `
  --output Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
python -B Scripts/Release/prepare_release.py `
  --verify Releases/1.0.0/Artifacts/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
```

Das Zielverzeichnis muss bestehen; ZIP und Prüfsumme dürfen noch nicht
existieren. Für Wiederholungen einen neuen leeren Ausgabeort wählen. Der
Generator überschreibt keine bestehenden Pakete. Der ZIP-Inhalt kommt aus
dem ausdrücklich ausgewählten Commit. Die eigene Artefaktablage bleibt
ausgeschlossen, sodass kein ZIP sich selbst enthält. Gitmetadaten, ignorierte
Builds, Secrets und private `.runtime`-Daten werden nicht übernommen.

`PACKAGE-MANIFEST.json` bindet jede Datei mit Größe und SHA-256 an den
Quellcommit und die unveränderte Produktbasis. `SHA256SUMS.txt` deckt auch
das Paketmanifest ab; die externe `.zip.sha256` bindet das gesamte Archiv.
Zeitstempel und Reihenfolge sind fest. Bytegleiche ZIPs werden bei identischen
Inputs und identischer Python-/Kompressionsruntime erzeugt; eine digitale
Herausgebersignatur oder native Installationsqualifikation folgt daraus nicht.

Ein Fehler bei Manifest, Dependencyclosure, Quellbindung, Export oder
Paketintegrität stoppt den Vorgang. Es gibt keinen Git-, Provider- oder
Binaryfallback. Die [Release-Tests](../../Tests/Release/README.md) prüfen auch
negative Fälle und laufen über den bestehenden Dokumentationsworkflow.

## Auspacken und erster Test

1. Gesamte ZIP in ein neues Verzeichnis entpacken und `START-HERE.md` lesen.
2. Vor Ausführung ZIP-Prüfsumme und Paketmanifest mit dem obigen Prüfmodus in
   einem vollständigen Checkout prüfen. Der referenzierte Quellcommit muss
   lokal verfügbar sein. Prüfsummen allein sind kein Herkunftsnachweis.
3. Den [Deploymentablauf](../../Deployment/README.md) und die Objektseiten der
   gewünschten Module lesen. Als erste Vorschau im entpackten Paket ausführen:

   ```powershell
   pwsh -File Deployment/Deploy-All.ps1 -DeploymentMode local `
     -ModuleId toolbelt.datetime.date-spine -PlanOnly
   ```

4. In einem eigenen Testsystem nur die bewusste Modulauswahl installieren und
   ein einzelnes synthetisches Objektbeispiel testen. Die beiden generierten
   `Install-Stable-local.sql` / `Install-Stable-central.sql` sind alternative
   Gesamt-Exports, keine automatisch ausgeführten Installer. SQLCMD-Modus,
   Fehlerabbruch, frische exklusive Sitzung und richtige Zieldatenbank sind
   erforderlich. Ein späterer Modulfehler rollt frühere Module nicht zurück.
5. Preview-Module separat auswählen. CLR, Trust, Dateifixtures oder
   Loopback-Provider gemäß den Modulregeln vorbereiten; das Paket ändert diese
   Voraussetzungen nicht. Uninstall folgt dem jeweiligen Modulvertrag.

Die breite Installationsabnahme des erzeugten Gesamtpakets ist `not executed`.
Bestehende native Modulnachweise bleiben mit ihrem dokumentierten Scope
verlinkt. Packagingchecks behaupten keine neue Rechte-, Speicher-,
Parallelitäts-, Recovery- oder TLS-Qualifikation.

## Vor einer Veröffentlichung

- Pro Modulversion die tatsächlich freizugebenden SQL-Versionen, relevanten
  CLs, Plattformen, Provider, Deploymentmodi und Dependency-/Consumerpfade
  abgrenzen; vollständige Pflichtnachweise fachlich prüfen. Auch Preview
  ersetzt keine fehlende Pflichtqualifikation im zugesagten Scope.
- Offene CSV-/Parser-/Datei-I/O-/Worker-/Recovery- und weitere Modulgrenzen
  aus der Matrix behandeln oder außerhalb des zugesagten Umfangs halten.
  Die Liste ist kein Auftrag für zusätzliche Entwicklungs- oder Labwellen.
- Lieferform festlegen und gegebenenfalls fehlende gemeinsam gebundene
  CLR-Binaries einschließlich Trustmanifeste, Herkunft und Lizenzhinweise
  ergänzen. Keine privaten Buildpfade oder unqualifizierten Rebuilds ausliefern.
- Endgültige Artefakte und deren Installationsweg prüfen; vollständigen
  Dokumentationsaudit und tatsächliche CI des endgültigen Heads nachweisen.
- Konkrete öffentliche Veröffentlichung separat freigeben. Erst danach
  tatsächliche URL, Tagcommit, Veröffentlichungszeit, Assethashes und
  Supportnachweise als `publication_record` pflegen und Modulstatus ändern.

Authentifizierte TLS-Abnahme und optionale Laufzeitmessungen bleiben getrennt.
Es werden kein Tag, GitHub-Release oder Veröffentlichungszeitpunkt vorgetäuscht.

## Quellen und Pflege

`module.yaml` bleibt Quelle für Version, Prüfstatus, Dependencies und Evidenz.
Der [Plan](release-plan.json) friert diese Daten und die Kanalvorschläge ein;
die Markdownmatrix wird daraus erzeugt. Nur für einen ausdrücklich geänderten
Produktstand `--refresh --product-commit <Commit>` verwenden und anschließend
alle betroffenen Nachweise erneut zuordnen. Die Prüfung verwirft Produktdrift
gegenüber der festgehaltenen Basis; sie wertet keinen Prüfstatus auf.

[Entwurf der Release Notes](RELEASE-NOTES.md) · [Releaseübersicht](../README.md)
