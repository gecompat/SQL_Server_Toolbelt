# Split-Advanced Moduldesign

S2 am 2026-10-01 ausdrücklich freigegeben; [besprochener Entwurf](ADVANCED_STRING_SPLIT_PROPOSAL.md), [öffentlicher Vertrag](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md).
Der S2-TVF-Kern ist dependencyfrei und ohne CLR. Das Modul unterstützt
local/central und Compatibility>=150 auf SQL Server 2019/2022/2025 Windows/Linux;
ab 1.1.0 erhält sein Installer eine ResultTable-Moduldependency für die neue USP.

## Inline-Präferenz und begründete Ausnahme

Der Parser muss Quote-/Escapezustand, Cursorfortschritt und längsten Separator zustandsabhängig verfolgen. Ein Inline-TVF-Entwurf könnte dies über rekursive CTE oder große relationale Kandidatenmengen ausdrücken, benötigt aber Rekursions-/Ressourcenregeln für bis65536 Codeeinheiten und muss späte Fehler atomar statt Teiltokens publizieren. Dies wäre für den begrenzten S2-Vertrag komplexer und mit zusätzlichen Ressourcenrisiken verbunden; keine gemessene pauschale Performancebehauptung.

Deshalb dokumentierte Ausnahme von der Inline-Präferenz: Multi-statement-TVF mit bounded sequentiellem Scan und internen Tokenspans. Erst nach vollständiger Validierung werden Erfolgstokens publiziert; erwartete Fehler liefern eine einzige Fehlerzeile. Keine TRY/CATCH-/THROW-Emulation in UDF, Enginefehler bleiben unverändert. [Microsoft UDF-Limitations](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine) erläutern die UDF-Einschränkungen.

BIN2 steuert explizit Codeeinheitenzählung und Vergleiche unabhängig von Datenbankcollation; bytebasierter Duplikatvergleich schützt trailing Spaces. Input-/JSON-/Separatormengen sind vor Parsing begrenzt. Tokenspans vermeiden vorzeitige Resultatmaterialisierung; kein Durchsatz-/Parallelitätsversprechen.

SQLCMD-Lifecycle folgt markerbasiertem Template mit Preflight und unter Lock wiederholter Kollisions-/Versionsprüfung, Transaktion und Sourcehashdiagnostik. Zentrale Deinstallation verlangt externe Verbraucherbestätigung. Symbolische Parserfehler und numerische Lifecyclefehler sind getrennte Verträge.

## Ausdrückliche Folgefreigabe vom 2026-10-01

Nach konkreter Vertragsbesprechung in PR #121 hat der Benutzer ausdrücklich
„Unquoting, Split-USP und ZIP-Writer implementieren“ beauftragt.
Damit sind TVF_UnquoteToken und USP_SplitAdvanced als getrennte öffentliche
APIs im bestehenden Split-Modul freigegeben; ZIP liegt in anderem Scope.
Historische Vorschlagstexte bleiben Entscheidungsverlauf, nicht aktuelle Sperre.
Version 1.1.0 ergänzt die beiden APIs, S2-Source bleibt unverändert.
TVFs bleiben dependencyfrei; Modulinstaller/USP-ResultTable deklarieren
same-database toolbelt.core.result-table >=1.0.0.

Unquoting benötigt links-nach-rechts Escape-/Double-Präzedenz und atomare
Ausgabe; rekursive Inline-CTE benötigt Rekursions-/Ressourcenregeln und
eine relationale Spankonstruktion mit erheblicher Zusatzkomplexität.
Deshalb bounded MSTVF als dokumentierte Inline-Präferenz-Ausnahme,
keine gemessene Performanceüberlegenheit. Span-Kopien vermeiden pro-Zeichen-
Konkatenation; dichte Doubles können trotzdem wiederholte LOB-Kopien
erzeugen und erhalten einen fokussierten 65536-Codeunit-Test.
USP führt exakt einen S2-Snapshot aus, Fehler vor Mutationen; kanonischer
ResultTable-Helper mit eigenem Transaktionsscope/committable Savepoint.
Öffentliche Verträge: TVF_UnquoteToken.md und USP_SplitAdvanced.md im Modul.
Neue Runtime-Evidenz separat, frühere S2-Evidenz nicht auf neue APIs übertragen.
