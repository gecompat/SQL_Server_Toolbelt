# Textpaare: Callerrechte der vorhandenen Batch-USP

Stand 2026-10-25. Die bestehende USP_CompareTextPairs 1.0.0 besteht auf zwölf
Windows-/Linux-Ziel-/CL-Kombinationen lokal und direkt zentral mit genau einem
EXECUTE-Grant. Belegt sind 24 positive Profile, 216 exakte SQL229-Abweisungen
und 1008 feste Zeilenorakel für Werte, NULL, Fehlercodes und Kardinalität.

Ohne Grant und nach REVOKE muss exakt 229 entstehen. Während des positiven
USP-Profils bleiben direkte Aufrufe der drei öffentlichen Vergleichs-TVFs,
der drei internen CLR-Kerne und des ResultTable-Helfers ebenfalls gesperrt.
Breite Rollen-, Schema- und Datenbankrechte werden nicht erteilt. Dies gilt
für den unverändert installierten Ownershipstand; andere Owner sind separat.

## Entwickelter Code und feste Orakel

Neu sind der auf genau eine vorhandene Edit-Distance-DLL begrenzte
[Labtreiber](../../Tests/Release/Invoke-TextPairsCallerLab.ps1), die
[Case-Datei](../../Tests/Release/Runtime/TextPairs.FunctionCases.sql) und die
[Berichtsregression](../../Tests/Release/test_text_pairs_caller_qualification.py).
Composer und isolierter Callercontroller sowie Trust-/Konfigurations-/Ownership-
Helfer bleiben unverändert. Ein separater Treiber erhält die Quellbindung der
früher ausgeführten Treiber. Produkt-SQL, C#, Manifeste und Pakete werden durch
diese Welle nicht verändert. Keine neuen CI-Jobs oder Trigger; die bestehende
Release-Regressionssuite bindet diese kanonische Callerprojektion mit.

Sieben feste signed Ordinals einschließlich bigint-Minimum prüfen Identität,
NULL, Leertext, unpaariges UTF16, Supplementary-Zeichen und Transpositionen.
Levenshtein, OSA und Jaro-Winkler laufen je über typisiertes INSERT EXEC und
eine caller-eigene ResultTable. Die Orakel verwenden feste Werte und Brüche
mit fester Float-Toleranz; ein zweiter Provideraufruf ist kein Ersatz dafür.
Direkte Clientmetadaten, Ausgabereihenfolge und vollständige Grenz-/KeepData-/
Transaktionsfälle sowie sämtliche Fachcodes bleiben eigene Gates.

```powershell
python -B Tests/Release/test_text_pairs_caller_qualification.py
```

## Native Bindung und Bereinigung

Für einen neuen autorisierten Lauf sind ein exklusives Labfenster, ein schema-
validierter Labvertrag und ein privater zwölfteiliger Runset mit
`schema_version=text-pairs-caller-contract/v1` erforderlich. Er bindet genau
Toolbelt_String_EditDistance 1.1.0, beide Exporte, kanonische Komposition,
Pflichtquellen und ausdrücklich ausgewählte Ziele. Kein automatischer Fallback.

```powershell
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-TextPairsCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex
pwsh -NoProfile -NonInteractive -File Tests/Release/Invoke-TextPairsCallerLab.ps1 -RunsetPath $RunsetPath -CaseIndex $CaseIndex -AuditOnly
```

Geprüft wurden SQL Server 2019 CL150, 2022 CL150/160 und 2025 CL150/160/170 auf
Windows und Linux, je local/direct central. Zwei frische Kontrollen wurden am
beabsichtigten Oracle abgewiesen: falscher Identitätsgolden und Schema-SELECT.
Ein erster eigener Fixturelauf stoppte an der gekoppelten Sessionprüfung;
er ist kein positiver Nachweis. Korrigiert wurde der Prüfpunkt: Zustände werden
separat vor/nach dem Aufruf erfasst, bei unverändertem Erhaltungsoracle.
Originaler Fehlversuch, Runset, Journal und exakte damalige Casebytes bleiben
privat erhalten. Die abschließende reine Leseprojektion löst nur den alten
Quellpfad gegen identische gespeicherte Bytes mit demselben Digest auf; sie
schreibt keinen Originalpin um und führt die fehlgeschlagene Fixture nicht aus.

Insgesamt 15 Versuche inklusive dieses Fehlers und beider Negativkontrollen
sind terminal und separat bereinigt. Nach allen eigenen Verbrauchern bestätigen
15 frische rein lesende Audits die Abwesenheit aller 27 eigenen Datenbanknamen,
ursprüngliche Konfiguration und entfernten eigenen beziehungsweise unverändert
vorhandenen Trust. Die 26 Namen der akzeptierten Matrix/Kontrollen sind separat
gezählt. Reale Werte, Trusthashes, Endpoints und Runtimeausgaben bleiben privat.
Das Labfenster wurde danach ausdrücklich an den anderen Chat zurückgegeben;
weitere native Replays sind nicht vorgesehen.

Die Paket-DLL ist bytegleich zu zwei früheren isolierten reproduzierbaren Builds;
alle aktuellen Compile-Inputs stimmen mit dem belegten Buildstand überein.
Kein neuer oder unbekannter Build wurde verwendet. Funktionsverbindungen waren
verschlüsselt mit explizitem Trustwert des validierten Vertrags; authentifiziertes
TLS bleibt nicht ausgeführt. Modulstatus bleibt teilweise validiert/unveröffentlicht.

Der [maschinenlesbare Bericht](text-pairs-caller-qualification.json) bindet die
öffentlichen Quellen und abstrakten Resultate. Vollständige API-, Lifecycle-,
Client-, Ressourcen-, Heap-/Parallelitäts- und echte CrossDB-Identitätsgates bleiben
getrennt. Geschlossen ist ausschließlich der beschriebene Caller-/Ausgabewegscope.
