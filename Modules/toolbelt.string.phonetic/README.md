# toolbelt.string.phonetic


## Aktuelle Installation

Den [modulbezogenen Buildplan](Deployment/README.md) oder den
[gemeinsamen Installer](../../Deployment/ONE-CALL-INSTALL.md) verwenden.
Beide führen auf denselben markerfreien create-only-Kern: normale SQL-Datei,
kein SQLCMD-Modus, keine Deployment-Extended-Properties. Der aktuelle SQL-Assemblyname ist `tlblt_String_Phonetic`.
Die bisherigen Versions-/Lifecycleangaben weiter unten und ihre damaligen
Assemblynamen bleiben an die ursprünglichen Artefakte gebunden. Sie sind kein
aktueller Upgrade-/Uninstallweg und keine neue native Installerabnahme.


Aktuelle [CLR-Callerrechte](../../Releases/1.0.0/CLR-STRING-CALLER-QUALIFICATION.md): isolierte SELECT-Profile auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Neue Testtreiber/Fixtures sind entwickelt; Produktimplementierung und Modulstatus bleiben unverändert. Weitere API-/Client-/Lifecycle- und Ressourcengates sind separat.

Version 1.0.0, unreleased und teilweise validiert. Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Der unten dokumentierte Differentialvergleich deckt einen festen Korpus ab; vollständiger Scannervergleich, vollständige Fachzielmatrix, weitere Rechtekontexte und aktuelle Head-CI bleiben getrennte Gates. Die oben verlinkte Callerqualifikation belegt ausschließlich ihren isolierten SELECT-Scope.
Die [Testdokumentation](Tests/README.md) trennt Offline- und private native
Teilnachweise von der noch offenen vollständigen Qualifikation.

Zwei öffentliche inline TVFs verwenden eine eigene SAFE-Assembly:
[TVF_ColognePhonetic](Documentation/TVF_ColognePhonetic.md) und
[TVF_DoubleMetaphone](Documentation/TVF_DoubleMetaphone.md). Jede Auswertung
liefert eager genau eine Zeile. NULL ist erfolgreich mit NULL-Codes; leer ergibt
leere Codes. Fehler 1/2/3 bedeuten ungültiges UTF16/Quote/nicht unterstütztes
Alphabet und liefern ausschließlich NULL-Codes. Technische Fehler werden nicht
als Fachresultat kaschiert.

Die vollständigen Scanner sind markierte C#-Ports von Apache Commons Codec
1.18.0. Es gibt keinen Double-Metaphone-Vierzeichen-Clamp. Das alternative
terminale J-Leerzeichen bleibt Teil des Codes. [Herkunft, Änderungen und
Lizenz](ThirdParty/ApacheCommonsCodec/README.md) sowie der
[kanonische Vertrag](../../Documentation/Architecture/PHONETIC_CONTRACT.md)
enthalten die genauen Alphabete, Transformationen und Prioritäten.

## Maschinenlesbare Objektverträge

- [Kölner Phonetik](../../Metadata/UsageSkills/toolbelt_string/TVF_ColognePhonetic.md)
- [Double Metaphone](../../Metadata/UsageSkills/toolbelt_string/TVF_DoubleMetaphone.md)

Jeder öffentliche Einstieg und sein interner CLR-Core besitzen einen eigenen
kanonischen Skill, identisch in ihrer DDL. Die Skills beschreiben den Unterschied
zwischen öffentlichen `varchar(max)`-Codes und internem `nvarchar(max)`-Transport,
NULL, leerem Code und Fachfehler sowie die festen Alphabet-/Größengrenzen.
Eine Skillbeschreibung ist kein neuer nativer Funktions- oder Gesamtnachweis.
Zur vollständigen noch offenen SQL-Katalogintegration siehe
[Usage-Skills](../../Metadata/UsageSkills/README.md).

## Installation und Abhängigkeiten

Den [gemeinsamen SQL-Installer](../../Scripts/Install/README.md) verwenden:
normale SQL-Datei, kein SQLCMD-Modus und keine Deploymentmarker. Lokal und zentral
steht derselbe Funktionssatz bereit. Der Hashweg und ausdrücklich gewählte Wege
mit bereits vorhandenem Datenbank-Trust sind getrennte Optionen; der Installer
aktiviert `TRUSTWORTHY` nicht und erteilt keine Rechte.

Ausgewählte Laufzeitnachweise liegen für Linux2019/latest CL150 und
Windows2025/exakt CU8 CL170 vor; die übrige Zielmatrix bleibt offen.
Keine Abhängigkeit von der Distanz-/Jaro-Assembly.

Binaryherkunft, exakte Lieferbytes und notwendige vorhandene Rechte vor der
Installation prüfen; Build-only ist keine Qualifikation. Bestehende Definitionen
bleiben im create-only-Weg erhalten, ein automatischer Upgrade-/Uninstallpfad ist
nicht vorgesehen. Frühere SQLCMD-/Marker-/AppLock-/Uninstallparameter und ihre
Nachweise gehören ausschließlich zu den ursprünglichen Lieferungen. Ein
fachlicher SELECT benötigt keine zusätzliche Runtime-Assemblyhashsicht oder
datenbankweite Metadatensicht.

## Tests und Grenzen

[Matrix](Tests/PHONETIC_TEST_MATRIX.md), [Ausführung](Tests/README.md) und
[synthetische Beispiele](Examples/Phonetic.sql). Buildgenerator und Framework-
Kandidatenkonsum benutzen den vorhandenen bounded Prozesshelfer. Die
Eingabequote ist 4096 rohe UTF16-Einheiten; transformiert maximal 8192,
Code maximal 16384 je Seite/32768 zusammen. Keine Kürzung, keine optionalen
Normalisierungen, keine Heap-/CPU-/Wallclock-/Produktionskapazitätszusage.
## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-09`
- Nachweis: `local: Tests/Differential/run-differential-phonetic.ps1 mit DifferentialCorpus.tsv`
- Scope: Bereits dokumentierter einmaliger Offlinevergleich unter Windows/.NET Framework 4.8 mit explizitem JDK27 und unveränderten Apache-Commons-Codec-1.18.0-Quellen: 36 feste Fälle, davon 20 Cologne und 16 Double Metaphone, stimmen in vollständigen Primary-/Alternatebytes überein. Vier Ergänzungen HCL/ACL/-CR/ACR liefern 45/085/47/087; die 32 bisherigen Fälle bleiben unverändert. Vorhandene Assembly mit belegter Herkunft aus fünf unveränderten aktuellen C#-Quellen wiederverwendet, kein neuer Produktbuild. Zwei Compiler und zwei Consumer erfolgreich. stderr nur decodiert leer; kein Datei-Cleanup-PASS. Keine vollständige Scanner-, SQL-, SAFE-, Zielmatrix-, Minimalrechte- oder Releasequalifikation.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
