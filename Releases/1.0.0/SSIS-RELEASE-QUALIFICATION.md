# SSIS-Teilqualifikation und Paketupdate vom 2026-10-25

Status: **im v1.0.0-Kandidaten vorbereitet, nicht verÃ¶ffentlicht**. Dieses manuell
freigegebene Arbeitspaket nimmt keine allgemeine autonome Weiterentwicklung auf.
Die Freigabematrix bleibt bei 19 Stable- und 26 Preview-Kandidaten; SSIS bleibt
`partially validated` und `unreleased`.

## GeprÃ¼fte Lieferung

Der eingefrorene Lieferstand `192e8c424d526d43cfa0db2ca5c4aa0b6c3ef95e` enthÃ¤lt
den Scope-IdentitÃ¤tskern1.2 aus PR427. Die
[Produktdelta-Bindung](ssis-release-update.json) vergleicht ihn mit der vorherigen
Gesamtlieferung. AuÃŸerhalb SSIS bleiben Runtime-, Deployment- und Workerbytes
unverÃ¤ndert. Dokumentations-/Manifestpflege und die explizit begrenzten
Testpflegedateien mÃ¼ssen dem gebundenen Ã¶ffentlichen Integrationsstand entsprechen.
Keine neue Ã¶ffentliche SQL-API und keine SicherheitsbudgetÃ¤nderung.

| Windows-Ziel | explizit geprÃ¼fte Compatibility Levels | Modi |
|---|---|---|
| SQL Server 2019 |150| local und central |
| SQL Server 2022 |150,160| local und central |
| SQL Server 2025 |150,160,170| local und central |

Bereite Windows-Patchziele wurden gemÃ¤ÃŸ dem projektspezifischen Labvertrag
gewÃ¤hlt; das ist keine vollstÃ¤ndige Patchmatrix. Der Generator bleibt SQL-Dialekt150.
Die Datenbank-CLs wurden gesetzt und unabhÃ¤ngig ausgelesen.

Die [SSIS-Buildprojektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Release.Windows.CL.20261025.json)
belegt zwÃ¶lf Kontexte mit je 181 Kern-, 61 API-, 28 Rechte-/Grenzen-, 15 Lifecycle-
und 8 echten Upgrades: **3.516 Assertions**. Dazu gehÃ¶ren einzelne EXECUTE-/
Metadaten-/Katalogrechte und ihre strikten Abweisungen. Zum AusfÃ¼hren erzeugter
SELECT-Stufen ist Quell-SELECT nÃ¶tig; Help funktioniert mit EXECUTE allein.
Die bestehende4000-Zeichen-ID-Grenze und atomare Ablehnung Ã¼bergroÃŸer Pakete
sind geprÃ¼ft. Full 23 am exakten Provider und 128 externe Modellgegenproben
belegen zusÃ¤tzlich feste Ausgabe-, Parser-, Diagnose- und Zeitbudgets.

Die [finale ZIP-Projektion](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Release.InstallPackage.20261025.json)
bindet den185-Dateien-Installationssatz an zwei echte Windows2025-PaketlÃ¤ufe
lokal/zentral mit 226 Assertions. Enthalten sind fertige DLLs, SQL, PowerShell,
Anleitung, PaketÃ¼bersicht und SSMS-Beispiel; ein eigener Build ist nicht nÃ¶tig.
Neuinstallation, Repeat, Uninstall, erneutes Uninstall und der echte Upgradepfad
vom ausgelieferten Iterationsbuild bestehen. Assembly-/ObjektidentitÃ¤ten und
alte JSON-Vorlagen bleiben erhalten. Parser-/ScriptDom-Pins sind unverÃ¤ndert.

## CLR- und Gesamtpaket

[CLR-Nachweis](clr-ssis-qualification.json) und
[Gesamtpaketnachweis](complete-ssis-qualification.json) unterscheiden ausdrÃ¼cklich
**je sechs neue Windows-Kontexte** von **je sechs beibehaltenen Linux-Kontexten**.
Jeder neue Kontext prÃ¼ft beide Deploymentmodi und eine Consumer-Datenbank,
inklusive Repeat und zweimaligem Uninstall. Die Gesamtprofile enthalten 45/43
Module auf Windows local/central und 40/40 in den Portable-Profilen.

Die Ã¼brigen zwÃ¶lf DLLs einschlieÃŸlich Parser und ScriptDom sind bytegleich zur
vorherigen CLR-Lieferung; nur SSIS wird ersetzt. Alle Portable-SQL-Payloads sind
unverÃ¤ndert. Die Linux-AusfÃ¼hrungen werden deshalb in ihrem ursprÃ¼nglichen
Scope Ã¼bernommen und ausdrÃ¼cklich nicht als neue LÃ¤ufe ausgegeben. Die alten
Qualifikationsdateien bleiben erhalten. Die zwÃ¶lf CLR-Projekte wurden jeweils
zweimal isoliert gebaut; die ausgelieferten Ã¼brigen Binaries behalten ihre
qualifizierten Bytes. Die SSIS-/Parser-DLLs stammen aus dem qualifizierten ZIP.

