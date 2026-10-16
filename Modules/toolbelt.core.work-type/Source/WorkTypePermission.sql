-- Persistente explizite Work-Type-Delegation; kein automatischer Grant.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'toolbelt_core.WorkTypePermission',N'U') IS NULL
BEGIN
    CREATE TABLE toolbelt_core.WorkTypePermission
    (
        WorkTypeId bigint NOT NULL,
        PrincipalId int NOT NULL,
        PermissionName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        PrincipalSid varbinary(85) NOT NULL,
        PrincipalCreatedAt datetime NOT NULL,
        WorkTypeVersion binary(8) NOT NULL,
        IsDenied bit NOT NULL,
        CONSTRAINT PK_WorkTypePermission PRIMARY KEY(WorkTypeId,PrincipalId,PermissionName),
        CONSTRAINT FK_WorkTypePermission_WorkType FOREIGN KEY(WorkTypeId)
            REFERENCES toolbelt_core.WorkType(WorkTypeId) ON DELETE CASCADE,
        CONSTRAINT CK_WorkTypePermission_Name CHECK
            (PermissionName IN('ENQUEUE','CLAIM','EXECUTE_NEW_SESSION'))
    );
END;
GO
