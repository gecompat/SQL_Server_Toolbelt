# SQL Server Toolbelt v1.0.0 vorbereiten

Status: **Releasevorbereitung, nicht veröffentlicht**. Der ausdrückliche
Benutzerauftrag umfasst das Gesamtpaket, die Trennung stabil/Preview und einen
Pull Request. Er umfasst keine Veröffentlichung und setzt die pausierte
autonome Weiterentwicklung nicht fort.

Für den ersten praktischen Test beginne mit der
[Installationsanleitung für SSMS](../../INSTALL.md). Sie benötigt für die
stabilen T-SQL-Kandidaten keinen eigenen Build. Die folgenden Abschnitte
erklären Lieferumfang, Paketpflege und Freigabegrenzen.

## Was enthalten ist

Alle 45 implementierten Module mit ihren unveränderten Modulversionen,
SQL-Quellen, vorhandenen CLR-Buildskripten, Deployment, Beispielen, Workern,
Dokumentation, Tests und Lizenzen sind im **Quellpaket-Kandidaten** enthalten.
Zusätzliche eigenständige SQL-Dateien bündeln die stabilen Kandidaten für
lokales beziehungsweise zentrales Deployment. Sie ändern keine öffentlichen
SQL-Verträge und werden durch den bestehenden Offline-Exporter erzeugt.

Die [Freigabematrix](FREIGABEMATRIX.md) unterscheidet 19 stabile und 26
Preview-Kandidaten. Der [Support-Zielumfang](SUPPORT.md) und die Kanalzuordnung
sind seit 2026-10-23 ausdrücklich freigegeben. Ausgangspunkt ist der Manifest-Prüfstatus; transitive
Preview-Dependencies begrenzen den Kanal. Deshalb sind Second Session und
Event Log trotz eigenem `validated` vorläufig Preview. Vor Veröffentlichung
bleibt die vollständige Pflichtqualifikation jeder zugesagten Kombination erforderlich.

Die [Nachweiszuordnung aller 45 Module](EVIDENCE-MAP.md) führt zu den
kanonischen Modulbelegen. Der [API-/Grenzbericht](API-QUALIFICATION.md)
trennt zusätzliche Labprüfungen von weiter offenen externen Voraussetzungen.

Das Gesamt-ZIP enthält zusätzlich den
[CLR-Installationskandidaten mit fertigen DLLs](CLR-INSTALL.md). Er liefert alle
zwölf Toolbelt-CLR-Module und ScriptDom, SQL-Dateien mit eingebetteten Bytes,
explizite Trustwerte, Quellcode und Attributionen. Die vier Profile unterscheiden
Windows/Portable und local/central; das Windows-Dateisystemmodul bleibt lokal.
Auf dem Installationsrechner sind keine Buildwerkzeuge erforderlich.
SSIS-/Parser-/ScriptDom-Binaries bleiben exakt aus dem bestehenden qualifizierten
Satz erhalten. Die maschinenlesbare Lieferform steht pro Modul in
[release-plan.json](release-plan.json). Paketinstallation und vollständige
fachliche Releasefreigabe sind getrennt; Preview-Grenzen bleiben bestehen.

## Paket bauen und unabhängig prüfen

Voraussetzungen sind ein vollständiger Git-Checkout, Python 3.10 oder neuer
und PowerShell 7. Es werden weder SQL Server, `sqlcmd`, Labzugang noch
Verbindungsdaten benötigt. Die Python-Werkzeuge nutzen die Standardbibliothek.

Im Repositoryroot, nach Commit der Releasevorbereitung, in einem neuen
privaten Ausgabeordner; das versionierte ZIP wird dabei nicht überschrieben:

```powershell
python -B Scripts/Release/prepare_release.py --check
New-Item -ItemType Directory .runtime/release-rebuild
python -B Scripts/Release/prepare_release.py --build --source-commit HEAD `
  --output .runtime/release-rebuild/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
python -B Scripts/Release/prepare_release.py `
  --verify .runtime/release-rebuild/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
```

