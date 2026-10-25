# JSON Pointer mit einzelnem SELECT-Recht

Stand 2026-10-25. Die vorhandene TVF besteht zwölf feste Status-/Typ-/Wert-/Fehlerorakel je positivem Profil: RFC-Escapes, Arrayelement, JSON-null, Missing, BIN2-Keyvergleich, SQL-NULL sowie Pointersyntax, doppelte Schlüssel, Arrayindex, abgesenktes Inputlimit und feste Tiefengrenze. Der ResultTable-Helfer bleibt gesperrt. Lifecycle-Minimalrechte, Maximalworkload, Heap und Parallelität behalten ihre eigenen Gates.

Zwölf Ziel-/CL-Kombinationen auf Windows und Linux: SQL2019/CL150,
SQL2022/CL150/160 und SQL2025/CL150/160/170, jeweils lokal und direkt zentral.
Der eigene Benutzer ohne Login erhält nacheinander genau ein Objektrecht.
Ohne Grant, nach REVOKE und für die getrennt genannten anderen Objekte muss
die Engine exakt SQL229 liefern; breite Datenbank-/Schemarechte bleiben ausgeschlossen.

| API | Einziger Grant |
|---|---|
| `toolbelt_json.TVF_ResolveJsonPointer` | SELECT |

Die feste kanonische Fixture `Pointer.FunctionCases.sql` verwendet
den unveränderten [gemeinsamen Callerablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).
Die [öffentliche JSON-Projektion](pointer-caller-qualification.json) bindet
Komposition, Source-/Treiber-/Exportbytes, Matrix, Orakelkontrollen und Grenzen.
Es bestehen 24 positive Einzelgrantprofile und
72 erwartete SQL229-Abweisungen. Zwei frische Kontrollen
mit falschem Orakel und zusätzlichem Grant werden verworfen. Nach allen Verbrauchern
sind 14 akzeptierte terminale Journale unabhängig frisch auditiert; alle
26 eigenen Datenbanknamen sind abwesend. Keine Serverkonfigurations-, Login-,
Assemblytrust- oder fremden Änderungen; private Journale bleiben lokal.

Diese Callerprofile ersetzen keine vollständige API-, Ausgabe-, Client-,
Lifecycle-, Ressourcen- oder Supportabnahme. Frühere Nachweise behalten ihren
eigenen Scope. Echte Lowpriv-CrossDB-Mappings und authentifiziertes TLS bleiben
separat. Functional verwendet Verschlüsselung und den expliziten Trustwert des
schema-validen Labvertrags ohne automatischen Transportfallback. Produkt-SQL,
Manifeste, Status und Pakete bleiben unverändert; keine Veröffentlichung oder Tags.
Weitere [Releasegates](RELEASE-GATES.md) bleiben offen.
