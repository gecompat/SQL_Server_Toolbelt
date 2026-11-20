# Mono.Cecil 0.11.6: ausschließlich Buildwerkzeug

Mono.Cecil wird verwendet, um aus dem unveränderten, gepinnten Microsoft-ScriptDom-
Original eine gesonderte Toolbelt-Assembly mit eigener CLR-Identität zu erzeugen.
Der ursprüngliche Microsoft-Namespace bleibt erhalten; die abgeleitete Assembly
ist ausdrücklich unsigniert und kein unverändertes Microsoft-Publisherartefakt.
Die SQL-Server-Engine erlaubt Original-ScriptDom-Versionen nicht allein aufgrund
unterschiedlicher SQL-Assemblynamen parallel. Eine bloße Aliasumbenennung reicht
deshalb für die gewünschte Koexistenz nicht aus.

Das Werkzeug wird nicht als SQL CLR installiert oder als Runtimeabhängigkeit
ausgeliefert. Das Produkt benötigt nach dem Build kein Mono.Cecil. Der Adapter
verändert weder Originaldatei noch installierte fremde Assemblies. Er schreibt
eine neue Datei, entfernt nur Strong-Name-bezogene Metadaten, ändert Assembly- und
Modulnamen und schreibt deterministisch. Nicht unterstützte Selbstreferenzen und
Reflection-Literale werden abgewiesen. Fachliche Methodenkörper bleiben erhalten.

Bezugsquelle: [NuGet 0.11.6](https://www.nuget.org/packages/Mono.Cecil/0.11.6),
[Upstream-Release](https://github.com/jbevain/cecil/releases/tag/0.11.6).
Lizenz: MIT, siehe LICENSE.txt. Der am 2026-11-20 bezogene NuGet-Satz wurde mit
`dotnet nuget verify --all` erfolgreich geprüft. Der Buildadapter prüft die
festen SHA2-512-Pins von Paket und ausgewählter net40-DLL vor Verwendung; er
verwendet keine bewegliche Versionsauswahl und deaktiviert keine TLS-Prüfung.

Die Pins und der begrenzte Buildablauf stehen in
[Resolve-ToolbeltScriptDom.ps1](../../Scripts/Clr/Resolve-ToolbeltScriptDom.ps1).
Der Transformationscode steht in
[PrivateScriptDom.cs](../../Scripts/Clr/PrivateScriptDom.cs).
Die neue Identität und der tatsächliche Ausgabehash werden einschließlich
Reproduktionsprüfung separat erfasst. Original-ScriptDom-Lizenz und Attribution
bleiben auch bei einer abgeleiteten Auslieferung erforderlich.

Pflege: gepinnter Buildtool-Einsatz, keine automatische Aktualisierung. Bei einem
neuen Upstream-Stand werden Lizenz, Herkunft, Änderung und deterministisches
Ergebnis erneut geprüft. Ein Ausstieg ist durch einen eigenen reproduzierbaren
ScriptDom-Sourcebuild mit derselben privaten Identitätsstrategie möglich; keine
Produkt-API oder SQL-Abhängigkeit bindet den Nutzer an Mono.Cecil.
