---
name: "toolbelt-semver-svf-semanticversionsortkey"
description: "Skalarer Komfortaufruf des kanonischen relationalen SemVer-Sortierschlüssels."
skill_format_version: "1.0"
module_id: "toolbelt.validation.semantic-version"
schema_name: "toolbelt_validation"
object_name: "SVF_SemanticVersionSortKey"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Version", "sql_type": "varchar(8000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": true, "description": "ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich."}]
source_paths: ["Modules/toolbelt.validation.semantic-version/Source/SVF_SemanticVersionSortKey.sql", "Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql", "Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# SVF_SemanticVersionSortKey

## Zweck und Einsatzfälle

Skalarer Komfortaufruf des kanonischen relationalen SemVer-Sortierschlüssels. Für mengenorientierte Vergleiche/Sortierung sind die relationalen TVFs die kanonischen Einstiegspunkte; SVFs dienen einzelnen Komfortaufrufen.

## Voraussetzungen

Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |

## Ergebnisse

Ein varbinary(max)-Rückgabewert mit dem Vertrag von TVF_SemanticVersionSortKey, bei ungültiger/NULL-Eingabe NULL. Build-Metadaten beeinflussen den Schlüssel nicht; gleiche Präzedenz liefert keinen eindeutigen Zeilen-Tie-Breaker. Kein Resultset und keine OUTPUT-Parameter. Binärformat nicht als unbegrenzt stabilen externen Speichervertrag verwenden.

## Aufrufbeispiele

```sql
SELECT toolbelt_validation.SVF_SemanticVersionSortKey('1.2.3-alpha.1') AS SortKey;
-- Für Mengen TVF_SemanticVersionSortKey per APPLY verwenden.
```

## Rechte

Vorhandenes EXECUTE auf dieser skalaren Funktion und die im tatsächlichen Ownership-/Datenbankkontext erforderlichen Rechte der internen Funktionsaufrufe. Keine automatische Rechtevergabe, Serverrechte, EXECUTE-AS-Ausweitung oder Quelltabellenabfrage. Zentrale dreiteilige Aufrufe erfordern den entsprechenden Datenbankzugriff; ein Skill erteilt keine Rechte.

## Ressourcenbedarf

Skalarer T-SQL-Wrapper mit einem SELECT aus der SortKey-TVF; übernimmt deren Parser-, Positions-, Aggregations- und Ausgabekosten. Keine Zusage von skalarem Inlining, Laufzeit oder Indexnutzbarkeit in jedem Abfragekontext.

## Nebenwirkungen

Rein lesende Berechnung aus Argumenten und lokalen Werten; kein Zugriff auf Benutzertabellen/Systemkataloge, keine DML an persistenten Objekten, keine Dateien oder externen Aufrufe. Ausgabe erzeugt keine Installation, Indexanlage oder Zustandsänderung.

## Fehlerbehandlung

Der Parser liefert genau einen ersten Validierungsbefund: VALID (gültig), NULL_INPUT (NULL), EMPTY_INPUT (leer), INVALID_CHARACTER (Zeichen außerhalb des globalen ASCII-Zeichenvorrats), BUILD_FORMAT (mehrfaches Plus oder leere/ungültige Build-Identifier), EMPTY_BUILD (Plus ohne Buildteil), EMPTY_PRERELEASE (Bindestrich ohne Pre-release-Teil), CORE_FORMAT (nicht drei nichtleere reine Ziffernkomponenten), CORE_LEADING_ZERO (führende Core-Null), PRERELEASE_FORMAT (leerer/ungültiger Pre-release-Identifier), PRERELEASE_LEADING_ZERO (mehrstelliger rein numerischer Pre-release-Identifier mit führender Null). Die Prüf-Reihenfolge ist globaler Input/Zeichenvorrat, Buildabtrennung, Pre-release-Abtrennung, Core, Pre-release-Identifier und Build-Identifier. Vergleich und SortKey geben bei ungültigem Parserstatus NULL statt dieses Statuscodes aus; für Diagnosen den Parser separat verwenden. SQL-Typbindungs-, Ressourcen- und Enginefehler sind keine fachlichen Validierungscodes und werden nicht allgemein abgefangen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag. Vorhandene fachliche Nachweise dürfen nur bei unveränderter Bindung wiederverwendet werden; diese passiven Skillkommentare sind keine neue native Qualifikation. Kein Versionsbereich-/Wildcard-/v-Präfix-/Paketmanagerparser, keine automatische Bereinigung und keine Eindeutigkeit bei gleicher SemVer-Präzedenz. Die Argumentgrenze gilt nach SQL-Bindung; fehlende Originalbytes längerer Eingaben sind nicht rekonstruierbar.
