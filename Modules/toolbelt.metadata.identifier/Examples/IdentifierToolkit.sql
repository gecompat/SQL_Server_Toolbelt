-- Ausschließlich synthetische Identifierbeispiele.

SELECT *
FROM toolbelt_metadata.TVF_ParseMultipartName
(
    N'[Archive.Db].dbo.[Order.Detail]'
);

SELECT toolbelt_metadata.SVF_QuoteMultipartName
(
    N'Server...Object'
) AS QuotedName;

SELECT *
FROM toolbelt_metadata.TVF_ParseMultipartName
(
    N'dbo.Object;DROP'
);
