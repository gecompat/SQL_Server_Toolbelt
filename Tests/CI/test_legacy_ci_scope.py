"""Keep retired native lifecycle jobs explicit and preserve their cleanup guards."""
from pathlib import Path
import re
import unittest

ROOT=Path(__file__).resolve().parents[2]
BASELINE='2fbe8e3e86f370b22ad2ce9f9716d971072a052b'


class LegacyCiScope(unittest.TestCase):
    def workflows(self):
        for path in (ROOT/'.github/workflows').glob('*.yml'):
            text=path.read_text(encoding='utf-8-sig')
            if text.startswith('# Current markerless install gates run separately;'):
                yield path,text

    def test_retired_native_jobs_require_explicit_dispatch_and_original_checkout(self):
        count=0
        for path,text in self.workflows():
            jobs=text.split('\njobs:\n',1)[1]
            for block in re.split(r'(?m)(?=^  [A-Za-z0-9_-]+:\s*$)',jobs):
                if 'Retired SQLCMD/marker lifecycle:' not in block:continue
                count+=1
                self.assertRegex(block,r"(?m)^    if: github.event_name == 'workflow_dispatch'")
                self.assertIn("github.event_name == 'workflow_dispatch' && '"+BASELINE+"' || github.sha",block)
        self.assertGreater(count,0)

    def test_every_affected_workflow_retains_an_automatic_component_gate(self):
        for path,text in self.workflows():
            with self.subTest(path=path.name):
                jobs=text.split('\njobs:\n',1)[1]
                automatic=[b for b in re.split(r'(?m)(?=^  [A-Za-z0-9_-]+:\s*$)',jobs)
                           if 'Retired SQLCMD/marker lifecycle:' not in b]
                self.assertTrue(any('Tests/Static/validate_contract.py' in b for b in automatic))

    def test_cleanup_bodies_are_preserved_byte_for_byte(self):
        import subprocess
        for path,text in self.workflows():
            original=subprocess.check_output(['git','show',BASELINE+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT).decode('utf-8-sig')
            # Editing job admission/checkout must not remove existing always cleanup.
            for token in re.findall(r'(?m)^.*always\(\).*$|^.*docker (?:rm|stop).*$|^.*cleanup.*$',original):
                self.assertIn(token,text,path.name)


if __name__=='__main__':unittest.main()
