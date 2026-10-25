# Split Advanced mit getrennten Callerrechten verwenden

> Späterer Nachtrag vom 2026-10-25: Der [CL-Abschluss](SPLIT-ADVANCED-CL-COMPLETION.md)
> ergänzt sechs neue niedrigere CL-Fälle. Dieser ursprüngliche Bericht und
> seine JSON-Projektion bewahren den damaligen begrenzten Ausführungsumfang.

Stand 2026-10-25. Die beiden TVFs von Split Advanced 1.1.0 sind mit je einem
SELECT, die USP mit einem EXECUTE geprüft. Ein zusätzliches, getrennt gezähltes
USP-Profil verwendet EXECUTE auf `toolbelt_core.USP_PrepareResultTable` für
ResultTable. Der ausgewählte Scope umfasst sechs physische Plattform-/Versions-
ziele mit ihrem jeweils höchsten unterstützten Kompatibilitätslevel.

## Tatsächlich geprüfter Umfang

Der [gemeinsame T-SQL-Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen)
installiert nur Split Advanced 1.1.0 und ResultTable 1.0.0. Die feste
`Runtime/SplitAdvanced.Rights.sql` verlangt eine eigene markierte Datenbank
und einen vorher nicht vorhandenen Benutzer ohne Login. Breite Rollen-,
Schema- oder Datenbankrechte entfallen.

Split-TVF und USP prüfen feste Originaltokens einschließlich erhaltener
Quotes und eingebettetem Separator. Unquote dekodiert ein eigenständiges
festes Klammerbeispiel. Alle APIs prüfen NULL-Priorität und ungültige
Konfiguration. Beide USP-Pfade erwarten genau SQL51680; NULL und Fehler
verändern eine bereits gefüllte ResultTable nicht. Der zusätzliche Helper-
Pfad wird ausdrücklich nicht als Einzelgrantprofil gezählt. Fehlende und
entzogene Rechte, andere öffentliche APIs und der nicht benötigte Helper
müssen mit exakt SQL229 scheitern.

Windows und Linux bestanden jeweils SQL2019 CL150, SQL2022 CL160 und
SQL2025 CL170 local/direct-central: sechs Fälle, 36 Einzelgrantprofile,
zwölf Helperprofile, 228 SQL229- und 24 SQL51680-Abweisungen. Ein absichtlich
falscher Token-Sollcount und ein zusätzliches Objektrecht wurden aus den
erwarteten Gründen verworfen; beide Kontrollen bleiben `FAILED_CLEANED`.

**Nicht ausgeführt in diesem Callerprofil-Scope:** Windows/Linux SQL2022
CL150 sowie SQL2025 CL150/160. Die sechs Fälle qualifizieren keine vollständige
Zwölf-Kombinationen-Matrix. Die Auswahl deckt alle sechs physischen Versions-/
Plattformziele ab und erhält Reserve im unveränderten gemeinsamen Testbudget.
Historische Funktionsnachweise bleiben ausschließlich in ihrem eigenen Scope.

Alle acht Versuche bestanden unabhängige Input-/Abwesenheitsaudits. Nach dem
letzten Verbraucher bestätigten frische Audits alle 14 eigenen Datenbanknamen
als abwesend. Eigene Principals und Temp-Fixtures sind entfernt; Moduldefinitionen,
Serverkonfiguration, CLR und Assemblytrust bleiben unverändert. Private
Identitäten und Logs bleiben lokal.

## Quellen und Grenzen

Die [JSON-Projektion](split-advanced-rights-qualification.json) bindet die
konsumierten Quellen, Exports, Fixture und vorhandenen Harness-/Labadapter
und zählt die sechs nicht ausgeführten CL-Kombinationen ausdrücklich auf.
Der [Moduleinstieg](../../Modules/toolbelt.string.split-advanced/README.md)
führt zu den bestehenden öffentlichen Verträgen und historischen Testgrenzen.

Keine neue Testinfrastruktur oder CI-Labmatrix und keine Wiederholung der
historischen vollen Funktionssuite. Vollständige Grenzen-/Lifecycle-/
Konkurrenz-/Ressourcenverträge, echte Lowpriv-CrossDB-Mappings, authentifizierte
TLS-Abnahme, harte Recovery und weitere Modulpflichtfälle bleiben separat.
Functional verwendet erforderliche Verschlüsselung und den expliziten
Trustwert des schema-validierten Labvertrags.

Keine vollständige Modul-/Releaseabnahme, Produkt-, Manifest-, Paket- oder
Statusänderung. Die [Releasegates](RELEASE-GATES.md) und die separate
Veröffentlichungsfreigabe gelten weiterhin.