Das Zielverzeichnis muss bestehen; ZIP und Prüfsumme dürfen noch nicht
existieren. Für Wiederholungen einen neuen leeren Ausgabeort wählen. Der
Generator überschreibt keine bestehenden Pakete. Der ZIP-Inhalt kommt aus
dem ausdrücklich ausgewählten Commit. Die eigene Artefaktablage bleibt
ausgeschlossen, sodass kein ZIP sich selbst enthält. Gitmetadaten, ignorierte
Builds, Secrets und private `.runtime`-Daten werden nicht übernommen.
`PREPARATION.bundle` erhält einen reproduzierbaren Snapshotcommit mit exakt
demselben Quellbaum, ohne Paketablage und mit ausschließlich synthetischen
Autor-/Committerdaten (`Codex`, `codex@localhost`). Sein Parent ist der
bytegleiche synthetische Produkt-Snapshot aus [product-source.json](product-source.json).
Dieser ersetzt ausschließlich Commitmetadaten des Entwicklungsstands und
hat den darin genannten öffentlichen Main-Commit als Parent. Beide neuen
Snapshotobjekte sind im Bundle enthalten. Arbeitscommit-Metadaten,
`.git`-Konfiguration und Reflogs werden nicht übernommen. Dadurch
bleibt der Quellcommit nach Squash-Merge und Branchcleanup rekonstruierbar.
Der Prüfmodus importiert das Bundle nur in ein eigenes temporäres Repository;
der vorhandene Objektstore und seine Refs werden nicht geändert. Er braucht
die lokal verfügbare öffentliche Main-Basis, keinen Remote- oder Credentialzugriff.
Der frühere Arbeitsbranch und seine persönlichen Commitmetadaten sind für die
Prüfung nicht erforderlich. Auch der Plancheck kann die Produktbasis aus dem
prüfsummengebundenen lokalen Paket in einem privaten temporären Repository
wiederherstellen; er verändert dabei keine Checkout-Refs oder dessen Objektstore.
Für einen eigenen Neubau in einem frischen Checkout kann der Maintainer das
geprüfte `PREPARATION.bundle` aus dem entpackten Paket ausdrücklich lokal
importieren: `git fetch --no-tags --no-write-fetch-head <PREPARATION.bundle> refs/heads/preparation`.
Dieser lokale Import ergänzt immutable Gitobjekte und benötigt keinen
früheren Arbeitsbranch oder Netzwerkzugriff; Branches und Tags bleiben erhalten.
Der Paketbau erzeugt dazu nur unreferenzierte immutable Gitobjekte und einen
temporären eigenen Index. Der echte Index, Branches und Tags bleiben erhalten.
`preparation_origin_commit` nennt den Arbeitsstand als Herkunft; `source_commit`
bindet den bytegleichen bereinigten Snapshot. Die Herkunfts-ID ist kein
Veröffentlichungsnachweis.

`PACKAGE-MANIFEST.json` bindet jede Datei mit Größe und SHA-256 an den
Quellcommit und die unveränderte Produktbasis. `SHA256SUMS.txt` deckt auch
das Paketmanifest ab; die externe `.zip.sha256` bindet das gesamte Archiv.
Zeitstempel und Reihenfolge sind fest. Bytegleiche ZIPs werden bei identischen
Inputs und identischer Python-/Kompressionsruntime erzeugt; eine digitale
Herausgebersignatur oder native Installationsqualifikation folgt daraus nicht.

Der Prüfmodus erzeugt beide stabilen SQL-Exports erneut aus dem eingefrorenen
Gitstand und vergleicht ihre vollständigen Bytes. Er startet dafür ausschließlich
den vorhandenen Offline-Exporter; keine SQL-Verbindung wird aufgebaut.

Ein Fehler bei Manifest, Dependencyclosure, Quellbindung, Export oder
Paketintegrität stoppt den Vorgang. Es gibt keinen Git-, Provider- oder
Binaryfallback. Die [Release-Tests](../../Tests/Release/README.md) prüfen auch
negative Fälle und laufen über den bestehenden Dokumentationsworkflow.

