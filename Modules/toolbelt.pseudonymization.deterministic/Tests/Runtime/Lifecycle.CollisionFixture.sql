SET NOCOUNT ON;
-- Pro Fall eine synthetische Testdatenbank; keine Reparatur fremder Ressourcen.
DECLARE @FaultCase nvarchar(64)=N'$(FaultCase)';
IF @FaultCase IN(N'FutureSlot',N'ImitatedFutureSlot')
BEGIN
 IF OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicTranslate') IS NOT NULL
  THROW 54090,N'Der FutureSlot-Test erfordert einen historischen Stand.',1;
 EXEC(N'CREATE FUNCTION toolbelt_pseudonymization.TVF_DeterministicTranslate() RETURNS TABLE AS RETURN SELECT CONVERT(nvarchar(max),N''Contoso'') AS Value,CONVERT(int,73) AS ErrorCode;');
 IF @FaultCase=N'ImitatedFutureSlot'
 BEGIN
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.pseudonymization.deterministic',
   @level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicTranslate';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',
   @level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicTranslate';
 END;
END;
ELSE IF @FaultCase=N'UnknownVersion'
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@value=N'9.9.9';
ELSE IF @FaultCase IN(N'ForeignFunctionMarker',N'InconsistentFunctionVersion')
BEGIN
 DECLARE @Property sysname=CASE WHEN @FaultCase=N'ForeignFunctionMarker' THEN N'Toolbelt.ModuleId' ELSE N'Toolbelt.ModuleVersion' END;
 EXEC sys.sp_updateextendedproperty @name=@Property,@value=N'fixture.foreign',
 @level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicTranslate';
END;
ELSE THROW 54090,N'Unbekannter Lifecycle-FaultCase.',2;
