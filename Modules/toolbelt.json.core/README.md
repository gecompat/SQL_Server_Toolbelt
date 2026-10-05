# Shared SAFE JSON Core

`toolbelt.json.core`1.0.0 stellt die technische SAFE-Assembly
`Toolbelt_JsonCore` bereit. Sie exportiert keine SQL-Funktion. Der gemeinsame
iterative Scanner dient Constructors1.3 und JSON Schema1.0; die Legacy-/AGF-
Policy der Constructors bleibt getrennt von der Schema-Policy.

Der [öffentliche Gesamtvertrag](../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
beschreibt Unicode, exakte Zahlen, Arbeitskosten und Lifecycle. Die
[Testmatrix](Tests/TEST_MATRIX.md) trennt Offline- und native Nachweise.

Die Assembly wird ausdrücklich vor ihren Verbrauchern in derselben Datenbank
installiert. Deployment liest vollständige Metadaten, prüft bekannte Bytes,
typisierte Marker und vorhandene Owner und wiederholt den Preflight unter der
gemeinsamen AppLock. Uninstall lehnt vorhandene Assemblyverbraucher ab. Es gibt
keine automatische Dependencyinstallation, Truständerung oder Rechtevergabe.

`Scripts/New-JsonClosureRelease.ps1` erzeugt mit `-ModuleId toolbelt.json.core`,
`-AssemblyPath` und `-OutputDirectory` ein geschlossenes Offline-Paket. Der
Generator baut und installiert nichts. Der Trustmanifest ist ein Vorschlag;
neue SHA2-512-Trusthashes benötigen ein separates exaktes Benutzer-Opt-in.

Aktuell: Source, eigene IL, kanonischer Projektbuild, Syntax und Paketierung
teilweise validiert; begrenzte native Core-/Schema-Läufe bestanden auf
Linux2019/latest CL150 und Windows2025/CU8 CL170 local/central. Genuine
Constructor1.2→1.3 bestand auf Linux local/central. Weitere Ziel-/Lifecycle-
matrix offen, unreleased. Die eigene
IL-Prüfung zertifiziert keine transitive Framework-SAFE-Kompatibilität.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: run-json-schema-lab.ps1 Windows CL150/160`
- Scope: Windows2025/exaktCU8 CL150 und CL160 jeweils local/central: Core-/Schema-Scope, Repeat, zwei Consumer-Abweisungen, Coreidentität nach Schema-DROP und eigenes DB-/Trustcleanup bestanden. Frische hashgebundene read-only Dispositionaudits bestanden. Genuine1.2→1.3 separat auf beiden zusätzlichen Windowslevels local/central mit post-DROP-Rollback, Annotationserhalt und frischem Dispositionaudit bestanden. Weitere Ziel-/Rechtematrix offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
