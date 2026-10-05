# Exaktes Trust-Opt-in – JSON Closure1.0 / Constructors1.3

Status: **GRANTED_FOR_EXACT_LAB_TEST_SCOPE**, Benutzerzustimmung2026-10-05:
„Diese drei exakten Trusthashes im beschriebenen Testscope freigegeben“.
Diese Vorlage dokumentiert keine erneute fachliche
Implementierungsfreigabe. Die Schema-/Kern-Welle ist bereits ausdrücklich
freigegeben. Ihr Freigabetext hält fest: „Neue Trusthashes benötigen weiterhin
ihr exaktes Opt-in.“ Der [Gesamtvertrag](../../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
bewahrt diese Grenze.

Die nachstehenden drei unveränderlichen SHA2-512-Werte gehören zur
[damals qualifizierten Closure](KNOWN_JSON_ARTIFACT_CLOSURE_PRE_UNICODE_BINDING.json). Source-Driver,
eigene vollständige IL, verbotene Negativfixtures, kanonische bytegleiche
Projektbuilds und Offline-Paketierung sind geprüft. Native SAFE-Ladbarkeit,
Migration und Lifecycle sind dadurch noch nicht nachgewiesen.

| Assembly | Version | Artifact-ID |
|---|---|---|
| Toolbelt_JsonCore |1.0.0 |975d4a84bb86e80b6e5844d6e86785ae0e98b13ee44c0f66c021507a23e0f888 |
| Toolbelt_JsonConstructors |1.3.0 |a6d81103af18a73a14e58339abb8c7835e0d16d559951cfc3a03d305b63e4a23 |
| Toolbelt_JsonSchema |1.0.0 |b10d6d371f79562cb4b2c5b7c96ebdf021c6e08c4e641eb8947d17dd1a66947e |

Toolbelt_JsonCore:

```text
4680e9d34a0870924b5ca003cc5983882fc8ffb653e702bcc549e5f65dde11934c55ba7b356b519503ac5ce1e2478fe64876fea0295176ff13b5b4a6ab61b894
```

Toolbelt_JsonConstructors:

```text
8ab08a17d1be0b861043463e223154dffbed8273bc2c197cd7c8b791c3c06c4af418358e8e743d72068a3a9f726f7f85f50bcfa431df0484202ab562e1edb4bf
```

Toolbelt_JsonSchema:

```text
a80993ffde9d9197e0fca4ae71eb80a8c39c0758fede21cd0c924bf1098e10da331aeae67f2660ca4cf51d5b28ca626ef5f77930de71364e2791c06c8eec46d4
```

Freigegebener Scope: kontrollierte Registrierung ausschließlich dieser Hashes
für die freigegebene native Entwicklungs-/Testwelle auf frisch schema-
validierten, ausdrücklich ausgewählten bereiten Labzielen Linux/SQL2019/latest
und Windows/SQL2025/CU8. Verwendet werden bestehende Rechte. Vorhandene
Trusteinträge bleiben unverändert. Eigene hinzugefügte Einträge werden nach
allen Testverbrauchern nur bei unverändert eindeutig eigenem Scope entfernt;
fremde zwischenzeitliche Änderungen werden nicht überschrieben. Private
Vorzustände und Wiederherstellungsjournal bleiben unversioniert.

`clr strict security` bleibt1. Eine erforderliche Änderung von `clr enabled`
folgt ausschließlich dem bereits freigegebenen Testkonfigurationsvertrag in
AGENTS.md mit Prüfung ausstehender Änderungen und Wiederherstellungsjournal.
Keine neuen Rechte, Ownerreparatur, TRUSTWORTHY, Reconfigure-with-override,
Serverneustarts oder Lab-Infrastrukturverwaltung. Diese Zustimmung würde
keine anderen Bytes, Hashes, Zielsysteme oder Produktionsinstallation umfassen.

## Fortgeltender Auftrag nach der Einzelzustimmung

Der Benutzer ergänzte2026-10-05 ausdrücklich:
„du brauchst das Trust-Opt-in dafür nicht einholen - ich gebe es dir jetzt schon frei“.
Die laufende Schema-/Kern-Entwicklungswelle wird deshalb mit ihren notwendigen
begrenzten Tests autonom fortgesetzt. Die bereits bekannten unveränderten
Core-/Constructorhashes, der separat qualifizierte korrigierte Schemahash und
der genuine bekannte historische Constructor1.2-Hash werden exakt gebunden
verwendet. Die bestehende synthetische GitHub-Compatibility-CI ist Teil der
beauftragten Test-/PR-Abnahme; diese technische Kopplung ist kein neues
Produkt-Trustfeature und keine pauschale Hashadoption. Die Labpriorität bleibt
gewahrt. Auf Labzielen gelten weiterhin die genaue Zielauswahl, bestehende
Rechte, strict security und ausschließlich eigene unverändert identifizierte
Wiederherstellung. Produktinstaller ändern keinen Trust. Keine Produktion,
Veröffentlichung, Rechte-/Ownerreparatur oder Lab-Infrastrukturverwaltung.

Zusätzlich bestätigte der Benutzer für Schemahashes:
„hiermit gebe ich alle Schema-Trusthash Abfragen von dir frei - du brauchst mich nicht mehr fragen!“
Die [Unicode-Bindungsvorlage](../../toolbelt.json.schema/Documentation/TRUST_UNICODE_BINDING_OPT_IN.md)
führt diesen fortgeltenden Auftrag und den konkreten aktuellen Schemahash.
