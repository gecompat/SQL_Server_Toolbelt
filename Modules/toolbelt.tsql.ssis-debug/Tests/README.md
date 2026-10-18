# SSIS-Debug: Prüfmatrix und Evidenz

Stand 2026-10-17. Alle eingecheckten DTSX-Fixtures sind synthetisch und werden
mit `Fixtures/build_fixtures.py` erzeugt; keine Kundenpakete oder Runtimewerte.

`Framework/Invoke-Contract.ps1` prüft den exakten ScriptDom-Pin und führt
isolierte .NET-Framework-Prozesse mit begrenztem Stack und Watchdog aus.
Profil `Full` umfasst derzeit 21 Kindprozesse: JSON-Grenzen und exakte Werte,
Format 6/8, Vorlagen-Roundtrip, Source/Union/Derived/Lookup/Split/Destination,
CTE-Parsecache, blockierte Komponenten, unzulässige SQL-Statements sowie
Operator-, Struktur-, Kommentar-, Projektions- und Textgrenzen.

Bestanden: 21 Kindprozesse einschließlich gezielter Reviewregressionen zu
Lookup-Dezimalprodukt, Textlängen, SUM/AVG/LEN, Integerpräzedenz,
NULLbarkeit und Zeitpräzision, Erhalt von WHERE-Klauseln, Katalogdrift,
reiner TVF ohne Alias und Unicode-Lookup-Collations. SQL-Vorfilter, JSON,
Paketgröße, XML-Tiefe, Komponenten, Eingaben, Spalten und Pfade haben gezielte
minus-eins/exakt/plus-eins-Orakel. UTF-16, DTD-Ablehnung, doppelte Identitäten,
Sensitive-Redaction und Managed-Source-Aliase 11 bis 17 sind enthalten.
Reproduzierbarer Framework-Build und fokussierte Quellprüfungen bestanden.
Zusätzlich bestehen zwölf isolierte SQL-Syntaxprüfungen
(`Framework/Invoke-Syntax.ps1`) für Source und expandierte Deploy-/Uninstall-
Scripts in SQL150/160/170. Binärliterale wurden hierfür normalisiert.
Das ist keine native SQL- oder SSIS-SDK-Qualifikation.

`Runtime/Invoke-CoreContract.ps1` mit `-Full` bindet `Invoke-V1Cases.ps1`
je DTSX-Format sowie `Invoke-ComponentCases.ps1` einmal im Format 8 ein.
`Invoke-ApiCases.ps1` prüft 14 Parameter und das tatsächliche 13-spaltige
Resultset einschließlich Typen, Längen, NULLbarkeit und ResultTable-Collation.
`Invoke-LifecycleCases.ps1` prüft atomare Kollisions-, Dependency-, Consumer-,
AppLock- und Callertransaktionsablehnung. Der Adapter
`Runtime/Invoke-LabContract.ps1` wählt schema-validierte, bereite Labziele,
verifiziert den reproduzierbaren Release und dessen exakte Dependencypins
und legt ausschließlich eigene synthetische Testdatenbanken an. Er prüft
Deployment/Repeat/Uninstall/Repeat und stellt den eigenen DB-/Trust-/
Konfigurationsscope wieder her. Eine frische Kontrollverbindung bestätigte
anschließend je Ziel den Cleanup. Keine Runtime-Logs oder Labdetails werden
als Repositoryartefakte gespeichert.

Native Qualifikation vom 2026-10-17 am finalen Produktbuild. Aufruf je Version:

```powershell
& Tests/Runtime/Invoke-LabContract.ps1 -Version 2025 -Patch base `
    -Modes local,central -Full -PredecessorRoot $previousReleaseRoot `
    -DatabaseCollation Latin1_General_100_CI_AS_SC_UTF8
```

`previousReleaseRoot` enthält die separat verifizierten Originalartefakte
von Parser 2.0.0 und Table Clone 4.1.0. Kein Hash- oder Markerersatz für ein
echtes Upgrade. Die ursprüngliche Triggerfixture läuft vor, die aktuelle
Triggerfixture nach dem gekoppelten Upgrade auf 2.0.1/4.1.1.

| SQL Server / Datenbankcollation | Modus | Kern | API | Lifecycle | Gesamtstatus |
|---|---|---:|---:|---:|---|
| 2019 / BIN2 | local / central | je 181 | je 61 | je 15 | bestanden |
| 2022 / CS_AS | local / central | je 181 | je 61 | je 15 | bestanden |
| 2025 / CI_AS_SC_UTF8 | local / central | je 181 | je 61 | je 15 | bestanden |

