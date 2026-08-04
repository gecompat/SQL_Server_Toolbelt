# Second-Session-Moduldesign

## Ziel

`toolbelt.core.second-session` stellt genau eine synchrone Version-1-Semantik bereit: einen nicht in die Caller-Transaktion promovierten RPC zu einer zweiten Session derselben SQL-Server-Instanz.

## Providerentscheidung

Version 1 verwendet einen administrativ vorbereiteten Loopback-Linked-Server. `rpc out` muss aktiviert und `remote proc transaction promotion` deaktiviert sein. Das Modul prüft diese Optionen bei Konfiguration und Ausführung erneut.

Das Modul erzeugt oder verändert keine Linked Server, Login-Mappings oder Credentials. Der Providername wird als Moduldaten gespeichert; die Serveradministration bleibt außerhalb des Modul-Lifecycle.

## Ausgeschlossene Provider

- Service Broker ist für diesen synchronen, rollback-unabhängigen Vertrag ungeeignet, weil `SEND` transaktional an den Caller gebunden ist.
- SQL CLR mit regulärer externer Verbindung würde `EXTERNAL_ACCESS` benötigen und ist deshalb kein plattformübergreifender Linux-/Windows-Provider.
- SQL Agent und externe Worker besitzen andere synchrone, Security- und Fehlerverträge und werden nicht als austauschbare Version-1-Provider behauptet.

## Sicherheitsgrenze

Die öffentliche Procedure akzeptiert niemals SQL-Text. Ein Work Type muss im persistenten Katalog registriert und enabled sein. Der Remote-Dispatcher löst den Eintrag erneut in der Ziel-Datenbank auf, prüft die feste Handler-Signatur und die `EXECUTE`-Berechtigung des Remote-Principals.

Dynamisches SQL dient ausschließlich dem kontrollierten Quoting von Linked Server, Datenbank, Schema und Procedure sowie der Parameterbindung. Nutzdaten werden nicht in den Batchtext eingebettet.

## Transaktionsvertrag

Der öffentliche Aufruf verändert die Caller-Transaktion nicht. Der Remote-RPC darf auch aus `XACT_STATE() = -1` erfolgen. Der Remote-Dispatcher startet eine eigene Transaktion; Handlerfehler und Resultset-Verstöße rollen diese Transaktion zurück und werden weitergegeben.

Die lokale ResultTable-Ausgabe ist in einem uncommittable Caller nicht zulässig. Die direkte Ergebniszeile benötigt keine lokale Mutation.

## Context

Execution-ID, Correlation-ID, Actor und Tenant werden in der Remote-Session über `toolbelt.core.execution-context` gesetzt und nach Erfolg oder Fehler bestmöglich gelöscht. Connection Pooling darf keine Toolbelt-Sessionwerte zwischen Aufrufen erhalten.

## Handlervertrag

- `NONE`: keine Parameter.
- `JSON_PAYLOAD`: exakt ein Eingabeparameter `@PayloadJson nvarchar(max)`.

`WITH RESULT SETS NONE` verhindert unbeabsichtigte Handler-Resultsets. Der integer Returncode wird getrennt von SQL-Fehlern zurückgegeben.
