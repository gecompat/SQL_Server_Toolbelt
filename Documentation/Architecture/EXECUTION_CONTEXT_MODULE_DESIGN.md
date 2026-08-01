# Execution-Context-Moduldesign

Version 1 verwendet ausschließlich namespacete `SESSION_CONTEXT`-Schlüssel. Ein Context besitzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und ScopeDepth. Verschachtelung erzeugt keine neue Identität, sondern erhöht die Tiefe. Dadurch bleibt Version 1 ohne persistente Tabelle und ohne serialisierten Stack.

Die inline TVF ist die primäre Leseschnittstelle. Der SVF-Wrapper ist optionaler Komfort und darf in mengenorientierten Abfragen nicht die TVF verdrängen. Aufrufer mit Connection Pooling müssen Begin und End paaren; bei der letzten Ebene werden alle Toolbelt-Schlüssel gelöscht.
