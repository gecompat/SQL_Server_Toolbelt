from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = (root / "Clr" / "WindowsFilesystemProvider.cs").read_text(encoding="utf-8")
procedures = (root / "Source" / "Procedures.sql").read_text(encoding="utf-8")
manifest = (root / "module.yaml").read_text(encoding="utf-8")

for marker in ["SqlContext.WindowsIdentity", "ReparsePointForbidden", "MaxChunkBytes", "WriteAtomically", "EXTERNAL_ACCESS"]:
    if marker not in source + manifest:
        raise SystemExit(f"Missing security or streaming marker: {marker}")
for name in ["ReadBinaryFileChunk", "ReadTextFileChunk", "WriteBinaryFile", "WriteTextFile", "TranscodeTextFile", "ListDirectory", "CreateDirectory", "RemoveFile", "RemoveDirectory"]:
    if f"USP_{name}" not in procedures or f"CLR_{name}" not in procedures:
        raise SystemExit(f"Missing facade or provider binding: {name}")
if "TRUSTWORTHY" in root.joinpath("Deployment/Deploy.sql").read_text(encoding="utf-8").upper():
    raise SystemExit("TRUSTWORTHY must not be used")
print("Windows filesystem static contract passed.")
