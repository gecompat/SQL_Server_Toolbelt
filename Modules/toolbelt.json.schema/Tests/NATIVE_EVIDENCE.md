# Begrenzte native JSON-Closure-Qualifikation

Stand2026-10-05, Codex. Die konkrete Schema-/Kern-/Constructorwelle ist
funktionsbezogen freigegeben; die fortgeltende
[Trustautorität](../../toolbelt.json.core/Documentation/TRUST_OPT_IN_PROPOSAL.md)
verlangt keine erneuten Schemahashfragen. Ausgeführt wurde der öffentliche
`Tests/CI/run-json-schema-lab.ps1` gegen frisch schema-validierte ausdrücklich
ausgewählte bereite Labziele, mit vorhandenen Rechten und strict security1.

| Scope | Linux/SQL2019/latest CL150 | Windows/SQL2025/CU8 CL170 | Windows/SQL2025/CU8 CL150/160 |
|---|---|---|---|
| Core/Schema local/central | bestanden | bestanden | bestanden |
| Constructors1.3 vier ausgewählte Fixtures | lokal bestanden | lokal/zentral bestanden | lokal/zentral bestanden |
| Genuine bekannte1.2→1.3 local/central, dieselben vier aktuellen Fixtures | bestanden | bestanden | bestanden |
| Frischer read-only Core-/Schema-Dispositionaudit | bestanden | bestanden | bestanden |
| Frischer read-only Migrations-Dispositionaudit | bestanden | bestanden | bestanden |

Alle abschließenden Adapter hatten tatsächlichen Exit0, vollständige
stdout-/stderr-Capture, leeres stderr, unveränderte eingefrorene Inputs und
`COMPLETE` mit verifizierter eigener DB-/Trustdisposition. Es erfolgten keine
Konfigurations-, Rechte-, Owner- oder Lab-Infrastrukturänderungen. Private
Journale, konkrete Vorzustände und Runtimekanäle bleiben unversioniert.

## Tatsächlicher fachlicher Umfang

Core/Schema:30 Fälle aus `Contract.Tests.sql`, `Safety.Tests.sql` und ein
direkter Clientreader mit genau einem Resultset, zehn öffentlichen Typen/
Ordinals, SUMMARY/ERROR-Reihenfolge und einheitlichem Urteil. Geprüft wurden
unter anderem Scalars, SQL-NULL-Priorität, ungültige Syntax/Unicode/Duplikate,
exakte riesige Zahlen, nicht unterstützte unbenutzte Schemaorte, Referenzzyklen,
lokale Referenzen, Budget1, Tiefe129 und `MaxErrors`0/1. Die vier ergänzten
Fälle prüfen Pointer über4000 UTF16-Einheiten mit escaped Slash/Tilde und
NUL bytegenau sowie abgesenkte Schema-/Dokumentbytes und Schemafehlerpriorität.
Diese erweiterten Läufe bestanden auf beiden Zielen local/central mit
anschließendem frischem hashgebundenem Dispositionaudit. Helpfirst,
Argument-/Namensraumfehler, ResultTable-Replace/Append und committabler
Callerrollback sind im Safety-Scope enthalten. Die erweiterte abschließende
Safety-Fixture bestand außerdem echte CHECK-Constraintfehler nach Routing:
Ownrollback, Savepoint-Erhalt vorheriger Caller-Arbeit und doomeder Caller
bleiben korrekt; die aufrufende Fixture rollt ihren eigenen doomen Caller zurück.
Ein voriger55691/state10-Fixturefehllauf bleibt fehlgeschlagen; Transaktions-
und Tabellenorakel werden im korrigierten Test getrennt ausgeführt.
Erst-/Repeat-Install,
Core-Consumer-Reject, Schema-SQL-Consumer-Reject und Uninstall/Repeat
einschließlich unveränderter Coreidentität nach Schema-DROP bestanden.

Constructors: `JsonAggregates.Contract.sql`, `JsonConstructors.Contract.sql`,
`JsonGroups.Contract.sql`, `InstalledMetadata.Contract.sql`. Die vollständige
Constructor-Fixture enthält unverändert16-MiB-Ausgabe und100000 Einträge;
die vorigen20-/60-Sekunden-Timeouts sind keine erfolgreichen Gesamtläufe.
Ein endliches300-Sekunden-Commandbudget innerhalb des endlichen Gesamtbudgets
ermöglichte die vollständige Prüfung. Progresswitnesses enthalten nur feste
synthetische Phasenbezeichner, keine Payloads.

## Genuine Migration und Enginegrenze

Der historische1.2-Installer und die DLL wurden aus unveränderten Git-Blobs
des Commit46b2f078662a3203a8da67bfe331b33607962082 gebaut. Die DLL stimmt
exakt mit der unveränderten historischen Known-Artifact-Zeile überein.
Kein imitierter Versionsmarker oder neu erzeugter angeblicher1.2-Stand.
Historische AGF-/Gruppenfixturen bestanden vor dem Übergang. Schema weist
den vorhandenen1.2-Consumer mit55633/state1 ab.

Der erste echte `ALTER ASSEMBLY` scheiterte bereinigt mit6282/state1: Die
referenzierten Assemblies dürfen dabei nicht geändert werden.
[Microsofts Fehlervertrag](https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors-6000-to-6999)
bestätigt die Enginegrenze. Der korrigierte atomare Pfad ersetzt ausschließlich
die drei eigenen CLR-Slots und eigene Assembly. Fünf Procedureidentitäten,
effektive Owner und der vorhandene Berechtigungskatalog bleiben erhalten.
Verlustgefährdete direkte CLR-/Assemblyrechte, explizite CLR-Owner oder
Zusatzmetadaten werden vor dem Austausch abgewiesen; keine GRANT-Reparatur.

