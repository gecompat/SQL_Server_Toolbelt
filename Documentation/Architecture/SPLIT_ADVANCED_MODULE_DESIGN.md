# Split-Advanced Moduldesign

S2 am 2026-10-01 ausdrücklich freigegeben; [besprochener Entwurf](ADVANCED_STRING_SPLIT_PROPOSAL.md), [öffentlicher Vertrag](../../Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md). Modul `toolbelt.string.split-advanced` ist dependencyfrei, ohne CLR, unterstützt local/central und Compatibility>=150 auf SQL Server 2019/2022/2025 Windows/Linux.

## Inline-Präferenz und begründete Ausnahme

Der Parser muss Quote-/Escapezustand, Cursorfortschritt und längsten Separator zustandsabhängig verfolgen. Ein Inline-TVF-Entwurf könnte dies über rekursive CTE oder große relationale Kandidatenmengen ausdrücken, benötigt aber Rekursions-/Ressourcenregeln für bis65536 Codeeinheiten und muss späte Fehler atomar statt Teiltokens publizieren. Dies wäre für den begrenzten S2-Vertrag komplexer und mit zusätzlichen Ressourcenrisiken verbunden; keine gemessene pauschale Performancebehauptung.

Deshalb dokumentierte Ausnahme von der Inline-Präferenz: Multi-statement-TVF mit bounded sequentiellem Scan und internen Tokenspans. Erst nach vollständiger Validierung werden Erfolgstokens publiziert; erwartete Fehler liefern eine einzige Fehlerzeile. Keine TRY/CATCH-/THROW-Emulation in UDF, Enginefehler bleiben unverändert. [Microsoft UDF-Limitations](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine) erläutern die UDF-Einschränkungen.

BIN2 steuert explizit Codeeinheitenzählung und Vergleiche unabhängig von Datenbankcollation; bytebasierter Duplikatvergleich schützt trailing Spaces. Input-/JSON-/Separatormengen sind vor Parsing begrenzt. Tokenspans vermeiden vorzeitige Resultatmaterialisierung; kein Durchsatz-/Parallelitätsversprechen.

SQLCMD-Lifecycle folgt markerbasiertem Template mit Preflight und unter Lock wiederholter Kollisions-/Versionsprüfung, Transaktion und Sourcehashdiagnostik. Zentrale Deinstallation verlangt externe Verbraucherbestätigung. Symbolische Parserfehler und numerische Lifecyclefehler sind getrennte Verträge.

Optionaler USP mit gleichem Kern und Unquoting sind spätere separate Funktionsslices; nicht implementiert oder pauschal freigegeben.
