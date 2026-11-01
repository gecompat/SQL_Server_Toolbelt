# Aktueller Releasekandidat für v1.0.0

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
Die Installation folgt ausschließlich der [Parameter-Help-Anleitung](PARAMETER-HELP.md)
und dem dort benannten ZIP mit vier Installationsprofilen. Sie ist für eine
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
