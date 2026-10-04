# toolbelt.string.phonetic

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
- Datum: `2026-10-04`
- Nachweis: `Begrenzte private Offline-/Nativeadapter mit unabhängiger physischer Prozess- und Bereinigungsprüfung`
- Scope: Am 2026-10-04 bestanden Build, Frameworkprüfungen mit jeweils 223 Assertions unter en-US/de-DE/tr-TR und die eigene IL-/Metadatenprüfung (keine unbekannten eigenen IL-Aufrufe). Begrenzte private Labadapter bestanden auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170. Je Ziel: vier Fixtures einmal lokal, acht echte Clientreader je local/central sowie zwei lokale Größenwitnesses; Clean/Repeat, resolved Consumer-Ablehnungen, zentrale Bestätigung und Uninstall/Repeat mit frischer eigener Bereinigung. Keine Konfigurations-, Rechte- oder Owneränderungen. Java-Differential, unresolved Consumer, weitere Ziele/CL, tatsächliche Minimalrechte, vollständige Lifecyclematrix und aktuelle Head-CI bleiben offen. Teilweise validiert und unveröffentlicht; kein vollständiger Produkt-PASS.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
