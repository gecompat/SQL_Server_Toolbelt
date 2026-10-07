from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root / "Clr" / "WindowsFilesystemProvider.cs").read_text(encoding="utf-8")
procedures = (root / "Source" / "Procedures.sql").read_text(encoding="utf-8")
manifest = (root / "module.yaml").read_text(encoding="utf-8")
trust_deployment = (root / "Deployment" / "Add-TrustedAssembly.sql").read_text(encoding="utf-8")
caller_smoke_test = (root / "Tests" / "Runtime" / "WindowsCallerListDirectory.Manual.sql").read_text(encoding="utf-8")

for marker in ["SqlContext.WindowsIdentity", "ReparsePointForbidden", "MaxChunkBytes", "WriteAtomically", "EXTERNAL_ACCESS"]:
    if marker not in source + manifest:
        raise SystemExit(f"Missing security or streaming marker: {marker}")
if "SqlContext.WindowsIdentity" not in source or "CallerWindowsAuthenticationRequired" not in source:
    raise SystemExit("Caller-Modus muss ohne Windows-Token vor der Impersonierung ablehnen.")
if "sys.server_principals WHERE name = ORIGINAL_LOGIN()" in source:
    raise SystemExit("Caller-Modus darf nicht von der Sichtbarkeit serverweiter Metadaten abhängen.")
if source.index("RunAs(executionIdentity", source.index("public static void ListDirectory")) > source.index("SqlContext.Pipe.SendResultsStart", source.index("public static void ListDirectory")):
    raise SystemExit("ListDirectory muss die Resultset-Ausgabe nach der Caller-Impersonation ausführen.")
for name in ["ReadBinaryFileChunk", "ReadTextFileChunk", "WriteBinaryFile", "WriteTextFile", "TranscodeTextFile", "ListDirectory", "CreateDirectory", "RemoveFile", "RemoveDirectory"]:
    if f"USP_{name}" not in procedures or f"CLR_{name}" not in procedures:
        raise SystemExit(f"Missing facade or provider binding: {name}")
if "TRUSTWORTHY" in root.joinpath("Deployment/Deploy.sql").read_text(encoding="utf-8").upper():
    raise SystemExit("TRUSTWORTHY must not be used")
if "SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);" not in trust_deployment:
    raise SystemExit("Trusted-Assembly-Hash muss vor dem Procedure-Aufruf materialisiert werden.")
if "@hash = HASHBYTES(" in trust_deployment:
    raise SystemExit("Trusted-Assembly-Procedure darf keinen Funktionsausdruck als Parameter erhalten.")
deployment = root.joinpath("Deployment/Deploy.sql").read_text(encoding="utf-8")
if "@InstalledAssemblyHash" not in deployment or "ELSE IF @InstalledAssemblyHash <> @AssemblyHash" not in deployment:
    raise SystemExit("Wiederholungsdeployment muss eine unveränderte Assembly ohne ALTER überspringen.")
if procedures.startswith("+"):
    raise SystemExit("Procedures.sql darf vor dem ersten SET keinen SQL-fremden Prefix enthalten.")
help_parameters = [line for line in procedures.splitlines() if "UNION ALL SELECT" in line and "'PARAMETER'" in line]
if len(help_parameters) != 5 or any(
    ", CAST(0 AS bit), CAST(1 AS bit)," not in line for line in help_parameters
):
    raise SystemExit("Help-Flags müssen in jedem UNION-Zweig bit bleiben; int-Literale verbreitern die Metadaten.")
