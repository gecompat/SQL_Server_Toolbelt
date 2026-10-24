# Neutrales SSIS Paketmodell exportieren

Der freigegebene Austauschvertrag mit SQL Server Analyze ergänzt den bestehenden
Debuggenerator um einen externen Exporthost. Beide verwenden dieselben
typisierten Definitionen und Beziehungen aus `Core/PackageDocument.cs` sowie
dieselben Komponentenprofile. Der Generator liest XML nicht ein zweites Mal;
seine SQL-Typ-, Binding- und CTE-Projektion bleibt ein eigener Verbraucher.

Die Freigabe stammt aus dem Benutzerauftrag „Ich gebe den Vertrag frei. Setze
ihn schrittweise in Analyze und Toolbelt um“. Der
[projektübergreifende Vertrag](https://github.com/gecompat/SQL_Server_Analyze/blob/main/Documentation/Architecture/SSIS_Analyze_Toolbelt_Exchange_Contract.md)
definiert Identität, Coverage und Evidenzgrenzen. Die kanonischen
[Schema- und Beispieldateien](../Contracts/Exchange/SSIS_Exchange_V1.schema.json)
sowie die [gemeinsamen Sollfälle](../Contracts/Exchange/Fixtures/direct-8.expected.json)
liegen in diesem Modul. Analyze übernimmt sie unverändert mit Commit- und Hashbindung.

## Build und Übergabe

Der externe Host benötigt .NET 10. Für den Build wird das entsprechende SDK
verwendet. SQL Server, SQL CLR, ScriptDom und SSIS SDK werden vom Host nicht
benötigt. Die bestehende SQL-CLR-Fassade bleibt Windows-spezifisch; ihre
Abhängigkeiten werden durch den externen Host nicht installiert oder geändert.
Der Host wird derzeit aus den Quellen gebaut. Das bestehende versionierte
Installations-ZIP enthält den früher qualifizierten CLR-Build und keinen
Exporthost; es ist kein Liefernachweis für diesen neuen Kern.

```powershell
$sourceCommit = git rev-parse HEAD
dotnet build Modules/toolbelt.tsql.ssis-debug/Exchange/Host/Toolbelt.Ssis.Export.csproj `
    -c Release -p:SourceRevisionId=$sourceCommit

dotnet Modules/toolbelt.tsql.ssis-debug/Exchange/Host/bin/Release/net10.0/Toolbelt.Ssis.Export.dll `
    Modules/toolbelt.tsql.ssis-debug/Contracts/Exchange/Fixtures/direct-8.dtsx
```

Der Host akzeptiert genau einen ausdrücklich übergebenen `.dtsx`-Pfad und
schreibt ausschließlich das Modell nach stdout. Fehler liefern einen neutralen
Code auf stderr und Exitcode 3 für ungültige oder begrenzte Paketdaten,
beziehungsweise 4 für einen Hostfehler. Größenprüfungen begrenzen auch eine
während des Einlesens wachsende Datei. Ein DTD oder externer Resolver wird
nicht zugelassen. Zum lokalen Ausprobieren dient ausschließlich die synthetische
Fixture. Reale Pakete und exportierte Strukturen gehören nicht ins Repository.

Für einen qualifizierten Build müssen die Quellen des angegebenen Git-Commits
unverändert vorliegen. Ein Entwicklungsbuild mit veränderten Quellen und alter
Commitangabe ist kein Release- oder Herkunftsnachweis. Der ausgegebene Buildhash
bezieht sich auf die tatsächlich ausgeführte Hostassembly. Auch diese Angaben
authentifizieren das JSON-Modell nicht.

Der Caller kann das Ergebnis mit dem nativen Analyze-Objekt
`[monitor].[USP_SsisPackageModelAnalysis]` verarbeiten. Er übergibt JSON und
optional die Originalbytes als Parameter. Analyze lädt keine Toolbelt-Assembly
und ruft den Host nicht selbst auf. Die bestehende XML-Inventur und beide
Loganalysen bleiben eigenständig nutzbar.

## Abdeckung des ersten Slices

Der Kern inventarisiert das festgelegte Objektuniversum vor jeder
Komponentenfilterung. Direkte Pipeline- und Control-Flow-Kanten sowie
auflösbare direkte Spaltenzuordnungen erhalten eigene Kennungen. Eine
Datenzuordnung erzeugt `MAPPED_VALUE_INPUT`; ein Metadatenverweis allein erzeugt
keine Wertabhängigkeit. Unbekannte Komponenten, nicht aufgelöste Bezüge,
Ausdrucksattribute und verschlüsselte Bereiche begrenzen die Coverage.

`BOUND_EXPRESSION_INPUT`, `LOOKUP_ROW_SELECTION` und `SPLIT_ROW_SELECTION`
sind im Vertrag vorgesehen, aber in diesem Slice nicht qualifiziert und
werden nicht ausgegeben. Es gibt keine transitive Closure und keinen
SSIS-Runtime-Nachbau. Pragmatische Vergleichs- und Cacheentscheidungen des
SQL-Generators gehören nicht in das neutrale Modell.

## Gemeinsame Prüfung

`Tests/test_contract.py` verwendet das kanonische Schema, dieselbe Fixture und
denselben unabhängigen Objekt-/Kantensollsatz wie der native Analyze-Harness.
Der Test vergleicht den externen Host mit einem .NET-Framework-Host der
SQL-CLR-Assembly; Herkunftsfelder der unterschiedlichen Hostbuilds werden
beim Modellvergleich ausgeklammert. DTDs, unbekannte Formate, gleiche Namen
in verschiedenen Scopes, private Literalwerte und Ausdrucksattribute besitzen
gezielte Gegenproben. `jsonschema` ist ausschließlich eine Testabhängigkeit.

Die bestehenden Generator-Frameworkfälle und die native local/central-Suite
bleiben eigene Regressionen. Der native Harness akzeptiert einen expliziten
geprüften Kandidatenhash und separate Releaseverzeichnisse; Standardaufrufe
behalten ihren bisherigen festen Hash. Das ersetzt keine Freigabe eines
beliebigen Binaries. Alle Quellen-/Binarybindungen, Strict-Security-Prüfungen,
privaten Journale und Wiederherstellungsgates bleiben aktiv.

Der vorhandene Windows-CI-Job baut zusätzlich genau einen externen Host und
führt die gemeinsamen Gegenproben gegen die bereits gebaute CLR-Assembly aus.
`jsonschema==4.26.0` bleibt eine reine Testabhängigkeit. Die acht synthetischen
Eingaben laufen jeweils in einem .NET-Framework-Paritätsprozess und einem
externen .NET-Prozess; hinzu kommt die einmalige Kompilierung des Paritätshosts.
Es entstehen keine weiteren Jobs oder Labzugriffe. Die bestehenden 21
Generator-Frameworkkinder werden nicht verdoppelt. Die unabhängige Prüfung dieses
Änderungsschritts umfasste einen Reviewer und einen Folgeauftrag zu dessen
konkreten Befunden. Weitere Reviews werden dadurch nicht ausgelöst.

Die externe Hostausführung ist unter Windows mit .NET 10 geprüft. Ein eigener
Linux-Hostlauf, umfassende Ressourcenqualifikation, SDK-Parität, aktuelle
Head-CI und eine Veröffentlichung sind getrennte Nachweise.