Das sind 1.542 erfolgreiche native Assertions in sechs vollständigen Läufen.
Deployment/Repeat/Uninstall/Repeat, echte Vorgängerupgrades mit Triggerregression
und frische Cleanup-Audits bestanden auf allen drei ausgewählten Zielen.

Vollständige Namen: `Latin1_General_100_BIN2`, `Latin1_General_100_CS_AS`,
`Latin1_General_100_CI_AS_SC_UTF8`. Die Collations wurden risikobasiert auf
die Engineversionen verteilt; keine vollständige kartesische Collationmatrix.
Die nativen Aufrufe verwenden den öffentlichen Standarddialekt SQL150;
die Syntaxprofile SQL150/160/170 sind zusätzlich offline geprüft.

Die fachlichen Orakel umfassen:

- Alle generierten CTE-Stufen ohne Vorbereitung in frischen Sessions,
  genaue Ziel-/Stufenauswahl sowie ausführbare bekannte Vorstufen bei
  unbekanntem Nachfolger; Conversion, gemeinsamer Eingangsstand bei Overwrite
  und Variablenshadowing im näheren Scope.
- Direkte DECLARE-Änderungen: Split-Schwelle erhält Cache und Trefferauswahl;
  relevanter Lookupparameter ändert Fingerprint und tatsächlich gelesene
  Referenzmenge. Cache-Ownership-Manipulation wird abgewiesen.
- Composite-/NULL-/Mehrfachtreffer, eingefrorene beliebige Auswahl,
  explizite Sortierung und Unicode-Textschlüssel mit abweichenden Collations.
- Help zuerst, Resultsetanzahl, alle KeepData-Konstellationen, Dummyspalten,
  Indexerhalt, atomare Fehler sowie gesunde und nicht mehr schreibfähige
  Callertransaktionen und SET-Erhalt.
- Parallele unbestätigte DML als Dirty Read und tatsächliches Warten auf
  Sch-M trotz NOLOCK; Cross-DB-Aufruf und Ausführung aus einer Clientdatenbank.
- Loginloser synthetischer Principal mit den erforderlichen Metadatenrechten
  ohne Quell-SELECT; fehlende Metadatensicht blockiert die Analyse.
- Views/lokale Synonyme, reine TVF und RLS-Funktion sowie ausgewählte
  berechnete Spalte; prozedurale Computed-UDF, versteckter TVF-Tabellenzugriff,
  Remote-Synonyme und schreibende/mehrteilige Quelltexte bleiben blockiert.

Die nativen Regressionen führten zu fünf Korrekturen: vollständiger
SelectStatement-Kontext beim Rendern von QueryExpression (WHERE-Erhalt),
optionaler Alias reiner TVFs, XACT_STATE-Guard vor dem CLR-Aufruf,
präzise Behandlung katalogbelegter interner Computed-Spaltenkanten und
undelimitierte, streng begrenzte COLLATE-Namen. Computed-Spaltenkanten bleiben
im Driftfingerprint; die UDF-/Remote-/Mehrdeutigkeitsprüfungen bleiben aktiv.

Frühere Fehlerläufe sind kein PASS. Ihr eigener Datenbank-/Trust-/
Konfigurationsscope wurde wiederhergestellt und frisch geprüft. Reale
Runtimeausgaben, Hashjournale und Labdetails bleiben außerhalb des Repositories.

Die pauschale TLS-Sperre ist durch die Benutzerklarstellung vom 2026-10-16
ersetzt. `Functional` übernimmt den expliziten booleschen Trustwert des
schema-validierten Vertrags; Encrypt bleibt True, kein automatischer Fallback.
Diese Fachläufe verwenden explizit `TrustServerCertificate=True`.
Authentifizierte TLS-Abnahme bleibt separat `not executed`.

Aktuelle Head-/Integrations-CI und Release bleiben getrennte offene Gates.
SSIS-SDK-/Engineparität, Produktionslast und eine vollständige Kombination
aller Ressourcenmaxima werden nicht behauptet. Linux ist für diese UNSAFE-
Assembly nicht anwendbar. Der Modulstatus bleibt teilweise validiert und
unveröffentlicht.

