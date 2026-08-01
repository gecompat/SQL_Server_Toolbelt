IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NULL OR OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId', N'FN') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_BeginExecution', N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext', N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_EndExecution', N'P') IS NULL
 THROW 52430, N'Execution-Context-Objektbestand ist unvollständig.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(32), value)=N'1.0.0')
 THROW 52431, N'Modulmarker fehlt.', 1;
PRINT N'Execution Context Lifecycle: erfolgreich';
