# SQL-Objektreferenz

## Einzelne SQL-Objekte nachschlagen

Suche im [API-Katalog](API_CATALOG.md) nach dem vollständigen Objektnamen.
Wenn der Name noch nicht bekannt ist, beginne mit der
[Auswahl nach Aufgabe](../ChooseFunctions.md). Die
[durchsuchbare HTML-Ansicht](API_CATALOG.html) kann nach dem Entpacken direkt
im Browser geöffnet werden. In der GitHub-Dateiansicht eignet sich der
Markdown-Katalog.

Öffne im Suchergebnis unter „Vertrag und Quelle“ die Markdown-Datei mit dem
Objektnamen. Dort stehen Zweck, Einsatzbedingungen, Parameter, Resultate,
Fehler, Nebenwirkungen und Grenzen. Eine daneben aufgeführte `.sql`-Datei
enthält die Implementierung. Maßgeblich für die Benutzung ist der Objektvertrag.

## Beispiele finden

Der [Beispielkatalog](API_CATALOG.md) nennt SQL-Typ, Default, Richtung und
Voraussetzungen der Parameter. Die [SQL-Beispielsammlung](API_EXAMPLES.sql)
enthält dieselben Aufrufe zur Einzelauswahl. Wähle die Datenbank zuvor selbst
und richte die auf der Objektseite genannten Testdaten, Dateiroots oder Handler
ein. Führe nur das benötigte Beispiel aus, insbesondere bei schreibenden Aufrufen.

Vergleiche das Ergebnis mit der Objektseite. Je nach Schnittstelle stehen
`NULL`, eine leere Ergebnismenge, eine Statusspalte und eine SQL-Ausnahme für
unterschiedliche Fälle. Abfrageergebnisse haben ohne zugesagte Reihenfolge
keine feste Sortierung.

## Hilfe in SQL abrufen

Die [Usage-Skill-Sicht](../../Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ObjectUsageSkills.md)
liefert Kurzbeschreibung und vollständigen Markdown-Vertrag. Prozeduren
bieten zusätzlich `@Hilfe=1`. Bei erforderlichen Signaturparametern nennt
die Objektseite die Werte oder Platzhalter für den Hilfeaufruf. Die Sicht
beschreibt bekannte Objekte des Builds. Ob ein Objekt im installierten Profil
vorhanden ist und aufgerufen werden darf, hängt von Installation und Rechten ab.

## Den Implementierungsweg verstehen

Die Objektseiten erläutern die für das Ergebnis maßgeblichen Regeln. Wer
beispielsweise eine konkrete Vergleichs- oder Parserentscheidung nachvollziehen
möchte, findet zusätzliche Details in den
[technischen Lösungswegen](IMPLEMENTATION_GUIDE.md).

<a id="quellen-und-pflege"></a>
[Katalogquellen und Pflege](MAINTENANCE.md)
