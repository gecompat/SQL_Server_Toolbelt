# SSIS-Pipelinebuild: Qualifikation und Paketbindung

Historischer Pipelinebuild aus PR #446. Die folgenden Ergebnisse und
Paketbeschreibungen behalten ihre damaligen Build-, Paket- und Methodenbindungen.
Der neue Lookup-Build hat einen [eigenen Nachweis](SSIS-LOOKUP-QUALIFICATION.md).

Stand 2026-10-25. Diese Folgequalifikation bindet den bereits freigegebenen
gemeinsamen Pipeline-Identitätskern aus PR #435 an den SQL-CLR-Build und die
v1.0.0-Installationskandidaten. Die öffentliche SQL-API, Modulversion 1.0.0,
Parser-/ScriptDom-Pins und Sicherheitsbudgets bleiben unverändert.
Eine Veröffentlichung ist nicht autorisiert.

## Was neu geprüft wurde

| Umfang | Tatsächliches Ergebnis | Gebundener Nachweis |
|---|---|---|
| Neuer SSIS-Binary | Reproduzierbarer Doppelbau; 23 isolierte Frameworkfälle und 147 gemeinsame CLR-/Hostgegenproben | [Buildprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Pipeline.Windows.CL.20261025.json) |
| Windows SQL2019/2022/2025 | Zwölf lokale/zentrale Engine-/CL-Fälle mit 3516 Assertions: API, Callerrechte, Grenzen, Lifecycle und echtes Upgrade | dieselbe Buildprojektion |
| Eigenständiges SSIS-ZIP | Zwei Windows-SQL2025-Kontexte, 226 Assertions, entpackte Skripte mit ODBC-sqlcmd, Erst-/Repeatinstallation und Uninstall/Repeat | [Paketprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Pipeline.InstallPackage.20261025.json) |
| CLR-Paket | Sechs neue Windows-Engine-/CL-Fälle, jeweils lokal/zentral mit Consumer | [CLR-Projektion](https://github.com/gecompat/SQL_Server_Toolbelt/blob/d228163a945678044032d3868dd11425f5f6a457/Releases/1.0.0/clr-ssis-qualification.json) |
| Gesamtpaket | Sechs neue Windows-Engine-/CL-Fälle, jeweils lokal/zentral mit Consumer | [Gesamtpaketprojektion](https://github.com/gecompat/SQL_Server_Toolbelt/blob/d228163a945678044032d3868dd11425f5f6a457/Releases/1.0.0/complete-ssis-qualification.json) |

Die Matrix umfasst SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170.
Jeder neue mutierende Fall hatte einen eigenen äußeren Watchdog. Die Grenzen
bleiben 300 Sekunden Arbeit, 360 Sekunden Cleanupdeadline und 400 Sekunden außen;
einzelne SQL-Kommandos bleiben auf höchstens 45 Sekunden begrenzt.
Alle 26 fachlichen Treiberfälle bestanden und wurden unabhängig auditiert.
Zwei Wrapperläufe endeten zunächst mit Fehler, weil ein gleichzeitig erkannter
Labverbraucher die Wiederherstellung unserer Konfiguration blockierte. Nach
dessen Ende wurde ausschließlich der unveränderte eigene Änderungsscope
in je einem zusätzlichen Recoveryversuch wiederhergestellt und frisch unabhängig
geprüft. Die ursprünglichen Wrapperfehler bleiben erhalten; die bereits grünen
Fachtests wurden nicht wiederholt. Insgesamt wurden 28 native Versuche gezählt. Abschließende
frische Prüfungen bestätigten die Abwesenheit eigener Datenbanken, unveränderte
Inputpins sowie wiederhergestellte Trust- und Konfigurationszustände. Private
Journale, Identitäten und Rohlogs werden nicht ausgeliefert.

Der erste externe Hosttest konnte wegen der fehlenden Python-Testdependency
`jsonschema` nicht beginnen. Nach Bereitstellung der bereits im CI gepinnten
Version 4.26.0 in einem isolierten Verzeichnis bestanden 147 Gegenproben.
Dieser Setupfehler war kein nativer SQL-Test und wurde nicht als PASS ausgegeben.

## Installation und Upgrade

Das [eigenständige SSIS-ZIP](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md)
enthält 189 Dateien: fertige Assemblies, originale Trustmanifeste,
SQL-/PowerShell-Skripte, Quellcode, Lizenzen und das vollständige SSMS-Beispiel.
`START-HERE.txt` führt durch die Installation. Der neue Installeraufruf benötigt
keinen eigenen Build; der optionale externe Exporthost ist kein Bestandteil
dieses SQL-Installationspakets.

Der Upgradefall beginnt mit dem tatsächlich in PR #442 ausgelieferten
Scope-Identitätsbuild und endet mit dem neuen Pipelinebuild. Beide tragen
dieselbe Modulversion; geprüft wurden die unterschiedlichen tatsächlichen
Binarybytes, erhaltene Assembly-/Prozeduridentitäten und die wiederverwendete
alte JSON-Vorlage. Frühere Upgradepfade behalten ihre ursprünglichen Nachweise.

Der Installationssatz ist ein unveränderlicher Snapshot seines Paketcommits.
Die nach der Ausführung ergänzte Paketprojektion bindet seinen exakten ZIP-Hash
im Repository. Spätere Nachweis-/Dokumentationspflege verändert seine enthaltenen
DLL-/SQL-Bytes nicht. Das [CLR-Paket](CLR-INSTALL.md) übernimmt genau denselben
qualifizierten SSIS-Binary. Die übrigen zwölf gelieferten DLLs einschließlich
ScriptDom bleiben gegenüber der früheren Lieferung bytegleich.

## Historische Nachweise und Paketprüfung

Die [vorherige SSIS-Teilqualifikation](SSIS-RELEASE-QUALIFICATION.md) bleibt
historisch. Ihre damaligen Gesamtpaketprojektionen sind im öffentlichen
[PR #442-Mergestand](https://github.com/gecompat/SQL_Server_Toolbelt/tree/ccedd1143d17e56d3067f72bbb3f622849c4e9a4/Releases/1.0.0)
unverändert verfügbar. Aktuelle CLR-/Gesamtpaketprojektionen ersetzen keine
historischen Ausführungsdaten durch einen neuen Methodencode.

Der [Produktdelta-Nachweis](https://github.com/gecompat/SQL_Server_Toolbelt/blob/d228163a945678044032d3868dd11425f5f6a457/Releases/1.0.0/ssis-release-update.json) vergleicht die aktuelle
Lieferung weiter mit der ursprünglichen stabilen Produktbasis. Die Herkunft
des damaligen Archivs und die spätere öffentliche Integrationsbasis für
Test-/Dokumentationspflege sind separat gebunden. Außerhalb von SSIS bleiben
Runtime-/Deployment-/Workerbytes geschützt; nur ausdrücklich ausgewählte,
bereits integrierte Tests und Dokumentation dürfen exakt aus dieser Basis
übernommen werden. Zwei neue Offlinegegenproben sichern diese Trennung sowie
die Abweisung nicht integrierter oder fachlicher Änderungen.

Die sechs früheren Linux-Fälle pro Gesamtpaket bleiben ausschließlich wegen
exakt gleicher Portable-SQL-Payloads und unveränderter zugehöriger Binaries
anwendbar. Es gab keine neue Linux-Ausführung. Der SSIS-Generator bleibt
Windows-only; eine Preview-Kennzeichnung ersetzt keine Pflichtprüfung.

Der bestehende CLR-Packer bindet Doppelbuildberichte an den gesamten
Modules-/Deployment-Quellbaum. Deshalb wurde der finale Paketquellstand einmal
mit dem bestehenden Zwölfprojekt-Doppelbau geprüft. Bereits gültige native
Nicht-SSIS-Fälle werden nicht wiederholt. Die vorhandenen Offline-Workflows
und Zeitgrenzen bleiben erhalten; keine neuen CI-Jobs, Reviewerketten oder
periodischen Vollprüfungen entstehen. Die Abschlussprüfung umfasst den
vollständigen Release-/Dokumentationsaudit und einen frischen Checkout mit
Bundle-Recovery, weil lokale synthetische Produktobjekte kein CI-Nachweis sind.

## Verbleibende Grenzen

Functional-Tests verwenden verpflichtende Verschlüsselung und den expliziten
Trustwert des schema-validierten Labvertrags ohne Provider-/TLS-Fallback.
Authentifizierte TLS-Abnahme bleibt separat. Ebenso offen bleiben die manuelle
SSMS-GUI-/Windows-Identitätsabnahme, externe Linux-Hostausführung und dessen
fertige Hostlieferung sowie über diesen Scope hinausgehende Ressourcen-,
Recovery- und Produktionsnachweise. SSISDB-Consumerkorrelation besitzt ihren
eigenen Vertrag und Nachweis. Die übrigen Modul-/Releasegates stehen in
[RELEASE-GATES.md](RELEASE-GATES.md); dieses Paket ist keine Gesamtfreigabe.
