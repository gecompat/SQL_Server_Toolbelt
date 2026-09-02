from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root / "Clr" / "WindowsFilesystemProvider.cs").read_text(encoding="utf-8")
procedures = (root / "Source" / "Procedures.sql").read_text(encoding="utf-8")
manifest = (root / "module.yaml").read_text(encoding="utf-8")
trust_deployment = (root / "Deployment" / "Add-TrustedAssembly.sql").read_text(encoding="utf-8")

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
if procedures.startswith("+"):
    raise SystemExit("Procedures.sql darf vor dem ersten SET keinen SQL-fremden Prefix enthalten.")
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
if "@Content varbinary(max) = NULL" in procedures[: procedures.index("CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]")]:
    raise SystemExit("CLR-varbinary(max)-Binding darf keinen Defaultwert verwenden.")
if "@Content nvarchar(max) = NULL" in procedures[: procedures.index("CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]")]:
    raise SystemExit("CLR-nvarchar(max)-Binding darf keinen Defaultwert verwenden.")
print("Windows filesystem static contract passed.")
