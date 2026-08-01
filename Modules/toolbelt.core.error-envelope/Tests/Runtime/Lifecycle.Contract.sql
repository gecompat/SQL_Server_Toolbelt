IF OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope', N'P') IS NULL
    THROW 52410, N'USP_CaptureErrorEnvelope fehlt.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.error-envelope.Version' AND CONVERT(nvarchar(32), value)=N'1.0.0')
    THROW 52411, N'Modulmarker fehlt.', 1;
PRINT N'Error Envelope Lifecycle: erfolgreich';
