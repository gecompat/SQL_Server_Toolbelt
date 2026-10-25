# JSON Schema: nachgewiesenes Caller-Rechteprofil

Die damals offene Manifest-/Paketlücke ist durch die spätere
[exakte Metadatenkorrektur](CALLER-METADATA-UPDATE.md) geschlossen.
Der folgende Ausführungsbericht behält seine ursprünglichen Quellen und Grenzen.

Stand 2026-10-25. Die vorhandene JSON-Schema-USP 1.0.1 besteht auf zwölf
Windows-/Linux-Ziel-/CL-Kombinationen lokal und direkt zentral. Die neue
SQL-Fixture belegt 168 Rechtezustände,24 positive Profile, 240 feste Fachfälle,
96 exakte SQL229-Abweisungen und 48 Abweisungen mit55601.

## Erforderliche einzelne Objektrechte

| Objekt | Recht | Begründung im bestehenden Quellpfad |
|---|---|---|
| toolbelt_json.USP_ValidateJsonSchema | EXECUTE | Öffentlicher Einstieg |
| toolbelt_core.USP_PrepareResultTable | EXECUTE | Dependency-Metadaten müssen sichtbar sein; ResultTable ruft den Helper auf |
| toolbelt_json.FT_ValidateJsonSchemaInternal | SELECT | Zugriff aus dynamischem SQL |

Diese drei Rechte sind gemeinsam für den geprüften Datenpfad erforderlich.
Das ist ein Nachweis des vorhandenen Verhaltens; der Test verändert keine
Produktfunktion und erteilt keine Rechte außerhalb eigener Wegwerfdatenbanken.
Die interne TVF wird dadurch direkt lesbar; sie wird nicht zum öffentlichen API.
Help und zusätzliche VIEW-DEFINITION-Alternativen sind hier nicht qualifiziert.

Sieben Zustände werden pro Datenbank separat geprüft: keine Grants; nur die
USP; USP plus Helper; alle drei Rechte; Helper entzogen; Helper wieder vorhanden
und TVF-SELECT entzogen; öffentliche USP wieder entzogen. Fehlender öffentlicher
Aufruf beziehungsweise fehlendes TVF-SELECT muss exakt 229 ergeben. Die beiden
Zustände mit sichtbarer USP und unsichtbarem Helper ergeben exakt 55601.
Breite Rollen-, Datenbank- und Schemarechte bleiben ausgeschlossen.

## Entwickelter und ausgeführter Testcode

Neu sind der auf genau JsonCore/JsonSchema begrenzte
[Labtreiber](../../Tests/Release/Invoke-JsonSchemaCallerLab.ps1) und die
[SQL-Fixture](../../Tests/Release/Runtime/JsonSchema.CallerRights.sql).
Die bereits qualifizierten Trust-, Konfigurations-, Pin-, SQL- und
Ownership-Helfer werden unverändert verwendet. Der separate Treiber lässt die
ausgeführten Quellen der String-Nachweise unverändert. Ein gemeinsamer Umbau
würde deren Ausführungsbindung verändern. Neue CI-Jobs und wiederholte Builds entfallen.
Die Offlineprüfung ist separat auszuführen:

```powershell
python -B Tests/Release/test_json_schema_caller_profile.py
```

Der native Aufruf benötigt einen schema-validierten Labvertrag und einen privaten
zwölfteiligen Runset mit `schema_version=json-schema-caller-contract/v1`, beiden exakten
reproduzierbaren DLLs und allen Pflichtpins:

```powershell
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-JsonSchemaCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-JsonSchemaCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex -AuditOnly
```

Geprüft wurden SQL Server 2019 CL150, 2022 CL150/160 und 2025 CL150/160/170
auf Windows und Linux, jeweils lokal und direkt zentral. Fünf synthetische
Fälle je Ausgabeweg prüfen VALID, INVALID_INSTANCE, SQL_NULL, INVALID_JSON
und INVALID_SCHEMA mit festen Urteilen, NULL-Regeln, Fehlercodes und typisierter
Zehnspaltenausgabe. Direkte Ausgabe wird über INSERT EXEC erfasst; ResultTable
verwendet eine unter dem Caller erzeugte lokale Temp-Tabelle. Das ist keine
separate direkte Clientmetadatenabnahme.

Zwei frische Kontrollen wurden im beabsichtigten Orakel abgewiesen: falscher
IsValid-Golden und zusätzliches Schema-SELECT. Alle 14 nativen Versuche endeten
mit bestätigter Bereinigung. Abschließend liegen 14 erfolgreiche separate rein lesende
Audits vor, einer pro terminalem Versuch: stabile Inputpins, Abwesenheit aller 26
eigenen Datenbanknamen, ursprüngliche Konfiguration und entfernter eigener
beziehungsweise unverändert vorhandener Trust. Auf einem Ziel waren zuvor der
erste Abschlussaudit, sechs begrenzte Nachprüfungen und eine private Diagnose
wegen einer zwischenzeitlichen Konfigurationsabweichung fehlgeschlagen.
Der Zustand wurde nicht verändert. Nach ausdrücklich menschlich autorisierter
Abstimmung und bestätigter Wiederherstellung des anderen Labverbrauchers
bestand genau der noch offene Leseaudit. Danach wurde das exklusive Labfenster
an den SSIS-Chat abgegeben; keine weiteren Labmutationen oder Auditwiederholungen.
Originale Fehlerbeobachtungen und Konfigurationswerte bleiben privat erhalten.
Es gab keine fehlgeschlagene positive Zielprüfung und keine Wiederholung der
Fachtests.

Die beiden Paket-DLLs wurden bytegenau mit zwei früheren isolierten Builds
verglichen. Sämtliche aktuellen Compile-Inputs beider Projekte sind identisch
zum belegten Buildstand; die Schema-Referenz verwendet genau diese Core-DLL.
Es wurde kein unbekanntes Binary verwendet und kein Trusthash veröffentlicht.
Funktionsverbindungen waren verschlüsselt und verwendeten ausschließlich den
expliziten Trustwert des validierten Labvertrags; authentifiziertes TLS bleibt
separat nicht ausgeführt.

## Verbleibende Grenzen

Das eingefrorene Modulmanifest und Paket nennen weiterhin pauschal nur EXECUTE.
Diese Formulierung beschreibt den nachgewiesenen Datenpfad nicht vollständig.
Die objektbezogene Anwenderdokumentation ist präzisiert; Manifest-/Paketrefresh
bleibt beim koordinierten Paketowner. Das bestehende Artefakt wird hier nicht
umgeschrieben. Vollständige API-, Lifecycle-, Ressourcen-, Client- und echte
CrossDB-Identitätsgates bleiben getrennt. Status bleibt partially validated und
unreleased; keine Veröffentlichung oder Tags.

Der [maschinenlesbare Bericht](json-schema-caller-profile.json) bindet die
öffentlichen Quellen und abstrakten Resultate. Geschlossen ist ausschließlich
dieser Caller- und Ausgabewegscope.
