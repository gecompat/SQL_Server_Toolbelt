"""Run intact historical evidence checks, without accepting current deployment."""
from pathlib import Path
import os
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
BASELINE='2fbe8e3e86f370b22ad2ce9f9716d971072a052b'


def main():
    sys.path.insert(0,str(ROOT/'Tests/Release'))
    from ssis_historical_context import historical_root
    frozen=historical_root(ROOT,BASELINE)
    changed=subprocess.check_output(['git','diff','--name-only','--diff-filter=MD',BASELINE,'--',
        'Releases',':(glob)Modules/**/Tests/Qualification/**',':(glob)Modules/**/InstallPackages/**'],cwd=ROOT,text=True)
    protected=[p for p in changed.splitlines() if p.endswith(('.json','.zip','.sha256','.sha512'))]
    if protected:raise ValueError('HISTORICAL_EVIDENCE_CHANGED: '+', '.join(protected))
    env=os.environ.copy();env['PYTHONIOENCODING']='utf-8';env['PYTHONDONTWRITEBYTECODE']='1'
    print('HISTORICAL_RELEASE_SUITE source='+BASELINE+'; no current deployment qualification',flush=True)
    return subprocess.run([sys.executable,'-B',str(frozen/'Tests/Documentation/run_release_validation.py')],
                          cwd=frozen,env=env,timeout=1800).returncode


if __name__=='__main__':raise SystemExit(main())
