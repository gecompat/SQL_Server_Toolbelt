# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

16 Module sind implementiert; 14 sind `partially validated`, zwei
`not executed`.

## Aktive Arbeitspakete

### AP-2026-018: W2c Console Message und Capability Catalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-018` |
| Ziel | Die freigegebenen Kandidaten `TC-2026-016` und `TC-2026-023` als zwei unabhängige portable Module implementieren und prüfen. |
| Scope | `toolbelt.core.console-message` Version `1.0.0` mit `toolbelt_core.USP_WriteConsoleMessage`; `toolbelt.metadata.capability-catalog` Version `1.0.0` mit `toolbelt_metadata.VW_ModuleCapabilities`; lokale und zentrale Installation; keine Präfixe, Severity-Optionen, Registry, Filter-TVF oder `module.yaml`-Runtime-Abhängigkeit. |
| Dependencies | W2c-Hauptempfehlung und ausdrückliche Benutzerfreigabe vom 2026-07-30; USP-, Modul-, Lifecycle- und Metadata-Verträge; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `active` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `not executed` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Unicode-sichere vollständige Message-Chunks mit PRINT oder NOWAIT; NULL ohne Ausgabe; kein fachliches Resultset; read-only Projektion kanonischer Database-level Marker; `valid`/`incomplete`/`invalid`; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Verträge vorhanden; SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170, Capture-Marker, Wiederholungsdeployment, Lifecycle, Central und Uninstall noch `not executed`. |
| Blocker | Kein Implementierungsblocker. Merge bleibt bis zu erfolgreicher Runtime- und Dokumentationsprüfung gesperrt. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `CONSOLE_MESSAGE_MODULE_DESIGN.md` und `CAPABILITY_CATALOG_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.core.console-message/` und `Modules/toolbelt.metadata.capability-catalog/`. |
| Nächster Schritt | W2c-Runtime und Dokumentationskonsistenz im Pull Request ausführen; nur bei grünem finalem Head nach `main` mergen. |

