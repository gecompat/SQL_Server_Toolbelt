# Releasewerkzeuge und Nachweisbindung

Aktuelle markerfreie SQL-Profile, Payload und Installationssatz werden über
[Scripts/Install](../Install/README.md) gebaut. Der gemeinsame Client verwendet
diesen Satz und lädt keinen historischen Installer automatisch nach.

Die bestehenden versions-/receiptgebundenen Werkzeuge dieses Verzeichnisses
bleiben für ihre ursprünglichen Lieferungen und Nachweise erhalten. Auch ein
Dateiname mit `current` bezeichnet dort den damaligen Buildvertrag. Ihre
Prüfungen werden am ausdrücklich ausgewählten Originalcommit ausgeführt und
qualifizieren neue Deploymentbytes nicht. Es werden keine historischen Pins
oder ursprünglichen Archive durch neue Hashes ersetzt.

Ein neuer Build benötigt eine tatsächliche Quell-/Binarybindung, notwendige
aktuelle Prüfungen und grüne Head-/Main-CI. Veröffentlichen oder Taggen ist
ein eigener Benutzerauftrag; Paketbau allein gibt das nicht frei.
