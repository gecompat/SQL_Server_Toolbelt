# JSON-Pfade mit getrennten SELECT-Rechten

Stand 2026-10-25. Legacy- und Status-TVF bestehen feste FOUND-/MISSING-/INVALID-/SQL_NULL-/LIMIT-Orakel einschließlich JSON-null, BIN2-Schlüsselvergleich, zitiertem Schlüssel, Arraywildcard und lexikalischem Tiefenlimit. Der jeweils andere API-Einstieg und der ResultTable-Helfer bleiben gesperrt.

Zwölf Ziel-/CL-Kombinationen auf Windows und Linux: SQL2019/CL150,
SQL2022/CL150/160 und SQL2025/CL150/160/170, jeweils lokal und direkt zentral.
Der eigene Benutzer ohne Login erhält nacheinander genau ein Objektrecht.
Ohne Grant, nach REVOKE und für die getrennt genannten anderen Objekte muss
die Engine exakt SQL229 liefern; breite Datenbank-/Schemarechte bleiben ausgeschlossen.

| API | Einziger Grant |
|---|---|
| `toolbelt_json.TVF_JsonPathExists` | SELECT |
| `toolbelt_json.TVF_JsonPathExistsStatus` | SELECT |

Die feste kanonische Fixture `JsonPath.FunctionCases.sql` verwendet
den unveränderten [gemeinsamen Callerablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).
Die [öffentliche JSON-Projektion](json-path-caller-qualification.json) bindet
Komposition, Source-/Treiber-/Exportbytes, Matrix, Orakelkontrollen und Grenzen.
Es bestehen 48 positive Einzelgrantprofile und
192 erwartete SQL229-Abweisungen. Zwei frische Kontrollen
mit falschem Orakel und zusätzlichem Grant werden verworfen. Nach allen Verbrauchern
sind 14 akzeptierte terminale Journale unabhängig frisch auditiert; alle
26 eigenen Datenbanknamen sind abwesend. Keine Serverkonfigurations-, Login-,
Assemblytrust- oder fremden Änderungen; private Journale bleiben lokal.

Ein früherer Versuch verwarf die unvollständige Fixture wegen eines falsch
benannten Helfers vor dem Wertorakel. Seine ursprüngliche unabhängige Bereinigungs-
und damalige Pinprüfung bleibt erhalten. Er ist keine akzeptierte Gegenkontrolle
und wurde mit korrigiertem Input durch zwei frische Kontrollen ersetzt.

Diese Callerprofile ersetzen keine vollständige API-, Ausgabe-, Client-,
Lifecycle-, Ressourcen- oder Supportabnahme. Frühere Nachweise behalten ihren
eigenen Scope. Echte Lowpriv-CrossDB-Mappings und authentifiziertes TLS bleiben
separat. Functional verwendet Verschlüsselung und den expliziten Trustwert des
schema-validen Labvertrags ohne automatischen Transportfallback. Produkt-SQL,
Manifeste, Status und Pakete bleiben unverändert; keine Veröffentlichung oder Tags.
Weitere [Releasegates](RELEASE-GATES.md) bleiben offen.
