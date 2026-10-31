"""Negative Vor-SQL-Gates des aktuellen Stable-19-Labtreibers."""
from pathlib import Path
import json
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / "Tests/Release/Invoke-Stable19AcceptanceLab.ps1"


class Stable19AcceptanceTests(unittest.TestCase):
    def rejected(self, change, expected, outside=False):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=None if outside else ROOT / ".runtime") as temp:
            folder = Path(temp)
            record = dict(schema_version="toolbelt-stable19-acceptance/v1", source_commit="1" * 40,
                          cases=[dict(Platform="linux", Version="2019", Patch="latest", CL=150)] * 12,
                          modules=[dict(module_id="toolbelt.test." + str(i), module_version="1.0.0") for i in range(19)],
                          pins=[], exports=dict(local="unused", central="unused"), fixture="unused")
            change(record, folder)
            runset = folder / "runset.json"
            runset.write_text(json.dumps(record), encoding="utf-8")
            result = subprocess.run(["pwsh", "-NoProfile", "-NonInteractive", "-File", str(DRIVER),
                                     "-RunsetPath", str(runset), "-CaseIndex", "0"],
                                    cwd=ROOT, capture_output=True, text=True, timeout=25,
                                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            self.assertEqual(result.returncode, 1)
            self.assertIn(expected, result.stdout)
            self.assertEqual(result.stderr, "")
            self.assertFalse(list(folder.glob("case-*.json")), "No native attempt may begin")

    def test_outside_private_directory_rejected(self):
        self.rejected(lambda r, d: None, "RELEASE_PRIVATE_PATH_REQUIRED", outside=True)

    def test_unsupported_engine_cl_rejected(self):
        self.rejected(lambda r, d: r["cases"][0].update(CL=170), "STABLE19_CASE")

    def test_missing_driver_and_payload_pins_rejected(self):
        self.rejected(lambda r, d: None, "STABLE19_REQUIRED_PIN")

    def test_changed_pinned_input_rejected(self):
        def change(record, folder):
            source = folder / "source.sql"
            source.write_text("SELECT 42;", encoding="utf-8")
            record["pins"] = [dict(path=str(source), sha256="0" * 64)]
        self.rejected(change, "RELEASE_INPUT_DRIFT")


if __name__ == "__main__":
    unittest.main()
