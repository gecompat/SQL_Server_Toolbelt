# `toolbelt_datetime.TVF_DateSpineCore`

Interne Inline TVF für die gemeinsame Periodenlogik der drei öffentlichen
Date-Spine-Funktionen. `@Grain` akzeptiert intern ausschließlich `day`,
`iso_week` oder `month`; andere Werte liefern keine Zeilen.

Das Objekt ist kein öffentlicher Erweiterungspunkt. Aufrufer verwenden die
typisierten öffentlichen Funktionen.
