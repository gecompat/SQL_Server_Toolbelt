#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:-mcr.microsoft.com/mssql/server:2025-latest}"
container_name="tbx-second-session-spike-${GITHUB_RUN_ID:-local}"
sa_password="TbxA1!$(openssl rand -hex 16)"
echo "::add-mask::${sa_password}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d \
  --name "${container_name}" \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${sa_password}" \
  "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then
    sqlcmd_path="${candidate}"
    break
  fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 60 ]]; then
    docker logs "${container_name}"
    exit 1
  fi
  sleep 2
done

run_query() {
  local database="$1"
  local query="$2"
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" -Q "${query}"
}

run_file() {
  local database="$1"
  local file="$2"
  shift 2
  docker exec -i "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" -i /dev/stdin "$@" < "${file}"
}

work_dir="$(mktemp -d)"
setup_sql="${work_dir}/setup.sql"
test_sql="${work_dir}/test.sql"

cat > "${setup_sql}" <<'SQL'
:on error exit

IF DB_ID(N'tbx_second_session_spike') IS NOT NULL
BEGIN
    ALTER DATABASE [tbx_second_session_spike] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [tbx_second_session_spike];
END;
GO
CREATE DATABASE [tbx_second_session_spike] COLLATE Latin1_General_100_CS_AS;
GO

USE [tbx_second_session_spike];
GO
CREATE TABLE dbo.RemoteEvent
(
      EventId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_RemoteEvent PRIMARY KEY
    , SourceSessionId int NOT NULL
    , RemoteSessionId int NOT NULL
    , EventName varchar(64) NOT NULL
    , CreatedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_RemoteEvent_CreatedAtUtc DEFAULT SYSUTCDATETIME()
);
GO
CREATE OR ALTER PROCEDURE dbo.USP_WriteRemoteEvent
      @SourceSessionId int
    , @EventName varchar(64)
    , @ThrowAfterInsert bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    INSERT INTO dbo.RemoteEvent(SourceSessionId, RemoteSessionId, EventName)
    VALUES (@SourceSessionId, @@SPID, @EventName);

    IF @ThrowAfterInsert = 1
        THROW 52600, N'Synthetischer Remote-Fehler.', 1;

    COMMIT TRANSACTION;
    RETURN 0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.USP_ReturnsResultSet
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS int) AS UnexpectedResult;
    RETURN 0;
END;
GO

USE [master];
GO
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'TBX_LOOPBACK')
    EXEC master.dbo.sp_dropserver @server=N'TBX_LOOPBACK', @droplogins='droplogins';
GO
EXEC master.dbo.sp_addlinkedserver
      @server = N'TBX_LOOPBACK'
    , @srvproduct = N''
    , @provider = N'MSOLEDBSQL'
    , @datasrc = N'localhost'
    , @provstr = N'encrypt=optional';
GO
EXEC master.dbo.sp_addlinkedsrvlogin
      @rmtsrvname = N'TBX_LOOPBACK'
    , @useself = N'False'
    , @locallogin = NULL
    , @rmtuser = N'sa'
    , @rmtpassword = N'$(SaPassword)';
GO
EXEC master.dbo.sp_serveroption N'TBX_LOOPBACK', N'rpc out', N'true';
EXEC master.dbo.sp_serveroption N'TBX_LOOPBACK', N'remote proc transaction promotion', N'false';
GO
SQL

run_file master "${setup_sql}" -v "SaPassword=${sa_password}"

cat > "${test_sql}" <<'SQL'
:on error exit
USE [tbx_second_session_spike];
GO
SET NOCOUNT ON;

IF NOT EXISTS
(
    SELECT 1
    FROM master.sys.servers
    WHERE name = N'TBX_LOOPBACK'
      AND is_rpc_out_enabled = 1
      AND is_remote_proc_transaction_promotion_enabled = 0
)
    THROW 52610, N'Linked-Server-Vertrag ist nicht korrekt konfiguriert.', 1;

DECLARE @SourceSessionId int = @@SPID;
DECLARE @RemoteReturnCode int;

BEGIN TRANSACTION;
EXEC @RemoteReturnCode = [TBX_LOOPBACK].[tbx_second_session_spike].[dbo].[USP_WriteRemoteEvent]
      @SourceSessionId = @SourceSessionId
    , @EventName = 'caller-rollback';
