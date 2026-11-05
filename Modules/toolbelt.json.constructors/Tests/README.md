# Testausführung

## Aktuelle Windows-2025-Ergänzung vom 2026-11-05

Die aktuellen Produkt- und Fixturequellen aus
[2aea5b08](https://github.com/gecompat/SQL_Server_Toolbelt/tree/2aea5b08cb20e5d69b3829afc3050cc443cf99c3)
bestanden mit dem gehärteten
[Labadapter cb251204](https://github.com/gecompat/SQL_Server_Toolbelt/tree/cb251204)
auf dem ausdrücklich ausgewählten Windows-SQL-2025-/CU8-Ziel:

| CL | Installation | Constructor-Fixtures | Frischer unabhängiger Audit |
|---|---|---|---|
| 150 | local | vier bestanden | bestanden |
| 150 | direkt central | vier bestanden | bestanden |
| 160 | local | vier bestanden | bestanden |
| 160 | direkt central | vier bestanden | bestanden |
| 170 | local | vier bestanden | bestanden |
| 170 | direkt central | vier bestanden | bestanden |

Je Kontext liefen dieselben vier unten genannten Fixtures einschließlich
16 MiB/100000 Einträgen, aktuellen Metadaten und Repeat-/Uninstall-Lifecycle.
Die sechs Audits binden die jeweiligen finalen Journale. Die drei DLLs wurden
gegen die aktuelle bekannte Closure geprüft und unverändert wiederverwendet.
Vorhandene CLR-/Strict-Security-Einstellungen genügten; diese Welle änderte
keine Serverkonfiguration, Rechte oder bestehenden Identitäten.

Der Adapter prüft vor Entfernung eines eigenen Trusteintrags zusätzlich alle
sichtbaren Datenbanken auf verbleibende Assembly-Verbraucher des exakten
Hashes. Fehlende Sicht, nicht verfügbare Datenbanken, Lesefehler und geänderte
Kataloge blockieren die Entfernung. Elf isolierte synthetische Gegenproben
bestanden. Eine separate native Probe mit eigener bekannter SAFE-Assembly
bestätigte die Abweisung bei vorhandenem Verbraucher und das unveränderte
Trusttupel; nach Entfernung des eigenen Verbrauchers bestand der Nullnachweis.
Ihr frischer unabhängiger Audit ist bestanden.

Der erste zusätzliche Consumer-Test scheiterte im privaten Verbindungsadapter
vor Assemblyanlage. Sein ursprüngliches Fehlerjournal bleibt erhalten. Die
noch unmarkierte eigene leere Datenbank wurde erst nach lesender Prüfung von
Erzeugungszeit, Eigentümer, exakter Identität und unverändertem Inhalt
bereinigt; der separate frische Audit bestand. Die korrigierte Probe ist ein
eigener Nachweis und ersetzt den Fehler nicht. Der abschließende lesende
Gesamtaudit bestätigt die Abwesenheit aller acht eigenen Testdatenbanken und
den vorgesehenen Trustzustand. Private Originale bleiben außerhalb Git.

Damit ist der aktuelle Fixtureumfang auf Windows2019/2022/2025 über die
jeweils unterstützten CLs lokal und direkt zentral belegt. Eigene
CrossDB-Consumer, Minimalrechte, vollständige historische Upgrade-/Owner-/
Kollisionsmatrix und allgemeine Heap-/Parallelkapazität bleiben separat.
Das Modul bleibt teilweise validiert und unveröffentlicht. Die folgende
Windows2019-/2022-Teilabnahme wird unverändert wiederverwendet; deren grüne
Native-Fälle wurden nicht wiederholt.

## Aktuelle Windows-Teilabnahme vom 2026-11-05

Der öffentliche `Tests/CI/run-json-schema-lab.ps1` unterstützt für
`QualificationScope=constructors` zusätzlich Windows SQL Server 2019/CU32
mit CL150 und SQL Server 2022/CU26 mit CL150/160. Die Scopegrenzen von
Schema und Migration bleiben bei ihren bisherigen Zielkombinationen.
Patch und CL werden ausdrücklich gewählt; es gibt keinen Ersatzprovider.

| SQL Server im schema-validierten Labvertrag | CL | Installation | Constructor-Fixtures | Frischer unabhängiger Audit |
|---|---|---|---|---|
| Windows 2019/CU32 | 150 | local | vier bestanden | bestanden |
| Windows 2019/CU32 | 150 | direkt central | vier bestanden | bestanden |
| Windows 2022/CU26 | 150 | local | vier bestanden | bestanden |
| Windows 2022/CU26 | 150 | direkt central | vier bestanden | bestanden |
| Windows 2022/CU26 | 160 | local | vier bestanden | bestanden |
| Windows 2022/CU26 | 160 | direkt central | vier bestanden | bestanden |

Jeder Kontext führte `JsonAggregates.Contract.sql`,
`JsonConstructors.Contract.sql`, `JsonGroups.Contract.sql` und
`InstalledMetadata.Contract.sql` aus. Dazu gehören die unveränderten
synthetischen 16-MiB-/100000-Einträge-Fälle, exakte aktuelle Metadaten,
Repeat, Dependency-Abweisung, Uninstall/Repeat und erhaltener Core.
Die unabhängigen Audits binden jeweils das finale Journal. Alle sechs
eigenen Datenbanken sind entfernt; eigene Trusttupel und die vorübergehend
unter bestehender Freigabe hergestellte CLR-Voraussetzung wurden
wiederhergestellt. Zwei zusätzliche frische Konfigurationsaudits bestätigten
auch unveränderte fremde CLR-Verbraucher und Serveridentität. Originale und
Wiederherstellungsjournale bleiben privat.

Die getesteten Produkt-, Fixture- und Adapterquellen sind im
[Quellstand cfcc9f4f](https://github.com/gecompat/SQL_Server_Toolbelt/tree/cfcc9f4fa8e7641ea0a727894eb0a7a8093c572a)
gebunden. Die anschließenden Nachträge ergänzen Dokumentation und erhöhen die
erste kalte CI-Core-Kompilierung von 15 auf 60 Sekunden. Produkt-, Fixture- und
Windows-Labadapterbytes bleiben dabei unverändert; die Native-Fälle werden
durch diese Offline-Prozessgrenze nicht verändert.
Die drei DLLs wurden anhand der
[aktuellen Closure](../../toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json)
als exakt bekannte Bytes wiederverwendet. Es wurde kein neuer Binarybuild
oder neuer Trustvertrag eingeführt.

Dieser Umfang belegt lokale und direkt zentrale Aufrufe. Eigene
CrossDB-Consumer, vollständige historische Upgrade-/Owner-/Kollisionsmatrix,
Minimalrechte und allgemeine Heap-/Parallelkapazität bleiben separat.
Die älteren Windows-2025-Läufe belegen ihren ursprünglichen Quellenstand;
sie werden hier nicht zur frischen Abnahme späterer Security-/Helpänderungen
aufgewertet. Das Modul bleibt teilweise validiert und unveröffentlicht.

Vor einem weiteren Lauf die separat qualifizierten drei DLLs bereitstellen,
die vorhandenen CLR-/Sicherheitsvoraussetzungen und Zielberechtigung prüfen
und einen eigenen endlichen Lauf mit unabhängigem Abschlussaudit reservieren.
Der öffentliche Treiber ändert keine Serverkonfiguration oder Berechtigungen.
`Test-JsonSchemaLabScope.ps1` prüft seine Metadatenrouten offline: 53
Scope-/Selektorfälle, neun historische Versionsfälle und 23 gemeinsame
Driver-/Audittupel. Eine grüne Offlineprüfung ist keine neue SQL-Ausführung.

## Historischer Teilstand vom 2026-10-03

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

Historischer nativer Gruppenadapter: `Tests/CI/run-json-groups-lab.ps1`; er
akzeptiert ausschließlich den ursprünglichen SQL-only-Stand 1.1.0. Andere,
fehlende oder doppelte Versionsangaben stoppen vor dem Lesen der Legacydateien
und vor Labdiscovery mit `JSON_CLR_NATIVE_ADAPTER_REVIEW_REQUIRED`. Die frühere
Sperre nur für 1.2 erfasste den aktuellen Stand 1.3 nicht; eine spätere
Source-Anzahlprüfung verhinderte weiterhin die SQL-Ausführung. Neun
Offlinegegenproben im bestehenden `Test-JsonSchemaLabScope.ps1` prüfen Versionen
und frühe Aufrufreihenfolge. Dies qualifiziert keinen neuen nativen Adapter.
Die 1.2-Teilnachweise stammen aus separat geprüften privaten Adaptern. Die
Bash-Labroute ist für Lab explizit gesperrt; GitHub-Container verwenden den
Bash-Runner weiterhin als gesonderten aktuellen PR-Head-Gate.

Der flüchtige CI-Container erhält eine zufällige Owner-Kennung. Beim normalen
Prozessende werden volle Container-ID und Owner aus derselben Inspectaufnahme
strikt geprüft. Nur der eigene Owner erlaubt Entfernung per ID; eine frische
Docker-Abfrage muss die Namensabwesenheit bestätigen. Run-/Attempt-/SQL-Name
und Owner werden vor privatem Setup validiert; das Verzeichnis entsteht erst
nach fallibler Owner-/Kennwortvorbereitung. Erfolgreicher Cleanup meldet
`JSON_CONSTRUCTORS_CI_CLEANUP_VERIFIED` und erhält den ursprünglichen Fehlerstatus.
Ein fremder Namensersatz wird nicht entfernt; unklarer Abschluss meldet
`JSON_CONSTRUCTORS_CI_CLEANUP_UNVERIFIED` und Fehlerstatus.

`python Tests/CI/test_owned_container_cleanup.py --module json_constructors`
prüft die echte Cleanupfunktion in13 synthetischen Fällen einschließlich
Namensaustausch, ungültiger ID-/Ownerformen, Extrafeldern, ursprünglichem
Fehler7 sowie Docker-/Inspect-/Entfernungs-/Nachlistenfehlern. Die bestehende
Dokumentations-CI führt die gekoppelte Probe aus; kein Docker/SQL oder Labzugriff.
Echte Head-/Main-Zeugen stehen separat im PR. Der vorhandene SQL2019-CL150-,
SQL2022-CL160- und SQL2025-CL150/160/170-Scope bleibt erhalten. Kein Nachweis
für Runner-/Host-/Docker-Daemon-Ausfall oder allgemeine Hard-Interrupt-Recovery.

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
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central: vier Constructor1.3-Fixtures mit16 MiB/100000 Einträgen sowie genuine bekannte1.2→1.3-Migration bestanden. Fünf Procedureidentitäten, effektive Owner und vorhandene Rechte erhalten; post-DROP-Rollback, Annotationserhalt, neue Core-Referenz, Schema30-Fall-Fixture, Repeat/Uninstall/Coreerhalt und frische hashgebundene Dispositionaudits bestanden. Keine Konfigurations-/Rechte-/Owneränderungen. Weitere physische Ziel-/Lifecycle-/Minimalrechtematrix offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Ergänzende Constructor1.3-Compatibilityqualifikation2026-10-05

Windows2025/exaktCU8 mit CL150 und CL160 bestand jeweils local/central
vier aktuelle Constructor-Fixtures einschließlich16 MiB/100000 Einträgen.
Getrennte genuine1.2→1.3-Läufe auf beiden Levels bestanden post-DROP-Rollback,
zusätzliche Annotation, Erhalt der fünf Procedureidentitäten/effektiven Owner/
vorhandenen Rechte, aktuelle Constructor-Fixtures und nachgelagerte Schema30-
Fixture. Je abgeschlossenes Journal, eigenes Cleanup und frischer hashgebundener
read-only Dispositionaudit. Unveränderte bekannte DLLs; keine Konfigurations-,
Rechte- oder Owneränderungen. Weitere physische Ziele, vollständige Drift-/
Lock-/Owner-/Minimalrechtematrix und allgemeine Heapgarantien bleiben offen.
