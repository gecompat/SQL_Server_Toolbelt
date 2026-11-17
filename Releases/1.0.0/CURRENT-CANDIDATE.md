# Quellrelease und gebundener Installationskandidat für v1.0.0


## Gemeinsamer aktueller Installationssatz

Der [aktuelle Installer](CURRENT-INSTALL.md) und seine
[zwölf nativen Installationsprofile](CURRENT-INSTALL-QUALIFICATION.md) schließen
die frühere gemeinsame Quell-/Binarybindungslücke. Der aktuelle Kandidatenbuilder
verwendet dieses neue qualifizierte Paket. Historische Snapshots ohne dieses
Paket behalten ihren unveränderten Help-Installer; keine unbekannte aktuelle
Lieferung darf bei fehlendem Record darauf zurückfallen.

## Aktuelles Quellrelease

Ein konsistenter aktueller Entwicklungsstand kann ohne weitere Testwelle als
Quellrelease aus einem exakt festgelegten grünen Main-Commit gebaut werden.
Der Git-Export enthält dessen versionierte Quellen aller 45 Module, Dokumentation
und die bereits versionierten Installationspakete. Lokale Änderungen, untracked
Dateien, private Nachweise und Git-Historie werden nicht übernommen.
Die enthaltenen Installationspakete behalten ihre jeweils eigenen Quellen-,
Versions- und Qualifikationsbindungen; daraus entsteht kein neuer gemeinsamer
Installer für alle aktuellen Quellen und keine vollständige Modulqualifikation.

Aus dem Repository-Root, mit einem neuen Ausgabeziel in einem vorhandenen
Ausgabeverzeichnis:

```powershell
$sourceCommit = git rev-parse origin/main
$releaseZip = Join-Path $outputDirectory 'SQL-Server-Toolbelt-1.0.0-source.zip'
git archive --format=zip --prefix=SQL-Server-Toolbelt-1.0.0-source/ --output=$releaseZip $sourceCommit
Get-FileHash -LiteralPath $releaseZip -Algorithm SHA256
```

Vorher PR-/Main-CI am exakten Commit prüfen. Nach dem Export den vollständigen
Archivinhalt gegen denselben versionierten Git-Snapshot vergleichen und die
Prüfsumme, den Commit sowie die verbleibenden Liefergrenzen daneben festhalten.
Der Einstieg im Archiv ist README.md; für ein enthaltenes Installationspaket
gilt dessen eigene Anleitung. Keine alten Installer stillschweigend auf neue
Quellen umdeuten und keine Integritätsprüfung mit neuen Hashes umgehen.

Der Abschlussauftrag vom 2026-11-17 beendet nach konsistenter Integration und
Releasebau die laufende Verarbeitungswelle. Weitere Entwicklungs-/Testwellen
beginnen erst nach einem neuen Benutzerauftrag. Veröffentlichung und Tags
bleiben ausgeschlossen.

## Gebundener Help-Installationskandidat

Die folgenden Angaben beschreiben den bestehenden Builder mit strikter Bindung
an sein bereits qualifiziertes Help-Installationspaket. Seine Bezeichnung
„current-candidate“ bedeutet nicht, dass dieses historische Paket automatisch
zu später geänderten Produktquellen passt. Der lesende Preflight am Main-Stand
vom 2026-11-17 scheitert an der Quellbindung von
`Modules/toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql`.
Dieser historische Befund bleibt erhalten. Die alte Lieferung wird weiterhin
abgewiesen; der neue gemeinsame aktuelle Installationssatz wird separat geprüft. Es wird keine neue native Qualifikation des gemeinsamen Installers
behauptet. Das aktuelle Quellrelease oben bleibt davon getrennt.

Dieser Kandidat bündelt die versionierten aktuellen Quellen aller 45 Module,
Dokumentation und das bereits separat geprüfte Parameter-Help-Installationspaket.
Er dient der Prüfung des eingefrorenen Entwicklungsstands. Der erzeugte
CURRENT-RELEASE-PLAN.json enthält die aktuellen Manifestwerte und Dependencies;
19 stabile und 26 Preview-Zielkanäle bleiben getrennt von einer Veröffentlichung.