IF @RemoteReturnCode <> 0
    THROW 52611, N'Unerwarteter Remote-Returncode.', 1;
ROLLBACK TRANSACTION;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.RemoteEvent
    WHERE EventName = 'caller-rollback'
      AND SourceSessionId = @SourceSessionId
      AND RemoteSessionId <> @SourceSessionId
)
    THROW 52612, N'Remote Commit überlebte den Caller-Rollback nicht oder lief nicht in einer zweiten Session.', 1;

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    CREATE TABLE #Parent(Id int NOT NULL CONSTRAINT PK_Parent PRIMARY KEY);
    CREATE TABLE #Child
    (
          Id int NOT NULL
        , ParentId int NOT NULL
        , CONSTRAINT FK_Child_Parent FOREIGN KEY(ParentId) REFERENCES #Parent(Id)
    );
    INSERT INTO #Child(Id, ParentId) VALUES (1, 999);
    THROW 52613, N'Der synthetische Constraintfehler blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52613
        THROW;
    IF XACT_STATE() <> -1
        THROW 52614, N'Der Caller ist nicht im erwarteten uncommittable Zustand.', 1;

    SET @RemoteReturnCode = NULL;
    EXEC @RemoteReturnCode = [TBX_LOOPBACK].[tbx_second_session_spike].[dbo].[USP_WriteRemoteEvent]
          @SourceSessionId = @SourceSessionId
        , @EventName = 'caller-uncommittable';
    IF @RemoteReturnCode <> 0
        THROW 52615, N'Unerwarteter Remote-Returncode im uncommittable Caller.', 1;

    ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.RemoteEvent
    WHERE EventName = 'caller-uncommittable'
      AND SourceSessionId = @SourceSessionId
      AND RemoteSessionId <> @SourceSessionId
)
    THROW 52616, N'Remote Commit aus uncommittable Caller fehlt.', 1;

BEGIN TRY
    EXEC [TBX_LOOPBACK].[tbx_second_session_spike].[dbo].[USP_WriteRemoteEvent]
          @SourceSessionId = @SourceSessionId
        , @EventName = 'remote-error'
        , @ThrowAfterInsert = 1;
    THROW 52617, N'Der Remote-Fehler blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (52600, 7391, 7411)
        THROW;
END CATCH;

IF EXISTS (SELECT 1 FROM dbo.RemoteEvent WHERE EventName = 'remote-error')
    THROW 52618, N'Die fehlerhafte Remote-Transaktion wurde nicht zurückgerollt.', 1;

DECLARE @DynamicSql nvarchar(max) =
    N'EXEC @ReturnCode = [TBX_LOOPBACK].[tbx_second_session_spike].[dbo].[USP_WriteRemoteEvent]'
    + N' @SourceSessionId=@SourceSessionId, @EventName=@EventName WITH RESULT SETS NONE;';
SET @RemoteReturnCode = NULL;
EXEC sys.sp_executesql
      @DynamicSql
    , N'@SourceSessionId int, @EventName varchar(64), @ReturnCode int OUTPUT'
    , @SourceSessionId = @SourceSessionId
    , @EventName = 'dynamic-rpc'
    , @ReturnCode = @RemoteReturnCode OUTPUT;
IF @RemoteReturnCode <> 0
    THROW 52619, N'Dynamischer Remote-Returncode ist inkonsistent.', 1;

BEGIN TRY
    EXEC [TBX_LOOPBACK].[tbx_second_session_spike].[dbo].[USP_ReturnsResultSet]
    WITH RESULT SETS NONE;
    THROW 52620, N'Resultset-Verstoß wurde nicht abgelehnt.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52620
        THROW;
END CATCH;

IF (SELECT COUNT(*) FROM dbo.RemoteEvent WHERE EventName IN ('caller-rollback', 'caller-uncommittable', 'dynamic-rpc')) <> 3
    THROW 52621, N'Die Spike-Evidenz ist unvollständig.', 1;

PRINT N'Second-Session-Loopback-Spike: erfolgreich';
GO
SQL

run_file tbx_second_session_spike "${test_sql}"

run_query master "EXEC master.dbo.sp_dropserver @server=N'TBX_LOOPBACK', @droplogins='droplogins';"

echo "Second-Session-Loopback-Spike: erfolgreich"