Auch die 19 Stable-SQL-Payloads bleiben unverÃ¤ndert. Das eigenstÃ¤ndige Stable-SQL-
ZIP behÃ¤lt seine ursprÃ¼ngliche Quellarchiv-/Plan-/Nachweisbindung. Der Packer
prÃ¼ft diese feste Ã¶ffentliche VorgÃ¤ngerquelle; ein Neubinden an das es selbst
enthaltende neue Gesamtquell-ZIP wÃ¼rde eine zirkulÃ¤re Herkunftsangabe erzeugen.

## Cleanup, Fehler und PrÃ¼fgrenzen

Alle eigenen Datenbanken, TrustÃ¤nderungen und KonfigurationsÃ¤nderungen sind
unabhÃ¤ngig abschlieÃŸend auditiert. FÃ¼r jede der zwÃ¶lf neuen globalen PaketfÃ¤lle
bestehen zusÃ¤tzliche frische Cleanup-/Pin- und vollstÃ¤ndige Konfigurationsaudits.
Benutzer ohne Login und gezielte RechteÃ¤nderungen wurden ausschlieÃŸlich in
eigenen temporÃ¤ren Testdatenbanken verwendet.

Die manuelle Welle umfasst 34 von 36 erlaubten nativen Treiberversuchen:
28 erfolgreiche FÃ¤lle, fÃ¼nf vollstÃ¤ndig bereinigte Fehler des neuen
SSIS-Testclients und einen vor jeder Mutation zurÃ¼ckgewiesenen
Connection-Builder-Fehler des Paketadapters. Die korrigierten Inputs wurden
qualifiziert; kein Fehllauf wurde nachtrÃ¤glich PASS. Zwei erfolgreiche frÃ¼here
ZIP-FÃ¤lle bleiben gezÃ¤hlt; nach ErgÃ¤nzung der fehlenden internen PaketÃ¼bersicht
wurde der geÃ¤nderte endgÃ¼ltige Container nochmals in beiden Modi geprÃ¼ft.
UrsprÃ¼nglicher Start und acht Stunden Gesamtgrenze bleiben erhalten.

Die Grenzen 300 Sekunden Arbeit, 360 Sekunden Cleanup und 400 Sekunden Ã¤uÃŸerer
Watchdog wurden nicht erhÃ¶ht. Functional-LÃ¤ufe verwenden Encrypt=True und den
expliziten schema-validierten Lab-Trustwert ohne Provider-/TLS-Fallback.
Reale Endpoints, Zugangsdaten, Journale, Runtimewerte und Rohlogs bleiben privat.
Kosten und Tokens sind UNKNOWN. Aktuelle Head-CI wird im zugehÃ¶rigen PR gefÃ¼hrt.

## Weiter offen

- SSMS-GUI und eine nutzbare Windows-TestidentitÃ¤t fÃ¼r den vollstÃ¤ndigen Ã¶ffentlichen Clientweg.
- Authentifizierte TLS-Abnahme als eigener Scope; sie ersetzt keine FachprÃ¼fung.
- Linux-AusfÃ¼hrung und fertige Auslieferung des externen Exporthosts; im ZIP ist kein Host-Executable zugesagt.
- Echte SSISDB-Korrelation, SDK-/Realdatenpaket-ParitÃ¤t sowie nicht zugesagte Komponenten.
- Noch nicht belegte vollstÃ¤ndige Minimalrechte-/CrossDB-IdentitÃ¤ts-, Heap-/ParallelitÃ¤ts-, harte Recovery- und Produktionsgates.
- Gesamtfreigabe und ausdrÃ¼ckliche VerÃ¶ffentlichung von v1.0.0.

Diese Nachweise schlieÃŸen den genannten endlichen Lab- und Paketierungsscope.
Sie stufen keine Module hoch und erklÃ¤ren nicht alle 45 Module fÃ¼r vollstÃ¤ndig
abgenommen. Die [Releasegates](RELEASE-GATES.md) und der [Supportvertrag](SUPPORT.md)
bleiben maÃŸgeblich. Installation beginnt bei [INSTALL.md](../../INSTALL.md).


## Dokumentationsintegration nach den nativen LÃ¤ufen

Der tatsÃ¤chliche native AusfÃ¼hrungsstand bleibt
`fbd20b952f3e8c37ddda56b3d245ce71ce60af6e`, Methodencode `66ed4fa`.
Zwischen ihm und dem Lieferstand unterscheiden sich innerhalb der Produktpfade
nur Markdown-Dateien sowie die Kommentarposition im SSIS-Manifest. Der
Produktdelta-Nachweis enthÃ¤lt beide vollstÃ¤ndigen Pfad-/Hashmengen; alle anderen
Produktbytes bleiben gleich. Das Ã¤ndert keine nativen AusfÃ¼hrungsbehauptungen
und lÃ¶st keinen erneuten SQL-Test aus.

Der vorhandene CLR-Packer bindet seinen Buildbericht bewusst an den gesamten
Modules-/Deployment-Baum. Daher ist nach dieser Dokumentationsintegration ein
weiterer begrenzter Doppelbau nÃ¶tig; die alte BuildausfÃ¼hrung bleibt erhalten.
Das Gate wurde nicht abgeschwÃ¤cht. Das ist ein zusÃ¤tzlicher Offlineaufwand ohne
neue NativefÃ¤lle, CI-Jobs, Trigger, Reviewketten oder Modellaufrufe.


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
