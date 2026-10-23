# v1.0.0 – Entwurf der Release Notes

**Nicht veröffentlicht.** Die Projektversion bündelt den aktuellen Bestand
von 45 implementierten Modulen; ihre individuellen Versionsnummern bleiben
erhalten. Freigegebene Zielkanäle: 19 stabil, 26 Preview. Der
[Support-Zielumfang](SUPPORT.md) erteilt noch keine öffentliche Supportzusage. Die
[Freigabematrix](FREIGABEMATRIX.md) nennt jede Version, Dependencies und offene
Abnahmegrenzen; der [Plan](release-plan.json) ist die maschinenlesbare Ableitung.

## Umfang

- Kern-, Datums-, Konvertierungs-, Metadaten-, Text-, JSON-, Datei-/Archiv-,
  Pseudonymisierungs- und Orchestrierungsmodule mit ihren bestehenden APIs.
- SSIS-Debug einschließlich JSON-Variablenvorlage, änderbaren DECLARE-Werten,
  einzeln testbaren CTE-Stufen, SSMS-Beispiel und vorhandenem Windows-Installationssatz.
- Vollständige Quellen und Anleitungen sowie zusätzliche eigenständige
  SQL-Exports der stabilen Kandidaten für lokales/zentrales Deployment.
- Erhaltene AI Repository Foundation 1.25.0 mit gebundener Provenienz und
  getrennten menschlichen Lesewegen; keine neue optionale Runtime aktiviert.
- Reproduzierbare CLR-Buildprüfung und nativer Pakettest der stabilen Exports;
  ausgeführter Scope und verbleibende Grenzen im [Gatebericht](RELEASE-GATES.md).
- Zusätzlicher [CLR-Installationssatz ohne eigenen Build](CLR-INSTALL.md):
  zwölf Toolbelt-DLLs, ScriptDom, Quellcode, Trust und fertige SQL-Dateien;
  Windows-/Portable- sowie lokale/zentrale Profile sind nativ paketgeprüft.

## Grenzen und Migration

Diese Vorbereitung verändert weder SQL-APIs noch Modulversionen oder
Deployment-/Trustregeln. Upgrades bleiben an die tatsächlich unterstützten
historischen Modulversionen gebunden; die Projektversion 1.0.0 ist kein
universeller Upgradepfad. Backups und ein eigener Installationstest sind
gemäß dem jeweiligen Modulvertrag einzuplanen.

Alle Modulmanifeste sind noch `unreleased`. Preview ist keine pauschale
Qualifikation. Die vorgebauten CLR-Binaries sind an ihre Paketnachweise gebunden;
genaue Supportkombinationen und vollständige fachliche Pflichtnachweise müssen
vor einer öffentlichen Supportzusage abgenommen sein. Die
authentifizierte TLS-Abnahme bleibt separat; unabhängige Functional-Nachweise
gelten ausschließlich für ihren dokumentierten Transport-/Funktionsscope.

Tatsächlicher Tag, Veröffentlichungsdatum, URL und finale Assethashes werden
erst bei einer separat autorisierten Veröffentlichung eingetragen. Bis dahin
ist [README](README.md#vor-einer-veröffentlichung) die verbleibende Checkliste.
