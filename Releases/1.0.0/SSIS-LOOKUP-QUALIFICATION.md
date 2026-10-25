# SSIS-Lookup-Ausgangsrollen: Qualifikation und Paketbindung

Stand 2026-10-25. Diese Folgequalifikation bindet den freigegebenen Build aus
PR #447 an die SQL-CLR- und v1.0.0-Installationspakete. Das bekannte Lookup-v6-
Profil kann seinen zweiten regulären Ausgang unabhängig von dessen Namen als
`NO_MATCH` kennzeichnen. Unbekannte Profile und mehrdeutige Ausgangsmengen
bleiben `UNKNOWN`. Die öffentliche SQL-API, Modulversion 1.0.0,
Parser-/ScriptDom-Pins und Sicherheitsbudgets bleiben unverändert.
Eine Veröffentlichung ist nicht autorisiert.

## Was neu geprüft wurde

| Umfang | Tatsächliches Ergebnis | Gebundener Nachweis |
|---|---|---|
| Neuer SSIS-Binary | Reproduzierbarer Doppelbau; 23 begrenzte Frameworkfälle und 165 gemeinsame CLR-/Hostgegenproben | [Buildprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.Windows.CL.20261025.json) |
| Windows SQL2019/2022/2025 | Zwölf lokale/zentrale Engine-/CL-Fälle mit 3516 Assertions: API, Callerrechte, Grenzen, Lifecycle und echtes Upgrade | dieselbe Buildprojektion |
| Eigenständiges SSIS-ZIP | Zwei Windows-SQL2025-Kontexte, 226 Assertions, entpackte Skripte mit ODBC-sqlcmd, Erst-/Repeatinstallation und Uninstall/Repeat | [Paketprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/LookupRoles.InstallPackage.20261025.json) |
| CLR-Paket | Sechs neue Windows-Engine-/CL-Fälle, jeweils lokal/zentral mit Consumer | [CLR-Projektion](clr-ssis-qualification.json) |
| Gesamtpaket | Sechs neue Windows-Engine-/CL-Fälle, jeweils lokal/zentral mit Consumer | [Gesamtpaketprojektion](complete-ssis-qualification.json) |

Die Matrix umfasst SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170.
Alle 26 neuen nativen Treiberfälle bestanden einschließlich unabhängiger
Cleanup-/Pin-/Konfigurationsaudits. Abschließende frische Prüfungen bestätigten
erneut die Abwesenheit eigener Datenbanken sowie die Wiederherstellung eigener
Trust- und Konfigurationsänderungen. Private Journale, Identitäten und Rohlogs
werden nicht ausgeliefert. Die Grenzen bleiben 300 Sekunden Arbeit,
360 Sekunden Cleanupdeadline und ein eigener äußerer Watchdog von 400 Sekunden;
einzelne SQL-Kommandos bleiben auf höchstens 45 Sekunden begrenzt.

Zwei Offline-Setupfehler bleiben dokumentiert: Der erste Launcher bot das
erforderliche PowerShell-Cmdlet nicht an; anschließend wurde der kanonische
`pwsh`-Launcher verwendet. Beim ersten externen Hostbuild fehlte der dokumentierte
explizite `SourceRevisionId`-Parameter, weshalb der Test die Produceridentität
vor dem Modellvergleich abwies. Nach dem entsprechend gebundenen Build bestanden
alle 165 Gegenproben. Beide Fehler lagen vor nativen SQL-Tests und werden nicht
als erfolgreiche Testläufe ausgegeben. Orakel und Sicherheitsbudgets wurden
nicht gelockert.

Die spätere lokale Releaseplanprüfung wies außerdem eine CRLF-Ausfertigung
des neuen Buildnachweises ab. Git und die qualifizierten Pakete enthielten
bereits dieselben korrekten LF-Bytes. Der lokale Arbeitsstand wurde exakt aus
dem versionierten Blob hergestellt; Hashprüfung und Artefakte blieben unverändert.
Diese Offlinekorrektur löste keine erneute native Ausführung aus.

## Installation und Upgrade

Das [eigenständige SSIS-ZIP](../../Modules/toolbelt.tsql.ssis-debug/InstallPackages/README.md)
enthält 191 Dateien: fertige Assemblies, originale Trustmanifeste,
SQL-/PowerShell-Skripte, Quellcode, Lizenzen und das vollständige SSMS-Beispiel.
`START-HERE.txt` führt durch die Installation; ein eigener Build ist nicht nötig.
Der optionale externe Exporthost ist kein Bestandteil dieses SQL-Installationspakets.

