# toolbelt.string.phonetic

Aktuelle [CLR-Callerrechte](../../Releases/1.0.0/CLR-STRING-CALLER-QUALIFICATION.md): isolierte SELECT-Profile auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Neue Testtreiber/Fixtures sind entwickelt; Produktimplementierung und Modulstatus bleiben unverändert. Weitere API-/Client-/Lifecycle- und Ressourcengates sind separat.

Version 1.0.0, unreleased und teilweise validiert. Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Java-Differential, vollständige Zielmatrix, Minimalrechte und aktuelle Head-CI bleiben offen; teilweise validiert und unveröffentlicht.
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

## Installation und Abhängigkeiten

Ausgewählte Laufzeitnachweise liegen für Linux2019/latest CL150 und
Windows2025/exakt CU8 CL170 vor; die übrige Zielmatrix bleibt offen.
Keine Abhängigkeit von der Distanz-/Jaro-Assembly.

1. Das neue Binary getrennt offline qualifizieren und seine vollständigen Bytes
   sowie SHA2-512 binden. Build-only ist keine Qualifikation.
2. Administrativ den exakten Hash separat mit Deployment/Add-TrustedAssembly.sql
   optieren. Bestehende CLR-Konfiguration und strict security bleiben erhalten.
3. SQLCMD Deployment/Deploy.sql aus Deployment ausführen, mit AssemblyBits,
   DeploymentMode=local|central und ExpectedInstalledAssemblyHash (0x nur
   für Abwesenheit, sonst exakter installierter SHA2-512).
4. Für Uninstall dieselbe installierte Hash-Erwartung; bei central zusätzlich
   ConfirmNoExternalConsumers=1 nach tatsächlicher Consumerprüfung.

Lifecycleprüfungen erfolgen vor Mutation und unter eigener Transaktion/AppLock.
Fremde Slots, inkohärente Marker, Hash-/Ownerabweichungen und lokale fremde
Consumer werden abgelehnt. Caller-Transaktionen sind nicht unterstützt.
Lifecycle benötigt bestehende vollständige Metadatensicht; Runtime-SELECT
bekommt keine zusätzliche Hash- oder datenbankweite Sichtbarkeitsanforderung.
Keine Rechte-, Owner-, Konfigurations- oder Truständerung durch Standarddeploy.
Uninstall entfernt keinen Servertrust.

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
