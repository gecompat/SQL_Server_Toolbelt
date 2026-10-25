# SSIS-Teilqualifikation und Paketupdate vom 2026-10-25

Status: **im v1.0.0-Kandidaten vorbereitet, nicht veröffentlicht**. Dieses manuell
freigegebene Arbeitspaket nimmt keine allgemeine autonome Weiterentwicklung auf.
Die Freigabematrix bleibt bei 19 Stable- und 26 Preview-Kandidaten; SSIS bleibt
`partially validated` und `unreleased`.

## Geprüfte Lieferung

Der eingefrorene Lieferstand `192e8c424d526d43cfa0db2ca5c4aa0b6c3ef95e` enthält
den Scope-Identitätskern 1.2 aus PR #427. Die
[Produktdelta-Bindung](ssis-release-update.json) vergleicht ihn mit der vorherigen
Gesamtlieferung. Außerhalb SSIS bleiben Runtime-, Deployment- und Workerbytes
unverändert. Dokumentations-/Manifestpflege und die explizit begrenzten
Testpflegedateien müssen dem gebundenen öffentlichen Integrationsstand entsprechen.
Keine neue öffentliche SQL-API und keine Sicherheitsbudgetänderung.

| Windows-Ziel | explizit geprüfte Compatibility Levels | Modi |
|---|---|---|
| SQL Server 2019 |150| local und central |
| SQL Server 2022 |150,160| local und central |
| SQL Server 2025 |150,160,170| local und central |

Bereite Windows-Patchziele wurden gemäß dem projektspezifischen Labvertrag
gewählt; das ist keine vollständige Patchmatrix. Der Generator bleibt SQL-Dialekt 150.
Die Datenbank-CLs wurden gesetzt und unabhängig ausgelesen.

Die [SSIS-Buildprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Release.Windows.CL.20261025.json)
belegt zwölf Kontexte mit je 181 Kern-, 61 API-, 28 Rechte-/Grenzen-, 15 Lifecycle-
und 8 echten Upgrades: **3.516 Assertions**. Dazu gehören einzelne EXECUTE-/
Metadaten-/Katalogrechte und ihre strikten Abweisungen. Zum Ausführen erzeugter
SELECT-Stufen ist Quell-SELECT nötig; Help funktioniert mit EXECUTE allein.
Die bestehende 4000-Zeichen-ID-Grenze und atomare Ablehnung übergroßer Pakete
sind geprüft. Full 23 am exakten Provider und 128 externe Modellgegenproben
belegen zusätzlich feste Ausgabe-, Parser-, Diagnose- und Zeitbudgets.

Die [finale ZIP-Projektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Release.InstallPackage.20261025.json)
bindet den 185-Dateien-Installationssatz an zwei echte Windows 2025-Paketläufe
lokal/zentral mit 226 Assertions. Enthalten sind fertige DLLs, SQL, PowerShell,
Anleitung, Paketübersicht und SSMS-Beispiel; ein eigener Build ist nicht nötig.
Neuinstallation, Repeat, Uninstall, erneutes Uninstall und der echte Upgradepfad
vom ausgelieferten Iterationsbuild bestehen. Assembly-/Objektidentitäten und
alte JSON-Vorlagen bleiben erhalten. Parser-/ScriptDom-Pins sind unverändert.

## CLR- und Gesamtpaket

[CLR-Nachweis](clr-ssis-qualification.json) und
[Gesamtpaketnachweis](complete-ssis-qualification.json) unterscheiden ausdrücklich
**je sechs neue Windows-Kontexte** von **je sechs beibehaltenen Linux-Kontexten**.
Jeder neue Kontext prüft beide Deploymentmodi und eine Consumer-Datenbank,
inklusive Repeat und zweimaligem Uninstall. Die Gesamtprofile enthalten 45/43
Module auf Windows local/central und 40/40 in den Portable-Profilen.

