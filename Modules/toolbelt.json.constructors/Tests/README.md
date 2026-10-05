# Testausführung

Die 1.2-Sourcewelle ergänzt `JsonEntryBridge.Contract.sql` und `JsonAggregates.Contract.sql`. Ein separat geprüfter privater CLR-Nativeadapter bestand am 2026-10-03 lokal auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/CU8 CL170 jeweils alle acht kanonischen Fixtures einschließlich Bridge, AGFs, Constructors und Gruppen-Grenzen. Eigene Bereinigung und frische Abwesenheitsprüfung bestanden; keine Serverkonfigurations-, Rechte- oder Owneränderung. Das ist keine vollständige Lifecycle-/Central-/Minimalrechte- oder Releasequalifikation. Der historische Gruppen-Labadapter stoppt bei Version 1.2 weiterhin vor Labdiscovery.

## Gemeinsamer CLR-Kern 1.2.0 (2026-10-03)

Die bekannte Produktzeile und ihre acht bytegleichen CLR-Quellen wurden
unabhängig offline qualifiziert: drei Cultures mit je37 Fällen/962 Assertions,
große synthetische3 Fälle/67 Assertions, reproduzierbares Binary und vollständige
IL-/Metadatenbindung. Der öffentliche Frameworkrunner bestand separat seinen
begrenzten Offlineumfang von37 kleinen und3 großen Fällen. Die vollständige
SQL-/Lifecyclekopplung bleibt offen. Die statische
Kopplung prüft den ArtifactId-Frame, acht Sourcehashes sowie unveränderte
globale SQL-Prüfungen und unverändertes ResultTable-Routing gegenüber1.1.

Am 2026-10-04 reproduzierte der begrenzte kanonische Projektbuild mit den fünf
im Projekt gesetzten Eigenschaften und ohne Profil-Overrides exakt die bekannte
qualifizierte Binaryzeile; Quellen und Ergebnisbytes wurden unabhängig geprüft.
CI deaktiviert zusätzlich Node-Reuse und automatische Response-Dateien.
Der lokale Nachweis mit MSBuild 18 ersetzt keine aktuelle CI-Qualifikation mit
ihrem ausgewählten Compilerstand. Registry, Binary und die acht CLR-Quellen
wurden dabei nicht geändert.

Die beiden lokalen Acht-Fixture-Läufe schließen nur die tatsächlich enthaltenen
Regressionen, Bridge-Rowformen und positiven leeren/gruppierten AGF-Proben.

Am 2026-10-04 bestand separat auf Windows 2025/CU8 CL170 die lokale Migration
eines genuine unveränderten 1.1-Pakets aus sieben SQL-Dateien zu 1.2. Vorher
wurden fünf Procedure-Slots ohne CLR-Assembly geprüft, danach acht Slots und
sechs exakt typisierte Assemblymarker. Repeat, die unveränderten Runtime-Fixtures
`InstalledMetadata.Contract.sql` und `Lifecycle.Contract.sql` sowie Uninstall
und wiederholter Uninstall bestanden. Der begrenzte Rootprozess endete mit
vollständigen Kanälen und unveränderten Eingabepins; eigene Bereinigung und
frische Abwesenheitsprüfung bestanden. Keine Serverkonfigurations-, Rechte-
oder Owneränderung. Dieser Einzelnachweis ist keine vollständige Produktqualifikation.

Am 2026-10-04 bestanden separat sechs lokale negative Fälle auf Windows
2025/CU8 CL170: fünf eigene Assemblymarkerfehler mit jeweils exakt
`53623/1` beim ersten originalen Deploy- und Uninstall-GO sowie ein eigener
synthetischer SQL-Consumer mit `53626/1` nur beim ersten Uninstall-GO.
Vollständige Katalogsnapshots blieben unverändert; eigene Marker und Consumer
wurden geprüft wiederhergestellt beziehungsweise entfernt. Uninstall/Repeat,
eigene Bereinigung und frische Abwesenheitsprüfung bestanden ohne
Konfigurations-, Rechte- oder Owneränderung. Der vorhandene Guest-Kontext war
mit exakt `916/4` nicht nutzbar und bleibt `NOT_EXECUTED`, nach bestätigtem
REVERT, gesunder Sitzung und identischem Snapshot. Der Ownerfall blieb ohne
autorisierte Owneränderung ebenfalls `NOT_EXECUTED`. Das sind sechs bestandene
Fälle, kein Acht-Fälle-PASS und kein vollständiger Lifecycle-Negativnachweis.
Frühere fehlgeschlagene Versuche bleiben historische Fehlversuche.

