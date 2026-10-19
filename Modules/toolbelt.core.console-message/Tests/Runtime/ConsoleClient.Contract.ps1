[CmdletBinding()]
param([Parameter(Mandatory)][System.Data.SqlClient.SqlConnection]$Connection)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Der CLR-Handler funktioniert auch bei InfoMessage auf einem IO-Thread.
if (-not ('Toolbelt.Tests.ConsoleClientContract' -as [type])) {
    $references = @((Get-ChildItem (Join-Path $PSHOME 'ref/*.dll')).FullName)
    $references += [System.Data.SqlClient.SqlConnection].Assembly.Location
    # Den installierten System.Data.SqlClient auch mit neueren PowerShell-
    # Referenzassemblies und dessen Obsolete-Markierung explizit prüfen.
    Add-Type -ReferencedAssemblies $references -CompilerOptions '/nowarn:1701,0618' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading;

namespace Toolbelt.Tests {
    public static class ConsoleClientContract {
        static void Require(bool value, string code) {
            if (!value) throw new InvalidOperationException("CONSOLE_CLIENT_" + code);
        }

        static List<string> Capture(SqlConnection connection, string payload, bool immediate,
                                    bool help, int expectedError) {
            var frames = new List<string>();
            SqlInfoMessageEventHandler handler = (sender, args) => {
                foreach (SqlError error in args.Errors) {
                    Require(error.Class == 0, "MESSAGE_SEVERITY");
                    frames.Add(error.Message);
                }
            };
            connection.InfoMessage += handler;
            try {
                using (var command = connection.CreateCommand()) {
                    command.CommandTimeout = 60;
                    command.CommandText = @"SET NOCOUNT ON;
DECLARE @Return int;
EXEC @Return=toolbelt_core.USP_WriteConsoleMessage
     @Message=@Payload,@Immediate=@Immediate,@Debug=1,@Hilfe=@Help;
IF @Return<>0 THROW 52998,N'Console return code.',1;";
                    command.Parameters.Add("@Payload", SqlDbType.NVarChar, -1).Value =
                        (object)payload ?? DBNull.Value;
                    command.Parameters.Add("@Immediate", SqlDbType.Bit).Value = immediate;
                    command.Parameters.Add("@Help", SqlDbType.Bit).Value = help;
                    bool rejected = false;
                    try {
                        using (var reader = command.ExecuteReader()) {
                            if (help) {
                                Require(reader.FieldCount == 12, "HELP_COLUMNS");
                                int rows = 0;
                                while (reader.Read()) rows++;
                                Require(rows > 0, "HELP_ROWS");
                                Require(!reader.NextResult(), "HELP_EXTRA_RESULT");
                            } else {
                                do {
                                    Require(reader.FieldCount == 0, "UNEXPECTED_RESULTSET");
                                } while (reader.NextResult());
                            }
                        }
                    } catch (SqlException error) {
                        Require(expectedError != 0 && error.Number == expectedError,
                                "UNEXPECTED_SQL_ERROR_" + error.Number);
                        rejected = true;
                    }
                    Require(rejected == (expectedError != 0), "EXPECTED_REJECTION");
                }
            } finally {
                connection.InfoMessage -= handler;
            }
            return frames;
        }

        static void Payload(SqlConnection connection, string payload, bool immediate) {
            var frames = Capture(connection, payload, immediate, false, 0);
            Require(String.Equals(String.Concat(frames), payload ?? "", StringComparison.Ordinal),
                    "PAYLOAD_MISMATCH");
            if (String.IsNullOrEmpty(payload)) Require(frames.Count == 0, "EMPTY_MESSAGE");
            int size = immediate ? 2000 : 4000;
            foreach (string frame in frames) {
                Require(frame.Length > 0 && frame.Length <= size, "FRAME_SIZE");
                Require(!Char.IsLowSurrogate(frame[0]) &&
                        !Char.IsHighSurrogate(frame[frame.Length - 1]), "SURROGATE_BOUNDARY");
            }
        }

        static bool Nowait(SqlConnection connection) {
            using (var first = new ManualResetEventSlim(false)) {
                SqlInfoMessageEventHandler handler = (sender, args) => {
                    foreach (SqlError error in args.Errors)
                        if (error.Message == "TBX-NOWAIT-PROBE") first.Set();
                };
                connection.InfoMessage += handler;
                try {
                    using (var command = connection.CreateCommand()) {
                        command.CommandTimeout = 30;
                        command.CommandText = @"SET NOCOUNT ON;
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=N'TBX-NOWAIT-PROBE',@Immediate=1;
WAITFOR DELAY '00:00:03';";
                        var pending = command.ExecuteNonQueryAsync();
                        bool observed = first.Wait(TimeSpan.FromSeconds(10));
                        bool beforeCompletion = observed && !pending.IsCompleted;
                        pending.GetAwaiter().GetResult();
                        Require(observed || first.IsSet, "NOWAIT_MARKER_MISSING");
                        // Clientpufferung ist eine Beobachtung, kein Engine-Vertragsfehler.
                        return beforeCompletion;
                    }
                } finally {
                    connection.InfoMessage -= handler;
                }
            }
        }

        public static bool Run(SqlConnection connection) {
            Require(connection.State == ConnectionState.Open, "CONNECTION_CLOSED");
            foreach (bool immediate in new [] { false, true }) {
                Payload(connection, null, immediate);
                Payload(connection, "", immediate);
                Payload(connection, "100% literal %s %d\r\nZeile 2   ", immediate);
                int size = immediate ? 2000 : 4000;
                Payload(connection, new String('A', size - 1) + "\U0001F43C" +
                        new String('B', size + 19) + "\r\nEND   ", immediate);
                Payload(connection, new String('C', 524288), immediate);
                Require(Capture(connection, new String('D', 524289), immediate, false, 52801)
                        .Count == 0, "REJECTION_EMITTED_PAYLOAD");
            }
            Require(Capture(connection, new String('E', 524289), true, true, 0).Count == 0,
                    "HELP_EMITTED_PAYLOAD");
            return Nowait(connection);
        }
    }
}
'@
}

$beforeCompletion = [Toolbelt.Tests.ConsoleClientContract]::Run($Connection)
Write-Output ('CONSOLE_CLIENT_ADONET_PASS NOWAIT_' + $(
    if ($beforeCompletion) { 'BEFORE_COMPLETION' } else { 'NOT_OBSERVED_BEFORE_COMPLETION' }))