Die übrigen zwölf DLLs einschließlich Parser und ScriptDom sind bytegleich zur
vorherigen CLR-Lieferung; nur SSIS wird ersetzt. Alle Portable-SQL-Payloads sind
unverändert. Die Linux-Ausführungen werden deshalb in ihrem ursprünglichen
Scope übernommen und ausdrücklich nicht als neue Läufe ausgegeben. Die alten
Qualifikationsdateien bleiben erhalten. Die zwölf CLR-Projekte wurden jeweils
zweimal isoliert gebaut; die ausgelieferten übrigen Binaries behalten ihre
qualifizierten Bytes. Die SSIS-/Parser-DLLs stammen aus dem qualifizierten ZIP.

Auch die 19 Stable-SQL-Payloads bleiben unverändert. Das eigenständige Stable-SQL-
ZIP behält seine ursprüngliche Quellarchiv-/Plan-/Nachweisbindung. Der Packer
prüft diese feste öffentliche Vorgängerquelle; ein Neubinden an das es selbst
enthaltende neue Gesamtquell-ZIP würde eine zirkuläre Herkunftsangabe erzeugen.

## Cleanup, Fehler und Prüfgrenzen

Alle eigenen Datenbanken, Truständerungen und Konfigurationsänderungen sind
unabhängig abschließend auditiert. Für jede der zwölf neuen globalen Paketfälle
bestehen zusätzliche frische Cleanup-/Pin- und vollständige Konfigurationsaudits.
Benutzer ohne Login und gezielte Rechteänderungen wurden ausschließlich in
eigenen temporären Testdatenbanken verwendet.

Die manuelle Welle umfasst 34 von 36 erlaubten nativen Treiberversuchen:
28 erfolgreiche Fälle, fünf vollständig bereinigte Fehler des neuen
SSIS-Testclients und einen vor jeder Mutation zurückgewiesenen
Connection-Builder-Fehler des Paketadapters. Die korrigierten Inputs wurden
qualifiziert; kein Fehllauf wurde nachträglich PASS. Zwei erfolgreiche frühere
ZIP-Fälle bleiben gezählt; nach Ergänzung der fehlenden internen Paketübersicht
wurde der geänderte endgültige Container nochmals in beiden Modi geprüft.
Ursprünglicher Start und acht Stunden Gesamtgrenze bleiben erhalten.

Die Grenzen 300 Sekunden Arbeit, 360 Sekunden Cleanup und 400 Sekunden äußerer
Watchdog wurden nicht erhöht. Functional-Läufe verwenden Encrypt=True und den
expliziten schema-validierten Lab-Trustwert ohne Provider-/TLS-Fallback.
Reale Endpoints, Zugangsdaten, Journale, Runtimewerte und Rohlogs bleiben privat.
Kosten und Tokens sind UNKNOWN. Aktuelle Head-CI wird im zugehörigen PR geführt.

## Weiter offen

- SSMS-GUI und eine nutzbare Windows-Testidentität für den vollständigen öffentlichen Clientweg.
- Authentifizierte TLS-Abnahme als eigener Scope; sie ersetzt keine Fachprüfung.
- Linux-Ausführung und fertige Auslieferung des externen Exporthosts; im ZIP ist kein Host-Executable zugesagt.
- Echte SSISDB-Korrelation, SDK-/Realdatenpaket-Parität sowie nicht zugesagte Komponenten.
- Noch nicht belegte vollständige Minimalrechte-/CrossDB-Identitäts-, Heap-/Parallelitäts-, harte Recovery- und Produktionsgates.
- Gesamtfreigabe und ausdrückliche Veröffentlichung von v1.0.0.

Diese Nachweise schließen den genannten endlichen Lab- und Paketierungsscope.
Sie stufen keine Module hoch und erklären nicht alle 45 Module für vollständig
abgenommen. Die [Releasegates](RELEASE-GATES.md) und der [Supportvertrag](SUPPORT.md)
bleiben maßgeblich. Installation beginnt bei [INSTALL.md](../../INSTALL.md).


## Dokumentationsintegration nach den nativen Läufen