Am 2026-10-04 bestanden auf Windows 2025/CU8 CL170 außerdem getrennt die
lokale und zentrale Migration eines genuine unveränderten 1.0-Pakets aus fünf
SQL-Dateien zu 1.2: vorher drei Procedure-Slots ohne Assembly, danach acht Slots
und sechs exakt typisierte Assemblymarker. Repeat sowie die originalen
InstalledMetadata.Contract.sql- und Lifecycle.Contract.sql-Fixtures bestanden.
Zentral bestand zusätzlich das originale Central.Contract.sql im eigenen
Consumerkontext. Fehlende zentrale Bestätigung wurde nur im ersten originalen
Uninstall-GO mit exakt 53625/1 und identischem vollständigem Snapshot geprüft;
bestätigter Uninstall und Wiederholung bestanden in beiden Modi. Eigene
Bereinigung und frische Abwesenheitsprüfung bestanden ohne Konfigurations-,
Rechte- oder Owneränderung. Frühere fehlgeschlagene Adapterversuche bleiben
historisch; dies ist kein vollständiger Lifecycle-, Rechte- oder Produkt-PASS.

Weitere native Gates bleiben offen: vollständige AGF-Fehler-/Profilgrenzen,
Engine-Merge/Serialisierung, tatsächliche lokale und zentrale eingeschränkte
Callerrechte, weitere Upgrade-/Repeat-/Uninstall-Zielkombinationen und weitere
typedMarker-/Hash-/Owner-/Visibility-/Consumer-Ablehnung jenseits der sechs
ersten-GO-Proben, AppLock/Drift/Caller/Rollback sowie Heap-/Spill-
Verhalten. Die aktuelle CI ist
ein eigenständiger Gate; bisherige 1.0/1.1-Evidenz bleibt historisch.

## Neue Uninstall-Metadatenvoraussetzung (2026-10-02)

Die einzeln freigegebene fail-closed Voraussetzung wurde nach Umsetzung mit
`Tests/CI/run-json-groups-lab.ps1 -RuntimeTests InstalledMetadata.Contract.sql`
auf Linux 2019/latest und Windows 2025 exakt CU8 jeweils lokal/zentral erneut
geprüft. Beide tatsächlichen Prozesse Exit0; gekoppelte Lifecycle-/Client-/
Consumerprüfungen erfolgreich, private Journale COMPLETE, alle eigenen
Datenbanken entfernt, keine Konfigurations- oder Rechteänderung.
Kein neuer Default-All-PASS und kein tatsächlicher Missing-rights-Nachweis.
Vier neue CI-Injektionen ersetzen je eine Permissionpredicate erst in Pass 1
unter AppLock durch 0 bzw. NULL und verlangen 53622 sowie anschließend intakte
Lifecycle-/InstalledMetadata-Verträge. Diese negativen Injektionen und neue
Exact-head-CI sind noch nicht ausgeführt.

## Additive Gruppenwelle 1.1.0

Vor-Source-Gate als Commit `412dbdd3` festgehalten. Genau zwei neue Fassaden verwenden den bestehenden Kern mit GroupMode.

Am 2026-10-02 bestanden auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal und zentral die fünf Runtime-Fixtures `JsonConstructors.Contract.sql`, `Collation.Contract.sql`, `JsonGroups.Contract.sql`, `JsonGroups.Boundaries.sql` und `InstalledMetadata.Contract.sql` sowie Clientmetadaten. Dazu gehören alte ungruppierte Regression, Unicode-/Literalfälle, Gruppierung, beide Resultschemas, KeepData/Empty-Routing, späte Fehler und echte 100000-Gruppen-/16-MiB-Grenzen. Diese Teilnachweise stammen aus insgesamt fehlgeschlagenen Läufen: Das spätere Central-Orakel meldete 54600/45 wegen einer column_id-Lücke. Sie sind kein vollständiger Adapter-PASS.

