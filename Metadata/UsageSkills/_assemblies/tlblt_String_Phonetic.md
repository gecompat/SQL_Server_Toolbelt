---
name: "toolbelt-assembly-tlblt-string-phonetic"
description: "Technischer CLR-Container für begrenzte Phonetikverfahren."
skill_format_version: "1.0"
module_id: "toolbelt.string.phonetic"
schema_name: ""
object_name: "tlblt_String_Phonetic"
object_type: "ASSEMBLY"
database_role: "toolbelt"
is_internal: true
parameters: []
source_paths: ["Modules/toolbelt.string.phonetic/module.yaml", "Scripts/Install/New-SimpleCommonInstall.py"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_string.TVF_ColognePhonetic", "toolbelt_string.TVF_DoubleMetaphone"]
---

# tlblt_String_Phonetic

## Zweck und Einsatzfälle

Technischer CLR-Container für begrenzte Phonetikverfahren. Internes Deploymentobjekt; Anwendungen verwenden die öffentlichen SQL-Einstiege: `toolbelt_string.TVF_ColognePhonetic`, `toolbelt_string.TVF_DoubleMetaphone`.

## Voraussetzungen

Unterstützte SQL-Versionen laut aktueller Moduldeklaration: 2019, 2022, 2025. SQL-CLR-Plattform: Windows und Linux gemäß Modulprofil. Für spätere CLR-Ausführung muss CLR bereits aktiviert sein. Die Assembly wird ausschließlich aus geprüften, quellgebundenen Releasebytes und in ihrer benötigten Abhängigkeitsclosure installiert. Deklariertes PERMISSION_SET: SAFE. Der gemeinsame Installer wählt exakten Hashtrust oder bereits vorhandenen geeigneten Datenbanktrust; er aktiviert TRUSTWORTHY nicht und deaktiviert Strict Security nicht.

## Parameter und Zugriff

Keine SQL-Aufrufparameter und kein eigenständiger EXEC-Aufruf. Der SQL-Assemblyname lautet `tlblt_String_Phonetic`; SQL-Assemblies besitzen kein Schema. Der Verzeichnisname `_assemblies` ist nur die Ablage der Skillquelle. Assemblyname, Managed-Klassen-/Methodennamen und Dateiname sind getrennte Identitäten. Für Fachaufrufe die oben genannten öffentlichen Objekt-Skills lesen.

## Ergebnisse

Die Assembly selbst liefert kein Resultset. Ergebnisse, Datentypen und Größen-/Statusgrenzen gehören zu den öffentlichen SQL-Einstiegen. Eine erfolgreiche CREATE-Operation ist keine Prüfung aller Funktionen oder Verbraucher.

## Aufrufbeispiele

```sql
-- Optionaler Metadatenblick, kein Fachaufruf und kein Installationsnachweis:
SELECT name,permission_set_desc
FROM sys.assemblies
WHERE name=N'tlblt_String_Phonetic';
-- Für den eigentlichen Aufruf den Skill eines öffentlichen Einstiegspunkts lesen.
```

## Rechte

Installation benötigt die von der Engine für CREATE ASSEMBLY und den gewählten Trustweg geforderten vorhandenen Rechte. Die Ausgabe einer Skillbeschreibung gewährt keine solchen Rechte. SAFE ist bei aktiver CLR Strict Security allein kein Autorisierungsnachweis. Für Fachaufrufe gelten separat die jeweiligen Objekt-/Daten-/Dateirechte; kein automatisches GRANT oder EXECUTE AS durch diese Beschreibung. Metadatenzeilen sind von vorhandener Sichtbarkeit abhängig.

## Ressourcenbedarf

Das Assemblybinary wird einmal als Datenbankobjekt installiert; SQL-CLR-Laden und Fachaufrufe können zusätzlichen Speicher und CPU benötigen. Dateigröße, Hash und Abhängigkeiten sind an das konkrete Liefermanifest gebunden und werden hier nicht als feste Runtimewerte behauptet. Keine Laufzeit- oder Kapazitätsgarantie aus dem Containernamen.

## Nebenwirkungen

Die Beschreibung führt nichts aus. CREATE ASSEMBLY legt ein Datenbankobjekt an; der ausdrücklich gewählte Hashweg kann einen exakten serverweiten Trusteintrag hinzufügen. Bestehende Assemblies werden im create-only-Weg weder ersetzt noch entfernt. Fachliche Nebenwirkungen entstehen nur durch spätere Aufrufe der jeweiligen Objekte; insbesondere Dateisystemzugriffe besitzen einen eigenen Autorisierungsvertrag.

## Fehlerbehandlung

Fehlende CLR-/Trust-/CREATE-Rechte, nicht unterstützte Plattformen, fehlende Abhängigkeiten oder abweichende geprüfte Lieferbytes bleiben Installations-/Enginefehler. Kein automatischer Wechsel des Trustwegs, kein Nachladen fremder Binaries, kein Abschalten von Sicherheitsoptionen und kein Retry durch den Skill.

## Aussagegrenzen

Interner Container, keine direkte fachliche API. Das tlblt-Präfix trennt SQL-Assemblynamen von fremden Installationen; es ist keine pauschale Garantie für beliebige Managed-Abhängigkeitskombinationen. Ein Katalogeintrag belegt weder Installation, qualifizierten Runtimeumfang noch ausreichende Rechte. Historische Modulnachweise gelten ausschließlich für ihre ursprünglichen Bindungen; die technischen Metadaten qualifizieren keine neue Gesamtinstallation.