for binding in (
    "CLR_ReadBinaryFileChunk",
    "CLR_ReadTextFileChunk",
    "CLR_WriteBinaryFile",
    "CLR_WriteTextFile",
    "CLR_TranscodeTextFile",
    "CLR_ListDirectory",
    "CLR_CreateDirectory",
    "CLR_RemoveFile",
    "CLR_RemoveDirectory",
):
    binding_start = procedures.index(f"CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[{binding}]")
    binding_end = procedures.index("GO", binding_start)
    if "@ExecutionIdentity nvarchar(16) = N'Caller'" not in procedures[binding_start:binding_end]:
        raise SystemExit(f"CLR-Binding {binding} benötigt nvarchar für die C#-string-Signatur.")
    if "CREATE OR ALTER PROCEDURE" not in procedures[binding_start:binding_end]:
        raise SystemExit(f"CLR-Binding {binding} muss Assembly-Upgrades idempotent unterstützen.")
if procedures.count("DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);") != 9:
    raise SystemExit("Jede öffentliche Facade muss den ExecutionIdentity-Wert für das CLR-Binding materialisieren.")
if "TBXFS:EntryLimitExceeded" not in procedures or "Die Verzeichnisausgabe ueberschreitet @MaxEntries" not in procedures:
    raise SystemExit("USP_ListDirectory muss bei der Eintragsgrenze eine verständliche Fehlermeldung ausgeben.")
if procedures.count("Dateisystemprovider konnte") != 8:
    raise SystemExit("Jede übrige öffentliche Dateisystem-Fassade muss ihren Providerfehler einordnen.")
for marker in ("RootAlias \"__REQUIRED__\"", "USP_ListDirectory", "@ExecutionIdentity = 'Caller'", "@MaxEntries = 10000"):
    if marker not in caller_smoke_test:
        raise SystemExit(f"Manueller Caller-Smoke-Test enthält nicht: {marker}")
if "@Content varbinary(max) = NULL" in procedures[: procedures.index("CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]")]:
    raise SystemExit("CLR-varbinary(max)-Binding darf keinen Defaultwert verwenden.")
if "@Content nvarchar(max) = NULL" in procedures[: procedures.index("CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]")]:
    raise SystemExit("CLR-nvarchar(max)-Binding darf keinen Defaultwert verwenden.")

# Drei öffentliche Schreibpfade leiten denselben unveränderten Boolwert weiter.
for call, expected_count in (
    ("WriteAtomicallyScoped(root, target, overwrite, delegate(FileStream output)", 2),
    ("WriteAtomically(targetRoot, targetPath, overwrite, delegate(FileStream destination)", 1),
):
    if source.count(call) != expected_count:
        raise SystemExit("NoOverwrite muss in allen drei Schreibpfaden weitergegeben werden.")
helper = source[source.index("private static void WriteAtomically("):source.index("private static SqlDataRecord Record(")]
if "Root root, string target, bool overwrite, Action<FileStream> write" not in helper:
    raise SystemExit("Atomarer Schreibhelper benötigt den ursprünglichen Overwrite-Boolwert.")
publication = "if (!overwrite) File.Move(staging, target); else if (File.Exists(target)) File.Replace(staging, target, null, true); else File.Move(staging, target);"
if publication not in helper or helper.count("File.Replace(") != 1:
    raise SystemExit("NoOverwrite darf weder Exists/Replace noch einen Fallback verwenden; true bleibt unverändert.")
if "if (ownStage)" not in helper or "filesystem(delegate { if (File.Exists(staging)) File.Delete(staging); });" not in helper:
    raise SystemExit("Eigene Stagingdatei muss auch nach fehlgeschlagener Veröffentlichung bereinigt werden.")
if "WriteAtomicallyScoped(root, target, overwrite, write, delegate(Action action) { action(); });" not in helper:
    raise SystemExit("Historischer Helper muss denselben atomaren Publikationskern verwenden.")
copy = source[source.index("private static long CopyBinaryContent("):source.index("private static void WriteAtomically(")]
if copy.count("content.Read(") != 2 or copy.count("filesystem(delegate { output.Write(") != 3:
    raise SystemExit("SQL-LOB-Reads bleiben außerhalb, alle drei Chunk-/BOM-Writes innerhalb der FS-Scope.")