Verarbeitungsumfang der wiederaufgenommenen Welle: ein Owner, derselbe
unabhängige Reviewer, ein initialer Auftrag und zwei begrenzte Befundfolgeaufträge.
Der zweite Folgeauftrag war eine vorab begrenzte Ausnahme für die neu nativ
erkannte Computed-Dependency-Sicherheitsgrenze. Keine weitere Reviewkette.
Die abschließende COLLATE-Renderkorrektur wurde mit geschlossener Tokenprüfung,
Frameworkregression und nativer Matrix geprüft; keine unabhängige Prüfung
jedes finalen Bytes wird behauptet. Unveränderte Parser245-/Guard60-Nachweise
werden wiederverwendet. Keine neue pauschale Runtime-CI, keine Runtime-Logs
im Repository; Token-/Kostenmessung nicht verfügbar, endlicher Aufgaben-/
Agentenumfang statt behauptetem Geldlimit.

Der PR ergänzt eine begrenzte Windows-CI in
[`ssis-debug-build.yml`](../../../.github/workflows/ssis-debug-build.yml):
ein Job für den zweimaligen aktuellen Providerbuild mit exaktem ScriptDom-Pin,
Full21, fünfzehn Source-/Beispielsyntaxfälle und PowerShell-Adaptersyntax.
`-SourceOnly` verlangt keine privaten Releaseartefakte; der normale Syntaxrunner
prüft einundzwanzig Fälle einschließlich expandierter Deploymentartefakte.
Dieser CI-Build ist kein neues qualifiziertes SQL-Releasebinary; weder
Dependency-/Trustpins noch native Nachweise werden automatisch umgebunden.
Keine zusätzliche Labmatrix oder TLS-Abnahme. Vorhandene Consumer-CI bleibt
wegen Parser-/Dependency- und gemeinsamem Transportcode erforderlich;
keine weitere Reviewdelegation allein für PR-Text oder CI-Auswertung.

Das [vollständige SSMS-Beispiel](../Examples/README.md) verwendet dieselbe
synthetische Format-8-Fixture und die bereits nativ geprüften Demotabellen.
`Invoke-Syntax.ps1` prüft dessen vollständiges SQL zusätzlich mit150/160/170,
ohne OPENROWSET, Demo-DDL oder Generatoraufrufe auszuführen. Diese begrenzte
Erweiterung verwendet den vorhandenen Windowsjob und denselben ScriptDom-Pin;
sie ergänzt drei Parseraufrufe, keine weiteren Jobs, Builds, Frameworkkinder,
SQL-/Labzugriffe oder Reviewagents. Die manuelle SSMS-Bedienung einschließlich
Dateileserechten ist damit kein neuer Runtime-Nachweis.

Die [Installationsanleitung](../Examples/Installation/README.md) ergänzt zwei
SQL-Beispiele für Vorbereitung und Kontrolle. Der bestehende Syntaxrunner
prüft beide mit150/160/170, also sechs zusätzliche Parseraufrufe.
`Tests/Framework/Invoke-InstallationExample.ps1` prüft mit synthetischen Dateien,
Manifesten und einem sqlcmd-Prozessdoppel die Artefakt-/Pinabweisung vor dem
ersten externen Aufruf, den verbindungslosen ValidateOnly-Modus, die fünf Phasen mit
exakten Trustparametern, Arbeitsverzeichnisse, beide expliziten Transportwerte
und den Abbruch an jeder Phase ohne Folgeaufruf oder Transportfallback.
Es werden weder eine echte SQL-Verbindung noch CLR-/Trust-/Datenbankänderungen
ausgeführt. Beide Erweiterungen laufen im vorhandenen Windowsjob; keine
weiteren Jobs, Builds, Framework-CLR-Kinder, Labzugriffe oder Reviewagents.
Die Beispiele und diese Offlineprüfung sind keine neue native Installation
oder Releasequalifikation. Die bestehenden Manifest-/Offline-Exportgates
bleiben erhalten; unbekannte Token-/Kostenverbräuche werden nicht beziffert.

Die PR-Integration besteht zusätzlich den Offline-Gesamtexport mit45 Modulen
(33 Fälle/178 Assertions). Der generische Deployer übernimmt beide SSIS-
Prozedurdefinitionen ausschließlich aus kanonischen Sources, sperrt deren
Überschreibung und prüft den ausdrücklich übergebenen Releasehash. Keine
Ausführung von Exportdateien oder zusätzliche native Gesamtqualifikation.
Die beiden Git-Zeilenendenkanonisierungen am gemeinsamen Guard und an den
generierten Dependencypins wurden durch vollständigen Textvergleich nach
CRLF→LF-Normalisierung als inhaltsgleich geprüft. Die ursprünglichen nativen
Releaseartefakte und deren Trustpins wurden dabei nicht neu erzeugt oder
nachträglich als neuer CI-Binarynachweis ausgewiesen.

