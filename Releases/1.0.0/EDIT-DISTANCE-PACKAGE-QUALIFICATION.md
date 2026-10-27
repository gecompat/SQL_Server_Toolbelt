# Edit Distance: Paketbindung der festen Verträge

Die gelieferte `Toolbelt.String.EditDistance.dll` wurde aus dem unveränderten
CLR-Installationspaket gelesen und mit den festen Verträgen des vorhandenen
Modultests geprüft. Paket, Sidecar, Manifest, Modulquellen und die vier
Contract-/Oracle-Dateien wurden vor und nach dem Lauf gebunden. Die extrahierte
DLL blieb bytegleich zu ihrem Paketeintrag.

Der paketgebundene Adapter für diese festen Verträge bestand mit 27.104 Distance-Zeilen,
60 Jaro-Paaren über `de-DE`, `en-US` und `tr-TR` sowie insgesamt 109.333
Assertions. Die unabhängige Referenzprüfung erfasste weitere 21.185 Assertions.
Ein begrenzter direkter IL-Inspektionslauf bestand ebenfalls. Er ist kein
vollständiger No-I/O- oder Sicherheitsnachweis.

Der erste Runnerstart wurde vor dem Kindprozess wegen des Ausgabepfads
abgewiesen. Ein späterer Lauf bestand die Fachphasen, wurde aber im
abschließenden Eingabepin-Audit wegen einer unvollständigen Pfadliste
zurückgewiesen. Der finale Lauf bestand mit vollständigen Vor-/Nachpins.
Diese Historie bleibt vom finalen PASS getrennt.

Die maschinenlesbare [Evidenz](EDIT-DISTANCE-PACKAGE-QUALIFICATION.json)
bindet Paket, DLL, Modulquellen, feste Orakel und Qualifikationsadapter. Es
wurde keine SQL- oder Labverbindung verwendet. Modulstatus, Paketinhalt und
Veröffentlichungsfreigabe ändern sich durch diesen begrenzten Offlinebeleg
nicht. Weitere API-, Minimalrechte-, Ressourcen-, Lifecycle- und vollständige
CLR-Nachweise bleiben separat.
