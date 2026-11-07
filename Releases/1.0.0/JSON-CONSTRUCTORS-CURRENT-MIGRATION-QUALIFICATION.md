# JSON Constructors: aktuelle genuine Migrationsmatrix

Am2026-11-07 bestand die genuine bekannte Constructor1.2→1.3-Migration mit
aktuellem Core1.0.0 und nachgelagertem Schema1.0.1 auf der unterstützten
Windows-/Linux-SQL-Matrix: **zwölf Gesamtläufe,24 Installationskontexte,
240 Fixture-Checkpoints, zwölf frische Fallaudits und sechs abschließende
Konfigurations-/Trustaudits**, ohne nativen Fehler.
**COMPLETE_FOR_CURRENT_GENUINE_MIGRATION_SCOPE**.

| Ausgewähltes Labziel | CLs | Installation je CL | Neue Kontexte | Fallaudits |
|---|---|---|---:|---:|
| Windows2019/CU32 | 150 | lokal/direkt zentral | 2 | 1 |
| Windows2022/CU26 | 150,160 | lokal/direkt zentral | 4 | 2 |
| Windows2025/CU8 | 150,160,170 | lokal/direkt zentral | 6 | 3 |
| Linux2019/latest | 150 | lokal/direkt zentral | 2 | 1 |
| Linux2022/latest | 150,160 | lokal/direkt zentral | 4 | 2 |
| Linux2025/latest | 150,160,170 | lokal/direkt zentral | 6 | 3 |

Der Clienthost war Windows; Linux bezeichnet die SQL-Ziele. Zentral ist direkte
SameDB-Nutzung. Keine neue Identität, GRANT-, Owner- oder Labinfrastrukturänderung.

## Weshalb eine aktuelle Matrix nötig war

Die vier historischen Migrationsjournale und ihre hashgebundenen damaligen
Audits bleiben unverändert erhalten. Ihr wiedergefundener genuine1.2-Receipt
und dessen22 Quellpins sind intakt. Die alten Gesamtläufe sind trotzdem keine
frische aktuelle Integrationsabnahme: Der korrekt gegen die Repositorywurzel
aufgelöste Vergleich findet15–19 abweichende Produktdateien je altem Lauf,
einschließlich Schema-CLR/Deployment sowie Constructor-/ResultTable-Sources.
Eine zunächst fehlerhafte Zuordnung relativer Pfade wurde vor SQL korrigiert;
die daraus erwogene reine Acht-Paare-Restmatrix wurde nicht gestartet.

Die neue Matrix prüft die aktuelle Integration vollständig. Historische
Erfolge oder Fehlläufe, einschließlich des verworfenen ALTER-Versuchs6282,
werden nicht umetikettiert. Es werden auch keine neuen 1.0-/1.1-Legacypfade
eingeführt; Gegenstand ist ausschließlich die bereits unterstützte bekannte1.2.

## Tatsächlich ausgeführte Kette je Kontext

Zehn benannte Checkpoints bestehen je Kontext:

1. Echte bekannte1.2 installieren und deren Aggregat-/Gruppenfixtures ausführen.
2. Einen Fehler nach eigenem DROP injizieren und den vollständigen Ausgangszustand
   vergleichen: Objekte, Assembly, Owner und erweiterte Eigenschaften unverändert.
3. Zusätzliche synthetische Assemblyannotation erzeugen; aktuelle Migration muss
   ablehnen und den Startzustand unverändert lassen. Eigene Annotation entfernen.
4. Tatsächlich auf1.3 migrieren. Die fünf Procedureidentitäten, effektiven
   SQL-/Assemblyowner und vorhandenen Berechtigungstupel müssen erhalten bleiben;
   die neue gemeinsame Core-Referenz muss bestehen.
5. Den aktuellen Schema-Consumer installieren, seine kanonische Vertragsfixture
   ausführen und wieder entfernen.
6. Die vier aktuellen Constructor-Fixtures ausführen: Aggregate, Constructors,
   Gruppen und installierte Metadaten. Darin liegen auch die bestehenden
  16-MiB-/100000-Einträge-Orakel.

Die erste und letzte Gruppe enthalten zwei beziehungsweise vier Fixtures;
zusammen ergibt das zehn Checkpoints je Kontext,240 insgesamt. Dies ist kein
hochgerechneter Einzelassertion-Zähler. Das erhaltene alte interne Label
`migrated-schema-26-cases` benennt den Checkpoint; ausgeführt wird die gepinnte
aktuelle Schemaquelle, nicht eine daraus abgeleitete alte Fallzahl.

