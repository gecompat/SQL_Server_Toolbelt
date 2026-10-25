"""Tatsächliche manuelle Pointer-Cleanups ohne Docker oder SQL ausführen."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'Modules/toolbelt.json.pointer/Tests/CI'

def load(name):
    spec=importlib.util.spec_from_file_location(name,BASE/(name+'.py'))
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module

class ProbeCleanupTests(unittest.TestCase):
    def test_real_cleanup_functions_keep_foreign_resources_and_propagate_failures(self):
        for name in ('run_max_workload','test_hard_interrupt_recovery'):
            module=load(name)
            for scenario in ('own','absent','foreign','invalid-id','daemon','remove-error','post-error','residue'):
                with self.subTest(module=name,scenario=scenario):
                    removed=[]
                    def cli(args,*unused,**options):
                        argv=args[1:] if args[0]=='docker' else args
                        if argv[:2]==['container','inspect']:
                            code=1 if scenario in ('absent','daemon') else 0
                            cid='invalid' if scenario=='invalid-id' else 'a'*64
                            owner='foreign' if scenario=='foreign' else 'owned'
                            return subprocess.CompletedProcess(args,code,cid+'|'+owner,'')
                        if argv[0]=='rm':
                            self.assertEqual(['rm','-f','--volumes','a'*64],argv)
                            removed.append(True)
                            return subprocess.CompletedProcess(args,17 if scenario=='remove-error' else 0,'','')
                        self.assertEqual(['container','ls','--all','--filter','name=^synthetic$','--format','{{.ID}}'],argv)
                        return subprocess.CompletedProcess(args,17 if scenario in ('daemon','post-error') else 0,'residue' if scenario=='residue' else '','')
                    with patch.object(module,'invoke' if name=='run_max_workload' else 'docker',cli):
                        try:
                            ok=module.cleanup_container('synthetic','owned',time.monotonic()+60) if name=='run_max_workload' else module.recover('synthetic','owned')
                        except module.ProbeError:
                            ok=False
                    self.assertEqual(scenario in ('own','absent'),ok)
                    self.assertEqual(scenario in ('own','remove-error','post-error','residue'),bool(removed))

    def test_real_finally_preserves_journal_until_container_cleanup_is_confirmed(self):
        module=load('run_max_workload')
        runtime=ROOT/'.runtime';runtime.mkdir(exist_ok=True)
        for confirmed in (False,True):
            with self.subTest(confirmed=confirmed),tempfile.TemporaryDirectory(prefix='probe-cleanup-check-',dir=runtime) as parent:
                private=Path(parent)/'owned';private.mkdir()
                def fail_start(*args):raise module.ProbeTimeout('synthetic create timeout')
                with patch.object(module.sys,'argv',['probe','--sql-version','2019','--stage-bytes','65536','--shape','root']),patch.object(module.shutil,'which',return_value='synthetic-docker'),patch.object(module.tempfile,'mkdtemp',return_value=str(private)),patch.object(module,'checked',side_effect=fail_start),patch.object(module,'cleanup_container',return_value=confirmed),patch.object(module.signal,'signal'),contextlib.redirect_stderr(io.StringIO()):
                    result=module.main()
                self.assertNotEqual(0,result)
                self.assertEqual(not confirmed,private.exists())
                if not confirmed:self.assertTrue((private/'owner.json').is_file())

if __name__=='__main__':unittest.main()
