"""Native Verbundabnahme bleibt von Vollqualifikation und Historie getrennt."""
from pathlib import Path
import copy,json,sys,unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import prepare_release as release
import prepare_current_candidate as candidate
import current_install_qualification as q

class CurrentInstallQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _,cls.files=release.snapshot('HEAD')
        for p in (q.PACKAGE,q.PACKAGE+'.sha256',q.RECORD):
            cls.files[p]=(ROOT/p).read_bytes()

    def changed(self,update):
        files=dict(self.files);record=json.loads(files[q.RECORD]);update(record)
        files[q.RECORD]=(json.dumps(record)+'\n').encode()
        return files

    def test_current_candidate_uses_the_new_native_qualified_installer(self):
        result=candidate.installer_inputs(self.files)
        self.assertEqual(result['path'],q.PACKAGE)
        self.assertEqual(len(result['profiles']),4)

    def test_current_plan_keeps_historical_channel_approval_separate(self):
        original=self.files['Releases/1.0.0/support-scope.json']
        plan=candidate.current_plan(self.files,'0'*40)
        self.assertEqual(sum(plan['channels'].values()),45)
        self.assertIn('proposals only',plan['channel_semantics'])
        self.assertIs(plan['publication_authorized'],False)
        self.assertEqual(self.files['Releases/1.0.0/support-scope.json'],original)

    def test_missing_current_record_cannot_fall_back_to_historical_help(self):
        files=dict(self.files);files.pop(q.RECORD)
        with self.assertRaises(ValueError):candidate.installer_inputs(files)

    def test_failed_or_missing_fresh_audit_and_changed_process_result_are_rejected(self):
        for update in (lambda r:r['cases'][0].update(result='FAILED_CLEANED'),
                       lambda r:r['cases'][0].update(fresh_independent_audit='not executed'),
                       lambda r:r['cases'][0].update(body_exit_code=1)):
            with self.subTest(update=update),self.assertRaises(ValueError):q.installer_inputs(self.changed(update))

    def test_unknown_compiler_change_and_rewritten_archive_are_rejected(self):
        files=dict(self.files)
        path='Modules/toolbelt.tsql.ssis-debug/Clr/Core.cs'
        files[path]+=b'\n// unknown source drift'
        with self.assertRaises(ValueError):q.installer_inputs(files)
        files=dict(self.files);files[q.PACKAGE]+=b'unknown archive bytes'
        with self.assertRaises(ValueError):q.installer_inputs(files)

    def test_whole_module_claim_and_erased_history_are_rejected(self):
        for update in (lambda r:r.update(full_business_requalification=True),lambda r:r['history'].update(failed_total_cases=0)):
            with self.subTest(update=update),self.assertRaises(ValueError):q.installer_inputs(self.changed(update))

if __name__=='__main__':unittest.main()
