using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using Toolbelt.Archive.ZipMemory;

namespace Toolbelt.Filesystem.Windows
{
    public static partial class WindowsFilesystemProvider
    {
        [SqlProcedure]
        public static void ExtractZipArchiveToDirectory(SqlBytes zipArchive, string rootAlias, string relativeDirectory, long maxArchiveBytes, long maxEntries, long maxEntryBytes, long maxTotalExpandedBytes, decimal maxCompressionRatio, int maxPathLength, bool overwriteExistingFiles, string executionIdentity, bool stageRows, SqlBoolean hilfe = default(SqlBoolean))
        {
            if (hilfe.IsTrue) { UsageSkillsGenerated.Send("toolbelt_filesystem", "CLR_ExtractZipArchiveToDirectory"); return; }
            if (zipArchive.IsNull || zipArchive.Length == 0) throw new ArgumentException("ZIP_ARCHIVE_REQUIRED");
            ValidateArchiveTransaction(stageRows);
            var execution = new FilesystemExecution(executionIdentity);
            string root, work;
            bool createDirectories, exclusiveRoot;
            using (var connection = new SqlConnection("context connection=true"))
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"SELECT RootPath, WorkPath, AllowCreateDirectory, AllowZipOverwrite
FROM toolbelt_filesystem.FileSystemRoot
WHERE RootAlias = @Alias AND IsActive = 1 AND AllowWrite = 1
  AND (@ServiceAccount = 0 OR AllowServiceAccount = 1);";
                command.Parameters.Add("@Alias", SqlDbType.NVarChar, 128).Value = (object)rootAlias ?? DBNull.Value;
                command.Parameters.Add("@ServiceAccount", SqlDbType.Bit).Value = executionIdentity == "ServiceAccount";
                connection.Open();
                using (var row = command.ExecuteReader())
                {
                    if (!row.Read()) Fail("RootNotAuthorized");
                    root = row.GetString(0);
                    work = row.IsDBNull(1) ? null : row.GetString(1);
                    createDirectories = row.GetBoolean(2);
                    exclusiveRoot = row.GetBoolean(3);
                }
            }

            var archive = new ZipEntryProvider.ExtractionArchive(zipArchive.Stream, zipArchive.Length, maxArchiveBytes,
                maxEntries, maxEntryBytes, maxTotalExpandedBytes, maxCompressionRatio, maxPathLength);
            IList<ArchiveDirectoryExtraction.ExtractionOutcome> outcomes;
            using (var destination = new ArchiveDestination(root, relativeDirectory, work, createDirectories,
                overwriteExistingFiles, exclusiveRoot, execution.RunArchive))
                outcomes = ArchiveDirectoryExtraction.ExtractDirectory(archive, destination);

            if (stageRows) { StoreArchiveOutcomes(outcomes); return; }
            SqlDataRecord result = Record("Ordinal", SqlDbType.BigInt, "EntryName", SqlDbType.NVarChar, -1,
                "EntryKind", SqlDbType.VarChar, 9, "Status", SqlDbType.VarChar, 16,
                "BytesWritten", SqlDbType.BigInt, "ErrorCode", SqlDbType.VarChar, 64);
            SqlContext.Pipe.SendResultsStart(result);
            foreach (var outcome in outcomes)
            {
                result.SetInt64(0, outcome.Ordinal);
                result.SetString(1, outcome.Entry.Name);
                result.SetString(2, outcome.Entry.IsDirectory ? "directory" : "file");
                result.SetString(3, outcome.Status);
                if (outcome.BytesWritten.HasValue) result.SetInt64(4, outcome.BytesWritten.Value);
                else result.SetDBNull(4);
                if (outcome.ErrorCode == null) result.SetDBNull(5);
                else result.SetString(5, outcome.ErrorCode);
                SqlContext.Pipe.SendResultsRow(result);
            }
            SqlContext.Pipe.SendResultsEnd();
        }

        private static void ValidateArchiveTransaction(bool stageRows)
        {
            using (var connection = new SqlConnection("context connection=true"))
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"SELECT CASE
WHEN @@TRANCOUNT <> 0 OR XACT_STATE() = -1 OR (@@OPTIONS & 2) <> 0 THEN 1
WHEN @Stage = 1 AND OBJECT_ID(N'tempdb..#tbx_ZipDirectoryResult',N'U') IS NULL THEN 2
ELSE 0 END;";
                command.Parameters.Add("@Stage", SqlDbType.Bit).Value = stageRows;
                connection.Open();
                int status = (int)command.ExecuteScalar();
                if (status == 1) throw new InvalidOperationException("ARCHIVE_TRANSACTION_FORBIDDEN");
                if (status == 2) throw new InvalidOperationException("ARCHIVE_RESULT_STAGE_REQUIRED");
            }
        }

        private static void StoreArchiveOutcomes(IList<ArchiveDirectoryExtraction.ExtractionOutcome> outcomes)
        {
            using (var connection = new SqlConnection("context connection=true"))
            using (var command = connection.CreateCommand())
            {
                command.CommandText = @"INSERT #tbx_ZipDirectoryResult(Ordinal,EntryName,EntryKind,Status,BytesWritten,ErrorCode)
VALUES (@Ordinal,@Name,@Kind,@Status,@Bytes,@Code);";
                var ordinal = command.Parameters.Add("@Ordinal", SqlDbType.BigInt);
                var name = command.Parameters.Add("@Name", SqlDbType.NVarChar, -1);
                var kind = command.Parameters.Add("@Kind", SqlDbType.VarChar, 9);
                var status = command.Parameters.Add("@Status", SqlDbType.VarChar, 16);
                var bytes = command.Parameters.Add("@Bytes", SqlDbType.BigInt);
                var code = command.Parameters.Add("@Code", SqlDbType.VarChar, 64);
                connection.Open();
                foreach (var outcome in outcomes)
                {
                    ordinal.Value = (long)outcome.Ordinal;
                    name.Value = outcome.Entry.Name;
                    kind.Value = outcome.Entry.IsDirectory ? "directory" : "file";
                    status.Value = outcome.Status;
                    bytes.Value = (object)outcome.BytesWritten ?? DBNull.Value;
                    code.Value = (object)outcome.ErrorCode ?? DBNull.Value;
                    command.ExecuteNonQuery();
                }
            }
        }

        private sealed partial class FilesystemExecution
        {
            public void RunArchive(Action action)
            {
                try { Run(action); }
                catch
                {
                    if (!restored) throw new InvalidOperationException("ARCHIVE_IDENTITY_CONTEXT_FAILED");
                    throw;
                }
            }
        }
    }
}