Alle Module bleiben unveröffentlicht. Die Integritätsprüfung belegt Quellcommit,
Paketinhalt, Dateiprüfsummen und die Bindung des vorhandenen Help-Installers.
Sie ist keine vollständige fachliche Modul-, Plattform-, Minimalrechte-,
Recovery- oder authentifizierte TLS-Abnahme. Die [Releasegates](RELEASE-GATES.md)
und der [Support-Zielumfang](SUPPORT.md) bestimmen die verbleibenden Grenzen.

Der später separat nativ geprüfte administrative SSIS-Trustguard besitzt einen
eigenen [Nachweis und Prüfumfang](../../Modules/toolbelt.tsql.ssis-debug/Tests/InstallerTrust/README.md).
Sein historischer Input im unveränderten Help-Paket wird nur nach Prüfung der
aktuellen Guard-/Methodenbindung aus dem fest gebundenen Originalpaket erkannt.
Diese Kandidatenprüfung verwendet ausschließlich die versionierten Bytes des
gewählten Quellcommits. Compilerquellen, andere Deployments und Paketbytes
erhalten dadurch keine allgemeine Ausnahme und keine neue native Abnahme.

## Bauen und prüfen

Erforderlich sind Python 3.10 oder neuer, Git und ein vollständiger Checkout
mit lokal vorhandenem Quellcommit. Alle gewünschten Quellen müssen committed
sein; nicht versionierte Dateien, lokale Änderungen und Git-Historien werden
nicht in das Paket übernommen. Aus dem Repository-Root mit einem neuen,
bereits vorhandenen Ausgabeverzeichnis ausführen:

    python -B Scripts/Release/prepare_current_candidate.py --build --source-commit HEAD --output .runtime/SQL-Server-Toolbelt-1.0.0-current-candidate.zip
    python -B Scripts/Release/prepare_current_candidate.py --verify .runtime/SQL-Server-Toolbelt-1.0.0-current-candidate.zip

Ein bestehendes ZIP oder eine bestehende Prüfsummendatei wird nicht überschrieben.
Bei Erfolg entstehen ZIP und danebenliegende SHA256-Datei. Die Prüfung muss
CURRENT_CANDIDATE_VERIFY: PASS ausgeben. Ein fehlender Quellcommit, geänderte
Datei, unpassender Installer oder ungültiger Archivpfad beendet sie mit Fehler.
Nicht durch neue Prüfsummen oder manuelle Änderungen am Manifest umgehen;
Quellstand und vorhandenen Nachweis abgleichen und einen neuen Kandidaten bauen.

## Auspacken und installieren

Nach Vergleich der separat bezogenen SHA256-Datei das ZIP in ein neues
Verzeichnis entpacken und START-HERE.md lesen. CANDIDATE-MANIFEST.json bindet
alle gelieferten Dateien; SHA256SUMS.txt enthält ihre Einzelprüfsummen.
Die Installation folgt dem in CURRENT-RELEASE-PLAN.json benannten Installer
und der [aktuellen Installationsanleitung](CURRENT-INSTALL.md) mit vier Profilen. Sie ist für eine
leere, ausdrücklich ausgewählte Testdatenbank bestimmt. Erforderliche Rechte,
CLR und bewusst eingerichteter Trust bleiben separate Voraussetzungen.

Der Quellkandidat selbst führt kein SQL aus und richtet keine Ressourcen ein.
Die bestehenden Stable-/CLR-/SSIS-Pakete sowie release-plan.json und
product-source.json unter Releases/1.0.0 bleiben historische gebundene Inputs.
Ihr älterer Produktcommit ist keine Qualifikation des aktuellen Quellbaums.
Der bisherige Builder prepare_release.py prüft weiterhin genau diese ältere
Lieferung; seine Produktgates werden durch diesen Kandidaten nicht verändert.

Für die Veröffentlichung bleiben vollständige Pflichtnachweise im konkret
zugesagten Umfang, erfolgreiche CI des finalen Kandidaten und ein gesonderter
ausdrücklicher Veröffentlichungsauftrag erforderlich. Es werden kein Tag,
GitHub-Release oder veröffentlichter Modulstatus erzeugt.

Die aktuelle Manifestprojektion enthält 20 Stable- und 25 Preview-Vorschläge.
Die historische Supportfreigabe mit 19/26 bleibt unverändert und wird nicht
auf diese Projektion übertragen; der Installer erteilt keine neue Kanal- oder
Veröffentlichungsfreigabe.
