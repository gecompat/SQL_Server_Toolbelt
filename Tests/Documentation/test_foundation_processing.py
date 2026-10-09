"""Offline Toolbelt consumers; no real client/cache-hit attestation."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("processing", ROOT / ".ai/foundation/runtime/processing_efficiency.py")
processing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(processing)
RULES = ".ai/WORKING_RULES.md"
COST = "Documentation/Standards/AI_COST_AND_QUALITY_PROCESSING_POLICY.md"
BASELINE = ".ai/foundation/FOUNDATION_RULESET.md"
DEPENDENCIES = {BASELINE: [], RULES: [BASELINE], COST: [RULES]}


class ToolbeltSessionScenarios(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for path in [*DEPENDENCIES, "AGENTS.md"]:
            destination = self.root / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes((ROOT / path).read_bytes())
        self.session = processing.SessionContext()
        self.reads = []

    def snapshot(self, *, complete=True):
        # Explicit synthetic discovery; never infer the real client's settings.
        authority = processing.digest({"chain": ["AGENTS.md"],
            "instructions": (self.root / "AGENTS.md").read_text(encoding="utf-8"),
            "fixture_config": {"fallback_names": [], "byte_limit": 65536}})
        return processing.capture_context(self.root, DEPENDENCIES,
            repository_identity="synthetic-toolbelt", authority_key=authority,
            scope_key="governance-upgrade", discovery_complete=complete)

    def analyze_required(self, snapshot):
        # Retain actually read fixture analysis in memory, never as authority.
        analyses = {}
        for path in self.session.check(snapshot)["reread"]:
            self.reads.append(path)
            analyses[path] = (self.root / path).read_text(encoding="utf-8")
        self.session.acknowledge(snapshot, analyses)

    def test_second_unchanged_wave_has_no_rule_read(self):
        first = self.snapshot()
        self.assertEqual("READ", self.session.check(first)["status"])
        self.analyze_required(first)
        self.reads.clear()
        second = self.snapshot()
        self.analyze_required(second)
        self.assertEqual([], self.reads)
        self.assertEqual("REUSE", self.session.check(second)["status"])
        self.assertIn("Geprüfte Sessionanalyse", self.session.analysis_for(second, RULES))

    def test_rule_change_invalidates_transitive_cost_analysis(self):
        self.analyze_required(self.snapshot())
        with (self.root / RULES).open("a", encoding="utf-8") as output:
            output.write("\nSynthetische zusätzliche Scopegrenze.\n")
        changed = self.snapshot()
        result = self.session.check(changed)
        self.assertEqual("PARTIAL", result["status"])
        self.assertEqual([BASELINE], result["reuse"])
        self.assertEqual(sorted([RULES, COST]), result["reread"])
        with self.assertRaises(KeyError):
            self.session.analysis_for(changed, COST)

    def test_instruction_change_invalidates_all(self):
        self.analyze_required(self.snapshot())
        with (self.root / "AGENTS.md").open("a", encoding="utf-8") as output:
            output.write("\nSynthetisches neues Stop-Gate.\n")
        self.assertEqual(sorted(DEPENDENCIES), self.session.check(self.snapshot())["reread"])

    def test_fingerprint_does_not_create_missing_analysis(self):
        snapshot = self.snapshot()
        self.analyze_required(snapshot)
        empty = processing.SessionContext()
        self.assertEqual("READ", empty.check(snapshot)["status"])
        with self.assertRaises(KeyError):
            empty.analysis_for(snapshot, RULES)

    def test_incomplete_discovery_blocks_reuse_and_acknowledgement(self):
        self.analyze_required(self.snapshot())
        incomplete = self.snapshot(complete=False)
        self.assertEqual("DISCOVERY_INCOMPLETE", self.session.check(incomplete)["reason"])
        self.assertEqual([], self.session.check(incomplete)["reuse"])
        with self.assertRaises(ValueError):
            self.session.acknowledge(incomplete, {RULES: "not authorized to reuse"})


if __name__ == "__main__":
    unittest.main()