Die finalen fokussierten Läufe wählten ausdrücklich nur `-RuntimeTests InstalledMetadata.Contract.sql`. Beide Adapter bestanden lokal und zentral Metadaten, genuine unveränderte 1.0-Upgrades, Repeat, Rollback/Postlock/AppLock, Marker, Future-Slot-Typen, Dependencies, committable/doomed Callertransaktionen mit ON/OFF-Optionen, Central-Bestätigung, den tatsächlichen Consumer am höchsten ausgewählten CL, Uninstall und eigene Bereinigung. Die Wiederherstellungsjournale wurden unabhängig geprüft: abgeschlossen, eigene Datenbanken entfernt, keine Konfigurations- oder Rechteänderung. Daraus wird kein finaler Default-All-Fixtures-PASS abgeleitet.

Frühere fehlgeschlagene Läufe bleiben erhalten: 53609/4 im Escape-Budget-Orakel, 206 im Kollisionsfixture, 3998 im Caller-Batch und 54600/45 im Central-Orakel. Die jeweiligen Test-/Adapterkorrekturen ändern keinen Corevertrag.

Neue Minimalrechte, weitere Zielkombinationen und Produktions-/Parallelkapazität bleiben offen. Die Uninstall-Voraussetzung `VIEW DEFINITION`/`SELECT` wurde am 2026-10-02 einzeln freigegeben; die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen. Aktuelle CI wird als separater PR-Mergegate nachgewiesen. Status `partially validated`, `unreleased`. Historische 1.0-Evidenz unten gilt ausschließlich für die damaligen drei Slots.

Historischer nativer Gruppenadapter: `Tests/CI/run-json-groups-lab.ps1`; bei Version 1.2 stoppt er ausdrücklich vor Labdiscovery. Die 1.2-Teilnachweise stammen aus separat geprüften privaten Adaptern. Die Bash-Labroute ist für Lab explizit gesperrt; GitHub-Container verwenden den Bash-Runner weiterhin als gesonderten aktuellen PR-Head-Gate.

## Historische Ausführung 1.0.0

Genuine SQL-Upgradepakete werden ausschließlich aus den fest gebundenen
öffentlichen Commits erzeugt: fünf Dateien für 1.0.0, sieben für 1.1.0.
`Deployment/New-LegacyTestArtifacts.ps1 -Version 1.1.0` fragt nur die sieben
erwarteten SQL-Pfade ab und prüft jedes originale Git-Blob sowie den vollständigen
Dateisatz. Die Sourcekorrektur ist kein tatsächlich ausgeführter Upgrade-PASS.
Reine Tree-Parserkontrollen: `Tests/Static/Test-LegacyTree.ps1`; keine SQL-Ausführung.

Static: `python Modules/toolbelt.json.constructors/Tests/Static/validate_contract.py`.
Lab: `pwsh -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2019 -Platforms linux -StopOnFailure`.
Zweiter Scope separat2025Windows, CU/base-Override nach Rootregeln.
Der bestehende Runner validiert den portablen Exportvertrag/schema; keine Lab-Infrastrukturänderungen.
Am 2026-10-01 ausgeführt: beide obigen Zielscopes erfolgreich mit dem vollständigen
finalen Adapter. `local: Tests/CI/run-lab-local.ps1` ist der Nachweis, keine
persistierten Rohlogs/Verbindungswerte. Windowsbefehl:
`pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2025 -Platforms windows -WindowsPatches CU8 -StopOnFailure`.
Static, PowerShell-Syntax und scopebezogene Manifest-/Dokumentationslinksprüfung
erfolgreich. Weitere Ziele/GitHub-hosted/CrossDB-Minimalrechte nicht ausgeführt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-json-schema-lab.ps1`
- Scope: Constructor1.3: vier ausgewählte Runtime-Fixtures einschließlich16 MiB/100000 Einträgen Linux2019/latest CL150 lokal und Windows2025/CU8 CL170 local/central bestanden. Genuine bekannte1.2→1.3 beide Ziele local/central, fünf Procedureidentitäten/Rechte und effektive Owner erhalten, drei eigene CLR-Slots/Assembly atomar neu, post-DROP-Rollback und Annotationserhalt, nachgelagerte Schema26-Fall-Fixture, Repeat/Uninstall/Coreerhalt und frische hashgebundene Dispositionaudits bestanden. Weitere Ziel-/Lifecycle-/Minimalrechtematrix und aktuelle Head-CI offen; verworfener ALTER-Versuch6282 bleibt fehlgeschlagen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