Das geprüfte Upgrade beginnt mit dem tatsächlich in PR #446 ausgelieferten
Pipelinebuild und endet mit dem neuen Lookup-Build. Trotz gleicher Modulversion
sind die unterschiedlichen Binarybytes gebunden. Assembly- und Prozeduridentitäten
bleiben erhalten, die alte JSON-Vorlage wird wiederverwendet. Frühere Upgradepfade
behalten ihre ursprünglichen Nachweise. Der Vorgänger ist im Labtreiber über
`Pipeline.Windows.CL.20261025.json` mit exaktem Quellcommit und Artefaktpins begrenzt.

Der Installationssatz ist ein unveränderlicher Snapshot seines Paketcommits.
Die spätere Paketprojektion im Repository bindet seinen exakten ZIP-Hash und
verändert die enthaltenen DLL-/SQL-Bytes nicht. Das [CLR-Paket](CLR-INSTALL.md)
übernimmt denselben qualifizierten SSIS-Binary. Die übrigen zwölf gelieferten
DLLs einschließlich ScriptDom sind gegenüber der vorherigen Lieferung bytegleich.

## Metadatenkorrektur und historische Nachweise

Die [Caller-Metadatenkorrektur](CALLER-METADATA-UPDATE.md) ergänzt in sechs
Modulmanifesten die bereits nativ geprüften einzelnen Objektrechte. Hierfür
werden ausschließlich die exakten bisherigen Manifestbytes und die fest
definierte Rechteänderung akzeptiert. Die ursprünglichen drei Callerberichte
bleiben unverändert; sie werden weder neu datiert noch als neue Ausführung
ausgegeben. SQL-/DLL-Änderungen außerhalb des qualifizierten SSIS-Builds sind
davon nicht gedeckt.

Der [Produktdelta-Nachweis](ssis-release-update.json) bindet die kombinierte
Lieferung an die ursprüngliche stabile Produktbasis und die öffentliche
Integrationsbasis. Die vorherige [Pipelinequalifikation](SSIS-PIPELINE-QUALIFICATION.md)
bleibt historisch mit ihren eigenen Paketen und Methoden. Ihre damaligen drei
Gesamtpaketprojektionen sind unverändert im öffentlichen
[Stand vor dieser Welle](https://github.com/gecompat/SQL_Server_Toolbelt/tree/d228163a945678044032d3868dd11425f5f6a457/Releases/1.0.0)
verfügbar. Neue Offlinegegenproben weisen zusätzliche Vertragsänderungen und
unqualifizierte Felder auch bei neu berechneten Dateihashes ab.

Die sechs früheren Linux-Fälle je Gesamtpaket bleiben ausschließlich wegen
exakt gleicher Portable-SQL-Payloads und unveränderter zugehöriger Binaries
anwendbar. Es gab keine neue Linux-Ausführung. Der SSIS-Generator bleibt
Windows-only; Preview ersetzt keine Pflichtprüfung.

Der CLR-Packer bindet seinen Buildbericht an den gesamten Modules-/Deployment-
Quellbaum. Deshalb wurde der finale Paketquellstand einmal mit dem bestehenden
Zwölfprojekt-Doppelbau geprüft. Unveränderte native Nicht-SSIS-Fälle werden
nicht wiederholt. Die vorhandenen CI-Prüfungen bleiben bestehen; es entstehen
keine neuen periodischen Tests oder zusätzlichen Reviewerketten. Zur
Abschlussprüfung gehören der vollständige Release-/Dokumentationsaudit sowie
die Archivprüfung in einem frischen Checkout ohne lokale synthetische
Produktobjekte. CI bleibt an den tatsächlichen PR-Head und Mergecommit gebunden.

## Verbleibende Grenzen

Functional-Tests verwenden verpflichtende Verschlüsselung und den expliziten
Trustwert des schema-validierten Labvertrags ohne Provider-/TLS-Fallback.
Authentifizierte TLS-Abnahme bleibt separat. Ebenso offen bleiben die manuelle
SSMS-GUI-/Windows-Identitätsabnahme, externe Linux-Hostausführung und dessen
fertige Hostlieferung sowie weitergehende Ressourcen-, Recovery- und
Produktionsnachweise. SSISDB-Consumerkorrelation besitzt ihren eigenen Vertrag
und Nachweis. Die übrigen Modul-/Releasegates stehen in
[RELEASE-GATES.md](RELEASE-GATES.md); diese Welle ist keine Gesamtfreigabe.