### AP-2026-003: ResultTable-Kernmodul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-003` |
| Ziel | Das implementierungsreif spezifizierte Modul `toolbelt.core.result-table` vollständig implementieren, dokumentieren, installieren, deinstallieren und auf den verfügbaren Zielplattformen validieren. |
| Scope | Modulverzeichnis, `module.yaml`, `toolbelt_core.USP_PrepareResultTable`, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Runtime-, Collation-, Deployment- und Plattformtests. |
| Dependencies | `AP-2026-002`, `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017` und `DEC-2026-019`. |
| Priorität | `P0` |
| Status | `active` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Exakt ein persistentes SQL-Objekt in Version `1.0.0`; öffentliche Signatur und Help-Vertrag vollständig; `@LikeTable`-Schemaquelle, `@KeepData`-Matrix, Preflight, in-place-Umbau, Savepoint- und Fehlervertrag implementiert; lokale und zentrale Installation; kontrolliert wiederholbare Lifecycle-Skripte; keine nicht freigegebenen weiteren persistenten Objekttypen; Dokumentation und Manifest konsistent; alle verfügbaren Pflichtprüfungen ausgeführt und nicht verfügbare Prüfungen ehrlich ausgewiesen. |
| Tests | Statischer Vertrag und aktuelle GitHub-hosted Linux-Matrix am 2026-07-29 erfolgreich: vollständige Suite auf SQL Server 2019, 2022 und 2025 einschließlich Collation-, 1024-Spalten-, Transaktions-, Multi-Session-, Central-/Lifecycle- und synthetischem Performance-Workload. Windows und weitere Pflichtfälle bleiben `not executed`. |
| Blocker | Kein Merge-Blocker für den implementierten und teilweise validierten Stand. Für `validated` fehlen insbesondere Windows-Evidenz, echter Savepoint-Rollback nach einem natürlichen Enginefehler und eine vergleichbare plattformübergreifende Performance-Baseline. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.core.result-table/`; [Basislauf 30447442638](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30447442638), [erweiterter Lauf 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934) und [Multi-Session-Lauf 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) erfolgreich. |
| Nächster Schritt | Einen geeigneten Windows-Runner beziehungsweise eine freigegebene Windows-Testumgebung bereitstellen; unabhängig davon einen nicht invasiven, deterministischen Enginefehler für den echten Savepoint-Rollback suchen. Erst nach vollständiger Pflichtmatrix auf `validated` setzen. |

## Abgeschlossene Arbeitspakete

### AP-2026-017: W2b-A JSON Path Exists

| Feld | Wert |
|---|---|
| ID | `AP-2026-017` |
| Ziel | Den freigegebenen Pfadprüfungs-Slice von `TC-2026-009` als portables Modul für SQL Server 2019+ implementieren und prüfen. |
| Scope | `toolbelt.json.path-exists` Version `1.0.0`; öffentliche `toolbelt_json.TVF_JsonPathExists`; Root-, Property-, Quote-, Array-Index- und Wildcard-Pfade; SQL-NULL-Propagation; fehlerfreies `0` bei ungültigem JSON oder Pfad; lokales und zentrales Deployment. Keine JSON-Konstruktoren, Aggregate, SQL CLR, Scalar-Wrapper oder SQL-Server-2025-Preview-Ranges/-Listen/`last`. |
| Dependencies | Gemeinsame W2b-Vertragsrunde und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | `1`/`0`/SQL-`NULL` als `int`; JSON `null` zählt als vorhanden; case-sensitive BIN2-Keyvergleich; Pfad- und JSON-Fehler verlassen den Funktionsvertrag nicht; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Prüfung und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 mit nativer Parität, synthetischen Fehler-/Collation-Fällen, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesign `JSON_PATH_EXISTS_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.json.path-exists/`; [W2b JSON Path Runtime 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943) und [Documentation Consistency 30568128932](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128932) erfolgreich. |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung gezielt ausführen. |

### AP-2026-016: Portable W2a – Truncation, Bucketing und Bigint-Bitoperationen

| Feld | Wert |
|---|---|
| ID | `AP-2026-016` |
| Ziel | Die gemeinsam geplanten Kandidaten `TC-2026-004`, `TC-2026-005` und `TC-2026-007` als drei portable Compatibility-Module implementieren und prüfen. |
| Scope | `toolbelt.datetime.truncate`, `toolbelt.datetime.bucket` und `toolbelt.binary.bit-operations`; typgetrennte öffentliche Date/Time-Inline-TVFs, interner Bucket-Optimizer-Core, Bigint-Shift/Count/Get/Set, Lifecycle, Central Deployment, Dokumentation und synthetische Contract-Tests. Keine Scalar UDFs, keine `datetime`-/`smalldatetime`-/`time`-Familie und kein `binary(n)`-/`varbinary(n)`-Provider. |
| Dependencies | Funktionsbezogener W2a-Vorschlag im Implementierungsplan und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Typstabile relationale APIs; dokumentierte Dateparts, Scale-7-, `DATEFIRST`-, Origin-, negative Floor-, Shift-, Vorzeichen- und Validation-Code-Semantik; lokale und zentrale Installation; Wiederholungsdeployment und Uninstall; native Parität auf SQL Server 2022/2025; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Contracts und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Runtime, nativer Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `DATETIME_TRUNCATE_MODULE_DESIGN.md`, `DATETIME_BUCKET_MODULE_DESIGN.md` und `BIT_OPERATIONS_MODULE_DESIGN.md`; [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509), [Documentation Consistency 30561235177](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561235177). |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung sowie gezielte Bucket-Core-Performance-Evidenz ausführen. |

### AP-2026-015: Portable W1 – Calendar Difference, Directional TRIM und URI Component

| Feld | Wert |
|---|---|
| ID | `AP-2026-015` |
| Ziel | Die gemeinsam besprochenen Kandidaten `TC-2026-002`, `TC-2026-008` und `TC-2026-024` als drei unabhängige, portable Module implementieren. |
| Scope | `toolbelt.datetime.calendar-difference`, `toolbelt.string.directional-trim` und `toolbelt.conversion.uri-component`; öffentliche inline TVFs, optionale URI-Scalar-APIs, Lifecycle, Dokumentation und synthetische Contract-Tests. |
| Dependencies | Funktionsbezogene Besprechung und ausdrückliche Benutzerfreigabe vom 2026-07-30; für TRIM und URI `toolbelt.core.generate-series` Version `1.0.0`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Anniversary-Regel, gerichtetes und typstabiles Trim sowie RFC-3986-Komponentenencoding sind explizit dokumentiert; keine implizite IRI-, Form-Encoding- oder Double-Decoding-Semantik. |
| Tests | Statische Contracts und GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; Anniversary-, Grenzwert-, Unicode-/UTF-8-, Fehler-, Paritäts-, Wiederholungs-, lokaler, zentraler und Uninstall-Scope geprüft. |
| Blocker | Keine. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe 2026-07-30; [W1 Portable Runtime 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399), [Documentation Consistency 30553118014](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118014). |
| Nächster Schritt | Physische Zielversions- und Windows-Läufe sowie die noch offenen LOB-, Collation- und Kollisionsfälle im Rahmen der Releasevalidierung ausführen. |

### AP-2026-014: Inline-TVF-Alternativen für bestehende SVFs

| Feld | Wert |
|---|---|
| ID | `AP-2026-014` |
| Ziel | Für alle fachlich geeigneten vorhandenen SVFs eine semantisch äquivalente inline-TVF-API bereitstellen und die inline TVF als kanonischen relationalen Kern verwenden. |
| Scope | `toolbelt.conversion.base64`, `toolbelt.conversion.integer-base` und `toolbelt.validation.semantic-version`; sechs neue inline TVFs gemäß `SVF_INLINE_TVF_AUDIT.md`; vorhandene SVFs bleiben als Convenience-API erhalten. |
| Dependencies | Benutzeranforderung vom 2026-07-30; `DEC-2026-022`; bestehende öffentliche Verträge der sechs SVFs. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Kein TVF-Wrapper ruft lediglich die SVF auf; Fachlogik besitzt genau einen kanonischen Kern; Parität, Objekttyp, `NULL`- und Fehlersemantik, lokale und zentrale Installation sowie Lifecycle sind getestet; Objekt- und Moduldokumentation zeigt `APPLY` als bevorzugte Mengenverwendung. |
| Tests | Statische Modulverträge und vollständiger Dokumentationsaudit erfolgreich; Runtime auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parität, `APPLY`, Upgrade, Wiederholung, Kollision, zentralem Deployment und Uninstall erfolgreich. |
| Blocker | Keine. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | `DEC-2026-022`, `Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md`; [Base64 Runtime 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837), [Integer-Base Runtime 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860), [Semantic-Version Runtime 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984), [Documentation Consistency 30535377863](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377863). |
| Nächster Schritt | Physische Zielversions- und Windows-Läufe im Rahmen der Releasevalidierung ausführen. |

### AP-2026-013: Frei definierbare Zahlensysteme implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-013` |
| Ziel | `TC-2026-031` als Integer-Encode-/Decode-Capability mit frei definierbarem Alphabet implementieren. |
| Scope | `toolbelt.conversion.integer-base` Version `1.0.0`; vollständiger `bigint`-Bereich; Alphabet mit 2 bis 93 druckbaren ASCII-Zeichen außer `-`; kanonische Encode-/Decode-Darstellung und Overflow-Vertrag. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Encode/Decode verwenden denselben kanonischen Alphabetvertrag; Zeichen sind binär eindeutig; ungültiges Alphabet, ungültige Ziffer, Vorzeichen, `bigint`-Minimum, Null und Overflow sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag und SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben `not executed`. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-031`; kanonische Artefakte unter `Modules/toolbelt.conversion.integer-base/`; erfolgreicher [Runtime-Lauf 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070); persönlicher Brainstorm als Herkunft. |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung später gezielt ausführen. |

### AP-2026-012: Semantic-Version Parser und Comparator implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-012` |
| Ziel | `TC-2026-030` als strikt SemVer-2.0.0-konformen Parser, Comparator und Sort Key implementieren. |
| Scope | `toolbelt.validation.semantic-version` Version `1.0.0`; ASCII `varchar(8000)`; Core, Pre-release, Build Metadata, Validierung, Präzedenzvergleich und binärer Sort Key; keine allgemeinen Produktversionsformate. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | SemVer-2.0.0-Grammatik und Präzedenz vollständig; Build Metadata beeinflusst Vergleich und Key nicht; beliebig lange numerische Komponenten ohne verlustbehaftete Konvertierung; offizielle und synthetische Vektoren, Lifecycle und Dokumentation vollständig. |
| Tests | Statischer Vertrag und SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben `not executed`. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-030`; kanonische Artefakte unter `Modules/toolbelt.validation.semantic-version/`; erfolgreicher [Runtime-Lauf 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373). |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung später gezielt ausführen. |

### AP-2026-011: Multi-Separator-Split Version 1 implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-011` |
| Ziel | `TC-2026-001` als portablen Split-Vertrag für mehrere einzelne Trennzeichen implementieren. |
| Scope | `toolbelt.string.split-characters` Version `1.0.0`; `TVF_SplitByCharacters`; stabile Ordinals, definierte leere Tokens, einzelne Separatorzeichen, binärer Collation- und LOB-Vertrag; keine mehrzeichigen Separatoren, Quote- oder Escape-Semantik. |
| Dependencies | `toolbelt.core.generate-series` Version `1.0.0`; vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Literalvertrag bleibt von Regex getrennt; Token und Ordinal sind deterministisch; `NULL`, NUL, leerer Input, aufeinanderfolgende Separatoren, Separator am Rand, Collations und Größenklassen sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag und SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen physische SQL-Server-2019-/2022- und Windows-Evidenz. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-001`; kanonische Artefakte unter `Modules/toolbelt.string.split-characters/`; [Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708) erfolgreich. |
| Nächster Schritt | Physische 2019-/2022- und Windows-Läufe gezielt vor Release ausführen. `TC-2026-032` bleibt Research ohne Implementierungsfreigabe. |

### AP-2026-010: Identifier- und Multipart-Name-Toolkit implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-010` |
| Ziel | Den aus `RI-2026-011` formalisierten und freigegebenen Vertrag `TC-2026-029` als portables Metadata-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.metadata.identifier` Version `1.0.0`; `TVF_ParseMultipartName` und `SVF_QuoteMultipartName`; ein- bis vierteilige Namen, `[...]`, `]]`, ausgelassene mittlere Teile, stabile Validation Codes, lokales und zentrales Deployment. Keine Objektauflösung, Berechtigungsprüfung, doppelten Anführungszeichen oder CLR. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe des Benutzers vom 2026-07-30; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zustandsbasierter kanonischer Parser; genau eine Ergebniszeile; rechtsbündige Teile; vollständige Escape-, Omission-, Längen-, Collation-, Wrapper-, Deployment- und Lifecycle-Contracts; Dokumentation und Change-Impact-Registry gekoppelt. |
| Tests | Statischer Vertrag und SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen physische SQL-Server-2019-/2022- und Windows-Evidenz. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-029`; kanonische Artefakte unter `Modules/toolbelt.metadata.identifier/`; [Identifier Runtime Run 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834) erfolgreich. |
| Nächster Schritt | Physische 2019-/2022- und Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-009: Portable Ganzzahlreihen implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-009` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-006` als portables Core-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.core.generate-series` Version `1.0.0`; `TVF_GenerateSeriesInt` und `TVF_GenerateSeriesBigInt`; portable T-SQL Inline TVFs; lokales und zentrales Deployment; Richtungs-, Default-, NULL-, Fehler-, Grenz-, Größen-, Join-, `CROSS APPLY`-, native Paritäts- und Lifecycle-Tests. Keine Dezimaltypen, persistente Numbers-Tabelle oder SQL CLR. |
| Dependencies | Besprochener und am 2026-07-30 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu einem anderen Toolbelt-Modul. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Inline TVFs im Schema `toolbelt_core`; typstabile `int`-/`bigint`-Resultsets; gemeinsamer `bigint`-Kern; richtungsabhängiger Default; keine stille Kürzung; Enginefehler bei Schritt `0` und nicht darstellbarer Zeilenzahl; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung und serieller GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben bis zur gezielten Releasevalidierung `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen physische SQL-Server-2019-/2022- und Windows-Evidenz sowie eine breitere Performancebewertung sehr großer Reihen. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; kanonische Artefakte unter `Modules/toolbelt.core.generate-series/`; [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) erfolgreich. |
| Nächster Schritt | Physische 2019-/2022- und Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-008: Base64/Base64URL-Modul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-008` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-012` als portables Conversion-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.conversion.base64` Version `1.0.0`; `SVF_Base64Encode` und `SVF_Base64Decode`; T-SQL/XML-Provider; lokales und zentrales Deployment; RFC-4648-, native Paritäts-, Fehler-, Größen- und Lifecycle-Tests. Kein CLR, keine Zeichenkodierung und keine Datei-I/O. |
| Dependencies | Besprochener und am 2026-07-29 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu ResultTable. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Scalar UDFs im Schema `toolbelt_conversion`; Standard- und URL-safe-Ausgabe; Decode beider Alphabete, optionales Padding und definierter Whitespace; unveränderte Providerfehler; keine String-zu-Binär-Konvertierung; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung und serieller GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben bis zur gezielten Releasevalidierung `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen physische SQL-Server-2019-/2022- und Windows-Evidenz sowie eine breitere Performancebewertung großer LOBs. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.conversion.base64/`; [Base64 Runtime Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) erfolgreich. |
| Nächster Schritt | Physische 2019-/2022- und Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-007: Entscheidungsvorbereitung für das zweite Modul

| Feld | Wert |
|---|---|
| ID | `AP-2026-007` |
| Ziel | Die nächsten kleinen Compatibility-Kandidaten so vergleichen, dass die funktionsbezogene Benutzerbesprechung ohne verdeckte Typ-, Provider- oder Fehlerentscheidungen geführt werden kann. |
| Scope | Vertiefter Vergleich von `TC-2026-004` und `TC-2026-012`; dokumentierte Empfehlung, Vertragsfragen, Provideroptionen, Testdimensionen, Abhängigkeiten und Implementierungs-Gates. Keine SQL-Implementierung und kein Modulmanifest. |
| Dependencies | `AP-2026-003`, `AP-2026-005`, funktionsbezogenes Implementierungs-Gate und Phase-2-Abhängigkeit aus der Roadmap. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Bevorzugter Besprechungskandidat nachvollziehbar ausgewählt; Alternative mit konkretem Grund zurückgestellt; offene Benutzerentscheidungen und Pflichtprüfungen sichtbar; kein öffentlicher Funktionsvertrag oder Implementierungsrecht behauptet. |
| Tests | Primärquellenabgleich gegen Microsoft Learn und RFC 4648; Kandidaten-, Backlog-, Roadmap-, Link-, Datenschutz- und Change-Impact-Prüfung. Runtime-Tests sind für diese reine Entscheidungsvorbereitung `not applicable`. |
| Blocker | Keine. Der konkrete Vertrag wurde am 2026-07-29 besprochen und freigegeben; das pauschale Referenzmodul-Gate wurde durch `DEC-2026-021` scopebezogen präzisiert. |
| Evidenz | `Documentation/Research/SECOND_MODULE_SELECTION.md` und aktualisierte Kandidaten `TC-2026-004`/`TC-2026-012`; geprüft am 2026-07-29. |
| Nächster Schritt | Abgeschlossen; Umsetzung erfolgt in `AP-2026-008`. Die offenen ResultTable-Pflichtfälle bleiben ein eigenes Arbeitspaket. |

### AP-2026-006: Dokumentationsbaseline und inkrementeller Drift-Schutz

| Feld | Wert |
|---|---|
| ID | `AP-2026-006` |
| Ziel | Die vollständige Dokumentationsbaseline herstellen und nachfolgende Änderungen über explizite, diff-basierte Artefaktkopplungen synchron halten. |
| Scope | Statuskorrekturen, getrennte Modulstatusdimensionen, Modulregistry, gekoppelte Dokumentationspfade, generierte Statusabschnitte, inkrementeller Validator, pfadbezogene CI und Pull-Request-Checkliste. |
| Dependencies | aktueller `main`, implementiertes ResultTable-Modul und `DEC-2026-020`. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Einmaliger Vollaudit erfolgreich; bekannte Statusdrift beseitigt; Runtime-CI nicht mehr durch reine Dokumentationsänderungen ausgelöst; Folgeprüfungen diff-basiert; geschützte Lizenzinhalte unverändert. |
| Tests | Python-Standardbibliothek-Validator, modulspezifische statische Prüfung, Markdown-Linkprüfung, YAML-/Workflow-Strukturprüfung, Datenschutz-/Secret-Diffprüfung und GitHub Actions. |
| Blocker | Keine. |
| Evidenz | Lokaler vollständiger Baseline-Audit am 2026-07-29 erfolgreich; [Documentation Consistency Run 30453805254](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805254) und [ResultTable Runtime Run 30453805186](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805186) vollständig erfolgreich. |
| Nächster Schritt | Abgeschlossen; die laufende Dokumentationskonsistenz wird durch den inkrementellen Validator geschützt. |

### AP-2026-005: SQL-Server-Toolbelt-Landschaft und Prior Art

| Feld | Wert |
|---|---|
| ID | `AP-2026-005` |
| Ziel | Öffentliche SQL-Server-Toolbox-, Capability-, Test-, Diagnose-, Maintenance- und Parallelisierungsprojekte systematisch vergleichen, belastbare Prior Art für die bereits erfassten Execution-Themen dokumentieren und neue Toolbelt-Lücken ableiten. |
| Scope | Landschaftsdokument mit direkter Einordnung von 16 Projekten; vertiefter Vergleich der direkten Capability-Libraries; zweite Session, rollback-unabhängiges Logging, Parallelisierungsprovider, Console, Error Handling und Cancellation; Präzisierung von `TC-2026-012`; neue Kandidaten `TC-2026-023` bis `TC-2026-028`; quellenbasierte Vorprüfung des persönlichen Brainstorms einschließlich PowerShell, Python, REST/Web und KI/Chat. |
| Dependencies | `AP-2026-001`, `AP-2026-004`, Repository-Grenzen, Third-Party-/Source-Policy und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Projekte nach Rolle, Technik, Packaging, Lizenz-/Statushinweis und Repository-Ziel eingeordnet; direkte Analogien von bloßen Skriptkatalogen getrennt; Prior Art für zweite Session, Parallelisierung, Host-Automation, Python, REST und KI aus Primärquellen dokumentiert; übertragbare und zu vermeidende Muster benannt; neue Kandidaten vollständig und ohne Implementierungszusage erfasst. |
| Tests | Quellen- und Linkstrukturprüfung; Duplikatprüfung gegen kuratierte Kandidatenlisten, persönlichen Brainstorm und Architekturverträge; Third-Party-, Datenschutz- und Secret-Gate; ausschließlich Dokumentations- und Backlogänderungen. |
| Blocker | Keine für Research; Codeübernahme benötigt zusätzlich eine datei- und versionsbezogene Lizenzprüfung. Jede Funktion benötigt vor Implementierung weiterhin eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md`, präzisierter Kandidat `TC-2026-012`, aktualisierte Kandidaten `TC-2026-014`/`TC-2026-015` und neue Kandidaten `TC-2026-023` bis `TC-2026-028`; geprüft am 2026-07-29. |
| Nächster Schritt | Forschungsergebnis nach Abschluss der ResultTable-Validierungswelle mit dem Benutzer priorisieren; keine automatische Aktivierung eines weiteren Implementierungsarbeitspakets. |

