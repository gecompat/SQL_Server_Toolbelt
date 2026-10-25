# Pseudonymisierung mit getrennten Callerrechten verwenden

Stand 2026-10-25. Range, DateShift, Translate und GeoJitter 1.2.0 sind jeweils
mit genau einem SELECT geprüft, Lookup mit genau einem EXECUTE. Ein weiteres,
ausdrücklich getrenntes Lookup-Profil verwendet zusätzlich EXECUTE auf
`toolbelt_core.USP_PrepareResultTable` für die ResultTable-Ausgabe.

## Tatsächlich geprüfter Umfang

Der [gemeinsame T-SQL-Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert nur Deterministic Synthetic Mapping 1.2.0 und ResultTable 1.0.0
über die verbindungslosen Exports. Die feste `Runtime/Deterministic.Rights.sql`
verlangt eine eigene markierte Datenbank und einen vorher nicht vorhandenen
Benutzer ohne Login. Breite Rollen-, Schema- oder Datenbankrechte entfallen.

Jede TVF prüft einen bestehenden unabhängigen Festwert, NULL-Priorität und
einen Konfigurationsfehler. Geo verwendet ausschließlich den synthetischen
Ursprung (0,0), einen festen Zielpunkt mit Toleranz 1E-9, gültige Point-/SRID-
Metadaten und die Distanzgrenze. Lookup prüft einen synthetischen Einzelpool
sowie einen NULL-Key im direkten und gesonderten ResultTable-Pfad.
Fehlende und entzogene Rechte, andere öffentliche APIs, der nicht benötigte
Helper und drei interne Kerne müssen mit genau SQL229 scheitern. Das zusätzliche
Helperprofil wird ausdrücklich nicht als Einzelgrantprofil gezählt.

Windows/Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170
bestanden jeweils local/direct-central: zwölf Fälle, 120 Einzelgrantprofile,
24 Lookup-/Helperprofile und 1.416 strikte SQL229-Abweisungen. Ein absichtlich
falscher Range-Festwert und ein zusätzliches fremdes Objektrecht wurden aus
dem erwarteten Grund verworfen; beide Kontrollen bleiben `FAILED_CLEANED`.

Alle 14 Versuche bestanden unabhängige Input-/Abwesenheitsaudits. Nach dem
letzten Verbraucher bestanden nochmals frische Audits; alle 26 eigenen
Datenbanknamen waren abwesend. Eigene Principals und Temp-Fixtures sind entfernt.
Modulobjekte und Definitionen, CLR-Konfiguration, Assemblytrust und weitere
Serverparameter blieben unverändert. Private Identitäten und Logs bleiben lokal.

## Quellen und Grenzen

Die [JSON-Projektion](deterministic-rights-qualification.json) bindet die
konsumierten Quellen, Exports, Fixture und vorhandenen Harness-/Labadapter.
Keine neue Testinfrastruktur, zusätzliche CI-Labmatrix oder Wiederholung der
historischen vollständigen Funktionssuiten. Die ursprünglichen Pflichtfälle
behalten ihren eigenen Umfang.

Functional verwendet erforderliche Verschlüsselung und den expliziten Trustwert
des schema-validierten Labvertrags. Authentifizierte TLS-Abnahme, echte Lowpriv-
CrossDB-Mappings, vollständige Großwert-/Konkurrenz-/Ressourcen-/Lifecycleverträge,
harte Recovery und andere Modulpflichtfälle bleiben separat. Dies ist keine
vollständige Modul- oder Releaseabnahme. Produktquellen, Paketbytes und Statuswerte
bleiben unverändert; die [Releasegates](RELEASE-GATES.md) und die separate
Veröffentlichungsfreigabe gelten weiterhin.
