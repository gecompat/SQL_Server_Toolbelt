SET QUOTED_IDENTIFIER ON;
-- Nur eigene disposable Datenbank, Operatorrechte werden nicht verändert.
SET NOCOUNT ON;
CREATE USER SecuritySchemaOwner WITHOUT LOGIN;
ALTER AUTHORIZATION ON SCHEMA::toolbelt_core TO SecuritySchemaOwner;
BEGIN TRY
:r ../../Source/SchemaTrustPreflight.sql
 THROW 52992,N'Fremder Schemaowner wurde akzeptiert.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51032 THROW;
END CATCH;
ALTER AUTHORIZATION ON SCHEMA::toolbelt_core TO dbo;
GO
GRANT ALTER ON SCHEMA::toolbelt_core TO SecuritySchemaOwner;
BEGIN TRY
:r ../../Source/SchemaTrustPreflight.sql
 THROW 52992,N'Untrusted Schemakontrolle wurde akzeptiert.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51032 THROW;
END CATCH;
REVOKE ALTER ON SCHEMA::toolbelt_core FROM SecuritySchemaOwner;
GO
ALTER ROLE db_ddladmin ADD MEMBER SecuritySchemaOwner;
BEGIN TRY
:r ../../Source/SchemaTrustPreflight.sql
 THROW 52992,N'Untrusted feste DDLrolle wurde akzeptiert.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51032 THROW;
END CATCH;
ALTER ROLE db_ddladmin DROP MEMBER SecuritySchemaOwner;
DROP USER SecuritySchemaOwner;
GO
:r ../../Source/SchemaTrustPreflight.sql
PRINT N'Schematrustvertrag: erfolgreich';
GO
