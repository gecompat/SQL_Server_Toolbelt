# Code-Dokumentationsregeln

## Sprache

- Codekommentare und technische Dokumentation sind **deutsch**.
- Etablierte englische Fachbegriffe bleiben englisch.
- SQL-Schlüsselwörter, Produkt-, API-, Datei-, Schema-, Objekt-, Klassen- und Parameternamen bleiben englisch.

## Kommentarstil

- Kommentare erklären **Absicht und Randbedingungen**, nicht jede Zeile.
- Nicht triviale Codeblöcke erklären bei Bedarf:
  - Zweck
  - Voraussetzungen
  - Seiteneffekte
  - Besonderheiten
  - Designgrund
  - Performance-Überlegungen
  - Versionsabhängigkeiten und Plattformgrenzen
  - Besondere Techniken
- Veraltete Kommentare gelten als **Fehler** und sind sofort zu aktualisieren oder zu entfernen.

## Objekt-Header für öffentliche SQL-Objekte

Jedes öffentliche SQL-Objekt erhält einen Header mit folgenden Abschnitten (soweit zutreffend):

```sql
-- =============================================================
-- Objekt:        <Schema.ObjektName>
-- Typ:           <Stored Procedure / TVF / SVF / View>
-- Zweck:         <Kurze Beschreibung>
-- Vertrag:       <Verweis auf USP_CONTRACT.md oder analog>
-- Parameter:     <Parameterliste mit Typen und Defaults>
-- Resultset:     <Spaltenbeschreibung>
-- Dependencies:  <Abhängige Objekte oder Module>
-- Rechte:        <Erforderliche Berechtigungen>
-- Versionen:     <SQL Server 2019+, Windows/Linux>
-- Fehlerverhalten: <Wie werden Fehler behandelt?>
-- Performance:   <Relevante Performance-Überlegungen>
-- Einschränkungen: <Bekannte Grenzen>
-- Erstellt:      <Datum>
-- Geändert:      <Datum>
-- =============================================================
```

Interne Hilfsobjekte erhalten einen vereinfachten Header; vollständige Dokumentation ist dennoch erforderlich.

## Stil

- Sachlich, präzise, professionell, vollständig.
- Kein Marketing, keine Floskeln, keine erfundenen Fakten, keine erfundenen Quellen, keine erfundenen Testergebnisse.
- Keine künstlichen Übersetzungen.
- Aussagen nach Möglichkeit kennzeichnen als:
  - dokumentiert
  - empirisch
  - Schlussfolgerung
  - Planung
  - Vermutung
  - offen

## Hauptsprache eines Dokuments

Ein Dokument hat grundsätzlich eine Hauptsprache. Ausnahmen:
- Der bilinguale README-Lizenzblock (Deutsch/Englisch)
- Die mehrsprachige `LICENSE.md`