Der tatsächliche native Ausführungsstand bleibt
`fbd20b952f3e8c37ddda56b3d245ce71ce60af6e`, Methodencode `66ed4fa`.
Zwischen ihm und dem Lieferstand unterscheiden sich innerhalb der Produktpfade
nur Markdown-Dateien sowie die Kommentarposition im SSIS-Manifest. Der
Produktdelta-Nachweis enthält beide vollständigen Pfad-/Hashmengen; alle anderen
Produktbytes bleiben gleich. Das ändert keine nativen Ausführungsbehauptungen
und löst keinen erneuten SQL-Test aus.

Der vorhandene CLR-Packer bindet seinen Buildbericht bewusst an den gesamten
Modules-/Deployment-Baum. Daher ist nach dieser Dokumentationsintegration ein
weiterer begrenzter Doppelbau nötig; die alte Buildausführung bleibt erhalten.
Das Gate wurde nicht abgeschwächt. Das ist ein zusätzlicher Offlineaufwand ohne
neue Nativefälle, CI-Jobs, Trigger, Reviewketten oder Modellaufrufe.


Der Dokumentsynchronisationsfehler wurde durch Einrücken zweier Kommentare
innerhalb der Manifestsektion behoben; alle YAML-Schlüssel und Werte bleiben
unverändert. Der Lieferproduktbaum schließt erzeugte Quellarchive explizit aus,
wie bereits die kanonische Quellsnapshot-Auswahl. So werden frühere Quell-ZIPs
nicht rekursiv im Recovery-Bundle eines neuen Quell-ZIPs verpackt. Ursprung,
Ausgabenausschluss und exakter Produktbaum sind im Produktnachweis festgehalten.

Der eigenständige SSIS-Installationssatz bleibt der exakt nativ geprüfte
185-Dateien-Container. Seine Buildquellen und Statusabschnitte sind ein
unveränderter Snapshot seines Paket-Sourcecommits. Spätere Abnahmeprojektionen
und generierte Statuspflege stehen im Repository und im aktualisierten
Gesamtquellpaket; sie ändern keine enthaltenen SQL-/DLL-Bytes oder Installationsschritte.


Auch die abschließende Korrektur der generierten Dokumentationskopplung löst
wegen dieses bestehenden breiten Buildguards einen weiteren Offline-Doppelbau
aus. Alle zwölf Binaries sind über alle drei Buildwellen bytegleich. Native
Fälle werden dafür nicht wiederholt; der 36er-Rahmen bleibt bei 34 Versuchen.
Die drei historischen Release-Regressionen vergleichen alte ODBC-/Rechte-/
Adapterausführungen mit ihrem tatsächlich qualifizierten Vorgängerarchiv und
verändern weder deren Hashes noch die Fehlerorakel.


Die vollständige Offline-Regressionssuite behält ihre 120-Sekunden-Grenze.
Wiederholtes Entpacken und Rekonstruieren derselben historischen Quellen wird
nur innerhalb dieses Testprozesses gemeinsam genutzt. Der Cachekey bindet
Repositoryscope, Produkt-ID, Quellarchiv, Prüfsummensidecar und beide relevanten
Anwendbarkeitsnachweise jeweils an aktuelle Inhalts-Hashes. Unbekannte oder
geänderte Inputs laufen durch den ursprünglichen Validator; Fehler werden
nicht gecacht. Kopierte Rückgabedictionaries verhindern Fixtureveränderungen
durch negative Gegenproben. Eine zusätzliche Regression prüft Treffer,
Dependencyänderung, isolierte Rückgaben und wiederholte Ablehnungen.
Das ändert weder Produktvalidatoren noch native Testorakel oder Zeitbudgets.


Die Offline-Paketprüfung löst einen im frischen Checkout fehlenden synthetischen
Produktbaum aus dem geprüften Bundle auf. Native Methodenbindungen behalten ihre
ursprünglichen Hashes; spätere Offline-Prüfer ersetzen die ausgeführten Methoden
nicht. Zulässig ist ausschließlich die exakt hashgleiche historische Quelle aus
dem Quellen- oder Produktsnapshot desselben Bundles. Abweichende Bäume, beschädigte
Pakete und geänderte ausgelieferte Methoden bleiben Fehler. Diese Korrektur ändert
keine DLL, keinen SQL-Payload und keinen nativen Ausführungsnachweis.
