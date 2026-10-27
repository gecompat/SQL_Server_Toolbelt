# T-SQL-Scriptparser: begrenzte Paketbindung

Dieser Nachweis bindet den gelieferten `Toolbelt.Tsql.ScriptParser.dll`-Eintrag
an einen festgelegten Satz vorhandener Parserverträge. Paket, Sidecar,
Qualifikationsdatei und insgesamt 16 repo-relative Eingabepins wurden vor und
nach dem Lauf geprüft. Diese Pins umfassen Paket, Sidecar,
Qualifikationsdatei, Prozesshelfer, Adapter/Fixture und neun
Modul-/Harnessquellen. Der Extrakt blieb bytegleich mit dem Paket.

## Geprüfter Umfang

Der paketgebundene Providerlauf bestand 63 isolierte Aufrufe mit exakt
`FRAMEWORK_PASS` und LF-Zeilenende:

- ein Parametervertrag;
- zehn bestehende Parser-Versionsprofile (80 bis 170);
- 16 feste Korpusfälle für SQL-Versionen 150, 160 und 170;
- vier Versionsgrenzen für Window-Aggregate und `JSON_ARRAYAGG`.

Der Korpus stammt aus dem vorhandenen Contractskript. Seine festen Eingaben
sind in [der maschinenlesbaren Evidenz](SCRIPT-PARSER-PACKAGE-QUALIFICATION.json)
mit repo-relativen SHA-256-Pins gebunden.

Separat bestand ein aus dem Modulquellcode gebauter Guard mit 60 Assertions.
Dieser Source-Guard ist kein Paket-DLL-Nachweis. Der Lauf umfasste 67
aufgezeichnete Prozessstufen; Paket, Sidecar, Qualifikationsdatei, Eingaben,
Werkzeuge, extrahierte DLLs, erzeugte Harnessdateien und Korpusdateien hatten
übereinstimmende Vorher-/Nachher-Pins. Vier Negativkontrollen wiesen ein
falsches Paket, eine falsche Sidecar-Prüfsumme, eine geänderte
Qualifikationsdatei und einen ZIP-Pfad außerhalb des Archivs zurück.

Ein Runset-Schemafehler wurde vor dem ersten Provideraufruf abgewiesen. Ein
späterer Fixturehashfehler folgte auf elf erfolgreiche Provideraufrufe. Ein
zunächst erfolgreicher Lauf mit Windows-Arbeitskopie-Zeilenenden wurde danach
durch einen erneuten Lauf mit den kanonischen LF-Bytes ersetzt. Die finale
Evidenz und alle Pins beziehen sich auf diesen LF-Lauf; die frühere Historie
bleibt getrennt erhalten.

## Grenzen

Das ist eine begrenzte Paketbindung der ausgewählten festen Tests. Sie belegt
weder eine vollständige Modul- oder Plattformmatrix noch eine transitive
IL-/No-I/O-Qualifikation, SQL-/Labbereitstellung, Berechtigungen,
Deployment oder Gesamt-CLR-Freigabe. Der Source-Guard bleibt davon getrennt.
Es wurden keine SQL- oder Labverbindungen geöffnet. Modulstatus, Manifest,
Paketinhalt und Veröffentlichungsfreigabe wurden nicht geändert.