## Auspacken und erster Test

1. Gesamte ZIP in ein neues Verzeichnis entpacken und `START-HERE.md` lesen.
2. Vor Ausführung die ZIP-Prüfsumme mit der separat aus demselben Stand
   bezogenen Prüfsumme vergleichen, wie in der Installationsanleitung erklärt.
   Die vollständige Source-/Paketprüfung mit dem obigen Prüfmodus bleibt
   Bestandteil der Paketpflege und CI und kann unabhängig in einem vollständigen
   Checkout wiederholt werden. Der referenzierte Quellcommit muss dort lokal
   verfügbar sein. Prüfsummen allein sind kein Herkunftsnachweis.
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

Die gepackten Exports der 19 stabilen Kandidaten bestanden auf zwölf
Windows-/Linux-/SQL-/CL-Kombinationen Erstinstallation, Wiederholung,
zentralen Consumer und Uninstall. Der [Gatebericht](RELEASE-GATES.md)
nennt den exakten Scope, die Eingabebindung und den bereinigten Erstfehler.
Die Gesamtinstallation aller 45 Module einschließlich Preview und CLR ist
weiter `not executed`. Bestehende native Modulnachweise bleiben mit ihrem
dokumentierten Scope verlinkt. Der Pakettest behauptet keine neue Rechte-,
Speicher-, Parallelitäts-, Recovery- oder TLS-Qualifikation.

## Vor einer Veröffentlichung

- Pro Modulversion die tatsächlich freizugebenden SQL-Versionen, relevanten
  CLs, Plattformen, Provider, Deploymentmodi und Dependency-/Consumerpfade
  abgrenzen; vollständige Pflichtnachweise fachlich prüfen. Auch Preview
  ersetzt keine fehlende Pflichtqualifikation im zugesagten Scope.
- Offene CSV-/Parser-/Datei-I/O-/Worker-/Recovery- und weitere Modulgrenzen
  aus der Matrix behandeln oder außerhalb des zugesagten Umfangs halten.
  Die Liste ist kein Auftrag für zusätzliche Entwicklungs- oder Labwellen.
- Den CLR-Installationskandidaten einschließlich seiner gebundenen Binaries,
  Trustwerte, Herkunft, Lizenzhinweise und abgegrenzten Paketnachweise in den
  konkret freigegebenen Lieferumfang aufnehmen. Keine spätere Binaryänderung
  ohne Prüfung der betroffenen Dependencies und Nachweise übernehmen.
- Endgültige Artefakte und deren Installationsweg prüfen; vollständigen
  Dokumentationsaudit und tatsächliche CI des endgültigen Heads nachweisen.
- Konkrete öffentliche Veröffentlichung separat freigeben. Erst danach
  tatsächliche URL, Tagcommit, Veröffentlichungszeit, Assethashes und
  Supportnachweise als `publication_record` pflegen und Modulstatus ändern.

Authentifizierte TLS-Abnahme und optionale Laufzeitmessungen bleiben getrennt.
Es werden kein Tag, GitHub-Release oder Veröffentlichungszeitpunkt vorgetäuscht.
Der [aktuelle Gatebericht](RELEASE-GATES.md) unterscheidet erledigte technische
Vorarbeiten, noch fehlende Nachweise und Entscheidungen zur Veröffentlichung.

## Quellen und Pflege

`module.yaml` bleibt Quelle für Version, Prüfstatus, Dependencies und Evidenz.
Der [Plan](release-plan.json) friert diese Daten und die Kanalvorschläge ein;
die Markdownmatrix wird daraus erzeugt. Nur für einen ausdrücklich geänderten
Produktstand `--refresh --product-commit <Commit>` verwenden und anschließend
alle betroffenen Nachweise erneut zuordnen. Die Prüfung verwirft Produktdrift
gegenüber der festgehaltenen Basis; sie wertet keinen Prüfstatus auf.

[Entwurf der Release Notes](RELEASE-NOTES.md) · [Releaseübersicht](../README.md)