In beiden Modi beider Ziele bestand die gezielte Exception nach eigenem
DROP mit exakter Rückkehr zu1.2-ObjectIds/Assemblybytes/Markern. Eine zusätzliche
Assemblyannotation wurde unverändert abgewiesen und nur die eigene Annotation
anschließend entfernt. Nach normaler Migration und neuer Verbindung bestand
die Identitäts-/Owner-/Berechtigungsprüfung, die neue Core-Referenz und die
Schema-26-Fall-Fixture. Dies beweist keine Erhaltung beliebiger direkter
CLR-Grants; dieser Installer weist solche Zustände ab. Nichtleere zusätzliche
Procedure-Grants und tatsächliche Lowpriv-Caller wurden nicht erzeugt/geprüft.

## Frische Disposition und offene Reichweite

`Tests/CI/Test-JsonSchemaLabDisposition.ps1` führte nach Ende der jeweiligen
Testverbraucher einen neuen ausschließlich lesenden Audit aus. Das exakte
abgeschlossene Journal und die ursprünglichen externen Labvertrag-/Schema-/
Promptbytes sind hashgebunden. Eigene Datenbanken sind frisch abwesend;
eigene Truständerungen sind frisch restauriert, vorhandene Trusttupel exakt
unverändert. Alte Journale ohne persistierte externe FrozenInputs erfüllen
diese neue Auditvoraussetzung nicht. Daher wurde der Core-/Schema-Scope
mit dem finalen hashgebundenen Driver erneut ausgeführt und frisch auditiert;
die früheren erfolgreichen Runs bleiben historische separate Evidenz.

Weitere physische Labziele SQL2022, Linux2025 und Windows2019/2022,
CrossDB-Consumer, vollständige Marker-/Owner-/Lock-/Visibility-/Fremdslotmatrix,
Maximalinput-/Heap-/Spill-/Parallelitätskapazität und tatsächliche Minimalrechte
bleiben offen. Die gekoppelte CI bestand am exakten PR176-Head
6dd4ef65ecac8d98d4d5c964a649d63c0d8692dc mit allen12 Checks, einschließlich
bekannter SAFE-Artifactqualifikation und Linux-SQL2019/2022/2025-Runtime.
Dies ist getrennte synthetische CI-Evidenz, kein neuer physischer Labnachweis. Diese Teilqualifikation ist kein Release.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central:30 Contractfälle, Safety/Help/ResultTable/Callerrollback, direkte Clientmetadaten, Repeat, Consumer-Abweisungen, Uninstall/Repeat und eigenes DB-/Trustcleanup bestanden. Je frischer hashgebundener Dispositionaudit bestanden; keine Konfigurations-/Rechte-/Owneränderungen. Genuine1.2→1.3 separat auf beiden zusätzlichen Windowslevels local/central mit Schema30-Fixture und frischem Dispositionaudit bestanden; weitere physische Ziele und Minimalrechte offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Ergänzende Windows-Compatibilityqualifikation2026-10-05

Core/Schema local/central mit unveränderten drei bekannten DLL-Identitäten
bestand zusätzlich CL150 und CL160 auf dem bereits freigegebenen
Windows2025/exaktCU8-Ziel: je30 Contractfälle und die gleiche Safety-/Client-/
Lifecycle-Fixture. Jeder Lauf hatte ein abgeschlossenes eigenes Journal und
anschließend einen frischen hashgebundenen read-only Dispositionaudit.
Der öffentliche Adapter akzeptiert jetzt150/160/170; Linux2019 bleibt durch
den separaten exakten Zielguard auf150 begrenzt. Keine neue Serverauswahl,
Konfigurations-/Rechteänderung. Constructors und genuine1.2→1.3 wurden
anschließend auf beiden zusätzlichen Levels separat local/central qualifiziert
und frisch auditiert, einschließlich der vier Constructor-Fixtures und
nachgelagerter Schema30-Fixture. Frühere Parameterbindungsabweisung von160
lag vor jeglicher Labnutzung und wird nicht als Runtimefehlversuch gezählt.

## Parameterbindung und mehrschichtiger Zielschutz

Der ursprüngliche ValidateSet-Binder akzeptierte Casevarianten, während der
Zielguard case-sensitiv prüfte. Ein reiner AST-/Bindungstest reproduzierte
WINDOWS/WiNdOwS am ersten Guard. Der tatsächliche nachfolgende Labselector
filtert ebenfalls case-sensitiv und findet dafür kein schema-konformes Ziel;
keine unautorisierte Labnutzung ist aus diesem Teilguardfehler nachgewiesen.
Die fünf textuellen Enumparameter verlangen jetzt ihre dokumentierte
Schreibweise bereits bei Bindung.33 gezielte Metadaten-/Selectorassertions
bestanden ohne Labzugriff; dieselbe Suite weist den ursprünglichen Stand ab.
Ein erneuter kanonischer CL160-Core-/Schema-Lauf mit dem gehärteten Adapter
bestand local/central einschließlich frischem Dispositionaudit. CI führt den
Scope-Test ausdrücklich aus und löst ihn bei allen drei Native-Adapterdateien
und der neuen Scope-Testsuite aus; laufende Runtimeprüfungen bleiben erhalten.
