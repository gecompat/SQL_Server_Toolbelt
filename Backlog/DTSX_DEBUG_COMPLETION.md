# DTSX-Debug aus Paketmetadaten vervollständigen

## Auftrag und Ziel

Am 2026-11-20 beauftragte der Benutzer nach Besprechung der konkreten
Connection-, Lookup-, Quellprojektions-, UNION- und Flatfile-Befunde die
Fertigstellung der bestehenden DTSX-Debug-Erzeugung. Private Originalpakete
bleiben ausschließlich lokale Abnahmeinputs. Öffentliche Tests verwenden
synthetische, unabhängig konstruierte Strukturen.

Ziel ist vollständiges, syntaktisch geprüftes Debug-SQL für übersetzbare
Datenflüsse mit eindeutigem Eingabevertrag. Paketbasierte Ergebnisse bleiben
unverifizierte Entwürfe, keine behauptete SSIS-Runtime-Parität oder Prüfung
der realen Datenbank. Paket oder SQL werden beim Erzeugen nicht ausgeführt.

## Lösungsplan und Alternativen

1. `ConnectionString` und `InitialCatalog` aus lokal auflösbaren Ausdrücken
   zusammensetzen. Startwerte, Defaults, Scope, Zyklus-/Typgrenzen und mehrere
   Server eindeutig behandeln. Sensitive oder echte fehlende Laufzeitwerte
   niemals durch zufällige Defaults ersetzen. Alternative: explizite bestehende
   CatalogBindings; der Komfortweg soll diese manuelle Doppelpflege vermeiden.
2. Den Paketvertrag der Abfrageausgabe von einer Prüfung zugrunde liegender
   Datenbankobjekte trennen. Lookup-Referenzmetadaten, SQL-Aliase, TVF und Joins
   auswerten, ohne fehlende Basistabellenspalten zu erfinden. Bestehende
   AST-/Nur-Lesen-Grenzen und optionalen strikten Katalogweg erhalten.
3. Beim UNION leere unverbundene Reserveeingänge auslassen. Unverbundene
   Eingänge mit tatsächlich gemappten Spalten, mehrdeutige Lineage, Zyklen
   und fehlerhafte Typzuordnungen weiterhin ablehnen.
4. Benutzerpräzisierung: Flatfiles ausdrücklich als lokale Dummy-SELECTs mit
   den aus DTSX bekannten Spaltentypen annehmen. Keine Datei lesen. Diese
   Annahme kennzeichnen und bearbeitbare Beispielwerte ermöglichen.
5. Danach sämtliche privaten Ausgangspakete mit demselben gebauten Kern erneut
   prüfen. Weitere konkrete Befunde an ihren tatsächlichen Inputs untersuchen.
   Teilpfade und unvollständige Ausgaben niemals als Gesamt-PASS darstellen.

## Abnahme und Grenzen

- Synthetische positive und negative Gegenproben für jede geänderte Semantik;
  bestehende Framework-/AST-/Vertragsprüfungen am eingefrorenen Kandidaten.
- Reproduzierbarer aktueller CLR-Build, SQL-Syntaxprüfung der erzeugten Artefakte,
  klare Zuordnung von Defaults, erforderlichen Eingaben und offenen Quellabhängigkeiten.
- Keine realen Paketnamen, SQL-Texte, Verbindungsdaten oder Runtimeoutputs in Git.
- Bestehende historische Nachweise unverändert; geänderte Produktinputs erhalten
  neue aktuelle Evidenz. Keine pauschale Vollqualifikation aus Parsererfolg.
- Ein Verantwortlicher, ein kohärenter PR, keine Agentendelegation. Gemeinsamer
  Implementierungs-/Offline-Prüfrahmen: 90 Minuten ab Beginn dieser Welle;
  alter SQL-/Auditverbrauch bleibt geschlossen. Keine neuen nativen Zielaufrufe
  oder Infrastrukturänderungen in diesem Rahmen. Am sicheren Checkpoint offene
  notwendige Schritte und tatsächlich verbrauchte Grenzen dokumentieren.
- Regulärer Merge nur mit tatsächlicher grüner Head-CI, danach Main-CI prüfen,
  eigenen Branch bereinigen, private Nachweise erhalten. Keine Veröffentlichung.

Zusätzliche Freigabe: Der Benutzer ergänzte den privaten Korpus auf 35 Pakete
und konkretisierte Prozedurquellen/-Lookups: Resultsetschema aus DTSX verwenden,
vorherigen Datenfluss und Prozedurergebnisse über lokale #-Tabellen
materialisieren, keine globalen ##-Tabellen. Der Generator führt diese
Aufrufe nicht selbst aus. Der [Anwendervertrag](../Modules/toolbelt.tsql.ssis-debug/Documentation/LocalCteDebug.md)
erklärt Annahmen, Grenzen und tatsächlichen Ausführungszeitpunkt.

Status 2026-11-20: implementiert in [PR #629](https://github.com/gecompat/SQL_Server_Toolbelt/pull/629).
Reproduzierbarer CLR-Build, synthetische Quellen-/Prozedur-/Lookup-/Flatfile-
Gegenproben und lokale Paket-Erzeugung sind ausgeführt. Der vollständige
Frameworkvertrag und die tatsächliche Head-/Main-CI sind Abschlussgates des PR.
Kein nativer SQL-Zielaufruf und keine Veröffentlichung in dieser Welle.
Private Ausgangspakete, erzeugte Skripte, Fehlversuche und Originalnachweise
bleiben lokal erhalten; historische Qualifikationen werden nicht aufgewertet.
Die Anleitung erklärt erforderliche Startwerte, Ausführungsabhängigkeiten und
Grenzen der angenommenen Daten. Dieser Paketentwurf ist keine Gesamtqualifikation
der realen Quellsysteme oder der SSIS-Runtime.
