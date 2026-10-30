# Vorgänger der vollständigen Parameterhilfe

`Predecessors.zip` bewahrt 68 exakte Quellen aus Main `a11426b5` und die
unveränderte Projektlizenz. Der geschlossene Adapter
[`parameter_help_transition.py`](../../parameter_help_transition.py) prüft die
Archivbytes und die erlaubte Projektion: ausschließlich generierte Hilfeblöcke,
SSIS-Parameterbeschreibungen und die SSIS-CLR-Hilfekonstante dürfen abweichen.
Fachliche SQL-/CLR-Implementierung und historische Nachweise bleiben gebunden.

Das Archiv ist kein Installationspaket und kein Laufzeitnachweis der neuen Hilfe.

`Verifiers.zip` erhält außerdem die 24 unmittelbar vorherigen Lesadapter und
Offlineprüfer. `VerifierPins.json` und seine feste Bindung im Adapter erlauben
ausschließlich die geprüften aktuellen Bytefolgen. Vor einer älteren
Methodenprüfung wird genau dieser Lesadapter rückprojiziert; beliebige weitere
Änderungen bleiben ein Fehler. Alte Quellpins, Oracles, Berichte und deren
Nachweisumfang werden weder neu gepinnt noch als Abnahme der neuen Hilfe ausgegeben.

Auch der parallel integrierte SSIS-Snapshot-Nachweis verwendet diese geschlossene
Quellprojektion. Sein ausgeführtes Paket und seine Snapshot-Oracles bleiben
unverändert. Der SSIS-Generator ist dafür mit seiner exakten Vorher-/Nachher-
Bytefolge gebunden; seine neue Hilfe qualifizieren die separaten Help-Tests.