### AP-2026-004: Backlog Research Wave 2 – Execution Infrastructure

| Feld | Wert |
|---|---|
| ID | `AP-2026-004` |
| Ziel | Die vom Benutzer angestoßenen Ideen zu zweiter Session, rollback-unabhängigem Logging, Parallelisierung, Error Handling, Console-Ausgabe und Gruppenabbruch quellenbasiert erfassen und um unmittelbar notwendige Supporting Capabilities ergänzen. |
| Scope | `TC-2026-014` bis `TC-2026-022`; Toolbelt-Kandidaten für autonome Ereignisprotokollierung, Work Queue, Console, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker Lease und sicheren Work-Type-Katalog. |
| Dependencies | Repository-Grundaufbau, Backlog-Curator-Regeln und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, vollständige Felder, Primärquellen, klare Trennung dokumentierter Engine-Semantik von offenen Architekturentscheidungen sowie einen nächsten Besprechungsschritt; kein Runtime-Objekt und keine Implementierungsfreigabe werden erzeugt. |
| Tests | Duplikatprüfung gegen alle drei Kandidatenlisten und bestehende Architekturverträge; Quellenprüfung gegen Microsoft Learn und den Microsoft SQL Server Blog; Datenschutz- und Secret-Gate. |
| Blocker | Keine für die Research-Erfassung; jede spätere Funktion benötigt eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Backlog/TOOLBELT_CANDIDATES.md`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Kandidaten einzeln nach Nutzen und Abhängigkeiten mit dem Benutzer besprechen; keine automatische Aktivierung als Implementierungsarbeitspaket. |

### AP-2026-002: ResultTable-Infrastruktur implementierungsreif spezifizieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-002` |
| Ziel | Den Kandidaten `TC-2026-003` als erstes `toolbelt_core`-Modul ohne offene Vertragsfragen spezifizieren. |
| Scope | Modulgrenze, Objektinventar, öffentliche Schnittstelle, Schemaquelle, Metadaten- und Datentypnormalisierung, `@KeepData`, Preflight, DDL, Transaktionen, Fehler, Deployment, Lifecycle und Testmatrix. |
| Dependencies | `TC-2026-003`, `USP_CONTRACT.md`, Modul- und Deployment-Modell. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; einzige Procedure klassifiziert; keine ungeregelten weiteren persistenten Objekttypen benötigt; Referenztabellen- und Vertrauensgrenze definiert; interne Temp-Namensregel festgelegt; Fehler-, Transaktions-, Collation-, Datentyp-, Deploy- und Uninstall-Verträge dokumentiert; vollständige Testmatrix vorhanden. |
| Tests | Statischer Abgleich gegen USP-Vertrag, T-SQL-Regeln, Modul-/Deployment-Modell, Namenskonventionen, Datenschutz, Supportmatrix und Architekturentscheidungen; Runtime-Tests für diese reine Designwelle `not applicable`. |
| Blocker | Keine |
| Evidenz | `Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md`, `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017`; geprüft am 2026-07-29. |
| Nächster Schritt | `AP-2026-003` ausführen. |

