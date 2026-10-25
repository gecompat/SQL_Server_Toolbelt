# Providerview mit einzelnem SELECT-Recht

Stand 2026-10-25. Die vorhandene View projiziert einen ausschließlich synthetischen, deaktivierten loopback-Datensatz mit festem fehlendem Contoso-Linked-Servernamen. Feste Auditwerte, Rowversionform und drei Serverkatalogflags werden geprüft. Die native Einzelfallvorprüfung bestätigte den Katalogzugriff, danach wurden genau die elf übrigen Fälle und zwei frische Gegenkontrollen ausgeführt. Direkte Tabelle, Konfigurations-/Transportprozeduren und ResultTable-Helfer bleiben gesperrt. Reale Providerkonfiguration, Loginmapping, RPC und neue Sessions behalten ihre eigenen Gates; kein Linked Server wurde angelegt, aktiviert oder geändert.

Zwölf Ziel-/CL-Kombinationen auf Windows und Linux: SQL2019/CL150,
SQL2022/CL150/160 und SQL2025/CL150/160/170, jeweils lokal und direkt zentral.
Der eigene Benutzer ohne Login erhält nacheinander genau ein Objektrecht.
Ohne Grant, nach REVOKE und für die getrennt genannten anderen Objekte muss
die Engine exakt SQL229 liefern; breite Datenbank-/Schemarechte bleiben ausgeschlossen.

| API | Einziger Grant |
|---|---|
| `toolbelt_core.VW_SecondSessionProviders` | SELECT |

Die feste kanonische Fixture `Provider.FunctionCases.sql` verwendet
den unveränderten [gemeinsamen Callerablauf](../../Tests/Release/README.md#native-funktions-callerrechte-prüfen).
Die [öffentliche JSON-Projektion](provider-caller-qualification.json) bindet
Komposition, Source-/Treiber-/Exportbytes, Matrix, Orakelkontrollen und Grenzen.
Es bestehen 24 positive Einzelgrantprofile und
144 erwartete SQL229-Abweisungen. Zwei frische Kontrollen
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