Danach bestehen Repeat, Constructor-Uninstall/Repeat und Core-Erhalt:
vorzeitiger Core-Uninstall muss ablehnen, Constructor-Uninstall darf den Core
nicht austauschen, abschließend wird der eigene Core entfernt. Erst danach
zählt der Modus als abgeschlossen. Ein leerer vorhandener Grantbestand wird
ebenfalls exakt verglichen; dies ist kein nichtleeres ACL-/Lowpriv-Profil.

## Methode und Sicherheitsbindung

Ausgeführter Snapshot:
[`0a0801a1`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/0a0801a1b26a4f2bc819493e47e87a11f4fc75e5).
Der bestehende [Native-Treiber](../../Tests/CI/run-json-schema-lab.ps1) und sein
[unabhängiger Audit](../../Tests/CI/Test-JsonSchemaLabDisposition.ps1) verwenden
dasselbe [reine Auswahlprädikat](../../Tests/CI/JsonSchemaQualificationScope.ps1).
Die echte Migrationstargetprüfung wurde erweitert, nicht umgangen. Andere
Constructor-Fixturegrenzen bleiben unverändert.900 reine Kombinationen prüfen
zulässige/abgewiesene Plattform-/Patch-/CL-/Scopetupel, einschließlich falscher
Großschreibung. Die vorhandenen PS-Proben bestehen63 Aufruf-/Selektorfälle,
neun historische Versionsfälle,33 Producer-/Audittupel und elf Trustguards.

Die drei aktuellen DLLs müssen exakt zur bekannten gemeinsamen Artefaktregistry
passen. Die echte unveränderte1.2-DLL und Quellen sind separat an Revision
`46b2f078662a3203a8da67bfe331b33607962082` und deren bekannte Zeile gebunden.
Keine neuen Builds, Produkt-SQL-/C#-, Binär-, Manifest- oder Quotenänderungen.
Eingaben, Produkt-/Testquellen, Helfer, Host und schema-validierter Labvertrag
samt Prompt sind privat gepinnt und vor/nach Verwendung geprüft.

Bestehende administrative Rechte werden verwendet. Vor Konfigurationsänderung
werden tatsächliche Hauptversion, Plattform, Softwareversion und vorhandener
Sysadmin geprüft; der finale Audit vergleicht Version/Plattform erneut. Nur
freigegebene notwendige CLR-Konfiguration und exakte bekannte Hashtrusts werden
im eigenen Umfang verwendet. Strict Security bleibt aktiv. Die Datenbank-
Entfernung bindet volle eigene ID/Erstellungszeit/Owner; Trustentfernung benötigt
unveränderte Tupel und globale Verbraucherfreiheit. Drift blockiert fremde
Wiederherstellung.

## Abschluss und verbleibende Grenzen

Die neue Welle hatte36 Ziel-/Auditdispatches,24 eigene DBs und45 Minuten ohne
Wiederholung gemeinsam für beide Plattformen: zwölf Läufe, zwölf separate
Fallaudits, sechs Konfigurationsvorbereitungen und sechs Wiederherstellungs-/
Freshaudits. Alle36 Aufrufe und24 Datenbanken sind innerhalb der Originalfrist
geschlossen. Keine ungezählten Zusatzdispatches; ältere Budgets bleiben erhalten.

Die zwölf frischen Fallaudits binden unveränderte finale Originaljournale,
DB-Abwesenheit und vier eigene/vorhandene Trusttupel. Alle sechs physischen
Konfigurationsscopes bestehen anschließend den vollständigen Konfigurations-/
Trustvergleich. Private Originale bleiben erhalten; keine Runtime-Rohdaten im Git.

Absichtliche andere Owner, nichtleere ACL-Übernahme, direkte AGF-Minimalrechte,
neue Netzwerk-/CrossDB-Identitäten, Linux-Clienthost, Heap/Spill/Parallelität,
harte Host-Recovery und vollständige Modul-/Releasequalifikation bleiben
separat. Functional mit explizitem Labtrust ist keine authentifizierte TLS-
Abnahme. Modulstatus weiterhin teilweise validiert und unveröffentlicht;
keine Veröffentlichung oder Tags.