### AP-2026-001: Backlog Research Wave 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-001` |
| Ziel | Eine erste belastbare, versionsbezogene Kandidatenwelle für SQL Server 2019, 2022 und 2025 erstellen. |
| Scope | `Backlog/TOOLBELT_CANDIDATES.md`; vorhandene Kandidaten präzisieren und neue Compatibility-, Core-, String-, Datetime-, JSON- und Binary-Kandidaten erfassen. |
| Dependencies | Repository-Grundaufbau und Backlog-Curator-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, Ziel-Repository, Versionsbezug, spätere native Funktion, Nutzen, Technologieoptionen, Performance-/Security-Aspekte, Plattformgrenzen, Duplikatprüfung, Primärquellen, Prüfdatum und nächsten Schritt. |
| Tests | Primärquellenprüfung gegen Microsoft Learn; Duplikatprüfung innerhalb der Toolbelt-Listen; Abgrenzung zu `SQL_Server_Analyze`; Fakten und offene Punkte getrennt formuliert. |
| Blocker | Keine |
| Evidenz | `TC-2026-001` bis `TC-2026-013`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Weitere Kandidatenwellen nach Abhängigkeit oder durch den Backlog Curator ergänzen. |

## Vorlage

```markdown
### AP-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | AP-YYYY-NNN |
| Ziel | <Messbares Ziel> |
| Scope | <Betroffene Module, Schemas und Objekte> |
| Dependencies | <Arbeitspakete, Module oder externe Voraussetzungen> |
| Priorität | <P0 / P1 / P2 / P3> |
| Status | <proposed / researched / ready for development / active / blocked / completed / rejected> |
| Implementation Status | <nur für Module; aus module.yaml abgeleitet> |
| Validation Status | <nur für Module; aus module.yaml abgeleitet> |
| Release Status | <nur für Module; aus module.yaml abgeleitet> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.
