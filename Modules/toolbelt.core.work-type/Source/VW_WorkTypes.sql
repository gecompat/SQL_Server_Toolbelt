SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkTypes]
AS
SELECT
      wt.[WorkTypeId]
    , wt.[WorkTypeName]
    , wt.[HandlerSchema]
    , wt.[HandlerProcedure]
    , QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]) AS [HandlerQualifiedName]
    , wt.[ParameterMode]
    , wt.[PayloadContractJson]
    , wt.[DefaultTimeoutSeconds]
    , wt.[IsIdempotent]
    , wt.[IsEnabled]
    , wt.[Description]
    , wt.[CreatedAtUtc]
    , wt.[CreatedBy]
    , wt.[ModifiedAtUtc]
    , wt.[ModifiedBy]
    , wt.[DisabledAtUtc]
    , wt.[DisabledBy]
    , wt.[DisabledReason]
    , wt.[RowVersion]
    , CONVERT(bit, CASE
          WHEN OBJECT_ID(QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]), N'P') IS NOT NULL
            OR OBJECT_ID(QUOTENAME(wt.[HandlerSchema]) + N'.' + QUOTENAME(wt.[HandlerProcedure]), N'PC') IS NOT NULL
          THEN 1 ELSE 0 END) AS [HandlerExists]
FROM [toolbelt_core].[WorkType] AS wt;
GO
