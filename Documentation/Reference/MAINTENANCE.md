# SQL-Objektkatalog pflegen

## Quellen und Pflege

- `Modules/*/module.yaml` bestimmt Umfang, Sichtbarkeit, Typ und Modulversion.
- `Modules/*/Source/*.sql` liefert Parameterreihenfolge, SQL-Typen, Defaults
  und OUTPUT. Auch dynamisch deklarierte CLR-Aggregate werden berücksichtigt.
- Die [kanonischen Usage-Skills](../../Metadata/UsageSkills/README.md) liefern
  Kurzbeschreibungen, Parametererklärungen, synthetische Beispiele und
  Voraussetzungen für den Beispielkatalog. Dieselben Parametererklärungen
  erscheinen in den generierten `API_PARAMETERS`-Blöcken der Objektseiten.
- Bei öffentlichen T-SQL-Prozeduren bezieht auch die Standardhilfe ihre
  Parameterbeschreibungen, fachliche Pflicht und NULL-Regeln aus dem Usage-Skill.
  [usp_help.json](usp_help.json) liefert die übrigen strukturierten Help-Zeilen.
  [api_examples.json](api_examples.json) bleibt Quelle für historische
  Projektionen und den separaten SSIS-Standardhilfe-Generator.
- [`generate_parameter_help.py`](../../Scripts/Documentation/generate_parameter_help.py)
  schreibt die markierten `API_PARAMETER_HELP`-Blöcke. Der
  [SSIS-Generator](../../Modules/toolbelt.tsql.ssis-debug/Scripts/New-ContractSources.py)
  erzeugt die SSIS-Standardhilfe und ergänzt die vollständigen kanonischen
  Skilltexte in Fassade und CLR-Hilfe.
- Modullokale Objektseiten bleiben die verbindlichen fachlichen Verträge,
  insbesondere für zulässige Parameterwerte, Resultsets und Grenzen.

Der Katalog ersetzt keine Objektseite und behauptet keine Runtime-Validierung.
Er wird ausschließlich offline aus Repositoryquellen erzeugt. Zugangsdaten,
installierte SQL-Kataloge und reale Ausgaben werden nicht eingelesen.

Bei einer neuen oder entfernten öffentlichen API muss der zugehörige
kanonische Skill mitgepflegt werden. Jeder Source-Parameter benötigt eine passende Erklärung;
neue oder entfernte Parameter stoppen die Prüfung bis zur redaktionellen Pflege.
Bei Vertragsänderungen sind Beschreibung, Beispiele und
Voraussetzungen fachlich zu prüfen; der Generator kann diese semantische
Prüfung nicht übernehmen. Die drei Katalogausgabedateien und die markierten
Parametertabellen nicht direkt bearbeiten; übrige Objektabschnitte bleiben manuell.

SQL-Typbindung erfolgt vor der Objektvalidierung. Beispielsweise kann SQL Server
einen numerischen Nichtnullwert beim Binden an `bit` bereits in 1 umwandeln;
eine begrenzte Textparameterlänge ist keine nachträgliche Trunkierungsprüfung
im Objekt. `nvarchar(n)` zählt UTF-16-Einheiten, `varchar(n)` Bytes, nicht
pauschal sichtbare Zeichen. Weiterführend:
[bit-Konvertierung](https://learn.microsoft.com/en-us/sql/t-sql/data-types/bit-transact-sql),
[Unicode-Längen](https://learn.microsoft.com/en-us/sql/t-sql/data-types/nchar-and-nvarchar-transact-sql),
[varchar-Längen](https://learn.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql).

Vom Repository-Root aus generieren und anschließend prüfen:

```bash
python Scripts/Documentation/generate_parameter_help.py --write
python Modules/toolbelt.tsql.ssis-debug/Scripts/New-ContractSources.py
python Tests/Documentation/generate_api_catalog.py --write
python Tests/Documentation/generate_api_catalog.py
python Tests/Documentation/test_api_catalog.py
python Tests/Documentation/test_parameter_help.py
```

Nach einer Änderung der SSIS-Hilfekonstante muss die DLL neu gebaut werden;
eine reine SQL-Neuerzeugung genügt dort nicht. Der
[Nachweis der ursprünglichen Help-Paketierung](../../Releases/1.0.0/PARAMETER-HELP.md#erzeugung-und-nachweisgrenze)
erklärt Paketkopplung und Nachweisgrenzen. Der Generator castet lange Unicode-
Texte bereits beim ersten Literal auf `nvarchar(max)`: Ein Cast erst nach der
Verkettung würde eine vorherige 4000-Codeeinheiten-Trunkierung nicht rückgängig
machen. Zur Laufzeit werden die statischen Zeilen ausgegeben, keine externen
Dokumentationsdateien gelesen.

Die [Prüfmatrix der vollständigen Parameterhilfe](../../Tests/Release/ParameterHelp.md)
erklärt die tatsächlichen Installations- und Help-Laufzeittests sowie deren
Grenzen. Damit lassen sich Referenztext, Generator, installierter Hilfetext
und zugehöriger Nachweis durchgehend verfolgen.

Die Ausgabe ist deterministisch. Die Read-only-Prüfung erkennt fehlende oder
veraltete API-Einträge, unbekannte öffentliche Typen, mehrdeutige Quellen und
abweichende generierte Dateien. Source-/Vertragsfingerprints erkennen auch
Änderungen ohne sichtbare Signaturänderung. LF und CRLF werden gleich behandelt.
Die bestehende Dokumentations-CI führt Prüfung und Regressionstests über das
Impact-Paket `public_api_catalog` in der Repo-Map aus; ein Vollaudit prüft sie
ebenfalls. Geänderte Quellen und die neu generierten Dateien gemeinsam committen.

Historische Release-Nachweise behalten ihre ursprünglichen Texte und Pins.
Die [begrenzte Parameterprojektion](../../Scripts/Release/HistoricalSources/parameter-contracts-20261030/README.md)
ergänzt dafür den bestehenden historischen Prüfweg. Sie akzeptiert nur die
kanonisch generierte Parametertabelle bei unverändertem übrigen Text.
Quellgeprüfte neue Erklärungen sind dadurch keine neue native Runtimequalifikation.