for marker in (
    "FilesystemExecution execution = new FilesystemExecution(executionIdentity);",
    "identity = GetCallerIdentity();",
    "if (!restored) { identityFailure.Throw(); return; }",
    "if (context == null) { restored = false; identityFailure = failure; }",
    "context.Undo();",
    "filesystem(delegate { output.Flush(true); });",
    "filesystem(delegate { output.Dispose(); });",
    "if (failure == null) filesystem(delegate { if (!overwrite) File.Move(staging, target);",
    "if (failure != null) failure.Throw();",
):
    if marker not in source:
        raise SystemExit("Streaming-/Identitätsscope oder Erstfehlerschutz fehlt: " + marker)
for framework_file in ("NoOverwriteHarness.cs", "Invoke-NoOverwrite.ps1", "Test-WitnessControls.ps1"):
    if not root.joinpath("Tests/Framework", framework_file).is_file():
        raise SystemExit("NoOverwrite-Offline-Regressionsquelle fehlt: " + framework_file)
if 'version: "1.0.0"' not in manifest or "release_status: unreleased" not in manifest:
    raise SystemExit("Enger unreleased-NoOverwrite-Fix darf keine Version oder Freigabe erfinden.")

# Gemeinsamer Caller-Guard: keine wrapper-only Pruefung oder Metadatenrechte.
if source.count("GetCallerIdentity();") != 2 or source.count("SqlContext.WindowsIdentity;") != 1:
    raise SystemExit("Beide Caller-Pfade muessen dieselbe Authentifizierung pruefen.")
auth = source[source.index("private static WindowsIdentity GetCallerIdentity()"):source.index("private static void RunAs(")]
if "SELECT CONVERT(nvarchar(40), CONNECTIONPROPERTY('auth_scheme'));" not in auth:
    raise SystemExit("Requestbezogene Authentifizierung fehlt.")
if "scheme as string" not in auth or "Trim(" in auth or "ToUpper" in auth:
    raise SystemExit("Auth-Modi muessen exakt typisiert und ordinal sein.")
for mode in ("NTLM", "KERBEROS", "DIGEST", "BASIC", "NEGOTIATE"):
    if f'String.Equals(value, "{mode}", StringComparison.Ordinal)' not in auth:
        raise SystemExit("Geschlossener Windows-Auth-Modus fehlt.")
if auth.count("String.Equals(value,") != 5 or "Impersonate(" in auth or "sys.dm_" in auth:
    raise SystemExit("Caller-Auth-Guard darf weder I/O noch DMV-Abhaengigkeit erweitern.")

# Der bestehende Löschvertrag darf die begrenzte Vorprüfung nicht umgehen.
remove_start = source.index("public static void RemoveDirectory(")
remove_end = source.index("private static Root GetRoot(", remove_start)
remove = source[remove_start:remove_end]
for marker in (
    'RemoveDirectoryBounded(root.RootPath, path, recursive, maxDepth, maxEntries)',
    'if (plan.Count >= maxEntries) Fail("EntryLimitExceeded")',
    'if (current.Depth >= maxDepth) Fail("DepthLimitExceeded")',
    'for (int index = plan.Count - 1; index >= 0; index--)',
    'Directory.Delete(entry.Path, false)',
    'Directory.Delete(path, false)',
    'Fail("DirectoryTreeChanged")',
):
    if marker not in remove:
        raise SystemExit("Begrenzter RemoveDirectory-Vertrag fehlt: " + marker)
if "Directory.Delete(path, recursive)" in remove or "Enumerate(path, recursive, maxDepth)" in remove:
    raise SystemExit("RemoveDirectory darf keinen ungeprüften rekursiven Delete verwenden.")
if remove.index('Fail("DirectoryNotEmpty")') > remove.index('Directory.Delete(entry.Path, false)'):
    raise SystemExit("Alle fachlichen Limitprüfungen müssen vor der ersten Löschung liegen.")

print("Windows filesystem static contract passed.")
