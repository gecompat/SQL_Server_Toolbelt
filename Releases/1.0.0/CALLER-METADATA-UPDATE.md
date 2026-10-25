# Caller-Rechte im Releasekandidaten

Die sechs nachstehenden Modulmanifeste nennen jetzt die bereits nativ
nachgewiesenen einzelnen Objektrechte. Die Installation vergibt diese Rechte
nicht automatisch. Installations- und DDL-Rechte bleiben von den Rechten für
den späteren Funktionsaufruf getrennt.

| Modul | Aufrufrechte | Nativer Nachweis |
|---|---|---|
| Base64 | SELECT auf die vier TVFs; EXECUTE auf die beiden Scalarwrapper | [Konvertierung](CONVERSION-CALLER-QUALIFICATION.md) |
| IntegerBase | SELECT auf die beiden TVFs; EXECUTE auf die beiden Scalarwrapper | [Konvertierung](CONVERSION-CALLER-QUALIFICATION.md) |
| URI Component | SELECT auf die vier TVFs; EXECUTE auf die beiden Scalarwrapper | [Konvertierung](CONVERSION-CALLER-QUALIFICATION.md) |
| Identifier | SELECT auf TVF_ParseMultipartName; EXECUTE auf SVF_QuoteMultipartName | [Utility](UTILITY-CALLER-QUALIFICATION.md) |
| Semantic Version | SELECT auf die drei TVFs; EXECUTE auf die beiden Scalarwrapper | [Utility](UTILITY-CALLER-QUALIFICATION.md) |
| JSON Schema | Gemeinsam EXECUTE auf toolbelt_json.USP_ValidateJsonSchema und toolbelt_core.USP_PrepareResultTable sowie SELECT auf toolbelt_json.FT_ValidateJsonSchemaInternal | [JSON Schema](JSON-SCHEMA-CALLER-PROFILE.md) |

Bei JSON Schema gelten alle drei Rechte sowohl für die direkte Ausgabe als
auch für ResultTable. Das SELECT macht die interne TVF direkt lesbar; sie wird
dadurch nicht zur öffentlichen API. Help und alternative VIEW-DEFINITION-
Profile wurden damit nicht abgenommen. Die qualifizierten Benutzer hatten
keine breiten Schema-, Datenbank- oder Rollenrechte.

Für eine Anwendung soll die Administration nur die benötigten, hier belegten
Objektrechte auswählen. Bei Fehler 229 sind Aufrufrecht und Zielobjekt zu
prüfen; JSON-Schema-Fehler 55601 kann auf die fehlende Sichtbarkeit des
ResultTable-Helpers hinweisen. Allgemeine Rollen oder Schema-EXECUTE sind kein
Ersatz für dieses geprüfte Profil. Der [Installationsweg](../../INSTALL.md)
bleibt unverändert und benötigt weiterhin ein geeignetes Installationskonto.

## Was die Korrektur belegt

Die ursprünglichen drei maschinenlesbaren Callerberichte behalten ihre
Ausführungspins, Ergebnisse und damaligen offenen Punkte bytegenau.
[caller-metadata-update.json](caller-metadata-update.json) bindet diese
historischen Quellen getrennt an die korrigierten Manifeste. Der endgültige
Produktsnapshot wird mit dem [SSIS-Lookup-Nachweis](SSIS-LOOKUP-QUALIFICATION.md)
gemeinsam gebunden. Es wird kein alter Test als neuer Lauf ausgegeben.

Der [begrenzte Prüfer](../../Scripts/Release/caller_metadata.py) akzeptiert nur
die sechs exakt festgelegten Rechtefelder und die ausgewählten Lesepfade.
Innerhalb dieser sechs Metadatenkorrekturen bleiben alle anderen Manifestfelder,
SQL-, C#-, Deployment-, Worker- und API-Verträge unverändert. Die zusätzlich
inzwischen integrierte SSIS-Änderung aus PR #447 wird separat neu qualifiziert;
ihr neuer Binary wird nicht als unveränderter alter Build dargestellt. Bereits öffentliche Markdownpflege aus dem gebundenen
Main-Stand darf übernommen werden. Negativkontrollen weisen zusätzliche
Runtime-, Dependency-, Status-, Vertrags- und Berichtänderungen ab.

Die Paketvorbereitung erhält die ursprünglichen SQL-/DLL-Nachweise und prüft
deren exakte Bytes. Geänderte Metadaten werden nicht als erneute native
Ausführung dargestellt. Die vorgeschriebenen aktuellen Head- und Main-CI-
Läufe sind im zugehörigen PR nachzuweisen.

## Verbleibende Grenzen

Geschlossen wird ausschließlich die zuvor dokumentierte Manifest-/Paketlücke
dieser sechs Module. Ältere pauschale Rechtekommentare in Scalar-SQL-Dateien
bleiben als historische Kommentare gekennzeichnet; sie sind keine alternative
Berechtigungsanleitung. Die aktuellen Einzelrechte stehen hier und in den
Modulmanifesten. Eine Änderung dieser SQL-Bytes gehört nicht zu dieser
Metadatenkorrektur.

Weitere API-, Lifecycle-, Ressourcen-, Identitäts-, Client- und echte CrossDB-
Gates stehen weiterhin in [RELEASE-GATES.md](RELEASE-GATES.md). Alle Module
bleiben `unreleased`; Zielkanäle und Supportumfang werden nicht erweitert.
Veröffentlichung, Tag und GitHub-Release bleiben separat nicht autorisiert.

Für die Pflege wurden keine zusätzlichen CI-Jobs oder Modellreviewketten
eingeführt. Die vorhandenen fünf durch Manifeständerungen ausgelösten
Runtimeworkflows bleiben erhalten; ihre aktuellen Head-/Main-Prüfungen werden
nicht durch historische Callerbelege ersetzt. Unveränderte lokale native
Callerfälle werden nach exakter Quellbindung wiederverwendet. Der neue SSIS-
Binary und die betroffenen Paketpfade benötigen ihre neue Build-/Nativeabnahme.
