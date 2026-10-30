# Code-Dokumentationsregeln

## Sprache

- Codekommentare und technische Dokumentation sind deutsch.
- Etablierte englische Fachbegriffe bleiben englisch.
- SQL-Schlüsselwörter sowie Datei-, Schema-, Objekt-, Parameter-, Spalten-, Variablen-, Klassen- und Methodennamen bleiben englisch.

## Kommentarstil

Kommentare erklären Absicht und Randbedingungen, nicht lediglich die sichtbare Syntax.

Nicht triviale Codeblöcke dokumentieren bei Bedarf:

- fachlichen Zweck;
- Voraussetzungen;
- Seiteneffekte;
- Besonderheiten und Risiken;
- Designgrund und verworfene naheliegende Alternative;
- Performance-Auswirkungen;
- Versions-, Provider- und Plattformgrenzen;
- Error-, Transaction- oder Cleanup-Verhalten.

Veraltete Kommentare gelten als Fehler und werden zusammen mit der Implementierung aktualisiert oder entfernt.

## Objekt-Header

Jedes öffentliche SQL-Objekt erhält einen Header mit den zutreffenden Feldern:

```sql
-- ============================================================================
-- Objekt:          <Schema.ObjectName>
-- Typ:             <Stored Procedure / TVF / SVF / View>
-- Zweck:           <Fachliche Beschreibung>
-- Vertrag:         <Verbindlicher Standard oder objektspezifische Dokumentation>
-- Parameter:       <Namen, Typen und Defaults>
-- Resultset:       <Spalten oder Rückgabewert>
-- Dependencies:    <Module oder Objekte>
-- Rechte:          <Erforderliche Berechtigungen>
-- Versionen:       <SQL Server 2019/2022/2025>
-- Plattformen:     <Windows/Linux/Provider>
-- Fehlerverhalten: <THROW, Teilfehler und Transaktionszustand>
-- Performance:     <Kosten und Skalierungsgrenzen>
-- Einschränkungen: <Bekannte Grenzen>
-- ============================================================================
```

Interne Hilfsobjekte dürfen einen kürzeren Header verwenden, müssen Zweck, Dependencies, Besonderheiten und Fehlerverhalten aber weiterhin nachvollziehbar dokumentieren.

## Objektreferenz und Beispiele

Für neue sowie fachlich oder algorithmisch geänderte öffentliche SQL-Objekte
ist die eigene Objektseite am aktuellen Code und Vertrag zu prüfen und
mitzupflegen. Sie erklärt Zweck, Parameter und Defaults, Rückgabewert bzw.
Resultspalten, relevante Voraussetzungen, Fehler und Grenzen. Über den
Einstieg in der Root-README und den Objektkatalog muss sie auffindbar sein.

Jede solche Objektseite enthält mindestens einen konkreten synthetischen
Beispielaufruf für die normale Verwendung oder einen direkten Link zu genau
diesem Beispiel in einer gemeinsam gepflegten Referenz. Dabei gilt:

- Benötigte Module, Rechte, Eingabedaten, Tabellen, Dateien, registrierte
  Handler oder vorherige Aufrufe sind erklärt oder gezielt verlinkt. Das
  Beispiel ist unter diesen Voraussetzungen ausführbar. Beliebige IDs oder
  Platzhalter ohne Beschaffungs- oder Vorbereitungsschritt genügen nicht.
- Erwarteter Wert, relevante Ergebnisspalten, Status oder beobachtbare
  Zustandsänderung und deren Bedeutung werden erläutert. Bei veränderlichen
  IDs, Zeitwerten oder Umgebungsinhalten werden belastbare Eigenschaften
  statt erfundener exakter Ausgaben beschrieben. Eine USP-Hilfe ersetzt
  kein Beispiel der normalen Verwendung.
- Zusätzliche NULL-, Leer-, Grenz- oder Fehlerbeispiele werden ausgewählt,
  wenn sie eine nicht offensichtliche Vertragsunterscheidung verständlich
  machen; es wird keine vollständige Testmatrix in die Anleitung kopiert.
- Seiteneffekte, notwendige Vorbereitung und die Bereinigung eigener
  Beispielressourcen sind nachvollziehbar. Beispiele dürfen keine
  unbeabsichtigte Sammelausführung voraussetzen.
- Aus dem Vertrag abgeleitete Ergebniserwartungen sind von tatsächlich
  ausgeführten Nachweisen unterscheidbar. Synthetische Beispiele sind keine
  neue Runtime- oder Plattformqualifikation.

## Technische Implementierungserklärungen

Bei nicht trivialer Funktionalität muss ein technisch interessierter
Softwareentwickler den Weg vom Problem zur implementierten Lösung
nachvollziehen können. Nicht trivial sind insbesondere nicht offensichtliche
Algorithmen, Parser- oder Ownershipzustände, numerische und Unicode-Grenzen,
Providerbesonderheiten sowie technische Entscheidungen, deren Grund sich
nicht bereits aus Signatur oder gewöhnlicher Syntax ergibt.

