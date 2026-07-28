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

## Dokumentationskopplung

Kommentare, öffentliche Dokumentation, Help-Resultset, Beispiele und Tests müssen denselben Vertrag abbilden. Eine Änderung an Parametern, Resultspalten, Defaults oder Semantik aktualisiert alle gekoppelten Artefakte im selben Pull Request.

## Stil

- sachlich, präzise, professionell und vollständig;
- keine Marketing-Sprache oder Floskeln;
- keine erfundenen Fakten, Quellen oder Testergebnisse;
- Unsicherheiten als dokumentiert, empirisch, Schlussfolgerung, Planung, Vermutung oder offen kennzeichnen;
- ein Dokument besitzt grundsätzlich eine Hauptsprache, ausgenommen Lizenzfassungen.
