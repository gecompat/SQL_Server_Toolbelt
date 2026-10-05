# Exaktes Trust-Opt-in – korrigierte interne Unicode-Bindung

Status: **GRANTED_FOR_EXACT_LAB_TEST_SCOPE**, Benutzerzustimmung2026-10-05:
„du brauchst das Trust-Opt-in dafür nicht einholen - ich gebe es dir jetzt schon frei“.
Die fachliche Schema-/Kern-Freigabe und die bereits
erteilten Core-/Constructor-Trustfreigaben bleiben bestehen.

Zusätzliche ausdrückliche Benutzerfreigabe2026-10-05:
„hiermit gebe ich alle Schema-Trusthash Abfragen von dir frei - du brauchst mich nicht mehr fragen!“
Für diese laufende freigegebene Schema-Entwicklungs-/Lab-Testwelle dürfen
weitere separat qualifizierte Schemahashes im beschriebenen Testscope ohne
erneute Frage verwendet werden. Jede neue Binaryidentität, Offlinequalifikation,
genaue Zielauswahl und Wiederherstellung bleiben nachvollziehbar erforderlich.
Diese Autorisierung erweitert keine Produktions- oder Infrastrukturgrenze.

Der native SQL2019-Bindingversuch zeigte6552 für den bisherigen internen
varchar-Profile-Parameter. CLR-TVFs unterstützen ausschließlich Unicode-
Zeichenfelder. Der interne Profile-Parameter und die bisher vier internen
varchar-Ergebnisspalten sind nun nvarchar; die öffentliche USP behält ihre
freigegebenen Parameter, zehn Ergebnisfelder, ASCII-Identität und Fehlerpriorität.
[Microsoft-Parametermapping](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-types-net-framework/mapping-clr-parameter-data)
und [CLR-TVF-Grenze](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions)
begründen die technische Korrektur.

Der aktuelle vollständige Source-Driver einschließlich aller drei Culture-
Orakel und eigener IL bestand erneut. Alle drei kanonischen Projektbuilds
sind bytegleich; die Closure-static und sieben Paketierungsfälle bestanden.
Core- und Constructorbytes sind unverändert. Die korrigierten Schemabytes
sind in den begrenzten Core-/Schema-Läufen auf Linux/SQL2019/latest CL150
und Windows/SQL2025/CU8 CL170 jeweils lokal und zentral erfolgreich nativ
ausgeführt. Genuine Constructor1.2→1.3 bestand anschließend auf beiden Zielen
local/central; die vollständige Matrix bleibt offen.
Der vorherige Hash wird nicht als neuer
qualifizierter Stand ausgegeben; seine Freigabe steht unverändert in der
[historischen Vorlage](../../toolbelt.json.core/Documentation/TRUST_OPT_IN_PROPOSAL.md).

SQL-Assembly: `Toolbelt_JsonSchema`; Managed-Version1.0.0.0.
Artifact-ID: `4ae51961dc53bd6aff96bb566e908cbb715d40512f36cffc756e7f2813a3a143`.
Exakter neuer SHA2-512:

```text
f67e0f9f3f6e83acc304e8e60bc98ee2610018e654ac4eb6e430f98a9665f9a1c85e90ef97950d348fcc0fc6389de71b214d1f9101835fec9a305ef39c41af21
```

Freigegeben sind dieser zusätzliche Hash und gemäß obiger Benutzerzustimmung
weitere separat qualifizierte Schemahashes im selben bereits
besprochenen Testscope: frisch schema-validierte bereite Labziele
Linux/SQL2019/latest und Windows/SQL2025/CU8; bestehende Rechte und strict
security1; private Vorzustände und Journal; Wiederherstellung ausschließlich
eigener unverändert identifizierter Änderungen nach allen Testverbrauchern.
Die ursprüngliche Einzelzustimmung war auf diese Labziele begrenzt. Die
anschließende allgemeine Trustfreigabe für die laufende Entwicklungswelle
erlaubt deren notwendige begrenzte Testkopplung, einschließlich der bestehenden
synthetischen GitHub-Compatibility-CI; siehe die
[datierte Fortsetzungsautorität](../../toolbelt.json.core/Documentation/TRUST_OPT_IN_PROPOSAL.md).
Keine Produktion, Lab-Infrastrukturverwaltung oder neue Rechte/Owner.
Die unveränderten Core-/Constructorhashes behalten ihre bekannte Identität.
