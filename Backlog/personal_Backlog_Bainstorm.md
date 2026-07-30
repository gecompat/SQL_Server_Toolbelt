--- 

> Recherche 2026-07-29 — ChatGPT: Zahlensysteme, Kompression/Archive, Datei-/Verzeichniszugriff, Anonymisierung und Objektklonen wurden gegen Primärquellen und Repository-Grenzen vorgeprüft. Ergebnis: [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md). Es wurde daraus noch keine Implementierungsfreigabe abgeleitet.

# Konvertierung numerischer Ganzzahlen in variables Zahlensystem  

> Überführung 2026-07-30 — Codex: Als `TC-2026-031` formalisiert und nach gemeinsamer Vertragsbesprechung mit Status `ready for development` in `AP-2026-013` aufgenommen. Der Originalgedanke bleibt als Herkunft erhalten.  
  z.B.  
> - Binär (2)
> - Oktal (8)
> - Hexadecimal (16)
> - weitere erfundene Dezimalsystem  
>   (36) 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ

das kann immer über die gleiche Logik laufen, es werden nur mehr oder weniger Zeichen verwendbar


# ZIP

> Überführung 2026-07-30 — Codex: Die Archiv- und Kompressionsideen wurden getrennt als `TC-2026-033` bis `TC-2026-036` formalisiert; Status jeweils `researched`. ZIP-Listing, ZIP-Extraktion/-Erzeugung, Gzip-Adapter und weitere Kompressionsprovider bleiben eigenständige Verträge.
## Untervariante
### ls ZIP    Inhalt der Files/Directories von Zip
### Unzip 
* File 
* String

mit ich glaube 2026 gibt es decompress und compress (oder so ähnlich) - das ist glaube ich auch zip

### unterschiedliche Kompressionsverfahren
* zip
* 7z
* gz
* ...

# Read/Write File

> Überführung 2026-07-30 — Codex: Als `TC-2026-037` formalisiert; Status `researched`. Read/Write, Encoding/BOM, Pfad-Sandbox, Identität und Plattformprovider bleiben vor einer Implementierungsfreigabe offen.
* Binary / nonbinary
* Encoding ANSI, Windows-1252, .... mit/ohne BOM
* ...

# Directory List

> Überführung 2026-07-30 — Codex: Als `TC-2026-038` formalisiert; Status `researched`. Directory Listing bleibt von Dateiinhalt und undokumentierten Extended Procedures getrennt.

# Anonymisierungsfunktionen

> Überführung 2026-07-30 — Codex: In die getrennten Kandidaten `TC-2026-039` bis `TC-2026-043` für Hash-Lookup, Random Range, gesalzene Zeichentranslation, Date Shifting und Geo-Jittering überführt; Status jeweils `researched`. Die formalen Kandidaten verwenden bewusst den präziseren Begriff Pseudonymisierung, soweit keine Irreversibilität belegt ist.
* HashLookup - aus Hashwert wird eine ID von LookupTabelle ermittelt und von dieser Tabelle der Wert genommen.
* random_range
* translate mit Salt
* Case-In/sensitiv
* Date +/- random_range ...
* GEO
* ...

# Clone Object Framework

> Überführung 2026-07-30 — Codex: Als `TC-2026-044` formalisiert; Status `researched`. Der Kandidat trennt zunächst kontrollierte Skripterzeugung von automatischer DDL-Ausführung.
ermöglicht eine Kopie einer z.B. Tabelle mit allen Indizes, CheckConstraints, FK, Trigger, DefaultConstraints, ....
dabei bekommen aber all diese Objekte eindeutige Namen (sofern notwenidg (PK) )
Umbenennungsfunktionen
mit/ohne Identiy
...


 # Excel-File direkt lesen und auswerten

> Überführung 2026-07-30 — Codex: Als XLSX-Reader `TC-2026-045` formalisiert; Status `researched`. ZIP-Container, Open-XML-Semantik und Dateizugriff bleiben getrennte Provider-/Dependency-Fragen.
 durch unzip könnte man Excel Files direkt lesen und auswerten.
 
 # Thema tSQLt.NewConnection

> Überführung 2026-07-30 — Codex: Als providerneutrale Second-Session-Abstraktion `TC-2026-046` formalisiert; Status `researched`. `tSQLt.NewConnection`, SQL CLR, SQL Server Agent, Service Broker und externe Runner sind nur mögliche, getrennt zu prüfende Provider.
 man sollte das m.M. so implementieren, dass man mehrere Wege (Provider) für die "Ochestrierung" wählen kann.
 jede Variante hat ihre eigenen Anwendungsfälle und es stehen auch nicht überall alle Wege zur Verfügung - evtl. vorhandene Architekturvorschriften 
 
 # Regex Funktionen für SQL 2019, 2022

> Überführung 2026-07-30 — Codex: Bereits durch `TC-2026-010` abgedeckt; Status `researched`. Gewünschte Syntaxbreite, RE2-/NET-Semantik, Limits und Provider bleiben vor einer Implementierungsfreigabe offen.
 zu prüfen is, ob die vorhandene SQL2025'er Regexfunktionen die gesamte (gewünschte) Breite abdecken  
Fragestellung: was ist die gewünschte Breite? - welche Funktionalitäten fallen dir ein?  
  

~~ # Powershell am Host ausführen - Ergebnis entgegennehmen~~

Änderungsvermerk 2026-07-29, Codex: Als `TC-2026-025` in den kanonischen Toolbelt-Backlog übernommen; Status `researched`. Beliebige Raw-Script-Ausführung bleibt ausdrücklich außerhalb des freigegebenen Scopes.

~~ # python am Host ausführen - Ergebnis entgegennehmen~~

Änderungsvermerk 2026-07-29, Codex: Als `TC-2026-026` in den kanonischen Toolbelt-Backlog übernommen; Status `researched`. In-database Python und allgemeine Host-Automation werden als getrennte Providerverträge behandelt.

~~ # Rest Calls und Web Requests~~

Änderungsvermerk 2026-07-29, Codex: Als `TC-2026-027` in den kanonischen Toolbelt-Backlog übernommen; Status `researched`. SQL Server 2025 und Compatibility-Provider für 2019/2022 bleiben getrennt.

~~ # KI - Chat~~

Änderungsvermerk 2026-07-29, Codex: Als `TC-2026-028` in den kanonischen Toolbelt-Backlog übernommen; Status `researched`. Embeddings und generative Chat-Aufrufe erhalten keinen gemeinsamen unspezifischen Vertrag.

 
 
 
 
 
