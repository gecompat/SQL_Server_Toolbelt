# JSON Pointer V1 – verbindlicher Vertrag

Stand: 2026-10-05. RelatedReference: `RI-2026-041`.
Nach Besprechung in [PR173](https://github.com/gecompat/SQL_Server_Toolbelt/pull/173)
und der konkret gestellten Frage antwortete der Benutzer ausdrücklich:
„Diese Pointer-Funktion freigegeben“. Diese Einzelzustimmung autorisiert genau
die folgende lesende T-SQL-MSTVF. Keine Schema-, Patch-, CLR- oder Releasefreigabe.

## Zweck und Oberfläche

`toolbelt.json.pointer` 1.0.0 löst die Stringform eines JSON Pointers nach
[RFC6901](https://www.rfc-editor.org/rfc/rfc6901) auf und unterscheidet Existenz,
fehlenden Wert, JSON-null und SQL-NULL. Kein SQL/JSON-Path, URIfragment, Patch,
Datei-/Netzwerkzugriff oder Datenänderung.

Genau ein öffentliches Objekt: `toolbelt_json.TVF_ResolveJsonPointer`,
Multi-statement T-SQL-TVF (`TF`). Kein Scalarwrapper oder persistenter Helper.

| Ordinal | Parameter | Typ | Default | Zulässigkeit |
|---:|---|---|---|---|
| 1 | `@Json` | nvarchar(max) | keiner | vollständiges JSON einschließlich Scalarroot; SQL-NULL siehe Priorität |
| 2 | `@Pointer` | nvarchar(max) | keiner | Stringform, leer für Root; höchstens4000 UTF16-Einheiten |
| 3 | `@MaxInputBytes` | bigint | 16777216 | 1..16777216, nur absenkbar; DATALENGTH des Originaldokuments |
| 4 | `@MaxDepth` | int | 128 | 1..128, nur absenkbar; gleichzeitig offene Container |

Bei TVF-Aufrufen werden alle vier Argumente angegeben; `DEFAULT` verwendet
die jeweiligen Budgetdefaults. BudgetsNULL/0/negativ/über Ceiling sind ungültig.

## Genau eine Ergebniszeile

| Ordinal | Spalte | Typ | Nullable | Bedeutung |
|---:|---|---|---|---|
| 1 | Status | varchar(16) | nein | FOUND, MISSING, JSON_NULL, SQL_NULL oder INVALID |
| 2 | JsonType | varchar(8) | ja | STRING, NUMBER, BOOLEAN, OBJECT, ARRAY oder NULL |
| 3 | Value | nvarchar(max) | ja | decodierter String, originales Zahlenliteral, true/false oder gültiger Containertext |
| 4 | ErrorCode | varchar(32) | ja | stabiler Code bei INVALID, sonst SQL-NULL |

Textspalten verwenden `Latin1_General_100_BIN2`. Bei FOUND sind JsonType und
Value vorhanden; ein leerer String bleibt FOUND/STRING mit leerem Value.
JSON_NULL liefert JsonType=`NULL`, Value=SQL-NULL. MISSING/SQL_NULL/INVALID
liefern JsonType und Value als SQL-NULL. ErrorCode ist nur bei INVALID vorhanden.
Containerwerte besitzen keine Formatierungstreuezusage; Zahlen werden nicht
in einen nativen Zahlentyp konvertiert. Metadaten-Nullability ist verbindlich.

## Priorität und Fehler

1. SQL-NULL in Json oder Pointer: SQL_NULL, auch bei sonst ungültigen Budgets.
2. Ungültige Budgets: INVALID/PARAMETER.
3. Überschrittene Input-/Pointergrenzen: INVALID/INPUT_LIMIT beziehungsweise
   INVALID/POINTER_LIMIT; Originalbytes zählen vor Wrapperkopien.
4. Pointerstring beginnt außer bei leerem Root mit `/`; ausschließlich `~0`
   und `~1` sind Escapes. Syntaxfehler: INVALID/POINTER_SYNTAX.
   Ungepaarte Pointer-Surrogate: INVALID/UNICODE.
5. Vollständige JSON-Syntax ungültig: INVALID/JSON_SYNTAX.
6. Dokumenttiefe über MaxDepth: INVALID/DEPTH_LIMIT; Scalarroot zählt0,
   Containerroot1. Danach ungepaarte decodierte Dokument-Surrogate:
   INVALID/UNICODE. Die vollständige Unicodeprüfung umfasst unselektierte
   Keys/Strings; nach bestätigter Syntax hat Tiefe Vorrang vor Unicode.
7. Auflösung: mehrere passende decodierte Objektkeys ergeben
   INVALID/DUPLICATE_KEY; ungültige Arrayindexlexik INVALID/ARRAY_INDEX.

Keine Eingabe-/Enginefehlertexte im Ergebnis. Technische Enginefehler werden
nicht in ein erfundenes fachliches Ergebnis umgedeutet.

## Pointer- und Unicode-Semantik

Leerer Pointer adressiert die Wurzel. `~1` ergibt Slash, `~0` Tilde; kein
doppeltes Decoding. Leere Keytokens sind zulässig. Objektkeys werden nach
Decoding ohne Normalisierung oder Collationfaltung exakt einschließlich
trailing spaces und NUL verglichen: BIN2 plus DATALENGTH.

Arrayindices sind `0` oder positive ASCII-Dezimalzahlen ohne führende Null.
Nur im Arraykontext gilt diese Lexik: Objektkeys `01`, `x` und `-` bleiben
normale Keys. Arraytoken `-` und gültige Indices außerhalb des Arrays ergeben
MISSING; auch beliebig große gültige Indices werden ohne Overflow so bewertet.
Weiterlaufen durch Scalar oder JSON-null ergibt MISSING. JSON_NULL bezeichnet
nur den erfolgreich aufgelösten terminalen Nullwert. Unbeteiligte Duplicatekeys
verhindern die Auflösung nicht.

Gültige Surrogatpaare einschließlich gemischter raw/escaped Dokumenteinheiten
sind erlaubt; ungepaarte Surrogate im gesamten Dokument/Pointer werden
abgewiesen. Escaped NUL ist zulässig, keine Unicode-Normalisierung.
Die Abweisung ungepaarter Escapes ist Toolbelt-Policy gegenüber
[RFC8259 §8.2](https://www.rfc-editor.org/rfc/rfc8259#section-8.2).

## Kanonischer nativer Pfad und MSTVF-Ausnahme

ISJSON bleibt Grammatikautorität. Object-/Arrayroots direkt validieren; nur
Scalarroots erhalten einen max-typisierten Arraywrapper mit genau einem Element.
Der künstliche Wrapper verändert die fachliche Tiefe nicht. Anschließend prüft
ein vorwärts laufender Policywalker Quotes/Escapes, decodierte UTF16-Einheiten
und offene Container unter expliziter non-SC-Collation in begrenzten Chunks.
Keine zweite Number-/Member-/Separatorgrammatik.

OPENJSON bekommt ausschließlich zuvor gültige Operanden; separate IF-Zweige
und initial gültige lokale Operanden, keine WHERE-/CASE-Auswertungsbarriere.
Je Traversalschritt Trefferzahl/Typ/Wert aggregieren. Kein vollständiges
Geschwisterresultset in einer Tabellenvariable. Pointerescapes werden ohne
NUL-abhängiges REPLACE decodiert. Der Constructor-CLR-Kern bleibt unverändert.

Sequentieller Unicodezustand, Phasenpriorität und abhängige Traversalschritte
mit Duplicate-Aggregation begründen die MSTVF-Ausnahme. Eine gleichwertige
Inline-Lösung ist ungezeigt, nicht grundsätzlich unmöglich. Rekursive CTEs und
CLR-Reuse wurden als Alternativen geprüft. MSTVF-Kardinalität, Parallelität
und APPLY-Kosten dürfen nicht als Inline-TVF-Eigenschaften beworben werden.

Inputgröße/Tiefe begrenzen eigene Scans und Traversalschritte; wiederholtes
Fragmentparsing/-kopieren kann nominell Arbeit proportional zu Input mal Tiefe
benötigen. Keine Heap-, Dauer-, Maximalworkload- oder Performancezusage.
Es wird kein zusätzliches unbesprochenes Arbeitsbudget eingeführt.

## Lifecycle und Validierung

Local und central verwenden denselben Sourcekern; direkte CrossDB-Aufrufe
werden separat geprüft. Keine Modulabhängigkeit, Rechtevergabe, CLR-/Trust-
oder Konfigurationsänderung. Deployment benötigt passende vorhandene DDL-
Rechte und vollständige Dependency-Metadatensicht. Geteiltes toolbelt_json-
Schema und fremde Objekte bleiben erhalten. Keine Synonyme.

Support: SQL Server2019/2022/2025 Windows/Linux mit CL150/160/170, soweit der
jeweilige Engine-Major den CL unterstützt. Deployment weist ältere Engines,
CL unter150 sowie inkompatible Version-/CL-Paare vor Mutation ab. Im unterstützten
central/CrossDB-Scope besitzen auch Caller-/Consumerdatenbanken CL150 oder höher;
der Adapter prüft ihre ausdrücklich gewählte Compatibility-Konfiguration.

Lifecycle 55520..55529: vollständiger Preflight vor Mutation, exakte typisierte
Ownershipmarker/Release-/Modusprüfung, eigener atomarer Transaktionsscope,
Application Lock, Fremdconsumer-/Fremdslotschutz und Repeat/Uninstall. Aktive
Callertransaktionen werden vor SET/DDL nicht-dooming mit RAISERROR50000/state1
und Präfix `TBX_JSON_POINTER_LIFECYCLE_CALLER_TRANSACTION` abgewiesen.
Central-Uninstall verlangt explizite ConfirmNoExternalConsumers=1.
Sourcehashes bleiben diagnostisch. Version1.0.0 besitzt keinen Vorgänger;
historische Upgrades sind not applicable.

Pflichtnachweise: feste RFC-/Status-/Prioritätsorakel, Metadaten und Clientreader,
BIN2/CI/CS/SC/UTF8-Kontexte, Local/Central/Consumer, Erst-/Repeat-/Uninstall,
Caller-/Lock-/Rollback-/Marker-/Fremdslot-/Dependencyschutz und eigener Cleanup.
SQL2019/2022/2025 Windows/Linux getrennt bewerten. Die sechs historischen
Engineproben in PR173 sind kein API-/Policywalker- oder Lifecycle-Nachweis.
Weitere offene Kombinationen bleiben sichtbar; keine Releasefreigabe.
