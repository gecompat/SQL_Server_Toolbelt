"""Große native Capture-Grenzen nur bei originaler vollständiger Bindung anerkennen."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import regex_capture_boundary_status as status


class RegexCaptureBoundaryStatusTests(unittest.TestCase):
    def report(self):return json.loads((ROOT/status.REPORT).read_bytes())
    def acceptance(self):return json.loads((ROOT/status.ACCEPTANCE).read_bytes())

    def test_exact_original_large_boundary_scope(self):
        result=status.validate()
        self.assertEqual((result['routes'],result['new_native_calls']),(24,0))
        self.assertEqual((result['large_exact_bytes'],result['large_over_bytes']),(16777216,16777218))

    def test_large_opt_in_cannot_disappear(self):
        r=self.report()
        next(d for d in r['fixture_definitions'] if d['id']==status.ID)['large']=False
        with self.assertRaises(ValueError):status.validate(r)

    def test_missing_blocked_or_unaudited_metadata_cannot_be_reused(self):
        for kind in ('missing','blocked','audit','matrix'):
            r=self.report();c=r['native_api_cases'][0]
            if kind=='missing':c['passed'].remove(status.ID+':local')
            elif kind=='blocked':c['blocked'].append(dict(id=status.ID))
            elif kind=='audit':c['independent_cleanup_and_pins']=False
            else:r['native_api_cases'].pop()
            with self.subTest(kind=kind),self.assertRaises(ValueError):status.validate(r)

    def test_original_partial_and_unknown_cause_remain(self):
        r=self.report();r['native_api_cases'][0]['result']='PASS'
        with self.assertRaises(ValueError):status.validate(r)
        a=self.acceptance();a['historical_cause']='fixed'
        with self.assertRaises(ValueError):status.validate(acceptance=a)

    def test_source_and_delivered_binary_binding_cannot_change(self):
        r=self.report();r['source_sha256'][status.FIXTURE]='0'*64
        with self.assertRaises(ValueError):status.validate(r)
        a=self.acceptance();a['delivered_regex_binary_sha256']='0'*64
        with self.assertRaises(ValueError):status.validate(acceptance=a)


if __name__=='__main__':unittest.main()
