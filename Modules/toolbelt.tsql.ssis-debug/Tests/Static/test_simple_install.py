"""Generator control tests with synthetic payloads; never a native build claim."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("simple_install", MODULE / "Scripts/New-SimpleInstall.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class SimpleInstaller(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.dom = self.root / "private.dll"
        self.dom.write_bytes(b"synthetic private dependency")
        (self.root / "Toolbelt.Tsql.SsisDebug.dll").write_bytes(b"synthetic provider")
        sources = sorted({p.resolve() for p in (MODULE / "Clr").rglob("*")
                          if p.suffix in {".cs", ".csproj"} and not {"bin", "obj", ".runtime"}.intersection(p.relative_to(MODULE / "Clr").parts)}
                         | {p.resolve() for p in (MODULE / "Exchange/Core").glob("*.cs")}
                         | {(MODULE.parent / "toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs").resolve()})
        import os
        entries = [Path(os.path.relpath(p, MODULE)).as_posix() + ":" + installer.sha(p.read_bytes()) for p in sources]
        self.manifest = dict(moduleId="toolbelt.tsql.ssis-debug", permissionSet="UNSAFE", reproducedBuild=True,
                             sha512=installer.sha(b"synthetic provider", "sha512"),
                             scriptDomSha512=installer.sha(self.dom.read_bytes(), "sha512"), sourceFiles=entries,
                             sourceFingerprintSha256=installer.sha("\n".join(entries).encode()),
                             deploymentFiles=["Source/" + name + ":" + installer.sha((MODULE / "Source" / name).read_bytes())
                                              for name in ("USP_ExplainSsisDataFlow.sql", "USP_ExplainSsisDataFlowInternal.sql")])
        self.save()

    def save(self):
        (self.root / "Toolbelt.Tsql.SsisDebug.trust-manifest.json").write_text(json.dumps(self.manifest), encoding="utf-8")

    def test_admission_retains_bound_bytes_for_every_supported_mode(self):
        for mode in ('auto','hash','trustworthy-checked','trustworthy'):
            with self.subTest(mode=mode):
                result=installer.validate_inputs(self.root,self.dom,mode)
                self.assertEqual(result['provider'],b'synthetic provider')
                self.assertEqual(result['scriptdom'],b'synthetic private dependency')

    def reject(self, mutate, expected):
        mutate(); self.save()
        with self.assertRaisesRegex(ValueError, expected):
            installer.validate_inputs(self.root, self.dom)

    def test_payload_drift(self):
        self.reject(lambda: self.dom.write_bytes(b"changed"), "BINARY_BINDING")

    def test_source_inventory(self):
        self.reject(lambda: self.manifest["sourceFiles"].pop(), "SOURCE_INVENTORY")

    def test_source_hash(self):
        self.reject(lambda: self.manifest["sourceFiles"].__setitem__(0, self.manifest["sourceFiles"][0].rsplit(":", 1)[0] + ":" + "0" * 64), "SOURCE_DRIFT")

    def test_facade_drift(self):
        self.reject(lambda: self.manifest.__setitem__("deploymentFiles", []), "FACADE_SOURCE_DRIFT")

    def test_unknown_mode(self):
        with self.assertRaisesRegex(ValueError, "TRUST_MODE"):
            installer.validate_inputs(self.root, self.dom, "fallback")



if __name__ == "__main__":
    unittest.main()