## Aktuelle Validierungsevidenz

Neue Buildqualifikation vom 2026-10-18: Der Parserbuild ohne PDB-Debugdaten
ist aus zwei verschiedenen Verzeichnissen bytegleich; alle 57 Methoden-ILs
bleiben unverändert. Neu ausgeführt: 245 Parser-Frameworkfälle, 21 SSIS-
Frameworkfälle, 21 Syntaxprüfungen und 55 Installerassertionen. Der neu
gebundene Satz besteht auf Windows SQL2019/BIN2, SQL2022/CS_AS und
SQL2025/CI_AS_SC_UTF8 jeweils lokal und zentral 181 Kern-, 61 API- und
15 Lifecycleassertionen (1.542 insgesamt), echte Parser-/Table-Clone-Upgrades
einschließlich beider Triggerfixtures und Repeat. Die drei eigenen Journale
enden mit `PASS_CLEANED`. Funktionale Tests verwendeten den expliziten
Trustwert des schema-validierten Labvertrags mit erforderlicher Verschlüsselung;
authentifizierte TLS-, Head-CI- und Releaseabnahme bleiben getrennt.

Die geänderten Binary-/Dependencypins begründen diese neue begrenzte
Qualifikation. Ein vollständiger Releaseaudit, Performance- oder weiterer
Minimalrechtenachweis wird daraus nicht abgeleitet. Die Prüfung erfolgt in
einer kohärenten Welle ohne zusätzliche Reviewagents; erfolgreiche unveränderte
Prüfungen werden nicht erneut ausgeführt. Private Builds-/Nativeprotokolle und
Wiederherstellungsjournale bleiben außerhalb des Repositorys.

Das versionierte [Installationspaket](../InstallPackages/README.md) wird im
bestehenden SSIS-Offlinejob zusätzlich mit
`Tests/Static/validate_install_package.py` geprüft. Der Check liest nur das ZIP:
Dateipfade, vollständige Hashlisten, drei DLLs, beide Deployments, aktuelle
Dependency-Pins, Pflichtskripte und CodeView-/PDB-Freiheit der Toolbelt-Binaries.
Er ergänzt denselben Job ohne weiteren Build, neue Jobs oder SQL-/Labzugriffe.
Die Ausnahme in `.gitignore` gilt nur für die benannte ZIP, deren Prüfsumme
und die zugehörige README. Ungefilterte Laufzeitlogs und private Journale
werden nicht aufgenommen.

Der Benutzer hat am 2026-10-18 die Veröffentlichung mit eingebettetem lokalen
Parser-Buildpfad abgelehnt und stattdessen Pfadbereinigung und neue Qualifikation
freigegeben. Die ursprüngliche Nativevidenz wird nicht auf neue Hashes umgedeutet.

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-18`
- Nachweis: `local: Parser-Releasebuilder in zwei Buildroots; Parser Framework Full; SSIS Releasebuilder, Framework Full, Syntax und InstallationExample; Invoke-LabContract.ps1 -Full -Version 2019/2022/2025 -Modes local,central -PredecessorRoot (je Version)`
- Scope: Neuer freigegebener Buildsatz ohne Parser-PDB-Debugdaten: Parser aus zwei verschiedenen Verzeichnissen bytegleich und alle57 Methoden-ILs unverändert;245 Parser- und21 SSIS-Frameworkfälle,21 SQL-Syntaxfälle sowie55 Installerassertionen bestanden. Windows2019/BIN2,2022/CS_AS und2025/CI_AS_SC_UTF8 jeweils local/central:181 Kern-,61 API- und15 Lifecycleassertionen je Lauf,1542 insgesamt. Echte Parser2.0.0→2.0.1-/TableClone4.1.0→4.1.1-Upgrades mit ursprünglicher/aktueller Triggerfixture und Repeat bestanden; drei eigene Journale PASS_CLEANED. Functional mit explizitem Lab-Trustwert bei erforderlicher Verschlüsselung. Authentifizierte TLS-Abnahme, aktueller Head-CI- und Releaseabschluss separat; kein Produktions- oder vollständiger SDK-Paritätsnachweis.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
