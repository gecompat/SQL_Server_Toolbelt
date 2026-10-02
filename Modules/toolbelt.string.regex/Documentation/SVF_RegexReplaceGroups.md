# SVF_RegexReplaceGroups

Die separat freigegebene gruppenbezogene Replace-Funktion verwendet denselben
Capture-Dialekt wie [TVF_RegexCaptures](TVF_RegexCaptures.md). Der vollständige
[Vertrag](../../../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md)
definiert Fehlerpriorität, Capture-Historienprofil und Ressourcenbegrenzung.

`toolbelt_string.SVF_RegexReplaceGroups(@Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max), @Start int = 1, @Occurrence int = 0, @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard') -> nvarchar(max)`

Die T-SQL-Fassade ruft den internen SAFE-CLR-Kern `SVF_RegexReplaceGroupsCore`
mit einheitlicher Unicode-Collationidentität auf. Ein relationaler Ersatzkern
ohne CLR-Skalaraufruf ist für diesen materialisierten Transformationvertrag
nicht verfügbar. Die bisherigen sieben APIs, insbesondere das literale
`SVF_RegexReplace`, behalten ihre Semantik.

- `$1` referenziert eine deklarierte Gruppe; die ganze Ziffernfolge gehört
  zum Ordinal, daher ist `$10` Gruppe 10. Keine führenden Nullen oder Gruppe 0.
- `${Name}` referenziert ausschließlich einen explizit deklarierten Namen,
  ordinal und case-sensitive. Unbekannte Referenzen sind Fehler auch ohne Treffer.
- `$$` erzeugt einen Dollar. Backslash bleibt literal; andere Dollarformen
  sind ungültig.
- Wiederholte Gruppen verwenden die letzte erfolgreiche Capture. Nicht
  beteiligte Gruppen liefern Leertext.

Occurrence=0 ersetzt alle nicht überlappenden Treffer, positive Werte nur
den entsprechenden Treffer; Start ist eine positive 1-basierte UTF-16-Position.
Fehlender Treffer liefert die unveränderte Quelle. Leere Treffer rücken den
Suchcursor um eine UTF-16-Einheit weiter, am Ende höchstens einmal.
NULL-Input, Pattern oder Replacement liefert NULL vor übriger Validierung.

Fehlerpriorität: NULL, Profile, Start/Occurrence, Flags, Größen, Pattern/
Komplexität/Capture-Historie, Replacement, Suche/Output/Budget. Ungültige,
überlaufende oder unbekannte Replacementreferenzen: SQL6522 mit
`TBX_REGEX_INVALID_REPLACEMENT`. Kein Abschneiden oder stilles Aufwerten.

Quelle, Replacement und Output höchstens 1048576/8388608 UTF-16-Einheiten
für standard/large. Pattern8000, Gruppen64, erfolgreiche Capture-Historie
konservativ100000. Die kooperativen Gesamtbudgets500/2000ms und Suchschritte
bis250ms garantieren keinen Durchsatz, Heapverbrauch oder harte Wallclock.

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(
    N'abb',N'(?<First>a)(b)+',N'${First}:$2:$$',DEFAULT,DEFAULT,DEFAULT,DEFAULT);
-- a:b:$
```

SELECT oder REFERENCES auf der Fassade ist erforderlich. CrossDB-
Nutzermappings bleiben ein eigener Prüfkontext. Der reine Memorykern greift
nicht auf Daten, Dateien, Netzwerk oder global veränderliche Caches zu.
