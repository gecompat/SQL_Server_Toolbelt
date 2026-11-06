# JSON-Constructor: begrenztes Callerprofil

Am 2026-11-06 bestanden die vier vorhandenen Constructor-USPs unter einem
synthetischen Datenbankbenutzer ohne Login auf Windows SQL2025/CU8 mit
CL150, CL160 und CL170, jeweils lokal und direkt zentral. Das sind sechs
Kontexte, 72 positive API-/Routenprofile und 72 erwartete SQL229-Abweisungen.
Jeder der drei Gesamtläufe bestand beide Modi und einen frischen separaten
Abschlussaudit. Ergebnis: **PASS_FOR_DECLARED_SCOPE**, keine Modulgesamtfreigabe.

## Rechte und Orakel

Der Benutzer hat die temporäre Rechtevergabe ausdrücklich freigegeben:
EXECUTE auf `USP_JsonArray`, `USP_JsonObject`, `USP_JsonArraysByGroup` und
`USP_JsonObjectsByGroup`, außerdem VIEW DEFINITION und EXECUTE ausschließlich
auf `toolbelt_core.USP_PrepareResultTable`. Der Benutzer erhält keine Login-,
Rollen-, Schema-, Datenbank- oder Serverrechte. Bestehende Identitäten bleiben
unverändert. Er und seine Temp-Tabellen entstehen ausschließlich in der eigenen
markierten Testdatenbank und werden anschließend entfernt.

Das erste positive Profil verwendet die vier öffentlichen EXECUTE-Grants und
Helper-VIEW-DEFINITION; das zweite ergänzt genau Helper-EXECUTE. Directresult
besteht in beiden Profilen, ResultTable im zweiten. Daraus folgt keine Aussage,
dass alle sechs Grants für jeden Pfad notwendig sind. Es werden keine internen
Einstiege freigegeben. Direkte interne USP-/Bridgeaufrufe sowie öffentliche
Aufrufe ohne beziehungsweise nach Widerruf des jeweiligen EXECUTE-Grants werden
mit SQL229 abgewiesen. Breite Rechte und privilegierte Rollen werden geprüft.

Die [Fixture](../../Tests/Release/Runtime/JsonConstructors.CallerRights.sql)
verlangt feste binäre Array-/Object-/Gruppenwerte, einfache und gruppierte
ResultTable-Spalten mit exakten Typen, Nullability und Collation sowie relative
Spaltenreihenfolge. Der neutrale Sitzungszustand wird ohne Katalogzugriff
erfasst und anschließend durch einen eigenen Clientaufruf erneut geprüft.

## Methode und Bereinigung

Der [Treiber](../../Tests/Release/Invoke-JsonConstructorsCallerLab.ps1) verwendet
kanonische Exports der unveränderten Module ResultTable1.0.0, JsonCore1.0.0 und
Constructors1.3.0. Zwei registrierte bekannte SAFE-DLLs wurden unverändert
wiederverwendet. Quelle der korrigierten Methode ist
[`2ef5fb41`](https://github.com/gecompat/SQL_Server_Toolbelt/commit/2ef5fb41d92ed4a420dc0f544dd43fca00bcf060).
Die privaten Runsets binden tatsächliche Arbeitsbaum-/Export-/Artefaktbytes;
die Gitreferenz ersetzt weder diese Bytepins noch die originalen Ausführungsjournale.

Die Functional-Verbindung übernimmt Verschlüsselung und den expliziten
Trustwert des schema-validierten, exakt ausgewählten Labvertrags. Jeder
Abschlussaudit verwendet einen neuen Prozess und eine neue Verbindung und bindet
den SHA256 des unveränderten finalen Originaljournals. Eigene DB-Abwesenheit,
Wiederherstellung des protokollierten Trust-/CLR-Konfigurationsumfangs und
Methodenpins wurden bestätigt. Keine Sicherheitsabschwächung oder Labänderung;
eigene notwendige CLR-/Truständerungen folgen den bestehenden engen Regeln.

## Erhaltene Fehler und Grenzen

Die gemeinsame Welle verbrauchte zwölf Ziel-/Auditaufrufe und zwölf
Datenbankreservierungen innerhalb der unveränderten 45-Minutenfrist. Tatsächlich
wurden neun eigene Datenbanken angelegt und entfernt. Alle sechs frischen
Abschlussaudits sind vollständig; ein grüner Audit macht einen fehlgeschlagenen
Gesamtlauf nicht erfolgreich.

- SQL2019 CL150 blieb FAILED_CLEANED: Das Testorakel verlangte fälschlich
  dichte column_id-Werte nach In-place-ALTER. Die Korrektur prüft benannte,
  typisierte Spalten und relative Reihenfolge, ohne Produktänderung.
- SQL2022 CL150 und CL160 blieben FAILED_CLEANED: Die abschließende Fixturebilanz
  vermischte Katalogzugriff und XACT_STATE. Der gezielte CL160-Befund zeigte
  zwölf positive und zwölf negative Fälle, aber XACT_STATE1 bei TranCount0.
  Erst die getrennte Sitzungsbeobachtung der korrigierten Methode bestand
  anschließend auf den drei noch nicht versuchten SQL2025-Kontexten.

Für SQL2019/2022 gibt es daher keinen bestandenen neuen Caller-Gesamtfall und
keinen rückwirkenden PASS. Historische fachliche Constructor-Matrizen behalten
ihren ursprünglichen Scope. Die geschlossenen alten und neuen Budgets werden
nicht erneuert. Zehn Offlinegegenproben sichern Authority, Frist, Zielauswahl,
Bytepins und die beiden konkreten Testadapterkorrekturen ab.

Aggregate, direkte Clientmetadaten, Netzwerklogins, tatsächliche CrossDB-
Identitäten, andere Owner, Produktionskapazität, authentifiziertes TLS und
vollständige Modul-/Releaseabnahme sind nicht Bestandteil dieses Nachweises.
Modulstatus bleibt teilweise validiert und unveröffentlicht. Private Originale
bleiben unter `.runtime`; keine Veröffentlichung oder Tags.
