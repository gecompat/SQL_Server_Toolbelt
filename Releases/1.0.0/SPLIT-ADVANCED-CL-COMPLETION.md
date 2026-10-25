# Split-Callerrechte: die fehlenden Kompatibilitätsstufen ergänzen

Stand 2026-10-25, zweiter ausdrücklich freigegebener endlicher Release-Rahmen.
Die sechs zuvor offenen Fälle Windows/Linux SQL2022 CL150 und SQL2025
CL150/160 bestanden neu lokal und direkt zentral. Die früheren sechs Fälle
SQL2019 CL150, SQL2022 CL160 und SQL2025 CL170 bleiben unverändert erhalten.
Damit ist die Zwölf-Kombinationen-Matrix genau dieser Callerprofile vollständig.

## Neue Ausführung und unveränderte Wiederverwendung

Verwendet wurde die bestehende `Runtime/SplitAdvanced.Rights.sql` über den
[gemeinsamen Testweg](../../Tests/Release/README.md#weitere-tsql-callerrechte-prüfen).
Pro Kontext gelten weiter drei einzelne API-Grants und ein separat gezählter
USP-/ResultTable-Helperpfad. Originaltokens, eigenständiges Unquoting,
NULL-/Konfigurationsfälle, ResultTable-Erhalt sowie SQL229/51680 bleiben unverändert.
Die sechs neuen Fälle belegen 48 positive Profile, 228 SQL229- und 24 SQL51680-
Abweisungen. Frische unabhängige Audits nach dem letzten Verbraucher bestätigten
alle zwölf neuen eigenen Datenbanknamen als abwesend.

Die [ursprüngliche Projektion](split-advanced-rights-qualification.json) mit
sechs positiven Fällen und beiden verworfenen Orakelkontrollen ist unverändert.
Vor Wiederverwendung wurden alle kanonischen Source-/Fixture-/Treiberbindungen,
Modulversionen, Exports und privaten Labpins erneut auf identische Bytes geprüft.
Die neue private Koordination verwaltet nur den separat autorisierten Rahmen;
sie ändert keine SQL-Orakel oder Testtreibersemantik. Bereits grüne Zieltests
und Kontrollen wurden nicht erneut ausgeführt. Die damaligen `not executed`-
Angaben bleiben als historischer Ausführungsumfang richtig.

Die [Abschlussprojektion](split-advanced-cl-completion.json) trennt sechs neu
verbrauchte Fälle von sechs wiederverwendeten Fällen und bindet die ursprüngliche
Projektion über ihren SHA256. Zusammen: 96 positive Profile, davon 72 Einzelgrants
und 24 Helperprofile; 456 SQL229- und 48 SQL51680-Abweisungen. Diese Summen sind
kein erfundener neuer Zwölf-Fälle-Lauf und keine Hochstufung des Modulstatus.

## Unveränderte Grenzen

Ausschließlich eigene markierte Datenbanken, Benutzer ohne Login und synthetische
Daten; keine Server-, CLR-, Trust-, Infrastruktur- oder fremden Ressourcenänderungen.
Private Identitäten und Logs bleiben lokal. Functional verwendet die erforderliche
Verschlüsselung und den expliziten Trustwert des schema-validierten Labvertrags.
Echte Lowpriv-CrossDB-Mappings, authentifizierte TLS-Abnahme, vollständige Grenzen-/
Lifecycle-/Konkurrenz-/Ressourcenverträge, harte Recovery und Paketabschluss bleiben
separat. Keine Produkt-, Manifest-, Status- oder Paketänderung und keine
Veröffentlichung; die [Releasegates](RELEASE-GATES.md) gelten weiterhin.