Die Erklärung behandelt die für das konkrete Verständnis nötigen Punkte:

- technische Grundlage, etwa SQL-/CLR-Mechanismus, Bibliothek, Format,
  Algorithmus oder mathematische Repräsentation;
- wesentliche Verarbeitungsschritte, Zwischenzustände und Bedingungen,
  durch die das Verfahren den dokumentierten Vertrag erfüllt;
- Zweck entscheidender Schleifen, Rekursionen oder mehrfacher Durchläufe:
  welcher Zustand fortgeschrieben wird, wie Fortschritt bzw. Begrenzung
  entsteht und warum die einfachere naheliegende Form nicht genügt;
- relevante Designgründe, Alternativen und Grenzen einschließlich
  nachvollziehbarer Kosten- oder Skalierungsaussagen, soweit sie für die
  Auswahl oder Nutzung der Funktion wichtig sind;
- konkrete zuständige Quelldateien bzw. benannte Methoden oder Codeabschnitte.
  Geeignete technische Primärquellen können Grundlagen vertiefen; ein
  externer Link ersetzt nicht die Erklärung der eigenen Implementierung.

Es sind keine schematischen Pflichtabsätze zu jedem Punkt und keine Erklärung
jeder Schleife oder SQL-Anweisung erforderlich. Syntaxnacherzählung,
allgemeines Entwicklergrundwissen, unbelegte Vorteile und Fülltext erfüllen
die Anforderung nicht. Eine triviale Funktion benötigt weder einen leeren
Technikabschnitt noch einen gesonderten Ausnahmebericht.

Gemeinsame Kerne werden einmal auf einer passenden Modul- oder Vertiefungsseite
erklärt. Betroffene Objektseiten verlinken den konkreten passenden Abschnitt;
ein Wrapper erklärt nur seine zusätzliche Rolle. Als redaktionelle Beispiele
dienen die [technischen Lösungswege](../Reference/IMPLEMENTATION_GUIDE.md),
etwa SemVer-Sortkeys, JSON-Vorprüfungen oder bandbegrenzte Distanzmatrizen.
Erklärungen beziehen sich auf den aktuellen Code; Vermutungen über historische
Designabsichten werden nicht als belegte Begründung ausgegeben.

## Pflege und Abnahme

Eine fachliche oder algorithmische Änderung aktualisiert im selben PR die
betroffenen Beispiele, Ergebnisdeutung und technischen Erklärungen, auch
wenn Parameter und Resultset gleich bleiben. Reine Formatierungs- oder
Schreibfehlerkorrekturen erzwingen keine fachfremde Dokumentationsrevision.
Bestehende Lücken werden im betroffenen Leseweg nachgezogen; daraus entsteht
kein pauschaler Auftrag zur Umschreibung aller Objektseiten.

Der Autor und das im konkreten PR ohnehin erforderliche Review prüfen den
betroffenen Weg von der Root-README über die Objektseite bis zum Beispiel,
Ergebnis und gegebenenfalls Implementierungsweg. Bestehende Link-, Katalog-
und Change-Impact-Prüfungen ergänzen diese fachliche Prüfung. Eine Anzahl
von Beispielen, Überschriften oder Wörtern allein belegt keine Qualität.
Es entstehen keine zusätzliche Reviewkette, feste Textlänge oder automatische
SQL-Ausführung allein wegen einer Dokumentationsänderung; Testauswahl und
Evidenz folgen der [Testregel](TEST_AND_VALIDATION_POLICY.md).

## Dokumentationskopplung

Kommentare, öffentliche Dokumentation, Help-Resultset, Beispiele und Tests müssen denselben Vertrag abbilden. Eine Änderung an Parametern, Resultspalten, Defaults oder Semantik aktualisiert alle gekoppelten Artefakte im selben Pull Request.

Für menschliche Lesewege, Verzeichniszwecke und den getrennten KI-Einstieg
gilt die [Foundation-Dokumentationsrichtlinie](../../.ai/foundation/DOCUMENTATION_POLICY.md).
Der Autor prüft den betroffenen Ablauf einschließlich notwendiger Folgeseiten,
Ergebnisdeutung und Fehlerklärung. Auch reine Verhaltens-, Konfigurations-
oder Generatoränderungen können solche Pfade betreffen. Bestehende Prüfungen
und gezielte Lektüre genügen; grüne Links allein belegen keine Lesbarkeit.
Unabhängige Altlasten werden gemäß ihrer konkreten Planung schrittweise
bearbeitet, statt aus jeder Änderung eine Gesamtrevision abzuleiten.

## Stil

- sachlich, präzise, professionell und vollständig;
- keine Marketing-Sprache oder Floskeln;
- keine erfundenen Fakten, Quellen oder Testergebnisse;
- Unsicherheiten als dokumentiert, empirisch, Schlussfolgerung, Planung, Vermutung oder offen kennzeichnen;
- ein Dokument besitzt grundsätzlich eine Hauptsprache, ausgenommen Lizenzfassungen.
